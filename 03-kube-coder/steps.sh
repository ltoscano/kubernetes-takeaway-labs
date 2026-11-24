#!/usr/bin/env bash
# Parte 3 - Kubernetes e gli agenti AI: workspace agentici con kube-coder
# Prerequisito: ./install-ingress-nginx.sh (ingress-nginx con IngressClass "nginx")
# Variabili:  KC_VERSION (tag del progetto, default v1.87.2)
#             SKIP_BUILD=1 per riusare l'immagine kube-coder:local già costruita
source "$(dirname "$0")/../lib.sh"; cd "$(dirname "$0")"
KC_VERSION="${KC_VERSION:-v1.87.2}"
NS=ws-local
PF_PORT=8081          # porta locale per il port-forward verso ingress-nginx
HOSTNAME_WS=kube-coder.local

# --- 3.3 Sorgenti e immagine del workspace -----------------------------------
if [[ ! -d kube-coder ]]; then
  run git clone --branch "$KC_VERSION" --depth 1 https://github.com/imran31415/kube-coder.git
fi
run "git -C kube-coder describe --tags"
if [[ "${SKIP_BUILD:-0}" != "1" ]] || ! docker image inspect kube-coder:local >/dev/null 2>&1; then
  # 20-30 minuti la prima volta: l'immagine contiene code-server, Chrome/Firefox, ttyd e gli agenti
  run docker build -t kube-coder:local -f kube-coder/devlaptop/Dockerfile kube-coder
fi
run "docker image ls kube-coder:local"
# nessun registry: copiamo l'immagine direttamente nel containerd dei nodi worker
run kind load docker-image kube-coder:local --name takeaway --nodes "$NODE2,$NODE3"
run "docker exec $NODE2 crictl images | grep -E 'IMAGE|kube-coder'"
pausa

# --- 3.4 Installazione con Helm -----------------------------------------------
run "kubectl create namespace $NS --dry-run=client -o yaml | kubectl apply -f -"
# credenziali dell'autenticazione basic gestita dall'Ingress (utente admin, password admin)
run "kubectl create secret generic kube-coder-basic-auth --namespace $NS \
  --from-literal=auth=\"admin:\$(openssl passwd -apr1 admin)\" --dry-run=client -o yaml | kubectl apply -f -"
run helm upgrade --install base-infrastructure kube-coder/charts/base-infrastructure \
  --namespace $NS --set namespace=$NS --wait
run helm upgrade --install ws-local kube-coder/charts/workspace --namespace $NS \
  -f kube-coder/deployments/local/values.yaml -f values-takeaway.yaml --wait --timeout 10m
run helm list --namespace $NS
pausa

# --- 3.5 Anatomia di un workspace: gli oggetti Kubernetes -----------------------
run kubectl get deployment,pod,service,ingress,pvc --namespace $NS -o wide
run kubectl get serviceaccount,role,rolebinding,resourcequota,limitrange,networkpolicy --namespace $NS
run kubectl describe resourcequota --namespace $NS
run "kubectl get deployment ws-local --namespace $NS -o jsonpath='{.spec.strategy.type}{\"\n\"}'"
run "kubectl get pod --namespace $NS -l app=ws-local -o jsonpath='{.items[0].spec.securityContext}{\"\n\"}'"
run "kubectl get pod --namespace $NS -l app=ws-local -o jsonpath='{range .items[0].spec.containers[*]}{.name}{\"  \"}{.resources}{\"\n\"}{end}'"
run "kubectl get pvc ws-local-home --namespace $NS -o jsonpath='{.metadata.annotations}{\"\n\"}'"
pausa

# --- 3.6 Accesso al workspace ---------------------------------------------------
kubectl port-forward --namespace ingress-nginx svc/ingress-nginx-controller $PF_PORT:80 >/dev/null 2>&1 &
PF_PID=$!; trap 'kill $PF_PID 2>/dev/null || true' EXIT; sleep 3
echo
echo "\$ kubectl port-forward --namespace ingress-nginx svc/ingress-nginx-controller $PF_PORT:80 &"
# senza credenziali l'Ingress risponde 401; con admin/admin arriva al pod
run "curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: $HOSTNAME_WS' http://localhost:$PF_PORT/"
run "curl -s -o /dev/null -w '%{http_code}\n' -u admin:admin -H 'Host: $HOSTNAME_WS' http://localhost:$PF_PORT/"
run "curl -s -u admin:admin -H 'Host: $HOSTNAME_WS' http://localhost:$PF_PORT/health; echo"
pausa

# --- 3.7 Gli agenti nel pod ------------------------------------------------------
run "kubectl exec --namespace $NS deploy/ws-local -c ide -- bash -lc 'claude --version; codex --version; opencode --version; tmux -V'"
# API dei task: crea una sessione dell'agente in una sessione tmux del pod
API="http://localhost:$PF_PORT/api/claude/tasks"
run "curl -s -u admin:admin -H 'Host: $HOSTNAME_WS' -H 'Content-Type: application/json' \
  -d '{\"prompt\": \"Elenca i file in /home/dev\", \"assistant\": \"claude\"}' \
  $API | tee /tmp/kc-task.json | jq '{task_id, status, assistant, tmux_session}'"
TASK_ID=$(jq -r .task_id /tmp/kc-task.json)
sleep 20
run "curl -s -u admin:admin -H 'Host: $HOSTNAME_WS' $API | jq '.tasks[] | {task_id, status, prompt}'"
run "kubectl exec --namespace $NS deploy/ws-local -c ide -- tmux ls"
# che cosa vede l'agente? senza credenziali, la schermata iniziale di Claude Code
run "kubectl exec --namespace $NS deploy/ws-local -c ide -- tmux capture-pane -p -t kube-coder-$TASK_ID | grep -v '^\s*\$' | head -15"
run "curl -s -u admin:admin -H 'Host: $HOSTNAME_WS' -X DELETE $API/$TASK_ID | jq '{task_id, status}'"
# i permessi del service account del workspace (par. 2.17)
SA=system:serviceaccount:$NS:ws-local
run kubectl auth can-i create jobs --namespace $NS --as=$SA
run kubectl auth can-i create cronjobs --namespace $NS --as=$SA
run "kubectl auth can-i create jobs --namespace default --as=$SA || true"
run "kubectl auth can-i list nodes --as=$SA || true"
pausa

# --- 3.8 Stato persistente, sospensione e isolamento -----------------------------
run "kubectl exec --namespace $NS deploy/ws-local -c ide -- bash -c 'echo \"progetto creato il \$(date)\" > /home/dev/NOTE.txt'"
OLD_POD=$(kubectl get pod --namespace $NS -l app=ws-local -o jsonpath='{.items[0].metadata.name}')
run kubectl delete pod --namespace $NS $OLD_POD
run kubectl wait --for=condition=Ready pod --namespace $NS -l app=ws-local --timeout=5m
run kubectl get pod --namespace $NS -l app=ws-local
run "kubectl exec --namespace $NS deploy/ws-local -c ide -- cat /home/dev/NOTE.txt"
# "Stop" del workspace: zero repliche, il volume resta
run kubectl scale deployment ws-local --namespace $NS --replicas=0
run "kubectl wait --for=delete pod --namespace $NS -l app=ws-local --timeout=120s || true"
run kubectl get deployment,pvc --namespace $NS
run kubectl scale deployment ws-local --namespace $NS --replicas=1
run kubectl rollout status deployment/ws-local --namespace $NS --timeout=5m
pausa
# La NetworkPolicy ammette traffico verso il workspace solo dal namespace ingress-nginx...
curl_pod
run "kubectl exec curl -- curl -s -o /dev/null -m 5 -w '%{http_code}\n' http://ws-local.$NS:6080/health || true"
# ...ma Flannel non applica le NetworkPolicy: la richiesta da "default" passa comunque
run "kubectl get pods --namespace kube-flannel -o wide | head -3"

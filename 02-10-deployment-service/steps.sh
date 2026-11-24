#!/usr/bin/env bash
# Par. 2.10 - Deployment e service
source "$(dirname "$0")/../lib.sh"; cd "$(dirname "$0")"

# generazione dello scheletro del manifest (non crea nulla sul cluster)
run "kubectl create deployment test-deploy-1 --image=nginx:1.29 --image=debian:13 --dry-run=client --output yaml > /tmp/test-deploy-1-generato.yml"
run cat /tmp/test-deploy-1-generato.yml
pausa
# manifest completo (volume condiviso + comando del writer)
run kubectl create -f test-deploy-1.yml
run kubectl rollout status deployment/test-deploy-1 --timeout=180s
run kubectl get deployments -o wide
run kubectl get pods -o wide
pausa
run kubectl scale --replicas=2 deployment/test-deploy-1
run kubectl rollout status deployment/test-deploy-1 --timeout=180s
run kubectl get pods -o wide
POD=$(kubectl get pods -l app=test-deploy-1 -o jsonpath='{.items[0].metadata.name}')
run kubectl logs $POD -c web --tail=3
run "kubectl exec $POD --container web -- /bin/cat /usr/share/nginx/html/index.html | tail -n 3"
run "kubectl exec $POD --container writer -- /bin/cat /html/index.html | tail -n 3"
pausa
# service NodePort
run kubectl expose deployment test-deploy-1 --name myservice --type=NodePort --port=80
run kubectl describe service myservice
sleep 5   # lasciamo a kube-proxy il tempo di programmare le regole sui nodi
run kubectl get endpointslices -l kubernetes.io/service-name=myservice
NODEPORT=$(kubectl get svc myservice -o jsonpath='{.spec.ports[0].nodePort}')
NODE2_IP=$(kubectl get node $NODE2 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
# dal nodo control plane, verso un altro nodo sulla NodePort
run "docker exec $NODE1 curl -s http://$NODE2_IP:$NODEPORT | tail -n 2"
# da un pod, usando il nome DNS del service
curl_pod
run "kubectl exec curl -- sh -c 'curl -s http://myservice | tail -n 2'"
pausa
# service LoadBalancer: senza un cloud provider l'EXTERNAL-IP resta <pending>
run kubectl expose deployment test-deploy-1 --name myservicelb --type=LoadBalancer --port=80
sleep 5
run kubectl get services
pausa
# variante con sidecar nativo
run kubectl apply -f test-deploy-1-sidecar.yml
run kubectl rollout status deployment/test-deploy-sidecar --timeout=180s
run kubectl get pods -l app=test-deploy-sidecar
run "kubectl get pod -l app=test-deploy-sidecar -o jsonpath='{range .items[0].status.initContainerStatuses[*]}{.name}{\" started=\"}{.started}{\" ready=\"}{.ready}{\"\\n\"}{end}'"
pausa
# pulizia
run kubectl delete service myservice myservicelb
run kubectl delete deployment test-deploy-1 test-deploy-sidecar

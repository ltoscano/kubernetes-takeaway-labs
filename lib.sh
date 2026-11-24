# Funzioni comuni ai laboratori di Kubernetes TakeAway, seconda edizione
# Uso: source ../lib.sh  (ogni steps.sh lo fa automaticamente)
set -euo pipefail
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
kubectl config use-context kind-takeaway >/dev/null 2>&1 || true

# Nomi dei nodi del cluster kind (corrispondono a node1, node2, node3 della prima edizione)
NODE1=takeaway-control-plane
NODE2=takeaway-worker
NODE3=takeaway-worker2

# run: stampa il comando come nel libro ("$ comando") e lo esegue
run() { printf '\n$ %s\n' "$*"; eval "$@"; }
# pausa: attende INVIO se la sessione è interattiva (STEP=1 ./steps.sh), altrimenti prosegue
pausa() { if [[ "${STEP:-0}" == "1" ]]; then read -r -p "-- INVIO per continuare --" _; fi; }
# watch_for: equivalente non interattivo di "kubectl get ... --watch" per N secondi
watch_for() { local secs=$1; shift; printf '\n$ %s --watch   (interrotto dopo %ss)\n' "$*" "$secs"; eval "$* --watch --request-timeout=${secs}s" || true; }
# curl_pod: pod di appoggio con curl, sempre attivo, da usare con "kubectl exec curl -- ..."
curl_pod() {
  if ! kubectl get pod curl >/dev/null 2>&1; then
    run kubectl run curl --image=curlimages/curl:8.17.0 --restart=Never --command -- sleep infinity
  fi
  kubectl wait --for=condition=Ready pod/curl --timeout=120s >/dev/null
}

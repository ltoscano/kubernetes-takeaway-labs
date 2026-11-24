#!/usr/bin/env bash
# Esegue in sequenza TUTTI i laboratori del libro su un cluster kind nuovo e salva i log in ./logs
# Uso:  ./run-all.sh            (non interattivo, ~35 minuti)
#       STEP=1 ./run-all.sh     (si ferma dopo ogni blocco di comandi e attende INVIO)
#       FROM=02-12-namespace-quote ./run-all.sh   (riprende da un laboratorio, su un cluster già creato)
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p logs
SKIP="${FROM:+1}"
lab() {
  local name=$1; shift
  if [[ -n "$SKIP" && "$name" != "$FROM" ]]; then return 0; fi
  SKIP=""
  echo "=================== $name ==================="
  "$@" 2>&1 | tee "logs/$name.log"
}

lab 02-02-create-cluster   ./02-02-setup/create-cluster.sh
lab 02-05-flannel          ./02-05-cni/install-flannel.sh
lab 02-04-init             ./02-04-init/steps.sh
lab 02-07-rete             ./02-07-rete/steps.sh
lab 02-08-manifest         ./02-08-manifest/steps.sh
lab 02-09-pod              ./02-09-pod/steps.sh
lab 02-10-deployment       ./02-10-deployment-service/steps.sh
lab 02-11-ingress          ./02-11-ingress/steps.sh
lab 02-11-gateway-api      ./02-11-ingress/gateway-api/steps.sh
lab 02-12-namespace-quote  ./02-12-namespace-quote/steps.sh
lab 02-13-configmap-secret ./02-13-configmap-secret/steps.sh
lab 02-14-job-cronjob      ./02-14-job-cronjob/steps.sh
lab 02-15-helm             ./02-15-helm/steps.sh
lab 02-16-metrics-server   ./02-16-monitoring/steps-metrics-server.sh
lab 02-16-prometheus       ./02-16-monitoring/steps-prometheus-grafana.sh
lab 02-17-headlamp-rbac    ./02-17-headlamp-rbac/steps.sh
lab 02-18-scheduling       ./02-18-scheduling/steps.sh
lab 02-19-hpa              ./02-19-hpa/steps.sh
lab 02-20-rollout          ./02-20-rollout/steps.sh
echo "Tutti i laboratori completati. Per eliminare il cluster: ./02-02-setup/delete-cluster.sh"

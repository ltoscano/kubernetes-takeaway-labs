#!/usr/bin/env bash
# Par. 2.15 - Helm: il gestore di pacchetti (richiede helm già installato, vedi install-helm.sh)
source "$(dirname "$0")/../lib.sh"; cd "$(dirname "$0")"

run helm version
run helm repo add podinfo https://stefanprodan.github.io/podinfo
run helm repo update
run "helm search repo podinfo"
run "helm search hub podinfo --max-col-width 60 | head -n 4"
pausa
run helm install mypodinfo podinfo/podinfo --wait
run helm list
run kubectl get deployment,service mypodinfo
pausa
run helm upgrade mypodinfo podinfo/podinfo --set replicaCount=2 --wait
run helm history mypodinfo
run helm rollback mypodinfo 1 --wait
run kubectl get deployment mypodinfo
pausa
run helm uninstall mypodinfo

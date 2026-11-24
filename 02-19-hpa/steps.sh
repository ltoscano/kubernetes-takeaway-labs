#!/usr/bin/env bash
# Par. 2.19 - Scaling orizzontale automatico dei pod (richiede metrics-server, par. 2.16.3)
source "$(dirname "$0")/../lib.sh"; cd "$(dirname "$0")"

run kubectl apply -f my-nginx.yaml
run kubectl rollout status deployment/my-nginx --timeout=120s
run kubectl apply -f hpa-my-nginx.yaml
sleep 45
run kubectl get hpa my-nginx
run kubectl describe hpa my-nginx
pausa
# generatore di carico: 2 pod che interrogano il service in un ciclo infinito
run kubectl apply -f load-generator.yaml
watch_for 150 kubectl get hpa my-nginx
run kubectl get deployment my-nginx
pausa
run kubectl delete -f load-generator.yaml
watch_for 150 kubectl get hpa my-nginx
pausa
run kubectl delete -f hpa-my-nginx.yaml -f my-nginx.yaml

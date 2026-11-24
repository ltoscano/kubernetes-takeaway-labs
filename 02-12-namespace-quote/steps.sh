#!/usr/bin/env bash
# Par. 2.12 - Namespace e quote
source "$(dirname "$0")/../lib.sh"; cd "$(dirname "$0")"

run kubectl create namespace development
run kubectl create namespace production
run kubectl create quota dev-quota --hard=limits.memory=1Gi,requests.memory=896Mi,limits.cpu=1000m,requests.cpu=500m,pods=2 --namespace development
run kubectl describe quota dev-quota --namespace development
pausa
run kubectl apply -f nginx-dev.yaml
run kubectl describe quota dev-quota --namespace development
pausa
run "kubectl apply -f nginx2-troppa-memoria.yaml || true"
pausa
run kubectl create -f ./default-development.yaml --namespace=development
run kubectl describe limits default-development --namespace development
run kubectl run nginx2 --image=nginx:1.29 --namespace development
run "kubectl get pod nginx2 --namespace development -o jsonpath='{.spec.containers[0].resources}'; echo"
run kubectl describe quota dev-quota --namespace development
run "kubectl run nginx3 --image=nginx:1.29 --namespace development || true"
pausa
run kubectl delete namespace development production

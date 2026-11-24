#!/usr/bin/env bash
# Par. 2.13 - Configurazioni e Secrets
source "$(dirname "$0")/../lib.sh"; cd "$(dirname "$0")"

run kubectl create configmap my-config --from-literal=mykey1=myvalue1 --from-literal=mykey2=myvalue2
run kubectl get configmap my-config -o yaml
run kubectl apply -f test-pod-configmap.yaml
run kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/test-pod-configmap --timeout=120s
run "kubectl logs test-pod-configmap | grep -E '^(HOME|HOSTNAME|mykey)'"
pausa
run kubectl create secret generic my-secret --from-literal user=admin --from-literal password=1234
run kubectl get secret my-secret -o yaml
run "kubectl get secret my-secret -o jsonpath='{.data.password}' | base64 --decode; echo"
run kubectl apply -f test-pod-secret.yaml
run kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/test-pod-secret --timeout=120s
run "kubectl logs test-pod-secret | grep -E '^(HOME|user|password)'"
run kubectl apply -f test-pod-secret-volume.yaml
run kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/test-pod-secret-volume --timeout=120s
run kubectl logs test-pod-secret-volume
pausa
run kubectl delete pod test-pod-configmap test-pod-secret test-pod-secret-volume
run kubectl delete configmap my-config
run kubectl delete secret my-secret

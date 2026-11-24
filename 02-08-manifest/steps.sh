#!/usr/bin/env bash
# Par. 2.8 - Approccio generale alla configurazione (manifest, apply, taint)
source "$(dirname "$0")/../lib.sh"; cd "$(dirname "$0")"

run kubectl apply -f nginx-deployment.yaml
run kubectl rollout status deployment/nginx-deployment --timeout=180s
run kubectl get deployment nginx-deployment
run kubectl get pods -o wide
pausa
# riduzione a 2 repliche: modifichiamo il file e lo riapplichiamo
sed 's/replicas: 3/replicas: 2/' nginx-deployment.yaml > /tmp/nginx-deployment-2.yaml
run kubectl apply -f /tmp/nginx-deployment-2.yaml
run kubectl rollout status deployment/nginx-deployment --timeout=120s
run kubectl get deployment nginx-deployment
pausa
# taint del nodo control plane
run "kubectl describe node $NODE1 | grep Taints"
# Esempio di taint e toleration su un nodo worker (poi lo rimuoviamo)
run kubectl taint nodes $NODE3 bar:NoSchedule
run "kubectl describe node $NODE3 | grep Taints"
run kubectl taint nodes $NODE3 bar:NoSchedule-
pausa
# pulizia
run kubectl delete -f nginx-deployment.yaml

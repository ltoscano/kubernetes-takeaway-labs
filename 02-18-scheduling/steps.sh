#!/usr/bin/env bash
# Par. 2.18 - Pianificazione tramite taint, selettori e affinità
source "$(dirname "$0")/../lib.sh"; cd "$(dirname "$0")"

# 1) taint + toleration
run kubectl taint node $NODE2 sku=gpu:NoSchedule
run kubectl label node $NODE2 sku=gpu
run kubectl apply -f pod-toleration.yaml
run kubectl wait --for=condition=Ready pod/tf-mnist-toleration --timeout=120s
run kubectl get pod tf-mnist-toleration -o wide
pausa
# 2) nodeSelector: senza nodi etichettati il pod resta Pending
run kubectl apply -f pod-nodeselector.yaml
sleep 5
run kubectl get pod tf-mnist-nodeselector
run "kubectl describe pod tf-mnist-nodeselector | sed -n '/^Events:/,\$p'"
run kubectl label node $NODE3 hardware=highmem
run kubectl wait --for=condition=Ready pod/tf-mnist-nodeselector --timeout=120s
run kubectl get pod tf-mnist-nodeselector -o wide
pausa
# 3) nodeAffinity
run kubectl apply -f pod-nodeaffinity.yaml
run kubectl wait --for=condition=Ready pod/tf-mnist-nodeaffinity --timeout=120s
run kubectl get pod tf-mnist-nodeaffinity -o wide
pausa
# 4) podAffinity / podAntiAffinity (rimuoviamo il taint perché servono entrambi i worker)
run kubectl taint node $NODE2 sku=gpu:NoSchedule-
run kubectl apply -f cache.yaml
run kubectl rollout status deployment/cache --timeout=180s
run kubectl apply -f web-server.yaml
run kubectl rollout status deployment/web-server --timeout=180s
run "kubectl get pods -l 'app in (cache,webstore)' -o wide --sort-by=.spec.nodeName | awk '{print \$1, \$3, \$7}' | column -t"
pausa
# 5) cordon: nessun nuovo pod sul nodo
run kubectl cordon $NODE3
run kubectl get nodes
run kubectl uncordon $NODE3
pausa
run kubectl delete -f pod-toleration.yaml -f pod-nodeselector.yaml -f pod-nodeaffinity.yaml -f web-server.yaml -f cache.yaml
run kubectl label node $NODE3 hardware-
run kubectl label node $NODE2 sku-

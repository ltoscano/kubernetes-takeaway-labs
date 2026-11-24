#!/usr/bin/env bash
# Par. 2.7 - Configurazione di rete (Flannel, pause container, service di sistema)
source "$(dirname "$0")/../lib.sh"

run kubectl get pods --namespace kube-flannel -o wide
run "kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}'; echo"
# rotte e configurazione Flannel su un nodo worker (shell del nodo con docker exec)
run docker exec $NODE2 ip route
run docker exec $NODE2 cat /run/flannel/subnet.env
run "docker exec $NODE2 ethtool -i flannel.1 | head -n 2"
run "docker exec $NODE2 ip -d link show flannel.1 | grep -o 'vxlan id [0-9]* .*dstport [0-9]*'"
run "docker exec $NODE2 ss -ulpn | grep 8472"
pausa
# container pause (sandbox) visti dal runtime containerd
run docker exec $NODE2 crictl pods
run "docker exec $NODE2 crictl images | grep -E 'IMAGE|pause'"
pausa
run kubectl get service --all-namespaces
run kubectl describe service kubernetes
run kubectl get endpointslices --namespace default
pausa
# Cambio del backend Flannel da vxlan a host-gw (i nodi kind sono sulla stessa rete L2).
# Necessario su Docker Desktop per raggiungere le NodePort dal tuo computer (par. 2.11).
run "kubectl get configmap kube-flannel-cfg -n kube-flannel -o jsonpath='{.data.net-conf\.json}'; echo"
kubectl get configmap kube-flannel-cfg -n kube-flannel -o json \
  | jq '.data["net-conf.json"] |= (fromjson | .Backend = {"Type":"host-gw"} | tojson)' \
  | kubectl apply -f -
run kubectl rollout restart daemonset/kube-flannel-ds --namespace kube-flannel
run kubectl rollout status daemonset/kube-flannel-ds --namespace kube-flannel --timeout=180s
sleep 5
run docker exec $NODE2 ip route

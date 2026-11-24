#!/usr/bin/env bash
# Par. 2.16.3 - Aggregatori: metrics-server (Metrics API) e accesso alle metriche del kubelet
source "$(dirname "$0")/../lib.sh"; cd "$(dirname "$0")"

run helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
run helm repo update metrics-server
# --kubelet-insecure-tls: SOLO per il laboratorio (i certificati dei kubelet di kind non sono firmati dalla CA del cluster)
run "helm upgrade --install metrics-server metrics-server/metrics-server --namespace kube-system --set 'args={--kubelet-insecure-tls}' --wait"
run kubectl wait --for=condition=Available apiservice/v1beta1.metrics.k8s.io --timeout=180s
run "kubectl api-versions | grep metrics"
run kubectl get apiservices v1beta1.metrics.k8s.io
sleep 30   # il primo campionamento richiede qualche decina di secondi
run "kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes | jq '.items[] | {name: .metadata.name, usage: .usage}'"
run kubectl top node
run "kubectl top pods --all-namespaces --sort-by=memory | head -n 6"
run "kubectl top pod -n kube-system -l k8s-app=kube-dns --containers"
pausa
# Le metriche grezze del kubelet (cAdvisor) attraverso il proxy del kube-apiserver
run "kubectl get --raw /api/v1/nodes/$NODE2/proxy/metrics/cadvisor | grep '^container_memory_working_set_bytes' | head -n 3"
run "kubectl get --raw /api/v1/nodes/$NODE2/proxy/stats/summary | jq '.node | {nodeName, cpu: .cpu.usageNanoCores, memory: .memory.workingSetBytes}'"

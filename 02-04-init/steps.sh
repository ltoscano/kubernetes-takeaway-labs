#!/usr/bin/env bash
# Par. 2.3-2.4 - Analisi dell'inizializzazione del cluster (eseguito da kind con kubeadm)
source "$(dirname "$0")/../lib.sh"

run kubectl version
run kubectl get nodes -o wide
# la configurazione kubeadm generata da kind (equivale ai parametri di "kubeadm init")
run "docker exec $NODE1 grep -E 'kind:|kubernetesVersion|podSubnet|serviceSubnet|advertiseAddress' /kind/kubeadm.conf"
# i manifest dei pod statici letti dal kubelet del control plane
run docker exec $NODE1 ls /etc/kubernetes/manifests
run kubectl get namespaces
run kubectl get pods --namespace kube-system -o wide
run kubectl get daemonset --namespace kube-system

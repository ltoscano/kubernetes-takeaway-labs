#!/usr/bin/env bash
# Par. 2.5 - Installazione del plug-in di rete Flannel (backend VXLAN, pod network 10.244.0.0/16)
set -euo pipefail
FLANNEL_VERSION="${FLANNEL_VERSION:-v0.28.11}"
kubectl apply -f "https://github.com/flannel-io/flannel/releases/download/${FLANNEL_VERSION}/kube-flannel.yml"
kubectl -n kube-flannel rollout status daemonset/kube-flannel-ds --timeout=180s
kubectl wait --for=condition=Ready nodes --all --timeout=180s
kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide

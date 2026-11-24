#!/usr/bin/env bash
# Rimuove kube-coder e ingress-nginx dal cluster (il cluster resta)
source "$(dirname "$0")/../lib.sh"; cd "$(dirname "$0")"
run "helm uninstall ws-local --namespace ws-local || true"
run "helm uninstall base-infrastructure --namespace ws-local || true"
# il chart protegge il volume persistente (helm.sh/resource-policy: keep): va eliminato a mano
run "kubectl delete namespace ws-local --ignore-not-found"
run "helm uninstall ingress-nginx --namespace ingress-nginx || true"
run "kubectl delete namespace ingress-nginx --ignore-not-found"
echo "Per eliminare anche i sorgenti e l'immagine: rm -rf kube-coder && docker image rm kube-coder:local"

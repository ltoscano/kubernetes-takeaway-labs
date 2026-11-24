#!/usr/bin/env bash
# Par. 3.3 - Ingress controller richiesto da kube-coder (ingress-nginx)
# Il chart di kube-coder usa le annotation di ingress-nginx (autenticazione basic,
# timeout dei WebSocket): installiamo quindi l'ultima versione rilasciata del
# controller (v1.15.1, marzo 2026) accanto a HAProxy, con la sua IngressClass "nginx".
source "$(dirname "$0")/../lib.sh"; cd "$(dirname "$0")"

run helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx --version 4.15.1 \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=ClusterIP \
  --set controller.ingressClassResource.default=false \
  --wait --timeout 5m
run kubectl get ingressclass
run kubectl get pods,services --namespace ingress-nginx

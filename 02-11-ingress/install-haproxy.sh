#!/usr/bin/env bash
# Par. 2.11 - Installazione dell'HAProxy Kubernetes Ingress Controller con Helm.
# Il service del controller è di tipo NodePort con porte fisse 30080 (http) e 30443 (https):
# nel file kind-takeaway.yaml queste porte del nodo sono pubblicate su localhost del tuo computer.
set -euo pipefail
helm repo add haproxytech https://haproxytech.github.io/helm-charts
helm repo update haproxytech
helm upgrade --install haproxy-kubernetes-ingress haproxytech/kubernetes-ingress \
  --namespace haproxy-controller --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30080 \
  --set controller.service.nodePorts.https=30443 \
  --set controller.service.nodePorts.stat=30024 \
  --set controller.ingressClassResource.default=true \
  --wait --timeout 5m

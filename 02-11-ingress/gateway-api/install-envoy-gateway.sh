#!/usr/bin/env bash
# Par. 2.11 (riquadro Gateway API) - Installa Envoy Gateway, una implementazione conforme della Gateway API.
# Il chart installa anche le CRD standard della Gateway API (GatewayClass, Gateway, HTTPRoute, ...).
set -euo pipefail
EG_VERSION="${EG_VERSION:-v1.10.0}"
helm upgrade --install eg oci://docker.io/envoyproxy/gateway-helm --version "${EG_VERSION}" \
  --namespace envoy-gateway-system --create-namespace --wait --timeout 5m
kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available

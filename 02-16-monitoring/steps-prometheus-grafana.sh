#!/usr/bin/env bash
# Par. 2.16.3-2.16.5 - kube-state-metrics, Prometheus e Grafana con il chart kube-prometheus-stack
source "$(dirname "$0")/../lib.sh"; cd "$(dirname "$0")"

run helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
run helm repo update prometheus-community
run helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --wait --timeout 10m
run kubectl get pods --namespace monitoring
run kubectl get services --namespace monitoring
pausa
# kube-state-metrics: interroghiamo l'endpoint /metrics da un pod temporaneo
curl_pod
run "kubectl exec curl -- sh -c 'curl -s http://prometheus-kube-state-metrics.monitoring:8080/metrics | grep ^kube_deployment_status_replicas_available'"
pausa
# Prometheus: port-forward e una query PromQL tramite HTTP API
kubectl port-forward --namespace monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 >/dev/null 2>&1 &
PF=$!; sleep 90   # Prometheus ha bisogno di qualche campione per calcolare rate()
run "curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=rate(node_network_receive_packets_total{device=\"eth0\"}[1m])' | jq -r '.data.result[] | \"\(.metric.instance)  \(.value[1])\"'"
run "curl -s 'http://localhost:9090/api/v1/targets?state=active' | jq -r '.data.activeTargets[].labels.job' | sort | uniq -c"
kill $PF 2>/dev/null; wait $PF 2>/dev/null || true
pausa
# Grafana: password dell'utente admin
run "kubectl get secret --namespace monitoring prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 --decode ; echo"
run "kubectl get configmaps -n monitoring -l grafana_dashboard=1 --no-headers | wc -l"
echo "Per aprire Grafana:     kubectl port-forward --namespace monitoring svc/prometheus-grafana 3000:80     -> http://localhost:3000"
echo "Per aprire Prometheus:  kubectl port-forward --namespace monitoring svc/prometheus-kube-prometheus-prometheus 9090 -> http://localhost:9090"

#!/usr/bin/env bash
# Par. 2.11 - Dalla risorsa Ingress alla Gateway API (richiede i service del par. 2.11 già creati)
source "$(dirname "$0")/../../lib.sh"; cd "$(dirname "$0")"

run ./install-envoy-gateway.sh
run kubectl apply -f gateway-foo-bar.yml
run kubectl wait --for=condition=Accepted gateway/foo-bar-gateway --timeout=180s
# il deployment di Envoy per il Gateway viene creato da Envoy Gateway qualche secondo dopo
until kubectl get deployment -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-name=foo-bar-gateway -o name | grep -q .; do sleep 2; done
run kubectl wait --for=condition=Available deployment -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-name=foo-bar-gateway --timeout=180s
run kubectl get gatewayclass,gateway,httproute
# Programmed=False/AddressNotAssigned: nel laboratorio non c'è un load balancer che assegni un indirizzo esterno
run "kubectl get gateway foo-bar-gateway -o jsonpath='{range .status.conditions[*]}{.type}={.status} ({.reason}){\"\\n\"}{end}'"
# Il Gateway ottiene un service LoadBalancer: senza cloud provider resta <pending>, quindi
# lo invochiamo dall'interno del cluster usando il suo ClusterIP.
GW_SVC=$(kubectl get svc -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-name=foo-bar-gateway -o jsonpath='{.items[0].metadata.name}')
run kubectl get svc -n envoy-gateway-system $GW_SVC
GW_IP=$(kubectl get svc -n envoy-gateway-system $GW_SVC -o jsonpath='{.spec.clusterIP}')
sleep 10   # tempo per la propagazione della configurazione a Envoy
curl_pod
run "kubectl exec curl -- sh -c 'curl -s -H \"Host: foo.bar\" http://$GW_IP/hello | grep Hostname; curl -s -H \"Host: foo.bar\" http://$GW_IP/getdate | tail -n 1'"
pausa
run kubectl delete -f gateway-foo-bar.yml
run helm uninstall eg --namespace envoy-gateway-system

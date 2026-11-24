#!/usr/bin/env bash
# Par. 2.11 - Configurazione Ingress controller (HAProxy)
source "$(dirname "$0")/../lib.sh"; cd "$(dirname "$0")"

run ./install-haproxy.sh
run kubectl get pods,services --namespace haproxy-controller
run kubectl get ingressclass
pausa
run kubectl apply -f test-deploy-1.yml -f test-2-deploy.yml
run kubectl rollout status deployment/test-deploy-1 --timeout=180s
run kubectl rollout status deployment/test-2-deploy --timeout=180s
run kubectl apply -f test-ing-myservices.yml
run kubectl apply -f test-ing-rules.yml
sleep 10   # tempo per la riconfigurazione di HAProxy
run kubectl get ingress
run kubectl describe ingress test-ing-rules
pausa
# test dal tuo computer (porta 30080 pubblicata da kind).
# NB: richiede il backend Flannel host-gw impostato al par. 2.7 (02-07-rete/steps.sh)
run "curl -s -H 'Host: foo.bar' http://localhost:30080/hello | grep Hostname"
run "curl -s -H 'Host: foo.bar' http://localhost:30080/getdate | tail -n 2"
run "curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: altro.host' http://localhost:30080/hello"
pausa
# Le risorse di questo paragrafo (test-deploy-1, test-2-deploy, myserviceing1/2) restano attive:
# servono all'esempio Gateway API (gateway-api/steps.sh). Per rimuoverle:
#   kubectl delete -f test-ing-rules.yml -f test-ing-myservices.yml -f test-2-deploy.yml -f test-deploy-1.yml

#!/usr/bin/env bash
# Par. 2.20 - Strategie di aggiornamento di un'applicazione
source "$(dirname "$0")/../lib.sh"; cd "$(dirname "$0")"

run kubectl apply -f nginx-deployment.yaml
run kubectl rollout status deployment/nginx-deployment --timeout=120s
run "kubectl describe deployment nginx-deployment | grep -E 'StrategyType|RollingUpdateStrategy|Image:'"
pausa
# aggiornamento dell'immagine + motivazione registrata nella cronologia
run kubectl set image deployment/nginx-deployment nginx=nginx:1.29
run "kubectl annotate deployment/nginx-deployment kubernetes.io/change-cause='aggiornamento a nginx 1.29'"
run kubectl rollout status deployment/nginx-deployment --timeout=180s
run kubectl rollout history deployment/nginx-deployment
run kubectl rollout history deployment/nginx-deployment --revision=2
run "kubectl describe deployment/nginx-deployment | grep 'Image:'"
pausa
run kubectl rollout pause deployment/nginx-deployment
run kubectl rollout resume deployment/nginx-deployment
pausa
# rollback alla revisione 1
run kubectl rollout undo deployment/nginx-deployment --to-revision=1
run kubectl rollout status deployment/nginx-deployment --timeout=180s
run kubectl rollout history deployment/nginx-deployment
run "kubectl describe deployment/nginx-deployment | grep 'Image:'"
pausa
# strategia Recreate
run "kubectl patch deployment nginx-deployment -p '{\"spec\":{\"strategy\":{\"type\":\"Recreate\",\"rollingUpdate\":null}}}'"
run kubectl set image deployment/nginx-deployment nginx=nginx:1.29
run kubectl rollout status deployment/nginx-deployment --timeout=180s
run "kubectl describe deployment nginx-deployment | grep -E 'StrategyType|Image:'"
pausa
# blue/green
run kubectl apply -f blue-green.yaml
run kubectl rollout status deployment/my-nginx-app-blue --timeout=120s
run kubectl rollout status deployment/my-nginx-app-green --timeout=120s
sleep 5
curl_pod
run "kubectl exec curl -- sh -c 'curl -s http://my-inbound-service | grep Name'"
run "kubectl patch service my-inbound-service -p '{\"spec\":{\"selector\":{\"app\":\"my-nginx-app\",\"version\":\"green\"}}}'"
curl_pod
run "kubectl exec curl -- sh -c 'curl -s http://my-inbound-service | grep Name'"
pausa
run kubectl delete -f blue-green.yaml -f nginx-deployment.yaml

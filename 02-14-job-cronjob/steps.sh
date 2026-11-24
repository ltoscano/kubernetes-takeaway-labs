#!/usr/bin/env bash
# Par. 2.14 - Job e CronJob
source "$(dirname "$0")/../lib.sh"; cd "$(dirname "$0")"

run kubectl apply -f test-job-countdown.yaml
run kubectl wait --for=condition=Complete job/test-job-countdown --timeout=180s
run kubectl get jobs
run kubectl get pods -l job-name=test-job-countdown
POD=$(kubectl get pods -l job-name=test-job-countdown -o jsonpath='{.items[0].metadata.name}')
run "kubectl logs $POD | head -n 3"
run kubectl delete job test-job-countdown
pausa
run kubectl apply -f test-cronjob-countdown.yaml
run kubectl get cronjobs
watch_for 150 kubectl get pods -l job-name
run kubectl get jobs
pausa
run kubectl delete cronjob test-cronjob-countdown

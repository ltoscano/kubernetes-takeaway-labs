#!/usr/bin/env bash
# Par. 2.17 - Interfaccia web (Headlamp) e autenticazione RBAC
source "$(dirname "$0")/../lib.sh"; cd "$(dirname "$0")"

run helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
run helm repo update headlamp
run helm upgrade --install my-headlamp headlamp/headlamp --namespace kube-system --wait
run kubectl get deployment,service my-headlamp --namespace kube-system
pausa
run kubectl apply -f admin-user.yaml -f viewer-user.yaml
# token a breve scadenza (non più Secret creati automaticamente, da Kubernetes 1.24)
run "kubectl create token admin-user --namespace kube-system --duration=1h | cut -c1-40; echo '...'"
pausa
# Verifica delle autorizzazioni RBAC
run kubectl auth can-i delete pods --all-namespaces --as=system:serviceaccount:kube-system:admin-user
run kubectl auth can-i list pods --all-namespaces --as=system:serviceaccount:kube-system:viewer-user
run "kubectl auth can-i delete pods --all-namespaces --as=system:serviceaccount:kube-system:viewer-user || true"
run "kubectl auth can-i get secrets --namespace default --as=system:serviceaccount:kube-system:viewer-user || true"
echo
echo "Apri Headlamp con:  kubectl port-forward --namespace kube-system svc/my-headlamp 4466:80   -> http://localhost:4466"
echo "e usa il token di admin-user (kubectl create token admin-user -n kube-system) oppure di viewer-user."

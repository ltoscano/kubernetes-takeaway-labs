#!/usr/bin/env bash
# Par. 2.9 - Pod e ciclo di vita dei pod (approccio imperativo con kubectl run)
source "$(dirname "$0")/../lib.sh"; cd "$(dirname "$0")"

# 1) pod che termina con successo (exit 0) dopo 30 secondi
run "kubectl run busybox --image=busybox:1.37 --restart=OnFailure --env=exitCode=0 -- sh -c 'sleep 30 && exit \$exitCode'"
watch_for 45 kubectl get pods busybox
run kubectl get pod busybox -o wide
# 2) stesso nome: errore AlreadyExists
run "kubectl run busybox --image=busybox:1.37 --restart=OnFailure --env=exitCode=1 -- sh -c 'sleep 30 && exit \$exitCode' || true"
run "kubectl describe pod busybox | sed -n '/^Events:/,\$p'"
pausa
# 3) cancelliamo e ricreiamo il pod con codice di uscita 1 (fallimento)
run kubectl delete pod busybox
run "kubectl run busybox --image=busybox:1.37 --restart=OnFailure --env=exitCode=1 -- sh -c 'sleep 30 && exit \$exitCode'"
watch_for 100 kubectl get pods busybox
run "kubectl describe pod busybox | grep -E 'BackOff|Restart Count|Last State|Exit Code' || true"
pausa
run kubectl delete pod busybox --now

#!/usr/bin/env bash
# Par. 2.2-2.3 - Crea il cluster di laboratorio "takeaway" (1 control plane + 2 worker) con kind.
# Requisiti: Docker (Desktop o Engine) con almeno 4 CPU e 6 GB di RAM, kind >= 0.33, kubectl >= 1.36.
set -euo pipefail
cd "$(dirname "$0")"

kind create cluster --config kind-takeaway.yaml

# I nodi kind includono solo alcuni plug-in CNI di base (host-local, loopback, portmap, ptp).
# Flannel delega la configurazione dell'interfaccia del pod al plug-in "bridge": lo aggiungiamo su ogni nodo.
CNI_VERSION="${CNI_VERSION:-v1.10.0}"
for node in $(kind get nodes --name takeaway); do
  echo ">> installo il plug-in CNI bridge ${CNI_VERSION} su ${node}"
  docker exec "${node}" sh -c "ARCH=\$(dpkg --print-architecture); \
    curl -sSL https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-\${ARCH}-${CNI_VERSION}.tgz \
    | tar -xz -C /opt/cni/bin ./bridge"
done

kubectl get nodes -o wide
echo "Cluster creato. I nodi resteranno NotReady finché non installi il plug-in di rete (02-05-cni/install-flannel.sh)."

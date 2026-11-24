#!/usr/bin/env bash
# Par. 2.15 - Installazione di Helm 4 con lo script ufficiale (Linux/macOS).
# Alternative: "brew install helm" (macOS), "winget install Helm.Helm" (Windows).
set -euo pipefail
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
less get_helm.sh   # buona pratica: leggi lo script prima di eseguirlo (q per uscire)
./get_helm.sh
helm version

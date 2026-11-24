# Kubernetes TakeAway – Laboratori della seconda edizione

Script e manifest che accompagnano il libro **Kubernetes TakeAway – Implementa i cluster K8s come un
professionista** (The Good Programmer), seconda edizione, aggiornata a **Kubernetes 1.37**.

Il repository contiene tutti i passaggi pratici del libro, verificati su un cluster reale a tre nodi
creato con [kind](https://kind.sigs.k8s.io) sul proprio computer:

- **Parte 2 – Attività pratica**: una cartella per ogni paragrafo, dalla creazione del cluster (2.2) alle
  strategie di aggiornamento (2.20);
- **Parte 3 – Capitolo speciale: Kubernetes e gli agenti AI**: installazione di
  [kube-coder](https://github.com/imran31415/kube-coder) sul cluster di laboratorio.

Ogni cartella contiene i manifest YAML del paragrafo e uno script (`steps.sh`) che esegue i comandi
nello stesso ordine del testo, stampandoli preceduti da `$`. La cartella `logs/` contiene l'output
dell'ultima esecuzione completa, utile per confrontare i risultati.

Il consiglio è di seguire il libro digitando i comandi a mano almeno la prima volta, e di usare gli
script per verificare, recuperare un passaggio o ripartire da un punto preciso.

## Come iniziare

```bash
git clone https://github.com/ltoscano/kubernetes-takeaway-labs.git
cd kubernetes-takeaway-labs
```

## Prerequisiti

| Strumento | Versione verificata | Note |
|---|---|---|
| Docker (Desktop o Engine) | 29.9 | almeno 4 CPU e 6 GB di RAM assegnati (8 GB consigliati per il par. 2.16) |
| kind | 0.33.0 | `brew install kind` / `winget install Kubernetes.kind` |
| kubectl | 1.36 o 1.37 | deve differire al massimo di una minor dal cluster (1.37) |
| Helm | 4.3.2 | dal par. 2.11 |
| curl, jq | qualsiasi | |

Gli script sono per `bash` (Linux, macOS, WSL2 su Windows).

## Uso

```bash
./02-02-setup/create-cluster.sh        # cluster "takeaway": 1 control plane + 2 worker
./02-05-cni/install-flannel.sh         # plug-in di rete
./02-07-rete/steps.sh                  # analisi della rete e passaggio di Flannel a host-gw
./02-08-manifest/steps.sh              # ... e così via, nell'ordine del libro
```

oppure tutto in sequenza (circa 35 minuti), con i log in `logs/`:

```bash
./run-all.sh                           # non interattivo
STEP=1 ./run-all.sh                    # si ferma dopo ogni blocco e attende INVIO
FROM=02-12-namespace-quote ./run-all.sh   # riprende da un laboratorio (cluster già creato)
```

Per eliminare il cluster: `./02-02-setup/delete-cluster.sh`.

### Parte 3 – kube-coder (facoltativa)

Il capitolo speciale non è incluso in `run-all.sh`, perché richiede di costruire un'immagine di circa 2,7 GB
(10-30 minuti la prima volta) e circa 15 GB di spazio libero per Docker:

```bash
./03-kube-coder/install-ingress-nginx.sh   # ingress-nginx 1.15.1 (IngressClass "nginx") accanto a HAProxy
./03-kube-coder/steps.sh                   # clona kube-coder v1.87.2, costruisce e carica l'immagine, installa e verifica
SKIP_BUILD=1 ./03-kube-coder/steps.sh      # riusa l'immagine kube-coder:local già costruita
./03-kube-coder/cleanup.sh                 # rimuove workspace, volume e ingress-nginx
```

Dashboard: `kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8081:80`, poi aggiungi
`127.0.0.1 kube-coder.local` a `/etc/hosts` e apri http://kube-coder.local:8081 (utente `admin`, password `admin`).

## Contenuto

| Cartella | Paragrafo | Cosa fa |
|---|---|---|
| `02-02-setup/` | 2.2-2.3 | `kind-takeaway.yaml`, creazione/eliminazione del cluster (aggiunge il plug-in CNI `bridge` ai nodi) |
| `02-04-init/` | 2.4 | versione, nodi, configurazione kubeadm, static pod, namespace, pod di sistema |
| `02-05-cni/` | 2.5 | installazione di Flannel v0.28.11 |
| `02-07-rete/` | 2.7 | rotte, VXLAN, container pause, service `kubernetes`, EndpointSlice, cambio backend a host-gw |
| `02-08-manifest/` | 2.8 | primo Deployment, scaling via manifest, taint |
| `02-09-pod/` | 2.9 | ciclo di vita dei pod, restart policy, CrashLoopBackOff |
| `02-10-deployment-service/` | 2.10 | pod multi-container con volume condiviso, sidecar nativo, service NodePort e LoadBalancer |
| `02-11-ingress/` | 2.11 | HAProxy Ingress Controller (Helm), regole Ingress con fan-out e rewrite |
| `02-11-ingress/gateway-api/` | 2.11 | lo stesso esempio con la Gateway API ed Envoy Gateway |
| `02-12-namespace-quote/` | 2.12 | namespace, ResourceQuota, LimitRange |
| `02-13-configmap-secret/` | 2.13 | ConfigMap e Secret come variabili d'ambiente e come volume |
| `02-14-job-cronjob/` | 2.14 | Job e CronJob (`batch/v1`) |
| `02-15-helm/` | 2.15 | Helm 4: repository, ricerca, install, upgrade, rollback |
| `02-16-monitoring/` | 2.16 | metrics-server, kube-prometheus-stack (Prometheus, kube-state-metrics, Grafana) |
| `02-17-headlamp-rbac/` | 2.17 | Headlamp, service account, RBAC, `kubectl create token`, `kubectl auth can-i` |
| `02-18-scheduling/` | 2.18 | taint/toleration, nodeSelector, nodeAffinity, podAffinity/podAntiAffinity, cordon |
| `02-19-hpa/` | 2.19 | HorizontalPodAutoscaler `autoscaling/v2` con generatore di carico |
| `02-20-rollout/` | 2.20 | RollingUpdate, cronologia, rollback, Recreate, blue/green |
| `03-kube-coder/` | Parte 3 | workspace agentici con kube-coder: ingress-nginx, build dell'immagine, chart Helm, API dei task, persistenza, NetworkPolicy |

## Interfacce web

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090  # http://localhost:9090
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80                       # http://localhost:3000
kubectl port-forward -n kube-system svc/my-headlamp 4466:80                             # http://localhost:4466
```

Password di Grafana: `kubectl get secret -n monitoring prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 -d`
Token per Headlamp: `kubectl create token admin-user -n kube-system`

## Note

- **Docker Desktop (macOS/Windows)**: il traffico che arriva dal computer alle porte pubblicate da kind
  non attraversa correttamente l'overlay VXLAN di Flannel. Per questo `02-07-rete/steps.sh` passa
  Flannel al backend `host-gw`; è necessario prima del par. 2.11.
- La porta 8080 del computer è spesso occupata: l'Ingress è pubblicato su `localhost:30080`/`30443`
  e Headlamp su `localhost:4466`.
- Le verifiche "dall'interno del cluster" usano un pod di appoggio `curl` (`kubectl exec curl -- ...`),
  creato al primo utilizzo da `curl_pod` in `lib.sh`.
- Versioni fissate per la ripetibilità: Kubernetes 1.37.0 (immagine kind con digest), Flannel v0.28.11,
  plug-in CNI v1.10.0, Envoy Gateway v1.10.0, immagini `nginx:1.29`, `busybox:1.37`, `alpine:3.22`,
  `debian:13`, `traefik/whoami:v1.12`, `curlimages/curl:8.17.0`, `redis:8-alpine`.
  I chart Helm (HAProxy, metrics-server, kube-prometheus-stack, Headlamp, podinfo) sono installati
  alla versione più recente: per fissarli aggiungi `--version` ai comandi `helm`.
- Parte 3: kube-coder è un progetto di terze parti (licenza MIT) in rapida evoluzione; lo script usa la
  versione fissata `v1.87.2` e costruisce l'immagine in locale. ingress-nginx, che kube-coder richiede,
  è stato ritirato a marzo 2026: va bene per il laboratorio locale, non per la produzione.

## Segnalazioni

Hai trovato un comando che non funziona più con una versione recente di uno strumento? Apri una
*issue* indicando il paragrafo, il sistema operativo e l'output ottenuto.

## Licenza

Gli script e i manifest di questo repository sono distribuiti con licenza [MIT](LICENSE): puoi usarli,
modificarli e ridistribuirli liberamente, anche per scopi commerciali, mantenendo la nota di copyright.
La licenza riguarda solo i laboratori, non il testo del libro, che resta protetto da copyright.
I progetti di terze parti installati dagli script (kind, Flannel, HAProxy, Prometheus, Headlamp,
kube-coder e gli altri) hanno ciascuno la propria licenza.

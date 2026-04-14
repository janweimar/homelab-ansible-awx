# 🧊 Minikube Cluster - Betriebsanleitung

**Playbook:** `pb_setup_app_deploy.yml` (Minikube wird automatisch installiert bei `app_deploy_type=minikube`)
**Voraussetzung:** Docker muss installiert sein (wird als Dependency mitinstalliert)
**Hinweis:** K3s ist die bevorzugte Kubernetes-Distribution! Minikube nur in Ausnahmen.

---

## 📋 Übersicht

Installiert einen Minikube Single-Node Kubernetes Cluster mit:
- Minikube Binary (versioniert aus `kube_stack_versionen.yml`)
- Docker als Container-Driver
- kubectl standalone
- Helm
- Addons: storage-provisioner, default-storageclass, ingress

---

## 🛠️ Cluster-Status

```bash
# === Als kube User arbeiten ===
sudo su - kube

# === Cluster Status ===
minikube status                              # Läuft der Cluster?
kubectl get nodes -o wide                    # Node bereit? IP, Version
minikube ip                                  # Minikube IP (für nginx Proxy)

# === Minikube starten/stoppen ===
minikube start                               # Cluster starten
minikube stop                                # Cluster stoppen
minikube delete                              # Cluster komplett löschen (VORSICHT!)
```

---

## 📦 Pods anzeigen und verwalten

```bash
# === Alle Pods (alle Namespaces) ===
kubectl get pods -A                          # Kurzübersicht
kubectl get pods -A -o wide                  # Mit IP + Node

# === Pods in einem Namespace ===
kubectl get pods -n <NS>                     # Pods eines Namespace
kubectl get pods -n kube-system              # System-Pods

# === Pod-Details ===
kubectl describe pod <POD_NAME> -n <NS>      # Alles über einen Pod

# === Nicht laufende Pods ===
kubectl get pods -A --field-selector=status.phase!=Running
```

---

## 📋 Logs anzeigen

```bash
# === Pod Logs ===
kubectl logs <POD_NAME> -n <NS>              # Aktuelle Logs
kubectl logs <POD_NAME> -n <NS> --tail=50    # Letzte 50 Zeilen
kubectl logs <POD_NAME> -n <NS> -f           # Live-Stream
kubectl logs <POD_NAME> -n <NS> --previous   # Logs vom letzten Crash

# === Logs nach Label ===
kubectl logs -n <NS> -l app=<APP> --tail=50

# === Minikube System-Logs ===
minikube logs                                # Minikube Logs
minikube logs --file=kubelet                 # Kubelet Logs
```

---

## 🔌 Services und Netzwerk

```bash
# === Services anzeigen ===
kubectl get svc -A                           # Alle Services + Ports
minikube service list                        # Service URLs (mit Minikube IP)

# === Endpoints ===
kubectl get endpoints -A                     # Pod-IPs hinter Services

# === NodePort herausfinden ===
kubectl get svc <SERVICE> -n <NS> -o jsonpath='{.spec.ports[0].nodePort}'

# === Service URL öffnen (mit Minikube IP) ===
minikube service <SERVICE> -n <NS> --url     # URL anzeigen
```

---

## 💾 Storage und PVCs

```bash
# === PersistentVolumeClaims ===
kubectl get pvc -A                           # Alle PVCs + Status
kubectl get pv                               # Alle PersistentVolumes

# === StorageClass ===
kubectl get storageclass                     # standard (minikube)

# === Addons ===
minikube addons list                         # Welche Addons aktiv?
```

---

## 📊 Ressourcen-Verbrauch

```bash
# === CPU + RAM ===
kubectl top nodes                            # Pro Node
kubectl top pods -A                          # Pro Pod
kubectl top pods -A --containers             # Pro Container
```

---

## 🔧 Pods neustarten / skalieren

```bash
kubectl rollout restart deployment/<n> -n <NS>          # Rolling Restart
kubectl scale deployment/<n> -n <NS> --replicas=0       # Stoppen
kubectl scale deployment/<n> -n <NS> --replicas=1       # Starten
kubectl scale deployment --all -n <NS> --replicas=0     # Alle stoppen
kubectl rollout status deployment/<n> -n <NS>           # Status
```

---

## 🐚 In Pod einloggen

```bash
kubectl exec -it <POD_NAME> -n <NS> -- /bin/bash
kubectl exec -it <POD_NAME> -n <NS> -- /bin/sh          # Falls bash fehlt
kubectl cp <NS>/<POD_NAME>:/pfad/datei ./lokale_datei    # Datei aus Pod
kubectl cp ./lokale_datei <NS>/<POD_NAME>:/pfad/datei    # Datei in Pod
```

---

## 🔍 Debugging

```bash
# === Pod startet nicht? ===
kubectl describe pod <POD_NAME> -n <NS>                  # Events lesen!
kubectl get events -n <NS> --sort-by='.lastTimestamp'     # Letzte Events

# === CrashLoopBackOff? ===
kubectl logs <POD_NAME> -n <NS> --previous               # Crash-Logs

# === DNS testen ===
kubectl exec -n <NS> <POD_NAME> -- nslookup kubernetes.default

# === Alle Ressourcen ===
kubectl get all -n <NS>

# === Minikube SSH (in den Minikube-Container) ===
minikube ssh                                              # Shell im Minikube VM
minikube ssh -- df -h                                     # Speicherplatz prüfen
```

---

## 🧹 Aufräumen

```bash
kubectl delete namespace <NS>                             # Namespace komplett löschen
kubectl delete pod <POD_NAME> -n <NS>                     # Pod löschen
kubectl delete jobs --field-selector=status.successful=1 -A  # Fertige Jobs
```

---

## 📦 Helm

```bash
helm list --all-namespaces                                # Installierte Charts
helm status <RELEASE> -n <NS>                             # Chart-Details
helm uninstall <RELEASE> -n <NS>                          # Deinstallieren
helm repo list                                            # Helm Repos
helm repo update                                          # Repos aktualisieren
```

---

## 🔄 Nach Server-Reboot

Minikube startet automatisch per systemd-Service:
```
systemd → minikube.service (After=docker.service) → minikube start → alle Pods
```

Falls manuell nötig:
```bash
sudo su - kube
minikube start
```

---

## 📌 Kurzreferenz

```bash
sudo su - kube                               # Als kube User arbeiten
minikube status                              # Cluster-Status
minikube ip                                  # Minikube IP
kubectl get pods -A -o wide                  # Alle Pods mit IPs
kubectl logs -n <NS> -l app=<APP> --tail=50  # Logs nach Label
kubectl top pods -A                          # RAM/CPU
kubectl exec -it <POD> -n <NS> -- /bin/sh    # Shell im Pod
kubectl get events -A --sort-by='.lastTimestamp' | tail -20  # Events
kubectl get svc -A                           # Services + Ports
kubectl get pvc -A                           # Storage
minikube service list                        # Service URLs
```

---

**Version:** 2.0

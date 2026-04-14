# 🧊 K3s Cluster - Betriebsanleitung

**Playbook:** `pb_setup_app_deploy.yml` (K3s wird automatisch installiert bei `app_deploy_type=k3s`)
**Voraussetzung:** Keine — K3s bringt alles mit (containerd, kubectl, CNI)
**Bevorzugte Kubernetes-Distribution!** (vor Minikube und k8s)

---

## 📋 Übersicht

Installiert einen K3s Single-Node Kubernetes Cluster mit:

- K3s Binary (versioniert aus `kube_stack_versionen.yml`)
- Eingebautes containerd, Flannel CNI, CoreDNS
- Local-Path StorageClass (automatische PVs!)
- kubectl als Symlink auf k3s
- Helm
- Traefik deaktiviert (nginx Ingress extern)

---

## 🛠️ Cluster-Status

```bash
# === Als kube User arbeiten ===
sudo su - kube

# === Cluster Status ===
kubectl get nodes -o wide                    # Node bereit? IP, Version, OS
kubectl cluster-info                         # API-Server Adresse
k3s --version                                # Installierte K3s Version

# === K3s Service ===
systemctl status k3s                         # Läuft der Service?
systemctl start k3s                          # Starten
systemctl stop k3s                           # Stoppen
systemctl restart k3s                        # Neustarten
```

---

## 📦 Pods anzeigen und verwalten

```bash
# === Alle Pods (alle Namespaces) ===
kubectl get pods -A                          # Kurzübersicht
kubectl get pods -A -o wide                  # Mit IP + Node

# === Pods in einem Namespace ===
kubectl get pods -n ollama                   # Nur Ollama Pods
kubectl get pods -n open-webui               # Nur Open WebUI Pods
kubectl get pods -n kube-system              # System-Pods

# === Pod-Details ===
kubectl describe pod <POD_NAME> -n <NS>      # Alles über einen Pod
kubectl get pod <POD_NAME> -n <NS> -o yaml   # Vollständiges YAML

# === Pod-Status Probleme ===
kubectl get pods -A --field-selector=status.phase!=Running  # Nicht laufende Pods
kubectl get events -A --sort-by='.lastTimestamp' | tail -20  # Letzte Events
```

---

## 📋 Logs anzeigen

```bash
# === Pod Logs ===
kubectl logs <POD_NAME> -n <NS>              # Aktuelle Logs
kubectl logs <POD_NAME> -n <NS> --tail=50    # Letzte 50 Zeilen
kubectl logs <POD_NAME> -n <NS> -f           # Live-Stream (Ctrl+C zum Beenden)
kubectl logs <POD_NAME> -n <NS> --previous   # Logs vom letzten Crash

# === Logs nach Label ===
kubectl logs -n ollama -l app=ollama --tail=50
kubectl logs -n open-webui -l app=open-webui --tail=50

# === K3s System-Logs ===
journalctl -u k3s -n 50                     # K3s Service Logs
journalctl -u k3s -f                        # Live-Stream
```

---

## 🔌 Services und Netzwerk

```bash
# === Services anzeigen ===
kubectl get svc -A                           # Alle Services + Ports
kubectl get svc -n ollama                    # Ollama Service + NodePort
kubectl get svc -n open-webui                # Open WebUI Service + NodePort

# === Endpoints (Pod-IPs hinter Services) ===
kubectl get endpoints -A                     # Welche Pods hinter welchem Service

# === NodePort herausfinden ===
kubectl get svc <SERVICE> -n <NS> -o jsonpath='{.spec.ports[0].nodePort}'
```

---

## 💾 Storage und PVCs

```bash
# === PersistentVolumeClaims ===
kubectl get pvc -A                           # Alle PVCs + Status
kubectl get pvc -n ollama                    # Ollama PVCs (Modelle!)

# === PersistentVolumes ===
kubectl get pv                               # Alle PVs + Kapazität

# === StorageClass ===
kubectl get storageclass                     # local-path (default)

# === Wo liegen die Daten? ===
# /var/lib/rancher/k3s/storage/              # Local-Path Storage
ls -la /var/lib/rancher/k3s/storage/
```

---

## 📊 Ressourcen-Verbrauch

```bash
# === CPU + RAM pro Node ===
kubectl top nodes                            # Gesamtverbrauch

# === CPU + RAM pro Pod ===
kubectl top pods -A                          # Alle Pods
kubectl top pods -n ollama                   # Nur Ollama

# === Detailliert pro Container ===
kubectl top pods -A --containers             # Aufgeschlüsselt nach Container
```

---

## 🔧 Pods neustarten / skalieren

```bash
# === Deployment neustarten (Rolling Restart) ===
kubectl rollout restart deployment/<NAME> -n <NS>
kubectl rollout restart deployment/ollama -n ollama

# === Pods skalieren ===
kubectl scale deployment/<NAME> -n <NS> --replicas=0    # Stoppen
kubectl scale deployment/<NAME> -n <NS> --replicas=1    # Starten

# === Alle Deployments in einem Namespace stoppen ===
kubectl scale deployment --all -n ollama --replicas=0

# === Rollout Status ===
kubectl rollout status deployment/<NAME> -n <NS>
```

---

## 🐚 In Pod einloggen

```bash
# === Shell öffnen ===
kubectl exec -it <POD_NAME> -n <NS> -- /bin/bash
kubectl exec -it <POD_NAME> -n <NS> -- /bin/sh         # Falls bash fehlt

# === Befehl im Pod ausführen ===
kubectl exec -n ollama <POD_NAME> -- ollama list        # Ollama Modelle
kubectl exec -n ollama <POD_NAME> -- ollama pull llava   # Modell laden

# === Dateien kopieren (Pod ↔ Host) ===
kubectl cp <NS>/<POD_NAME>:/pfad/datei ./lokale_datei   # Aus Pod
kubectl cp ./lokale_datei <NS>/<POD_NAME>:/pfad/datei   # In Pod
```

---

## 🔍 Debugging

```bash
# === Pod startet nicht? ===
kubectl describe pod <POD_NAME> -n <NS>      # Events am Ende lesen!
kubectl get events -n <NS> --sort-by='.lastTimestamp'

# === CrashLoopBackOff? ===
kubectl logs <POD_NAME> -n <NS> --previous   # Logs vom letzten Crash

# === ImagePullBackOff? ===
kubectl describe pod <POD_NAME> -n <NS> | grep -A5 "Events"

# === Pending? (kein Node/RAM/CPU) ===
kubectl describe pod <POD_NAME> -n <NS> | grep -A5 "Conditions"

# === DNS testen (aus einem Pod heraus) ===
kubectl exec -n ollama <POD_NAME> -- nslookup kubernetes.default

# === Netzwerk testen (aus einem Pod heraus) ===
kubectl exec -n open-webui <POD_NAME> -- curl -s http://ollama-service.ollama.svc.cluster.local:11434/

# === Alle Ressourcen in einem Namespace ===
kubectl get all -n ollama
kubectl get all -n open-webui
```

---

## 🧹 Aufräumen

```bash
# === Namespace komplett löschen (VORSICHT!) ===
kubectl delete namespace ollama              # Löscht ALLES in dem Namespace

# === Einzelne Ressourcen löschen ===
kubectl delete pod <POD_NAME> -n <NS>        # Pod löschen (wird neugestartet)
kubectl delete deployment <NAME> -n <NS>     # Deployment löschen
kubectl delete pvc <NAME> -n <NS>            # PVC löschen (DATEN WEG!)

# === Fertige Jobs aufräumen ===
kubectl delete jobs --field-selector=status.successful=1 -A
```

---

## 📦 Helm

```bash
# === Installierte Charts ===
helm list --all-namespaces

# === Chart-Details ===
helm status <RELEASE> -n <NS>

# === Chart deinstalliert ===
helm uninstall <RELEASE> -n <NS>

# === Repos verwalten ===
helm repo list
helm repo update
```

---

## 📦 StorageClass

K3s bringt den Local-Path-Provisioner mit. PersistentVolumeClaims
werden automatisch gebunden — keine manuellen PVs nötig!

Daten liegen unter: `/var/lib/rancher/k3s/storage/`

---

## 🔄 Nach Server-Reboot

K3s ist als systemd-Service installiert und startet automatisch:

```
systemd → k3s.service → containerd → kubelet → API-Server → alle Pods
```

Daten bleiben erhalten (Local-Path Storage auf Festplatte).

---

## 🗑️ Deinstallation

```bash
/usr/local/bin/k3s-uninstall.sh
```

Entfernt K3s komplett inkl. aller Kubernetes-Daten.

---

## 📌 Kurzreferenz

```bash
sudo su - kube                               # Als kube User arbeiten
kubectl get pods -A                          # Alle Pods
kubectl get pods -A -o wide                  # Mit IPs
kubectl logs -n <NS> -l app=<APP> --tail=50  # Logs nach Label
kubectl top pods -A                          # RAM/CPU
kubectl exec -it <POD> -n <NS> -- /bin/sh    # Shell im Pod
kubectl get events -A --sort-by='.lastTimestamp' | tail -20  # Letzte Events
kubectl get svc -A                           # Services + Ports
kubectl get pvc -A                           # Storage
kubectl rollout restart deployment/<NAME> -n <NS>  # Pod neustarten
```

---

**Version:** 2.0

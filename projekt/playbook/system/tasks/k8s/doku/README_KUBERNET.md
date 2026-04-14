# ☸️ Kubernetes Cluster (kubeadm) - Betriebsanleitung

**Playbook:** `pb_setup_app_deploy.yml` (k8s wird automatisch installiert bei `app_deploy_type=k8s`)
**Voraussetzung:** containerd muss installiert sein
**Hinweis:** K3s ist die bevorzugte Kubernetes-Distribution! k8s (kubeadm) nur für Legacy.

---

## 📋 Übersicht

Installiert einen Kubernetes Cluster mit:
- kubeadm, kubelet, kubectl
- cri-tools, kubernetes-cni
- Calico oder Flannel CNI
- Helm

---

## 🛠️ Cluster-Status

```bash
# === Als kube User arbeiten ===
sudo su - kube

# === Cluster Status ===
kubectl get nodes -o wide                    # Node bereit? IP, Version
kubectl cluster-info                         # API-Server Adresse
kubeadm version                              # kubeadm Version
kubectl version --short                      # kubectl + Server Version

# === Kubelet Service ===
systemctl status kubelet                     # Läuft der Service?
systemctl start kubelet                      # Starten
systemctl restart kubelet                    # Neustarten
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

# === Kubelet Logs ===
journalctl -u kubelet -n 50
journalctl -u kubelet -f                     # Live-Stream
```

---

## 🔌 Services und Netzwerk

```bash
# === Services anzeigen ===
kubectl get svc -A                           # Alle Services + Ports
kubectl get endpoints -A                     # Pod-IPs hinter Services

# === NodePort herausfinden ===
kubectl get svc <SERVICE> -n <NS> -o jsonpath='{.spec.ports[0].nodePort}'
```

---

## 💾 Storage und PVCs

```bash
# === PersistentVolumeClaims ===
kubectl get pvc -A                           # Alle PVCs + Status
kubectl get pv                               # Alle PersistentVolumes

# === StorageClass ===
kubectl get storageclass
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
kubectl rollout status deployment/<n> -n <NS>           # Status
```

---

## 🐚 In Pod einloggen

```bash
kubectl exec -it <POD_NAME> -n <NS> -- /bin/bash
kubectl exec -it <POD_NAME> -n <NS> -- /bin/sh          # Falls bash fehlt
kubectl cp <NS>/<POD_NAME>:/pfad/datei ./lokale_datei    # Datei aus Pod
```

---

## 🔍 Debugging

```bash
kubectl describe pod <POD_NAME> -n <NS>                  # Events lesen!
kubectl get events -n <NS> --sort-by='.lastTimestamp'     # Letzte Events
kubectl logs <POD_NAME> -n <NS> --previous               # Crash-Logs
kubectl get all -n <NS>                                   # Alle Ressourcen
kubectl describe node $(hostname)                         # Node-Details
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
```

---

## 🔄 Nach Server-Reboot

kubelet ist als systemd-Service installiert und startet automatisch.

---

## 📌 Kurzreferenz

```bash
sudo su - kube                               # Als kube User arbeiten
kubectl get pods -A -o wide                  # Alle Pods mit IPs
kubectl logs -n <NS> -l app=<APP> --tail=50  # Logs nach Label
kubectl top pods -A                          # RAM/CPU
kubectl exec -it <POD> -n <NS> -- /bin/sh    # Shell im Pod
kubectl get events -A --sort-by='.lastTimestamp' | tail -20  # Events
kubectl get svc -A                           # Services + Ports
kubectl get pvc -A                           # Storage
```

---

**Version:** 2.0

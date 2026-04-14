# 🐳 Containerd - Betriebsanleitung

**Playbook:** `pb_inst_containerd.yml` (via containerd_install.yml)  
**Zweck:** Container Runtime für Kubernetes

---

## 🛠️ SERVICE MANAGEMENT

**Status prüfen:**
```bash
systemctl status containerd
```

**Service starten/stoppen:**
```bash
systemctl start containerd
systemctl stop containerd
systemctl restart containerd
```

**Service Logs:**
```bash
journalctl -u containerd -f
journalctl -u containerd -n 100 --no-pager
```

---

## 📦 CONTAINERD BEFEHLE

### Container-Verwaltung

**Container auflisten:**
```bash
ctr -n default containers ls
ctr -n k8s.io containers ls  # Kubernetes namespace
```

**Container Details:**
```bash
ctr -n default container info <container-id>
```

**Container löschen:**
```bash
ctr -n default container delete <container-id>
```

### Image-Verwaltung

**Images auflisten:**
```bash
ctr -n default images ls
ctr -n k8s.io images ls
```

**Image pullen:**
```bash
ctr -n default image pull docker.io/library/nginx:latest
```

**Image löschen:**
```bash
ctr -n default image rm docker.io/library/nginx:latest
```

### Namespace-Verwaltung

**Namespaces anzeigen:**
```bash
ctr namespaces ls
```

**Neuen Namespace erstellen:**
```bash
ctr namespaces create myapp
```

---

## 🔧 CRICTL BEFEHLE

crictl ist das CLI-Tool für CRI (Container Runtime Interface) - verwendet von Kubernetes.

### Pod-Verwaltung

**Pods auflisten:**
```bash
crictl pods
crictl pods --namespace=kube-system
```

**Pod Details:**
```bash
crictl inspectp <pod-id>
```

### Container-Verwaltung

**Container auflisten:**
```bash
crictl ps -a
crictl ps  # Nur laufende
```

**Container Logs:**
```bash
crictl logs <container-id>
crictl logs -f <container-id>  # Follow
```

**Container exec:**
```bash
crictl exec -it <container-id> /bin/bash
```

### Image-Verwaltung

**Images auflisten:**
```bash
crictl images
```

**Image pullen:**
```bash
crictl pull nginx:latest
```

**Image löschen:**
```bash
crictl rmi <image-id>
```

---

## 🔍 TROUBLESHOOTING

### Problem: Containerd startet nicht

```bash
# Config Syntax prüfen
containerd config default > /tmp/default-config.toml
diff /etc/containerd/config.toml /tmp/default-config.toml

# Logs prüfen
journalctl -u containerd -n 50 --no-pager

# Service Status
systemctl status containerd

# Manuell starten (Debug)
containerd --config /etc/containerd/config.toml --log-level debug
```

### Problem: Container lassen sich nicht starten

```bash
# Runtime prüfen
crictl version
ctr version

# Config prüfen
crictl info

# Systemd prüfen
systemctl status containerd

# Namespaces prüfen
ctr namespaces ls
```

### Problem: Image Pull schlägt fehl

```bash
# Registry erreichbar?
ping registry-1.docker.io

# DNS funktioniert?
nslookup registry-1.docker.io

# Proxy-Config prüfen
cat /etc/systemd/system/containerd.service.d/http-proxy.conf

# Service neu starten
systemctl restart containerd
```

### Problem: "failed to reserve sandbox name"

```bash
# Alte Container/Pods aufräumen
crictl ps -a | grep Exited
crictl rm <container-id>

# Pods aufräumen
crictl pods | grep NotReady
crictl stopp <pod-id>
crictl rmp <pod-id>
```

---

## ⚙️ KONFIGURATION

### Containerd Config

**Speicherort:** `/etc/containerd/config.toml`

**Standard-Config generieren:**
```bash
containerd config default > /etc/containerd/config.toml
```

**Wichtige Einstellungen:**
```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  runtime_type = "io.containerd.runc.v2"
  
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
  SystemdCgroup = true  # Wichtig für Kubernetes!
```

**Config neu laden:**
```bash
systemctl restart containerd
```

### crictl Config

**Speicherort:** `/etc/crictl.yaml`

**Inhalt:**
```yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
```

---

## ⚠️ WICHTIGE HINWEISE

### Swap

- Swap **MUSS** für Kubernetes deaktiviert sein
- Wurde vom Playbook permanent deaktiviert
- Eintrag in `/etc/fstab` auskommentiert

**Swap-Status prüfen:**
```bash
free -h
swapon --show
cat /proc/swaps
```

### Paket-Management

- containerd ist mit `apt-mark hold` fixiert
- Automatische Updates sind deaktiviert
- Manuelles Update erforderlich

**Hold-Status prüfen:**
```bash
apt-mark showhold | grep containerd
```

**Hold entfernen (temporär):**
```bash
apt-mark unhold containerd
apt update
apt install containerd
apt-mark hold containerd
```

### Netzwerk

- Containerd verwendet CNI (Container Network Interface)
- Standard-Namespace: `default`
- Kubernetes-Namespace: `k8s.io`

---

## 📁 WICHTIGE DATEIEN

| Pfad | Beschreibung |
|------|-------------|
| `/etc/containerd/config.toml` | Hauptkonfiguration |
| `/etc/crictl.yaml` | crictl Konfiguration |
| `/var/lib/containerd/` | Containerd Daten |
| `/run/containerd/containerd.sock` | Unix Socket |
| `/etc/fstab` | Swap-Deaktivierung |

---

## 🔗 WEITERE INFORMATIONEN

**Containerd Dokumentation:** https://containerd.io/docs/  
**crictl Dokumentation:** https://github.com/kubernetes-sigs/cri-tools  
**CRI Specification:** https://github.com/kubernetes/cri-api

---

## ✅ CHECKLISTE POST-INSTALLATION

- [ ] Service läuft: `systemctl status containerd`
- [ ] Swap deaktiviert: `free -h`
- [ ] Config deployed: `cat /etc/containerd/config.toml`
- [ ] crictl funktioniert: `crictl version`
- [ ] Namespaces vorhanden: `ctr namespaces ls`
- [ ] Paket-Hold gesetzt: `apt-mark showhold | grep containerd`

---

**Version:** 1.0  
**Letzte Änderung:** 2026-03-01

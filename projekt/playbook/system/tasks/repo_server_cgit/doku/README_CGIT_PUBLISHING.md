# 📂 cgit Publishing - Betriebsanleitung

**Playbook:** `pb_conf_cgit_publishing_server.yml`
**Voraussetzung:** `pb_setup_repo_server.yml` muss bereits ausgeführt sein

---

## 📋 Übersicht

Synchronisiert Git-Repositories für den cgit-Server:
- Neue Repos klonen (als Mirror)
- Bestehende Repos aktualisieren
- Nicht mehr benötigte Repos entfernen
- Batch-Verarbeitung für große Repository-Listen

---

## 🛠️ Wichtige Befehle

### Repositories verwalten

```bash
# Alle Repos anzeigen
ls -la /srv/git/

# Einzelnes Repo aktualisieren
cd /srv/git/<repo>.git && git fetch --all

# Repo-Größe prüfen
du -sh /srv/git/*

# Gesamtgröße
du -sh /srv/git/
```

### cgit Konfiguration

```bash
# Config anzeigen
cat /etc/cgitrc

# cgit via nginx testen
curl -s http://localhost/cgit/ | head -20
```

### Fehleranalyse

```bash
# Failed-Clone-Reports
ls /tmp/ansible_git_clone/

# Aktive Git-Prozesse
ps aux | grep git

# nginx Error Log
tail -f /var/log/nginx/error.log
```

---

## 📁 Verzeichnisstruktur auf dem Server

```
/srv/git/
├── repo1.git/
│   ├── description          ← Repository-Beschreibung (für cgit)
│   ├── git-daemon-export-ok ← cgit-Marker
│   ├── config
│   └── refs/
├── repo2.git/
└── ...
```

---

## ⚙️ Variablen

### Pflicht

```yaml
git_clone_list:
  - name: repo_name        # Name ohne .git
    url: https://...       # Clone URL
    description: "Text"   # Optional: Beschreibung für cgit
```

### Optional

```yaml
git_batch_size: 20         # Repos pro Batch (Standard: 20)
```

---

## 🔄 Batch-Verarbeitung

Große Repository-Listen (100+) werden in Batches verarbeitet:

```
git_batch_size: 20

Beispiel 50 Repos:
  Batch 1: Repos 1–20
  Batch 2: Repos 21–40
  Batch 3: Repos 41–50
```

---

## ❗ Troubleshooting

### Repo wird nicht geklont
```bash
# SSH-Key prüfen
ssh -T git@github.com

# Manuell testen
git clone --mirror <url> /tmp/test.git
```

### cgit zeigt Repo nicht an
```bash
# Marker prüfen
ls /srv/git/<repo>.git/git-daemon-export-ok

# Rechte prüfen
ls -la /srv/git/<repo>.git/
```

### Berechtigungsfehler
```bash
chown -R www-data:www-data /srv/git
chmod -R 2775 /srv/git
```

---

**Version:** 1.0

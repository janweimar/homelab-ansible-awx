# 📦 Repository Server - Betriebsanleitung

**Playbook:** `pb_setup_repo_server.yml`
**Installiert:** nginx, aptly, cgit, fcgiwrap

---

## 📋 Übersicht

Installiert und konfiguriert einen kompletten Repository-Server:
- **aptly** — Debian APT-Repository-Verwaltung
- **cgit** — Git-Web-Interface (Browser für Git-Repos)
- **nginx** — Reverse Proxy für beide Dienste
- **fcgiwrap** — FastCGI-Wrapper für cgit

---

## 🛠️ Wichtige Befehle

### aptly

```bash
# Repository-Liste
aptly repo list

# Mirror-Liste
aptly mirror list

# Publizierte Repos anzeigen
aptly publish list

# GPG-Key anzeigen
gpg --list-keys
```

### cgit

```bash
# Config anzeigen
cat /etc/cgitrc

# Git-Repos anzeigen
ls -la /srv/git/

# Einzelnes Repo prüfen
cd /srv/git/<repo>.git && git log -1
```

### nginx

```bash
# Konfiguration testen
nginx -t

# Neustart
systemctl restart nginx

# Status
systemctl status nginx

# Logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

---

## 📁 Verzeichnisstruktur auf dem Server

```
/srv/
├── aptly/                  ← aptly Daten & Repos
│   └── public/             ← Öffentlich via nginx
└── git/                    ← Git Repositories
    ├── repo1.git/
    └── repo2.git/

/etc/
├── aptly/
│   └── aptly.conf          ← aptly Konfiguration
└── cgitrc                  ← cgit Konfiguration

/etc/nginx/
└── sites-enabled/
    └── <domain>.conf       ← nginx vHost
```

---

## 🔄 Abhängige Playbooks

| Playbook | Zweck |
|----------|-------|
| `pb_conf_cgit_publishing_server.yml` | Git-Repos klonen/synchronisieren |
| `pb_conf_aptly_mirrors_repo_server.yml` | aptly Mirrors konfigurieren |
| `pb_conf_aptly_publishing_server.yml` | aptly Repos publizieren |

**Reihenfolge:**
1. `pb_setup_repo_server.yml` → Installation (zuerst!)
2. `pb_conf_cgit_publishing_server.yml` → Repos synchronisieren
3. `pb_conf_aptly_*` → aptly konfigurieren

---

## 🔒 Sicherheit

- Apache2 wird automatisch entfernt (Port-Konflikt mit nginx)
- GPG-Key für APT-Repo-Signierung wird automatisch erzeugt
- nginx mit optionalem ModSecurity WAF

---

## ❗ Troubleshooting

### nginx startet nicht
```bash
nginx -t          # Konfiguration prüfen
journalctl -u nginx -n 50
```

### aptly GPG-Fehler
```bash
gpg --list-keys
# GPG-Home: /root/.gnupg (oder laut aptly.conf)
```

### cgit zeigt keine Repos
```bash
ls -la /srv/git/
systemctl status fcgiwrap.socket
cat /etc/cgitrc
```

---

**Version:** 1.0

# 📚 BookStack Playbook - AWX Credentials

## 🔐 Benötigte Credentials in AWX

### 1. SSH Key Credential

**Typ:** `Machine`
**Felder:**

- Username: `root` oder sudo-User
- SSH Private Key: [Dein SSH Key]

---

### 2. BookStack Status Credential

**Typ:** `Custom`
**Name:** `status_bookstack_mod_`

**Felder:**

```yaml
allg_status: aktiviert | deaktiviert | deinstalliert
```

**Beispiel:**

```yaml
allg_status: aktiviert
```

---

### 3. BookStack Configuration Credential

**Typ:** `Custom`
**Name:** `credential_type_bookstack`

**Felder:**

```yaml
# Datenbank
bookstack_db_password: "IhrSicheresPasswort123!"

# Basis-Konfiguration
bookstack_admin_email: "admin@meine-domain.de"
bookstack_app_url: "http://repo.meine-domain.de"
bookstack_port: "8080"

# nginx Integration (Optional)
bookstack_nginx_integration: false  # true = nginx Reverse Proxy
bookstack_domain: ""                # z.B. "doku.meine-domain.de"
bookstack_ssl: false                # true = Let's Encrypt SSL
```

---

## 📋 AWX Custom Credential Type erstellen

### Schritt 1: Custom Credential Type anlegen

**Administration → Credential Types → Add**

**Name:** `BookStack Configuration`

**Input Configuration:**

```yaml
fields:
  - id: bookstack_db_password
    type: string
    label: Database Password
    secret: true
    
  - id: bookstack_admin_email
    type: string
    label: Admin E-Mail
    default: admin@admin.com
    
  - id: bookstack_app_url
    type: string
    label: Application URL
    default: http://localhost:8080
    
  - id: bookstack_port
    type: string
    label: Port
    default: "8080"
    
  - id: bookstack_nginx_integration
    type: boolean
    label: nginx Integration
    default: false
    
  - id: bookstack_domain
    type: string
    label: Domain (für nginx)
    default: ""
    
  - id: bookstack_ssl
    type: boolean
    label: SSL aktivieren (Let's Encrypt)
    default: false

required:
  - bookstack_db_password
  - bookstack_admin_email
```

**Injector Configuration:**

```yaml
extra_vars:
  bookstack_db_password: "{{ bookstack_db_password }}"
  bookstack_admin_email: "{{ bookstack_admin_email }}"
  bookstack_app_url: "{{ bookstack_app_url }}"
  bookstack_port: "{{ bookstack_port }}"
  bookstack_nginx_integration: "{{ bookstack_nginx_integration }}"
  bookstack_domain: "{{ bookstack_domain }}"
  bookstack_ssl: "{{ bookstack_ssl }}"
```

### Schritt 2: Credential anlegen

**Resources → Credentials → Add**

**Name:** `BookStack Repo-Server Config`
**Organization:** [Deine Org]
**Credential Type:** `BookStack Configuration`

**Details:**

- Database Password: `MeinSuperSicheresPasswort123!`
- Admin E-Mail: `admin@meine-domain.de`
- Application URL: `http://repo.meine-domain.de/doku`
- Port: `8080`
- nginx Integration: `✓` (aktiviert)
- Domain: `repo.meine-domain.de`
- SSL: `✓` (aktiviert)

---

## 🚀 Job Template erstellen

**Resources → Templates → Add Job Template**

**Name:** `BookStack Installation`
**Job Type:** `Run`
**Inventory:** [Dein Inventory mit Repo-Server]
**Project:** [Dein Ansible Projekt]
**Playbook:** `playbook_inst_bookstack.yml`

**Credentials:**

1. SSH Key: `production-ssh-key`
2. Status: `credential_type_status` (allg_status: aktiviert)
3. BookStack Config: `BookStack Repo-Server Config`

**Options:**

- ✓ Privilege Escalation

---

## 📝 Nutzungs-Szenarien

### Szenario 1: Einfache Installation (nur Docker)

```yaml
# Credentials
bookstack_db_password: "SicheresPasswort123"
bookstack_admin_email: "admin@example.com"
bookstack_app_url: "http://192.168.1.100:8080"
bookstack_port: "8080"
bookstack_nginx_integration: false
bookstack_domain: ""
bookstack_ssl: false
```

**Ergebnis:**

- BookStack erreichbar unter: `http://192.168.1.100:8080`
- Direkter Zugriff auf Docker-Container
- Port 8080 muss in Firewall geöffnet sein

---

### Szenario 2: Mit nginx Reverse Proxy (HTTP)

```yaml
bookstack_db_password: "SicheresPasswort123"
bookstack_admin_email: "admin@meine-domain.de"
bookstack_app_url: "http://repo.meine-domain.de/doku"
bookstack_port: "8080"
bookstack_nginx_integration: true
bookstack_domain: "repo.meine-domain.de"
bookstack_ssl: false
```

**Ergebnis:**

- BookStack erreichbar unter: `http://repo.meine-domain.de/doku`
- nginx leitet an localhost:8080 weiter
- Port 8080 NICHT von außen erreichbar
- Nur Port 80 in Firewall öffnen

---

### Szenario 3: Mit nginx + SSL (HTTPS)

```yaml
bookstack_db_password: "SicheresPasswort123"
bookstack_admin_email: "admin@meine-domain.de"
bookstack_app_url: "https://doku.meine-domain.de"
bookstack_port: "8080"
bookstack_nginx_integration: true
bookstack_domain: "doku.meine-domain.de"
bookstack_ssl: true
```

**Voraussetzungen:**

- Domain `doku.meine-domain.de` zeigt auf Server
- Port 80/443 in Firewall geöffnet
- certbot installiert

**Ergebnis:**

- BookStack erreichbar unter: `https://doku.meine-domain.de`
- Let's Encrypt SSL Zertifikat automatisch erstellt
- HTTP → HTTPS Redirect
- Port 8080 NICHT von außen erreichbar

---

## 🔧 Verwaltungs-Templates

### Playbook stoppen

```yaml
allg_status: deaktiviert
```

### Playbook deinstalliert

```yaml
allg_status: deinstalliert
```

**⚠️ ACHTUNG:** Bei Deinstallation werden ALLE Daten gelöscht!
Vorher Backup erstellen:

```bash
tar -czf bookstack-backup-$(date +%Y%m%d).tar.gz /opt/bookstack
```

---

## 📊 Firewall-Regeln

### Ohne nginx (direkter Zugriff)

```bash
sudo nft add rule inet filter input tcp dport 8080 accept
```

### Mit nginx (Reverse Proxy)

```bash
# HTTP
sudo nft add rule inet filter input tcp dport 80 accept

# HTTPS
sudo nft add rule inet filter input tcp dport 443 accept

# Port 8080 NICHT öffnen (nur intern)
```

---

## 🧪 Test nach Installation

### 1. Container prüfen

```bash
docker ps | grep bookstack
```

### 2. Logs prüfen

```bash
docker-compose -f /opt/bookstack/docker-compose.yml logs -f
```

### 3. Web-Zugriff testen

```bash
curl http://localhost:8080
# oder
curl http://repo.meine-domain.de/doku
```

### 4. Login testen

**Browser öffnen:**

- URL: [Deine konfigurierte URL]
- E-Mail: `admin@admin.com`
- Passwort: `password`

**⚠️ WICHTIG:** Passwort sofort ändern!

---

## 💾 Backup & Recovery

### Backup erstellen

```bash
# Komplettes Backup
tar -czf bookstack-backup-$(date +%Y%m%d).tar.gz /opt/bookstack

# Nur Datenbank
docker exec bookstack_db mysqldump -u bookstack -p bookstack > bookstack-db-$(date +%Y%m%d).sql
```

### Recovery

```bash
# Container stoppen
docker-compose -f /opt/bookstack/docker-compose.yml down

# Backup wiederherstellen
tar -xzf bookstack-backup-20250113.tar.gz -C /

# Container starten
docker-compose -f /opt/bookstack/docker-compose.yml up -d
```

---

## 🆘 Troubleshooting

### Problem: Container startet nicht

```bash
# Logs prüfen
docker-compose -f /opt/bookstack/docker-compose.yml logs

# Container Status
docker ps -a | grep bookstack

# Neu starten
docker-compose -f /opt/bookstack/docker-compose.yml restart
```

### Problem: nginx 502 Bad Gateway

```bash
# Prüfe ob Container läuft
docker ps | grep bookstack

# Prüfe Port
curl http://localhost:8080

# nginx Logs
tail -f /var/log/nginx/error.log
```

### Problem: SSL Zertifikat fehlt

```bash
# Manuell erstellen
sudo certbot --nginx -d doku.meine-domain.de

# Erneuern
sudo certbot renew
```

---

## 📚 Nächste Schritte nach Installation

1. **Login & Passwort ändern**
   - Einloggen mit <admin@admin.com> / password
   - Settings → Users → admin → Change Password

2. **Struktur erstellen**
   - Shelf anlegen: "Ansible Playbooks Git"
   - Books erstellen (siehe BOOKSTACK_STRUKTUR.md)

3. **Benutzer anlegen**
   - Settings → Users → Create New User
   - Berechtigungen setzen

4. **draw.io Dateien hochladen**
   - Seite → Insert Drawing
   - .drawio Dateien importieren

5. **Backup einrichten**
   - Cronjob für tägliches Backup
   - Backup-Speicherort definieren

---

**Status:** ✅ Bereit für AWX  
**Version:** 1.0  
**Erstellt:** 2025-01-13

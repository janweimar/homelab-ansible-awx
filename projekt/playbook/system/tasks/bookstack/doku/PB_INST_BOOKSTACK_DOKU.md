# PB_INST_BOOKSTACK - DOKUMENTATION

## BESCHREIBUNG

**Playbook:** `pb_inst_bookstack.yml`

Dieses Playbook installiert BookStack, ein Wiki-System für strukturierte Dokumentation, via Docker Compose auf dem Zielsystem.

**BookStack** ist eine moderne, Open-Source-Plattform für Dokumentation mit:

- Strukturierte Hierarchie (Shelves → Books → Chapters → Pages)
- WYSIWYG-Editor
- Markdown-Support
- Volltextsuche
- Benutzer- & Rechteverwaltung
- LDAP/SAML Integration
- API

---

## ZWECK

- Installation von BookStack via Docker
- Optional: nginx Reverse Proxy mit SSL (Let's Encrypt)
- Optional: ModSecurity (WAF)
- Automatisches DB-Setup (MariaDB)
- Persistente Datenspeicherung
- Container-Management (start/stop/restart)

---

## VORAUSSETZUNGEN

### System-Anforderungen

- **RAM:** min. 1 GB (empfohlen: 2 GB)
- **Disk:** min. 5 GB freier Speicher
- **CPU:** 1 Core (empfohlen: 2 Cores)

### Installierte Software

- **Docker** (wird automatisch installiert falls nicht vorhanden)
- **Docker Compose** (wird automatisch installiert)
- **nginx** (optional, für Reverse Proxy)

### Netzwerk

- **Port 8080** (Standard, änderbar) für direkten Zugriff
- **Port 80/443** (bei nginx Integration)
- Internet-Zugang für Docker-Images

---

## VARIABLEN

### Pflicht-Variablen

Keine! Alle Variablen haben Standardwerte.

### Optionale Variablen

#### bookstack_port

Port für BookStack Container

```yaml
bookstack_port: "8080"  # Standard
```

#### bookstack_db_password

Passwort für MariaDB-Datenbank

```yaml
bookstack_db_password: "{{ generiertes_passwort }}"  # Standard: auto-generiert
```

**Wichtig:** Wird automatisch generiert und in `.credentials` gespeichert

#### bookstack_admin_email

Admin-E-Mail für BookStack

```yaml
bookstack_admin_email: "admin@admin.com"  # Standard
```

#### bookstack_app_url

URL für BookStack (für Links, E-Mails etc.)

```yaml
bookstack_app_url: "http://localhost:8080"  # Standard
bookstack_app_url: "https://docs.example.com"  # Mit nginx
```

#### bookstack_nginx_integration

nginx Reverse Proxy aktivieren

```yaml
bookstack_nginx_integration: false  # Standard (direkter Zugriff)
bookstack_nginx_integration: true   # nginx Reverse Proxy
```

#### bookstack_domain

Domain für nginx (nur wenn `bookstack_nginx_integration: true`)

```yaml
bookstack_domain: "docs.example.com"
```

#### bookstack_ssl

SSL via Let's Encrypt aktivieren

```yaml
bookstack_ssl: false  # Standard (HTTP)
bookstack_ssl: true   # HTTPS via Let's Encrypt
```

**Voraussetzung:**

- `bookstack_nginx_integration: true`
- Domain muss auf Server zeigen
- Port 80/443 offen

#### nginx_modsecurity

ModSecurity WAF aktivieren

```yaml
nginx_modsecurity: false  # Standard
nginx_modsecurity: true   # ModSecurity aktiviert
```

**Voraussetzung:** `bookstack_nginx_integration: true`

---

## INSTALLATION

### Minimale Installation

```yaml
# AWX Variables - KEINE erforderlich!
allg_status: aktiviert
```

**Ergebnis:**

- BookStack auf Port 8080
- HTTP (kein SSL)
- Direkter Zugriff

### Produktions-Installation mit nginx

```yaml
# AWX Variables
allg_status: aktiviert
bookstack_nginx_integration: true
bookstack_domain: "docs.example.com"
bookstack_ssl: true
bookstack_admin_email: "admin@example.com"
bookstack_app_url: "https://docs.example.com"
```

**Ergebnis:**

- nginx Reverse Proxy
- Let's Encrypt SSL
- URL: <https://docs.example.com>

### Mit ModSecurity (Sicherheit)

```yaml
allg_status: aktiviert
bookstack_nginx_integration: true
nginx_modsecurity: true
bookstack_domain: "docs.example.com"
bookstack_ssl: true
```

**Ergebnis:**

- nginx + ModSecurity WAF
- SSL
- Zusätzlicher Schutz vor Angriffen

---

## WORKFLOW

### Phase 1: Vorbereitung

1. **Variablen setzen:** Standardwerte oder Custom
2. **Dependencies prüfen:** nginx/ModSecurity bei Bedarf
3. **Verzeichnisse erstellen:** `/opt/bookstack` (Standard)

### Phase 2: Docker-Setup

4. **Docker Compose File:** Template erstellen
2. **Credentials speichern:** DB-Passwort in `.credentials`
3. **Container starten:** bookstack + bookstack_db

### Phase 3: nginx (Optional)

7. **nginx konfigurieren:** Reverse Proxy Setup
2. **SSL aktivieren:** Let's Encrypt (optional)
3. **ModSecurity:** WAF-Regeln aktivieren (optional)

### Phase 4: Finalisierung

10. **Health Check:** BookStack Erreichbarkeit prüfen
2. **Info erstellen:** README.txt mit Zugangsdaten

---

## VERZEICHNISSTRUKTUR

```
/opt/bookstack/                    # Base-Verzeichnis
├── docker-compose.yml             # Docker Compose Config
├── .credentials                   # DB-Passwort (600)
├── README.txt                     # Zugangsdaten & Infos
└── data/
    ├── bookstack/                 # BookStack Daten
    │   └── storage/               # Uploads, Sessions, Logs
    └── bookstack_db/              # MariaDB Datenbank
        └── mysql/                 # DB-Dateien

/etc/nginx/sites-enabled/bookstack # nginx Config (optional)
```

---

## DOCKER CONTAINER

### Container-Übersicht

```
bookstack          # BookStack App (linuxserver/bookstack)
bookstack_db       # MariaDB 10.11
```

### Ports

- **8080:80** - BookStack (intern → extern)

### Volumes

- `bookstack_data` → `/config` (BookStack Daten)
- `bookstack_db` → `/var/lib/mysql` (MariaDB Daten)

### Netzwerk

- `bookstack_net` - Bridge-Netzwerk für Container-Kommunikation

### docker-compose.yml Struktur

```yaml
services:
  bookstack_db:
    image: mariadb:10.11
    environment:
      MYSQL_DATABASE: bookstackapp
      MYSQL_USER: bookstack
      MYSQL_PASSWORD: ${DB_PASSWORD}
    volumes:
      - bookstack_db:/var/lib/mysql

  bookstack:
    image: linuxserver/bookstack:latest
    depends_on:
      - bookstack_db
    ports:
      - "8080:80"
    environment:
      APP_URL: http://localhost:8080
      DB_HOST: bookstack_db
      DB_DATABASE: bookstackapp
      DB_USERNAME: bookstack
      DB_PASSWORD: ${DB_PASSWORD}
    volumes:
      - bookstack_data:/config
```

---

## NGINX INTEGRATION

### Reverse Proxy

nginx leitet Anfragen an BookStack Container weiter:

```
Browser → nginx (80/443) → BookStack Container (8080)
```

### Vorteile

- **SSL-Terminierung:** HTTPS-Verschlüsselung
- **Caching:** Statische Inhalte cachen
- **Load Balancing:** Mehrere BookStack-Instanzen
- **ModSecurity:** Web Application Firewall
- **Logging:** Zentrales Access-Log

### nginx Konfiguration

```nginx
server {
    listen 80;
    server_name docs.example.com;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### SSL via Let's Encrypt

Automatische Zertifikats-Erstellung:

```bash
certbot --nginx -d docs.example.com
```

---

## MODSECURITY

### Was ist ModSecurity?

Open-Source Web Application Firewall (WAF) mit:

- **OWASP Core Rule Set:** Schutz vor Standard-Angriffen
- **SQL Injection:** Erkennung & Blockierung
- **XSS:** Cross-Site Scripting Schutz
- **Path Traversal:** Verhinderung
- **DDoS:** Rate Limiting

### Aktivierung

```yaml
bookstack_nginx_integration: true
nginx_modsecurity: true
```

### Logs

```bash
# ModSecurity Logs
tail -f /var/log/nginx/modsec_audit.log

# nginx Error Log
tail -f /var/log/nginx/error.log
```

---

## WARTUNG

### Backup

#### Datenbank-Backup

```bash
# Manuelles Backup
docker exec bookstack_db mysqldump \
  -u bookstack -p'PASSWORD' \
  bookstackapp > backup.sql

# Automatisch via AWX
restore_db: false  # Vor Update
# ... Update durchführen ...
restore_db: true   # Nach Update
```

#### Storage-Backup

```bash
# Uploads & Konfiguration sichern
tar -czf bookstack_storage.tar.gz /opt/bookstack/data/bookstack/
```

### Updates

#### Docker-Images aktualisieren

```bash
cd /opt/bookstack
docker compose pull
docker compose up -d --force-recreate
```

#### Via Playbook

```bash
# Playbook erneut ausführen mit:
allg_status: aktiviert
```

### Monitoring

#### Container-Status

```bash
docker compose ps
docker compose logs -f
```

#### Disk-Usage

```bash
du -sh /opt/bookstack/data/*
```

#### Performance

```bash
docker stats bookstack bookstack_db
```

---

## ADMINISTRATION

### Erster Login

```
URL: http://server:8080
E-Mail: admin@admin.com
Passwort: password
```

**⚠️ WICHTIG:** Passwort sofort ändern!

### Benutzer anlegen

1. Settings → Users → Add New User
2. E-Mail, Name, Rolle festlegen
3. Passwort setzen oder per E-Mail senden

### Rollen & Rechte

- **Admin:** Volle Kontrolle
- **Editor:** Inhalte erstellen/bearbeiten
- **Viewer:** Nur Lesezugriff

### Struktur erstellen

```
Shelf (Regal)
└── Book (Buch)
    └── Chapter (Kapitel)
        └── Page (Seite)
```

### API nutzen

```bash
# API Token in Profil erstellen
# Dann Requests:

curl -H "Authorization: Token YOUR_TOKEN" \
  http://localhost:8080/api/books
```

---

## TROUBLESHOOTING

### Problem: Container startet nicht

**Symptom:** `docker compose up` fehlgeschlagen

**Diagnose:**

```bash
docker compose logs bookstack
docker compose logs bookstack_db
```

**Lösungen:**

- **Port belegt:** Port in `docker-compose.yml` ändern
- **DB-Fehler:** `docker compose down -v` (⚠️ löscht Daten!)
- **Netzwerk:** Docker-Netzwerk neu erstellen

### Problem: 502 Bad Gateway (nginx)

**Symptom:** nginx zeigt 502-Fehler

**Diagnose:**

```bash
# BookStack Container läuft?
docker compose ps

# BookStack erreichbar?
curl http://localhost:8080

# nginx Logs
tail -f /var/log/nginx/error.log
```

**Lösungen:**

- Container neu starten: `docker compose restart`
- nginx neu starten: `systemctl restart nginx`
- Firewall prüfen: `ufw status`

### Problem: DB-Verbindung fehlgeschlagen

**Symptom:** "SQLSTATE[HY000]: Can't connect to MySQL server"

**Lösungen:**

```bash
# DB-Container prüfen
docker compose logs bookstack_db

# Neustart
docker compose restart bookstack_db
sleep 10
docker compose restart bookstack

# Passwort prüfen
cat /opt/bookstack/.credentials
```

### Problem: Uploads funktionieren nicht

**Symptom:** "Failed to upload file"

**Lösung:**

```bash
# Permissions fixen
docker compose exec bookstack \
  chown -R www-data:www-data /config/www/storage

# Storage-Verzeichnis prüfen
ls -la /opt/bookstack/data/bookstack/storage
```

### Problem: SSL-Zertifikat ungültig

**Symptom:** "Your connection is not private"

**Lösungen:**

```bash
# Zertifikat erneuern
certbot renew

# nginx neu laden
systemctl reload nginx

# Zertifikat manuell erstellen
certbot certonly --nginx -d docs.example.com
```

---

## SICHERHEIT

### Best Practices

1. **Admin-Passwort ändern** - Sofort nach Installation
2. **DB-Passwort komplex** - Min. 16 Zeichen
3. **SSL aktivieren** - Immer HTTPS in Produktion
4. **ModSecurity nutzen** - Zusätzlicher Schutz
5. **Firewall konfigurieren** - Nur benötigte Ports öffnen
6. **Updates regelmäßig** - Docker-Images aktuell halten
7. **Backups erstellen** - Tägliche DB-Backups
8. **LDAP/SAML** - Externe Authentifizierung nutzen

### Firewall-Regeln

```bash
# Direkter Zugriff
ufw allow 8080/tcp

# nginx Reverse Proxy
ufw allow 80/tcp
ufw allow 443/tcp
```

### Passwort-Richtlinien

In BookStack: Settings → Security → Password Requirements

---

## PERFORMANCE-OPTIMIERUNG

### Caching

```yaml
# In docker-compose.yml hinzufügen:
CACHE_DRIVER: redis
SESSION_DRIVER: redis
```

### Datenbank-Tuning

```sql
-- MariaDB optimieren
SET GLOBAL innodb_buffer_pool_size = 256M;
SET GLOBAL max_connections = 200;
```

### nginx Caching

```nginx
location ~* \.(jpg|jpeg|png|gif|css|js)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
}
```

---

## MIGRATION

### Von BookStack (ohne Docker)

```bash
# 1. Datenbank exportieren
mysqldump -u root -p bookstackapp > old_backup.sql

# 2. Storage kopieren
cp -r /var/www/bookstack/storage/* /opt/bookstack/data/bookstack/storage/

# 3. Datenbank importieren
docker exec -i bookstack_db mysql -u bookstack -pPASSWORD bookstackapp < old_backup.sql
```

### Zwischen Servern

```bash
# Server A (alt)
docker exec bookstack_db mysqldump -u bookstack -pPASSWORD bookstackapp > backup.sql
tar -czf storage.tar.gz /opt/bookstack/data/bookstack/

# Server B (neu)
# ... Playbook ausführen ...
docker exec -i bookstack_db mysql -u bookstack -pNEW_PASSWORD bookstackapp < backup.sql
tar -xzf storage.tar.gz -C /opt/bookstack/data/
```

---

## BEST PRACTICES

1. **Umgebungen trennen:** Dev/Staging/Prod separate Instanzen
2. **HTTPS erzwingen:** Immer SSL in Produktion
3. **Regelmäßige Backups:** Tägliche automatische Backups
4. **Monitoring:** Uptime & Performance überwachen
5. **Updates testen:** Erst in Staging, dann Prod
6. **Dokumentation pflegen:** README aktuell halten
7. **Access Logs prüfen:** Verdächtige Aktivitäten erkennen

---

## ZUSAMMENHANG MIT ANDEREN PLAYBOOKS

```
1. pb_inst_docker.yml (optional)
   └─ Docker Installation

2. pb_inst_nginx.yml (optional)
   └─ nginx Installation

3. pb_inst_bookstack.yml ← DIESES PLAYBOOK
   └─ BookStack via Docker

4. pb_conf_nftables_firewall.yml (empfohlen)
   └─ Firewall-Konfiguration
```

---

## BEISPIEL-KONFIGURATIONEN

### Minimal Setup

```yaml
allg_status: aktiviert
```

### Standard Setup

```yaml
allg_status: aktiviert
bookstack_port: "8080"
bookstack_admin_email: "admin@company.com"
```

### Produktions-Setup

```yaml
allg_status: aktiviert
bookstack_nginx_integration: true
bookstack_domain: "docs.company.com"
bookstack_ssl: true
nginx_modsecurity: true
bookstack_admin_email: "it@company.com"
bookstack_app_url: "https://docs.company.com"
```

### High-Security Setup

```yaml
allg_status: aktiviert
bookstack_nginx_integration: true
bookstack_domain: "internal-docs.company.local"
bookstack_ssl: true
nginx_modsecurity: true

# Zusätzlich: IP-Whitelist in nginx
# Zusätzlich: LDAP-Integration aktivieren
# Zusätzlich: 2FA aktivieren
```

---

**Version:** 1.0  
**Letzte Aktualisierung:** 2025-02-16  
**Status:** Produktionsreif

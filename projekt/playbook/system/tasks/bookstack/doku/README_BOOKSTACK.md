# 📚 BookStack - Betriebsanleitung

**Playbook:** `pb_inst_bookstack.yml`  
**Zweck:** Wiki/Dokumentations-Platform

---

## 🔑 STANDARD-LOGIN

**E-Mail:** admin@admin.com  
**Passwort:** password  
⚠️ **WICHTIG:** Passwort nach erstem Login ändern!

---

## 📁 VERZEICHNISSTRUKTUR

```
/opt/bookstack/
├── docker-compose.yml        # Docker Compose Konfiguration
├── .credentials              # DB-Zugangsdaten (chmod 600)
├── README.txt                # Info-Datei
└── data/                     # BookStack Daten
    ├── db/                   # MariaDB Datenbank
    └── storage/              # BookStack Uploads & Storage
```

---

## 🛠️ DOCKER CONTAINER BEFEHLE

**Status prüfen:**
```bash
cd /opt/bookstack
docker compose ps
```

**Container starten:**
```bash
docker compose up -d
```

**Container stoppen:**
```bash
docker compose down
```

**Container neu starten:**
```bash
docker compose restart
```

**Logs anzeigen:**
```bash
docker compose logs -f
docker compose logs -f bookstack      # Nur BookStack
docker compose logs -f bookstack_db   # Nur DB
```

---

## 🔧 WARTUNG

**Backup erstellen:**
```bash
cd /opt/bookstack
tar -czf bookstack-backup-$(date +%Y%m%d).tar.gz data/
```

**Update durchführen:**
```bash
cd /opt/bookstack
docker compose pull
docker compose up -d
```

**In Container wechseln:**
```bash
docker compose exec bookstack /bin/bash
docker compose exec bookstack_db /bin/bash
```

---

## 🔍 TROUBLESHOOTING

**Problem: Container startet nicht**
```bash
docker compose logs bookstack
docker compose ps
```

**Problem: Datenbank-Verbindung fehlgeschlagen**
```bash
# Credentials prüfen
cat /opt/bookstack/.credentials

# DB-Container läuft?
docker compose ps bookstack_db
```

**Problem: Uploads funktionieren nicht**
```bash
# Permissions prüfen
ls -la /opt/bookstack/data/storage/
chmod -R 755 /opt/bookstack/data/storage/
```

---

## 📊 DATENBANK

**DB-Backup:**
```bash
docker compose exec bookstack_db mysqldump -u bookstack -p bookstackdb > backup.sql
```

**DB-Restore:**
```bash
docker compose exec -T bookstack_db mysql -u bookstack -p bookstackdb < backup.sql
```

---

## ✅ CHECKLISTE

- [ ] Container laufen: `docker compose ps`
- [ ] URL erreichbar
- [ ] Admin-Passwort geändert
- [ ] Backup erstellt
- [ ] nginx SSL aktiv (falls konfiguriert)

---

**Version:** 1.0  
**Letzte Änderung:** 2026-03-01

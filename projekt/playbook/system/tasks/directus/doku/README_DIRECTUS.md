# 🧱 Directus — Betriebsanleitung

**Playbook:** `pb_setup_directus.yml`
**Container:** `/opt/directus/docker-compose.yml`

---

## 📋 Übersicht

Directus als Headless CMS / REST API.
Verwendung: AWX-Variablenverwaltung über REST API.

Unterstützte Datenbanken: `mariadb` | `postgresql` | `mysql`

---

## 🛠️ Wichtige Befehle

```bash
# Status
cd /opt/directus && docker compose ps

# Logs
docker compose logs -f directus
docker compose logs -f directus_db

# Neustart
docker compose restart directus

# Stoppen / Starten
docker compose stop
docker compose start

# Update
docker compose pull && docker compose up -d
```

---

## 🔗 AWX REST API Integration

```bash
# Token holen
curl -X POST http://localhost:8055/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password"}'

# Collection abfragen
curl http://localhost:8055/items/<collection> \
  -H "Authorization: Bearer <token>"
```

---

## ❗ Troubleshooting

### Container startet nicht
```bash
docker compose logs directus_db
docker compose logs directus
```

### Datenbank nicht erreichbar
```bash
docker compose exec directus_db mariadb-admin ping -u directus -p
```

---

**Version:** 1.0

# 🐳 AWX Execution Environment - Betriebsanleitung

**Playbook:** `pb_inst_awx_ee.yml`  
**Zweck:** Custom AWX Execution Environment mit ansible-builder

---

## 📁 VERZEICHNISSTRUKTUR

```
/opt/awx_ee/
├── execution-environment.yml   # EE-Build-Definition
└── context/                    # Wird von ansible-builder erstellt
    ├── Containerfile           # Generiertes Dockerfile
    └── _build/
        ├── requirements.yml    # Galaxy Collections
        ├── requirements.txt    # Python-Pakete
        └── bindep.txt          # System-Pakete
```

---

## 🛠️ NÜTZLICHE BEFEHLE

### Image-Verwaltung

**Image bauen:**

```bash
cd /opt/awx_ee
ansible-builder build \
  --tag registry.example.com/awx-ee:latest \
  --container-runtime docker \
  --verbosity 3
```

**Image anzeigen:**

```bash
docker image ls | grep awx-ee
docker image inspect registry.example.com/awx-ee:latest
```

**Image zur Registry pushen:**

```bash
docker push registry.example.com/awx-ee:latest
```

**Image löschen:**

```bash
docker rmi registry.example.com/awx-ee:latest
docker builder prune -f
```

### Inhalt prüfen

**Collections anzeigen:**

```bash
docker run --rm registry.example.com/awx-ee:latest \
  ansible-galaxy collection list
```

**Python-Pakete anzeigen:**

```bash
docker run --rm registry.example.com/awx-ee:latest \
  pip3 list
```

**System-Pakete anzeigen:**

```bash
docker run --rm registry.example.com/awx-ee:latest \
  dpkg -l
```

**Ansible Version:**

```bash
docker run --rm registry.example.com/awx-ee:latest \
  ansible --version
```

---

## 🔧 VERWENDUNG IN AWX

### EE in AWX konfigurieren

1. **Administration** → **Execution Environments**
2. **Add** klicken
3. Werte eintragen:
   - **Name:** `awx-ee`
   - **Image:** `registry.example.com/awx-ee:latest`
   - **Pull:** `Always` (bei Registry) oder `Missing` (lokal)
4. **Save**

### EE einem Job Template zuweisen

1. **Resources** → **Templates**
2. Template bearbeiten
3. **Execution Environment** auswählen: `awx-ee`
4. **Save**

---

## 🔍 TROUBLESHOOTING

### Problem: Build schlägt fehl bei Galaxy Collections

**Symptom:** `ERROR: Failed to install collection`

**Lösung:**

```bash
# Galaxy-Erreichbarkeit testen
curl -s https://galaxy.ansible.com/api/ | head

# Collection manuell installieren
ansible-galaxy collection install community.general --force

# Build mit Debug
ansible-builder build --verbosity 3 2>&1 | tee build.log
```

### Problem: Build schlägt fehl bei Python-Paketen

**Symptom:** `ERROR: Could not find a version that satisfies the requirement`

**Lösung:**

```bash
# execution-environment.yml prüfen
cat /opt/awx_ee/execution-environment.yml

# Paket manuell testen
pip3 install --dry-run <paketname>

# Alternative Version versuchen
# In execution-environment.yml:
# python: |
#   ansible-core==2.14.0
```

### Problem: AWX findet Image nicht

**Lösung:**

```bash
# Image vorhanden?
docker image ls | grep awx-ee

# Pull-Policy in AWX prüfen:
# - "Always" → Image muss in Registry sein
# - "Missing" → Lokales Image wird genutzt

# Falls lokal: In AWX auf "Missing" setzen
```

### Problem: Podman kann kein Image bauen

**Symptom:** `ERRO[0000] cannot find UID/GID`

**Lösung:**

```bash
# Subuid/Subgid konfigurieren
echo "root:100000:65536" >> /etc/subuid
echo "root:100000:65536" >> /etc/subgid

# Podman migrieren
podman system migrate

# Erneut versuchen
ansible-builder build --container-runtime podman
```

### Problem: Registry-Push schlägt fehl

**Lösung:**

```bash
# Login prüfen
docker login registry.example.com

# Credentials eingeben
# Username: <user>
# Password: <password>

# Push mit Debug
docker push registry.example.com/awx-ee:latest --debug
```

---

## 🛡️ SICHERHEIT

### Registry-Zugriff (nginx Reverse Proxy)

- Registry läuft auf `127.0.0.1:5000` (nur lokal)
- nginx leitet externe Anfragen weiter
- **Nur Read-Only (Pull) von außen erlaubt**

```nginx
# nginx Konfiguration
location / {
    limit_except GET HEAD {
        deny all;
    }
    proxy_pass http://127.0.0.1:5000;
}
```

### Best Practices

- ✅ Registry-Push nur nach erfolgreichen Tests
- ✅ Tags mit Versionsnummern verwenden (nicht nur `latest`)
- ✅ Registry-Credentials in AWX Vault speichern
- ✅ SSL für Registry (Let's Encrypt)
- ✅ Regelmäßige Updates der Collections/Pakete

---

## 📝 AWX CREDENTIALS

| Variable | Typ | Default | Beschreibung |
|---|---|---|---|
| `allg_status` | choice | `aktiviert` | aktiviert / deinstalliert |
| `ee_image_name` | string | `awx-ee` | Name des EE Images |
| `ee_image_tag` | string | `latest` | Version/Tag |
| `container_runtime` | choice | `docker` | docker oder podman |
| `push_to_registry` | boolean | `true` | Nach Build pushen? |
| `awx_ee_registry_user` | string | - | Registry-User (optional) |
| `awx_ee_registry_password` | string | - | Registry-Password (optional) |

**Registry-URL** wird aus `os_urls.yml` geladen.

---

## ✅ CHECKLISTE POST-DEPLOYMENT

- [ ] Image gebaut: `docker image ls | grep awx-ee`
- [ ] Image zur Registry gepusht (falls aktiviert)
- [ ] EE in AWX angelegt
- [ ] Test-Job mit EE ausgeführt
- [ ] Collections verfügbar: `ansible-galaxy collection list`
- [ ] Python-Pakete verfügbar: `pip3 list`

---

**Version:** 1.0  
**Letzte Änderung:** 2026-03-01  
**Tool:** ansible-builder

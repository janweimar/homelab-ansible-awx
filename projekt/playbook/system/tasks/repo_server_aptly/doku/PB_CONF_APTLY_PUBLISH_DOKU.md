# PB_CONF_APTLY_PUBLISHING_REPO_SERVER - DOKUMENTATION

## BESCHREIBUNG

**Playbook:** `pb_conf_aptly_publishing_repo_server.yml`

Dieses Playbook verwaltet Aptly-Publishing auf einem Repository-Server. Es erstellt Snapshots aus Mirrors, vergleicht IST- und SOLL-Zustand, und veröffentlicht die finalen Pakete GPG-signiert über nginx.

**Wichtig:** Dieses Playbook benötigt bereits existierende Mirrors (erstellt durch `pb_conf_aptly_mirrors_repo_server.yml`).

---

## ZWECK

- Erstellen von Snapshots aus Mirrors
- IST/SOLL-Vergleich (aktueller Snapshot vs. Freeze-Liste)
- Delta-Berechnung (hinzuzufügende/zu löschende Pakete)
- Merge von mehreren Mirror-Snapshots
- Filtern nach Freeze-Konfiguration (fixierte Paket-Versionen)
- GPG-signiertes Publishing
- Automatisches Snapshot-Management
- Cleanup alter Snapshots

---

## VORAUSSETZUNGEN

### Installierte Pakete (durch pb_inst_repo_server.yml)
- aptly
- nginx
- gnupg
- curl

### Bereits durchgeführte Playbooks
1. **pb_inst_repo_server.yml** - Repository-Server Installation
2. **pb_conf_aptly_mirrors_repo_server.yml** - Mirrors erstellen

### GPG-Key
- GPG-Key für Signierung muss existieren (erstellt durch pb_inst_repo_server.yml)
- Key-Name: `aptly_key`
- Passphrase in AWX Credentials

### Variablen
- `repo_self_list` mit Freeze-Konfiguration
- `aptly_publish_defaults` mit Publishing-Einstellungen

---

## VARIABLEN

### Pflicht-Variablen

#### repo_self_list
Definition der zu veröffentlichenden Pakete mit festen Versionen

```yaml
repo_self_list:
  Debian:  # OS-Family
    apt_source_list:
      ubuntu_main_universe:  # Mirror-Name
        freeze:
          nginx:
            - "1.24.0-1ubuntu1"
          postgresql:
            - "16+258"
          curl:
            - "8.5.0-2ubuntu10.5"
      
      docker:
        freeze:
          docker-ce:
            - "5:27.0.3-1~ubuntu.24.04~noble"
          docker-compose-plugin:
            - "2.27.1-1~ubuntu.24.04~noble"
```

**Struktur:**
- `OS-Family`: Debian, RedHat, etc.
- `apt_source_list`: Map von Mirror-Namen
- `freeze`: Map von Paket → Versionen (Array)

**Wichtig:**
- Mirror-Namen müssen exakt mit `aptly_mirrors` übereinstimmen
- Versionen müssen exakt sein (inkl. Epoch, Release)
- Pakete müssen im Mirror verfügbar sein

#### aptly_publish_defaults
Publishing-Konfiguration

```yaml
aptly_publish_defaults:
  distribution_publish: "noble"              # Distribution (z.B. noble, jammy, bookworm)
  component_publish: "main"                  # Komponente (main, contrib, non-free)
  Architectures_publish: "amd64,all"         # Architekturen (kommasepariert)
  gpg_passphrase: "{{ from_credentials }}"   # GPG-Passphrase (aus AWX)
  gpg_apt_key_id: "ABCD1234"                 # Optional: Explizite Key-ID
```

---

## WORKFLOW

### Phase 1: Vorbereitung
1. **Publikation prüfen:** Prüft ob `repo_self` bereits existiert
2. **GPG-Key ermitteln:** Sucht automatisch nach `aptly_key`
3. **Initial-Publish:** Erstellt leere Publikation falls nicht vorhanden

### Phase 2: IST-Zustand
4. **Aktuellen Snapshot laden:** Ermittelt aktiven Snapshot der Publikation
5. **Paketliste extrahieren:** Liest alle Pakete mit Versionen aus

### Phase 3: SOLL-Zustand
6. **Mirror-Namen sammeln:** Aus `repo_self_list` extrahieren
7. **Freeze-Listen laden:** Für jeden Mirror Pakete mit Versionen sammeln
8. **Snapshots erstellen:** Pro Mirror einen Snapshot erstellen

### Phase 4: Vergleich
9. **Delta berechnen:**
   - Add: Pakete in SOLL aber nicht in IST
   - Delete: Pakete in IST aber nicht in SOLL
10. **Prüfung:** Falls keine Änderungen → Beenden

### Phase 5: Publishing (nur bei Änderungen)
11. **Snapshots mergen:** Alle Mirror-Snapshots zusammenführen
12. **Filtern:** Nur Freeze-Pakete behalten
13. **Publish Switch:** Publikation auf neuen Snapshot umschalten (GPG-signiert)
14. **Cleanup:** Alte Snapshots löschen

---

## AUSGABE-VERZEICHNIS

```
/root/.aptly/
├── db/                           # Aptly-Datenbank
├── public/                       # Nginx-Root
│   └── repo_self/                # Publikations-Prefix
│       ├── dists/
│       │   └── noble/            # Distribution
│       │       ├── Release        # Metadaten
│       │       ├── Release.gpg    # GPG-Signatur
│       │       ├── InRelease      # Signierte Metadaten
│       │       └── main/          # Komponente
│       │           └── binary-amd64/
│       │               ├── Packages       # Paketliste
│       │               └── Packages.gz    # Komprimiert
│       └── pool/                 # Paket-Pool
│           └── main/
│               └── n/nginx/
│                   └── nginx_1.24.0-1ubuntu1_amd64.deb
└── pool/                         # Globaler Pool (Hardlinks)
```

**Client-URL:** `http://<server>/repo_self`

---

## SNAPSHOTS

### Naming Convention
```
<mirror-name>                # Basis-Snapshot (z.B. "ubuntu_main")
repo_self-initial            # Leerer Initial-Snapshot
repo_self-all-mirrors        # Temporär: Merge aller Mirrors
repo_self-new                # Finaler Snapshot (nach Filter)
```

### Lifecycle
1. **Basis-Snapshot** wird vom Mirror erstellt
2. **Merge-Snapshot** vereint alle Mirrors
3. **Filter-Snapshot** enthält nur Freeze-Pakete
4. **Publish Switch** aktiviert neuen Snapshot
5. **Alter Snapshot** wird gelöscht

### Persistenz
- Aktiver Snapshot: `repo_self-new` (wird beibehalten)
- Temporäre Snapshots: `repo_self-all-mirrors` (wird gelöscht)
- Alte Snapshots: Automatisch gelöscht nach Switch

---

## GPG-SIGNIERUNG

### Key-Ermittlung
1. Prüfe `aptly_publish_defaults.gpg_apt_key_id`
2. Falls nicht gesetzt: Suche `aptly_key` in GPG-Keyring
3. Verwende ersten gefundenen Key

### Signatur-Prozess
```bash
aptly publish switch \
  -gpg-key=<KEY_ID> \
  -batch \
  -passphrase-file=<(echo "$PASSPHRASE") \
  noble \
  repo_self \
  repo_self-new
```

**Wichtig:** Passphrase wird aus AWX Credentials geladen!

### Key-Export (für Clients)
```bash
gpg --armor --export aptly_key > /root/.aptly/public/repo_self/aptly_key.pub
```

**Client-URL:** `http://<server>/repo_self/aptly_key.pub`

---

## FILTER-SYNTAX

### Aptly Filter Expression
```
(Name (= paket1), $Version (= version1)) | (Name (= paket2), $Version (= version2))
```

### Beispiel
```
(Name (= nginx), $Version (= 1.24.0-1ubuntu1)) | (Name (= curl), $Version (= 8.5.0))
```

### Generierung
Das Playbook baut den Filter automatisch aus `mirror_freeze_list`:
```yaml
mirror_freeze_list:
  - mirror: ubuntu_main
    package: nginx
    version: 1.24.0-1ubuntu1
  - mirror: ubuntu_main
    package: curl
    version: 8.5.0
```

---

## CLIENT-KONFIGURATION

### Repository hinzufügen
```bash
# GPG-Key importieren
curl -fsSL http://<server>/repo_self/aptly_key.pub | \
  sudo gpg --dearmor -o /etc/apt/keyrings/repo-self.gpg

# Repository eintragen
echo "deb [signed-by=/etc/apt/keyrings/repo-self.gpg] \
http://<server>/repo_self noble main" | \
  sudo tee /etc/apt/sources.list.d/repo-self.list

# Update
sudo apt update
```

### Pakete installieren
```bash
# Aus repo_self installieren
sudo apt install nginx

# Version prüfen
apt policy nginx

# Version fixieren
sudo apt-mark hold nginx
```

---

## BEFEHLE

### Status prüfen
```bash
# Publikation anzeigen
aptly publish list

# Aktiven Snapshot anzeigen
aptly publish show noble repo_self | grep Snapshot

# Snapshot-Inhalt
aptly snapshot show -with-packages repo_self-new
```

### Manuelles Publishing
```bash
# 1. Snapshot erstellen
aptly snapshot create my-snapshot from mirror ubuntu_main

# 2. Publish
aptly publish snapshot \
  -distribution=noble \
  -component=main \
  -architectures=amd64,all \
  -gpg-key=<KEY_ID> \
  -batch \
  my-snapshot repo_self
```

### Cleanup
```bash
# Alte Snapshots löschen
aptly snapshot list -raw | grep -v "repo_self-new" | \
  xargs -I{} aptly snapshot drop {}

# Ungenutzte Pakete entfernen
aptly db cleanup

# Publikation löschen
aptly publish drop noble repo_self
```

---

## TROUBLESHOOTING

### Problem: Paket-Version nicht gefunden
**Symptom:**
```
Paket 'nginx=1.24.0' nicht im Snapshot
```

**Ursache:** Version in Freeze-Liste falsch oder nicht im Mirror

**Lösung:**
```bash
# Verfügbare Versionen prüfen
aptly snapshot show -with-packages ubuntu_main | grep nginx

# Freeze-Liste anpassen
repo_self_list:
  Debian:
    apt_source_list:
      ubuntu_main:
        freeze:
          nginx:
            - "1.24.0-2ubuntu1"  # Korrigierte Version
```

### Problem: GPG-Signatur ungültig
**Symptom:**
```
GPG error: ... The following signatures couldn't be verified
```

**Ursache:** Client hat falschen Public Key

**Lösung:**
```bash
# Key neu importieren
curl -fsSL http://<server>/repo_self/aptly_key.pub | \
  sudo gpg --dearmor -o /etc/apt/keyrings/repo-self.gpg
```

### Problem: Snapshot existiert nicht
**Symptom:**
```
snapshot 'ubuntu_main' does not exist
```

**Ursache:** Mirror-Snapshot wurde nicht erstellt

**Lösung:**
```bash
# Mirror-Snapshot manuell erstellen
aptly snapshot create ubuntu_main from mirror ubuntu_main

# Oder: Mirrors Playbook erneut ausführen
```

### Problem: "No changes detected"
**Symptom:** Playbook meldet keine Änderungen, aber Pakete fehlen

**Ursache:** Freeze-Liste stimmt nicht mit tatsächlichem IST überein

**Lösung:**
```bash
# IST-Zustand prüfen
aptly snapshot show -with-packages repo_self-new | grep <paket>

# SOLL-Zustand prüfen
cat /path/to/repo_self_list.yml | grep -A5 freeze

# Delta manuell berechnen und Freeze-Liste korrigieren
```

---

## SICHERHEIT

### Passphrase-Verwaltung
- **Niemals im Code speichern!**
- Nur in AWX Custom Credential Type
- Wird zur Laufzeit eingefügt

### GPG-Key Backup
```bash
# Private Key exportieren (verschlüsselt aufbewahren!)
gpg --export-secret-keys aptly_key > aptly_key_backup.gpg

# Public Key exportieren
gpg --export aptly_key > aptly_key_backup.pub
```

### Nginx-Zugriff beschränken
```nginx
location /repo_self {
    allow 10.0.0.0/8;
    deny all;
}
```

---

## PERFORMANCE

### Große Freeze-Listen
- Pro Paket: ~0.1s Verarbeitungszeit
- 100 Pakete: ~10s
- 1000 Pakete: ~100s

### Snapshot-Merge
- Abhängig von Mirror-Größe
- ubuntu_main (~50.000 Pakete): ~30s
- docker (~200 Pakete): ~2s

### Publishing
- Switch: ~5-10s
- GPG-Signierung: ~2-3s pro Distribution

---

## BEST PRACTICES

1. **Mirrors zuerst:** Immer erst Mirrors erstellen/updaten
2. **Freeze klein halten:** Nur benötigte Pakete in Freeze-Liste
3. **Regelmäßig cleanen:** `aptly db cleanup` nach Updates
4. **Backup GPG-Key:** Regelmäßig Private Key sichern
5. **Versionierung:** Freeze-Listen in Git versionieren
6. **Testing:** Erst auf Test-System, dann Prod
7. **Monitoring:** Publikations-Status überwachen

---

## ZUSAMMENHANG MIT ANDEREN PLAYBOOKS

```
1. pb_inst_repo_server.yml
   └─ Installation: aptly, nginx, GPG-Key

2. pb_conf_aptly_mirrors_repo_server.yml
   └─ Mirrors erstellen und aktualisieren

3. pb_conf_aptly_publishing_repo_server.yml  ← DIESES PLAYBOOK
   └─ Snapshots erstellen und publishen

4. Client-Konfiguration
   └─ Repository nutzen
```

---

## BEISPIEL-KONFIGURATION

### Minimales Setup
```yaml
# AWX Variables
repo_self_list:
  Debian:
    apt_source_list:
      ubuntu_main:
        freeze:
          nginx:
            - "1.24.0-1ubuntu1"

aptly_publish_defaults:
  distribution_publish: "noble"
  component_publish: "main"
  Architectures_publish: "amd64,all"
  gpg_passphrase: "{{ from_credentials }}"
```

### Produktions-Setup
```yaml
repo_self_list:
  Debian:
    apt_source_list:
      ubuntu_main_universe:
        freeze:
          nginx:
            - "1.24.0-1ubuntu1"
          postgresql:
            - "16+258"
          python3:
            - "3.12.3-1ubuntu0.2"
      
      docker:
        freeze:
          docker-ce:
            - "5:27.0.3-1~ubuntu.24.04~noble"
          docker-compose-plugin:
            - "2.27.1-1~ubuntu.24.04~noble"

aptly_publish_defaults:
  distribution_publish: "noble"
  component_publish: "main"
  Architectures_publish: "amd64,all"
  gpg_passphrase: "{{ from_credentials }}"
  gpg_apt_key_id: "ABCD1234EF567890"  # Optional
```

---

**Version:** 1.0  
**Letzte Aktualisierung:** 2025-02-16  
**Status:** Produktionsreif

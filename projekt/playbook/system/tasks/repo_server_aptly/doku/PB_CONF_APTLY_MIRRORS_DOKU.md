# PB_CONF_APTLY_MIRRORS_REPO_SERVER - DOKUMENTATION

## BESCHREIBUNG

**Playbook:** `pb_conf_aptly_mirrors_repo_server.yml`

Dieses Playbook verwaltet Aptly-Mirrors auf einem Repository-Server. Es erstellt Mirrors basierend auf Roll-Listen (Paketlisten) und aktualisiert diese regelmäßig vom Upstream-Repository.

**Wichtig:** Dieses Playbook erstellt KEINE Snapshots und führt KEIN Publishing durch. Es ist ausschließlich für das Mirror-Management zuständig.

---

## ZWECK

- Erstellen von Aptly-Mirrors basierend auf `aptly_mirrors` Variable
- Filtern von Paketen nach Roll-Listen (`repo_self_list_var`)
- Filtern nach Architekturen (amd64, arm64, all, etc.)
- Automatisches Importieren von GPG-Keys
- Aktualisieren der Mirrors vom Upstream
- Löschen nicht mehr benötigter Mirrors
- Bereinigen der Aptly-Datenbank

---

## VORAUSSETZUNGEN

### Installierte Pakete (durch pb_inst_repo_server.yml)

- aptly
- nginx
- gnupg
- curl

### Konfiguration

- Repository-Server läuft
- SSH-Zugang als root
- Internet-Zugang zu Upstream-Repositories

### Variablen

- `aptly_mirrors` muss definiert sein
- `repo_self_list_var` muss Roll-Listen enthalten

---

## VARIABLEN

### Pflicht-Variablen

#### aptly_mirrors

Liste der zu verwaltenden Mirrors

```yaml
aptly_mirrors:
  - name: "ubuntu-noble-main"              # Eindeutiger Mirror-Name
    url: "http://archive.ubuntu.com/ubuntu"  # Repository-URL
    dist: "noble"                           # Distribution (z.B. noble, jammy)
    components:                             # Komponenten
      - "main"
      - "restricted"
    arch_filter: "amd64,all"                # Architekturen (kommagetrennt oder Liste)
    key_url: "https://..."                  # GPG-Key URL (optional)
```

**Felder:**

- `name`: Eindeutiger Mirror-Identifier (wird in Roll-Listen referenziert)
- `url`: Basis-URL des Upstream-Repositories
- `dist`: Distribution/Release-Name
- `components`: Liste der Komponenten (main, restricted, universe, multiverse)
- `arch_filter`:
  - String: `"amd64,all"` (kommagetrennt)
  - Liste: `["amd64", "all"]`
  - Leer/nicht gesetzt: Alle Architekturen
- `key_url`: URL zum GPG-Key (optional, Ubuntu-Keys sind vorinstalliert)

#### repo_self_list_var

Roll-Listen (Paketlisten) für jeden Mirror

```yaml
repo_self_list_var:
  ubuntu-noble-main:          # Muss mit aptly_mirrors.name übereinstimmen
    roll:
      - name: "nginx"         # Paketname
      - name: "postgresql-16"
      - name: "python3-pip"
  
  ubuntu-noble-universe:
    roll:
      - name: "docker.io"
      - name: "ansible"
```

**Struktur:**

- Key: Mirror-Name (muss in `aptly_mirrors` existieren)
- `roll`: Liste von Paketen
  - `name`: Exakter Paketname

### Optionale Variablen

```yaml
# Status des Playbooks
allg_status: "aktiviert"  # aktiviert | deaktiviert | deinstalliert

# Batch-Größe (derzeit nicht verwendet, für zukünftige Erweiterungen)
git_batch_size: 20

# AWX Job ID (automatisch gesetzt)
awx_job_id: "12345"
```

---

## WORKFLOW

### Phase 1: Vorhandene Mirrors ermitteln

```yaml
- aptly mirror list -raw
```

Erstellt Liste aller bereits existierenden Mirrors.

### Phase 2: Unerwünschte Mirrors löschen

Mirrors die in Aptly existieren, aber NICHT in `aptly_mirrors` definiert sind, werden gelöscht:

```yaml
- aptly mirror drop -force <mirror-name>
- aptly db cleanup
```

**Beispiel:**

```
Vorhanden: ubuntu-noble-main, ubuntu-jammy-main, old-mirror
Definiert:  ubuntu-noble-main, ubuntu-noble-universe

→ Gelöscht: ubuntu-jammy-main, old-mirror
```

### Phase 3: GPG-Infrastruktur

Erstellt notwendige Verzeichnisse und importiert Ubuntu-Basis-Keys:

```bash
/root/.aptly/
/root/.aptly/public/
/root/.gnupg/trustedkeys.gpg
```

Importiert Ubuntu-Archiv-Keys automatisch.

### Phase 4: Mirror-Verarbeitung (pro Mirror)

Für jeden Mirror in `aptly_mirrors`:

#### 4.1 GPG Key importieren

```bash
curl -fsSL {{ key_url }} -o /tmp/{{ name }}.gpg
gpg --import /tmp/{{ name }}.gpg
```

Übersprungen wenn `key_url` nicht definiert.

#### 4.2 Architektur-Filter normalisieren

Konvertiert verschiedene Eingabeformate zu einheitlicher Liste:

```yaml
# Eingabe: "amd64,all"  oder  ["amd64", "all"]
# Ausgabe: ["amd64", "all"]

# Eingabe: leer/null/all
# Ausgabe: ["all"]
```

#### 4.3 Paket-Filter generieren

Prüft ob Roll-Liste für Mirror existiert:

```yaml
pkglist_exists: "{{ item.name in repo_self_list_var }}"
```

Erstellt Filter-String:

```
(Name (= nginx) | Name (= postgresql-16) | Name (= python3-pip))
```

**Bei fehlender Roll-Liste:**

- Warnung ausgeben
- Mirror überspringen

#### 4.4 Architektur-Filter generieren

```
# Wenn all:
(kein Architektur-Filter)

# Wenn spezifisch:
($Architecture (= amd64) | $Architecture (= all))
```

#### 4.5 Filter kombinieren

```
# Nur Pakete:
(Name (= nginx) | Name (= postgresql))

# Pakete + Architektur:
((Name (= nginx) | Name (= postgresql)), ($Architecture (= amd64)))
```

#### 4.6 Mirror erstellen

**Wichtig:** Mirror wird immer NEU erstellt (falls vorhanden, erst löschen):

```bash
# Alten Mirror löschen
aptly mirror drop -force ubuntu-noble-main

# Neuen Mirror erstellen
aptly mirror create \
  -filter="(Name (= nginx) | Name (= postgresql))" \
  -filter-with-deps \
  -architectures="amd64,all" \
  ubuntu-noble-main \
  http://archive.ubuntu.com/ubuntu \
  noble main restricted
```

**Optionen:**

- `-filter`: Paket-Filter
- `-filter-with-deps`: Dependencies automatisch inkludieren
- `-architectures`: Nur wenn nicht "all"

#### 4.7 Mirror Update

```bash
aptly mirror update ubuntu-noble-main
```

**Error Handling:**

- 404-Fehler werden toleriert (normale Pakete wurden entfernt)
- Andere Fehler werden geloggt, brechen aber nicht ab

### Phase 5: Reporting

Sammelt Informationen über alle Mirrors:

```bash
# Pakete zählen
aptly mirror show ubuntu-noble-main | grep "Number of packages"

# Größe ermitteln
du -sm /root/.aptly
```

Gibt formatierte Übersicht aus:

```
═══════════════════════════════════════════════════
📦 APTLY MIRROR ÜBERSICHT
═══════════════════════════════════════════════════
Mirror: ubuntu-noble-main
  └─ Pakete: 2435
  └─ Größe:  8523MB
  ---------------------------------
Mirror: ubuntu-noble-universe
  └─ Pakete: 15234
  └─ Größe:  45123MB
═══════════════════════════════════════════════════
```

---

## ERROR HANDLING

### 404-Fehler beim Update

**Symptom:** `404 Not Found` während `aptly mirror update`

**Ursache:** Paket wurde aus Upstream-Repository entfernt

**Verhalten:**

- Playbook toleriert 404-Fehler
- Warnung wird ausgegeben
- Update wird fortgesetzt

### Fehlende Roll-Liste

**Symptom:** Mirror-Name in `aptly_mirrors`, aber nicht in `repo_self_list_var`

**Verhalten:**

- Warnung: `⚠️ Keine Paketliste für Mirror 'xyz' definiert`
- Mirror wird übersprungen
- Andere Mirrors werden normal verarbeitet

### GPG-Fehler

**Symptom:** `NO_PUBKEY` oder Signatur-Fehler

**Ursache:** Key nicht importiert oder falsche URL

**Lösung:**

1. Key-URL prüfen
2. Manuell importieren:

   ```bash
   curl -fsSL <key-url> | gpg --no-default-keyring \
     --keyring /root/.gnupg/trustedkeys.gpg --import
   ```

3. Playbook erneut ausführen

---

## FILTER-WITH-DEPS

**Option:** `-filter-with-deps`

**Bedeutung:** Inkludiert automatisch alle Dependencies der gefilterten Pakete

**Beispiel:**

```
Roll: nginx

Mit -filter-with-deps:
- nginx
- libc6
- libssl3
- zlib1g
- ... (alle Dependencies)

Ohne -filter-with-deps:
- nur nginx (Installation schlägt fehl!)
```

**Empfehlung:** Immer aktiviert lassen!

---

## ARCHITEKTUR-FILTER

### Verfügbare Architekturen

- `amd64`: x86_64 (64-bit Intel/AMD)
- `arm64`: ARM 64-bit (z.B. Raspberry Pi 4)
- `armhf`: ARM 32-bit Hardware Float
- `i386`: x86 32-bit
- `all`: Architektur-unabhängig (Skripte, Daten, etc.)

### Typische Kombinationen

**Server (x86):**

```yaml
arch_filter: "amd64,all"
```

**ARM-Systeme:**

```yaml
arch_filter: "arm64,all"
```

**Multi-Architektur:**

```yaml
arch_filter: "amd64,arm64,all"
```

**Alle Architekturen:**

```yaml
arch_filter: "all"
# oder nicht setzen
```

---

## REPOSITORY-STRUKTUR

### Aptly Datenbank

```
/root/.aptly/
├── aptly.conf              # Konfiguration
├── db/                     # Datenbank (BoltDB)
│   ├── packages/           # Paket-Metadaten
│   └── refs/               # Referenzen
├── pool/                   # Paket-Dateien (.deb)
│   ├── main/
│   └── universe/
└── public/                 # Publish-Verzeichnis (leer nach Mirror)
```

### Mirror-Inhalt

Ein Mirror enthält:

- Paket-Metadaten (Name, Version, Dependencies)
- Referenzen zu Upstream-Paketen
- KEINE echten .deb Dateien (nur Links)

Echte .deb Dateien werden erst bei `aptly snapshot` oder `aptly publish` heruntergeladen.

---

## INTEGRATION MIT ANDEREN PLAYBOOKS

### 1. pb_inst_repo_server.yml (Voraussetzung)

Installiert:

- aptly
- nginx
- GPG-Keys
- Verzeichnisstruktur

**Muss VOR diesem Playbook laufen!**

### 2. pb_conf_aptly_snapshots.yml (Folge-Playbook)

Erstellt Snapshots aus Mirrors:

- Base-Snapshot (aktueller Stand)
- Freeze-Snapshot (eingefrorener Stand)

### 3. pb_conf_aptly_publish.yml (Folge-Playbook)

Publiziert Snapshots:

- Macht Pakete über HTTP verfügbar
- Konfiguriert nginx
- Erstellt Repository-Struktur für Clients

### Workflow-Kette

```
1. pb_inst_repo_server.yml
   → Installiert aptly und Basis-Infrastruktur

2. pb_conf_aptly_mirrors_repo_server.yml  ← DIESES PLAYBOOK
   → Erstellt und aktualisiert Mirrors

3. pb_conf_aptly_snapshots.yml
   → Erstellt Snapshots aus Mirrors

4. pb_conf_aptly_publish.yml
   → Publiziert Snapshots für Clients
```

---

## PERFORMANCE

### Mirror-Größen (Beispiele)

| Mirror | Pakete | Größe | Update-Zeit |
|--------|--------|-------|-------------|
| Ubuntu Main (klein, 50 Pakete) | ~300 | ~800 MB | 2-5 Min |
| Ubuntu Main (voll) | ~15.000 | ~45 GB | 20-60 Min |
| Ubuntu Universe (voll) | ~100.000 | ~120 GB | 1-3 Std |

### Optimierung

**Roll-Listen klein halten:**

```yaml
# Schlecht: Zu viele Pakete
roll:
  - name: "*"  # NICHT MACHEN!

# Gut: Nur benötigte Pakete
roll:
  - name: "nginx"
  - name: "postgresql-16"
```

**Mehrere Mirrors statt einem großen:**

```yaml
# Besser aufteilen:
aptly_mirrors:
  - name: "base-packages"    # Basis-System
  - name: "web-packages"     # Web-Stack
  - name: "db-packages"      # Datenbanken
```

### Speicherplatz

**Minimum:** 10 GB pro Mirror (klein)  
**Empfohlen:** 50-100 GB pro Mirror (mittel)  
**Groß:** 200+ GB pro Mirror (voll)

**Datenbank wächst:**

- Jedes Update fügt neue Paket-Versionen hinzu
- Alte Versionen bleiben erhalten
- Regelmäßig `aptly db cleanup` ausführen

---

## MONITORING

### Mirror-Status prüfen

```bash
# Alle Mirrors
aptly mirror list

# Details mit Statistik
aptly mirror show -with-packages ubuntu-noble-main

# Nur Anzahl Pakete
aptly mirror show ubuntu-noble-main | grep "Number of packages"
```

### Datenbank-Größe

```bash
# Größe gesamt
du -sh /root/.aptly

# Größe pro Verzeichnis
du -sh /root/.aptly/*

# Größe Datenbank
du -sh /root/.aptly/db
```

### Letzte Updates

```bash
# Mirror-Metadaten
cat /root/.aptly/db/refs/mirrors/<mirror-name>

# Logs
journalctl -u nginx
tail -f /var/log/aptly/*.log  # falls konfiguriert
```

---

## SICHERHEIT

### GPG-Verifikation

Jedes Mirror sollte GPG-Keys haben:

```yaml
aptly_mirrors:
  - name: "custom-repo"
    key_url: "https://example.com/repo.gpg"
```

**Warnung:** Mirrors ohne `key_url` nutzen nur Ubuntu-Standard-Keys!

### Trusted Keys

Alle Keys liegen in:

```
/root/.gnupg/trustedkeys.gpg
```

**Niemals:**

- Unbekannte Keys importieren
- Keys von HTTP (statt HTTPS) laden
- --no-check-gpg verwenden

### Network Security

Mirror-Updates brauchen Internet-Zugang:

- Nur zu vertrauenswürdigen Repositories
- Über HTTPS wenn möglich
- Firewall: Ausgehend Port 80/443 erlauben

---

## BEISPIEL-KONFIGURATIONEN

### Minimal (Ubuntu Base)

```yaml
allg_status: aktiviert

aptly_mirrors:
  - name: "ubuntu-noble-minimal"
    url: "http://archive.ubuntu.com/ubuntu"
    dist: "noble"
    components: ["main"]
    arch_filter: "amd64,all"

repo_self_list_var:
  ubuntu-noble-minimal:
    roll:
      - name: "openssh-server"
      - name: "vim"
      - name: "curl"
```

### Multi-Mirror (Web + DB)

```yaml
allg_status: aktiviert

aptly_mirrors:
  - name: "web-stack"
    url: "http://archive.ubuntu.com/ubuntu"
    dist: "noble"
    components: ["main", "universe"]
    arch_filter: "amd64,all"
  
  - name: "database-stack"
    url: "http://archive.ubuntu.com/ubuntu"
    dist: "noble"
    components: ["main", "universe"]
    arch_filter: "amd64,all"

repo_self_list_var:
  web-stack:
    roll:
      - name: "nginx"
      - name: "apache2"
      - name: "php8.3"
      - name: "nodejs"
  
  database-stack:
    roll:
      - name: "postgresql-16"
      - name: "mysql-server-8.0"
      - name: "redis-server"
      - name: "mongodb"
```

### Custom Repository

```yaml
allg_status: aktiviert

aptly_mirrors:
  - name: "docker-ce"
    url: "https://download.docker.com/linux/ubuntu"
    dist: "noble"
    components: ["stable"]
    arch_filter: "amd64"
    key_url: "https://download.docker.com/linux/ubuntu/gpg"

repo_self_list_var:
  docker-ce:
    roll:
      - name: "docker-ce"
      - name: "docker-ce-cli"
      - name: "containerd.io"
      - name: "docker-buildx-plugin"
      - name: "docker-compose-plugin"
```

---

## TROUBLESHOOTING CHECKLISTE

- [ ] aptly installiert? (`aptly version`)
- [ ] Internet-Zugang? (`ping archive.ubuntu.com`)
- [ ] GPG-Keys vorhanden? (`gpg --list-keys`)
- [ ] Roll-Listen definiert? (in `repo_self_list_var`)
- [ ] Mirror-Namen konsistent? (aptly_mirrors ↔ repo_self_list_var)
- [ ] Genug Speicherplatz? (`df -h /root/.aptly`)
- [ ] Upstream-Repository erreichbar? (`curl -I <url>`)

---

## HÄUFIGE FEHLER

**Fehler:** `Failed to create mirror: already exists`  
**Lösung:** Playbook löscht bestehende Mirrors automatisch

**Fehler:** `Package xyz not found in filter`  
**Lösung:** Paketname in Roll-Liste prüfen (Tippfehler?)

**Fehler:** `NO_PUBKEY`  
**Lösung:** GPG-Key fehlt, `key_url` setzen

**Fehler:** `Architecture xyz not available`  
**Lösung:** Architektur existiert nicht im Upstream-Repo

---

## DOKUMENTATION ERWEITERN

Für AWX-Job-Dokumentation siehe:

```
playbook/system/tasks/repo_server_aptly/doku/aptly_mirrors_doku.md.j2
```

Schnellhilfe siehe:

```
playbook/system/tasks/repo_server_aptly/doku/help.txt
```

---

**Dokumentversion:** 1.0  
**Erstellt:** 2026-02-15  
**Playbook:** pb_conf_aptly_mirrors_repo_server.yml

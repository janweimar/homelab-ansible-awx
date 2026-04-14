# Playbook: pb_conf_cgit_publishing_server.yml

## Beschreibung

Synchronisiert Git-Repositories für den cgit Publishing Server durch Batch-Verarbeitung.

## Zweck

- Git-Repositories automatisch klonen/aktualisieren
- Nicht mehr benötigte Repos entfernen
- Batch-Verarbeitung für große Repository-Listen
- Error Reporting und Logging

## Voraussetzungen

- cgit muss installiert sein (via pb_inst_repo_server.yml)
- SSH-Key für Git-Zugriff konfiguriert
- nginx läuft
- /srv/git existiert

## Variablen

### Pflicht

```yaml
git_clone_list:
  - name: repo_name        # Name ohne .git
    url: https://...       # Clone URL
    description: "Text"    # Optional: Beschreibung
```

### Optional

```yaml
git_batch_size: 20        # Default: 20 Repos pro Batch
awx_job_id: "{{ tower_job_id }}"  # Für Reporting
```

## Workflow

### 1. Vorbereitung

- Erstellt /root/git_repo/ Verzeichnis
- Kopiert localhost-Playbooks auf Target

### 2. Bestandsaufnahme

- Listet vorhandene *.git Repos in /srv/git
- Berechnet Diff zu git_clone_list

### 3. Lösch-Phase

- Teilt zu löschende Repos in Batches
- Führt localhost_conf_git_remove.yml pro Batch aus
- Batch-Größe konfigurierbar

### 4. Klon-Phase

- Teilt neue Repos in Batches
- Führt localhost_conf_git_add.yml pro Batch aus
- Async mit 3600s Timeout
- Poll-Intervall: 10s

### 5. Reporting

- Sammelt fehlgeschlagene Klone in JSON
- Erstellt Report mit allen Failures
- Cleanup der Temp-Dateien

## Batch-Verarbeitung

### Vorteile

- Große Repository-Listen (100+) handhabbar
- Parallele Verarbeitung möglich
- Fehler-Isolation pro Batch
- Progress-Tracking

### Konfiguration

```yaml
git_batch_size: 20  # Anzahl Repos pro Batch
```

### Beispiel: 50 Repos

```
Batch 1: Repos 1-20
Batch 2: Repos 21-40
Batch 3: Repos 41-50
```

## Error Handling

### Failed Clones

Fehlgeschlagene Klone werden gesammelt in:

```
/tmp/ansible_git_clone/clone_failed_{job_id}/failed_repos_{batch}.json
```

### Finale Zusammenfassung

```
=== GIT MIRRORING REPORT (Job 1234) ===
Fehlgeschlagene Repos (3): ['repo1', 'repo2', 'repo3']
```

### Häufige Fehler

- SSH-Key fehlt/falsch
- Repository nicht erreichbar
- Berechtigungsfehler
- Netzwerk-Timeout

## Git-Mirror Optionen

### --mirror

- Klont ALLE Refs (Branches, Tags)
- Bare Repository (kein Checkout)
- Optimal für Server-Side Mirrors

### --no-recurse-submodules

- Keine Submodules klonen
- Reduziert Speicher und Zeit

## Repository-Struktur

```
/srv/git/
├── repo1.git/
│   ├── description          # Repository-Beschreibung
│   ├── git-daemon-export-ok # cgit-Marker
│   ├── config
│   └── refs/
├── repo2.git/
└── repo3.git/
```

## Localhost-Playbooks

### localhost_conf_git_add.yml

- Klont Repositories als Mirror
- Setzt Metadaten (description, export-ok)
- Sammelt Fehler in JSON

### localhost_conf_git_remove.yml

- Löscht Repositories in Batch
- Sicherheits-Check (Batch nicht leer)

## Berechtigungen

Nach dem Klonen:

```bash
chown -R www-data:www-data /srv/git
chmod -R 2775 /srv/git
```

## Integration

### Mit pb_inst_repo_server.yml

1. Erst pb_inst_repo_server.yml → Installiert cgit
2. Dann pb_conf_cgit_publishing_server.yml → Synchronisiert Repos

### AWX Job Template

```
Name: 0009_<ip_repo_server>_conf_cgit_publishing
Project: Ansible Automation
Playbook: pb_conf_cgit_publishing_server.yml
Inventory: Production
Credentials: SSH repo_max
Extra Variables: { "git_clone_list": [...] }
```

## Performance

### Typische Zeiten

- 1 Repo: ~5-30 Sekunden
- 20 Repos (Batch): ~2-10 Minuten
- 100 Repos: ~10-50 Minuten

### Optimierung

- Batch-Größe erhöhen (max ~50)
- Netzwerk-Bandbreite prüfen
- SSH-Kompression aktivieren

## Beispiel git_clone_list

```yaml
git_clone_list:
  - name: ansible
    url: https://github.com/ansible/ansible.git
    description: Ansible Automation Platform
    
  - name: terraform
    url: https://github.com/hashicorp/terraform.git
    description: Infrastructure as Code
    
  - name: kubernetes
    url: https://github.com/kubernetes/kubernetes.git
    description: Container Orchestration
    
  # Über 100 weitere möglich...
```

## Monitoring

### Während Ausführung

```bash
# Anzahl Repos
ls -1 /srv/git/*.git | wc -l

# Aktive Git-Prozesse
ps aux | grep git

# Disk Usage
du -sh /srv/git
```

### Nach Ausführung

```bash
# Error Reports
cat /tmp/ansible_git_clone/clone_failed_*/failed_repos_*.json

# Git-Status
cd /srv/git/<n>.git && git log -1
```

## Sicherheit

### SSH-Keys

- Nur Read-Only Keys verwenden
- Deploy Keys pro Repository empfohlen
- StrictHostKeyChecking=no nur für Automation

### Umgebungsvariablen

```bash
GIT_TERMINAL_PROMPT=0        # Keine Passwort-Prompts
GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"
```

## Siehe auch

- pb_inst_repo_server.yml - Installation
- repo_server_task_check.yml - Status-Checks
- cgit Dokumentation: <https://git.zx2c4.com/cgit/about/>

# PLAYBOOK DOKUMENTATION - Benutzer & SSH Sicherheit

## ÜBERSICHT

**Playbook:** `pb_conf_add_user_add_ssh_key_secure.yml`  
**Kategorie:** Konfiguration / Sicherheit  
**Status:** Produktiv  
**Version:** 1.0  
**Letzte Änderung:** 2025-01-25  
**Autor:** System

**Kurzbeschreibung:**

Erstanmeldung mit root
Erstellt einen neuen Benutzer mit sudo-Rechten, konfiguriert SSH-Key Authentifizierung und härtet die SSH-Konfiguration.

---

## AUFGABE / ANFORDERUNGEN

### Was macht das Playbook?

- Erstellt neuen Benutzer mit Passwort und sudo-Rechten
- Konfiguriert SSH Public Key Authentifizierung
- Schützt SSH-Config vor APT-Updates (Debian/Ubuntu)
- Deployed gehärtete SSH-Konfiguration
- Ändert SSH-Port von 22 auf 2222
- Deaktiviert Passwort-Authentifizierung
- Deaktiviert Root-Login
- Startet System neu für SSH-Änderungen

### Anwendungsfall

Wann und warum wird dieses Playbook benötigt?

**Beispiel-Szenario:**

```text
Neuer Server wird aufgesetzt und benötigt einen Admin-Benutzer
mit SSH-Key Zugang. SSH soll gegen Brute-Force und 
Standard-Angriffe abgesichert werden.
```

---

## VORAUSSETZUNGEN

### Muss bereits installiert sein (Prerequisites)

- [x] **sshd** - SSH Server Daemon (OpenSSH)
- [x] **sudo** - Sudo-Rechte Verwaltung

### Benötigte System-Ressourcen

- **CPU:** 1 Core
- **RAM:** 512 MB
- **Disk:** 100 MB
- **OS:** Debian 12, Ubuntu 22.04, RedHat 9, etc.

### Netzwerk-Anforderungen

- [x] Internet-Zugang für System-Updates (optional)
- [x] Port 2222 muss von Firewall erlaubt werden
- [x] SSH-Zugriff muss nach Reboot auf neuem Port möglich sein

### Benötigte externe Ressourcen

- [x] SSH Public Key Datei
- [x] Benutzer-Credentials (AWX)

---

## UNTERSTÜTZTE BETRIEBSSYSTEME

| OS        | Version | Status | Bemerkung |
| --------- | ------- | ------ | --------- |
| Debian    | 12      | ✓      | Empfohlen |
| Debian    | 11      | ✓      | -         |
| Ubuntu    | 22.04   | ✓      | -         |
| Ubuntu    | 20.04   | ✓      | -         |
| RedHat    | 9       | ✓      | -         |
| RedHat    | 8       | ✓      | -         |
| Suse      | 15      | ✓      | -         |
| Archlinux | Latest  | ✓      | -         |
| FreeBSD   | 13      | ✓      | -         |

---

## CREDENTIALS & ZUGANGSDATEN

### Übersicht benötigter Credentials

| Credential | Typ | Pflicht | Verwendet für | Speicherort |
| ------------ | ---------- | ------- | ----------------- | ------------- |
| root_access | Machine | ✓ | Server-Zugriff als root | AWX |
| user_credentials | Custom | ✓ | Neuer Benutzer + Passwort | AWX |
| ssh_public_key | File | ✓ | SSH Public Key | templates/*.pub |

### Credential-Aufbau

#### 1. root_access (Machine Credential)

**Credential Type:** Machine

```yaml
Username: root
Password: <root-password>
# ODER
SSH Private Key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----
Privilege Escalation Method: sudo
```

**Verwendung:** Initiale Anmeldung am Server um den neuen User anzulegen.

#### 2. user_credentials (Custom Credential)

**Credential Type:** Custom (muss in AWX angelegt werden)

**Custom Credential Type erstellen in AWX:**

```yaml
Name: User Management Credentials
Description: Credentials für Benutzer-Verwaltung

Input Configuration:
  fields:
    - id: add_user_sudo
      type: string
      label: Name User
    - id: new_user_password
      type: string
      label: New User Password
      secret: true

Injector Configuration:
  extra_vars:
    add_user_sudo: "{{ add_user_sudo }}"
    new_user_password: "{{ new_user_password }}"
```

**Credential ausfüllen:**

```yaml
Name User: admin
New User Password: <sicheres-passwort>
```

#### 3. ssh_public_key (File)

**Speicherort:** `tasks/add_user_ssh/templates/<servername>.pub`

**SSH-Key erstellen:**

```bash
# Key generieren
ssh-keygen -t ed25519 -C "admin@repo-server" -f ~/.ssh/repo_admin

# Public Key anzeigen
cat ~/.ssh/repo_admin.pub
```

**Public Key speichern:**

```bash
# Datei erstellen
F:\OneDrive\Projekt\__git\ansible\projekt\playbook\system\tasks\add_user_ssh\templates\repo_server.pub

# Inhalt:
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJxK... admin@repo-server
```

**WICHTIG:**

- Jeder Server bekommt eigenen SSH-Key!
- Dateiname z.B.: `repo_admin.pub`, `web_admin.pub`, `db_admin.pub`
- Nur Public Key (.pub) speichern, Private Key GEHEIM halten!

### Credential-Zuweisung in AWX Job Template

1. **Credentials hinzufügen:**
   - name: cred_root_user_pass_(serv_ip)
      - Machine Credential: `root_access`
   - name: cred_add_user_passw_sudo_(serv_ip)
      - Custom Credential: `cred_user`

2. **Extra Vars:**

```yaml
allg_status: aktiviert
ssh_port: 2222
ssh_public_key_file: "repo_admin.pub"  # Dateiname im templates Ordner
```

---

## VARIABLEN-CHECKLISTE

### Pflicht-Variablen (müssen aus AWX Credentials kommen)

- [x] **add_user_sudo** - Benutzername des anzulegenden Users
- [x] **new_user_password** - Passwort für den neuen Benutzer

### Optionale Variablen (mit Defaults)

- [ ] **ssh_port** - SSH Port (Default: `2222`)
- [ ] **update_system** - System-Update durchführen (Default: `true`)
- [ ] **debug_output** - Debug-Ausgaben anzeigen (Default: `false`)
- [ ] **allg_status** - `aktiviert` / `deaktiviert` / `deinstalliert`
- [ ] **ssh_public_key_file** - Dateiname des SSH Public Keys (Default: `repo_admin.pub`)

### Erweiterte Variablen (für Spezialfälle)

Keine.

---

## WICHTIGE VARIABLEN (var_)

### var_pack_name

```yaml
var_pack_name: []
```

**Beschreibung:** Leer, da keine Pakete installiert werden (nur Konfiguration).

### var_dependencies_list

```yaml
var_dependencies_list: []
```

**Beschreibung:** Leer, da keine Dependencies benötigt werden.

### var_prerequisites

```yaml
var_prerequisites:
  - sshd
  - sudo
```

**Beschreibung:** Voraussetzungen die bereits installiert sein MÜSSEN. Playbook prüft diese.

### var_inst_order

```yaml
var_inst_order: 0
```

**Beschreibung:** Keine Relevanz, da keine Installation erfolgt.

### unsupported_systems

```yaml
unsupported_systems: []
```

**Beschreibung:** Alle gängigen Systeme werden unterstützt.

---

## OS-SPEZIFISCHE VARIABLEN

### Benötigte Einträge in os_paths.yml

```yaml
paths:
  ssh:
    config:
      Debian: /etc/ssh/sshd_config
      RedHat: /etc/ssh/sshd_config
      # ... weitere OS
    sudoers_d:
      Debian: /etc/sudoers.d
      RedHat: /etc/sudoers.d
      # ... weitere OS
    apt_protect:
      Debian: /etc/apt/apt.conf.d/90preserve-ssh
      RedHat: /etc/yum/yum.conf.d/90preserve-ssh
      # ... weitere OS
```

### Benötigte Einträge in os_services.yml

```yaml
services:
  ssh:
    name:
      Debian: "sshd"
      RedHat: "sshd"
      # ... weitere OS
    start:
      Debian: "systemctl start sshd"
      # ... weitere OS
    restart:
      Debian: "systemctl restart sshd"
      # ... weitere OS
```

### Benötigte Einträge in os_command.yml

```yaml
commands:
  ssh:
    validate_config:
      Debian: "/usr/sbin/sshd -t -f %s"
      RedHat: "/usr/sbin/sshd -t -f %s"
      # ... weitere OS
```

---

## INSTALLATIONS-ABLAUF

### Phase 1: Pre-Tasks

1. System-Update durchführen (optional)
2. Variablen validieren (add_user_sudo, new_user_password, ssh_public_key_file)
3. SSH Public Key Existenz prüfen
4. Backup der aktuellen sshd_config erstellen

### Phase 2: Hauptkonfiguration

1. Benutzer anlegen mit Passwort und Home-Verzeichnis
2. Benutzer zu sudo/wheel Gruppe hinzufügen
3. Sudo-Rechte in /etc/sudoers.d/ konfigurieren
4. SSH Public Key in authorized_keys hinzufügen
5. APT-Schutz für SSH-Config einrichten (Debian/Ubuntu)
6. Gehärtete SSH-Config deployen

### Phase 3: System-Neustart

1. Reboot-Befehl wird gesendet, Playbook beendet sofort ohne Wartezeit
2. Nach Reboot ist nur noch SSH-Key Authentifizierung auf Port 2222 möglich

---

## DATEI-STRUKTUR

### Playbook-Dateien

```text
ansible/projekt/playbook/system/
├── pb_conf_add_user_add_ssh_key_secure.yml    # Haupt-Playbook
└── tasks/
    └── add_user_ssh/
        ├── add_user_ssh_pretask.yml            # Vorbereitungen
        ├── add_user_ssh_task.yml               # Hauptkonfiguration
        ├── templates/
        │   ├── sshd_config_secure.j2           # SSH Config Template
        │   ├── repo_admin.pub                  # SSH Key für Repo-Server
        │   ├── web_admin.pub                   # SSH Key für Web-Server
        │   └── db_admin.pub                    # SSH Key für DB-Server
        └── PB_ADD_USER_SSH_DOKU.md             # Diese Doku
```

### Erstellte Dateien auf dem Server

```bash
# Benutzer
/home/<add_user_sudo>/
/home/<add_user_sudo>/.ssh/authorized_keys

# Konfiguration
/etc/ssh/sshd_config
/etc/ssh/sshd_config.backup-<timestamp>
/etc/sudoers.d/<add_user_sudo>
/etc/apt/apt.conf.d/90preserve-ssh  # Debian/Ubuntu only
```

---

## VERWENDUNG

### Minimale Ausführung

```bash
ansible-playbook pb_conf_add_user_add_ssh_key_secure.yml \
  -e "allg_status=aktiviert" \
  -e "add_user_sudo=admin" \
  -e "new_user_password=SecurePass123" \
  -e "ssh_public_key_file=repo_admin.pub"
```

### Mit optionalen Variablen

```bash
ansible-playbook pb_conf_add_user_add_ssh_key_secure.yml \
  -e "allg_status=aktiviert" \
  -e "add_user_sudo=admin" \
  -e "new_user_password=SecurePass123" \
  -e "ssh_public_key_file=repo_admin.pub" \
  -e "ssh_port=2222" \
  -e "update_system=true" \
  -e "debug_output=false"
```

### In AWX

1. Job Template erstellen
2. Credentials zuweisen:
   - `root_access` (Machine) - für Server-Zugriff
   - `user_credentials` (Custom) - für add_user_sudo, new_user_password
3. Extra Vars setzen:

```yaml
allg_status: aktiviert
ssh_port: 2222
ssh_public_key_file: "repo_admin.pub"
```

4.Job starten

**WICHTIG:** Nach Job-Ausführung ändert sich der SSH-Port auf 2222!

---

## DEINSTALLATION

### Hinweis

**Dieses Playbook kann NICHT deinstalliert werden!**

Benutzer und SSH-Konfiguration müssen manuell zurückgesetzt werden:

```bash
# Backup wiederherstellen
cp /etc/ssh/sshd_config.backup-<timestamp> /etc/ssh/sshd_config
systemctl restart sshd

# Benutzer löschen (optional)
userdel -r <add_user_sudo>

# Sudoers-Datei entfernen (optional)
rm /etc/sudoers.d/<add_user_sudo>
```

---

## TROUBLESHOOTING

### Problem: SSH-Verbindung nach Reboot nicht möglich

**Symptom:**

```text
ssh: connect to host <server> port 2222: Connection refused
```

**Lösung:**

1. Prüfe ob SSH-Service läuft: `systemctl status sshd`
2. Prüfe Firewall-Regeln: `nft list ruleset | grep 2222`
3. Prüfe sshd_config Syntax: `sshd -t`
4. Prüfe Logs: `journalctl -u sshd -n 50`
5. Notfall: Console-Zugriff nutzen und Port zurücksetzen

### Problem: SSH-Key wird nicht akzeptiert

**Symptom:**

```text
Permission denied (publickey)
```

**Lösung:**

1. Prüfe Dateirechte: `ls -la /home/<user>/.ssh/`
2. Sollte sein: `.ssh` = 700, `authorized_keys` = 600
3. Prüfe Key-Format: `ssh-keygen -l -f authorized_keys`
4. Prüfe sshd_config: `grep PubkeyAuthentication /etc/ssh/sshd_config`
5. Debug-Modus: `ssh -vvv <user>@<server> -p 2222`

### Problem: Sudo-Rechte funktionieren nicht

**Symptom:**

```text
<user> is not in the sudoers file. This incident will be reported.
```

**Lösung:**

1. Prüfe sudoers-Datei: `cat /etc/sudoers.d/<user>`
2. Prüfe Rechte: `ls -l /etc/sudoers.d/<user>` (sollte 440 sein)
3. Prüfe Syntax: `visudo -cf /etc/sudoers.d/<user>`
4. Prüfe Gruppenzugehörigkeit: `groups <user>`

### Problem: APT-Update überschreibt sshd_config

**Symptom:**

SSH-Config wird bei APT-Update zurückgesetzt.

**Lösung:**

1. Prüfe ob APT-Schutz existiert: `cat /etc/apt/apt.conf.d/90preserve-ssh`
2. Falls nicht, manuell erstellen (siehe Datei-Struktur)
3. Nach APT-Update: Config-Backup wiederherstellen

---

## TESTING

### Manuelle Tests nach Installation

```bash
# 1. Neuen User prüfen
id <add_user_sudo>
groups <add_user_sudo>

# 2. Sudo-Rechte testen
su - <add_user_sudo>
sudo whoami  # sollte "root" zurückgeben

# 3. SSH-Key Authentifizierung testen
ssh <add_user_sudo>@<server> -p 2222 -i ~/.ssh/repo_admin

# 4. SSH-Config prüfen
sudo sshd -t
sudo grep -E "Port|PasswordAuthentication|PermitRootLogin|AllowUsers" /etc/ssh/sshd_config

# 5. SSH-Service Status
sudo systemctl status sshd
```

---

## SICHERHEITS-HINWEISE

### SSH-Härtung

- ✓ Port 2222 (nicht Standard)
- ✓ Nur moderne Verschlüsselung (chacha20-poly1305, aes256-gcm)
- ✓ Nur SSH Protocol 2
- ✓ MaxAuthTries 3
- ✓ LoginGraceTime 30s
- ✓ ClientAliveInterval 300

### Authentifizierung

- ✓ Nur SSH-Keys (kein Passwort)
- ✓ Root-Login deaktiviert
- ✓ Nur bestimmte Benutzer erlaubt (AllowUsers)
- ✓ PAM aktiviert

### Berechtigungen

- Config-Dateien: `0600` (root:root)
- Sudoers-Dateien: `0440` (root:root)
- .ssh Verzeichnis: `0700` (user:user)
- authorized_keys: `0600` (user:user)

### Wichtige Warnungen

⚠️ **WARNUNG 1:** System wird nach Ausführung neu gestartet!  
⚠️ **WARNUNG 2:** SSH-Port ändert sich von 22 auf 2222!  
⚠️ **WARNUNG 3:** Nach Reboot nur noch SSH-Key Authentifizierung möglich!  
⚠️ **WARNUNG 4:** Root-Login wird deaktiviert!  
⚠️ **WARNUNG 5:** Stelle sicher dass Firewall Port 2222 erlaubt!

---

## WARTUNG

### Tägliche Aufgaben

- [ ] SSH-Logs prüfen: `journalctl -u sshd | grep Failed`
- [ ] Sudo-Logs prüfen: `journalctl | grep sudo`

### Wöchentliche Aufgaben

- [ ] Authorized Keys prüfen
- [ ] Sudo-Rechte reviewen
- [ ] SSH-Config Backup erstellen

### Monatliche Aufgaben

- [ ] SSH-Version prüfen
- [ ] Security-Updates installieren
- [ ] SSH-Keys rotieren (Best Practice)

---

## BEKANNTE PROBLEME

| Problem | Status | Workaround | Fix geplant |
| ------- | ------ | ---------- | ----------- |
| -       | -      | -          | -           |

---

## ÄNDERUNGSHISTORIE

| Datum      | Version | Änderung                           | Autor  |
| ---------- | ------- | ---------------------------------- | ------ |
| 2025-01-25 | 1.0     | Initial - MPB-konform überarbeitet | System |

---

## REFERENZEN

### Dokumentation

- OpenSSH Docs: <https://www.openssh.com/manual.html>
- SSH Security: <https://stribika.github.io/2015/01/04/secure-secure-shell.html>

### Verwandte Playbooks

- `pb_inst_firewall_nftables.yml` - Firewall für Port 2222
- `pb_inst_fail2ban_nftables.yml` - SSH Brute-Force Schutz

### Interne Links

- [Server-Dokumentation](../../MUSTER_SERVER_DOKU.md)
- [Variablen-Dokumentation](../../MUSTER_VARS_DOKU.md)

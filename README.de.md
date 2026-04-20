# homelab-ansible-awx

AWX-basierte Homelab-Automatisierung mit Ansible — eigenständige Playbooks, Custom Credential Types, K3s-Deployments, Firewall, VPN und DNS-Provider-API-Anbindung.

---

## Überblick

Dieses Repository enthält meine Ansible-Playbooks und AWX-Konfiguration für ein selbst gehostetes Homelab mit mehreren Ubuntu 24.04 VPS-Servern.

Grundgedanke: **Jedes Playbook läuft eigenständig.** Workflows sind nur eine Aneinanderreihung von Playbooks — mehr nicht. Es gibt keine harten Abhängigkeiten zwischen Playbooks, und keine Magie die nur bei bestimmter Reihenfolge funktioniert. Wenn ein Playbook etwas braucht (z.B. nginx, K3s), bringt es das als Include-Task selbst mit.

---

## Quick Start

Am einfachsten: Das AWX-Backup in eine frische AWX-Installation importieren. Der Ordner `komplette_AWX_sicherung/` enthält alle Credential Types, Job Templates und Workflows als JSON-Export, direkt importierbar.

---

## Playbooks

Playbooks sind die primäre Einheit in diesem Repository. Jedes ist **eigenständig und idempotent** — du kannst jedes Playbook auf jedem Server jederzeit laufen lassen, und es wird das Richtige tun.

### Basissystem

| Playbook                                   | Beschreibung                                                     |
|--------------------------------------------|------------------------------------------------------------------|
| `pb_setup_add_sudo_user_add_ssh_key_secure.yml` | Sudo-User anlegen, SSH-Key hinzufügen, SSH härten          |
| `pb_setup_msmtp.yml`                       | Ausgehender Mailversand via msmtp                                 |
| `pb_setup_network.yml`                     | Netzwerk-Konfiguration (gai.conf, nload)                          |
| `pb_setup_logrotate.yml`                   | Log-Rotation                                                      |
| `pb_setup_auto_update.yml`                 | Unbeaufsichtigte Sicherheitsupdates                               |
| `pb_setup_audit.yml`                       | auditd System-Auditing                                            |
| `pb_setup_cronjobs.yml`                    | Cronjobs                                                          |

### Firewall & Netzwerk-Sicherheit

| Playbook                          | Beschreibung                                              |
|-----------------------------------|-----------------------------------------------------------|
| `pb_setup_firewall_nftables.yml`  | nftables Firewall mit automatischem Rollback               |
| `pb_setup_geoblock_nftables.yml`  | GeoIP-Blocking (Allow-Liste konfigurierbar)                |
| `pb_setup_fail2ban_nftables.yml`  | Brute-Force-Schutz (alle Jails in einem Lauf)              |

### VPN

| Playbook                     | Beschreibung                                    |
|------------------------------|-------------------------------------------------|
| `pb_setup_vpn_server.yml`    | WireGuard VPN-Gateway                            |
| `pb_setup_vpn_client.yml`    | WireGuard VPN-Client                             |

### Sicherheit & Monitoring

| Playbook                       | Beschreibung                                      |
|--------------------------------|---------------------------------------------------|
| `pb_setup_rkhunter.yml`        | Rootkit-Scanner (mit Baseline)                     |
| `pb_setup_suricata.yml`        | IDS/IPS Netzwerk-Monitoring                        |
| `pb_setup_wazuh_manager.yml`   | Wazuh Zentrales Monitoring (inkl. nginx)           |
| `pb_setup_wazuh_agent.yml`     | Wazuh-Agent                                        |
| `pb_setup_appamor.yml`         | AppArmor Prozess-Einschränkungen                   |
| `pb_setup_alerting.yml`        | Alerting-Konfiguration                             |

### Repo- / Jump-Server

| Playbook                                     | Beschreibung                                            |
|----------------------------------------------|---------------------------------------------------------|
| `pb_setup_add_repos_client.yml`              | Eigene APT-Repos auf Clients hinzufügen                  |
| `pb_setup_repo_server.yml`                   | Aptly + cgit + Helm-Registry (inkl. nginx)               |
| `pb_setup_aptly_mirrors_repo_server.yml`     | Aptly-Mirrors konfigurieren                              |
| `pb_setup_aptly_publishing_repo_server.yml`  | Aptly-Repos publizieren                                  |
| `pb_conf_helm_charts_repo_server.yml`        | Helm-Chart-Registry-Konfiguration                        |
| `pb_setup_cgit_publishing_server.yml`        | Git-Mirrors via cgit                                     |
| `pb_setup_cgit_update.yml`                   | cgit-Mirrors aktualisieren                               |
| `pb_setup_awx_ee.yml`                        | AWX Execution Environment Image bauen                    |

### Universal App Deploy

| Playbook                    | Beschreibung                                                       |
|-----------------------------|--------------------------------------------------------------------|
| `pb_setup_app_deploy.yml`   | Universelles App-Deployment (K3s / Minikube / Docker / nativ)       |
| `pb_setup_bookstack.yml`    | BookStack Wiki (legacy standalone)                                  |
| `pb_setup_openems.yml`      | OpenEMS FDTD-Simulation                                             |
| `pb_setup_openfoam.yml`     | OpenFOAM CFD-Simulation                                             |

### Sonstiges

| Playbook                        | Beschreibung                         |
|---------------------------------|--------------------------------------|
| `pb_test_infrastruktur.yml`     | Read-only Infrastruktur-Analyse       |
| `pb_hinweis_vpn_server_pause.yml` | Workflow-Pause-Hinweis              |

---

## Universal App Deploy System

`pb_setup_app_deploy.yml` kümmert sich um alle Application-Deployments — unabhängig von Typ oder Zielumgebung. Gesteuert wird das Ganze komplett über ein AWX-Credential. Wenn K3s oder Minikube gebraucht wird und noch nicht installiert ist, wird das automatisch mitinstalliert.

### Unterstützte Apps

`stalwart` · `odoo` · `directus` · `bookstack` · `ollama` · `open-webui` · `qdrant` · `awx` · `awx-ee` · `mariadb-webui` · `openclaw` · `wazuh` · `mailu`

### Unterstützte Deployment-Typen

| Wert                                | Beschreibung            | Status              |
|-------------------------------------|-------------------------|---------------------|
| `k3s` / `k3s_v1_34` / `k3s_v1_35`  | Kubernetes via K3s      | ✅ getestet         |
| `minikube` / `minikube_v1_38`       | Kubernetes via Minikube | ✅ getestet         |
| `k8s` / `k8s_v1_34`                | Vanilla Kubernetes      | 🚧 in Arbeit        |
| `docker` / `docker_v27`             | Docker Compose          | ✅ getestet         |
| `podman` / `podman_v5`              | Podman Compose          | 🚧 in Arbeit        |
| `nativ`                             | apt + systemd           | ✅ getestet         |

### Credential-Felder

| Feld                    | Status               | Beschreibung                                              |
|-------------------------|----------------------|-----------------------------------------------------------|
| `app_name`              | Pflicht              | Zu deployende Application                                  |
| `app_deploy_type`       | Pflicht              | Deployment-Typ (siehe oben)                                |
| `app_db_type`           | Pflicht              | Datenbank: `mariadb`, `postgresql`, `mysql`, `none`        |
| `app_port`              | Pflicht              | Interner Port                                              |
| `app_db_password`       |                      | Datenbank-Passwort                                         |
| `app_admin_email`       |                      | Admin-E-Mail-Adresse                                       |
| `app_admin_password`    |                      | Admin-Passwort                                             |
| `app_secret_key`        |                      | JWT/Session Secret — `openssl rand -hex 32`                |
| `app_nginx_integration` |                      | nginx als Reverse Proxy einrichten (Include-Task)          |
| `app_ssl`               |                      | HTTPS via Let's Encrypt                                    |
| `app_modsecurity`       |                      | ModSecurity WAF in nginx aktivieren                        |
| `app_vpn_only`          |                      | App nur über WireGuard VPN erreichbar                      |
| `app_ha_install`        | 🚧 in Arbeit         | High Availability (mehrere Replicas)                       |
| `app_skip_install`      |                      | Installation überspringen, nur nginx/SSL neu konfigurieren |
| `app_no_update`         |                      | Container-Image-Updates verhindern                         |
| `isolation_app`         | 🚧 in Arbeit         | DNS-Isolation — App kann keine externen Domains erreichen  |
| `app_bez`               |                      | Optionales Environment-Tag (z.B. `test`, `prod`)           |

---

## nginx — kein eigenständiges Playbook

Es gibt **kein** `pb_setup_nginx.yml`. nginx wird immer **als Bestandteil der App installiert und konfiguriert**, die es braucht — über den Include-Task `playbook/system/tasks/nginx/`. Dadurch hängen App und Reverse Proxy eng zusammen, und es gibt keine Reihenfolge-Abhängigkeiten.

Wenn `app_nginx_integration` in `pb_setup_app_deploy.yml` aktiv ist, macht der nginx-Task:

- nginx installieren (falls nicht vorhanden)
- vHost für die App erstellen
- Let's-Encrypt-Zertifikat anfordern (wenn `app_ssl` aktiv)
- Optional ModSecurity WAF aktivieren
- **A-Record via DNS-Provider-API setzen** (siehe unten)

Dasselbe Muster gilt für `pb_setup_wazuh_manager.yml`, `pb_setup_repo_server.yml` etc. — jedes bringt seinen eigenen nginx-Include mit.

---

## DNS-Provider-API-Anbindung

DNS-Records werden automatisch über die API des Hosting-Providers verwaltet. Aktuell implementiert: **Contabo**. Der Aufbau ist provider-agnostisch (`playbook/system/api/api_router.yml` verteilt je nach `api_provider`), damit weitere Provider ergänzt werden können, ohne die aufrufenden Playbooks anzufassen.

### Was automatisch verwaltet wird

1. **A-Record über den nginx-Include-Task**
   `app_vpn_only=false` → A-Record wird angelegt/aktualisiert auf die Server-IP
   `app_vpn_only=true` → A-Record wird entfernt (App nur noch über VPN erreichbar)
   Kein manuelles DNS-Editieren nötig beim Wechsel zwischen public und VPN-only.

2. **Mail-DNS-Records über den Stalwart-Post-Task** (beim Stalwart-Deploy)
   Stalwart generiert alle nötigen Records (MX, SPF, DKIM Ed25519, DKIM RSA, DMARC, TLS-RPT, SRV für IMAP/POP3/JMAP/CalDAV/CardDAV/Submission, CNAME für autoconfig/autodiscover). Der Post-Task holt sie über die Stalwart-API und pusht sie via Provider-API — typischerweise 18+ Records pro Mail-Domain, alle idempotent.

3. **DKIM Auto-Signing**
   Das Stalwart-K3s-Manifest konfiguriert `[auth.dkim] sign = ...` automatisch, damit ausgehende Mails mit Ed25519- und RSA-Schlüsseln signiert werden — ohne manuelle Signer-Registrierung.

### Design

- **Idempotent:** DELETE + ADD statt PUT (umgeht Provider-API-Eigenheiten)
- **State-basiert:** Alte DNS-Records werden in `server_state.fact` getrackt und beim Re-Deploy bereinigt
- **Provider-agnostisch:** `api_router.yml` wählt das passende Backend anhand des `api_provider`-Credentials

### Neuen Provider hinzufügen

Um einen neuen DNS-Provider hinzuzufügen (z.B. Hetzner, Cloudflare):

1. Neuen Ordner unter `playbook/system/api/<provider>/` anlegen (siehe `contabo/` als Vorlage — auth, setup, domain, dns, cleanup)
2. Dasselbe Set an Include-Tasks implementieren (`<provider>_auth.yml`, `<provider>_dns_record.yml`, `<provider>_domain_record.yml`, etc.)
3. Branch in `api_router.yml` hinzufügen
4. Provider im Credential-Feld `api_provider` als Option ergänzen

Der `hetzner/`-Ordner existiert bereits als Stub — Contributions willkommen.

---

## Server-Workflow (Beispiel)

Workflows sind **nur eine Aneinanderreihung von Job Templates**. Jedes JT startet ein eigenständiges Playbook. Nichts ist hart verdrahtet — du kannst umsortieren, überspringen oder Schritte hinzufügen wie du willst.

Beispiel: **Odoo-Server**

```
 #  JT                          Playbook                       Anmerkung
 1  jt_setup_msmtp              pb_setup_msmtp.yml
 2  jt_setup_network            pb_setup_network.yml
 3  jt_setup_firewall           pb_setup_firewall_nftables.yml
 4  jt_setup_geoblock           pb_setup_geoblock_nftables.yml
 5  jt_setup_logrotate          pb_setup_logrotate.yml
 6  jt_setup_auto_update        pb_setup_auto_update.yml
 7  jt_setup_audit              pb_setup_audit.yml
 8  jt_setup_vpn_client         pb_setup_vpn_client.yml
 9  jt_setup_odoo               pb_setup_app_deploy.yml         app_name=odoo, inkl. nginx + A-Record
10  jt_setup_fail2ban           pb_setup_fail2ban_nftables.yml  alle Jails auf einmal
11  jt_setup_suricata           pb_setup_suricata.yml
12  jt_setup_rkhunter           pb_setup_rkhunter.yml
13  jt_setup_wazuh_agent        pb_setup_wazuh_agent.yml
14  jt_setup_apparmor           pb_setup_appamor.yml            IMMER ZULETZT
```

Wichtige Regeln:

- `apparmor` immer zuletzt — kann andere Dienste blockieren, wenn zu früh gestartet
- `fail2ban` einmalig am Ende — alle Ziel-Dienste (nginx, App) müssen vorher stehen
- `rkhunter`-Baseline nach allen anderen Installationen — saubere Grundlage
- `add_sudo_user_ssh` läuft separat vor dem Workflow — Bootstrap-Schritt

---

## Features

- **Eigenständige Playbooks** — jedes Playbook funktioniert unabhängig
- **Universal App Deploy** — K3s, Minikube, Docker, nativ
- **Custom AWX Credential Types** — saubere Variablen-Trennung
- **nftables-Firewall** mit GeoIP, fail2ban, automatischem Rollback
- **WireGuard VPN** — interne Dienste können on-demand VPN-only geschaltet werden
- **nginx-Include + ModSecurity + Let's Encrypt** — überall wo nginx gebraucht wird
- **Wazuh-Agent** auf allen Servern
- **DNS-API-Anbindung** — A-Records und Mail-Records werden automatisch gepflegt
- **Stalwart Mail Server** — K3s-Deployment mit Auto-DKIM, SPF, DMARC, MTA-STS, DANE
- **Reboot-sicher** — alle Tasks überleben einen Server-Neustart

---

## Repository-Struktur

```
projekt/
├── pb_setup_*.yml              # Playbooks (eigenständige Einstiegspunkte)
└── playbook/system/
    ├── api/                    # DNS-Provider-Anbindung (contabo, hetzner)
    ├── daten/vars/             # Zentrale Variablen (os_urls, vpn, app_resources ...)
    ├── tasks/                  # Task-Bibliothek
    │   ├── nginx/              #   → Include-Task für Reverse Proxy + A-Record
    │   ├── stalwart/           #   → Stalwart Mail Server (K3s)
    │   ├── odoo/               #   → Odoo ERP
    │   ├── nftables/           #   → Firewall / GeoBlock / fail2ban
    │   ├── wireguard/          #   → WireGuard Server & Client
    │   └── ...
    └── templates/              # Jinja2-Templates
komplette_AWX_sicherung/        # AWX-Export (Credential Types, JTs, Workflows)
```

---

## OS-Kompatibilität

Getestet nur mit **Ubuntu 24.04**.

Die Grundstruktur ist OS-neutral — alle OS-spezifischen Werte (Paketnamen, Pfade, Dienste, Versionen) werden zentral in `playbook/system/daten/vars/` gepflegt. Das Hinzufügen von Debian, Rocky Linux etc. ist eine reine Ergänzung dieser Dateien, keine Playbook-Änderung nötig.

---

## Test-Status

| Task             | Ordner                   | Status         |
|------------------|--------------------------|----------------|
| Kubernetes (k8s) | `tasks/k8s/`             | nicht getestet |
| MariaDB WebUI    | `tasks/mariadb_webui/`   | nicht getestet |
| OpenEMS          | `tasks/openems/`         | nicht getestet |
| OpenFOAM         | `tasks/openfoam/`        | nicht getestet |
| Podman           | `tasks/podman_include/`  | nicht getestet |
| Suricata         | `tasks/suricata/`        | nicht getestet |

---

## Testumgebung

- Ubuntu 24.04
- AWX 24.6.1 auf Minikube (WSL / Windows 10)
- Ansible AWX Execution Environment (custom gebaut via `pb_setup_awx_ee.yml`)

---

## Hinweise

- Alle IPs, Domains und E-Mail-Adressen in Beispielen sind Platzhalter — per Find & Replace anpassbar
- Private Keys und Passwörter sind **nicht** im Repository enthalten
- Die meisten Inline-Codekommentare sind auf Deutsch — das Projekt war ursprünglich nicht für Veröffentlichung gedacht
- Englische README: [README.md](README.md)

---

## Über dieses Projekt

Der Großteil des Codes in diesem Repository wurde mit Hilfe von [Claude (Anthropic)](https://claude.ai) geschrieben. Architektur, Design-Entscheidungen und Tests sind von mir — Claude hat den Code geschrieben.

---

## Kontakt

Gerne über GitHub Issues oder Discussions.

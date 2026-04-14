# homelab-ansible-awx

AWX-basierte Homelab-Automatisierung mit Ansible — eigene Credential-Typen, K3s-Deployments, Firewall, VPN und mehr.

---

## Übersicht

Dieses Repository enthält meine Ansible-Playbooks und AWX-Konfiguration für ein selbst gehostetes Homelab mit 7 Ubuntu 24.04 VPS-Servern.

Das Ziel: Vollständige Server-Automation über AWX — von der Grundinstallation bis zum App-Deployment.

---

## Schnellstart

Der einfachste Einstieg ist das Einspielen der AWX-Sicherung in eine frische AWX-Installation. Der Ordner `komplette_AWX_sicherung/` enthält alle Credential-Typen, Job-Templates und Workflows als JSON-Export und kann direkt importiert werden.

---

## Infrastruktur

| Server        | Rolle                                 |
| ------------- | ------------------------------------- |
| VPN Server    | WireGuard Gateway                     |
| Wazuh Manager | IDS / Security Monitoring             |
| Mail Server   | Stalwart Mail                         |
| Repo Server   | Aptly + cgit + Helm Registry + awx_EE |
| AI Server     | Ollama + Open WebUI + Qdrant (K3s)    |
| Odoo Server   | Odoo ERP (K3s)                        |
| AWX Server    | AWX + Directus (K3s)                  |

Dies ist meine persönliche Infrastruktur — die Playbooks sind aber einzeln lauffähig und nicht an diese Serverstruktur gebunden.

---

## Features

- **Universelles App-Deploy-System** (`pb_setup_app_deploy.yml`) für K3s, Docker, Podman und native Deployments
- **Custom AWX Credential Types** für saubere Variablentrennung
- **nftables Firewall** mit GeoIP-Blocking, Fail2Ban und automatischem Rollback
- **WireGuard VPN** — alle internen Dienste nur über VPN erreichbar (optional)
- **nginx + ModSecurity** als Reverse Proxy mit SSL
- **Wazuh Agent** auf allen Servern
- **Reboot-sicher** — alle Tasks überleben einen Neustart

---

## Alles ist optional

Die Playbooks sind eigenständig lauffähig und können unabhängig voneinander eingesetzt werden. Es gibt keine harte Abhängigkeit zwischen den einzelnen Komponenten.

**WireGuard VPN** ist eine von mehreren Möglichkeiten — bei den meisten Deployments kann im AWX-Credential gewählt werden ob VPN aktiv ist oder nicht. Es ist kein Pflichtbestandteil.

**Die Workflows** im Repository sind Beispiele meiner konkreten Server-Einrichtung. Sie zeigen eine mögliche Reihenfolge, sind aber keine Vorgabe.

---

## Struktur

```
projekt/
├── pb_setup_*.yml              # Playbooks
└── playbook/system/
    ├── daten/vars/             # Zentrale Variablen (os_urls, vpn, app_resources ...)
    ├── tasks/                  # Task-Bibliothek (firewall, nginx, k3s, wireguard ...)
    └── templates/              # Jinja2-Templates
komplette_AWX_sicherung/        # AWX Export (Credential Types, Job Templates ...)
```

---

## Universelles App-Deploy-System

Das Herzstück des Projekts ist ein einziges Playbook — `pb_setup_app_deploy.yml` — das alle Anwendungs-Deployments unabhängig von Typ und Zielumgebung abwickelt.

Statt für jede App ein eigenes Playbook zu schreiben, wird das Deployment vollständig über ein **AWX-Credential** gesteuert. Man wählt die App, den Deployment-Typ, die Datenbank und ein paar Optionen — den Rest erledigt das Playbook.

### Unterstützte Apps

`directus` · `bookstack` · `ollama` · `open-webui` · `qdrant` · `odoo` · `mailcow` · `mariadb` · `awx-ee` · `awx` · `mariadb-webui` · `openclaw` · `wazuh` · `mailu` · `stalwart`

### Unterstützte Deployment-Typen

| Wert                              | Beschreibung             |
| --------------------------------- | ------------------------ |
| `k3s` / `k3s_v1_34` / `k3s_v1_35` | Kubernetes über K3s      |
| `minikube` / `minikube_v1_38`     | Kubernetes über Minikube |
| `k8s` / `k8s_v1_34`               | Vanilla Kubernetes       |
| `docker` / `docker_v27`           | Docker Compose           |
| `podman` / `podman_v5`            | Podman Compose           |
| `nativ`                           | apt + systemd            |

### Credential-Felder

| Feld                    | Pflicht | Beschreibung                                                                 |
| ----------------------- | ------- | ---------------------------------------------------------------------------- |
| `app_name`              | ✅      | Zu deployende Anwendung                                                      |
| `app_deploy_type`       | ✅      | Deployment-Typ (siehe oben)                                                  |
| `app_db_type`           | ✅      | Datenbank: `mariadb`, `postgresql`, `mysql`, `none`                          |
| `app_port`              | ✅      | Interner Port (z.B. 8055=Directus, 8069=Odoo, 11434=Ollama)                  |
| `app_db_password`       |         | Datenbank-Passwort                                                           |
| `app_admin_email`       |         | Admin E-Mail-Adresse                                                         |
| `app_admin_password`    |         | Admin-Passwort                                                               |
| `app_secret_key`        |         | JWT/Session-Secret — generieren mit `openssl rand -hex 32`                   |
| `app_nginx_integration` |         | nginx als Reverse Proxy einrichten                                           |
| `app_ssl`               |         | HTTPS über Let's Encrypt aktivieren                                          |
| `app_modsecurity`       |         | ModSecurity WAF im nginx aktivieren                                          |
| `app_vpn_only`          |         | App nur über WireGuard VPN erreichbar (kein SSL nötig)                       |
| `app_ha_install`        |         | High Availability (mehrere Replicas)                                         |
| `app_skip_install`      |         | Installation überspringen, nur nginx/SSL neu konfigurieren                   |
| `app_no_update`         |         | Container-Image-Updates verhindern                                           |
| `isolation_app`         |         | DNS-Isolation — App kann keine externen Domains auflösen - NICHT GETESTET!!! |
| `app_bez`               |         | Optionaler Umgebungs-Tag (z.B. `test`, `prod`)                               |

---

## Betriebssystem & Kompatibilität

Getestet wurde ausschließlich auf **Ubuntu 24.04**.

Die Ausgangsstruktur ist bewusst OS-neutral angelegt — alle betriebssystemspezifischen Werte (Paketnamen, Pfade, Services, Versionen) sind zentral in `playbook/system/daten/vars/` gepflegt. Dadurch können andere Linux-Distributionen (Debian, Rocky Linux, etc.) ergänzt werden, ohne den Playbook-Code anzupassen. Auch Versionsunterschiede innerhalb einer Distribution lassen sich über diese Struktur abbilden.

---

## Teststatus

Folgende Tasks sind im Code als `# STATUS: NICHT GETESTET` markiert — das bedeutet nicht, dass die anderen fehlerfrei laufen, sondern nur dass diese noch gar nicht ausgeführt wurden:

| Task             | Ordner                  |
| ---------------- | ----------------------- |
| Kubernetes (k8s) | `tasks/k8s/`            |
| MariaDB WebUI    | `tasks/mariadb_webui/`  |
| OpenEMS          | `tasks/openems/`        |
| OpenFOAM         | `tasks/openfoam/`       |
| Podman           | `tasks/podman_include/` |
| Suricata IDS/IPS | `tasks/suricata/`       |

---

## Voraussetzungen

- Ubuntu 24.04
- AWX (getestet mit AWX 24.6.1 auf Minikube WSL/Win10)
- Ansible AWX Execution Environment
- WireGuard VPN für den Zugriff auf interne Dienste (optional)

---

## Hinweise

- Alle IPs, Domains und E-Mail-Adressen sind durch Platzhalter ersetzt (z.B. `<ip_vpn_server>`)
- Private Keys und Passwörter sind **nicht** im Repository enthalten
- Alle Code-Kommentare sind auf **Deutsch** — das Projekt war ursprünglich nicht zur Veröffentlichung gedacht

---

## Hinweis zur Entstehung

Der Großteil des Codes in diesem Repository wurde mit Unterstützung von [Claude (Anthropic)](https://claude.ai) erstellt. Die Konzeption, Architektur-Entscheidungen und das Testing lagen bei mir — Claude hat den Code dazu geschrieben.

---

## Kontakt

Bei Fragen gerne über GitHub Issues oder Discussions melden.

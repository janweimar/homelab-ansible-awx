# homelab-ansible-awx

AWX-based homelab automation with Ansible — custom credential types, K3s deployments, firewall, VPN and more.

---

## Overview

This repository contains my Ansible playbooks and AWX configuration for a self-hosted homelab running 7 Ubuntu 24.04 VPS servers.

The goal: full server automation via AWX — from initial setup to app deployment.

---

## Quick Start

The easiest way to get started is to import the AWX backup into a fresh AWX installation. The `komplette_AWX_sicherung/` folder contains all credential types, job templates and workflows as a JSON export, ready to import.

---

## Infrastructure

| Server        | Role                                   |
|---------------|----------------------------------------|
| VPN Server    | WireGuard Gateway                      |
| Wazuh Manager | IDS / Security Monitoring              |
| Mail Server   | Stalwart Mail                          |
| Repo Server   | Aptly + cgit + Helm Registry + AWX EE  |
| AI Server     | Ollama + Open WebUI + Qdrant (K3s)     |
| Odoo Server   | Odoo ERP (K3s)                         |
| AWX Server    | AWX + Directus (K3s)                   |

---

## Playbooks

Each playbook is standalone and can be used independently — there are no hard dependencies between components.

| Playbook                   | Description                                         |
|----------------------------|-----------------------------------------------------|
| `pb_setup_msmtp.yml`       | Mail delivery via msmtp                             |
| `pb_setup_network.yml`     | Network configuration (gai.conf, nload)             |
| `pb_setup_firewall.yml`    | nftables firewall with automatic rollback           |
| `pb_setup_geoblock.yml`    | GeoIP blocking (allow: DE)                          |
| `pb_setup_logrotate.yml`   | Log rotation                                        |
| `pb_setup_auto_update.yml` | Unattended security updates                         |
| `pb_setup_audit.yml`       | auditd system auditing                              |
| `pb_setup_vpn_client.yml`  | WireGuard VPN client                                |
| `pb_setup_fail2ban.yml`    | Brute-force protection (all jails)                  |
| `pb_setup_suricata.yml`    | IDS/IPS network monitoring                          |
| `pb_setup_rkhunter.yml`    | Rootkit scanner (baseline)                          |
| `pb_setup_wazuh_agent.yml` | Wazuh monitoring agent                              |
| `pb_setup_apparmor.yml`    | Process restrictions via AppArmor                   |
| `pb_setup_nginx.yml`       | nginx reverse proxy + ModSecurity WAF + SSL         |
| `pb_setup_k3s.yml`         | K3s Kubernetes installation                         |
| `pb_setup_app_deploy.yml`  | Universal app deployment (K3s/Docker/Podman/native) |

---

## Server Workflow

Every server follows the same base workflow. App-specific job templates are inserted at step 9.
`fail2ban` is always last among the security tools — **after** all apps and nginx are installed.

### Base Workflow (copy template)

```
 #   JT                          Description
 1   jt_setup_msmtp              Mail delivery (msmtp)
 2   jt_setup_network            Network config (gai.conf, nload)
 3   jt_setup_firewall           nftables firewall              ← change creds!
 4   jt_setup_geoblock           GeoIP blocking (allow: DE)
 5   jt_setup_logrotate          Log rotation
 6   jt_setup_auto_update        Security updates
 7   jt_setup_audit              auditd
 8   jt_setup_vpn_client         WireGuard VPN client           ← change creds!
 9   ... app-specific JTs (nginx / K3s if needed) ...
10   jt_setup_fail2ban           Brute-force protection (all jails) ← change creds!
11   jt_setup_suricata           IDS/IPS monitoring             (not for VPN + Repo)
12   jt_setup_rkhunter           Rootkit scanner (baseline)
13   jt_setup_wazuh_agent        Monitoring
14   jt_setup_apparmor           Process restrictions           LAST!
```

### Example: Odoo Server

```
 #   JT                          Description
 1   jt_setup_msmtp              Mail delivery (msmtp)
 2   jt_setup_network            Network config
 3   jt_setup_firewall           nftables firewall              ← Odoo creds!
 4   jt_setup_geoblock           GeoIP blocking
 5   jt_setup_logrotate          Log rotation
 6   jt_setup_auto_update        Security updates
 7   jt_setup_audit              auditd
 8   jt_setup_vpn_client         WireGuard VPN client           ← Odoo creds!
 9   jt_setup_k3s                K3s installation
     jt_setup_app_deploy         Odoo (K3s, PostgreSQL)
     jt_setup_nginx              Reverse proxy + SSL
10   jt_setup_fail2ban           ssh + nginx + odoo jails       ← Odoo creds!
11   jt_setup_suricata           IDS/IPS monitoring
12   jt_setup_rkhunter           Rootkit scanner
13   jt_setup_wazuh_agent        Monitoring
14   jt_setup_apparmor           Process restrictions           LAST!
```

---

## Universal App Deploy System

`pb_setup_app_deploy.yml` handles all application deployments regardless of type or target environment — fully controlled through an AWX credential.

### Supported Apps

`directus` · `bookstack` · `ollama` · `open-webui` · `qdrant` · `odoo` · `mailcow` · `mariadb` · `awx-ee` · `awx` · `mariadb-webui` · `openclaw` · `wazuh` · `mailu` · `stalwart`

### Supported Deployment Types

| Value                               | Description             | Status              |
|-------------------------------------|-------------------------|---------------------|
| `k3s` / `k3s_v1_34` / `k3s_v1_35`  | Kubernetes via K3s      | ✅ tested           |
| `minikube` / `minikube_v1_38`       | Kubernetes via Minikube | ✅ tested           |
| `k8s` / `k8s_v1_34`                | Vanilla Kubernetes      | 🚧 work in progress |
| `docker` / `docker_v27`             | Docker Compose          | ✅ tested           |
| `podman` / `podman_v5`              | Podman Compose          | 🚧 work in progress |
| `nativ`                             | apt + systemd           | ✅ tested           |

### Credential Fields

| Field                   | Status               | Description                                               |
|-------------------------|----------------------|-----------------------------------------------------------|
| `app_name`              | required             | Application to deploy                                     |
| `app_deploy_type`       | required             | Deployment type (see above)                               |
| `app_db_type`           | required             | Database: `mariadb`, `postgresql`, `mysql`, `none`        |
| `app_port`              | required             | Internal port (e.g. 8055=Directus, 8069=Odoo, 11434=Ollama) |
| `app_db_password`       |                      | Database password                                         |
| `app_admin_email`       |                      | Admin e-mail address                                      |
| `app_admin_password`    |                      | Admin password                                            |
| `app_secret_key`        |                      | JWT/Session secret — generate with `openssl rand -hex 32` |
| `app_nginx_integration` |                      | Set up nginx as reverse proxy                             |
| `app_ssl`               |                      | Enable HTTPS via Let's Encrypt                            |
| `app_modsecurity`       |                      | Enable ModSecurity WAF in nginx                           |
| `app_vpn_only`          |                      | App accessible via WireGuard VPN only (no SSL needed)     |
| `app_ha_install`        | 🚧 work in progress  | High Availability (multiple replicas)                     |
| `app_skip_install`      |                      | Skip installation, reconfigure nginx/SSL only             |
| `app_no_update`         |                      | Prevent container image updates                           |
| `isolation_app`         | 🚧 work in progress  | DNS isolation — app cannot reach external domains         |
| `app_bez`               |                      | Optional environment tag (e.g. `test`, `prod`)            |

---

## Features

- **Standalone playbooks** — every playbook works independently, no hard dependencies
- **Universal App Deploy System** (`pb_setup_app_deploy.yml`) for K3s, Docker, Podman and native deployments
- **Custom AWX Credential Types** for clean variable separation
- **nftables Firewall** with GeoIP blocking, Fail2Ban and automatic rollback
- **WireGuard VPN** — all internal services accessible via VPN only (optional)
- **nginx + ModSecurity** as reverse proxy with SSL
- **Wazuh Agent** on all servers
- **Reboot-safe** — all tasks survive a server restart

---

## Repository Structure

```
projekt/
├── pb_setup_*.yml              # Playbooks
└── playbook/system/
    ├── daten/vars/             # Central variables (os_urls, vpn, app_resources ...)
    ├── tasks/                  # Task library (firewall, nginx, k3s, wireguard ...)
    └── templates/              # Jinja2 templates
komplette_AWX_sicherung/        # AWX export (Credential Types, Job Templates ...)
```

---

## OS Compatibility

Tested on **Ubuntu 24.04** only.

The base structure is intentionally OS-neutral — all OS-specific values (package names, paths, services, versions) are managed centrally in `playbook/system/daten/vars/`. This allows other Linux distributions (Debian, Rocky Linux, etc.) to be added without modifying any playbook code.

---

## Test Status

The following tasks are marked with `# STATUS: NOT TESTED` in the code:

| Task             | Folder                  |
|------------------|-------------------------|
| Kubernetes (k8s) | `tasks/k8s/`            |
| MariaDB WebUI    | `tasks/mariadb_webui/`  |
| OpenEMS          | `tasks/openems/`        |
| OpenFOAM         | `tasks/openfoam/`       |
| Podman           | `tasks/podman_include/` |
| Suricata IDS/IPS | `tasks/suricata/`       |

---

## Test Environment

- Ubuntu 24.04
- AWX 24.6.1 on Minikube WSL/Win10
- Ansible AWX Execution Environment

---

## Notes

- All IPs, domains and email addresses have been replaced with placeholders (e.g. `<ip_vpn_server>`) — easy to adapt using find & replace
- Private keys and passwords are **not** included in this repository
- All code comments are in **German** — this project was not originally intended for public release

---

## About

Most of the code in this repository was written with the help of [Claude (Anthropic)](https://claude.ai). The concept, architecture decisions and testing were done by me — Claude wrote the code.

---

## Contact

Feel free to reach out via GitHub Issues or Discussions.

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

| Server | Role |
|--------|------|
| VPN Server | WireGuard Gateway |
| Wazuh Manager | IDS / Security Monitoring |
| Mail Server | Stalwart Mail |
| Repo Server | Aptly + cgit + Helm Registry |
| AI Server | Ollama + Open WebUI + Qdrant (K3s) |
| Odoo Server | Odoo ERP (K3s) |
| AWX Server | AWX + Directus (K3s) |

This is my personal infrastructure — the playbooks are standalone and not tied to this specific server setup.

---

## Features

- **Universal App Deploy System** (`pb_setup_app_deploy.yml`) for K3s, Docker, Podman and native deployments
- **37 Custom AWX Credential Types** for clean variable separation
- **nftables Firewall** with GeoIP blocking, Fail2Ban and automatic rollback
- **WireGuard VPN** — all internal services accessible via VPN only (optional)
- **nginx + ModSecurity** as reverse proxy with SSL
- **Wazuh Agent** on all servers
- **Reboot-safe** — all tasks survive a server restart

---

## Everything is Optional

The playbooks are standalone and can be used independently — there are no hard dependencies between components.

**WireGuard VPN** is one of several options. For most deployments, you can choose in the AWX credential whether VPN is active or not. It is not a required component.

**The workflows** in this repository are examples based on my specific server setup. They show one possible installation order but are not a requirement.

---

## Structure

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

## Universal App Deploy System

The core of this project is a single playbook — `pb_setup_app_deploy.yml` — that handles all application deployments regardless of type or target environment.

Instead of writing a separate playbook for every app, the deployment is fully controlled through an **AWX credential**. You pick the app, the deployment type, the database and a few options — the playbook takes care of the rest.

### Supported Apps

`directus` · `bookstack` · `ollama` · `open-webui` · `qdrant` · `odoo` · `mailcow` · `mariadb` · `awx-ee` · `awx` · `mariadb-webui` · `openclaw` · `wazuh` · `mailu` · `stalwart`

### Supported Deployment Types

| Value | Description |
|-------|-------------|
| `k3s` / `k3s_v1_34` / `k3s_v1_35` | Kubernetes via K3s |
| `minikube` / `minikube_v1_38` | Kubernetes via Minikube |
| `k8s` / `k8s_v1_34` | Vanilla Kubernetes |
| `docker` / `docker_v27` | Docker Compose |
| `podman` / `podman_v5` | Podman Compose |
| `nativ` | apt + systemd |

### Credential Fields

| Field | Required | Description |
|-------|----------|-------------|
| `app_name` | ✅ | Application to deploy |
| `app_deploy_type` | ✅ | Deployment type (see above) |
| `app_db_type` | ✅ | Database: `mariadb`, `postgresql`, `mysql`, `none` |
| `app_port` | ✅ | Internal port (e.g. 8055=Directus, 8069=Odoo, 11434=Ollama) |
| `app_db_password` | | Database password |
| `app_admin_email` | | Admin e-mail address |
| `app_admin_password` | | Admin password |
| `app_secret_key` | | JWT/Session secret — generate with `openssl rand -hex 32` |
| `app_nginx_integration` | | Set up nginx as reverse proxy |
| `app_ssl` | | Enable HTTPS via Let's Encrypt |
| `app_modsecurity` | | Enable ModSecurity WAF in nginx |
| `app_vpn_only` | | App accessible via WireGuard VPN only (no SSL needed) |
| `app_ha_install` | | High Availability (multiple replicas) |
| `app_skip_install` | | Skip installation, reconfigure nginx/SSL only |
| `app_no_update` | | Prevent container image updates |
| `isolation_app` | | DNS isolation — app cannot reach external domains |
| `app_bez` | | Optional label/environment tag (e.g. `test`, `prod`) |

---

## OS Compatibility

Tested on **Ubuntu 24.04** only.

The base structure is intentionally OS-neutral — all OS-specific values (package names, paths, services, versions) are managed centrally in `playbook/system/daten/vars/`. This allows other Linux distributions (Debian, Rocky Linux, etc.) to be added without modifying any playbook code. Version differences within a distribution can also be handled through this structure.

---

## Test Status

The following tasks are marked with `# STATUS: NOT TESTED` in the code — this does not mean the others are guaranteed to work, only that these have never been executed at all:

| Task | Folder |
|------|--------|
| Kubernetes (k8s) | `tasks/k8s/` |
| MariaDB WebUI | `tasks/mariadb_webui/` |
| OpenEMS | `tasks/openems/` |
| OpenFOAM | `tasks/openfoam/` |
| Podman | `tasks/podman_include/` |
| Suricata IDS/IPS | `tasks/suricata/` |

---

## Requirements

- Ubuntu 24.04
- AWX (tested with AWX 24.6.1 on Minikube WSL/Win10)
- Ansible AWX Execution Environment
- WireGuard VPN for access to internal services (optional)

---

## Notes

- All IPs, domains and email addresses have been replaced with placeholders (e.g. `<ip_vpn_server>`)
- Private keys and passwords are **not** included in this repository
- All code comments are in **German** — this project was not originally intended for public release

---

## About

Most of the code in this repository was written with the help of [Claude (Anthropic)](https://claude.ai). The concept, architecture decisions and testing were done by me — Claude wrote the code.

---

## Contact

Feel free to reach out via GitHub Issues or Discussions.

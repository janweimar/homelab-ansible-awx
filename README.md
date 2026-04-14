# homelab-ansible-awx

AWX-based homelab automation with Ansible — custom credential types, K3s deployments, firewall, VPN and more.

---

## Overview

This repository contains my Ansible playbooks and AWX configuration for a self-hosted homelab running 7 Ubuntu 24.04 VPS servers.

The goal: full server automation via AWX — from initial setup to app deployment.

---

## Infrastructure

| Server | Role |
|--------|------|
| VPN Server | WireGuard Gateway |
| Wazuh Manager | IDS / Security Monitoring |
| Mail Server | Stalwart Mail |
| Repo Server | Aptly + cgit + Helm Registry + awx_EE|
| AI Server | Ollama + Open WebUI + Qdrant (K3s) |
| Odoo Server | Odoo ERP (K3s) |
| AWX Server | AWX + Directus (K3s) |

---

## Features

- **Universal App Deploy System** (`pb_setup_app_deploy.yml`) for K3s, Docker, Podman and native deployments
- **37 Custom AWX Credential Types** for clean variable separation
- **nftables Firewall** with GeoIP blocking, Fail2Ban and automatic rollback
- **WireGuard VPN** — all internal services accessible via VPN only
- **nginx + ModSecurity** as reverse proxy with SSL
- **Wazuh Agent** on all servers
- **Reboot-safe** — all tasks survive a server restart

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
- WireGuard VPN for access to internal services

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

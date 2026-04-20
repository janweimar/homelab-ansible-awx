# homelab-ansible-awx

AWX-based homelab automation with Ansible — standalone playbooks, custom credential types, K3s deployments, firewall, VPN, and DNS-provider API integration.

---

## Overview

This repository contains my Ansible playbooks and AWX configuration for a self-hosted homelab running multiple Ubuntu 24.04 VPS servers.

The core idea: **every playbook works on its own.** Workflows are just a sequence of playbooks — nothing more. There are no hard dependencies between playbooks, and no magic that only works when you run them in a specific order. If a playbook needs something (e.g. nginx, K3s), it brings it along as an include task.

---

## Quick Start

The easiest way to get started is to import the AWX backup into a fresh AWX installation. The `komplette_AWX_sicherung/` folder contains all credential types, job templates and workflows as a JSON export, ready to import.

---

## Playbooks

Playbooks are the primary unit in this repository. Each one is **standalone and idempotent** — you can run any playbook on any server at any time, and it will do the right thing.

### Base system

| Playbook                                   | Description                                                     |
|--------------------------------------------|-----------------------------------------------------------------|
| `pb_setup_add_sudo_user_add_ssh_key_secure.yml` | Create sudo user, add SSH key, harden SSH                  |
| `pb_setup_msmtp.yml`                       | Outgoing mail via msmtp                                          |
| `pb_setup_network.yml`                     | Network configuration (gai.conf, nload)                          |
| `pb_setup_logrotate.yml`                   | Log rotation                                                     |
| `pb_setup_auto_update.yml`                 | Unattended security updates                                      |
| `pb_setup_audit.yml`                       | auditd system auditing                                           |
| `pb_setup_cronjobs.yml`                    | Cron jobs                                                        |

### Firewall & Network Security

| Playbook                          | Description                                              |
|-----------------------------------|----------------------------------------------------------|
| `pb_setup_firewall_nftables.yml`  | nftables firewall with automatic rollback                 |
| `pb_setup_geoblock_nftables.yml`  | GeoIP blocking (configurable allow-list)                  |
| `pb_setup_fail2ban_nftables.yml`  | Brute-force protection (all jails at once)                |

### VPN

| Playbook                     | Description                                    |
|------------------------------|------------------------------------------------|
| `pb_setup_vpn_server.yml`    | WireGuard VPN gateway                           |
| `pb_setup_vpn_client.yml`    | WireGuard VPN client                            |

### Security & Monitoring

| Playbook                       | Description                                      |
|--------------------------------|--------------------------------------------------|
| `pb_setup_rkhunter.yml`        | Rootkit scanner (with baseline)                   |
| `pb_setup_suricata.yml`        | IDS/IPS network monitoring                        |
| `pb_setup_wazuh_manager.yml`   | Wazuh central monitoring (includes nginx)         |
| `pb_setup_wazuh_agent.yml`     | Wazuh agent                                       |
| `pb_setup_appamor.yml`         | AppArmor process restrictions                     |
| `pb_setup_alerting.yml`        | Alerting configuration                            |

### Repo / Jump Server

| Playbook                                     | Description                                            |
|----------------------------------------------|--------------------------------------------------------|
| `pb_setup_add_repos_client.yml`              | Add custom APT repos on clients                         |
| `pb_setup_repo_server.yml`                   | Aptly + cgit + Helm registry (includes nginx)           |
| `pb_setup_aptly_mirrors_repo_server.yml`     | Configure Aptly mirrors                                 |
| `pb_setup_aptly_publishing_repo_server.yml`  | Publish Aptly repos                                     |
| `pb_conf_helm_charts_repo_server.yml`        | Helm chart registry configuration                       |
| `pb_setup_cgit_publishing_server.yml`        | Git mirrors via cgit                                    |
| `pb_setup_cgit_update.yml`                   | Update cgit mirrors                                     |
| `pb_setup_awx_ee.yml`                        | Build AWX Execution Environment image                   |

### Universal App Deploy

| Playbook                    | Description                                                       |
|-----------------------------|-------------------------------------------------------------------|
| `pb_setup_app_deploy.yml`   | Universal app deployment (K3s / Minikube / Docker / native)        |
| `pb_setup_bookstack.yml`    | BookStack wiki (legacy standalone playbook)                        |
| `pb_setup_openems.yml`      | OpenEMS FDTD simulation                                            |
| `pb_setup_openfoam.yml`     | OpenFOAM CFD simulation                                            |

### Misc

| Playbook                        | Description                         |
|---------------------------------|-------------------------------------|
| `pb_test_infrastruktur.yml`     | Read-only infrastructure analysis    |
| `pb_hinweis_vpn_server_pause.yml` | Workflow pause reminder            |

---

## Universal App Deploy System

`pb_setup_app_deploy.yml` handles all application deployments regardless of type or target environment — fully controlled through an AWX credential. If K3s or Minikube is needed and not yet installed, it installs them automatically.

### Supported Apps

`stalwart` · `odoo` · `directus` · `bookstack` · `ollama` · `open-webui` · `qdrant` · `awx` · `awx-ee` · `mariadb-webui` · `openclaw` · `wazuh` · `mailu`

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
| `app_name`              | required             | Application to deploy                                      |
| `app_deploy_type`       | required             | Deployment type (see above)                                |
| `app_db_type`           | required             | Database: `mariadb`, `postgresql`, `mysql`, `none`         |
| `app_port`              | required             | Internal port                                              |
| `app_db_password`       |                      | Database password                                          |
| `app_admin_email`       |                      | Admin email address                                        |
| `app_admin_password`    |                      | Admin password                                             |
| `app_secret_key`        |                      | JWT/Session secret — `openssl rand -hex 32`                |
| `app_nginx_integration` |                      | Set up nginx as reverse proxy (include task)               |
| `app_ssl`               |                      | Enable HTTPS via Let's Encrypt                             |
| `app_modsecurity`       |                      | Enable ModSecurity WAF in nginx                            |
| `app_vpn_only`          |                      | App accessible via WireGuard VPN only                      |
| `app_ha_install`        | 🚧 work in progress  | High availability (multiple replicas)                      |
| `app_skip_install`      |                      | Skip installation, reconfigure nginx/SSL only              |
| `app_no_update`         |                      | Prevent container image updates                            |
| `isolation_app`         | 🚧 work in progress  | DNS isolation — app cannot reach external domains          |
| `app_bez`               |                      | Optional environment tag (e.g. `test`, `prod`)             |

---

## nginx — no standalone playbook

There is **no** `pb_setup_nginx.yml`. nginx is always installed and configured **as part of the app that needs it**, via the include task `playbook/system/tasks/nginx/`. This keeps the app and its reverse proxy tightly coupled and removes ordering requirements.

When `app_nginx_integration` is enabled in `pb_setup_app_deploy.yml`, the nginx task:

- installs nginx (if not present)
- creates a vHost for the app
- requests a Let's Encrypt certificate (if `app_ssl` is enabled)
- optionally enables ModSecurity WAF
- **sets the A record via the DNS-provider API** (see below)

The same pattern applies to `pb_setup_wazuh_manager.yml`, `pb_setup_repo_server.yml` etc. — each one brings its own nginx include.

---

## DNS Provider API Integration

DNS records are managed automatically via the hosting provider's API. Currently implemented: **Contabo**. The structure is provider-agnostic (`playbook/system/api/api_router.yml` dispatches by `api_provider`), so other providers can be added without touching the playbooks that use it.

### What is managed automatically

1. **A record via nginx include task**
   `app_vpn_only=false` → A record is created/updated to point at the server IP
   `app_vpn_only=true` → A record is removed (app only reachable via VPN)
   No manual DNS edits needed when switching between public and VPN-only.

2. **Mail DNS records via Stalwart post task** (when deploying Stalwart)
   Stalwart generates all needed records (MX, SPF, DKIM Ed25519, DKIM RSA, DMARC, TLS-RPT, SRV for IMAP/POP3/JMAP/CalDAV/CardDAV/submission, CNAME for autoconfig/autodiscover). The post task reads them from the Stalwart API and pushes them to the provider via API — typically 18+ records per mail domain, all idempotent.

3. **DKIM auto-signing**
   The Stalwart K3s manifest configures `[auth.dkim] sign = ...` automatically, so outgoing mail is signed with both Ed25519 and RSA keys without manual signer registration.

### Design

- **Idempotent:** DELETE + ADD pattern instead of PUT (works around provider API quirks)
- **State-aware:** Old DNS records are tracked in `server_state.fact` and cleaned up on re-deploy
- **Provider-agnostic:** `api_router.yml` selects the right backend by `api_provider` credential field

### Adding a new provider

To add a new DNS provider (e.g. Hetzner, Cloudflare):

1. Create a new folder under `playbook/system/api/<provider>/` (see `contabo/` as reference — auth, setup, domain, dns, cleanup)
2. Implement the same set of include tasks (`<provider>_auth.yml`, `<provider>_dns_record.yml`, `<provider>_domain_record.yml`, etc.)
3. Add a branch in `api_router.yml`
4. Add the provider to the `api_provider` credential field

The hetzner folder already exists as a stub — contributions welcome.

---

## Server Workflow (example)

Workflows are **just a sequence of job templates**. Each JT runs one standalone playbook. Nothing is hardwired — you can reorder, skip, or add steps as needed.

Example: **Odoo Server**

```
 #  JT                          Playbook                       Notes
 1  jt_setup_msmtp              pb_setup_msmtp.yml
 2  jt_setup_network            pb_setup_network.yml
 3  jt_setup_firewall           pb_setup_firewall_nftables.yml
 4  jt_setup_geoblock           pb_setup_geoblock_nftables.yml
 5  jt_setup_logrotate          pb_setup_logrotate.yml
 6  jt_setup_auto_update        pb_setup_auto_update.yml
 7  jt_setup_audit              pb_setup_audit.yml
 8  jt_setup_vpn_client         pb_setup_vpn_client.yml
 9  jt_setup_odoo               pb_setup_app_deploy.yml         app_name=odoo, includes nginx + A record
10  jt_setup_fail2ban           pb_setup_fail2ban_nftables.yml  all jails at once
11  jt_setup_suricata           pb_setup_suricata.yml
12  jt_setup_rkhunter           pb_setup_rkhunter.yml
13  jt_setup_wazuh_agent        pb_setup_wazuh_agent.yml
14  jt_setup_apparmor           pb_setup_appamor.yml            always last
```

Key rules:

- `apparmor` always last — it can restrict other services if run too early
- `fail2ban` runs once at the end — needs all target services (nginx, app) installed
- `rkhunter` baseline after all other installs — clean state
- `add_sudo_user_ssh` runs separately, before the workflow — bootstrap step

---

## Features

- **Standalone playbooks** — every playbook works independently
- **Universal app deploy** — K3s, Minikube, Docker, native
- **Custom AWX credential types** — clean variable separation
- **nftables firewall** with GeoIP, fail2ban, automatic rollback
- **WireGuard VPN** — internal services can be made VPN-only on demand
- **nginx include + ModSecurity + Let's Encrypt** — wherever nginx is needed
- **Wazuh agent** on all servers
- **DNS API integration** — A records and mail records managed automatically
- **Stalwart mail server** — K3s deployment with auto-DKIM, SPF, DMARC, MTA-STS, DANE
- **Reboot-safe** — all tasks survive a server restart

---

## Repository Structure

```
projekt/
├── pb_setup_*.yml              # Playbooks (standalone entry points)
└── playbook/system/
    ├── api/                    # DNS provider integration (contabo, hetzner)
    ├── daten/vars/             # Central variables (os_urls, vpn, app_resources ...)
    ├── tasks/                  # Task library
    │   ├── nginx/              #   → include task for reverse proxy + A record
    │   ├── stalwart/           #   → Stalwart mail server (K3s)
    │   ├── odoo/               #   → Odoo ERP
    │   ├── nftables/           #   → firewall / geoblock / fail2ban
    │   ├── wireguard/          #   → WireGuard server & client
    │   └── ...
    └── templates/              # Jinja2 templates
komplette_AWX_sicherung/        # AWX export (credential types, JTs, workflows)
```

---

## OS Compatibility

Tested on **Ubuntu 24.04** only.

The base structure is OS-neutral — all OS-specific values (package names, paths, services, versions) are managed centrally in `playbook/system/daten/vars/`. Adding Debian, Rocky Linux etc. is a matter of extending these files, no playbook code changes.

---

## Test Status

| Task             | Folder                   | Status         |
|------------------|--------------------------|----------------|
| Kubernetes (k8s) | `tasks/k8s/`             | not tested     |
| MariaDB WebUI    | `tasks/mariadb_webui/`   | not tested     |
| OpenEMS          | `tasks/openems/`         | not tested     |
| OpenFOAM         | `tasks/openfoam/`        | not tested     |
| Podman           | `tasks/podman_include/`  | not tested     |
| Suricata         | `tasks/suricata/`        | not tested     |

---

## Test Environment

- Ubuntu 24.04
- AWX 24.6.1 on Minikube (WSL / Windows 10)
- Ansible AWX Execution Environment (custom-built via `pb_setup_awx_ee.yml`)

---

## Notes

- All IPs, domains, and email addresses in examples are placeholders — adapt via find & replace
- Private keys and passwords are **not** included in this repository
- Most inline code comments are in German — this project was not originally intended for public release
- German README: [README.de.md](README.de.md)

---

## About

Most of the code in this repository was written with the help of [Claude (Anthropic)](https://claude.ai). Architecture, design decisions, and testing were done by me — Claude wrote the code.

---

## Contact

Feel free to reach out via GitHub Issues or Discussions.

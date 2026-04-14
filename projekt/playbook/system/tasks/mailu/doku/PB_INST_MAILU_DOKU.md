# MAILU - SYSTEM KONFIGURATION

## INSTALLATIONS-STATUS

{% if allg_status == "aktiviert" %}
**Status:** ✅ Mailu erfolgreich installiert

### Zugriff
- **Admin-GUI:** http://{{ urls[ansible_host].mailu.domain }}/admin *(VPN-only via nginx)*
- **Mail-Domain:** {{ urls[ansible_host].mailu.mail_domain }}
- **Hostname:** {{ urls[ansible_host].mailu.hostname }}

### Deployed Installation
- **Base-Verzeichnis:** `/opt/mailu`
- **Docker Compose:** `/opt/mailu/docker-compose.yml`
- **Umgebungsdatei:** `/opt/mailu/mailu.env`

### Docker-Container
- **mailu_front** — nginx (Mail-Ports)
- **mailu_admin** — Admin-UI
- **mailu_imap** — Dovecot (IMAP)
- **mailu_smtp** — Postfix (SMTP)
- **mailu_antispam** — Rspamd
- **mailu_redis** — Redis

### Ports
| Port | Protokoll  | Erreichbarkeit       |
|------|------------|----------------------|
| 25   | SMTP       | öffentlich           |
| 587  | Submission | öffentlich           |
| 993  | IMAPS      | öffentlich           |
| {{ app_port | default('8080') }} | Admin-GUI | VPN-only (nginx) |

### nginx Integration
**Status:** {{ 'Aktiviert ✅' if app_nginx_integration | default(false) | bool else 'Deaktiviert ❌' }}
- **Domain:** {{ urls[ansible_host].mailu.domain }}
- **SSL:** {{ 'Aktiviert ✅ (Let\'s Encrypt)' if app_ssl | default(false) | bool else 'Deaktiviert ❌' }}
- **ModSecurity:** {{ 'Aktiviert ✅' if app_modsecurity | default(false) | bool else 'Deaktiviert ❌' }}
- **VPN-only:** ✅ (nur über VPN erreichbar)
- **Konfiguration:** `{{ paths.nginx_sites_enabled[ansible_os_family] }}/{{ app_name }}_vpn.conf`

{% elif allg_status == "deaktiviert" %}
**Status:** ⏸️ Mailu Container gestoppt

{% elif allg_status == "deinstalliert" %}
**Status:** 🗑️ Mailu deinstalliert

{% endif %}

---

**Generiert:** {{ ansible_date_time.iso8601 }}
**Server:** {{ ansible_host }} ({{ ansible_hostname }})

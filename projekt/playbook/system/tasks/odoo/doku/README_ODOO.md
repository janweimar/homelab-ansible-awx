# Odoo ERP — README

## Überblick

Odoo ist ein Open-Source ERP/CRM System. Deployed über `pb_setup_app_deploy.yml` auf K3s mit PostgreSQL.

## Credential (a_cred_typ_pb_app_deploy)

| Feld | Wert |
|------|------|
| app_name | odoo |
| app_deploy_type | k3s |
| app_db_type | none (PostgreSQL ist im Manifest!) |
| app_port | 8069 |
| app_db_password | (setzen!) |
| app_admin_email | (Admin Login) |
| app_admin_password | (Master-Passwort) |
| app_ssl | true |
| app_modsecurity | true |
| app_vpn_only | false |

## Erster Start

Beim ersten Start initialisiert Odoo die PostgreSQL-Datenbank. Das kann 1-2 Minuten dauern.
Danach erreichbar unter der konfigurierten Domain.

## Dienste auf dem Server

| Pod | Funktion |
|-----|----------|
| odoo | Odoo ERP Anwendung (Port 8069) |
| odoo-postgresql | PostgreSQL Datenbank |

## Befehle

> Alle Befehle sind in der zentralen Befehlsreferenz:
> `playbook/system/daten/vars/BEFEHLE_REFERENZ.md` → Abschnitt "Odoo"

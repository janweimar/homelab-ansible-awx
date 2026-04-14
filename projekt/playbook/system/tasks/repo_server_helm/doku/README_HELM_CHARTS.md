# Helm Chart Cache — Repo-Server

## Beschreibung

Lokaler Cache für Helm Charts auf dem Repo-Server.
Gleiche Logik wie Aptly (APT-Pakete) und cgit (Git-Repos):
Charts werden von Upstream gezogen und lokal vorgehalten.

## Lokales Repo

```
https://repo.<domain> .de/helm/
```

## Nutzung auf Ziel-Servern

```bash
helm repo add repo_self_helm https://repo.<domain> .de/helm/
helm install awx-operator repo_self_helm/awx-operator --version 2.19.1
```

## Chart-Liste

Definiert in: `playbook/system/daten/vars/os_repo.yml` → `helm_charts`

## Verwaltung

- Setup: `pb_setup_repo_server.yml` (install_helm=true)
- Charts cachen: `pb_conf_helm_charts_repo_server.yml`
- Verzeichnis: `/var/www/helm/`

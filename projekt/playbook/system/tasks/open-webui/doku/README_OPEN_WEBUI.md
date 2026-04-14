# Open WebUI — Chat Frontend für Ollama (K3s Deployment)

## Übersicht

Open WebUI ist das Web-Frontend für die Ollama AI-Runtime. Bietet ein Chat-Interface ähnlich ChatGPT.

## Komponenten

| Komponente | Beschreibung |
|---|---|
| Open WebUI Pod | Chat-Interface (SQLite intern) |
| NodePort 30080 | Direkt über VPN erreichbar (kein nginx) |

## Zugriff (VPN-only)

- `http://10.200.0.23:3000` (nur über WireGuard VPN erreichbar!)
- Kein SSL, kein Auth — VPN ist der Schutz
- Erster Login im Browser erstellt den Admin-Account

## Verbindung zu Ollama

Open WebUI verbindet sich intern über K8s DNS:
`http://ollama-service.ollama.svc.cluster.local:11434`

## AWX

- **Playbook:** `pb_setup_app_deploy.yml`
- **Credential:** `a_cred_typ_pb_app_deploy` mit `app_name=open-webui`, `app_deploy_type=k3s`, `app_db_type=none`

## DNS-Isolation (Optional)

Open WebUI kann optional vom Internet isoliert werden. Dann kann der Container keine externen Domains auflösen — nur noch die interne Verbindung zu Ollama funktioniert.

| Variable | Wert | Verhalten |
|---|---|---|
| `isolation_app` | `false` (Default) | Normaler DNS-Zugriff |
| `isolation_app` | `true` | Nur cluster-interner DNS, kein Internet |

Aktivieren: Am Job Template als Extra Variable setzen:
```yaml
isolation_app: true
```

## Nützliche Befehle

```bash
# Pod-Status
sudo -u kube kubectl get pods -n open-webui

# Logs
sudo -u kube kubectl logs -n open-webui -l app=open-webui --tail=50

# Restart
sudo -u kube kubectl rollout restart deployment/open-webui -n open-webui
```

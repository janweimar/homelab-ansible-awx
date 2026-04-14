# Ollama — AI Runtime (K3s Deployment)

## Übersicht

Ollama ist die AI-Runtime für lokale LLM-Modelle. Läuft als Kubernetes Deployment auf K3s.

## Komponenten

| Komponente | Beschreibung |
|---|---|
| Ollama Pod | AI-Runtime (CPU-only Inferenz) |
| MariaDB Pod | Code-Wissensdatenbank |
| nginx vHost | Reverse Proxy (HTTPS) |

## Installierte Modelle

- **DeepSeek-Coder-V2-Lite (16B)** — Code-Assistenz
- **LLaVA 7B** — Bilderkennung

## Zugriff (VPN-only)

- `http://10.200.0.23` (nur über WireGuard VPN erreichbar!)
- Kein SSL, kein Auth — VPN ist der Schutz
- Moltbot API-URL: `http://10.200.0.23/api`

## AWX

- **Playbook:** `pb_setup_app_deploy.yml`
- **Credential:** `a_cred_typ_pb_app_deploy` mit `app_name=ollama`, `app_deploy_type=k3s`

## Nützliche Befehle

```bash
# Pod-Status
sudo -u kube kubectl get pods -n ollama

# Modelle auflisten
sudo -u kube kubectl exec -n ollama $(sudo -u kube kubectl get pods -n ollama -l app=ollama -o jsonpath='{.items[0].metadata.name}') -- ollama list

# Neues Modell herunterladen
sudo -u kube kubectl exec -n ollama <POD_NAME> -- ollama pull <MODELL>

# Logs
sudo -u kube kubectl logs -n ollama -l app=ollama --tail=50

# API testen (über VPN)
curl http://10.200.0.23/api/tags
```

# 🔍 Qdrant — Vektor-Datenbank für RAG (K3s Deployment)

## Übersicht

Qdrant speichert Vektor-Embeddings für semantische Suche (RAG). Zusammen mit MariaDB (exaktes Wissen) und Ollama (Inferenz) bildet es das AI-Backend.

## Komponenten

| Komponente | Beschreibung |
|---|---|
| Qdrant Pod | Vektor-DB (Storage: 20Gi PVC) |
| Port 6333 | HTTP REST API |
| Port 6334 | gRPC API |

## Integration

```
Code-Snippet → Ollama (Embedding erzeugen) → Qdrant (Vektor speichern)
Frage → Qdrant (ähnliche Vektoren finden) → Ollama (Antwort mit Kontext)
```

Cluster-interner Zugriff:
`http://qdrant-service.qdrant.svc.cluster.local:6333`

## AWX

- **Playbook:** `pb_setup_app_deploy.yml`
- **Credential:** `a_cred_typ_pb_app_deploy` mit `app_name=qdrant`, `app_deploy_type=k3s`, `app_db_type=none`

## Nützliche Befehle

```bash
# Pod-Status
sudo -u kube kubectl get pods -n qdrant

# Logs
sudo -u kube kubectl logs -n qdrant -l app=qdrant --tail=50

# Health Check
sudo -u kube kubectl exec -n qdrant $(sudo -u kube kubectl get pods -n qdrant -l app=qdrant -o jsonpath='{.items[0].metadata.name}') -- curl -s http://localhost:6333/healthz

# Collections anzeigen
sudo -u kube kubectl exec -n qdrant $(sudo -u kube kubectl get pods -n qdrant -l app=qdrant -o jsonpath='{.items[0].metadata.name}') -- curl -s http://localhost:6333/collections

# Restart
sudo -u kube kubectl rollout restart deployment/qdrant -n qdrant

# Storage prüfen
sudo -u kube kubectl get pvc -n qdrant
```

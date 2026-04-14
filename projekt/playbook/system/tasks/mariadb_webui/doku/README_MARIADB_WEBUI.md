# 🗄️ MariaDB Code-Wissensdatenbank + Adminer WebUI (K3s)

## Übersicht

Standalone MariaDB-Instanz für die Code-Wissensdatenbank mit Adminer als Web-Oberfläche. Getrennt von Open WebUI — diese DB speichert strukturierte Coding-Referenzen.

## Zweck

| Inhalt | Beschreibung |
|---|---|
| Alle Befehle einer Sprache | Mit Erklärung |
| Syntax + Parameter | Pro Befehl dokumentiert |
| Beispiele | Kopierbare Code-Snippets |
| Filter | Nach Sprache, Kategorie, Schwierigkeit |

## Komponenten

| Komponente | Beschreibung |
|---|---|
| MariaDB Pod | Datenbank (StatefulSet, PVC) |
| Adminer Pod | Web-Oberfläche zur DB-Verwaltung |

## Integration im AI-Stack

```
OpenClaw (WSL) ──VPN──▶ AI-Server (K3s)
                         ├── Ollama      (Inferenz)
                         ├── Qdrant      (RAG-Vektoren)
                         ├── MariaDB     (Code-Wissensdatenbank) ◀── NEU
                         ├── Adminer     (DB WebUI)              ◀── NEU
                         └── Open WebUI  (Chat, SQLite intern)
```

## AWX

- **Playbook:** `pb_setup_app_deploy.yml`
- **Credential:** `a_cred_typ_pb_app_deploy` mit:
  - `app_name=mariadb-webui`
  - `app_deploy_type=k3s_v1_34`
  - `app_db_type=mariadb`
  - `app_db_password=<sicheres Passwort>`
  - `app_port=8080`
  - `app_vpn_only=true`

## DB-Schema (geplant)

```sql
CREATE TABLE code_commands (
    id INT AUTO_INCREMENT PRIMARY KEY,
    language VARCHAR(50) NOT NULL,        -- python, bash, ansible, etc.
    category VARCHAR(100) NOT NULL,       -- string, file, network, etc.
    command VARCHAR(255) NOT NULL,         -- print(), ls, etc.
    syntax TEXT,                           -- print(value, sep, end)
    description TEXT NOT NULL,             -- Was macht der Befehl?
    example TEXT,                          -- Kopierbar
    difficulty ENUM('anfaenger','mittel','fortgeschritten') DEFAULT 'anfaenger',
    tags VARCHAR(255),                    -- Komma-getrennt
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_language (language),
    INDEX idx_category (category),
    INDEX idx_difficulty (difficulty)
);
```

## Nützliche Befehle

```bash
# Pod-Status
sudo -u kube kubectl get pods -n mariadb-webui

# Logs Adminer
sudo -u kube kubectl logs -n mariadb-webui -l app=mariadb-webui --tail=50

# Logs MariaDB
sudo -u kube kubectl logs -n mariadb-webui -l app=mariadb-webui-db --tail=50

# MariaDB Shell (direkt im Pod)
sudo -u kube kubectl exec -it -n mariadb-webui \
  $(sudo -u kube kubectl get pods -n mariadb-webui -l app=mariadb-webui-db -o jsonpath='{.items[0].metadata.name}') \
  -- mariadb -u root -p

# Restart
sudo -u kube kubectl rollout restart deployment/mariadb-webui -n mariadb-webui

# PVC prüfen
sudo -u kube kubectl get pvc -n mariadb-webui
```

## Zugang

- **Adminer:** Nur über VPN erreichbar
- **DB-Host in Adminer:** `mariadb-webui-db`
- **DB-User:** `mariadb_webui`
- **DB-Name:** `mariadb_webui`

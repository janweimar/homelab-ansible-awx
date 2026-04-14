# 🤖 OpenClaw (Moltbot) — Selbstgehosteter AI-Agent (Nativ auf WSL)

## Übersicht

OpenClaw ist ein selbstgehosteter AI-Agent der Messaging-Apps (WhatsApp, Telegram, Discord, Slack) oder das eingebaute TUI mit einem Ollama-Backend verbindet. In diesem Setup läuft OpenClaw nativ auf WSL und verbindet sich über VPN zum Ollama auf dem AI-Server.

## Komponenten

| Komponente | Beschreibung |
|---|---|
| OpenClaw Gateway | Daemon-Prozess (systemd) auf WSL |
| OpenClaw TUI | Terminal-Interface zum Chatten |
| Ollama CLI | Lokal installiert (für `ollama launch openclaw`) |
| Remote Ollama | AI-Server `10.200.0.23:11434` (VPN) |

## Netzwerk / VPN

| Gerät | VPN-IP |
|---|---|
| VPN-Server | 10.200.0.1 |
| Windows 10 (max) | 10.200.0.10 |
| AI-Server (Ollama) | 10.200.0.23 |

OpenClaw auf WSL nutzt die Windows-VPN-Verbindung (`win10_max` / `10.200.0.10`) um den AI-Server über `http://10.200.0.23:11434` zu erreichen. Kein öffentlicher Zugang nötig.

## Architektur

```
WSL (Windows 10 — VPN: 10.200.0.10)       AI-Server (VPN: 10.200.0.23)
┌─────────────────────┐                   ┌──────────────────┐
│  OpenClaw Gateway    │──── VPN ─────────▶│  Ollama API      │
│  (Port 18789)        │  10.200.0.0/24    │  (Port 11434)    │
│                      │                   │  + Modelle       │
│  TUI / Messaging     │                   │  (qwen3, etc.)   │
└─────────────────────┘                   └──────────────────┘
```

## Voraussetzungen

- WSL2 mit Ubuntu + systemd aktiviert
- SSH-Server in WSL laufend (für AWX)
- WireGuard VPN aktiv auf Windows (`win10_max` / 10.200.0.10)
- AI-Server mit Ollama + Modellen bereits deployed (K3s)

## AWX

- **Playbook:** `pb_setup_app_deploy.yml`
- **Credential:** `a_cred_typ_pb_app_deploy` mit:
  - `app_name=openclaw`
  - `app_deploy_type=nativ`
  - `app_db_type=none`
  - `app_port=18789`
- **Host:** WSL im AWX-Inventory (VPN-IP oder localhost)

## Konfiguration

Die Konfigurationsdatei liegt unter `~/.config/openclaw/config.json` und wird vom Playbook automatisch erstellt:

```json
{
  "models": {
    "providers": {
      "ollama": {
        "baseUrl": "http://10.200.0.23:11434/v1",
        "apiKey": "ollama-local",
        "api": "openai-completions"
      }
    }
  }
}
```

## Messaging (optional)

Aktuell ist nur TUI konfiguriert. Für Telegram/WhatsApp später:

1. Telegram: BotFather → Bot erstellen → Token in OpenClaw Config
2. WhatsApp: QR-Code Pairing über OpenClaw TUI
3. Discord/Slack: Bot-Token über jeweilige Developer-Portale

## Nützliche Befehle

```bash
# TUI starten (interaktiv chatten)
openclaw

# Alternativ über Ollama
ollama launch openclaw

# Gateway-Status prüfen
systemctl status openclaw-gateway

# Gateway-Logs anzeigen
journalctl -u openclaw-gateway -f

# Gateway neu starten
sudo systemctl restart openclaw-gateway

# Version prüfen
openclaw -v

# Konfiguration anzeigen
cat ~/.config/openclaw/config.json | jq .

# VPN-Verbindung zum AI-Server testen
curl -s http://10.200.0.23:11434/api/tags | jq .
```

## Dateien

| Pfad | Beschreibung |
|---|---|
| `~/.config/openclaw/config.json` | Hauptkonfiguration |
| `/etc/systemd/system/openclaw-gateway.service` | systemd Service |
| `/usr/local/bin/openclaw` | OpenClaw Binary |
| `/usr/local/bin/ollama` | Ollama CLI |

## Troubleshooting

| Problem | Lösung |
|---|---|
| Gateway startet nicht | `journalctl -u openclaw-gateway -e` prüfen |
| Ollama nicht erreichbar | VPN prüfen: `ping 10.200.0.23`, dann `curl http://10.200.0.23:11434/api/tags` |
| TUI zeigt keine Modelle | Config prüfen: `baseUrl` muss auf `/v1` enden |
| systemd fehlt in WSL | In `/etc/wsl.conf` unter `[boot]` → `systemd=true` setzen, WSL neu starten |
| VPN geht nicht aus WSL | WSL nutzt Windows-Netzwerk — VPN muss auf Windows aktiv sein |

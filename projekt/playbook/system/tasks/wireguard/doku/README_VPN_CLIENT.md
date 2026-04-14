# 🔒 WireGuard VPN Client - Anleitung

**Playbook:** `pb_setup_vpn_client.yml`
**Erstellt:** 2026-03-15
**Autor:** max

---

## 📁 DATEIEN

```
wireguard/
├── wireguard_client_task.yml       # Client Konfiguration
├── templates/
│   └── wg0-client.conf.j2         # Client WireGuard Config
├── doku/
│   ├── vpn_client_doku.md.j2      # Dokumentations-Template
│   └── README_VPN_CLIENT.md       # Diese Datei
```

---

## 🔧 FUNKTIONSWEISE

- Client-Identifikation ueber `ansible_default_ipv4.address` in `vpn_clients` (vpn.yml)
- Private Key kommt aus AWX Credential (`XXXX_wg_privkey`)
- Server Public Key + Client-Liste aus `vpn.yml` (ueber var_files)
- Kein Cross-Server SSH noetig

---

## 📝 AWX CREDENTIALS

| Credential | Beschreibung |
|-----------|-------------|
| `XXXX_wg_privkey` | WireGuard Private Key (pro Server) |
| `0000_global_*` | Standard Credentials (3 Stueck) |
| `XXXX_machine_max` | Machine Credential |

---

## 🛠️ NUETZLICHE BEFEHLE

```bash
# Status pruefen
systemctl status wg-quick@wg0
wg show wg0

# VPN-Verbindung testen
ping 10.200.0.1

# Logs
journalctl -u wg-quick@wg0 -n 50

# Manuell starten/stoppen
wg-quick up wg0
wg-quick down wg0
```

---

## 🔍 TROUBLESHOOTING

```bash
# Interface vorhanden?
ip link show wg0

# Config pruefen
cat /etc/wireguard/wg0.conf

# Handshake pruefen (sollte < 2min sein)
wg show wg0 latest-handshakes

# Firewall blockiert?
nft list ruleset | grep wg0

# DNS-Aufloesung ueber VPN?
resolvconf -l
```

---

## 🔧 NOTFALL

```bash
# VPN stoppen
systemctl stop wg-quick@wg0

# Interface entfernen
wg-quick down wg0

# Deinstallieren via Ansible
ansible-playbook pb_setup_vpn_client.yml -e "allg_status=deinstalliert"
```

---

**Version:** 1.0
**Letzte Aenderung:** 2026-03-15

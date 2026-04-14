# 🔒 WireGuard VPN Server - Komplette Anleitung

**Playbook:** `pb_inst_vpn_server.yml` + `pb_conf_vpn_client.yml`  
**Erstellt:** 2026-03-01  
**Autor:** max  
**VPN Subnet:** 10.200.0.0/24

---

## 📁 ORDNER-STRUKTUR

```
wireguard/
├── wireguard_server_pretask.yml    # Server Voraussetzungen prüfen
├── wireguard_server_task.yml       # Server Installation & Konfiguration
├── wireguard_server_post_task.yml  # Server Validierung & Info
├── wireguard_client_task.yml       # Client Konfiguration
├── templates/
│   ├── wg0-server.conf.j2         # Server WireGuard Config
│   ├── wg0-client.conf.j2         # Client WireGuard Config
│   └── wg-nftables.conf.j2        # nftables Firewall-Regeln
├── doku/
│   ├── vpn_server_doku.md.j2      # Dokumentations-Template
│   └── README_VPN_SERVER.md       # Diese Datei
```

---

## 🎯 PLAYBOOK-VERWENDUNG

### Server Playbook

**Datei:** `pb_inst_vpn_server.yml`

```yaml
- name: Include Pre-Tasks
  ansible.builtin.import_tasks: playbook/system/tasks/wireguard/wireguard_server_pretask.yml

- name: Include WireGuard Server Installation
  ansible.builtin.import_tasks: playbook/system/tasks/wireguard/wireguard_server_task.yml

- name: Include Post-Tasks
  ansible.builtin.import_tasks: playbook/system/tasks/wireguard/wireguard_server_post_task.yml
```

### Client Playbook

**Datei:** `pb_conf_vpn_client.yml`

```yaml
- name: Include WireGuard Client Configuration
  ansible.builtin.import_tasks: playbook/system/tasks/wireguard/wireguard_client_task.yml
```

---

## 📝 BENÖTIGTE VARIABLEN

### os_packages.yml

```yaml
packages:
  apt:
    wireguard:
      - wireguard
      - wireguard-tools
      - qrencode
      - iptables
      - resolvconf
```

### os_services.yml

```yaml
services:
  wireguard:
    start:
      Debian: "systemctl start wg-quick@wg0"
    enable:
      Debian: "systemctl enable wg-quick@wg0"
    restart:
      Debian: "systemctl restart wg-quick@wg0"
    status:
      Debian: "systemctl status wg-quick@wg0"
```

### Keys

**Pfad:** `playbook/system/templates/wireguard_keys/`

```
wireguard_keys/
├── server/
│   ├── private.key
│   └── public.key
└── clients/
    ├── wazuh_manager/
    ├── mail_server/
    └── ...
```

---

## 🛠️ NÜTZLICHE BEFEHLE

### Service-Management

**Service-Status prüfen:**

```bash
systemctl status wg-quick@wg0
```

**Service neu starten:**

```bash
systemctl restart wg-quick@wg0
```

**Logs anzeigen:**

```bash
journalctl -u wg-quick@wg0 -n 50
journalctl -u wg-quick@wg0 -f  # Follow mode
```

### WireGuard Interface

**Interface-Status anzeigen:**

```bash
wg show
wg show wg0
```

**Detaillierte Interface-Info:**

```bash
ip addr show wg0
ip link show wg0
```

**Connected Peers anzeigen:**

```bash
wg show wg0 peers
```

**Handshake-Zeiten prüfen:**

```bash
wg show wg0 latest-handshakes
```

**Transfer-Statistiken:**

```bash
wg show wg0 transfer
```

### Konfiguration

**WireGuard Konfiguration anzeigen:**

```bash
cat /etc/wireguard/wg0.conf
```

**Client Configs anzeigen:**

```bash
ls -la /etc/wireguard/clients/
cat /etc/wireguard/clients/wazuh_manager.conf
```

**Manuell starten/stoppen:**

```bash
wg-quick up wg0
wg-quick down wg0
```

---

## 🔍 TROUBLESHOOTING

### Problem: Client kann nicht verbinden

**1. Server-seitig prüfen:**

```bash
# Port lauscht?
ss -ulnp | grep 51820

# Firewall erlaubt Port?
nft list ruleset | grep 51820

# Interface UP?
ip link show wg0

# Logs checken
journalctl -u wg-quick@wg0 -n 50
```

**2. Client Public Key prüfen:**

```bash
wg show wg0 peers
```

**3. Handshake testen:**

```bash
# Von Client aus
ping 10.200.0.1

# Auf Server prüfen
wg show wg0 latest-handshakes
```

### Problem: Kein Traffic über VPN

```bash
# IP Forwarding aktiv?
sysctl net.ipv4.ip_forward
sysctl net.ipv6.conf.all.forwarding

# NAT-Regeln aktiv?
nft list ruleset | grep masquerade

# Routing-Table prüfen
ip route show table all | grep wg0
```

### Problem: Performance-Probleme

```bash
# MTU prüfen und anpassen
ip link set mtu 1420 dev wg0

# Transfer-Statistiken
wg show wg0 transfer

# Systemlast
htop
iftop -i wg0
```

---

## 🛡️ SICHERHEIT

### Umgesetzte Maßnahmen

- ✅ Private Keys chmod 600 (nur root lesbar)
- ✅ Firewall-Regeln: Port 51820/UDP eingeschränkt
- ✅ IP Forwarding nur für VPN-Interface
- ✅ NAT/Masquerading für Clients
- ✅ PersistentKeepalive für NAT-Traversal (25 Sekunden)

### Wichtige Hinweise

- **Keys rotieren:** Alle 6-12 Monate
- **Client-Configs sicher übertragen:** SCP verwenden, NICHT Email!
- **Firewall-Logs überwachen:** Fail2Ban Integration empfohlen
- **VPN-only Konfiguration:** Für kritische Services (z.B. Wazuh Manager)

### Client hinzufügen

**1. Key generieren:**

```bash
cd playbook/system/templates/wireguard_keys/clients
mkdir new_client
wg genkey | tee new_client/private.key | wg pubkey > new_client/public.key
chmod 600 new_client/private.key
```

**2. In Playbook hinzufügen:**

```yaml
# pb_inst_vpn_server.yml
vpn_clients:
  - name: "new_client"
    ansible_host: "1.2.3.4"
    vpn_ip: "10.200.0.30"
```

**3. Server neu deployen:**

```bash
ansible-playbook pb_inst_vpn_server.yml -i inventory/production
```

---

## 🔧 NOTFALL-ZUGRIFF

Falls VPN Probleme verursacht:

**1. Service stoppen (behält Config):**

```bash
systemctl stop wg-quick@wg0
```

**2. Interface komplett entfernen:**

```bash
wg-quick down wg0
ip link delete wg0
```

**3. Firewall-Regeln entfernen:**

```bash
rm /etc/nftables.d/30-wireguard.nft
systemctl reload nftables
```

**4. IP Forwarding deaktivieren:**

```bash
sysctl -w net.ipv4.ip_forward=0
sysctl -w net.ipv6.conf.all.forwarding=0
```

**5. Service komplett deinstalliert:**

```bash
ansible-playbook pb_inst_vpn_server.yml -e "allg_status=deinstalliert"
```

---

## 📁 WICHTIGE DATEIEN

| Pfad | Beschreibung |
|------|-------------|
| `/etc/wireguard/wg0.conf` | Server Hauptkonfiguration |
| `/etc/wireguard/server_private.key` | Server Private Key (chmod 600) |
| `/etc/wireguard/clients/` | Generierte Client Configs |
| `/etc/nftables.d/30-wireguard.nft` | Firewall-Regeln |
| `playbook/system/templates/wireguard_keys/` | Vorgefertigte Keys (Ansible) |

---

## 🚀 NÄCHSTE SCHRITTE

### 1. Client-Konfiguration deployen

```bash
# Auf jedem Client ausführen
ansible-playbook pb_conf_vpn_client.yml -i inventory/production

# Einzelner Client
ansible-playbook pb_conf_vpn_client.yml -l wazuh_manager
```

### 2. VPN-Verbindung testen

```bash
# Von Client aus
ping 10.200.0.1
```

### 3. Wazuh Manager auf VPN-only umstellen

```bash
# Firewall anpassen: Nur VPN-IPs erlauben
# Siehe: KONZEPT 7 (VPN-only Wazuh)
```

### 4. Monitoring einrichten

```bash
# Fail2Ban für VPN-Port
# Wazuh Agent für VPN-Monitoring
# Alerting bei Verbindungsabbrüchen
```

---

## 📋 CHECKLISTE POST-DEPLOYMENT

- [ ] Service läuft: `systemctl status wg-quick@wg0`
- [ ] Interface UP: `ip link show wg0`
- [ ] Port lauscht: `ss -ulnp | grep 51820`
- [ ] Firewall-Regeln aktiv: `nft list ruleset | grep wireguard`
- [ ] IP Forwarding aktiviert: `sysctl net.ipv4.ip_forward`
- [ ] Client Configs generiert: `ls /etc/wireguard/clients/`
- [ ] Clients können verbinden: `wg show wg0 peers`
- [ ] Monitoring eingerichtet
- [ ] Backup der Keys erstellt

---

## ✅ DEPLOYMENT STATUS

**Task-Status:**

- [x] Server PreTask erstellt
- [x] Server Task erstellt
- [x] Server PostTask erstellt
- [x] Client Task erstellt
- [x] Server Template erstellt
- [x] Client Template erstellt
- [x] nftables Template erstellt
- [x] Dokumentations-Template erstellt

**BEREIT FÜR DEPLOYMENT!**

---

**Version:** 1.0  
**Letzte Änderung:** 2026-03-01  
**Autor:** max

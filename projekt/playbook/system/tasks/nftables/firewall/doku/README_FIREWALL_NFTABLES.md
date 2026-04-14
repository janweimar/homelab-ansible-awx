# 🛡️ nftables Firewall - Betriebsanleitung

**Playbook:** `pb_inst_firewall_nftables.yml`  
**Zweck:** Stateful Firewall mit nftables

---

## 🏗️ FIREWALL-STRUKTUR

- **Tabelle:** `inet fire_tab`
- **Chains:** `in_chain`, `out_chain`, `for_chain`
- **Priorität:** -170
- **Konfiguration:** `/etc/nftables.conf`
- **Includes:** `/etc/nftables.d/*.nft`

---

## 🛠️ NÜTZLICHE BEFEHLE

### Service-Management

**Status prüfen:**
```bash
systemctl status nftables
```

**Service neu laden:**
```bash
systemctl reload nftables
```

**Service neu starten:**
```bash
systemctl restart nftables
```

### Regeln anzeigen

**Komplettes Ruleset:**
```bash
nft list ruleset
```

**Spezifische Tabelle:**
```bash
nft list table inet fire_tab
```

**Ohne Sets (übersichtlicher):**
```bash
nft list table inet fire_tab | sed '/^[[:space:]]*set /,/^[[:space:]]*}/d'
```

**Einzelne Chains:**
```bash
nft list chain inet fire_tab in_chain
nft list chain inet fire_tab out_chain
nft list chain inet fire_tab for_chain
```

**Alle Chains durchgehen:**
```bash
for chain in in_chain out_chain for_chain; do
  echo "=== $chain ==="
  nft list chain inet fire_tab $chain
  echo ""
done
```

### Konfiguration testen

**Syntax prüfen:**
```bash
nft -c -f /etc/nftables.conf
```

**Logs anzeigen:**
```bash
journalctl -u nftables -n 50
```

---

## 🔍 TROUBLESHOOTING

### Problem: Service startet nicht

```bash
# Syntax prüfen
nft -c -f /etc/nftables.conf

# Logs prüfen
journalctl -u nftables -n 100

# Manuell laden (Debug)
nft -f /etc/nftables.conf
```

### Problem: Verbindung verloren

**1. Warte auf Rollback-Timer**
- Timer läuft automatisch ab
- Firewall wird zurückgesetzt

**2. Physischer/Console-Zugriff:**
```bash
# Firewall stoppen
systemctl stop nftables

# Oder alle Regeln löschen
nft flush ruleset
```

**3. Notfall - Alles erlauben:**
```bash
nft add table inet filter
nft add chain inet filter input '{ type filter hook input priority 0; policy accept; }'
nft add chain inet filter forward '{ type filter hook forward priority 0; policy accept; }'
nft add chain inet filter output '{ type filter hook output priority 0; policy accept; }'
```

### Problem: Port nicht offen

```bash
# Regel prüfen
nft list ruleset | grep <PORT>

# Chain prüfen
nft list chain inet fire_tab in_chain

# Service lauscht?
ss -tulpn | grep <PORT>
```

---

## 🔧 REGELN ANPASSEN

### Port öffnen (temporär)

```bash
# TCP Port
nft add rule inet fire_tab in_chain tcp dport 8080 accept

# UDP Port
nft add rule inet fire_tab in_chain udp dport 5353 accept
```

**ACHTUNG:** Geht bei Reload verloren!

### Port öffnen (permanent)

**1. Via Ansible (empfohlen):**
```yaml
# AWX Credentials anpassen
in_ports: "22,80,443,8080"
```

**2. Manuell:**
```bash
# In /etc/nftables.d/10-custom.nft
add rule inet fire_tab in_chain tcp dport 8080 accept

# Reload
systemctl reload nftables
```

---

## 🛡️ SICHERHEIT

### Best Practices

- ✅ Default Policy: INPUT/FORWARD = DROP
- ✅ OUTPUT = ACCEPT (Server muss raus können)
- ✅ Nur benötigte Ports öffnen
- ✅ Rollback-Timer bei Änderungen nutzen
- ✅ Logging für verdächtige Pakete

### Rollback-Timer nutzen

```bash
# In Playbook setzen
rollback_timeout: 300  # 5 Minuten

# Manue

ll testen
nft -f /etc/nftables.conf.new && sleep 300 && nft -f /etc/nftables.conf.backup
```

---

## 📁 WICHTIGE DATEIEN

| Pfad | Beschreibung |
|------|-------------|
| `/etc/nftables.conf` | Hauptkonfiguration |
| `/etc/nftables.d/` | Include-Verzeichnis |
| `/etc/nftables.d/10-fire_tab.nft` | Firewall-Regeln |

---

## ✅ CHECKLISTE POST-DEPLOYMENT

- [ ] Service läuft: `systemctl status nftables`
- [ ] Regeln geladen: `nft list ruleset`
- [ ] SSH-Port offen (Test vor Logout!)
- [ ] Wichtige Services erreichbar
- [ ] Rollback-Timer getestet
- [ ] Backup der funktionierenden Config

---

**Version:** 1.0  
**Letzte Änderung:** 2026-03-01

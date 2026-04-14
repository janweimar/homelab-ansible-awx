# 🌍 GeoIP Blocking - Betriebsanleitung

**Playbook:** `pb_inst_geoblock_nftables.yml`  
**Zweck:** Geografisches Blocking mit nftables

---

## 🏗️ GEOIP-STRUKTUR

- **Tabelle:** `inet geo_tab`
- **Chain:** `geo_chain` (Priorität: -200)
- **Datenbank:** DB-IP Country Lite
- **Location File:** `location.csv`

---

## 📁 WICHTIGE DATEIEN

| Pfad | Beschreibung |
|------|-------------|
| `/etc/nftables.d/05-geo_tab.nft` | GeoIP Regeln |
| `playbook/system/daten/dbip-country-lite.csv` | IP-Datenbank |
| `playbook/system/daten/location.csv` | Länder-Mapping |
| `playbook/system/skript/nft_geoip.py` | GeoIP Parser |
| `playbook/system/daten/failsafe_ips.yml` | Trusted IPs |

---

## 🛠️ NÜTZLICHE BEFEHLE

### GeoIP Regeln anzeigen

**Komplette GeoIP Tabelle:**

```bash
nft list table inet geo_tab
```

**Ohne Sets (übersichtlich):**

```bash
nft list table inet geo_tab | sed '/^[[:space:]]*set /,/^[[:space:]]*}/d'
```

**GeoIP Chain:**

```bash
nft list chain inet geo_tab geo_chain
```

### Blockierte Länder anzeigen

```bash
nft list set inet geo_tab blocked_countries
```

### Trusted IPs anzeigen

```bash
nft list set inet geo_tab trusted_ips
```

### GeoIP-Datenbank prüfen

```bash
# Datenbank-Dateien
ls -lh playbook/system/daten/dbip-country-lite.csv
ls -lh playbook/system/daten/location.csv

# Anzahl Einträge
wc -l playbook/system/daten/dbip-country-lite.csv
```

---

## 🔍 TROUBLESHOOTING

### Problem: Legitime Verbindungen werden blockiert

**1. Prüfe Herkunftsland:**

```bash
# IP zu Land zuordnen (online)
whois 1.2.3.4 | grep -i country
```

**2. Zur Whitelist hinzufügen:**

```yaml
# In failsafe_ips.yml
in:
  global:
    ipv4:
      - 1.2.3.4/32
```

**3. Playbook neu ausführen:**

```bash
ansible-playbook pb_inst_geoblock_nftables.yml
```

### Problem: GeoIP funktioniert nicht

```bash
# Tabelle existiert?
nft list tables | grep geo_tab

# Chain existiert?
nft list chain inet geo_tab geo_chain

# Python-Script vorhanden?
ls -la playbook/system/skript/nft_geoip.py

# Datenbank aktuell?
stat playbook/system/daten/dbip-country-lite.csv
```

### Problem: Falsche Länder blockiert

**Prüfe Konfiguration:**

```yaml
# In AWX Credentials oder vars
geo_mode: whitelist  # oder blacklist
geo_countries: "DE,FR,GB"  # ISO-3166 Codes
```

**Modi:**

- `whitelist`: Nur diese Länder erlaubt
- `blacklist`: Diese Länder blockiert

---

## 🛡️ SICHERHEIT

### Best Practices

- ✅ Eigene IP immer in Trusted IPs
- ✅ AWX/Ansible Server-Land freigeben
- ✅ Wichtige Services (HTTP/HTTPS) bei Whitelist freigeben
- ✅ Rollback-Timer bei Änderungen nutzen
- ✅ Logs überwachen

### Rollback-Timer

```bash
# In Playbook setzen
rollback_timeout: 300  # 5 Minuten
```

**Funktionsweise:**

1. GeoIP wird aktiviert
2. Timer startet
3. Bei Verbindungsverlust: Auto-Rollback nach Timer
4. Bei erfolgreicher Bestätigung: Timer abbrechen

---

## 🔧 KONFIGURATION ANPASSEN

### Modus wechseln

```yaml
# Whitelist: Nur diese Länder erlaubt
geo_mode: whitelist
geo_countries: "DE,AT,CH"

# Blacklist: Diese Länder blockiert
geo_mode: blacklist
geo_countries: "CN,RU,KP"
```

### HTTP/HTTPS immer erlauben

```yaml
# Bei Whitelist empfohlen
allow_http: true
allow_https: true
```

### Land hinzufügen/entfernen

```yaml
# Aktuell: "DE,FR"
# Neu: "DE,FR,GB"
geo_countries: "DE,FR,GB"
```

**Playbook neu ausführen!**

---

## 📝 LÄNDER-CODES (ISO-3166-1)

### Häufig verwendete Codes

| Code | Land |
|------|------|
| DE | Deutschland |
| AT | Österreich |
| CH | Schweiz |
| FR | Frankreich |
| GB | Großbritannien |
| US | USA |
| CN | China |
| RU | Russland |
| KP | Nordkorea |
| IR | Iran |

**Vollständige Liste:** <https://de.wikipedia.org/wiki/ISO-3166-1-Kodierliste>

---

## 🚨 NOTFALL-ZUGRIFF

Falls GeoIP Probleme verursacht:

**1. GeoIP temporär deaktivieren:**

```bash
nft flush table inet geo_tab
```

**2. Nur Chain leeren:**

```bash
nft flush chain inet geo_tab geo_chain
```

**3. GeoIP komplett entfernen:**

```bash
nft delete table inet geo_tab
```

**4. Firewall stoppen:**

```bash
systemctl stop nftables
```

**5. Via Playbook deinstalliert:**

```bash
ansible-playbook pb_inst_geoblock_nftables.yml -e "allg_status=deinstalliert"
```

---

## 📊 MONITORING

### Geblockte Verbindungen zählen

```bash
# Logs durchsuchen
journalctl -u nftables | grep -i "geoip\|geo_tab" | wc -l
```

### Top geblockte Länder

```bash
# Aus nftables Counter (falls konfiguriert)
nft list table inet geo_tab | grep -A 1 counter
```

---

## ✅ CHECKLISTE POST-DEPLOYMENT

- [ ] Service läuft: `systemctl status nftables`
- [ ] GeoIP Tabelle existiert: `nft list table inet geo_tab`
- [ ] Eigene IP in Trusted IPs
- [ ] AWX Server-Land freigegeben
- [ ] Test mit externer IP (VPN)
- [ ] HTTP/HTTPS funktioniert (falls aktiviert)
- [ ] Rollback-Timer getestet
- [ ] Logs überwacht

---

**Version:** 1.0  
**Letzte Änderung:** 2026-03-01

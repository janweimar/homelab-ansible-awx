# 🔒 Fail2Ban + nftables - Betriebsanleitung

**Playbook:** `pb_inst_fail2ban_nftables.yml`  
**Zweck:** Intrusion Prevention System mit nftables Integration

---

## 📁 WICHTIGE DATEIEN

| Pfad | Beschreibung |
|------|-------------|
| `/etc/fail2ban/jail.local` | Default-Konfiguration |
| `/etc/fail2ban/jail.d/` | Jail-Konfigurationen |
| `/etc/fail2ban/action.d/nftables_custom.conf` | Custom nftables Action |
| `/etc/fail2ban/action.d/nftables-allports_custom.conf` | Allports Action |
| `/etc/fail2ban/action.d/nftables-multiport_custom.conf` | Multiport Action |
| `/etc/fail2ban/filter.d/` | Custom Filter (Odoo) |
| `/etc/nftables.d/20_f2b_ruleset.nft` | Fail2Ban nftables Ruleset |

---

## 🏗️ NFTABLES STRUKTUR

- **Tabelle:** `inet f2b_tab`
- **Chain:** `f2b_chain` (hook input, priority -1)
- **Sets:** `f2b_set_ip4`, `f2b_set_ip6`
- **Ruleset-Datei:** `/etc/nftables.d/20_f2b_ruleset.nft`

---

## 🛠️ NÜTZLICHE BEFEHLE

### Service-Management

**Status prüfen:**
```bash
systemctl status fail2ban
fail2ban-client status
```

**Service neu starten:**
```bash
systemctl restart fail2ban
```

**Logs anzeigen:**
```bash
journalctl -u fail2ban -n 50
journalctl -u fail2ban -f
```

### Jail-Management

**Alle Jails anzeigen:**
```bash
fail2ban-client status
```

**Spezifischen Jail prüfen:**
```bash
fail2ban-client status sshd
fail2ban-client status nginx-generic
```

**Gebannte IPs anzeigen:**
```bash
fail2ban-client get sshd banip
```

**IP manuell bannen:**
```bash
fail2ban-client set sshd banip 1.2.3.4
```

**IP entbannen:**
```bash
fail2ban-client set sshd unbanip 1.2.3.4
```

**Jail neu laden:**
```bash
fail2ban-client reload sshd
```

### nftables Integration

**F2B Tabelle anzeigen:**
```bash
nft list table inet f2b_tab
```

**F2B Sets anzeigen:**
```bash
nft list set inet f2b_tab f2b_set_ip4
nft list set inet f2b_tab f2b_set_ip6
```

**Gebannte IPs in nftables:**
```bash
nft list set inet f2b_tab f2b_set_ip4 | grep elements
```

---

## 🔍 TROUBLESHOOTING

### Problem: Fail2Ban startet nicht

```bash
# Konfiguration testen
fail2ban-client -t

# Logs prüfen
journalctl -u fail2ban -n 100

# Syntax einzelner Jail testen
fail2ban-client -d
```

### Problem: Jail bannt nicht

```bash
# Jail Status prüfen
fail2ban-client status sshd

# Filter testen
fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf

# Log-Pfad prüfen
grep logpath /etc/fail2ban/jail.d/*.conf
```

### Problem: IP wurde fälschlich gebannt

```bash
# IP sofort entbannen
fail2ban-client set sshd unbanip 1.2.3.4

# IP zur Whitelist hinzufügen
# In /etc/fail2ban/jail.local:
# ignoreip = 127.0.0.1/8 1.2.3.4

# Fail2Ban neu laden
systemctl reload fail2ban
```

### Problem: nftables Sets nicht synchron

```bash
# Sets manuell prüfen
nft list set inet f2b_tab f2b_set_ip4

# Fail2Ban neu starten (synchronisiert Sets)
systemctl restart fail2ban

# nftables neu laden
systemctl reload nftables
```

---

## 🛡️ SICHERHEIT

### Best Practices

- ✅ Whitelist eigene IPs in `ignoreip`
- ✅ Bantime nicht zu kurz (min. 1 Stunde)
- ✅ Maxretry konservativ (3-5 Versuche)
- ✅ Logs regelmäßig prüfen
- ✅ Fail2Ban-Logs nach Fehlalarmen durchsuchen

### IP zur Whitelist hinzufügen

**1. In Ansible:**
```yaml
# In failsafe_ips.yml unter f2b.ignore
f2b:
  ignore:
    ipv4:
      - 1.2.3.4
```

**2. Manuell (temporär):**
```bash
# In /etc/fail2ban/jail.local
[DEFAULT]
ignoreip = 127.0.0.1/8 1.2.3.4

# Reload
systemctl reload fail2ban
```

---

## 🔧 KONFIGURATION ANPASSEN

### Bantime ändern

```bash
# In /etc/fail2ban/jail.local oder jail.d/*.conf
[sshd]
bantime = 3600  # 1 Stunde in Sekunden

# Reload
systemctl reload fail2ban
```

### Neuen Jail hinzufügen

```bash
# Neue Datei erstellen
vi /etc/fail2ban/jail.d/custom-jail.conf

# Inhalt:
[custom]
enabled = true
port = 8080
filter = custom-filter
logpath = /var/log/custom.log
maxretry = 5
bantime = 3600

# Filter erstellen
vi /etc/fail2ban/filter.d/custom-filter.conf

# Reload
systemctl reload fail2ban
```

---

## 📊 MONITORING

### Statistiken anzeigen

```bash
# Gebannte IPs zählen
fail2ban-client status sshd | grep "Currently banned"

# Top gebannte IPs
grep "Ban " /var/log/fail2ban.log | awk '{print $NF}' | sort | uniq -c | sort -rn | head -10

# Jail-Aktivität
grep "Found" /var/log/fail2ban.log | tail -20
```

### Regelmäßige Checks

```bash
# Cron-Job für täglichen Report
0 8 * * * fail2ban-client status | mail -s "Fail2Ban Status" admin@example.com
```

---

## ✅ CHECKLISTE POST-DEPLOYMENT

- [ ] Service läuft: `systemctl status fail2ban`
- [ ] Alle Jails aktiv: `fail2ban-client status`
- [ ] nftables Sets existieren: `nft list sets`
- [ ] Eigene IPs in Whitelist
- [ ] Test-Ban durchgeführt
- [ ] Logs überwacht: `journalctl -u fail2ban -f`
- [ ] Monitoring eingerichtet

---

**Version:** 1.0  
**Letzte Änderung:** 2026-03-01

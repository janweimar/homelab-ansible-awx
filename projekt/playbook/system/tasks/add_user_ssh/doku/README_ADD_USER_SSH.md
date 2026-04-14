# 🔐 SSH Sicherheit - Betriebsanleitung

**Playbook:** `pb_conf_add_sudo_user_add_ssh_key_secure.yml`  
**Zweck:** Sicherer SSH-Zugang mit Key-Auth

---

## 🔑 SSH-VERBINDUNG

**Verbinden:**
```bash
ssh -p 2222 username@server-ip
```

**Mit spezifischem Key:**
```bash
ssh -p 2222 -i ~/.ssh/id_ed25519 username@server-ip
```

---

## 🛠️ SSH-VERWALTUNG

**Service-Status:**
```bash
systemctl status ssh
```

**Config testen:**
```bash
sshd -t
```

**Config neu laden:**
```bash
systemctl reload ssh
```

**Logs:**
```bash
journalctl -u ssh -f
tail -f /var/log/auth.log
```

---

## 🔍 TROUBLESHOOTING

**Problem: Verbindung verweigert**
```bash
# Port prüfen
ss -tlnp | grep 2222

# Firewall prüfen
nft list ruleset | grep 2222

# Logs prüfen
tail -100 /var/log/auth.log
```

**Problem: Key-Auth funktioniert nicht**
```bash
# Permissions prüfen
ls -la ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Public Key prüfen
cat ~/.ssh/authorized_keys
```

---

## 📁 WICHTIGE DATEIEN

| Pfad | Beschreibung |
|------|-------------|
| `/etc/ssh/sshd_config` | SSH Server Config |
| `/home/user/.ssh/authorized_keys` | Public Keys |
| `/etc/sudoers.d/username` | Sudo-Rechte |
| `/var/log/auth.log` | SSH Logs |

---

**Version:** 1.0

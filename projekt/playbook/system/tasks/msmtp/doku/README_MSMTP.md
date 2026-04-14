# 📧 msmtp - Betriebsanleitung

**Playbook:** `pb_inst_conf_msmtp.yml`

---

## 🛠️ BEFEHLE

**Test-Mail senden:**
```bash
echo "Test" | msmtp -a default recipient@example.com
```

**Config testen:**
```bash
msmtp -a default --serverinfo
```

---

**Version:** 1.0

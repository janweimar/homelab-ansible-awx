# 📋 Audit - Betriebsanleitung

**Playbook:** `pb_inst_audit.yml`

---

## 🛠️ BEFEHLE

**Status:**
```bash
systemctl status auditd
auditctl -s
```

**Regeln:**
```bash
auditctl -l
```

**Logs:**
```bash
ausearch -ts today
ausearch -m avc
```

---

**Version:** 1.0

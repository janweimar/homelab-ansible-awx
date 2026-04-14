# 🛡️ AppArmor - Betriebsanleitung

**Playbook:** `pb_inst_apparmor.yml`  
**Zweck:** Mandatory Access Control

---

## 🛠️ BEFEHLE

**Status:**
```bash
aa-status
```

**Profil in Enforce:**
```bash
aa-enforce /etc/apparmor.d/usr.sbin.nginx
```

**Profil in Complain:**
```bash
aa-complain /etc/apparmor.d/usr.sbin.nginx
```

**Profil deaktivieren:**
```bash
aa-disable /etc/apparmor.d/usr.sbin.nginx
```

**Logs:**
```bash
journalctl -fx | grep -i apparmor
```

---

**Version:** 1.0

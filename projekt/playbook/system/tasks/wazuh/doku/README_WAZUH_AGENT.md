# 🔒 Wazuh Agent - Betriebsanleitung

**Playbook:** `pb_setup_wazuh_agent.yml`

---

## 🔧 AWX Credentials

Keine eigenen Credentials noetig. Nur Standard-Credentials:

* Machine Credential (SSH-Key)
* SMTP Credential (`admin_email`, `smtp_user`)
* Status Credential (`allg_status`, `update_before_install`)
* Playbook-Log Credential

---

## 🛠️ BEFEHLE

**Agent Status:**
```bash
systemctl status wazuh-agent
```

**Agent neustarten:**
```bash
systemctl restart wazuh-agent
```

**Agent-Info anzeigen:**
```bash
/var/ossec/bin/agent-control -i 000
```

**Verbindung zum Manager pruefen:**
```bash
/var/ossec/bin/agent_control -lc
```

**Logs ansehen:**
```bash
tail -f /var/ossec/logs/ossec.log
```

---

## 📋 Konfiguration

| Einstellung         | Wert                              |
|---------------------|-----------------------------------|
| Config-Datei        | `/var/ossec/etc/ossec.conf`       |
| Logfile             | `/var/ossec/logs/ossec.log`       |
| Manager-IP          | 10.200.0.20 (ueber VPN)          |
| Protokoll           | TCP Port 1514                     |
| Registrierung       | Port 1515                         |
| Verschluesselung    | AES                               |

---

## ⚠️ Hinweise

* Der Agent verbindet sich ueber VPN (10.200.0.20) zum Wazuh Manager
* Wenn der Manager nicht laeuft, wartet der Agent und verbindet sich automatisch
* Registrierung wird nur durchgefuehrt wenn der Manager erreichbar ist
* Nach Manager-Neuinstallation muss der Agent ggf. neu registriert werden:

```bash
/var/ossec/bin/agent-auth -m 10.200.0.20 -A $(hostname)
systemctl restart wazuh-agent
```

---

**Version:** 1.0

# 🛡️ rkhunter - Betriebsanleitung

**Playbook:** `pb_setup_rkhunter.yml`

---

## 🔧 AWX Credentials

Keine eigenen Credentials noetig. Nur Standard-Credentials:

* Machine Credential (SSH-Key)
* SMTP Credential (`admin_email`, `smtp_user`)
* Status Credential (`allg_status`, `update_before_install`)
* Playbook-Log Credential

---

## 🛠️ BEFEHLE

**Manueller Scan:**
```bash
rkhunter --check --sk --nocolors
```

**Nur Warnungen anzeigen:**
```bash
rkhunter --check --sk --nocolors --report-warnings-only
```

**Signaturen aktualisieren:**
```bash
rkhunter --update
```

**Baseline neu erstellen (nach Paket-Updates):**
```bash
rkhunter --propupd
```

**Log ansehen:**
```bash
cat /var/log/rkhunter.log
```

---

## 📋 Konfiguration

| Einstellung         | Wert                           |
|---------------------|--------------------------------|
| Config-Datei        | `/etc/rkhunter.conf`           |
| Logfile             | `/var/log/rkhunter.log`        |
| Cronjob             | Taeglich 03:00 Uhr            |
| Mail bei Warnung    | Ja (ueber msmtp)              |
| PKGMGR              | DPKG (Debian)                  |
| SSH Root erlaubt    | Nein                           |

---

## ⚠️ Wichtig nach System-Updates

Nach `apt upgrade` oder Paketaenderungen koennen False Positives auftreten.
Dann Baseline neu erstellen:

```bash
rkhunter --propupd
```

---

## 🔍 Typische False Positives

* `/usr/bin/lwp-request` — Perl-Modul, harmlos
* Geaenderte Binaries nach `apt upgrade` — `--propupd` ausfuehren

---

**Version:** 1.0

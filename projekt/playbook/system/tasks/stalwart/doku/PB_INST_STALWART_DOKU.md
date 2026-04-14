# STALWART MAIL SERVER — SYSTEM KONFIGURATION

## INSTALLATIONS-STATUS

### Zugriff

- **Admin-GUI:** VPN-only via nginx
- **SMTP:** mail.<domain> .de:25 / 587 / 465
- **IMAP:** mail.<domain> .de:143 / 993

### Account-Verwaltung

Accounts werden per CSV verwaltet:
`playbook/system/tasks/stalwart/daten/accounts.csv`

CSV ist die **einzige Wahrheit** — was nicht in der CSV steht wird gelöscht!

### DNS-Einträge (PFLICHT nach Installation)

```
MX    <domain> .de.        10  mail.<domain> .de.
A     mail.<domain> .de.   →   <SERVER-IP>
TXT   <domain> .de.        "v=spf1 mx ~all"
TXT   _dmarc.<domain> .de. "v=DMARC1; p=quarantine; rua=mailto:postmaster@<domain> .de"
```

DKIM-Record: Im Admin-GUI unter **Management → Domains → <domain> .de** abrufen.

### Sicherheit

- ✅ TLS: STARTTLS + implizit TLS
- ✅ DKIM automatisch generiert
- ✅ SPF + DMARC konfiguriert
- ✅ Rate Limiting eingebaut
- ✅ IP-Blocking (Fail2Ban-ähnlich) eingebaut
- ✅ Nur authentifizierte User dürfen senden
- ✅ Admin-GUI VPN-only

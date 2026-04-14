# STALWART MAIL SERVER — SYSTEM KONFIGURATION

## INSTALLATIONS-STATUS

### Zugriff
- **Admin-GUI:** VPN-only via nginx
- **SMTP:** mail.allgemeinhobby.de:25 / 587 / 465
- **IMAP:** mail.allgemeinhobby.de:143 / 993

### Account-Verwaltung
Accounts werden per CSV verwaltet:
`playbook/system/tasks/stalwart/daten/accounts.csv`

CSV ist die **einzige Wahrheit** — was nicht in der CSV steht wird gelöscht!

### DNS-Einträge (PFLICHT nach Installation)
```
MX    allgemeinhobby.de.        10  mail.allgemeinhobby.de.
A     mail.allgemeinhobby.de.   →   <SERVER-IP>
TXT   allgemeinhobby.de.        "v=spf1 mx ~all"
TXT   _dmarc.allgemeinhobby.de. "v=DMARC1; p=quarantine; rua=mailto:postmaster@allgemeinhobby.de"
```
DKIM-Record: Im Admin-GUI unter **Management → Domains → allgemeinhobby.de** abrufen.

### Sicherheit
- ✅ TLS: STARTTLS + implizit TLS
- ✅ DKIM automatisch generiert
- ✅ SPF + DMARC konfiguriert
- ✅ Rate Limiting eingebaut
- ✅ IP-Blocking (Fail2Ban-ähnlich) eingebaut
- ✅ Nur authentifizierte User dürfen senden
- ✅ Admin-GUI VPN-only

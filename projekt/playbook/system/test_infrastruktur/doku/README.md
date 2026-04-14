# Infrastruktur Analyse Playbook — Dokumentation

## Übersicht

Dieses Playbook analysiert Linux-Clients vollständig und READ-ONLY.
**Es werden keinerlei Änderungen am System vorgenommen.**

---

## Ordnerstruktur

```
pb_test_infrastruktur.yml                  ← Hauptplaybook (nur includes)
playbook/system/test_infrastruktur/
├── app.yml                                ← Spezial-App-Liste
├── tasks/
│   ├── 01_system_info.yml                 ← Kernel, OS, Systeminfo
│   ├── 02_pakete.yml                      ← Alle Pakete, Updates
│   ├── 03_services.yml                    ← Services, Prozesse, Cronjobs
│   ├── 04_benutzer.yml                    ← User, Gruppen, SSH, Logins
│   ├── 05_netzwerk.yml                    ← Ports, Firewall, Verbindungen
│   ├── 06_ressourcen.yml                  ← CPU, RAM, Disk
│   ├── 07_logs.yml                        ← Logs, Login-Analyse
│   ├── 08_sicherheit.yml                  ← SIEM, auditd, Updates
│   ├── 09_container.yml                   ← Docker, Containerd
│   ├── 10_hardware.yml                    ← CPU-Info, RAID, Netzwerkadapter
│   ├── report.yml                         ← Report generieren
│   └── app_tests/
│       ├── test_runner.yml                ← Loop über alle Apps
│       ├── generisch.yml                  ← Fallback für alle Services
│       ├── nginx.yml                      ← nginx Spezialtest
│       ├── fail2ban.yml                   ← fail2ban Spezialtest
│       ├── modsecurity.yml                ← ModSecurity Spezialtest
│       ├── certbot.yml                    ← certbot Spezialtest
│       ├── nftables.yml                   ← nftables Spezialtest
│       ├── apparmor.yml                   ← AppArmor Spezialtest
│       └── auditd.yml                     ← auditd Spezialtest
├── templates/
│   └── report.md.j2                       ← Report-Template
└── doku/
    └── README.md                          ← Diese Datei
```

---

## Aufruf

```bash
# Alle Module
ansible-playbook pb_test_infrastruktur.yml

# Nur bestimmte Module
ansible-playbook pb_test_infrastruktur.yml --tags "netzwerk,services"

# Nur App-Tests
ansible-playbook pb_test_infrastruktur.yml --tags "apps"

# Nur Report neu generieren
ansible-playbook pb_test_infrastruktur.yml --tags "report"
```

---

## App-Prüfung erweitern

1. Neue App in `app.yml` eintragen
2. Neue Testdatei anlegen: `tasks/app_tests/<app-name>.yml`
3. Vorlage: `tasks/app_tests/generisch.yml` als Basis verwenden
4. Mindestens folgende Ebenen prüfen:
   - Ebene 1: Paket installiert?
   - Ebene 2: Service aktiv + enabled?
   - Ebene 3: Konfiguration valide?
   - Ebene 4: Tatsächliche Funktion?
   - Ebene 5: Logs unauffällig?
   - Ebene 6: Ressourcenverbrauch?

---

## Variablen-Struktur

Jedes Modul schreibt seine Ergebnisse in eine eigene Variable:

```yaml
<modul>_results:
  status: "OK | WARNUNG | FEHLER"
  zusammenfassung:
    ok: N
    warnungen: N
    fehler: N
  details:
    - name: "Prüfpunkt"
      status: "OK | WARNUNG | FEHLER"
      wert: "gefundener Wert"
      hinweis: "Empfehlung bei Problem"
```

---

## Report

Der Report wird automatisch am Ende jedes Durchlaufs erstellt:
- **Ablage:** `reports/analyse_<hostname>_<datum>.md` (auf dem Controller)
- **Format:** Markdown (lesbar, renderbar als HTML/PDF)
- **Inhalt:** Kurzübersicht → Fehler → Warnungen → Details je Modul → Empfehlungen

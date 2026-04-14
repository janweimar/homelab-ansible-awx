# 🔒 Wazuh Manager - Betriebsanleitung

**Playbook:** `pb_setup_wazuh_manager.yml`

---

## 🔧 AWX Credentials

| Credential                    | Typ                          | Pflicht |
|-------------------------------|------------------------------|---------|
| Machine Credential (SSH-Key)  | Machine                      | ✅      |
| `0000_global_smtp_admin_mail` | a_cred_typ_default_admin_smtp_mail | ✅ |
| `0000_global_doku_log`        | cred_typ_default_playbook_log_doku | ✅ |
| `0000_global_status_update`   | a_cred_typ_default_status_update | ✅  |
| `0200_wazuh_wazuh_install`    | a_cred_typ_pb_wazuh_install  | ✅      |

---

## 🛠️ BEFEHLE

**Dienst-Status prüfen:**

```bash
systemctl status wazuh-manager
systemctl status wazuh-indexer
systemctl status wazuh-dashboard
```

**Dienste neustarten:**

```bash
systemctl restart wazuh-manager
systemctl restart wazuh-indexer
systemctl restart wazuh-dashboard
```

**Logs ansehen:**

```bash
tail -f /var/ossec/logs/ossec.log
tail -f /var/log/wazuh-indexer/wazuh-indexer.log
```

**Config validieren (VOR Restart!):**

```bash
# Prueft ossec.conf auf Fehler ohne den Manager zu starten
sudo /var/ossec/bin/wazuh-analysisd -t

# Bei Fehler: Backup wiederherstellen
sudo cp /var/ossec/etc/ossec.conf.bak /var/ossec/etc/ossec.conf
sudo systemctl restart wazuh-manager
```

**Alle Agents anzeigen:**

```bash
/var/ossec/bin/manage_agents -l
```

**API testen:**

```bash
curl -k -X GET "https://localhost:55000/?pretty=true" \
  -H "Authorization: Bearer $(curl -u admin:admin -k -X GET \
  'https://localhost:55000/security/user/authenticate?raw=true')"
```

---

## 📋 Konfiguration

| Einstellung         | Wert                                    |
|---------------------|-----------------------------------------|
| Manager Config      | `/var/ossec/etc/ossec.conf`             |
| Indexer Config      | `/etc/wazuh-indexer/opensearch.yml`     |
| Dashboard Config    | `/etc/wazuh-dashboard/opensearch_dashboards.yml` |
| Agent-Schlüssel     | `/var/ossec/etc/client.keys`            |
| Logs                | `/var/ossec/logs/ossec.log`             |
| Port Agents         | 1514/tcp                                |
| Port Registrierung  | 1515/tcp                                |
| Port REST API       | 55000/tcp                               |
| Dashboard intern    | 443 (oder 5601 bei nginx)               |

---

## 🌐 nginx Reverse Proxy

Wenn `wazuh_nginx_integration: true`:

| Einstellung   | Wert                            |
|---------------|---------------------------------|
| Dashboard-URL | <https://wazuh>.<domain> .de |
| Port extern   | 443                             |
| Port intern   | 5601                            |
| SSL           | Let's Encrypt                   |

---

## 🔧 Troubleshooting / Fehlerbehebung

### dpkg kaputt (unterbrochene Installation)

Wenn `apt` oder `dpkg` Fehler melden weil eine frühere Installation unterbrochen wurde:

```bash
# dpkg reparieren - schließt unterbrochene Installationen ab
sudo dpkg --configure -a

# Fehlende Abhängigkeiten beheben
sudo apt-get install -f -y
```

### nginx blockiert dpkg

Wenn nginx kaputt installiert ist und dpkg blockiert:

```bash
# nginx und alle Module vollständig entfernen
sudo apt remove --purge nginx nginx-common libnginx-mod-http-ndk \
  libnginx-mod-http-modsecurity python3-certbot-nginx -y
sudo apt autoremove -y
sudo apt-get install -f -y

# Prüfen ob nginx weg ist (keine Ausgabe = sauber)
sudo dpkg -l | grep nginx
```

### Wazuh-Pakete lassen sich nicht entfernen

Wenn das pre-removal Script von wazuh-dashboard fehlschlägt:

```bash
# pre-removal Script entfernen (verhindert Fehler beim Entfernen)
sudo rm -f /var/lib/dpkg/info/wazuh-dashboard.prerm

# Pakete mit force entfernen
sudo dpkg --remove --force-all wazuh-dashboard
sudo dpkg --remove --force-all wazuh-indexer
sudo dpkg --remove --force-all wazuh-manager

# Konfig-Reste bereinigen (rc = removed but config remains)
sudo dpkg --purge wazuh-dashboard

# Abhängigkeiten reparieren
sudo apt-get install -f -y

# Prüfen ob alles weg ist (keine Ausgabe = sauber)
sudo dpkg -l | grep wazuh
```

### Wazuh meldet "already installed" obwohl platt gemacht

Wazuh-Pakete sind noch in dpkg registriert — obige Befehle ausführen um alles zu bereinigen.
Danach JT mit Modus `Erstinstallation` neu starten.

### Wazuh Installation schlägt fehl — Log prüfen

```bash
# Letzten Fehler im Installationslog ansehen
sudo tail -n 30 /var/log/wazuh-install.log
```

---

## ⚠️ Hinweise

* Alle Agents verbinden sich über VPN (Port 1514/1515)
* Dashboard läuft intern auf Port 5601 wenn nginx aktiv
* Wazuh APT-Repo wird nach Installation deaktiviert
* Wazuh-Indexer braucht mindestens 4 GB RAM
* Empfohlen: 8 GB RAM oder mehr

**Version:** 1.0

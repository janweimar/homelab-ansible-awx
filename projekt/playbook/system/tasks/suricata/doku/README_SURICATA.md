# Suricata IDS/IPS

## Übersicht

Suricata ist ein Open-Source IDS/IPS (Intrusion Detection/Prevention System).
Es analysiert Netzwerk-Traffic in Echtzeit und erkennt Bedrohungen anhand
von Signaturen (Rules) des Emerging Threats Rulesets.

## Modi

| Modus | Beschreibung | Capture |
|-------|-------------|---------|
| **IDS** | Erkennt Bedrohungen, blockiert nicht | af-packet (passiv) |
| **IPS** | Erkennt UND blockiert Bedrohungen | nfqueue (inline, nftables) |

## AWX Credential

| Feld | Beschreibung | Default |
|------|-------------|---------|
| `suricata_status` | aktiviert / deaktiviert / deinstallieren | aktiviert |
| `suricata_mode` | ids / ips | ids |
| `suricata_interface` | Netzwerk-Interface | eth0 |
| `suricata_home_net` | Geschütztes Netz (CIDR) | [10.200.0.0/24] |
| `suricata_rule_update` | Rules automatisch laden | true |

## Dateien

| Pfad | Beschreibung |
|------|-------------|
| `/etc/suricata/suricata.yaml` | Hauptkonfiguration |
| `/var/lib/suricata/rules/suricata.rules` | Aktive Regeln |
| `/var/log/suricata/eve.json` | JSON Event Log (für Wazuh/SIEM) |
| `/var/log/suricata/fast.log` | Schnelle Alert-Übersicht |
| `/var/log/suricata/stats.log` | Performance-Statistiken |

## Nützliche Befehle

```bash
# Status
systemctl status suricata

# Alerts live
tail -f /var/log/suricata/fast.log

# JSON Alerts filtern
cat /var/log/suricata/eve.json | jq 'select(.event_type=="alert")'

# Rules aktualisieren
suricata-update && systemctl restart suricata

# Regel-Quellen anzeigen
suricata-update list-sources

# Config testen
suricata -T -c /etc/suricata/suricata.yaml

# Interface-Statistiken
suricata --dump-config | grep interface
```

## Wazuh Integration

Suricata EVE JSON (`/var/log/suricata/eve.json`) kann von Wazuh gelesen werden.
In der Wazuh Agent Config `/var/ossec/etc/ossec.conf`:

```xml
<localfile>
  <log_format>json</log_format>
  <location>/var/log/suricata/eve.json</location>
</localfile>
```

## IPS-Modus: nftables Integration

Im IPS-Modus erstellt Suricata eine eigene nftables Tabelle:

```
table inet suricata {
  chain forward {
    type filter hook forward priority 10; policy accept;
    queue num 0
  }
}
```

Traffic wird über NFQUEUE an Suricata übergeben. Suricata entscheidet
ob der Traffic durchgelassen oder blockiert wird.

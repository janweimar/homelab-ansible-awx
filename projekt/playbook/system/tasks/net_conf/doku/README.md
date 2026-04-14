# Dokumentation für Netzwerk-Konfiguration

==================================================
📊 Netzwerk-Analyse & Monitoring – Kurzhilfe
==================================================

🔹 nload
Was ist es:
Konsolenbasiertes Tool zur Anzeige von Netzwerktraffic.

Was macht es:
Zeigt Upload- und Download-Daten in Echtzeit pro Netzwerkinterface.

Wichtige Befehle:
nload               -> Standardansicht
nload eth0          -> bestimmtes Interface
F2                  -> Optionen
q                   -> Beenden


🔹 iftop
Was ist es:
Interaktives Netzwerk-Monitoring ähnlich wie top.

Was macht es:
Zeigt, welche IPs und Verbindungen aktuell Bandbreite verbrauchen.

Wichtige Befehle:
iftop               -> Standardstart
iftop -i eth0       -> bestimmtes Interface
n / s / d           -> Sortierung ändern
q                   -> Beenden


🔹 nethogs
Was ist es:
Prozessbasierter Netzwerk-Monitor.

Was macht es:
Zeigt, welcher Prozess wie viel Netzwerktraffic erzeugt.

Wichtige Befehle:
nethogs             -> Standardstart
nethogs eth0        -> bestimmtes Interface
q                   -> Beenden


🔹 mtr
Was ist es:
Kombination aus ping und traceroute.

Was macht es:
Analysiert Netzwerkpfad und Paketverluste zu einem Zielhost.

Wichtige Befehle:
mtr google.com      -> Live-Analyse
mtr -r google.com   -> Report-Modus
q                   -> Beenden


🔹 tcpdump
Was ist es:
Low-Level Netzwerk-Paket-Sniffer.

Was macht es:
Schneidet und analysiert Netzwerkpakete direkt auf dem Interface.

Wichtige Befehle:
tcpdump -i eth0     -> Mitschnitt auf Interface
tcpdump port 80     -> Filter nach Port
tcpdump -c 100      -> Nur 100 Pakete


🔹 vnstat
Was ist es:
Netzwerk-Statistik-Tool mit Datenbank.

Was macht es:
Speichert und zeigt langfristige Traffic-Statistiken.

Wichtige Befehle:
vnstat              -> Übersicht
vnstat -d           -> Tagesstatistik
vnstat -m           -> Monatsstatistik
vnstat -l           -> Live-Ansicht

==================================================


#!/usr/bin/env python3
import sys
import re
import json


def extract_ip_candidates(in_ports: str, out_ports: str):
    """Sammelt alle potentiellen IP-Kandidaten aus in_ports/out_ports."""
    raw = f"{in_ports or ''},{out_ports or ''}"
    items = [x.strip() for x in raw.split(',') if x.strip()]
    cleaned = []

    for item in items:
        # Wir entfernen nur Port-/Proto-Teile, lassen aber mögliche Slashes stehen
        token = item.split(':')[0].strip()
        if token:
            cleaned.append(token)

    # Nur Elemente, die einen Punkt enthalten (IPv4-ähnlich)
    # -> behalten auch Slashes, um fehlerhafte IPs zu erkennen
    candidates = [x for x in cleaned if '.' in x]
    return candidates


def validate_ips(candidates):
    """Validiert IP-Adressen nach 3-Punkte-Struktur und Werte 0–255."""
    invalid_structure = []
    invalid_value = []

    ipv4_pattern = re.compile(
        r"^(25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])"
        r"(\.(25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])){3}$"
    )

    for ip in candidates:
        # Falsches Format: Slash am Ende, aber keine CIDR
        if ip.endswith('/') and not re.match(r".+/\d{1,2}$", ip):
            invalid_value.append(ip)
            continue

        # Wenn Slash mit CIDR → CIDR-Teil entfernen
        ip_base = ip.split('/')[0]

        dot_count = ip_base.count(".")
        if dot_count != 3:
            invalid_structure.append(ip)
            continue

        if not ipv4_pattern.match(ip_base):
            invalid_value.append(ip)

    invalid_ips = sorted(set(invalid_structure + invalid_value))
    return {
        "ip_candidates": candidates,
        "invalid_structure": invalid_structure,
        "invalid_value": invalid_value,
        "invalid_ips": invalid_ips,
    }


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(json.dumps({"error": "usage: validate_ips.py <in_ports> <out_ports>"}))
        sys.exit(1)

    in_ports = sys.argv[1]
    out_ports = sys.argv[2]

    result = validate_ips(extract_ip_candidates(in_ports, out_ports))
    print(json.dumps(result, indent=2))

    if result["invalid_ips"]:
        sys.exit(1)

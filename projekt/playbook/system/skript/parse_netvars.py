#!/usr/bin/env python3
import re
import json
import sys

def parse_entry(entry):
    """Parst einen einzelnen Netzwerkeintrag und gibt ein Wörterbuch mit 'ip', 'prt', 'proto' zurück."""
    entry = entry.strip()
    if not entry:
        return None

    result = {"ip": "", "prt": "", "proto": ""}

    parts = entry.split('/')
    ip_pattern = re.compile(r"^\d{1,3}(?:\.\d{1,3}){3}(?:/\d{1,2})?$")
    port_pattern = re.compile(r"^\d+$")
    proto_pattern = re.compile(r"^[a-zA-Z]+$")

    if len(parts) == 3:
        if ip_pattern.match(parts[0]):
            result["ip"] = parts[0]
        if port_pattern.match(parts[1]):
            result["prt"] = parts[1]
        if proto_pattern.match(parts[2]):
            result["proto"] = parts[2].lower()

    elif len(parts) == 2:
        if ip_pattern.match(parts[0]) and port_pattern.match(parts[1]):
            result["ip"] = parts[0]
            result["prt"] = parts[1]
        elif port_pattern.match(parts[0]) and proto_pattern.match(parts[1]):
            result["prt"] = parts[0]
            result["proto"] = parts[1].lower()
        elif ip_pattern.match(parts[0]) and proto_pattern.match(parts[1]):
            result["ip"] = parts[0]
            result["proto"] = parts[1].lower()

    elif len(parts) == 1:
        part = parts[0]
        if ip_pattern.match(part):
            result["ip"] = part
        elif port_pattern.match(part):
            result["prt"] = part
        elif proto_pattern.match(part):
            result["proto"] = part.lower()

    return result

def parse_entries(input_string):
    """Parst einen durch Kommas getrennten String von Netzwerkeinträgen."""
    if not input_string:
        return []
    entries = [e.strip() for e in input_string.split(',')]
    return [p for e in entries if (p := parse_entry(e))]

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("[]")
        sys.exit(0)
    parsed = parse_entries(sys.argv[1])
    print(json.dumps(parsed))

#!/bin/bash
# WireGuard Keys generieren - alle Teilnehmer
# Ausführen auf WSL: bash generate_wg_keys.sh

PARTICIPANTS=("vpn_server" "wazuh_manager" "mail_server" "repo_jump_server" "ai_server" "odoo_server" "awx_server")

echo "============================================"
echo "WireGuard Keys - $(date)"
echo "============================================"
echo ""

for name in "${PARTICIPANTS[@]}"; do
    PRIVKEY=$(wg genkey)
    PUBKEY=$(echo "$PRIVKEY" | wg pubkey)
    echo "--- $name ---"
    echo "Private Key: $PRIVKEY"
    echo "Public Key:  $PUBKEY"
    echo ""
done

echo "============================================"
echo "Private Keys → AWX Credentials (verschlüsselt)"
echo "Public Keys  → vpn.yml"
echo "============================================"


# sudo apt install wireguard-tools -y
# bash /mnt/f/OneDrive/Projekt/__git/ansible/projekt/playbook/system/skript/generate_wg_keys.sh
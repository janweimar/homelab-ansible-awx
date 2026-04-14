#!/usr/bin/env bash

# ============================================================
# Kubernetes Diagnose Script
# Zweck: Vollständige, audit-freundliche Prüfung eines Single-Node-Clusters
# ============================================================

set -euo pipefail

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
export KUBECONFIG=/etc/kubernetes/admin.conf
DNS_FQDN="kubernetes.default.svc.cluster.local"
TEST_POD="dns-test"
BUSYBOX_IMG="busybox:1.36"

echo "============================================================"
echo "Kubernetes Diagnose – Start"
echo "============================================================"

# ------------------------------------------------------------
# Funktion: Node Status
# ------------------------------------------------------------
check_nodes() {
    echo
    echo "------------------------------------------------------------"
    echo "1) Node-Status"
    echo "------------------------------------------------------------"
    kubectl get nodes -o wide
}

# ------------------------------------------------------------
# Funktion: kube-proxy Status
# ------------------------------------------------------------
check_kube_proxy() {
    echo
    echo "------------------------------------------------------------"
    echo "2) kube-proxy Pods"
    echo "------------------------------------------------------------"
    kubectl -n kube-system get pods -l k8s-app=kube-proxy -o wide
}

# ------------------------------------------------------------
# Funktion: CoreDNS Status
# ------------------------------------------------------------
check_coredns() {
    echo
    echo "------------------------------------------------------------"
    echo "3) CoreDNS Pods"
    echo "------------------------------------------------------------"
    kubectl -n kube-system get pods -l k8s-app=kube-dns -o wide
}

# ------------------------------------------------------------
# Funktion: iptables / nftables (NAT & Forward)
# ------------------------------------------------------------
check_iptables() {
    echo
    echo "------------------------------------------------------------"
    echo "4) iptables / nftables"
    echo "------------------------------------------------------------"

    echo "- iptables Backend:"
    iptables -V || true

    echo
    echo "- KUBE-SERVICES (iptables nat):"
    sudo iptables -t nat -L KUBE-SERVICES || echo "KUBE-SERVICES nicht gefunden (iptables)"

    echo
    echo "- nftables NAT (Auszug):"
    sudo nft list table ip nat | sed -n '1,200p' || true

    echo
    echo "- FORWARD Chain (fire_tab.for_chain):"
    sudo nft list chain inet fire_tab for_chain || echo "for_chain nicht gefunden"
}

# ------------------------------------------------------------
# Funktion: Node Taints
# ------------------------------------------------------------
check_taints() {
    echo
    echo "------------------------------------------------------------"
    echo "5) Node Taints"
    echo "------------------------------------------------------------"
    kubectl describe node | sed -n '/Taints:/,/Conditions:/p' || echo "Keine Taints gefunden"
}

# ------------------------------------------------------------
# Funktion: Kernel Forwarding
# ------------------------------------------------------------
check_forwarding() {
    echo
    echo "------------------------------------------------------------"
    echo "6) Kernel Forwarding"
    echo "------------------------------------------------------------"
    sysctl net.ipv4.ip_forward
}

# ------------------------------------------------------------
# Funktion: DNS Test Pod
# ------------------------------------------------------------
check_dns() {
    echo
    echo "------------------------------------------------------------"
    echo "7) DNS Test"
    echo "------------------------------------------------------------"

    # alten Pod entfernen, falls vorhanden
    kubectl delete pod "${TEST_POD}" --ignore-not-found=true >/dev/null 2>&1 || true

    # neuen Test-Pod starten
    kubectl run "${TEST_POD}" \
        --image="${BUSYBOX_IMG}" \
        --restart=Never \
        --command -- nslookup "${DNS_FQDN}"

    echo "Warte auf Pod-Completion..."
    kubectl wait --for=condition=Complete "pod/${TEST_POD}" --timeout=60s

    echo
    echo "Pod-Status:"
    kubectl get pod "${TEST_POD}" -o wide

    echo
    echo "DNS-Test Logs:"
    kubectl logs "${TEST_POD}"

    # Cleanup
    kubectl delete pod "${TEST_POD}" --ignore-not-found=true >/dev/null 2>&1 || true
}

# ------------------------------------------------------------
# Ausführung
# ------------------------------------------------------------
check_nodes
check_kube_proxy
check_coredns
check_iptables
check_taints
check_forwarding
check_dns

echo
echo "============================================================"
echo "Diagnose abgeschlossen"
echo "============================================================"

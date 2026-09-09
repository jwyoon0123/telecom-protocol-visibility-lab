#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"
. "$REPO/tools/load-env.sh"

HOME_UE_GATEWAY_CIDR="${HOME_UE_GATEWAY_CIDR:-${HOME_UE_GATEWAY}/16}"

[ "$(id -u)" -eq 0 ] || { echo "[ERROR] root required"; exit 1; }

if ! ip link show ogstun >/dev/null 2>&1; then
    ip tuntap add name ogstun mode tun
fi

ip addr flush dev ogstun
ip addr add "$HOME_UE_GATEWAY_CIDR" dev ogstun
ip link set ogstun up

sysctl -w net.ipv4.ip_forward=1
cat >/etc/sysctl.d/99-virtual-mobile-telecom-lab.conf <<'EOF'
net.ipv4.ip_forward=1
EOF

echo "===== OGSTUN ====="
ip -br addr show ogstun
echo "===== FORWARD ====="
sysctl net.ipv4.ip_forward

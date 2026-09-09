#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"; . "$REPO/tools/load-env.sh"
echo "=========================================="
echo " HOME 5G CAPTURE - $HOME_IP"
echo " RAN/UE          - $RAN_IP"
echo "=========================================="
pgrep -af 'open5gs-(amfd|smfd|upfd)' || true
ss -lnp -A sctp 2>/dev/null | grep "$NGAP_PORT" || true
ss -lunp | grep -E ":($PFCP_PORT|$GTPU_PORT)\\b" || true
ip -br addr show dev ogstun 2>/dev/null || true
exec tcpdump -ni "$CAPTURE_IF" -s0 -nn -vv \
  "host $RAN_IP and (sctp port $NGAP_PORT or udp port $GTPU_PORT)"

#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"; . "$REPO/tools/load-env.sh"
echo "=========================================="
echo " HOME LTE CAPTURE - $HOME_IP"
echo " RAN/UE           - $RAN_IP"
echo "=========================================="
pgrep -af 'open5gs-(mmed|sgwcd|sgwud|hssd)' || true
ss -lnp -A sctp 2>/dev/null | grep "$LTE_S1AP_PORT" || true
ss -lunp | grep ":$GTPU_PORT" || true
exec tcpdump -ni "$CAPTURE_IF" -s0 -nn -vv \
  "host $RAN_IP and (sctp port $LTE_S1AP_PORT or udp port $GTPU_PORT)"

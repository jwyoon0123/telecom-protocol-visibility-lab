#!/usr/bin/env bash
set -Eeuo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; . "$REPO/tools/load-env.sh"
for c in ip ss tcpdump python3; do command -v "$c" >/dev/null || { echo "[MISS] $c"; exit 1; }; done
modprobe sctp 2>/dev/null || true
grep -q '^sctp ' /proc/modules && echo '[OK] SCTP module' || echo '[WARN] SCTP kernel module is not visible'
echo '===== IP ====='; ip -4 -br addr
echo '===== ROUTES ====='; ip route
echo '===== SCTP ====='; ss -lnp -A sctp 2>/dev/null || true
echo '===== UDP ====='; ss -lunp | grep -E ":($GTPU_PORT|$PFCP_PORT)\\b" || true
echo '===== TCP ====='; ss -lntp | grep -E ":($DIAMETER_PORT|$N32_PORT|$N32F_PORT)\\b" || true

#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"
. "$REPO/tools/load-env.sh"

BASE="${SS7SIM_BASE:-/opt/telecom-lab/ss7simulator}"
PCAPDIR="${TELECOM_PCAP:-/opt/telecom-lab/pcap}"
mkdir -p "$PCAPDIR"
PCAP="$PCAPDIR/final-map-$(date +%Y%m%d-%H%M%S).pcap"

[ -x "$BASE/.venv/bin/python" ] || { echo "[ERROR] ss7simulator venv missing: $BASE/.venv"; exit 1; }
command -v tcpdump >/dev/null || { echo "[ERROR] tcpdump missing"; exit 1; }

cleanup() {
  if [ -n "${CAP_PID:-}" ]; then
    kill "$CAP_PID" 2>/dev/null || true
    wait "$CAP_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

echo "===== START CAPTURE ====="
echo "peer=$PARTNER_IP port=$SS7_PORT pcap=$PCAP"
tcpdump -ni "$CAPTURE_IF" -s0 -w "$PCAP" \
  "sctp and host $PARTNER_IP and port $SS7_PORT" \
  >/tmp/vmtl-final-map-tcpdump.log 2>&1 &
CAP_PID=$!
sleep 1

echo "===== SEND MAP ====="
set +e
"$BASE/.venv/bin/python" "$SCRIPT_DIR/78-send-map.py"
RC=$?
set -e
sleep 2
cleanup
CAP_PID=""

echo "===== RESULT ====="
echo "RC=$RC"
ls -lh "$PCAP"

echo "===== M3UA ====="
tcpdump -nn -vv -r "$PCAP" 2>/dev/null | \
  grep -E 'PPID M3UA|Payload Data|ASP Up|ASP Active|ABORT|SHUTDOWN' || true

if command -v tshark >/dev/null; then
  echo "===== TSHARK PROTOCOLS ====="
  tshark -r "$PCAP" \
    -d sctp.ppi==3,m3ua \
    -Y 'm3ua || sccp || tcap || gsm_map' \
    -T fields \
    -e frame.number -e _ws.col.Protocol -e _ws.col.Info \
    2>/dev/null || true
fi

echo "PCAP=$PCAP"
exit "$RC"

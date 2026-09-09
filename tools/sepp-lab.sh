#!/usr/bin/env bash
set -Eeuo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$REPO/tools/load-env.sh"
ROLE="${1:-}"; MODE="${2:-status}"
case "$ROLE" in home) LOCAL_IP="$HOME_IP"; PEER_IP="$PARTNER_IP";; partner) LOCAL_IP="$PARTNER_IP"; PEER_IP="$HOME_IP";; *) echo "Usage: $0 {home|partner} {start|stop|status|check|capture}"; exit 2;; esac
CFG="/etc/open5gs/sepp-lab.yaml"
PIDFILE="/run/vmtl-sepp-${ROLE}.pid"
LOG="/var/log/open5gs/sepp-lab-${ROLE}.console.log"
BIN="$(command -v open5gs-seppd || true)"; [ -n "$BIN" ] || BIN=/usr/local/bin/open5gs-seppd
case "$MODE" in
 start)
   [ -x "$BIN" ] || { echo "[ERROR] open5gs-seppd not found"; exit 1; }
   [ -f "$CFG" ] || { echo "[ERROR] $CFG missing; render/deploy configs first"; exit 1; }
   if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then echo "[OK] already running"; exit 0; fi
   nohup "$BIN" -c "$CFG" >"$LOG" 2>&1 & echo $! >"$PIDFILE"; sleep 3
   kill -0 "$(cat "$PIDFILE")" 2>/dev/null || { tail -100 "$LOG"; exit 1; }
   "$0" "$ROLE" status
   ;;
 stop)
   if [ -f "$PIDFILE" ]; then kill -TERM "$(cat "$PIDFILE")" 2>/dev/null || true; rm -f "$PIDFILE"; fi
   ;;
 status)
   echo "role=$ROLE local=$LOCAL_IP peer=$PEER_IP"
   [ -f "$PIDFILE" ] && ps -fp "$(cat "$PIDFILE")" 2>/dev/null || true
   ss -lntp | grep -E "${LOCAL_IP//./\\.}:(${N32_PORT}|${N32F_PORT})" || true
   ;;
 check)
   for p in "$N32_PORT" "$N32F_PORT"; do
     if timeout 3 bash -c "</dev/tcp/$PEER_IP/$p" 2>/dev/null; then echo "[OK] $PEER_IP:$p reachable"; else echo "[FAIL] $PEER_IP:$p unreachable"; fi
   done
   ;;
 capture)
   exec tcpdump -ni "$CAPTURE_IF" -s0 -nn -vv "host $PEER_IP and (tcp port $N32_PORT or tcp port $N32F_PORT)"
   ;;
 *) echo "Usage: $0 {home|partner} {start|stop|status|check|capture}"; exit 2;;
esac

#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"
. "$REPO/tools/load-env.sh"
TEST="$SCRIPT_DIR/500-partner-pdu-test.sh"
MODE="${1:-start}"
zmq_regex=":(${NR_ZMQ_GNB_TX_PORT}|${NR_ZMQ_UE_TX_PORT})([[:space:]]|$)"

status(){
  echo '=========================================='
  echo ' PARTNER 5G STATUS'
  echo '=========================================='
  pgrep -af 'gnb|srsue|srsenb' || true
  echo '===== ZMQ ====='; ss -lntp | grep -E "$zmq_regex" || true
  echo '===== N2 ====='; ss -anp -A sctp 2>/dev/null | grep "$NGAP_PORT" || true
  echo '===== UE ====='
  if ip netns list | grep -q "^${PARTNER_UE_NETNS}\\b"; then
    ip netns exec "$PARTNER_UE_NETNS" ip -br addr || true
    ip netns exec "$PARTNER_UE_NETNS" ip route || true
  fi
}
stop_all(){
  pkill -TERM -x srsue 2>/dev/null || true
  pkill -TERM -x gnb 2>/dev/null || true
  pkill -TERM -x srsenb 2>/dev/null || true
  sleep 3
  ss -lntp | grep -E "$zmq_regex" || true
}

case "$MODE" in
  start|restart)
    stop_all
    if ss -lntp | grep -E "$zmq_regex" >/dev/null; then echo '[FATAL] 5G ZMQ ports still in use'; exit 1; fi
    "$TEST"
    ;;
  status) status ;;
  ping)
    ip netns list | grep -q "^${PARTNER_UE_NETNS}\\b" || { echo "[FATAL] $PARTNER_UE_NETNS namespace missing"; exit 1; }
    ip netns exec "$PARTNER_UE_NETNS" ping -c 20 -i 0.2 "$PARTNER_UE_GATEWAY"
    ;;
  stop) stop_all ;;
  *) echo "Usage: $0 {start|restart|status|ping|stop}"; exit 2 ;;
esac

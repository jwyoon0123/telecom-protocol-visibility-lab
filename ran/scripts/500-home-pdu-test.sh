#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"
. "$REPO/tools/load-env.sh"

RUNTIME="${TELECOM_RUNTIME:-/opt/telecom-lab/runtime}/5g"
GNB="$(command -v gnb || true)"
SRSUE="$(command -v srsue || true)"
GNBCFG="$RUNTIME/gnb-home.yml"
UECFG="$RUNTIME/ue.conf"
GNBLOG="/var/log/gnb-home.log"
GNBCON="/var/log/gnb-home-console.log"
UELOG="/var/log/srsue-home.log"
UECON="/var/log/srsue-home-console.log"
MODE="${1:-start}"
zmq_regex=":(${NR_ZMQ_GNB_TX_PORT}|${NR_ZMQ_UE_TX_PORT})([[:space:]]|$)"

need_root(){ [ "$(id -u)" -eq 0 ] || { echo '[FATAL] root required'; exit 1; }; }
stop_all(){
  pkill -TERM -x srsue 2>/dev/null || true
  pkill -TERM -x gnb 2>/dev/null || true
  pkill -TERM -x srsenb 2>/dev/null || true
  sleep 3
  if ss -lntp | grep -E "$zmq_regex" >/dev/null; then
    echo '[ERROR] 5G ZMQ ports still in use'; ss -lntp | grep -E "$zmq_regex" || true; return 1
  fi
}
status(){
  echo '=========================================='
  echo ' HOME 5G STATUS'
  echo '=========================================='
  pgrep -af 'gnb|srsue|srsenb' || true
  echo '===== ZMQ ====='; ss -lntp | grep -E "$zmq_regex" || true
  echo '===== N2 ====='; ss -anp -A sctp 2>/dev/null | grep "$NGAP_PORT" || true
  echo '===== UE ====='
  if ip netns list | grep -q "^${HOME_UE_NETNS}\\b"; then
    ip netns exec "$HOME_UE_NETNS" ip -br addr || true
    ip netns exec "$HOME_UE_NETNS" ip route || true
  fi
}

case "$MODE" in
  stop) need_root; stop_all || true; exit 0 ;;
  status) status; exit 0 ;;
  ping) need_root; ip netns exec "$HOME_UE_NETNS" ping -c 20 -i 0.2 "$HOME_UE_GATEWAY"; exit $? ;;
  start|restart) ;;
  *) echo "Usage: $0 {start|restart|status|ping|stop}"; exit 2 ;;
esac

need_root
[ -x "$GNB" ] || { echo '[FATAL] gnb not found'; exit 1; }
[ -x "$SRSUE" ] || { echo '[FATAL] srsue not found'; exit 1; }
[ -f "$GNBCFG" ] || { echo "[FATAL] missing $GNBCFG"; exit 1; }
[ -f "$UECFG" ] || { echo "[FATAL] missing $UECFG; render private UE config first"; exit 1; }

cat <<EOF
==========================================
 HOME 5G SA / PDU TEST
==========================================
AMF : $HOME_IP:$NGAP_PORT
RAN : $RAN_IP
PLMN: $HOME_PLMN / TAC $HOME_TAC
UE  : expected $HOME_UE_EXPECTED_IP, gateway $HOME_UE_GATEWAY
EOF

stop_all
ip netns del "$HOME_UE_NETNS" 2>/dev/null || true
ip netns add "$HOME_UE_NETNS"
ip netns exec "$HOME_UE_NETNS" ip link set lo up

"$GNB" -c "$GNBCFG" --dryrun
rm -f "$GNBLOG" "$GNBCON" "$UELOG" "$UECON"
nohup "$GNB" -c "$GNBCFG" >"$GNBCON" 2>&1 &
GNBPID=$!

N2_OK=0
for _ in $(seq 1 30); do
  if ss -anp -A sctp 2>/dev/null | grep -F "$HOME_IP:$NGAP_PORT" >/dev/null; then N2_OK=1; break; fi
  if grep -F "Connection to AMF on ${HOME_IP}:${NGAP_PORT} completed" "$GNBLOG" "$GNBCON" 2>/dev/null | grep -q .; then N2_OK=1; break; fi
  kill -0 "$GNBPID" 2>/dev/null || break
  sleep 1
done
[ "$N2_OK" -eq 1 ] || { echo '[FATAL] N2 connection failed'; tail -120 "$GNBLOG" "$GNBCON" 2>/dev/null || true; exit 1; }
echo '[OK] N2 connected'

if ss -lntp | grep -E ":${NR_ZMQ_UE_TX_PORT}([[:space:]]|$)" >/dev/null; then
  echo "[FATAL] UE ZMQ TX port $NR_ZMQ_UE_TX_PORT already in use"; exit 1
fi

nohup bash -c 'tail -f /dev/null | "$@"' _ "$SRSUE" "$UECFG" >"$UECON" 2>&1 &
sleep 2
UEPID="$(pgrep -n -x srsue || true)"
[ -n "$UEPID" ] || { echo '[FATAL] srsUE failed to start'; tail -120 "$UECON"; exit 1; }

PDU_OK=0
for _ in $(seq 1 90); do
  if grep -q 'PDU Session Establishment successful' "$UELOG" "$UECON" 2>/dev/null; then PDU_OK=1; break; fi
  if grep -Eqi 'Address already in use|Error initializing radio' "$UELOG" "$UECON" 2>/dev/null; then
    echo '[FATAL] UE/ZMQ startup error'; tail -120 "$UELOG" "$UECON" 2>/dev/null || true; exit 1
  fi
  kill -0 "$UEPID" 2>/dev/null || break
  sleep 1
done
[ "$PDU_OK" -eq 1 ] || { echo '[FATAL] PDU Session not established'; tail -120 "$UELOG" "$UECON" 2>/dev/null || true; exit 1; }

grep -E 'Random Access Complete|RRC Connected|PDU Session Establishment successful|RRC NR reconfiguration successful' "$UELOG" "$UECON" 2>/dev/null || true
ip netns exec "$HOME_UE_NETNS" ip -br addr
ip netns exec "$HOME_UE_NETNS" ip route || true
ip netns exec "$HOME_UE_NETNS" ping -c 10 -i 0.2 "$HOME_UE_GATEWAY"

cat <<EOF
==========================================
 HOME 5G SA = DONE
==========================================
UE       = $HOME_UE_EXPECTED_IP
Gateway  = $HOME_UE_GATEWAY
N2       = SCTP/$NGAP_PORT
N3       = UDP/$GTPU_PORT
EOF

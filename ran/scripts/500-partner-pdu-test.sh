#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"
. "$REPO/tools/load-env.sh"

RUNTIME="${TELECOM_RUNTIME:-/opt/telecom-lab/runtime}/5g"
GNB="$(command -v gnb || true)"
SRSUE="$(command -v srsue || true)"
GNBCFG="$RUNTIME/gnb-partner.yml"
UECFG="$RUNTIME/ue-partner-final.conf"
GNBLOG="/var/log/gnb-partner.log"
GNBCON="/var/log/gnb-partner-console.log"
UELOG="/var/log/srsue-partner.log"
UECON="/var/log/srsue-partner-console.log"
zmq_regex=":(${NR_ZMQ_GNB_TX_PORT}|${NR_ZMQ_UE_TX_PORT})([[:space:]]|$)"

[ "$(id -u)" -eq 0 ] || { echo '[FATAL] root required'; exit 1; }
[ -x "$GNB" ] || { echo '[FATAL] gnb not found'; exit 1; }
[ -x "$SRSUE" ] || { echo '[FATAL] srsue not found'; exit 1; }
[ -f "$GNBCFG" ] || { echo "[FATAL] missing $GNBCFG"; exit 1; }
[ -f "$UECFG" ] || { echo "[FATAL] missing $UECFG; render private UE config first"; exit 1; }

cat <<EOF
================================================
 PARTNER 5G SA / PDU TEST
================================================
AMF : $PARTNER_IP:$NGAP_PORT
RAN : $RAN_IP
PLMN: $PARTNER_PLMN / TAC $PARTNER_TAC
UE  : expected $PARTNER_UE_EXPECTED_IP, gateway $PARTNER_UE_GATEWAY
EOF

pkill -TERM -x srsue 2>/dev/null || true
pkill -TERM -x gnb 2>/dev/null || true
pkill -TERM -x srsenb 2>/dev/null || true
sleep 3
if ss -lntp | grep -E "$zmq_regex" >/dev/null; then
  echo '[FATAL] 5G ZMQ ports still in use'; ss -lntp | grep -E "$zmq_regex" || true; exit 1
fi

ip netns del "$PARTNER_UE_NETNS" 2>/dev/null || true
ip netns add "$PARTNER_UE_NETNS"
ip netns exec "$PARTNER_UE_NETNS" ip link set lo up

"$GNB" -c "$GNBCFG" --dryrun
rm -f "$GNBLOG" "$GNBCON" "$UELOG" "$UECON"
nohup "$GNB" -c "$GNBCFG" >"$GNBCON" 2>&1 &
GNBPID=$!

N2_OK=0
for _ in $(seq 1 30); do
  if ss -anp -A sctp 2>/dev/null | grep -F "$PARTNER_IP:$NGAP_PORT" >/dev/null; then N2_OK=1; break; fi
  if grep -F "Connection to AMF on ${PARTNER_IP}:${NGAP_PORT} completed" "$GNBLOG" "$GNBCON" 2>/dev/null | grep -q .; then N2_OK=1; break; fi
  kill -0 "$GNBPID" 2>/dev/null || break
  sleep 1
done
[ "$N2_OK" -eq 1 ] || { echo '[FATAL] Partner N2 failed'; tail -120 "$GNBLOG" "$GNBCON" 2>/dev/null || true; exit 10; }
echo '[OK] Partner N2 connected'

nohup bash -c 'tail -f /dev/null | "$@"' _ "$SRSUE" "$UECFG" >"$UECON" 2>&1 &
sleep 2
UEPID="$(pgrep -n -x srsue || true)"
[ -n "$UEPID" ] || { echo '[FATAL] Partner UE failed to start'; tail -120 "$UECON"; exit 1; }

PDU_OK=0
for _ in $(seq 1 90); do
  if grep -q 'PDU Session Establishment successful' "$UELOG" "$UECON" 2>/dev/null; then PDU_OK=1; break; fi
  kill -0 "$UEPID" 2>/dev/null || break
  sleep 1
done
[ "$PDU_OK" -eq 1 ] || { echo '[FATAL] Partner PDU Session failed'; tail -120 "$UELOG" "$UECON" 2>/dev/null || true; exit 20; }

grep -E 'Random Access|RRC Connected|PDU Session|reconfiguration' "$UELOG" "$UECON" 2>/dev/null || true
ip netns exec "$PARTNER_UE_NETNS" ip -br addr
ip netns exec "$PARTNER_UE_NETNS" ip route || true
ip netns exec "$PARTNER_UE_NETNS" ping -c 10 -i 0.2 "$PARTNER_UE_GATEWAY"

echo '===================================='
echo ' PARTNER 5G SA = DONE'
echo '===================================='

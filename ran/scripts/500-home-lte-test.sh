#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"
. "$REPO/tools/load-env.sh"

RUNDIR="${TELECOM_RUNTIME:-/opt/telecom-lab/runtime}/lte"
ENB="$RUNDIR/enb.conf"
UE="$RUNDIR/ue.conf"
RR="$RUNDIR/rr.conf"
SIB="$RUNDIR/sib.conf"
RB="$RUNDIR/rb.conf"
ENBBIN="$(command -v srsenb || true)"
UEBIN="$(command -v srsue || true)"
ENBLOG="/var/log/srsenb-home-lte.log"
ENBCON="/var/log/srsenb-home-lte-console.log"
UELOG="/var/log/srsue-home-lte.log"
UECON="/var/log/srsue-home-lte-console.log"
MODE="${1:-start}"

zmq_regex=":(${LTE_ZMQ_ENB_TX_PORT}|${LTE_ZMQ_UE_TX_PORT}|${NR_ZMQ_GNB_TX_PORT}|${NR_ZMQ_UE_TX_PORT})([[:space:]]|$)"

need_root(){ [ "$(id -u)" -eq 0 ] || { echo '[FATAL] root required'; exit 1; }; }

stop_ran(){
  echo '[STOP] existing LTE/5G RAN'
  pkill -TERM -x srsue 2>/dev/null || true
  pkill -TERM -x srsenb 2>/dev/null || true
  pkill -TERM -x gnb 2>/dev/null || true
  sleep 3
  if ss -lntp | grep -E "$zmq_regex" >/dev/null; then
    echo '[WARN] software-RF TCP ports still in use'
    ss -lntp | grep -E "$zmq_regex" || true
  fi
}

find_example(){
  local name="$1" f
  for f in "/root/.config/srsran/$name" "/usr/local/share/srsran/$name.example" "/usr/share/srsran/$name.example"; do
    [ -f "$f" ] && { printf '%s\n' "$f"; return 0; }
  done
  f="$(find /usr/local/share/srsran /usr/share/srsran -type f -name "$name" -print -quit 2>/dev/null || true)"
  [ -n "$f" ] && { printf '%s\n' "$f"; return 0; }
  return 1
}

prepare_support_files(){
  mkdir -p "$RUNDIR"
  local target src
  for target in "$RR" "$SIB" "$RB"; do
    if [ ! -f "$target" ]; then
      src="$(find_example "$(basename "$target")")" || { echo "[FATAL] upstream support file missing: $(basename "$target")"; exit 1; }
      cp -a "$src" "$target"
      echo "[COPY] $src -> $target"
    fi
  done

  # Keep the LTE RRC TAC aligned with lab.env. Preserve the prior runtime copy.
  if grep -Eq '^[[:space:]]*tac[[:space:]]*=' "$RR"; then
    cp -a "$RR" "${RR}.pre-vmtl-$(date +%Y%m%d-%H%M%S)"
    local tac_hex
    printf -v tac_hex '0x%04x' "$HOME_TAC"
    sed -i -E "s/^[[:space:]]*tac[[:space:]]*=.*/  tac = ${tac_hex};/" "$RR"
  fi
}

status(){
  echo '=========================================='
  echo ' HOME LTE STATUS'
  echo '=========================================='
  pgrep -af 'srsenb|srsue|/usr/local/bin/gnb' || true
  echo '===== ZMQ ====='; ss -lntp | grep -E "$zmq_regex" || true
  echo '===== S1AP ====='; ss -anp -A sctp 2>/dev/null | grep "$LTE_S1AP_PORT" || true
  echo '===== UE ====='
  if ip netns list | grep -q "^${HOME_UE_NETNS}\\b"; then
    ip netns exec "$HOME_UE_NETNS" ip -br addr || true
    ip netns exec "$HOME_UE_NETNS" ip route || true
  else
    echo "$HOME_UE_NETNS namespace not present"
  fi
}

case "$MODE" in
  stop) need_root; stop_ran; exit 0 ;;
  status) status; exit 0 ;;
  ping) need_root; ip netns exec "$HOME_UE_NETNS" ping -c 20 -i 0.2 "$HOME_UE_GATEWAY"; exit $? ;;
  start|restart) ;;
  *) echo "Usage: $0 {start|restart|status|ping|stop}"; exit 2 ;;
esac

need_root
[ -n "$ENBBIN" ] || { echo '[FATAL] srsenb not found'; exit 1; }
[ -n "$UEBIN" ] || { echo '[FATAL] srsue not found'; exit 1; }
[ -f "$ENB" ] || { echo "[FATAL] missing $ENB; deploy RAN configs first"; exit 1; }
[ -f "$UE" ] || { echo "[FATAL] missing $UE; render with config/secrets.env and deploy RAN configs first"; exit 1; }

cat <<EOF
==========================================
 HOME 4G/LTE ATTACH TEST
==========================================
MME : $HOME_IP:$LTE_S1AP_PORT
RAN : $RAN_IP
PLMN: $HOME_PLMN / TAC $HOME_TAC
UE  : expected $HOME_UE_EXPECTED_IP, gateway $HOME_UE_GATEWAY
EOF

stop_ran
if ss -lntp | grep -E "$zmq_regex" >/dev/null; then
  echo '[FATAL] software-RF port still in use'
  ss -lntp | grep -E "$zmq_regex" || true
  exit 1
fi
prepare_support_files

ip netns del "$HOME_UE_NETNS" 2>/dev/null || true
ip netns add "$HOME_UE_NETNS"
ip netns exec "$HOME_UE_NETNS" ip link set lo up

rm -f "$ENBLOG" "$ENBCON" "$UELOG" "$UECON"
cd "$RUNDIR"
nohup "$ENBBIN" "$ENB" >"$ENBCON" 2>&1 &
ENBPID=$!
sleep 4
kill -0 "$ENBPID" 2>/dev/null || { echo '[FATAL] srsENB exited'; tail -100 "$ENBCON"; exit 1; }
echo "[OK] srsENB PID=$ENBPID"

S1_OK=0
for _ in $(seq 1 30); do
  if ss -anp -A sctp 2>/dev/null | grep -F "$HOME_IP:$LTE_S1AP_PORT" >/dev/null; then S1_OK=1; break; fi
  if grep -Eqi 'S1.*setup.*success|S1Setup.*success|MME.*connected' "$ENBLOG" "$ENBCON" 2>/dev/null; then S1_OK=1; break; fi
  kill -0 "$ENBPID" 2>/dev/null || break
  sleep 1
done
[ "$S1_OK" -eq 1 ] || { echo '[FATAL] S1AP connection failed'; tail -120 "$ENBLOG" "$ENBCON" 2>/dev/null || true; exit 1; }
echo '[OK] S1AP connected'

# Keep stdin open without exposing K/OPc in the process command line: UE reads them
# from the rendered private ue.conf.
nohup bash -c 'tail -f /dev/null | "$@"' _ "$UEBIN" "$UE" >"$UECON" 2>&1 &
sleep 3
pgrep -x srsue >/dev/null || { echo '[FATAL] srsUE exited'; tail -120 "$UECON"; exit 1; }

UE_OK=0
for _ in $(seq 1 90); do
  if ip netns exec "$HOME_UE_NETNS" ip -4 -br addr 2>/dev/null | grep -q 'tun_srsue'; then UE_OK=1; break; fi
  if grep -Eqi 'attach.*fail|authentication.*fail|error initializing radio|address already in use' "$UELOG" "$UECON" 2>/dev/null; then
    echo '[FATAL] LTE UE attach/radio error'; tail -120 "$UELOG" "$UECON" 2>/dev/null || true; exit 1
  fi
  sleep 1
done
[ "$UE_OK" -eq 1 ] || { echo '[FATAL] LTE UE IP not assigned'; tail -120 "$UELOG" "$UECON" 2>/dev/null || true; exit 1; }

ip netns exec "$HOME_UE_NETNS" ip -br addr
ip netns exec "$HOME_UE_NETNS" ip route || true
ip netns exec "$HOME_UE_NETNS" ping -c 10 -i 0.2 "$HOME_UE_GATEWAY"

cat <<EOF
==========================================
 HOME 4G/LTE TEST = DONE
==========================================
S1AP  = SCTP/$LTE_S1AP_PORT
GTP-U = UDP/$GTPU_PORT
EOF

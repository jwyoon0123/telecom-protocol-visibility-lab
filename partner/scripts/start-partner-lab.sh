#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"; . "$REPO/tools/load-env.sh"

[ "$(id -u)" -eq 0 ] || { echo "[ERROR] root required"; exit 1; }

echo "======================================"
echo " PARTNER SS7/M3UA SG START"
echo " Partner : $PARTNER_IP / PC $PARTNER_PC_DOTTED"
echo " Home    : $HOME_IP / PC $HOME_PC_DOTTED"
echo " M3UA    : SCTP/$SS7_PORT"
echo "======================================"

modprobe sctp || true
ping -c 2 -W 1 "$HOME_IP" || true
command -v osmo-stp >/dev/null || { echo "[ERROR] osmo-stp not found"; exit 1; }
osmo-stp --version

# An unrelated MSC listener can confuse a minimal STP-only lab. Disable it only
# when its unit is installed; this mirrors the validated source-lab baseline.
if systemctl list-unit-files 2>/dev/null | grep -q '^osmo-msc'; then
  systemctl disable --now osmo-msc 2>/dev/null || true
fi

systemctl reset-failed osmo-stp || true
systemctl restart osmo-stp
sleep 3
systemctl is-active osmo-stp

echo "===== SCTP ====="
ss -anp -A sctp || true
echo "===== LISTENER ====="
ss -lnp -A sctp | grep "$SS7_PORT" || { echo "[ERROR] SCTP/$SS7_PORT listener missing"; exit 1; }
echo "===== LOG ====="
journalctl -u osmo-stp -n 40 --no-pager

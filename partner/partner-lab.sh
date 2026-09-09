#!/usr/bin/env bash
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; REPO="$(cd "$HERE/.." && pwd)"; . "$REPO/tools/load-env.sh"
MODE="${1:-status}"
case "$MODE" in
 status) pgrep -af 'open5gs-|osmo-stp' || true; ss -anp -A sctp 2>/dev/null || true; ss -lunp | grep -E ':(2152|8805)\\b' || true ;;
 ss7) "$HERE/scripts/start-partner-lab.sh" ;;
 capture-5g) "$HERE/scripts/500-partner-5g-capture.sh" ;;
 sepp) "$REPO/tools/sepp-lab.sh" partner "${2:-status}" ;;
 diameter) exec "$REPO/tools/diameter-visibility.py" server --bind "$PARTNER_IP" --port "$DIAMETER_PORT" ;;
 *) echo "Usage: $0 {status|ss7|capture-5g|sepp [mode]|diameter}"; exit 2;;
esac

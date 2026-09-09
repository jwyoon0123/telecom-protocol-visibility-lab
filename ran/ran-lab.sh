#!/usr/bin/env bash
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; REPO="$(cd "$HERE/.." && pwd)"; . "$REPO/tools/load-env.sh"
MODE="${1:-status}"
case "$MODE" in
 status) pgrep -af 'srsenb|srsue|/usr/local/bin/gnb' || true; ss -anp -A sctp 2>/dev/null | grep -E "$LTE_S1AP_PORT|$NGAP_PORT" || true ;;
 home-lte) "$HERE/scripts/500-home-lte-test.sh" "${2:-start}" ;;
 home-5g) "$HERE/scripts/500-home-pdu-test.sh" "${2:-start}" ;;
 partner-5g) "$HERE/scripts/510-partner-5g.sh" "${2:-start}" ;;
 stop) pkill -TERM -x srsue 2>/dev/null || true; pkill -TERM -x srsenb 2>/dev/null || true; pkill -TERM -x gnb 2>/dev/null || true ;;
 *) echo "Usage: $0 {status|home-lte|home-5g|partner-5g|stop} [start|status|ping|stop]"; exit 2;;
esac

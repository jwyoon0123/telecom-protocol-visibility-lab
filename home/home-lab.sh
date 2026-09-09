#!/usr/bin/env bash
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; REPO="$(cd "$HERE/.." && pwd)"; . "$REPO/tools/load-env.sh"
MODE="${1:-status}"
case "$MODE" in
 status) "$HERE/scripts/520-core-mode.sh" status; pgrep -af 'open5gs-|osmo-stp' || true ;;
 lte|4g) "$HERE/scripts/520-core-mode.sh" 4g ;;
 5g) "$HERE/scripts/520-core-mode.sh" 5g ;;
 ss7) "$HERE/scripts/79-final-ss7-test.sh" ;;
 capture-lte) "$HERE/scripts/500-home-lte-capture.sh" ;;
 capture-5g) "$HERE/scripts/500-home-5g-capture.sh" ;;
 ogstun) "$HERE/scripts/103-ogstun.sh" ;;
 sepp) "$REPO/tools/sepp-lab.sh" home "${2:-status}" ;;
 diameter) exec "$REPO/tools/diameter-visibility.py" client --host "$PARTNER_IP" --bind "$HOME_IP" --port "$DIAMETER_PORT" ;;
 *) echo "Usage: $0 {status|lte|5g|ss7|capture-lte|capture-5g|ogstun|sepp [mode]|diameter}"; exit 2;;
esac

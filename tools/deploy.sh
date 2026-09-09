#!/usr/bin/env bash
set -Eeuo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$REPO/tools/load-env.sh"

ROLE="${1:-}"
APPLY="${2:-}"
case "$ROLE" in home|partner|ran) ;; *) echo "Usage: $0 {home|partner|ran} [--apply]"; exit 2;; esac

OUT="$REPO/build/generated"
if [ "$ROLE" = ran ]; then
  "$REPO/tools/render-configs.py" --output "$OUT"
else
  "$REPO/tools/render-configs.py" --public-only --output "$OUT"
fi

if [ "$APPLY" != "--apply" ]; then
  echo "[DRY RUN] Generated configs under $OUT"
  echo "Run: sudo $0 $ROLE --apply"
  exit 0
fi

[ "$(id -u)" -eq 0 ] || { echo "[ERROR] --apply requires root"; exit 1; }
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="/var/backups/virtual-mobile-telecom-lab/$STAMP"
mkdir -p "$BACKUP"

copy_with_backup(){
  local src="$1" dst="$2"
  [ -f "$src" ] || return 0
  if [ -f "$dst" ]; then
    mkdir -p "$BACKUP$(dirname "$dst")"
    cp -a "$dst" "$BACKUP$dst"
  fi
  mkdir -p "$(dirname "$dst")"
  install -m 0644 "$src" "$dst"
  echo "[APPLY] $dst"
}

case "$ROLE" in
  home)
    for src in "$OUT"/home/config/open5gs/*; do copy_with_backup "$src" "/etc/open5gs/$(basename "$src")"; done
    for src in "$OUT"/home/config/freeDiameter/*; do copy_with_backup "$src" "/etc/freeDiameter/$(basename "$src")"; done
    copy_with_backup "$OUT/home/config/osmocom/osmo-stp.cfg" /etc/osmocom/osmo-stp.cfg
    ;;
  partner)
    for src in "$OUT"/partner/config/open5gs/*; do copy_with_backup "$src" "/etc/open5gs/$(basename "$src")"; done
    for src in "$OUT"/partner/config/freeDiameter/*; do copy_with_backup "$src" "/etc/freeDiameter/$(basename "$src")"; done
    copy_with_backup "$OUT/partner/config/osmocom/osmo-stp.cfg" /etc/osmocom/osmo-stp.cfg
    ;;
  ran)
    RUNTIME="${TELECOM_RUNTIME:-/opt/telecom-lab/runtime}"
    mkdir -p "$RUNTIME/lte" "$RUNTIME/5g" "${TELECOM_PCAP:-/opt/telecom-lab/pcap}"
    copy_with_backup "$OUT/ran/config/templates/lte-enb.conf" "$RUNTIME/lte/enb.conf"
    copy_with_backup "$OUT/ran/config/templates/lte-ue.conf" "$RUNTIME/lte/ue.conf"
    copy_with_backup "$OUT/ran/config/templates/gnb-home.yml" "$RUNTIME/5g/gnb-home.yml"
    copy_with_backup "$OUT/ran/config/templates/gnb-partner.yml" "$RUNTIME/5g/gnb-partner.yml"
    copy_with_backup "$OUT/ran/config/templates/ue-home.conf" "$RUNTIME/5g/ue.conf"
    copy_with_backup "$OUT/ran/config/templates/ue-partner.conf" "$RUNTIME/5g/ue-partner-final.conf"
    # LTE support files are copied from installed srsRAN examples rather than vendored.
    SHARE=""
    for d in /usr/local/share/srsran /usr/share/srsran; do [ -d "$d" ] && SHARE="$d" && break; done
    if [ -n "$SHARE" ]; then
      for name in sib.conf rr.conf rb.conf; do
        found="$(find "$SHARE" -type f -name "$name" -print -quit 2>/dev/null || true)"
        if [ -n "$found" ] && [ ! -f "$RUNTIME/lte/$name" ]; then
          cp -a "$found" "$RUNTIME/lte/$name"
          echo "[COPY upstream example] $RUNTIME/lte/$name"
        fi
      done
    fi
    ;;
esac

echo "Backup: $BACKUP"
echo "Config deployment complete. Service restart is intentionally manual."

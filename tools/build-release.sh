#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; VER="$(cat "$ROOT/VERSION")"; NAME="virtual-mobile-telecom-lab-v${VER}"; OUT="$(dirname "$ROOT")/${NAME}.zip"
( cd "$ROOT" && make check )
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp -a "$ROOT" "$TMP/$NAME"
rm -rf "$TMP/$NAME/.git" "$TMP/$NAME/build"; find "$TMP/$NAME" -type d -name __pycache__ -prune -exec rm -rf {} +
( cd "$TMP" && zip -qr "$OUT" "$NAME" )
sha256sum "$OUT" >"$OUT.sha256"
echo "$OUT"; cat "$OUT.sha256"

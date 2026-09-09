#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
SERVER_PID=""
cleanup(){ [ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2>/dev/null || true; rm -rf "$TMP"; }
trap cleanup EXIT INT TERM

printf '%s\n' '[1/4] public render'
"$ROOT/tools/render-configs.py" --public-only --output "$TMP/rendered"
"$ROOT/tools/validate-rendered-configs.py" "$TMP/rendered"

printf '%s\n' '[2/4] public tree contains no local secret file'
[ ! -e "$ROOT/config/secrets.env" ] || { echo '[FAIL] config/secrets.env exists in source tree'; exit 1; }

printf '%s\n' '[3/4] synthetic Diameter loopback'
PORT="${VMTL_SELFTEST_DIAMETER_PORT:-13868}"
python3 "$ROOT/tools/diameter-visibility.py" server \
  --bind 127.0.0.1 --port "$PORT" \
  --origin-host diameter-partner.lab.invalid \
  >"$TMP/diameter-server.log" 2>&1 &
SERVER_PID=$!
sleep 0.4
python3 "$ROOT/tools/diameter-visibility.py" client \
  --host 127.0.0.1 --bind 127.0.0.1 --port "$PORT" \
  --origin-host diameter-home.lab.invalid --watchdogs 1 --interval 0.01
kill "$SERVER_PID" 2>/dev/null || true
wait "$SERVER_PID" 2>/dev/null || true
SERVER_PID=""

grep -q 'Capabilities-Exchange Request' "$TMP/diameter-server.log"
grep -q 'Device-Watchdog Request' "$TMP/diameter-server.log"

printf '%s\n' '[4/4] no Python bytecode/cache in source tree'
if find "$ROOT" \( -type d -name __pycache__ -o -type f -name '*.pyc' \) -print -quit | grep -q .; then
  echo '[FAIL] Python cache found in source tree'
  exit 1
fi

echo '[OK] self-test passed'

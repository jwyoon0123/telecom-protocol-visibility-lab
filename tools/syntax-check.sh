#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
while IFS= read -r f; do
  echo "[bash -n] ${f#$ROOT/}"
  bash -n "$f"
done < <(find "$ROOT" -type f -name '*.sh' -not -path '*/build/*' | sort)
while IFS= read -r f; do
  echo "[python compile] ${f#$ROOT/}"
  python3 - "$f" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
compile(p.read_text(encoding='utf-8'), str(p), 'exec')
PY
done < <(find "$ROOT" -type f -name '*.py' -not -path '*/build/*' | sort)
echo '[OK] syntax checks passed'

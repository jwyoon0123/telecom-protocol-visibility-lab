#!/usr/bin/env python3
import sys
from pathlib import Path

root = Path(sys.argv[1] if len(sys.argv) > 1 else 'build/generated')
if not root.exists():
    raise SystemExit(f'not found: {root}')

bad = []
for p in root.rglob('*'):
    if not p.is_file():
        continue
    text = p.read_text(encoding='utf-8', errors='replace')
    if '__' in text and any(part.startswith('__') and part.endswith('__') for part in text.replace('\n',' ').split()):
        bad.append((p, 'unrendered token'))

try:
    import yaml
except Exception:
    yaml = None

if yaml:
    for p in list(root.rglob('*.yaml')) + list(root.rglob('*.yml')):
        try:
            yaml.safe_load(p.read_text(encoding='utf-8'))
        except Exception as e:
            bad.append((p, f'YAML: {e}'))
else:
    print('[WARN] PyYAML not installed; YAML parse skipped')

if bad:
    for p, why in bad:
        print(f'[FAIL] {p}: {why}')
    raise SystemExit(1)
print('[OK] rendered config validation passed')

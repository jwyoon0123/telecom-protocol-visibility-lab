#!/usr/bin/env python3
import argparse
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]


def load_env(path: Path):
    data = {}
    if not path.exists():
        return data
    for raw in path.read_text(encoding='utf-8').splitlines():
        line = raw.strip()
        if not line or line.startswith('#') or '=' not in line:
            continue
        k, v = line.split('=', 1)
        data[k.strip()] = v.strip().strip('"').strip("'")
    return data


def render_text(text: str, values: dict, allow_secret_placeholders: bool):
    tokens = sorted(set(re.findall(r'__([A-Z0-9_]+)__', text)))
    missing = []
    for key in tokens:
        value = values.get(key)
        if value is None or value == '' or value.startswith('REPLACE_WITH_'):
            if allow_secret_placeholders and key in {
                'HOME_IMSI','HOME_K','HOME_OPC','PARTNER_IMSI','PARTNER_K','PARTNER_OPC'
            }:
                continue
            missing.append(key)
            continue
        text = text.replace(f'__{key}__', value)
    if missing:
        raise SystemExit('Missing template values: ' + ', '.join(sorted(missing)))
    return text


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--output', default=str(REPO / 'build/generated'))
    ap.add_argument('--public-only', action='store_true', help='Skip templates requiring subscriber secrets')
    args = ap.parse_args()

    values = load_env(REPO / 'config/lab.env.example')
    values.update(load_env(REPO / 'config/lab.env'))
    secrets = load_env(REPO / 'config/secrets.env')
    if not args.public_only:
        values.update(secrets)

    out = Path(args.output).resolve()
    if out.exists():
        import shutil
        shutil.rmtree(out)
    out.mkdir(parents=True)

    roots = [REPO / 'home/config', REPO / 'partner/config', REPO / 'ran/config/templates']
    secret_tokens = {'HOME_IMSI','HOME_K','HOME_OPC','PARTNER_IMSI','PARTNER_K','PARTNER_OPC'}

    rendered = 0
    skipped = 0
    for root in roots:
        for src in sorted(root.rglob('*.template')):
            text = src.read_text(encoding='utf-8')
            tokens = set(re.findall(r'__([A-Z0-9_]+)__', text))
            if args.public_only and tokens & secret_tokens:
                skipped += 1
                continue
            text = render_text(text, values, allow_secret_placeholders=False)
            rel = src.relative_to(REPO)
            rel = Path(str(rel)[:-len('.template')])
            dst = out / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_text(text, encoding='utf-8')
            rendered += 1

    print(f'output={out}')
    print(f'rendered={rendered}')
    print(f'skipped_secret_templates={skipped}')
    if not args.public_only and skipped == 0:
        print('private UE configs rendered; keep the output out of Git')

if __name__ == '__main__':
    main()

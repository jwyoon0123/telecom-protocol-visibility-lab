#!/usr/bin/env bash
set -Eeuo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a
if [ -f "$REPO/config/lab.env" ]; then
  . "$REPO/config/lab.env"
else
  . "$REPO/config/lab.env.example"
fi
if [ -f "$REPO/config/secrets.env" ]; then
  . "$REPO/config/secrets.env"
fi
set +a
export VMTL_REPO="$REPO"

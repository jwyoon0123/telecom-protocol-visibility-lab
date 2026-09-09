#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0

check(){
  local label="$1" pattern="$2"
  if grep -RniE --binary-files=without-match \
      --exclude-dir=.git --exclude-dir=build \
      --exclude='public-safety-scan.sh' \
      "$pattern" "$ROOT"; then
    echo "[FAIL] $label"
    FAIL=1
  else
    echo "[OK] $label"
  fi
}

# Repository-independent checks suitable for the public tree.
check 'possible 128-bit secret' '(^|[^0-9A-Fa-f])[0-9A-Fa-f]{32}([^0-9A-Fa-f]|$)'
check 'private key material' 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY'
check 'common credential assignments' '(password|passwd|api[_-]?token|access[_-]?token|client[_-]?secret)[[:space:]]*[:=][[:space:]]*[^<[:space:]]+'
check 'likely private hostnames' '([A-Za-z0-9_-]+\.)+(corp|internal|intranet|lan)(\.|[[:space:]]|$)'

# Optional organization-specific deny regex. Keep it outside Git, for example:
#   VMTL_DENY_REGEX='company-name|internal-domain\\.example'
if [ -n "${VMTL_DENY_REGEX:-}" ]; then
  check 'organization-specific deny regex' "$VMTL_DENY_REGEX"
else
  echo '[INFO] VMTL_DENY_REGEX not set; organization-specific name/domain scan skipped'
fi

if [ "$FAIL" -ne 0 ]; then exit 1; fi
echo '[OK] public safety scan passed'

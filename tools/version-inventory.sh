#!/usr/bin/env bash
set -u
echo '===== OS ====='; grep -E '^(PRETTY_NAME|VERSION_ID)=' /etc/os-release 2>/dev/null || true
echo '===== KERNEL ====='; uname -a
echo '===== OPEN5GS ====='; for b in open5gs-amfd open5gs-mmed open5gs-upfd open5gs-seppd; do command -v "$b" >/dev/null && { echo "--- $b ---"; "$b" -v 2>&1 | head -5; }; done
echo '===== OSMOCOM ====='; command -v osmo-stp >/dev/null && osmo-stp --version 2>&1 | head -8
echo '===== SRSRAN ====='; for b in srsenb srsue gnb; do command -v "$b" >/dev/null && { echo "--- $b ---"; "$b" --version 2>&1 | head -12; }; done
echo '===== NETWORK ====='; ip -4 -br addr; ip route
echo '===== IMPORTANT SOCKETS ====='; ss -anp -A sctp 2>/dev/null | grep -E '2905|36412|38412' || true; ss -lunp | grep -E '2152|8805' || true; ss -lntp | grep -E '3868|7778|7779' || true

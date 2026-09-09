#!/usr/bin/env bash
set -Eeuo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run as root"; exit 1; }
. /etc/os-release
case "${ID:-}" in ubuntu|debian) ;; *) echo "[ERROR] Debian/Ubuntu only"; exit 1;; esac
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y \
  ca-certificates curl wget git jq unzip zip \
  tcpdump tshark iproute2 iputils-ping ethtool \
  build-essential cmake meson ninja-build pkg-config \
  python3 python3-venv python3-pip python3-yaml python3-pymongo \
  libsctp-dev lksctp-tools libzmq3-dev openssl
modprobe sctp
cat >/etc/modules-load.d/telecom-sctp.conf <<'EOF'
sctp
EOF
mkdir -p /opt/telecom-lab/{runtime,pcap,logs,src} /var/log/open5gs
printf '[OK] common dependencies installed on %s\n' "$PRETTY_NAME"

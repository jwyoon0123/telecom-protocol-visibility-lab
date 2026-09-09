#!/usr/bin/env bash
set -Eeuo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run as root"; exit 1; }
mkdir -p /etc/open5gs/hnet /etc/open5gs/tls
chmod 700 /etc/open5gs/hnet /etc/open5gs/tls

if [ ! -f /etc/open5gs/hnet/curve25519-1.key ]; then
  openssl genpkey -algorithm X25519 -out /etc/open5gs/hnet/curve25519-1.key
fi
if [ ! -f /etc/open5gs/hnet/secp256r1-2.key ]; then
  openssl ecparam -name prime256v1 -genkey -conv_form compressed -out /etc/open5gs/hnet/secp256r1-2.key
fi

if [ ! -f /etc/open5gs/tls/ca.key ]; then
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -subj '/CN=Virtual Mobile Telecom Lab CA' \
    -keyout /etc/open5gs/tls/ca.key -out /etc/open5gs/tls/ca.crt
fi
for n in hss mme smf pcrf; do
  if [ ! -f "/etc/open5gs/tls/$n.key" ]; then
    openssl req -newkey rsa:2048 -nodes -subj "/CN=$n.lab.invalid" \
      -keyout "/etc/open5gs/tls/$n.key" -out "/etc/open5gs/tls/$n.csr"
    openssl x509 -req -days 3650 -in "/etc/open5gs/tls/$n.csr" \
      -CA /etc/open5gs/tls/ca.crt -CAkey /etc/open5gs/tls/ca.key -CAcreateserial \
      -out "/etc/open5gs/tls/$n.crt"
    rm -f "/etc/open5gs/tls/$n.csr"
  fi
done
chmod 600 /etc/open5gs/hnet/*.key /etc/open5gs/tls/*.key
chmod 644 /etc/open5gs/tls/*.crt
printf '[OK] lab-only HNET/freeDiameter key material generated locally; do not commit it\n'

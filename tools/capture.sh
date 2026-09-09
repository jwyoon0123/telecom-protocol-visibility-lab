#!/usr/bin/env bash
set -Eeuo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; . "$REPO/tools/load-env.sh"
MODE="${1:-all}"; OUTDIR="${TELECOM_PCAP:-/opt/telecom-lab/pcap}"; mkdir -p "$OUTDIR"; PCAP="$OUTDIR/${MODE}-$(date +%Y%m%d-%H%M%S).pcap"
case "$MODE" in
 ss7) FILTER="sctp port $SS7_PORT";;
 lte) FILTER="sctp port $LTE_S1AP_PORT or udp port $GTPU_PORT";;
 5g) FILTER="sctp port $NGAP_PORT or udp port $GTPU_PORT or udp port $PFCP_PORT";;
 diameter) FILTER="tcp port $DIAMETER_PORT or sctp port $DIAMETER_PORT";;
 n32) FILTER="tcp port $N32_PORT or tcp port $N32F_PORT";;
 all) FILTER="sctp port $SS7_PORT or sctp port $LTE_S1AP_PORT or sctp port $NGAP_PORT or udp port $GTPU_PORT or udp port $PFCP_PORT or tcp port $DIAMETER_PORT or sctp port $DIAMETER_PORT or tcp port $N32_PORT or tcp port $N32F_PORT";;
 *) echo "Usage: $0 {ss7|lte|5g|diameter|n32|all}"; exit 2;;
esac
echo "PCAP=$PCAP"; exec tcpdump -ni "$CAPTURE_IF" -s0 -nn -w "$PCAP" "$FILTER"

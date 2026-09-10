# GTP-U Packet Analysis Guide

## Overview

GTP-U (GPRS Tunneling Protocol - User Plane)는 3G/4G/5G의 데이터 평면 프로토콜로, 모바일 코어 내부와 기지국/게이트웨이 간 데이터 패킷을 터널링합니다.

**Protocol Stack**: GTP-U → UDP/2152 → IP

## GTP Header Structure

### GTPv1-U Header (variable length)
```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|VER|PT |  Res  |E|S|PN|       Message Type      |   Length     |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                         TEID                                  |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|         Sequence Number (opt)         |    N-PDU (opt)       |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|  Next Extension Header Type (opt)     |  Extension Data ...  |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

**Field Breakdown**:
- **VER**: Version (0x1 for GTPv1)
- **PT**: Protocol Type (1=GTP, 0=GTP')
- **E**: Extension Header flag
- **S**: Sequence Number flag
- **PN**: N-PDU flag
- **Message Type**: PDU type (0xFF=T-PDU/data, 0x26=Echo Request, etc.)
- **Length**: Payload length (excluding 8-byte header)
- **TEID**: Tunnel End-point Identifier (identifies user session)

## Message Types

| Code | Name | Direction | Usage |
|------|------|-----------|-------|
| 0x01 | Echo Request | Both | Keep-alive |
| 0x02 | Echo Response | Both | Keep-alive reply |
| 0xFF | T-PDU | Both | Data packet |

## TEID (Tunnel End-Point Identifier)

TEID는 터널 세션을 식별하는 32-bit 번호입니다.

```
Example trace:
Uplink (UE → PDN):   SGW-U → PGW-U
  Ingress TEID: 0x12345678 (SGW-U perspective)
  Egress TEID: 0xABCDEF00 (PGW-U perspective)

Downlink (PDN → UE): PGW-U → SGW-U
  Ingress TEID: 0xABCDEF00 (PGW-U perspective)
  Egress TEID: 0x12345678 (SGW-U perspective)
```

## Protocol Detection Patterns

### GTPv1-U on UDP/2152
```bash
# tcpdump filter for GTP-U data
tcpdump -i eth0 'udp port 2152'

# Wireshark dissector: gtp
# Display filter: gtp.message_type == 0xff  (T-PDU only)
```

### Inner IP Header Detection
```
After GTP header, common patterns:
  0x4X: IPv4 packet (X=version+header_len)
  0x6X: IPv6 packet

Example UL T-PDU (IPv4):
  GTP Header (8 bytes) → IPv4 (10.0.0.5 → 8.8.8.8) → DNS query
```

## GTP-U Flow in 4G (LTE)

```
┌─────────────────────────────────────────────┐
│ UE: 192.168.1.100                          │
└────────────┬────────────────────────────────┘
             │ IP packet (192.168.1.100 → 8.8.8.8)
             │ → encoded as LTE RLC/MAC frames
             │
┌────────────v────────────────────────────────┐
│ eNodeB: 10.10.10.62                        │
│ S1-U interface (SCTP)                       │
└────────────┬────────────────────────────────┘
             │ GTP-U Header + IPv4 packet
             │ (TEID: 0x12345678, UDP/2152)
             │
┌────────────v────────────────────────────────┐
│ SGW-U: 10.10.10.54                         │
│ Decapsulates GTP, forwards to PGW-U        │
└────────────┬────────────────────────────────┘
             │ (potentially re-encapsulates with new TEID)
             │
┌────────────v────────────────────────────────┐
│ PGW-U: 10.10.10.57                         │
│ Terminates GTP, forwards to PDN (Internet) │
└─────────────────────────────────────────────┘
```

## Capture & Analysis Commands

### Capture GTP-U in tcpdump
```bash
# All GTP-U traffic
sudo tcpdump -i eth0 'udp port 2152' -w gtp_traffic.pcap

# With payload inspection
sudo tcpdump -i eth0 'udp port 2152' -A -X

# Filter by TEID
sudo tcpdump -i eth0 'udp port 2152' -w gtp_teid.pcap
# Then analyze with Wireshark: gtp.teid == 0x12345678
```

### Wireshark Display Filters
```
gtp.message_type == 0xff          # Data packets only
gtp.teid == 0x12345678             # Specific tunnel
gtp && ip.src == 10.10.10.54       # From SGW-U
```

### Python Analysis
```python
import struct

def parse_gtp_header(data):
    version_pt_res = data[0]
    version = (version_pt_res >> 5) & 0x07
    flags = version_pt_res & 0x07
    msg_type = data[1]
    length = struct.unpack('>H', data[2:4])[0]
    teid = struct.unpack('>I', data[4:8])[0]
    return {
        'version': version,
        'msg_type': hex(msg_type),
        'length': length,
        'teid': hex(teid),
        'has_seq': bool(flags & 0x02),
        'has_npdu': bool(flags & 0x01)
    }
```

## Common Issues

### GTP packets not forwarded
**Symptom**: Packets reach SGW but don't exit to PDN  
**Cause**: TEID mismatch or incorrect routing table  
**Debug**:
```bash
# Check TEID mappings on SGW-U
grep -i teid /var/log/open5gs/upf.log

# Verify routing
ip route show
```

### Mismatched TEID in UL/DL
**Symptom**: UE traffic goes up but response doesn't return  
**Cause**: UL TEID ≠ DL TEID (expected behavior, not an error)  
**Fix**: Ensure both directions registered in tunnel table

### Performance degradation
**Symptom**: High packet loss on GTP-U  
**Check**:
```bash
# CPU/memory pressure
watch -n1 'top -bn1 | head -20'

# UDP statistics
netstat -s | grep -i udp

# Packet drops
ip -s link show
```

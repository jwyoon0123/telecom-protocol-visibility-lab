# SS7/M3UA Message Analysis Guide

## Overview

SS7 (Signaling System No. 7)는 공중 전화망의 신호 프로토콜입니다. M3UA는 SCTP를 통해 SS7을 IP 네트워크로 전송하는 프로토콜입니다.

**Protocol Stack**: M3UA (RFC 4666) → SCTP → IP/UDP/TCP

## M3UA Layer Structure

### Common Header (8 bytes)
```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|    Version    |    Reserved   |         Message Type          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|           Message Class       |          Message Type         |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                        Message Length                        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

- **Version**: 0x01
- **Message Class**: ASP State Mgmt (0), Transfer (1), SSNM (2), etc.
- **Message Type**: Specific command

## Key M3UA Message Types

### ASP State Management (Class 0)
| Code | Name | Usage |
|------|------|-------|
| 0x01 | ASP-UP | Server ready |
| 0x02 | ASP-DOWN | Server stopping |
| 0x03 | HEARTBEAT | Keep-alive |
| 0x04 | ASP-UP-ACK | Acknowledge UP |
| 0x05 | ASP-DOWN-ACK | Acknowledge DOWN |
| 0x06 | HEARTBEAT-ACK | Acknowledge HEARTBEAT |

### Transfer (Class 1)
| Code | Name | Usage |
|------|------|-------|
| 0x01 | DATA | SS7 payload |

## SS7 MTP3 Point Code Format

```
ITU-T (International): 14-bit code
  Bits 0-3: SPC (Signaling Point Code) network
  Bits 4-10: SPC cluster
  Bits 11-13: SPC member

Example: PC 500 (0x1F4)
  Network: 500 & 0x0F = 4
  Cluster: (500 >> 4) & 0x7F = 31
  Member: (500 >> 11) & 0x07 = 0
```

## SCCP (Signaling Connection Control Part)

SCCP는 MTP3 위의 연결 제어 계층입니다.

### SCCP Message Types
```
0x09: UDT (Unitdata) - Connectionless
0x0B: UDTS (Unitdata Service) - Error response
0x81: CR (Connection Request) - Connection setup
0x82: CC (Connection Confirm) - Connection accept
0x83: CREF (Connection Refused) - Rejection
0x84: RLSD (Release) - Disconnect
0x85: RLC (Release Complete) - Confirm close
```

## TCAP (Transaction Capabilities Application Part)

TCAP는 MAP 등 애플리케이션 프로토콜의 트랜잭션 계층입니다.

### TCAP Message Types
```
0x62: TC-BEGIN (Start transaction)
0x64: TC-CONTINUE (Continue)
0x65: TC-END (End normal)
0x67: TC-ABORT (Abnormal end)
```

## MAP (Mobile Application Part)

MAP는 이동통신망의 가입자 정보/인증 처리 프로토콜입니다.

### Key MAP Operations (sendAuthenticationInfo)
```
Operation Code: 56
Invoke ID: Transaction identifier

Request:
  IMSI: Subscriber identity
  NumberOfRequestedVectors: 1-5
  ImmediateResponsePreferred: bool

Response:
  AuthenticationTriplets: {
    RAND: Challenge (16 bytes)
    SRES: Expected response (4 bytes)
    Kc: Cipher key (8 bytes)
  }
  SelectedVLR-Number: VLR address (optional)
```

## Pcap Analysis Example

### Tools
```bash
# Capture SS7 traffic on SCTP/2905
tcpdump -i eth0 sctp port 2905 -w ss7_traffic.pcap

# Analyze with Wireshark
wireshark ss7_traffic.pcap

# Decode with tshark
tshark -r ss7_traffic.pcap -Y m3ua -V
```

### Expected Flow (sendAuthenticationInfo)
```
1. Home Core → Partner Core: TC-BEGIN
   M3UA Header
   MTP3: OPC=500, DPC=50
   SCCP: Calling GT (Home), Called GT (Partner)
   TCAP: TC-BEGIN, Invoke ID=1
   MAP: sendAuthenticationInfo (Op=56)
       IMSI=450011234567890

2. Partner Core → Home Core: TC-END
   M3UA Header
   MTP3: OPC=50, DPC=500
   SCCP: Calling GT (Partner), Called GT (Home)
   TCAP: TC-END, Invoke ID=1
   MAP: sendAuthenticationInfo-Result
       RAND, SRES, Kc values
```

## Troubleshooting

### Packet received but not processed (FW drops)
**Cause**: OPC/DPC not registered in firewall ruleset  
**Check**: 
```bash
grep -E 'opc|dpc' /etc/osmocom/osmo-stp.cfg
```
**Fix**: Register point codes in M3UA routing table

### SCTP connection refused
**Cause**: No listener on port 2905  
**Check**:
```bash
netstat -tlnp | grep 2905
```
**Fix**: Start OsmoSTP service

### MAP operation timeout
**Cause**: GT resolution failed (SCCP routing mismatch)  
**Check**: Calling/Called GT format and SCCP routing rules  
**Fix**: Ensure GT SSN matches expected service (SSN 6 for HLR)

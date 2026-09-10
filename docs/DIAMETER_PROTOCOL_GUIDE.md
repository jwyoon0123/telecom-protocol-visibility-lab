# Diameter Protocol Visibility Guide

## Overview

Diameter는 RFC 6733에 정의된 AAA(Authentication, Authorization, Accounting) 프로토콜로, 3GPP 망에서 S6a, S6d, Sh, Cx 인터페이스에 사용됩니다.

## Message Structure

### Header (20 bytes)
```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|    Version    |                 Message Length                |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
| Flags |      Command Code      |      Application ID           |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                         Hop-by-Hop ID                         |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                      End-to-End ID                            |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

- **Version**: 1 byte (0x01)
- **Message Length**: 3 bytes (big-endian, includes header)
- **Flags**: 1 byte
  - Bit 7 (0x80): Request flag (1=request, 0=answer)
  - Bit 6 (0x40): Proxiable
  - Bit 5 (0x20): Error
  - Bit 4 (0x10): Retransmitted
- **Command Code**: 3 bytes (big-endian)
- **Application ID**: 4 bytes (identifies application)
- **Hop-by-Hop ID**: 4 bytes (per-hop tracking)
- **End-to-End ID**: 4 bytes (end-to-end tracking)

## Key Command Codes

| Code | Name | Request/Answer | Usage |
|------|------|---|---|
| 257 | Capabilities-Exchange | Both | CER/CEA - Initial negotiation |
| 258 | Re-Auth | Both | RAR/RAA - Session refresh |
| 271 | Accounting | Both | ACR/ACA - Usage reporting |
| 280 | Device-Watchdog | Both | DWR/DWA - Keep-alive |
| 306 | S6a Auth-Info | Both | AIR/AIA - Authentication data |
| 316 | S6d Purge-UE | Both | PUR/PUA - UE session cleanup |

## AVP (Attribute-Value Pair) Structure

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                          AVP Code                             |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|   Flags   |                  AVP Length                       |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                        Vendor-ID (opt)                        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|    Data ...
+-+-+-+-+-+-+-+-+-+-+-
```

### AVP Flags
- Bit 7 (0x80): Vendor-Specific
- Bit 6 (0x40): Mandatory
- Bit 5 (0x20): Protected

## Key AVP Codes (3GPP S6a)

| Code | Name | Type | Mandatory |
|------|------|------|----------|
| 264 | Origin-Host | DiameterIdentity | Yes |
| 266 | Origin-State-Id | Unsigned32 | Yes |
| 268 | Result-Code | Unsigned32 | Yes |
| 280 | Accounting-Record-Number | Unsigned32 | - |
| 296 | Origin-Realm | DiameterRealm | Yes |
| 257 | Host-IP-Address | Address | Yes (in CER/CEA) |
| 265 | Supported-Vendor-Id | Unsigned32 | - |
| 258 | Vendor-Specific-Application-Id | Grouped | - |

## Protocol Decoding Example

```python
# CER (Capabilities-Exchange-Request) from home.lab.invalid
Version: 0x01
Length: 0x0000D0 (208 bytes)
Flags: 0x80 (Request)
Command: 257 (CER)
App-ID: 0 (Relay)
Hop-ID: 0x12345678
End-ID: 0x87654321

AVPs:
  264 (Origin-Host): "home.lab.invalid" [Mandatory]
  296 (Origin-Realm): "lab.invalid" [Mandatory]
  257 (Host-IP): 10.10.10.54 [Mandatory]
  266 (Origin-State-Id): 0 [Mandatory]
  269 (Product-Name): "Virtual-Mobile-Telecom-Lab"
  265 (Supported-Vendor-Id): 10415 (3GPP)
  258 (Vendor-Specific-App-Id): [Grouped]
    256 (Vendor-Id): 10415
    257 (Auth-App-Id): 16777251 (S6a)
```

## Testing with diameter-visibility.py

### Server Mode (Partner Core)
```bash
python3 tools/diameter-visibility.py server \
  --bind 10.10.10.53 \
  --port 3868 \
  --origin-host diameter-partner.lab.invalid \
  --origin-realm lab.invalid
```

### Client Mode (Home Core)
```bash
python3 tools/diameter-visibility.py client \
  --host 10.10.10.53 \
  --bind 10.10.10.54 \
  --port 3868 \
  --origin-host diameter-home.lab.invalid \
  --origin-realm lab.invalid \
  --watchdogs 5 \
  --interval 2.0
```

## Result Code Meanings

- **2001**: DIAMETER_SUCCESS
- **3002**: DIAMETER_AUTHORIZATION_REJECTED
- **5001**: DIAMETER_AVP_UNSUPPORTED
- **5002**: DIAMETER_UNKNOWN_SESSION_ID
- **5005**: DIAMETER_INVALID_AVP_VALUE

## Common Issues

### Missing Origin-Host/Realm
**Symptom**: CEA not received  
**Cause**: AVP 264/296 absent in CER  
**Fix**: Ensure `--origin-host` and `--origin-realm` are set

### Result-Code != 2001
**Symptom**: CEA received but Result-Code is error  
**Cause**: AVP validation failed or realm mismatch  
**Fix**: Check Origin-Host/Realm compatibility

### Timeout on first message
**Symptom**: DWA never arrives  
**Cause**: Server not listening or firewall blocking port 3868  
**Fix**: Verify `--port` and network connectivity

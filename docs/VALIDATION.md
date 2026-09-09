# Validation Matrix

| Test | Wire traffic | Acceptance |
|---|---|---|
| SS7 MAP | SCTP/2905, M3UA, SCCP, TCAP, MAP | ASPUP/ACK + ASPAC/ACK + MAP decode |
| Home LTE | SCTP/36412 + UDP/2152 | Attach, UE IP, gateway ping |
| Home 5G SA | SCTP/38412 + UDP/2152 | Registration, PDU Session, gateway ping |
| Partner 5G SA | SCTP/38412 + UDP/2152 | Registration, PDU Session, gateway ping |
| N32 | TCP/7778 + TCP/7779 | both peer ports reachable and captureable |
| Diameter visibility | TCP/3868 | CER/CEA + DWR/DWA, Result-Code 2001 |

## SS7 baseline already proven in the source lab

The validated baseline includes SCTP association, M3UA PPID 3, ASPUP/ACK, ASPAC/ACK, SCCP, TCAP Begin, MAP Invoke and `sendAuthenticationInfo` decode at the Partner side.

The following are explicitly outside the completed baseline:

- production Global Title translation
- actual HLR/VLR application response
- guaranteed commercial-network ASN.1 compatibility for every MAP operation
- production AS/routing-key design

## Decode example

```bash
tshark -r capture.pcap \
  -d sctp.ppi==3,m3ua \
  -Y 'm3ua || sccp || tcap || gsm_map' \
  -T fields \
  -e frame.number \
  -e _ws.col.Protocol \
  -e _ws.col.Info
```

## Diagnostic order

```text
1. IP/interface
2. listener/association
3. packet capture
4. protocol decode
5. registration/session/application state
6. user plane
```

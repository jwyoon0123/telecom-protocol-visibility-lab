# Architecture

## 1. Node roles

| Node | Default IP | Main roles |
|---|---:|---|
| Home Core | `10.10.10.54` | Open5GS EPC/5GC, OsmoSTP ASP, MAP generator, Home SEPP |
| Partner Core | `10.10.10.53` | Open5GS 5GC, OsmoSTP M3UA SG, Partner SEPP, Diameter visibility peer |
| RAN/UE | `10.10.10.62` | srsRAN LTE eNB/UE, 5G gNB/UE, ZeroMQ RF |

## 2. SS7

```text
Home ASP                         Partner SG
PC 1.1.1                        PC 2.2.2
10.10.10.54                     10.10.10.53:2905
     |                                  ^
     +-- SCTP -> M3UA -> SCCP -> TCAP --+
                              -> MAP
```

Baseline success means ASPUP/ACK, ASPAC/ACK and MAP decode are visible in PCAP. The lab does not claim production GT translation or HLR response behavior.

## 3. LTE

```text
RAN .62  -- S1AP/SCTP 36412 --> Home MME .54
RAN .62 <---- GTP-U/UDP 2152 --> Home SGW-U .54
UE namespace ue1 -> 10.45.0.0/16
```

## 4. 5G SA

Home profile:

```text
RAN .62 -- NGAP/SCTP 38412 --> Home AMF .54
RAN .62 <--- GTP-U/UDP 2152 -> Home UPF .54
UE namespace ue1 -> 10.45.0.0/16
```

Partner profile:

```text
RAN .62 -- NGAP/SCTP 38412 --> Partner AMF .53
RAN .62 <--- GTP-U/UDP 2152 -> Partner UPF .53
UE namespace ue2 -> 10.46.0.0/16
```

## 5. Mode isolation

Home SGW-U and Home UPF cannot both own `Home-IP:2152`. `home/scripts/520-core-mode.sh` moves the inactive UPF GTP-U endpoint to loopback when LTE is selected.

The RAN profiles reuse the same ZeroMQ pair, so Home 5G and Partner 5G must be stopped before switching profiles.

## 6. N32 / Diameter

N32 is an Open5GS SEPP transport exercise using TCP 7778/7779. Diameter visibility uses a synthetic protocol implementation on TCP/3868 for CER/CEA/DWR/DWA. Neither is described as a complete production roaming federation.

## 7. Visibility boundary

NF-to-NF traffic that remains on `127.0.0.0/8` never traverses the VM NIC. External packet sensors or physical switch mirrors cannot observe it unless the traffic is moved onto a visible interface or another capture method is used.

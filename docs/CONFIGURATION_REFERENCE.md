# Configuration Reference

`config/lab.env`는 topology와 synthetic identity를, `config/secrets.env`는 UE 인증 secret을 보관합니다. `*.example`만 Git에 commit합니다.

## Topology

| Variable | Reference value | Meaning |
|---|---|---|
| `HOME_IP` | `10.10.10.54` | Home Core external lab address |
| `PARTNER_IP` | `10.10.10.53` | Partner Core external lab address |
| `RAN_IP` | `10.10.10.62` | software RAN/UE host address |
| `CAPTURE_IF` | `eth0` | packet capture interface |

## Mobile identifiers

| Variable | Reference value |
|---|---|
| `HOME_PLMN` | `00101` |
| `HOME_TAC` | `7` |
| `HOME_PC_DOTTED` / `HOME_PC` | `1.1.1` / `2057` |
| `PARTNER_PLMN` | `00102` |
| `PARTNER_TAC` | `2` |
| `PARTNER_PC_DOTTED` / `PARTNER_PC` | `2.2.2` / `4114` |
| `SS7_HLR_SSN` | `6` |

These are synthetic lab identifiers, not production allocation guidance.

## UE networks

```text
Home     10.45.0.0/16   gateway 10.45.0.1   namespace ue1
Partner  10.46.0.0/16   gateway 10.46.0.1   namespace ue2
```

## Ports

| Variable | Protocol/port | Use |
|---|---|---|
| `SS7_PORT` | SCTP/2905 | M3UA |
| `LTE_S1AP_PORT` | SCTP/36412 | S1AP |
| `NGAP_PORT` | SCTP/38412 | NGAP/N2 |
| `GTPU_PORT` | UDP/2152 | GTP-U |
| `PFCP_PORT` | UDP/8805 | PFCP |
| `DIAMETER_PORT` | TCP/3868 | synthetic Diameter visibility |
| `N32_PORT` | TCP/7778 | lab N32 transport |
| `N32F_PORT` | TCP/7779 | lab N32 forwarding transport |

## ZeroMQ software RF

LTE uses 2000/2001; 5G uses 2100/2101 by default. The 5G Home and Partner profiles reuse the same pair, therefore they are mutually exclusive.

## Secrets

`HOME_IMSI`, `HOME_K`, `HOME_OPC`, `PARTNER_IMSI`, `PARTNER_K`, and `PARTNER_OPC` belong only in `config/secrets.env`. Use synthetic lab-only credentials. The renderer rejects placeholder values when a private UE config is requested.

# Tested Baseline

This repository separates **observed/validated behavior** from **public templates**.

## Validated source-lab behavior

- SS7: SCTP association, M3UA PPID 3, ASPUP/ACK, ASPAC/ACK, SCCP, TCAP Begin, MAP Invoke and `sendAuthenticationInfo` decode at the Partner side.
- Home LTE: S1AP attach, UE address assignment and user-plane ping to the Home gateway.
- Home 5G SA: NGAP/N2 registration, PDU Session establishment and user-plane ping.
- Partner 5G SA: NGAP/N2 registration, PDU Session establishment and user-plane ping.
- N32: Home/Partner TCP transport reachability on the lab SEPP ports.
- Diameter: synthetic CER/CEA and DWR/DWA visibility with Result-Code 2001.

## Not claimed

- production SS7 Global Title translation
- full HLR/VLR application behavior
- standards-complete BER payloads for every experimental MAP operation
- a real S6a roaming federation
- production N32 TLS/PRINS semantics
- simultaneous Home LTE and Home 5G external UDP/2152 ownership

## Release philosophy

A release is considered usable when `make check` passes and the three live nodes pass the validation matrix in `docs/VALIDATION.md`. CI can validate syntax/templates and synthetic Diameter logic; it cannot emulate the complete Open5GS/srsRAN radio/core state.

# Known Limitations

1. **SS7 Global Title** — baseline routing is Point Code/SSN oriented. GT translation is not a completed feature.
2. **MAP application response** — the Home MAP generator is primarily a packet-generation/visibility tool; a full HLR application is not bundled.
3. **MAP BER** — individual experimental operations may need operation-specific ASN.1 argument structures.
4. **Diameter** — included tool is synthetic CER/CEA/DWR/DWA visibility, not a complete S6a/S6d roaming peer.
5. **N32** — included SEPP profile exercises HTTP transport. Production N32 security/TLS/PRINS is not claimed.
6. **Loopback visibility** — SBI/PFCP/Diameter traffic kept on 127.x does not cross the external VM NIC.
7. **Home UDP/2152** — LTE SGW-U and 5G UPF are mode-switched, not concurrently external.
8. **RAN ZeroMQ** — Home 5G and Partner 5G reuse the same local ZMQ ports.
9. **Upstream version drift** — repository templates are based on an observed lab snapshot; pin and retest exact upstream revisions.
10. **No production subscriber data** — only synthetic identities should be used.

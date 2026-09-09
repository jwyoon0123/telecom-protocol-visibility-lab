# Public GitHub Publication Checklist

- [ ] repository owner has selected/approved a license, or intentionally publishes without one
- [ ] company names, trademarks, internal domains and commercial-product configuration are absent (optionally run `VMTL_DENY_REGEX=... make safety`)
- [ ] K/OP/OPc/password/token/private-key material is absent
- [ ] production IMSI/MSISDN/GT/CDR/PCAP is absent
- [ ] MongoDB subscriber dump is absent
- [ ] shell history, SSH material, machine UUID/serial, backup archives and raw host inventory are absent
- [ ] upstream source trees are not copied into this repository
- [ ] `make check` succeeds
- [ ] `docs/VERSION_MATRIX.md` reflects the release being published
- [ ] README limitations match current code behavior
- [ ] test PCAP, if added, contains only reviewed synthetic identifiers
- [ ] `git diff --cached` and `git status` are manually reviewed before push

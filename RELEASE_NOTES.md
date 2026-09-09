# Release Notes — v1.0.0

This is the first public-ready release of the three-node virtual mobile telecom lab.

## Included

- vendor-neutral Home Core / Partner Core / RAN-UE topology
- Open5GS configuration templates for the validated 4G/5G lab roles
- OsmoSTP Home ASP / Partner SG baseline templates
- SS7 `sendAuthenticationInfo` visibility generator/wrapper
- Home LTE, Home 5G SA and Partner 5G SA operational wrappers
- Home LTE/5G UDP/2152 mode switching
- software-RF ZeroMQ profile isolation
- synthetic Diameter CER/CEA/DWR/DWA visibility tool
- lab N32/SEPP transport helper
- configuration renderer, deployment backup logic and local subscriber provisioning helper
- syntax, public-safety, YAML/template and Diameter loopback self-tests
- GitHub Actions validation workflow

## Security/publication boundary

The release does not contain local subscriber K/OPc values, private keys, packet captures, database dumps, host inventory, company branding, internal domains, or commercial security-product configuration.

## Known boundary

The baseline proves telecom protocol visibility and selected attach/session flows. It does not claim production SS7 GT translation/full HLR behavior, a full S6a roaming federation, or production N32 TLS/PRINS semantics.

## Before publishing

The repository owner still needs to make the repository-license decision documented in `docs/LICENSING.md`. Exact srsRAN and Partner Open5GS revisions should also be recorded from the live nodes when available; no revision is guessed in this release.

# Version Matrix

## Observed source-lab snapshot

| Component | Home | Partner | RAN/UE |
|---|---|---|---|
| OS | Ubuntu 26.04.1 LTS | Ubuntu 26.04.1 LTS | Ubuntu 24.04.4 LTS |
| Kernel | 7.0.0-31-generic | 7.0.0-31-generic | 7.0.0-31-generic |
| Open5GS | 2.8.0 build artifacts observed | exact live revision not preserved in public snapshot | n/a |
| OsmoSTP | 2.3.0 observed | verify live node before tagging | n/a |
| srsRAN 4G | n/a | n/a | exact revision not preserved in public snapshot |
| srsRAN Project | n/a | n/a | exact revision not preserved in public snapshot |

The table documents evidence from the source lab; it is not a compatibility matrix. Do not infer an application revision from an OS version.

Before a tagged release, collect each live node:

```bash
./tools/version-inventory.sh > "version-inventory-$(hostname).txt"
```

Then record exact tags/commits in a release note or in your local `config/versions.env`. Do not commit raw host inventory if it contains internal addresses or host metadata.

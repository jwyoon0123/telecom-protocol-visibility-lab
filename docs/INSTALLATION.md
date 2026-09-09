# Installation and Rebuild

## 1. Reference host state

The lab snapshots used to prepare this release showed:

| Role | Observed OS | Observed kernel |
|---|---|---|
| Home Core | Ubuntu 26.04.1 LTS | 7.0.0-31-generic |
| Partner Core | Ubuntu 26.04.1 LTS | 7.0.0-31-generic |
| RAN/UE | Ubuntu 24.04.4 LTS | 7.0.0-31-generic |

This table documents the observed lab, not a blanket compatibility promise. Pin actual upstream application versions before a tagged release.

## 2. VM resources

A practical functional baseline is 4 vCPU, 4 GB RAM, 40–80 GB disk and one lab NIC. software PHY/RF timing is sensitive to CPU scheduling; increase reservation if ZMQ/RAN logs show repeated late/underflow symptoms.

## 3. Network

Default reference addresses:

```text
Home Core     10.10.10.54/24
Partner Core  10.10.10.53/24
RAN/UE        10.10.10.62/24
```

Set the actual DNS and gateway for your environment. Do not assume the gateway is also a resolver.

## 4. Common packages

On all three nodes:

```bash
sudo ./tools/bootstrap-deps.sh
```

## 5. Upstream software

Install the following from their upstream project/repository and record the exact tag/commit in `config/versions.env`:

- Open5GS on Home and Partner
- OsmoSTP on Home and Partner
- srsRAN 4G on RAN/UE
- srsRAN Project on RAN/UE
- ss7simulator on Home if the MAP generator is used

Expected binaries include:

```text
open5gs-mmed open5gs-hssd open5gs-sgwcd open5gs-sgwud
open5gs-amfd open5gs-smfd open5gs-upfd open5gs-nrfd
open5gs-scpd open5gs-ausfd open5gs-udmd open5gs-udrd
open5gs-pcfd open5gs-nssfd open5gs-seppd
osmo-stp
srsenb srsue gnb
```

The repository deliberately does not vendor upstream source trees.

## 6. Local secrets

```bash
cp config/lab.env.example config/lab.env
cp config/secrets.env.example config/secrets.env
chmod 600 config/secrets.env
```

Use synthetic lab-only subscriber identities. Never use production subscriber credentials.

## 7. Generate local key material

Home/Partner core nodes:

```bash
sudo ./tools/generate-lab-keys.sh
```

The generated private keys remain under `/etc/open5gs` and are ignored by Git.

## 8. Render configuration

Public/core-only render:

```bash
./tools/render-configs.py --public-only
```

RAN UE configs require the local `secrets.env`:

```bash
./tools/render-configs.py
```

## 9. Deploy with backup

Dry run first:

```bash
./tools/deploy.sh home
./tools/deploy.sh partner
./tools/deploy.sh ran
```

Then on the appropriate node:

```bash
sudo ./tools/deploy.sh home --apply
sudo ./tools/deploy.sh partner --apply
sudo ./tools/deploy.sh ran --apply
```

Every applied replacement is backed up under `/var/backups/virtual-mobile-telecom-lab/<timestamp>/`. Service restart is not automatic.

## 10. MongoDB subscriber

After `config/secrets.env` is populated:

```bash
./tools/provision-subscriber.py home
./tools/provision-subscriber.py partner
```

Review the dry-run, then:

```bash
./tools/provision-subscriber.py home --apply
./tools/provision-subscriber.py partner --apply
```

## 11. OsmoSTP

Partner is the baseline M3UA SG/listener. Home is the ASP/client. After deploying configs:

```bash
sudo systemctl restart osmo-stp
ss -anp -A sctp
```

Partner should listen on SCTP/2905; Home establishes toward Partner when an ASP connection is opened by the test tool/configuration.

## 12. RAN runtime

`tools/deploy.sh ran --apply` renders the private UE configs and copies `sib.conf`, `rr.conf`, `rb.conf` from the installed srsRAN example tree if available. Review the resulting files under `/opt/telecom-lab/runtime` before starting RAN.

## 13. First boot order

A stable sequence is:

```text
1. MongoDB
2. Home/Partner Open5GS control-plane NFs
3. Home/Partner UPF or LTE SGW-U according to selected mode
4. OsmoSTP
5. RAN gNB/eNB
6. UE
7. packet capture / validation
```

Do not try to start Home LTE and Home 5G external GTP-U at the same time.

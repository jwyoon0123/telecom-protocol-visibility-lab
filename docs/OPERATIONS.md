# Operations

Run commands from the repository root so `config/lab.env` can be loaded.

## Status

```bash
sudo -E home/home-lab.sh status
sudo -E partner/partner-lab.sh status
sudo -E ran/ran-lab.sh status
```

## SS7/MAP

Partner:

```bash
sudo -E partner/partner-lab.sh ss7
```

Home:

```bash
sudo -E home/home-lab.sh ss7
```

Expected wire stack:

```text
SCTP -> M3UA -> SCCP -> TCAP -> GSM MAP -> sendAuthenticationInfo
```

No HLR application response is required for the basic visibility acceptance test.

## Home LTE

Home core mode:

```bash
sudo -E home/home-lab.sh lte
```

Optional capture:

```bash
sudo -E home/home-lab.sh capture-lte
```

RAN:

```bash
sudo -E ran/ran-lab.sh home-lte start
```

Success criteria: S1AP, UE attach/IP and ping to Home gateway.

## Home 5G SA

```bash
sudo -E home/home-lab.sh 5g
sudo -E ran/ran-lab.sh home-5g start
sudo -E ran/ran-lab.sh home-5g ping
```

## Partner 5G SA

```bash
sudo -E ran/ran-lab.sh partner-5g start
sudo -E ran/ran-lab.sh partner-5g ping
```

Optional Partner capture:

```bash
sudo -E partner/partner-lab.sh capture-5g
```

## N32 transport

Start on both core nodes after deploying `sepp-lab.yaml`:

```bash
sudo -E home/home-lab.sh sepp start
sudo -E partner/partner-lab.sh sepp start
```

Peer reachability:

```bash
sudo -E home/home-lab.sh sepp check
sudo -E partner/partner-lab.sh sepp check
```

Capture:

```bash
sudo -E home/home-lab.sh sepp capture
```

This is transport visibility, not production TLS/PRINS validation.

## Diameter visibility

On Partner:

```bash
sudo -E partner/partner-lab.sh diameter
```

On Home:

```bash
sudo -E home/home-lab.sh diameter
```

The client sends CER and DWR; the server returns CEA and DWA with Result-Code 2001. This is intentionally synthetic and does not replace a full S6a implementation.

## Generic capture

```bash
sudo -E tools/capture.sh ss7
sudo -E tools/capture.sh lte
sudo -E tools/capture.sh 5g
sudo -E tools/capture.sh diameter
sudo -E tools/capture.sh n32
```

## Stop RAN

```bash
sudo -E ran/ran-lab.sh stop
```

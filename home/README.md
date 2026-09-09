# Home Core

역할: Open5GS LTE/5G Core, OsmoSTP ASP, SS7 MAP generator, Home SEPP.

Canonical entry point:

```bash
sudo -E ./home-lab.sh status
sudo -E ./home-lab.sh lte
sudo -E ./home-lab.sh 5g
sudo -E ./home-lab.sh ss7
```

`520-core-mode.sh`는 Home external UDP/2152 ownership을 LTE SGW-U와 5G UPF 사이에서 전환합니다.

See also: [`docs/CONFIGURATION_REFERENCE.md`](../docs/CONFIGURATION_REFERENCE.md) and [`docs/VALIDATION.md`](../docs/VALIDATION.md).

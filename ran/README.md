# RAN / UE

역할: srsRAN 4G LTE eNB/UE와 srsRAN Project 5G gNB + srsUE. RF hardware 대신 ZeroMQ를 사용합니다.

```bash
sudo -E ./ran-lab.sh home-lte start
sudo -E ./ran-lab.sh home-5g start
sudo -E ./ran-lab.sh partner-5g start
sudo -E ./ran-lab.sh stop
```

Home/Partner 5G는 같은 ZeroMQ port pair를 공유하므로 동시에 실행하지 않습니다.

See also: [`docs/CONFIGURATION_REFERENCE.md`](../docs/CONFIGURATION_REFERENCE.md) and [`docs/VALIDATION.md`](../docs/VALIDATION.md).

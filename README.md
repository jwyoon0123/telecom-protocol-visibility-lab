# Virtual Mobile Telecom Lab

**Home Core + Partner Core + software RAN/UE**로 SS7, LTE, 5G, GTP-U, N32 transport, Diameter visibility를 재현하는 폐쇄형 실습 환경입니다.

이 저장소는 특정 회사나 상용 보안제품에 종속되지 않는 **pre-product integration baseline**입니다. 공중 통신망, 실제 가입자 또는 허가되지 않은 네트워크에 사용하지 않습니다.

## Reference topology

```text
                         +----------------------+
                         |       RAN / UE       |
                         |     10.10.10.62      |
                         | srsRAN 4G + 5G/ZMQ   |
                         +----+------------+----+
                              |            |
             S1AP/NGAP/GTP-U  |            | NGAP/GTP-U
                              |            |
                     +--------v--+      +--v----------+
                     | Home Core |      | Partner Core|
                     |10.10.10.54|      |10.10.10.53  |
                     | Open5GS   |      | Open5GS     |
                     +-----+-----+      +------+------+ 
                           |                   ^
                           +-- SS7/M3UA 2905 --+
                           +-- N32 7778/7779 ---+
                           +-- Diameter 3868 ---+
```

| Flow | Transport | 검증 범위 |
|---|---|---|
| SS7/MAP | SCTP/2905 | M3UA, SCCP, TCAP, MAP `sendAuthenticationInfo` decode |
| Home LTE | SCTP/36412 + UDP/2152 | Attach, UE IP, Home gateway ping |
| Home 5G SA | SCTP/38412 + UDP/2152 | Registration, PDU Session, Home gateway ping |
| Partner 5G SA | SCTP/38412 + UDP/2152 | Registration, PDU Session, Partner gateway ping |
| N32 | TCP/7778,7779 | Open5GS SEPP transport reachability |
| Diameter | TCP/3868 | synthetic CER/CEA/DWR/DWA visibility |

## 반드시 알아야 할 제약

1. Home LTE와 Home 5G는 `Home-IP:2152/UDP`를 공유하여 **동시에 external GTP-U endpoint가 될 수 없습니다**.
2. Home 5G와 Partner 5G는 RAN VM의 ZeroMQ `2100/2101` pair를 공유하므로 **한 번에 한 profile**만 실행합니다.
3. SS7은 **Point Code + SSN 기반 baseline**입니다. production Global Title translation/HLR application response를 구현한 망이 아닙니다.
4. N32는 현재 HTTP transport lab이며 production TLS/PRINS security semantics를 의미하지 않습니다.
5. Diameter는 synthetic visibility test이며 실제 S6a roaming federation이 아닙니다.

## Quick start

```bash
git clone <YOUR_REPOSITORY_URL> virtual-mobile-telecom-lab
cd virtual-mobile-telecom-lab

cp config/lab.env.example config/lab.env
cp config/secrets.env.example config/secrets.env
chmod 600 config/secrets.env

# 공개 파일 검증
make check

# core/RAN config 생성
./tools/render-configs.py --public-only
# UE 테스트가 필요하면 secrets.env를 채운 후:
./tools/render-configs.py
```

실제 서버 적용은 자동 overwrite하지 않습니다.

```bash
# dry run
./tools/deploy.sh home
./tools/deploy.sh partner
./tools/deploy.sh ran

# 백업 후 실제 적용
sudo ./tools/deploy.sh home --apply
sudo ./tools/deploy.sh partner --apply
sudo ./tools/deploy.sh ran --apply
```

서비스 restart는 의도적으로 수동입니다. 자세한 절차는 [Installation](docs/INSTALLATION.md), [Operations](docs/OPERATIONS.md), [Configuration Reference](docs/CONFIGURATION_REFERENCE.md)를 참고하십시오.

## Canonical entry points

```bash
home/home-lab.sh
partner/partner-lab.sh
ran/ran-lab.sh
```

legacy repair/build script를 기본 운영 진입점으로 사용하지 않습니다.

## Repository layout

```text
config/       topology + local secret examples
home/         Home Core configs and validated wrappers
partner/      Partner Core configs and validated wrappers
ran/          LTE/5G RAN-UE configs and wrappers
tools/        rendering, deploy, validation, capture, Diameter/N32 helpers
docs/         architecture, installation, operation, validation, limitations
.github/      CI checks
```

## Validation and self-test

```bash
make check
```

`make check`는 shell/Python syntax, 공개정보/secret scan, template render/YAML validation, synthetic Diameter loopback self-test를 수행합니다. 실제 LTE/5G/SS7 E2E 판정은 live node에서 별도로 수행합니다.

## Public release

```bash
make check
make package
```

`tools/public-safety-scan.sh`는 secret/private-key/내부 hostname 패턴을 검사합니다. 조직 고유 명칭이나 내부 도메인은 `VMTL_DENY_REGEX`로 추가 검사할 수 있습니다. 공개 전에는 [Publication Checklist](docs/PUBLICATION_CHECKLIST.md)를 수동으로도 확인하십시오.

> Repository 라이선스는 자동으로 선택하지 않았습니다. 공개 전 [Licensing Decision](docs/LICENSING.md)을 확인하십시오. 기술 baseline과 공개용 정리 상태는 [Tested Baseline](docs/TESTED_BASELINE.md) 및 [Publication Checklist](docs/PUBLICATION_CHECKLIST.md)에 정리되어 있습니다.

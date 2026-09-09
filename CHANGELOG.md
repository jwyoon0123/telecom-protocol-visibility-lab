# Changelog

## 1.0.0 - 2026-09-09

- Home Core / Partner Core / RAN-UE 3-node lab 구조를 vendor-neutral 명칭으로 정리했습니다.
- SS7 baseline을 SCTP → M3UA → SCCP → TCAP → MAP `sendAuthenticationInfo` 검증 범위로 고정했습니다.
- Home LTE, Home 5G SA, Partner 5G SA 운영 wrapper와 packet capture 절차를 정리했습니다.
- Home LTE/5G UDP/2152 mode-switch와 RAN ZeroMQ 2100/2101 상호 배타 제약을 문서화했습니다.
- Open5GS/OsmoSTP/srsRAN 설정을 공개용 template + renderer 구조로 정리했습니다.
- subscriber K/OPc를 Git 외부의 `config/secrets.env`로 분리했습니다.
- synthetic Diameter CER/CEA/DWR/DWA visibility tool을 추가했습니다.
- Open5GS SEPP N32 transport start/status/check/capture wrapper를 추가했습니다.
- GitHub Actions CI, syntax check, public safety scan, release/package scripts를 추가했습니다.
- 회사명, 상표, 회사 도메인, 외부 보안제품 설정을 public tree에서 제거했습니다.
- runtime wrapper를 `lab.env` 기반으로 정리하고 core mode-switch 시 UPF 설정 백업을 추가했습니다.
- public configuration reference, tested-baseline 문서와 synthetic Diameter self-test를 추가했습니다.
- CI를 `make check` 단일 release gate로 통합했습니다.

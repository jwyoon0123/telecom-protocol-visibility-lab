# Contributing

변경은 다음 원칙을 따릅니다.

1. 실제 운영망이 아니라 private lab 주소와 synthetic subscriber만 사용합니다.
2. `config/secrets.env`와 generated private config는 commit하지 않습니다.
3. 새로운 protocol flow는 `docs/VALIDATION.md`에 성공 기준과 limitation을 같이 추가합니다.
4. 기존 canonical wrapper를 우회하는 repair/build script를 기본 운영 경로로 추가하지 않습니다.
5. Pull Request 전 `make check`를 통과시킵니다.

이 저장소에는 아직 별도 오픈소스 라이선스를 선택하지 않았습니다. 외부 공개/재배포 정책은 저장소 소유자가 결정해야 합니다.

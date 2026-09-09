# Manual Maintenance Rules

기존 실험 기록을 장기 유지보수용 문서로 바꿀 때 적용한 규칙입니다.

1. Home 역할에 회사명/상표를 사용하지 않습니다.
2. 상용 보안제품 연동은 이 public baseline과 분리합니다.
3. canonical wrapper를 문서 첫 경로로 두고 일회성 repair/build script는 제외합니다.
4. `SCTP/M3UA/SCCP/TCAP/MAP decode`와 `GT routing/HLR response`를 같은 완료 상태로 취급하지 않습니다.
5. synthetic Diameter와 full S6a를 구분합니다.
6. N32 transport와 TLS/PRINS security를 구분합니다.
7. port ownership/mode-switch 제약을 숨기지 않습니다.
8. subscriber secret은 local-only environment로 분리합니다.
9. release마다 exact host/application version inventory를 갱신합니다.
10. CI와 수동 publication checklist를 모두 통과시킵니다.

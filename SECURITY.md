# Security Policy

이 저장소는 폐쇄형 이동통신 실습망을 위한 자료입니다.

## 공개 저장소에 넣지 말아야 할 것

- 실제 가입자 IMSI/MSISDN과 인증키 K/OP/OPc
- 운영망 PCAP, CDR, 가입자 DB dump
- private key, token, password, shell history
- 회사 내부 hostname/domain/IP 계획
- 외부 상용 보안제품의 proprietary 설정/라이선스 파일

문제가 의심되면 commit/push 전에 다음을 실행하십시오.

```bash
make check
```

이미 secret을 push했다면 단순 삭제 commit만으로 충분하지 않습니다. 해당 secret을 폐기/교체하고 Git history에서도 제거해야 합니다.

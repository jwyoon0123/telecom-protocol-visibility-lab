# Pre-Product Integration Lab Manual

이 문서는 외부 보안제품을 연결하기 전의 **Home / Partner / RAN-UE** baseline을 정의합니다. 이후 어떤 IDS/FW/scanner를 연결하더라도 먼저 이 baseline을 독립적으로 통과시키는 것이 원칙입니다.

## 1. Baseline topology

```text
Home Core      10.10.10.54
Partner Core   10.10.10.53
RAN/UE         10.10.10.62
```

Home PLMN `00101`, Partner PLMN `00102`, Home PC `1.1.1`, Partner PC `2.2.2`를 synthetic reference identifier로 사용합니다.

## 2. Acceptance gates

### Gate A — IP

세 노드 간 IP reachability가 있어야 합니다.

### Gate B — SS7

Partner가 SCTP/2905 M3UA SG로 동작하고 Home이 MAP frame을 보냅니다. PCAP에서 `SCTP → M3UA → SCCP → TCAP → MAP`가 decode되어야 합니다.

### Gate C — Home LTE

Home SGW-U가 external UDP/2152를 소유하고 RAN eNB/UE가 S1AP attach 및 Home gateway ping을 성공해야 합니다.

### Gate D — Home 5G

Home UPF가 external UDP/2152를 소유하고 gNB/UE가 N2 registration, PDU Session, Home gateway ping을 성공해야 합니다.

### Gate E — Partner 5G

Partner AMF/UPF에 대해 동일한 registration/PDU/user-plane 검증을 수행합니다.

### Gate F — N32 transport

Home/Partner SEPP가 TCP/7778,7779에 bind되고 상호 reachability가 있어야 합니다.

### Gate G — Diameter visibility

Partner TCP/3868 synthetic peer와 Home client 사이에서 CER/CEA/DWR/DWA가 decode되어야 합니다.

## 3. What this baseline does not prove

- SS7 production GT translation or full HLR/VLR behavior
- complete roaming subscriber/business logic
- real S6a roaming federation
- production SEPP TLS/PRINS security
- external sensor visibility for traffic that never leaves loopback

## 4. Canonical commands

```bash
# SS7
partner/partner-lab.sh ss7
home/home-lab.sh ss7

# LTE
home/home-lab.sh lte
ran/ran-lab.sh home-lte start

# Home 5G
home/home-lab.sh 5g
ran/ran-lab.sh home-5g start

# Partner 5G
ran/ran-lab.sh partner-5g start

# N32
home/home-lab.sh sepp start
partner/partner-lab.sh sepp start

# Diameter synthetic visibility
partner/partner-lab.sh diameter
home/home-lab.sh diameter
```

## 5. Integration rule

외부 보안제품 연동 후 문제가 생기면 먼저 product path를 우회한 baseline을 다시 통과시키십시오. baseline이 정상인데 product path에서만 실패하면 제품 연동/정책/주소 모델을 조사합니다. baseline 자체가 실패하면 Home/Partner/RAN 설정을 먼저 복구합니다.

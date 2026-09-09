# Troubleshooting

## 1. Network first

```bash
ip -4 -br addr
ip route
ping -c 2 <peer-ip>
```

## 2. SCTP

```bash
modprobe sctp
ss -anp -A sctp
cat /proc/net/sctp/assocs 2>/dev/null || true
```

Key ports:

```text
2905   SS7/M3UA
36412  LTE S1AP
38412  5G NGAP
```

## 3. UDP

```bash
ss -lunp | grep -E ':(2152|8805)\b'
```

If Home `:2152` is owned by the wrong process, switch mode with `home/home-lab.sh lte` or `home/home-lab.sh 5g` instead of starting both.

## 4. RAN ZeroMQ

```bash
ss -lntp | grep -E ':(2000|2001|2100|2101)\b'
pgrep -af 'srsenb|srsue|gnb'
```

Stop the previous RAN profile before switching Home/Partner 5G.

## 5. SS7 decode

Capture first, then decode:

```bash
tcpdump -ni eth0 -s0 -w /tmp/ss7.pcap 'sctp port 2905'
tshark -r /tmp/ss7.pcap -d sctp.ppi==3,m3ua -Y 'm3ua || sccp || tcap || gsm_map'
```

An M3UA or application error after a valid MAP frame does not erase the fact that the protocol visibility path worked; classify transport, decode and application response separately.

## 6. `tshark` permission/AppArmor

If root can read a PCAP with `tcpdump -r` but `tshark -r` receives permission denial, inspect local AppArmor/LSM policy before modifying file ownership.

## 7. SEPP

```bash
home/home-lab.sh sepp status
home/home-lab.sh sepp check
partner/partner-lab.sh sepp status
partner/partner-lab.sh sepp check
```

## 8. Diameter

If CER is sent but no CEA arrives:

```bash
ss -lntp | grep 3868
tcpdump -ni eth0 -nn -vv 'tcp port 3868'
```

The included visibility tool uses TCP. Do not infer freeDiameter/S6a health from this synthetic test.

#!/usr/bin/env python3
"""Generate the validated SS7 MAP sendAuthenticationInfo visibility frame.

This is a private-lab packet generator, not a full HLR implementation.
"""
import os
import sys
import time

BASE = os.environ.get("SS7SIM_BASE", "/opt/telecom-lab/ss7simulator")
sys.path.insert(0, BASE)

from ss7sim.transport import sctp
from ss7sim.m3ua import codec as m3ua_codec
from ss7sim.stack import encoder
from ss7sim.sccp.address import SccpAddress

HOST = os.environ.get("PARTNER_IP", "10.10.10.53")
PORT = int(os.environ.get("SS7_PORT", "2905"))
LOCAL = [os.environ.get("HOME_IP", "10.10.10.54")]
HOME_PC = int(os.environ.get("HOME_PC", "2057"))
PARTNER_PC = int(os.environ.get("PARTNER_PC", "4114"))
HLR_SSN = int(os.environ.get("SS7_HLR_SSN", "6"))
HOME_PC_LABEL = os.environ.get("HOME_PC_DOTTED", str(HOME_PC))
PARTNER_PC_LABEL = os.environ.get("PARTNER_PC_DOTTED", str(PARTNER_PC))
IMSI = os.environ.get("HOME_IMSI", "001010000000001")

CDPA = SccpAddress(pc=PARTNER_PC, ssn=HLR_SSN, route_on_ssn=True)
CGPA = SccpAddress(pc=HOME_PC, ssn=HLR_SSN, route_on_ssn=True)

print("=================================")
print(" SS7 MAP VISIBILITY TEST")
print("=================================")
print(f"Peer : {HOST}:{PORT}")
print(f"OPC  : {HOME_PC} ({HOME_PC_LABEL})")
print(f"DPC  : {PARTNER_PC} ({PARTNER_PC_LABEL})")
print(f"SSN  : {HLR_SSN}")

print("[1] SCTP connect")
a = sctp.connect(HOST, PORT, timeout=5, local_addrs=LOCAL)

print("[2] M3UA ASPUP")
a.send(m3ua_codec.encode_aspup())
r = a.recv(timeout=3)
if not r:
    raise SystemExit("[FAIL] ASPUP_ACK timeout")
m = m3ua_codec.decode(r)
print("[RX] class=", m.msg_class, "type=", m.msg_type)

print("[3] M3UA ASPAC")
a.send(m3ua_codec.encode_aspac())
r = a.recv(timeout=3)
if not r:
    raise SystemExit("[FAIL] ASPAC_ACK timeout")
m = m3ua_codec.decode(r)
print("[RX] class=", m.msg_class, "type=", m.msg_type)
print("[OK] M3UA ACTIVE")

print("[4] Build MAP sendAuthenticationInfo")
frame = encoder.build_map_begin(
    "sendAuthenticationInfo",
    opc=HOME_PC,
    dpc=PARTNER_PC,
    cdpa=CDPA,
    cgpa=CGPA,
    imsi=IMSI,
    num_vectors=1,
)
print("Frame length:", len(frame))

print("[5] Send SCCP/TCAP/MAP")
a.send(frame)
print("[OK] MAP frame sent")
time.sleep(2)

print("[6] Try application response")
try:
    r = a.recv(timeout=2)
    print(f"[RX] {len(r)} bytes" if r else "[INFO] no response")
except Exception as exc:
    print("[INFO] no application response:", exc)
finally:
    a.close()
print("[DONE] MAP transmission completed")

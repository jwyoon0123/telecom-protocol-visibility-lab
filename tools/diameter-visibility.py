#!/usr/bin/env python3
"""Minimal synthetic Diameter CER/CEA + DWR/DWA visibility tool for a private lab."""
import argparse, os, random, socket, struct, sys, time

R=0x80
AVP_MANDATORY=0x40

def pad4(n): return (4-(n%4))%4

def avp(code, data, flags=AVP_MANDATORY, vendor=None):
    hdr_len=12 if vendor is not None else 8
    if vendor is not None: flags |= 0x80
    length=hdr_len+len(data)
    h=struct.pack('!I',code)+bytes([flags])+length.to_bytes(3,'big')
    if vendor is not None: h+=struct.pack('!I',vendor)
    return h+data+(b'\x00'*pad4(length))

def avp_u32(code, value): return avp(code, struct.pack('!I', value))
def avp_utf8(code, value): return avp(code, value.encode())
def avp_addr(code, ip): return avp(code, struct.pack('!H',1)+socket.inet_aton(ip))

def message(cmd, request, avps, app=0, hop=None, end=None):
    hop = random.getrandbits(32) if hop is None else hop
    end = random.getrandbits(32) if end is None else end
    body=b''.join(avps)
    length=20+len(body)
    flags=R if request else 0
    head=bytes([1])+length.to_bytes(3,'big')+bytes([flags])+cmd.to_bytes(3,'big')+struct.pack('!III',app,hop,end)
    return head+body

def read_exact(sock,n):
    b=b''
    while len(b)<n:
        x=sock.recv(n-len(b))
        if not x: raise EOFError
        b+=x
    return b

def recv_msg(sock):
    h=read_exact(sock,20)
    length=int.from_bytes(h[1:4],'big')
    body=read_exact(sock,length-20)
    return h+body

def parse(data):
    if len(data)<20: raise ValueError('short Diameter message')
    length=int.from_bytes(data[1:4],'big'); flags=data[4]; cmd=int.from_bytes(data[5:8],'big')
    app,hop,end=struct.unpack('!III',data[8:20]); pos=20; avps=[]
    while pos+8<=min(length,len(data)):
        code=struct.unpack('!I',data[pos:pos+4])[0]; fl=data[pos+4]; ln=int.from_bytes(data[pos+5:pos+8],'big')
        if ln<8 or pos+ln>len(data): break
        off=12 if fl&0x80 else 8
        payload=data[pos+off:pos+ln]
        avps.append((code,payload))
        pos += ln + pad4(ln)
    return {'request':bool(flags&R),'cmd':cmd,'app':app,'hop':hop,'end':end,'avps':avps}

def get_utf8(m, code):
    for c,p in m['avps']:
        if c==code:
            try:return p.decode()
            except:return p.hex()
    return None

def get_u32(m, code):
    for c,p in m['avps']:
        if c==code and len(p)>=4:return struct.unpack('!I',p[:4])[0]
    return None

def describe(m):
    names={257:'Capabilities-Exchange',280:'Device-Watchdog'}
    return f"{names.get(m['cmd'],str(m['cmd']))} {'Request' if m['request'] else 'Answer'} origin={get_utf8(m,264)} realm={get_utf8(m,296)} result={get_u32(m,268)}"

def common(origin_host, origin_realm, local_ip):
    return [avp_utf8(264,origin_host),avp_utf8(296,origin_realm),avp_addr(257,local_ip),avp_u32(266,0),avp_utf8(269,'Virtual-Mobile-Telecom-Lab'),avp_u32(265,10415),avp_u32(258,16777251)]

def answer_for(req, origin_host, origin_realm, local_ip):
    base=[avp_u32(268,2001)]+common(origin_host,origin_realm,local_ip)
    return message(req['cmd'],False,base,app=req['app'],hop=req['hop'],end=req['end'])

def run_server(a):
    s=socket.socket(); s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1); s.bind((a.bind,a.port)); s.listen(5)
    print(f'LISTEN {a.bind}:{a.port}',flush=True)
    while True:
        c,peer=s.accept(); print('ACCEPT',peer,flush=True)
        with c:
            c.settimeout(a.timeout)
            try:
                while True:
                    raw=recv_msg(c); m=parse(raw); print('RX',describe(m),flush=True)
                    if m['request'] and m['cmd'] in (257,280):
                        resp=answer_for(m,a.origin_host,a.origin_realm,a.bind); c.sendall(resp); print('TX',describe(parse(resp)),flush=True)
            except (EOFError,socket.timeout,ConnectionResetError):
                print('CLOSE',peer,flush=True)

def run_client(a):
    s=socket.create_connection((a.host,a.port),timeout=a.timeout); s.settimeout(a.timeout)
    with s:
        cer=message(257,True,common(a.origin_host,a.origin_realm,a.bind)); s.sendall(cer); print('TX',describe(parse(cer)))
        cea=parse(recv_msg(s)); print('RX',describe(cea))
        if get_u32(cea,268)!=2001: raise SystemExit('CEA Result-Code is not 2001')
        for _ in range(a.watchdogs):
            dwr=message(280,True,[avp_utf8(264,a.origin_host),avp_utf8(296,a.origin_realm)]); s.sendall(dwr); print('TX',describe(parse(dwr)))
            dwa=parse(recv_msg(s)); print('RX',describe(dwa))
            if get_u32(dwa,268)!=2001: raise SystemExit('DWA Result-Code is not 2001')
            time.sleep(a.interval)
    print('DIAMETER VISIBILITY TEST = DONE')

def main():
    ap=argparse.ArgumentParser(); sub=ap.add_subparsers(dest='mode',required=True)
    sv=sub.add_parser('server'); sv.add_argument('--bind',required=True); sv.add_argument('--port',type=int,default=3868); sv.add_argument('--origin-host',default='diameter-partner.lab.invalid'); sv.add_argument('--origin-realm',default='lab.invalid'); sv.add_argument('--timeout',type=float,default=30)
    cl=sub.add_parser('client'); cl.add_argument('--host',required=True); cl.add_argument('--bind',required=True); cl.add_argument('--port',type=int,default=3868); cl.add_argument('--origin-host',default='diameter-home.lab.invalid'); cl.add_argument('--origin-realm',default='lab.invalid'); cl.add_argument('--timeout',type=float,default=5); cl.add_argument('--watchdogs',type=int,default=2); cl.add_argument('--interval',type=float,default=.3)
    a=ap.parse_args(); run_server(a) if a.mode=='server' else run_client(a)
if __name__=='__main__': main()

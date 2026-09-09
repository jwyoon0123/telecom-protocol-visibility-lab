#!/usr/bin/env python3
import argparse
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]

def envfile(path):
    out={}
    if path.exists():
        for line in path.read_text().splitlines():
            line=line.strip()
            if line and not line.startswith('#') and '=' in line:
                k,v=line.split('=',1); out[k]=v.strip().strip('"').strip("'")
    return out

ap=argparse.ArgumentParser()
ap.add_argument('role', choices=['home','partner'])
ap.add_argument('--mongo-uri', default='mongodb://127.0.0.1:27017')
ap.add_argument('--database', default='open5gs')
ap.add_argument('--apply', action='store_true')
args=ap.parse_args()

cfg=envfile(REPO/'config/lab.env.example'); cfg.update(envfile(REPO/'config/lab.env'))
sec=envfile(REPO/'config/secrets.env')
role=args.role.upper()
for key in [f'{role}_IMSI', f'{role}_K', f'{role}_OPC']:
    if not sec.get(key) or sec[key].startswith('REPLACE_WITH_'):
        raise SystemExit(f'Missing real lab value in config/secrets.env: {key}')

imsi=sec[f'{role}_IMSI']; k=sec[f'{role}_K']; opc=sec[f'{role}_OPC']
if len(k)!=32 or len(opc)!=32:
    raise SystemExit('K and OPc must be 32 hex characters')
subnet = cfg[f'{role}_UE_SUBNET']

doc={
 'schema_version':1,'imsi':imsi,'msisdn':[],'imeisv':[],'mme_host':[],
 'mm_realm':[],'purge_flag':[],
 'slice':[{'sst':int(cfg.get('SST','1')),'default_indicator':True,'session':[{
   'name':cfg.get('DNN','internet'),'type':3,
   'qos':{'index':9,'arp':{'priority_level':8,'pre_emption_capability':1,'pre_emption_vulnerability':2}},
   'ambr':{'downlink':{'value':1000000000,'unit':0},'uplink':{'value':1000000000,'unit':0}},
   'pcc_rule':[]}]}],
 'security':{'k':k,'op':None,'opc':opc,'amf':'8000'},
 'ambr':{'downlink':{'value':1000000000,'unit':0},'uplink':{'value':1000000000,'unit':0}},
 'access_restriction_data':32,'network_access_mode':0,'subscriber_status':0,
 'operator_determined_barring':0,'subscribed_rau_tau_timer':12
}

print(f'role={args.role} imsi={imsi} database={args.database} ue_subnet={subnet}')
if not args.apply:
    print('DRY RUN. Add --apply to upsert into MongoDB.')
    raise SystemExit(0)

from pymongo import MongoClient
client=MongoClient(args.mongo_uri, serverSelectionTimeoutMS=3000)
col=client[args.database].subscribers
col.replace_one({'imsi':imsi}, doc, upsert=True)
print('subscriber upserted')

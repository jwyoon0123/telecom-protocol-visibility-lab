# Partner Core

## Role

Partner Core runs:
- **Open5GS Partner 5GC** – Partner network's 5G core (roaming/federation scenario)
- **OsmoSTP M3UA SG/Listener** – SIGTRAN signaling gateway for SS7
- **Partner SEPP** – Security Edge Protection Proxy for N32 inter-PLMN signaling
- **Synthetic Diameter Server** – Simulates S6a/S6d roaming messages

---

## Quick Start

### View Status

```bash
sudo -E ./partner-lab.sh status
```

### Run SS7 Gateway

```bash
sudo -E ./partner-lab.sh ss7
```

Starts OsmoSTP as the M3UA signaling gateway. Listens on SCTP/2905 for connections from Home Core.

### Run Synthetic Diameter Server

```bash
sudo -E ./partner-lab.sh diameter
```

Starts a synthetic Diameter server that:
- Accepts CER (Capabilities Exchange Request)
- Responds with CEA (Capabilities Exchange Answer)
- Echoes DWR (Device Watchdog Request) with DWA (Device Watchdog Answer)
- Provides basic S6a message visibility

---

## Configuration

Configuration files are auto-generated from templates. Key files:

- `open5gs-config/` – Open5GS 5G core configuration for Partner network
- `osmo-config/` – OsmoSTP M3UA signaling gateway configuration
- `sepp-config/` – SEPP configuration for N32 inter-PLMN signaling
- `diameter-server/` – Diameter server implementation

Modify template sources in `config/` directory, then regenerate:

```bash
./tools/render-configs.py
```

---

## Inter-Network Connections

### SS7/M3UA Connection (to Home Core)

- **Protocol:** M3UA over SCTP
- **Port:** SCTP/2905
- **Address:** Partner listens on 10.10.10.53:2905
- **Purpose:** Exchange SS7 MAP messages for authentication and HLR queries

### N32 Connection (to Home SEPP)

- **Protocol:** HTTP (in this lab; production uses TLS)
- **Ports:** TCP/7778 (inbound), TCP/7779 (outbound)
- **Address:** Partner listens on 10.10.10.53:7778
- **Purpose:** Inter-PLMN security signaling

### Diameter Connection (to Home or external)

- **Protocol:** Diameter
- **Port:** TCP/3868
- **Address:** Partner listens on 10.10.10.53:3868
- **Purpose:** S6a/S6d roaming federation messages

---

## Logs and Debugging

### View Real-Time Logs

```bash
# Open5GS logs
tail -f /var/log/open5gs/open5gs.log

# OsmoSTP logs
tail -f /var/log/osmoSTP/osmo-stp.log

# Diameter server logs
tail -f /var/log/diameter-server/diameter.log

# SEPP logs
tail -f /var/log/sepp/sepp.log
```

### Capture Network Traffic

```bash
sudo tcpdump -i eth0 -w partner-traffic.pcap
```

Then analyze with Wireshark or other packet analysis tools.

---

## Related Documentation

- **[CONFIGURATION_REFERENCE](../docs/CONFIGURATION_REFERENCE.md)** – Detailed config parameters
- **[OPERATIONS](../docs/OPERATIONS.md)** – Operational procedures
- **[VALIDATION](../docs/VALIDATION.md)** – Testing and verification methods

---

## Troubleshooting

### Diameter Server Not Responding

Check if it's listening:

```bash
netstat -tlnp | grep 3868
```

If not listening, check logs for errors:

```bash
tail -f /var/log/diameter-server/diameter.log
```

### SS7 Connection Not Established

Verify OsmoSTP is running:

```bash
sudo -E ./partner-lab.sh status
```

Check firewall rules:

```bash
sudo iptables -L -n | grep 2905
```

### Port Conflicts

If ports are already in use:

```bash
lsof -i :2905
lsof -i :3868
lsof -i :7778
sudo kill -9 <PID>
```

---

## Notes

- Partner Core typically runs on a separate VM from Home Core.
- Diameter server is synthetic for lab purposes; it doesn't implement full S6a/S6d logic.
- N32 in this lab is HTTP only; production systems use TLS with mutual authentication.
- Some operations require `sudo` privilege.

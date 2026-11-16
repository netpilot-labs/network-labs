# Router swap rehearsal: a new Arista edge floods a Cisco OSPF core, then CoPP and an edge filter contain it

Rehearse a site router replacement before the window. Three Cisco IOL routers are the existing core on OSPF area 0, with a Linux host on two of them. An Arista cEOS router takes over one site, linked to two of the core routers. A host behind it plays a planted misconfiguration: TCP connection attempts to port 179 on the core's addresses at a rate you set. You measure the core's CPU, OSPF neighbors and ping loss before and during the flood, trace the flooding site, then contain it with control plane policing on the Cisco routers and an inbound filter on the Arista edge.

![R1, R2 and R3 (Cisco IOL) form an OSPF area 0 triangle. host-a hangs off R1 and host-b off R2. EDGE (Arista cEOS, the replacement) links to R1 and R3, and flood-host sits on EDGE's LAN sending a TCP 179 flood](topology.png)

| Item | Value |
|---|---|
| Core links | R1 to R2 10.0.12.0/30, R2 to R3 10.0.23.0/30, R1 to R3 10.0.13.0/30, point-to-point OSPF |
| Edge links | R1 Ethernet1/0 to EDGE Ethernet1/1 10.0.14.0/30, R3 Ethernet0/3 to EDGE Ethernet1/2 10.0.34.0/30 |
| Loopbacks | R1 10.255.0.1, R2 10.255.0.2, R3 10.255.0.3, EDGE 10.255.0.4 |
| Host LANs | host-a 10.0.1.10/24 on R1, host-b 10.0.2.10/24 on R2, flood-host 10.0.4.10/24 on EDGE |
| Routing | OSPF area 0 everywhere, host LANs passive |
| The flood | `flood.py <rate>`: non-blocking TCP connects to port 179 on the six core addresses, paced to the rate |

## Run it

```bash
sudo containerlab deploy -t router-swap-flood.clab.yml
sudo docker cp flood.py clab-router-swap-flood-flood-host:/tmp/flood.py
```

The routers load their startup configs at deploy and the hosts get their addresses from the `exec` lines. Give OSPF about a minute to reach FULL on all five adjacencies.

## Measure, flood, trace, contain

```bash
# baseline: a ping five times a second across the core, and the core's CPU and neighbors
docker exec clab-router-swap-flood-host-a ping -D -i 0.2 10.0.2.10
# on R1, R2 and R3: show processes cpu | include CPU utilization
#                   show ip ospf neighbor

# the planted misconfiguration, 250 attempts a second (try 5000 and 20000 next)
docker exec -d clab-router-swap-flood-flood-host python3 /tmp/flood.py 250

# trace it on R1: input rate per interface, then a counting ACL scoped to the suspect site
# show interfaces | include line protocol|input rate
# ip access-list extended DETECT
#  permit tcp 10.0.4.0 0.0.0.255 any eq bgp
#  permit ip any any
# interface Ethernet1/0
#  ip access-group DETECT in
```

Then apply `controls/copp-cisco.txt` on the three Cisco routers and `controls/edge-filter-arista.txt` on EDGE, and read the counters: `show policy-map control-plane input class CM-TCP179` on Cisco, `show ip access-lists EDGE-IN` on Arista. Measure the same three things again.

Set your own password where the Arista config reads `<set-a-password>` before you deploy: a cEOS startup config replaces containerlab's default one, login included. The Cisco nodes keep containerlab's default login. You bring the Arista cEOS and Cisco IOL images yourself: the [Arista](../../arista/README.md) and [Cisco](../../cisco/README.md) READMEs say where to get them. The network-multitool hosts are a public image.

## Build it from one prompt

[Router swap flood rehearsal](https://github.com/netpilot-labs/example-prompts/blob/main/change-validation/router-swap-flood-rehearsal.md) builds this lab and runs every step above from one plain-English prompt in NetPilot. The run, its numbers and a cutover checklist: [FAA ground stop: the router swap flood, rebuilt in a lab](https://www.netpilot.io/blog/faa-ground-stop-router-swap-lab).

## Tested on

The recorded NetPilot run on 2026-11-15, on a 16 vCPU lab VM: Cisco IOL 17.12.1, Arista cEOS 4.36.1F and network-multitool (the `latest` tag that day).

- Baseline: 5 OSPF adjacencies FULL, core CPU 0 %, host-a to host-b 188 replies with no loss
- 250 attempts a second: core CPU 1 % or under, OSPF unchanged, ping 221 of 221
- The trace: the counting ACL matched 2,967 packets from 10.0.4.0/24 and R1's EDGE uplink carried the input, about a minute from start to the named site
- CoPP at 250 a second: about 82 % of the TCP 179 packets dropped on each router, the edge filter then dropped 2,626 at the source
- No controls, 5,000 and 20,000 attempted: core CPU 6 to 8 %, all of it in IP Input, OSPF FULL and no ping lost
- 20,000 attempted delivered about 6,447 a second to the core (one sender caps the packets on the wire). CoPP alone dropped 99.4 % of them, core CPU 0 %, ping 169 of 169

The flood alone did not take this core down, at any rate the run could deliver. What a rehearsal like this gives you is the proof for your own oldest box, the counters that name the flooding site, and the two controls tested before the window.

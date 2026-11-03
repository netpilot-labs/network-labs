# 02 EVPN-VXLAN spine and leaf

One vJunos-router spine, two vJunos-switch leaves and a Linux host on each leaf. OSPF area 0 is the underlay, iBGP in AS 65000 carries EVPN with the spine as route reflector, and VLAN 10 maps to VXLAN VNI 10010 on both leaves. The two hosts share one subnet, so their ping crosses VXLAN.

```
                  spine1 (vJunos-router)  lo0 10.255.0.1
                  ge-0/0/0          ge-0/0/1
               10.0.11.1/30        10.0.12.1/30
                    |                    |
               10.0.11.2/30        10.0.12.2/30
                  ge-0/0/0          ge-0/0/0
leaf1 (vJunos-switch) lo0 10.255.0.11    leaf2 (vJunos-switch) lo0 10.255.0.12
                  ge-0/0/1          ge-0/0/1
                    |  VLAN 10 access   |
                  host1                host2
             192.168.10.11/24      192.168.10.12/24
```

The three startup configs are the ones from our recorded run, unchanged. The spine has no EVPN instance: it reflects `family evpn signaling` between the leaves with `cluster 10.255.0.1`. Each leaf uses `vtep-source-interface lo0.0`, route distinguisher `<loopback>:1` and `vrf-target target:65000:10010`. Fabric links run MTU 9000.

Build this from one prompt in NetPilot with the [Juniper EVPN-VXLAN prompt](https://github.com/netpilot-labs/example-prompts/blob/main/data-center/juniper-evpn-vxlan-vjunos.md), or deploy these files on your own host.

## Requirements

- containerlab, a Linux host with Docker and KVM (nested virtualization on if the host is a VM)
- 4 vCPU and 5 GiB of memory per vJunos node: 12 vCPU and 15 GiB for this lab, plus room for the hosts
- vJunos-router and vJunos-switch images, which you bring yourself. Build both with [vrnetlab](https://github.com/srl-labs/vrnetlab) as the [repository README](../README.md) shows (`juniper/vjunosrouter` and `juniper/vjunosswitch`). The lab uses `vrnetlab/juniper_vjunos-router:26.2R1.7` and `vrnetlab/juniper_vjunos-switch:26.2R1.7`.

## Run the lab

```bash
git clone https://github.com/netpilot-labs/juniper-labs
cd juniper-labs/02-evpn-vxlan-spine-leaf
sudo containerlab deploy -t evpn-vxlan-spine-leaf.clab.yml
```

Deploy returns in seconds, then the switches boot. Plan for 40 to 50 minutes. A node that reads `healthy` is not ready yet: poll `show chassis fpc 0` on each one until it reads `Online`. Before that, `show interfaces ge-0/0/0 terse` answers `error: device ge-0/0/0 not found`, which is the line card still booting, not a fault.

Sign in with `ssh admin@clab-junos-evpn-vxlan-01-leaf1`, password `admin@123` (the containerlab default). Run host commands with `docker exec clab-junos-evpn-vxlan-01-host1 ping -c 5 192.168.10.12`.

```bash
sudo containerlab destroy -t evpn-vxlan-spine-leaf.clab.yml --cleanup
```

## Check each layer

| Layer | Where | Command | What we read |
|---|---|---|---|
| OSPF underlay | spine1 | `show ospf neighbor` | 2 neighbors, both `Full` |
| Leaf loopbacks | spine1 | `show route protocol ospf terse` | 10.255.0.11/32 and 10.255.0.12/32 |
| BGP EVPN overlay | spine1 | `show bgp summary` | 2 peers `Establ`, 6 routes in `bgp.evpn.0` (3 per leaf) |
| Remote VTEP | leaf1 | `show ethernet-switching vxlan-tunnel-end-point remote` | 10.255.0.12, VNID 10010 |
| Remote MAC | leaf1 | `show evpn database` | host2's MAC from 10.255.0.12, IP 192.168.10.12 |
| Data plane | host1 | `ping -c 5 192.168.10.12` | 5 of 5, 0% loss |

The leaves print `Warning: License key missing; requires 'BGP' license` on `show bgp summary`. The sessions come up anyway.

The full walkthrough with the real output is in the [Juniper EVPN-VXLAN lab tutorial](https://www.netpilot.io/blog/juniper-evpn-vxlan-lab), and the build is on video: [Juniper EVPN-VXLAN Lab After vLabs: OSPF + BGP EVPN on Real Junos](https://www.youtube.com/watch?v=dpwCRpUGD1E).

## What we measured

On a 16 vCPU cloud VM with nested virtualization, vJunos-router and vJunos-switch 26.2R1.7, minutes after the deploy:

| Event | Minutes |
|---|---|
| First node `healthy` (leaf2) | 22.7 |
| leaf2 `ge-0/0/0 not found`, FPC 0 `Present` | 27.8 to 29.5 |
| leaf2 FPC 0 `Online` | 30.6 |
| leaf2 uplink `up up` | 32.4 |
| All three nodes `healthy` | 39.3 |
| Last line card `Online` (leaf1) | 47.0 |
| First ping from host1 to host2, 5 of 5 | 47.2 |

The run in NetPilot pinned a management subnet for the lab. This file leaves management addressing to containerlab's default.

# SONiC EVPN-VXLAN with an L2 VNI

One spine and two leaves with an eBGP underlay and a BGP EVPN overlay. VLAN 100 on each leaf maps to VNI 10100, so the two hosts share one subnet across the fabric. Each switch configures itself at deploy from its script in `configs/`.

![spine (SONiC, AS 65000) links to leaf1 (SONiC, AS 65001, VTEP 10.1.1.1) and leaf2 (SONiC, AS 65002, VTEP 10.1.1.2). host1 (Linux host, 192.168.100.11) on leaf1, host2 (Linux host, 192.168.100.12) on leaf2, VLAN 100 on VNI 10100](topology.png)

## Run it

```bash
sudo containerlab deploy -t evpn-l2vni.clab.yml
docker exec clab-sonic-evpn-host1 ping -c 3 192.168.100.12
docker exec clab-sonic-evpn-leaf1 show vxlan remotemac all
docker exec clab-sonic-evpn-leaf1 vtysh -c 'show bgp l2vpn evpn route type macip'
```

After the ping, leaf1 lists host2's MAC behind remote VTEP 10.1.1.2, learned from the type-2 route. The image and memory notes are in the [SONiC README](../README.md).

## Build it from one prompt

[The prompt](https://github.com/netpilot-labs/example-prompts/blob/main/data-center/sonic-evpn-vxlan-l2vni.md) builds the same fabric in [NetPilot](https://www.netpilot.io/sonic-nos-lab) and runs the verification command after each step.

## Tutorial

[Learn VXLAN EVPN on SONiC](https://www.netpilot.io/solutions/learn-vxlan-evpn-sonic)

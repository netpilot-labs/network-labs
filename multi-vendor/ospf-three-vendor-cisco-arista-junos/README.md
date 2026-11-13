# Multi-vendor OSPF lab: Cisco, Arista and Junos in area 0

Three routers from three vendors in a line, every link and loopback in OSPF area 0. The Arista router in the middle has two FULL neighbors, the Cisco and Junos routers one each, and the loopbacks reach each other end to end.

```
R1 Cisco IOL ---- 10.0.12.0/30 ---- R2 Arista cEOS ---- 10.0.23.0/30 ---- R3 Junos (cRPD)
Lo0 1.1.1.1/32                      Lo0 2.2.2.2/32                       lo0 3.3.3.3/32
Ethernet0/1 .1                      Ethernet1/1 .2, Ethernet1/2 .1       eth1 .2
```

## Run it

```bash
sudo containerlab deploy -t ospf-three-vendor.clab.yml
```

All three routers load their startup configs at deploy. Check it:

```bash
docker exec clab-ospf-three-vendor-R2 Cli -c 'show ip ospf neighbor'
docker exec clab-ospf-three-vendor-R3 cli -c 'show ospf neighbor'
docker exec clab-ospf-three-vendor-R3 cli -c 'show route protocol ospf'
```

On R1, `show ip ospf neighbor` and `ping 3.3.3.3 source 1.1.1.1 repeat 5` over SSH or the console. The Cisco router takes a little longer to boot than the other two, so give the R1 to R2 adjacency a moment before the ping.

One detail that stops this lab when it is built by hand: the Junos router (cRPD) takes its MTU from the container link, larger than the 1500 the Cisco and Arista routers use, and an OSPF MTU mismatch keeps the adjacency from reaching FULL. R3 sets `mtu 1500` on eth1 and R2 sets `mtu 1500` on Ethernet1/2. Every link runs OSPF point-to-point, and R3's loopback is passive.

Set your own passwords where the configs read `<set-a-password>` before you deploy. You bring all three images yourself: the [Cisco](../../cisco/README.md), [Arista](../../arista/README.md) and [Juniper](../../juniper/README.md) READMEs say where to get them. cRPD runs OSPF with no license, while BGP on cRPD needs a Juniper license.

## Tested on

The recorded NetPilot run on 2026-11-11, built from one ChatGPT prompt: Cisco IOL 17.12.1, Arista cEOS 4.36.1F and Juniper cRPD 23.2R1.13. R2 read two neighbors FULL, R1 and R3 one each, R3 learned 1.1.1.1/32 and 2.2.2.2/32 through OSPF, and the ping from 1.1.1.1 to 3.3.3.3 got 5 of 5 replies.

Changes from the run, for portability: the lab is renamed from `three-vendor-ospf-line-20261111` to `ospf-three-vendor`, the fixed management subnet and addresses are dropped (containerlab picks its default), the startup-config paths point at `configs/` (kept as `.partial` files, so containerlab merges them into its default management and SSH setup, as the run did), and the two lab passwords are replaced by a placeholder. The run deployed the original files: these portability edits were not redeployed as a package.

## Build it from one prompt

[The prompt](https://github.com/netpilot-labs/example-prompts/blob/main/multi-vendor/all-vendors-ospf-area-0.md#from-chatgpt) builds the same lab in [NetPilot](https://www.netpilot.io) from ChatGPT, Claude or any MCP assistant, and checks every neighbor and the loopback ping.

## Tutorial

[Build a multi-vendor network lab from ChatGPT](https://www.netpilot.io/blog/chatgpt-multi-vendor-network-lab) · [watch](https://www.youtube.com/watch?v=RSbXFoUDr98)

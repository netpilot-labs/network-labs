# Arista cEOS eBGP lab: two switches and two hosts

Two cEOS switches with eBGP between them and a Linux host behind each. The startup configs in `configs/` set everything at deploy, so the hosts reach each other with no typing.

![sw1 (Arista cEOS, AS 65001) and sw2 (Arista cEOS, AS 65002) link Ethernet1 to Ethernet1 on 10.0.12.0/31. h1 (Linux host, 10.1.1.10) on sw1 Ethernet2, h2 (Linux host, 10.2.2.10) on sw2 Ethernet2](topology.png)

## Run it

```bash
sudo containerlab deploy -t two-switches.clab.yml
docker exec clab-arista-two-sw1 Cli -c 'show ip bgp summary'
docker exec clab-arista-two-h1 ping -c 3 10.2.2.10
```

BGP reads `Estab` about 7 seconds after the deploy returns. SSH in as `admin` with password `admin`. You bring the cEOS image yourself: the [Arista README](../README.md) has where to get it and what to know about it.

## Build it from one prompt

[The prompt](https://github.com/netpilot-labs/example-prompts/blob/main/routing/arista-ceos-ebgp-two-switches.md) builds the same lab in [NetPilot](https://www.netpilot.io) and proves the hosts reach each other.

## Tutorial

[Run Arista cEOS in containerlab](https://www.netpilot.io/blog/arista-ceos-containerlab)

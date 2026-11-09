# Arista MLAG lab: a VARP pair with a dual-homed host and switch

Two cEOS leaves in one MLAG domain with VARP gateways on VLANs 10 and 20. h1 is dual-homed on an LACP bond, and sw3 hangs off both leaves on an MLAG port channel with h2 behind it.

```
           Port-Channel10 (peer link, Ethernet1-2)
    leaf1 ===================================== leaf2
    Vlan10 .2  Vlan20 .2                Vlan10 .3  Vlan20 .3
      |  \                                  /  |
      |   +------ mlag 2: sw3 --- h2 -------+   |
      +---------- mlag 1: h1 bond0 ------------+
VARP gateways 10.10.10.1 and 10.20.20.1
h1 10.10.10.10 (VLAN 10), h2 10.20.20.10 (VLAN 20)
```

## Run it

```bash
sudo containerlab deploy -t mlag-pair.clab.yml
docker exec clab-arista-mlag-leaf1 Cli -c 'show mlag'
docker exec clab-arista-mlag-h1 ping -c 3 10.20.20.10
```

The hosts reached each other about 57 seconds after the deploy began. To measure a failover, run a ping from h1 and stop one leaf with `docker stop clab-arista-mlag-leaf1`. The tutorial has the outage numbers and why the configs use `lacp timer fast`. You bring the cEOS image yourself: the [Arista README](../README.md) has where to get it.

## Build it from one prompt

[The prompt](https://github.com/netpilot-labs/example-prompts/blob/main/data-center/arista-mlag-varp-pair.md) builds the same pair in [NetPilot](https://www.netpilot.io), stops one leaf and measures the outage.

## Tutorial

[Arista MLAG lab](https://www.netpilot.io/blog/arista-mlag-lab)

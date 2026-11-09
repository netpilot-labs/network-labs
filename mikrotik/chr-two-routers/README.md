# MikroTik CHR OSPF lab: two routers

Two RouterOS CHR routers on one link, OSPF in area 0, and a loopback on each that the other router learns.

```
r1 ether2 --- 10.0.12.0/30 --- ether2 r2
loopback 10.255.0.1        loopback 10.255.0.2
```

## Run it

```bash
sudo containerlab deploy -t chr-two-routers.clab.yml
ssh admin@clab-chr-two-routers-r1          # password admin
/routing ospf neighbor print
/ping 10.255.0.2 src-address=10.255.0.1
```

The neighbor reads `Full` and the ping answers once both nodes report `healthy` in `sudo containerlab inspect -t chr-two-routers.clab.yml`. The image, KVM and memory notes are in the [MikroTik README](../README.md).

## Build it from one prompt

[The prompt](https://github.com/netpilot-labs/example-prompts/blob/main/routing/mikrotik-chr-ospf-two-routers.md) builds the same lab in [NetPilot](https://www.netpilot.io/mikrotik-lab) and verifies it on the routers.

## Tutorial

[Run the official MikroTik CHR image in containerlab](https://www.netpilot.io/blog/mikrotik-chr-containerlab)

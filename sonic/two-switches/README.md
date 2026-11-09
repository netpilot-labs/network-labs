# SONiC two-switch lab

Two SONiC switches on one link and nothing else. The topology has no startup config, so you bring up the ports, ping across the link and start eBGP by hand, which is how the tutorial walks through it.

```
sw1 Ethernet0 --- 10.0.0.0/31 --- Ethernet0 sw2
AS 65001                          AS 65002
```

## Run it

```bash
sudo containerlab deploy -t two-switches.clab.yml
docker exec -it clab-sonic-two-switches-sw1 bash
config interface ip add Ethernet0 10.0.0.0/31
config interface startup Ethernet0
```

Do the same on sw2 with `10.0.0.1/31`, then `ping -c 3 10.0.0.1` from sw1. For BGP, `supervisorctl start bgpd` on both switches first, because this image boots with it stopped. The image and memory notes are in the [SONiC README](../README.md).

## Build it from one prompt

[The prompt](https://github.com/netpilot-labs/example-prompts/blob/main/routing/sonic-ebgp-two-switches.md) builds the same lab in [NetPilot](https://www.netpilot.io/sonic-nos-lab), brings the link and eBGP up and quotes the BGP summary from both switches.

## Tutorial

[Run SONiC in containerlab](https://www.netpilot.io/blog/sonic-containerlab)

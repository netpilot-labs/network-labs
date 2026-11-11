# Multi-vendor eBGP lab: Arista, Nokia and FRR in three autonomous systems

Three routers from three vendors in a chain, each in its own AS, each advertising its loopback into eBGP. Nokia SR Linux in the middle carries the Arista and FRR routes between them.

```
R1 Arista cEOS ---- 10.1.2.0/30 ---- R2 Nokia SR Linux ---- 10.2.3.0/30 ---- R3 FRR
AS 65001, Lo0 1.1.1.1              AS 65002, system0 2.2.2.2            AS 65003, lo 3.3.3.3
Ethernet1/1 .1                     ethernet-1/1 .2, ethernet-1/2 .1     eth1 .2
```

## Run it

```bash
sudo containerlab deploy -t ebgp-three-as.clab.yml
# wait until zebra and bgpd run on R3 (about a minute), then configure it
docker exec clab-ebgp-three-as-R3 pgrep bgpd
docker exec -i clab-ebgp-three-as-R3 vtysh < configs/R3.vtysh
```

Check it:

```bash
docker exec clab-ebgp-three-as-R1 Cli -c 'show ip bgp summary'
docker exec clab-ebgp-three-as-R2 sr_cli 'show network-instance default protocols bgp neighbor'
docker exec clab-ebgp-three-as-R3 vtysh -c 'show bgp ipv4 unicast summary'
docker exec clab-ebgp-three-as-R1 Cli -c 'ping 3.3.3.3 source 1.1.1.1 repeat 5'
```

R1 and R2 load their startup configs at deploy. R3 runs FRR in a Linux container, so its configuration goes in through vtysh after deploy, the way the recorded run did it. `containerlab deploy --reconfigure` wipes R3's configuration: push `configs/R3.vtysh` again after a redeploy.

Two details that stop this lab when it is built by hand. SR Linux eBGP imports and exports nothing until a routing policy allows it, so R2 has an accept-all import policy and an export policy for its loopback and the BGP-learned routes. FRR applies the RFC 8212 default to eBGP, so R3 has a permit-all route-map in both directions. The FRR link to SR Linux runs at MTU 1500 (the `exec` line), to match SR Linux.

SSH to R1 as `admin` with password `admin`, the lab default in `configs/R1.cfg`: change it before you expose the lab. You bring the cEOS image yourself: the [Arista README](../../arista/README.md) has where to get it. SR Linux and FRR are public images.

## Tested on

The recorded NetPilot run on 2026-11-11: cEOS 4.36.1F, SR Linux (the `latest` tag that day) and FRR 8.4. Both of R2's sessions read established, R1 and R3 each received the other two loopbacks, and the ping from 1.1.1.1 to 3.3.3.3 got 5 of 5 replies with a TTL of 63.

Changes from the run, for portability: the lab is renamed from `ebgp-3vendor` to `ebgp-three-as`, the fixed management subnet and addresses are dropped (containerlab picks its default), the startup-config paths point at `configs/`, R3's configuration is the one the run pushed through vtysh, and `daemons` and `vtysh.conf` follow what NetPilot writes for an FRR node (bgpd and the other routing daemons on, the integrated config). The run deployed the original files: these portability edits were not redeployed as a package.

## Build it from one prompt

[The prompt](https://github.com/netpilot-labs/example-prompts/blob/main/routing/bgp-ebgp-three-as.md#from-claude) builds the same lab in [NetPilot](https://www.netpilot.io) from Claude, ChatGPT or any MCP assistant, and checks every session and the loopback ping.

## Tutorial

[Multi-vendor eBGP from one prompt in Claude](https://www.netpilot.io/blog/netpilot-in-claude#multi-vendor-ebgp-from-one-prompt)

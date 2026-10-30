# MikroTik labs for containerlab

Three containerlab labs for MikroTik RouterOS CHR. Each one runs on the official `mikrotik/chr` image with the `mikrotik_chr` kind, which the NetPilot team contributed to containerlab and which shipped in v0.82.0.

| Lab | What it builds | Tutorial |
|---|---|---|
| [01-chr-two-routers](01-chr-two-routers) | Two CHR routers with OSPF over one link | [Run the official MikroTik CHR image in containerlab](https://www.netpilot.io/blog/mikrotik-chr-containerlab) |
| [02-mtcna-practice](02-mtcna-practice) | Gateway, ISP, web server and two PCs for DHCP, bridging, NAT, firewall, queues and PPPoE | [MTCNA practice lab](https://www.netpilot.io/blog/mtcna-practice-lab) |
| [03-dual-wan-pcc](03-dual-wan-pcc) | Dual WAN PCC load balancing with failover on RouterOS 7 | [MikroTik load balancing with PCC](https://www.netpilot.io/blog/mikrotik-load-balancing-pcc) |

## Requirements

- containerlab v0.82.0 or newer
- A Linux host with Docker. KVM is used when `/dev/kvm` is available. Without it the nodes run under QEMU emulation and boot several times slower.
- About 300 MB of memory per CHR node

## Run a lab

```bash
git clone https://github.com/netpilot-labs/mikrotik-labs
cd mikrotik-labs/01-chr-two-routers
sudo containerlab deploy -t chr-two-routers.clab.yml
```

The lab is ready when each CHR node reports `healthy`:

```bash
sudo containerlab inspect -t chr-two-routers.clab.yml
```

Log in with `admin` / `admin`:

```bash
ssh admin@clab-chr-two-routers-r1
```

Remove the lab when you are done:

```bash
sudo containerlab destroy -t chr-two-routers.clab.yml --cleanup
```

## Tested with

RouterOS 7.24.5 and containerlab v0.82.0 on Ubuntu 24.04 with KVM.

The CHR free license limits each interface to 1 Mbit/s of upload. Routing, firewall and control plane behavior are unaffected.

## Links

- [mikrotik_chr kind documentation](https://containerlab.dev/manual/kinds/mikrotik_chr/)
- [MikroTik lab on NetPilot](https://www.netpilot.io/mikrotik-lab), where an AI agent builds the same kind of lab from a prompt in the browser

Maintained by the NetPilot team. AI for network engineers. Not affiliated with or endorsed by MikroTik or the containerlab project.

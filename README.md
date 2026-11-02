# MikroTik labs for containerlab

Three containerlab labs for MikroTik RouterOS CHR. Each one runs on the official `mikrotik/chr` image with the `mikrotik_chr` kind, which the NetPilot team contributed to containerlab and which shipped in v0.82.0.

| Lab | What it builds | Tutorial |
|---|---|---|
| [01-chr-two-routers](01-chr-two-routers) | Two CHR routers with OSPF over one link | [Run the official MikroTik CHR image in containerlab](https://www.netpilot.io/blog/mikrotik-chr-containerlab) |
| [02-mtcna-practice](02-mtcna-practice) | Gateway, ISP, web server and two PCs for DHCP, bridging, NAT, firewall, queues and PPPoE | [MTCNA practice lab](https://www.netpilot.io/blog/mtcna-practice-lab) |
| [03-dual-wan-pcc](03-dual-wan-pcc) | Dual WAN PCC load balancing with failover on RouterOS 7 | [MikroTik load balancing with PCC](https://www.netpilot.io/blog/mikrotik-load-balancing-pcc) |

## Build this from one prompt

No Linux host? On [NetPilot](https://www.netpilot.io/mikrotik-lab) an AI agent builds the same kind of lab on real RouterOS in the browser, and you get the CLI on every router. RouterOS is preloaded. Each link opens NetPilot with the prompt filled in:

- [Two CHR routers](https://app.netpilot.io/?prompt=Build%20two%20MikroTik%20CHR%20routers%20connected%20on%20ether2%2C%20with%20OSPF%20in%20area%200%20and%20a%20loopback%20on%20each.%20Verify%20the%20adjacency%20and%20ping%20loopback%20to%20loopback.)
- [MTCNA practice](https://app.netpilot.io/?prompt=Build%20an%20MTCNA%20practice%20lab%3A%20a%20MikroTik%20CHR%20gateway%20with%20a%20DHCP%20WAN%20from%20a%20CHR%20ISP%20router%2C%20a%20LAN%20bridge%20with%20a%20DHCP%20server%20and%20two%20Linux%20PCs%2C%20and%20a%20Linux%20web%20server%20behind%20the%20ISP.%20Leave%20NAT%20and%20the%20firewall%20for%20me%20to%20configure.)
- [Dual WAN failover](https://app.netpilot.io/?prompt=Build%20me%20a%20MikroTik%20dual%20WAN%20lab%20on%20RouterOS%207%3A%20a%20gateway%20with%20uplinks%20to%20two%20ISP%20routers%2C%20both%20reaching%20one%20web%20server%2C%20and%20a%20PC%20on%20the%20LAN.%20Set%20up%20PCC%20load%20balancing%20with%20failover.%20Then%20kill%20ISP-1%20upstream%20while%20the%20gateway%20link%20stays%20up%2C%20and%20measure%20how%20long%20the%20PC%20loses%20traffic.)

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

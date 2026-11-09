# Arista cEOS labs for containerlab

Two containerlab labs for Arista cEOS-lab. Each one runs with the `arista_ceos` kind. Every config and every number here came from a real run.

| Lab | What it builds | Tutorial |
|---|---|---|
| [two-switches](two-switches) | Two cEOS switches and two Linux hosts with eBGP, configured at deploy | [Run Arista cEOS in containerlab](https://www.netpilot.io/blog/arista-ceos-containerlab) |
| [mlag-pair](mlag-pair) | An MLAG pair with VARP, a host on an LACP bond and a third switch on an MLAG port channel | [Arista MLAG lab](https://www.netpilot.io/blog/arista-mlag-lab) |

## Requirements

- containerlab, tested on v0.77.0 and v0.82.0
- A Linux host with Docker. No KVM needed, cEOS is a plain container.
- About 1.5 GB of memory per cEOS node, measured at 1.15 to 1.45 GiB
- An x86_64 cEOS image, which you bring yourself

## Get the image

This repository does not include the cEOS image and never will. It is Arista's software, under Arista's license. Register at arista.com, open Software Downloads, download the `cEOS64-lab` archive for your release, then import it:

```bash
docker import cEOS64-lab-4.36.1F.tar.xz ceos:4.36.1F
```

The labs use `ceos:4.36.1F`. For another release, change the `image` line in the topology file.

## Run a lab

```bash
git clone https://github.com/netpilot-labs/network-labs
cd network-labs/arista/two-switches
sudo containerlab deploy -t two-switches.clab.yml
```

Deploy returns after about 30 seconds. BGP is up about 7 seconds later. The MLAG lab needs about 57 seconds from the start of the deploy until the hosts reach each other. Open a switch CLI, or SSH in as `admin` with password `admin`:

```bash
docker exec -it clab-arista-two-sw1 Cli
```

Remove the lab when you are done:

```bash
sudo containerlab destroy -t two-switches.clab.yml --cleanup
```

## What to know about this image

- A custom `startup-config` replaces the default config. It drops the `admin` user and eAPI, so the configs here add them back. Without the user, SSH answers `Permission denied` while `docker exec` still works.
- An interface without `no switchport` keeps its `ip address` line in the running config and stays in VLAN 1, with no error at boot.
- Linux nodes get an MTU of 9500 on data links and routed cEOS ports have an IP MTU of 1500. Ping works and TCP stalls. The hosts here set `mtu 1500`.
- Do not use `docker restart` on a node. It hangs in `if-wait.sh` with `Connected 0 interfaces out of 2`. Use `containerlab destroy` without `--cleanup`, then `deploy`, which keeps the saved config.
- `docker stop` does not drop the link on the neighbor, so it behaves like a silent failure. The MLAG lab uses `lacp timer fast` and `spanning-tree portfast` for that reason. Its tutorial has the numbers.

## Tested with

cEOS-lab 4.36.1F on containerlab v0.77.0 and v0.82.0, Ubuntu 24.04.

## Links

- [Arista cEOS kind documentation](https://containerlab.dev/manual/kinds/ceos/)
- [NetPilot](https://www.netpilot.io/containerlab-cloud), where an AI agent builds the same kind of lab from a prompt in the browser, on your own cEOS image

Maintained by the NetPilot team. AI for network engineers. Not affiliated with or endorsed by Arista Networks or the containerlab project. Arista, EOS and cEOS are trademarks of Arista Networks.

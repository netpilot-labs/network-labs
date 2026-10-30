# Juniper vJunos labs for containerlab

A containerlab lab for Juniper vJunos-router, using the `juniper_vjunosrouter` kind. Every config and number here came from a real run.

| Lab | What it builds | Tutorial |
|---|---|---|
| [01-jncia-practice](01-jncia-practice) | Two vJunos-routers and two Linux hosts, with seven exercises mapped to the JN0-106 objectives | [JNCIA-Junos practice lab](https://www.netpilot.io/blog/jncia-practice-lab) |

Setup steps, traps and the switch kind are in [Run vJunos in containerlab](https://www.netpilot.io/blog/vjunos-containerlab).

## Requirements

- containerlab, tested on v0.77.0
- A Linux host with Docker and KVM. If the host is itself a VM, turn on nested virtualization.
- 4 vCPU and 5 GiB of memory per vJunos node. This lab wants 8 vCPU and 10 GiB, plus room for the hosts.
- A vJunos-router image, which you bring yourself

## Get the image

This repository does not include the vJunos image and never will. It is Juniper's software, under Juniper's license. Download the qcow2 from Juniper's [vJunos page](https://www.juniper.net/us/en/dm/vjunos-labs.html), accept the license there, then build the container image with [vrnetlab](https://github.com/srl-labs/vrnetlab):

```bash
git clone https://github.com/srl-labs/vrnetlab
cd vrnetlab/juniper/vjunosrouter
cp ~/Downloads/vJunos-router-26.2R1.7.qcow2 .
make
```

The lab uses `vrnetlab/juniper_vjunos-router:26.2R1.7`. For another release, change the `image` lines in the topology file.

## Run the lab

```bash
git clone https://github.com/netpilot-labs/juniper-labs
cd juniper-labs/01-jncia-practice
sudo containerlab deploy -t jncia-practice.clab.yml
```

Deploy returns in seconds, then the routers boot. Allow 20 to 40 minutes. Watch for `Startup complete` in `docker logs -f clab-jncia-lab-r1`, then poll `show chassis fpc 0` until it reads `Online`.

```bash
sudo containerlab destroy -t jncia-practice.clab.yml --cleanup
```

## License

BSD 3-Clause. The topology and configs are by the NetPilot team. NetPilot is AI for network engineers: https://www.netpilot.io

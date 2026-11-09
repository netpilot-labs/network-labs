# Juniper vJunos labs for containerlab

containerlab labs for Juniper vJunos-router and vJunos-switch, using the `juniper_vjunosrouter` and `juniper_vjunosswitch` kinds. Every config and number here came from a real run.

| Lab | What it builds | Tutorial |
|---|---|---|
| [01-jncia-practice](01-jncia-practice) | Two vJunos-routers and two Linux hosts, with seven exercises mapped to the JN0-106 objectives | [JNCIA-Junos practice lab](https://www.netpilot.io/blog/jncia-practice-lab) |
| [02-evpn-vxlan-spine-leaf](02-evpn-vxlan-spine-leaf) | A vJunos-router spine and two vJunos-switch leaves: OSPF underlay, BGP EVPN overlay, VLAN 10 on VXLAN VNI 10010 | [Juniper EVPN-VXLAN lab](https://www.netpilot.io/blog/juniper-evpn-vxlan-lab) |

Setup steps, traps and the switch kind are in [Run vJunos in containerlab](https://www.netpilot.io/blog/vjunos-containerlab).

## Requirements

- containerlab, tested on v0.77.0
- A Linux host with Docker and KVM. If the host is itself a VM, turn on nested virtualization.
- 4 vCPU and 5 GiB of memory per vJunos node: 8 vCPU and 10 GiB for lab 01, 12 vCPU and 15 GiB for lab 02, plus room for the hosts.
- The vJunos-router image (both labs) and the vJunos-switch image (lab 02), which you bring yourself

## Get the image

This repository does not include the vJunos image and never will. It is Juniper's software, under Juniper's license. Download the qcow2 from Juniper's support downloads pages for [vJunos-router](https://support.juniper.net/support/downloads/?p=vjunos-router) and [vJunos-switch](https://support.juniper.net/support/downloads/?p=vjunos-switch), accept the license there, then build the container image with [vrnetlab](https://github.com/srl-labs/vrnetlab):

```bash
git clone https://github.com/srl-labs/vrnetlab
cd vrnetlab/juniper/vjunosrouter
cp ~/Downloads/vJunos-router-26.2R1.7.qcow2 .
make
```

For vJunos-switch, run the same steps in `vrnetlab/juniper/vjunosswitch` with the vJunos-switch qcow2.

The labs use `vrnetlab/juniper_vjunos-router:26.2R1.7` and `vrnetlab/juniper_vjunos-switch:26.2R1.7`. For another release, change the `image` lines in the topology file.

## Run the lab

```bash
git clone https://github.com/netpilot-labs/juniper-labs
cd juniper-labs/01-jncia-practice
sudo containerlab deploy -t jncia-practice.clab.yml
```

Deploy returns in seconds, then the routers take a while to boot. Watch for `Startup complete` in `docker logs -f clab-jncia-lab-r1`, then poll `show chassis fpc 0` until it reads `Online`.

```bash
sudo containerlab destroy -t jncia-practice.clab.yml --cleanup
```

## License

BSD 3-Clause. The topology and configs are by the NetPilot team. NetPilot is AI for network engineers: https://www.netpilot.io

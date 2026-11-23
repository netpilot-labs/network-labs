# Fortinet FortiGate labs for containerlab

containerlab labs on a real FortiGate. They use the `fortinet_fortigate` kind. Every config and number here came from a real run.

| Lab | What it builds | Tutorial |
|---|---|---|
| [fortigate-zones-policy-nat](fortigate-zones-policy-nat) | One FortiGate between an inside and an outside zone, a PC and a web server, source NAT out, nothing in, and a deny policy that blocks ping while web traffic works | [Firewall lab: Palo Alto and FortiGate](https://www.netpilot.io/blog/firewall-lab-palo-alto-fortinet) |

## Requirements

- containerlab, with Docker on a Linux host with KVM (`/dev/kvm`): the FortiGate is a VM inside the container
- The FortiGate VM image, which you bring yourself
- About 2 GiB of memory for the FortiGate

## Get the image

This repository does not include FortiOS and never will. It is Fortinet's software, under Fortinet's license. Download the FortiGate VM for KVM from Fortinet's support portal, rename the `fortios.qcow2` inside the zip to `fortios-v7.0.9.qcow2` (your version), put it in `vrnetlab/fortinet/fortigate` of [vrnetlab](https://github.com/srl-labs/vrnetlab) and run `make`. That builds `vrnetlab/vr-fortios:7.0.9`, the tag the labs use. For another release, change the `image` line in the topology file.

The VM runs on a 15-day evaluation licence counted from first boot, and every fresh deploy starts a new window. FortiOS 7.0.x forwards traffic without a paid licence, so use a 7.0 build for these labs.

## Run a lab

```bash
git clone https://github.com/netpilot-labs/network-labs
cd network-labs/fortinet/fortigate-zones-policy-nat
sudo containerlab deploy -t fortigate-zones-policy-nat.clab.yml
```

```bash
sudo containerlab destroy -t fortigate-zones-policy-nat.clab.yml --cleanup
```

## Build it from one prompt

On NetPilot the same lab builds from one prompt in the browser, with nothing installed on your machine: [the prompt](https://github.com/netpilot-labs/example-prompts/blob/main/security/fortigate-zones-policy-nat.md). You upload your FortiGate image once.

## License

BSD 3-Clause. The topology and configs are by the NetPilot team. NetPilot is AI for network engineers: https://www.netpilot.io

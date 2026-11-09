# Cisco IOS labs for containerlab

containerlab labs on real Cisco IOS, using the `cisco_iol` kind (Cisco IOL). Every config and number here came from a real run.

| Lab | What it builds | Tutorial |
|---|---|---|
| [01-ccna-ospf-mtu](01-ccna-ospf-mtu) | The classic CCNA OSPF lab: two Cisco IOL routers in area 0 and a Linux host on each LAN, with one stray MTU to find. Includes the fixed lab as a Packet Tracer `.pkt` | [The same CCNA lab on real Cisco IOS](https://www.netpilot.io/blog/network-simulator-online-free#the-same-ccna-lab-on-real-cisco-ios) |
| [02-hub-spoke-ospf](02-hub-spoke-ospf) | A head office and two branches on three Cisco IOL routers in OSPF area 0, a Linux host on each LAN, with an OSPF area mismatch to plant and find. Includes the handover document an AI agent wrote for it | [Five tasks, one scorecard](https://www.netpilot.io/blog/ai-tools-for-network-engineers#tested-on-a-real-cisco-lab-five-tasks-one-scorecard) |

What changes between Cisco Packet Tracer and real Cisco IOS, protocol by protocol: [Packet Tracer vs real Cisco IOS](https://www.netpilot.io/packet-tracer-vs-real-ios).

## Requirements

- containerlab, with Docker on a Linux host
- The Cisco IOL image, which you bring yourself
- About 1 GiB of memory per IOL router

## Get the image

This repository does not include Cisco IOL and never will. It is Cisco's software, under Cisco's license. Get the IOL image through your Cisco account (Cisco Modeling Labs ships it), then build the container image with [vrnetlab](https://github.com/srl-labs/vrnetlab) in `vrnetlab/cisco/iol`, following its README. The labs use `vrnetlab/cisco_iol:17.12.1`. For another release, change the `image` lines in the topology file.

## Run the lab

```bash
git clone https://github.com/netpilot-labs/cisco-labs
cd cisco-labs/01-ccna-ospf-mtu
sudo containerlab deploy -t ccna-ospf-mtu.clab.yml
```

```bash
sudo containerlab destroy -t ccna-ospf-mtu.clab.yml --cleanup
```

## Build it from one prompt

On NetPilot the same lab builds from one prompt in the browser, with nothing installed on your machine: [open the prompt prefilled](https://www.netpilot.io/blog/network-simulator-online-free#the-same-ccna-lab-on-real-cisco-ios). You upload your Cisco IOL image once.

## License

BSD 3-Clause. The topology and configs are by the NetPilot team. NetPilot is AI for network engineers: https://www.netpilot.io

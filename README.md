<p align="center">
  <a href="https://www.netpilot.io">
    <img src="https://www.netpilot.io/netpilot-logo.svg" alt="NetPilot" width="240" />
  </a>
</p>

# Network labs for containerlab

Tested network labs you can copy and deploy: the containerlab topology, the device configs, and what the lab was tested on. Cisco IOS, Juniper vJunos, Arista cEOS, SONiC and MikroTik RouterOS, from CCNA practice to EVPN-VXLAN fabrics and router hardening. Every lab here was deployed and checked on a real run.

Need a lab for a change, a design review, a certification or a customer demo? Find it below, clone the repo and run one command. Each lab also links to the prompt that builds it in [NetPilot](https://www.netpilot.io), where an AI agent builds the same lab in the browser with nothing to install. All the prompts are in [example-prompts](https://github.com/netpilot-labs/example-prompts).

## The labs

| Lab | Vendor | What it builds | Cert | Image | Tested on | Prompt | Tutorial |
|---|---|---|---|---|---|---|---|
| [ccna-ospf-mtu](cisco/ccna-ospf-mtu) | Cisco IOS | Two IOL routers in OSPF area 0 and a host on each LAN, one stray MTU to find. Includes the fixed lab as a Packet Tracer `.pkt` | CCNA | bring your own | IOL 17.12.1 | [prompt](https://github.com/netpilot-labs/example-prompts/blob/main/troubleshooting/cisco-ios-ospf-mtu-mismatch.md) | [read](https://www.netpilot.io/blog/network-simulator-online-free#the-same-ccna-lab-on-real-cisco-ios) · [watch](https://www.youtube.com/watch?v=OgvgcCUHu8g) |
| [hub-spoke-ospf](cisco/hub-spoke-ospf) | Cisco IOS | A head office and two branches in OSPF area 0, an area mismatch to plant and find, and the handover document an agent wrote |  | bring your own | IOL 17.12.1 | [prompt](https://github.com/netpilot-labs/example-prompts/blob/main/troubleshooting/ai-five-jobs-cisco-ios.md) | [read](https://www.netpilot.io/blog/ai-tools-for-network-engineers#tested-on-a-real-cisco-lab-five-tasks-one-scorecard) · [watch](https://www.youtube.com/watch?v=H2xePvVEauA) |
| [jncia-practice](juniper/jncia-practice) | Juniper vJunos | Two vJunos-routers and two hosts, seven exercises mapped to the JN0-106 objectives | JNCIA-Junos | bring your own | vJunos 26.2R1.7, containerlab 0.77.0 | [prompt](https://github.com/netpilot-labs/example-prompts/blob/main/routing/juniper-vjunos-ospf-two-routers.md) | [read](https://www.netpilot.io/blog/jncia-practice-lab) |
| [evpn-vxlan-spine-leaf](juniper/evpn-vxlan-spine-leaf) | Juniper vJunos | A spine and two leaves: OSPF underlay, BGP EVPN overlay, VLAN 10 on VNI 10010 | | bring your own | vJunos 26.2R1.7, containerlab 0.77.0 | [prompt](https://github.com/netpilot-labs/example-prompts/blob/main/data-center/juniper-evpn-vxlan-vjunos.md) | [read](https://www.netpilot.io/blog/juniper-evpn-vxlan-lab) |
| [two-switches](arista/two-switches) | Arista cEOS | Two cEOS switches and two hosts with eBGP, configured at deploy | | bring your own | cEOS 4.36.1F, containerlab 0.77.0 and 0.82.0 | [prompt](https://github.com/netpilot-labs/example-prompts/blob/main/routing/arista-ceos-ebgp-two-switches.md) | [read](https://www.netpilot.io/blog/arista-ceos-containerlab) |
| [mlag-pair](arista/mlag-pair) | Arista cEOS | An MLAG pair with VARP, a host on an LACP bond and a third switch on an MLAG port channel | | bring your own | cEOS 4.36.1F, containerlab 0.77.0 and 0.82.0 | [prompt](https://github.com/netpilot-labs/example-prompts/blob/main/data-center/arista-mlag-varp-pair.md) | [read](https://www.netpilot.io/blog/arista-mlag-lab) |
| [two-switches](sonic/two-switches) | SONiC | Two SONiC switches on one link, configured by hand | | free, public | sonic-vs 202511, containerlab 0.77.0 and 0.82.0 | [prompt](https://github.com/netpilot-labs/example-prompts/blob/main/routing/sonic-ebgp-two-switches.md) | [read](https://www.netpilot.io/blog/sonic-containerlab) |
| [bgp-leaf-spine](sonic/bgp-leaf-spine) | SONiC | Two spines, two leaves and two hosts with eBGP and ECMP, configured at deploy | | free, public | sonic-vs 202511, containerlab 0.77.0 and 0.82.0 | [prompt](https://github.com/netpilot-labs/example-prompts/blob/main/data-center/sonic-bgp-leaf-spine-ecmp.md) | [read](https://www.netpilot.io/blog/sonic-frr-bgp) |
| [evpn-l2vni](sonic/evpn-l2vni) | SONiC | One spine, two leaves and two hosts with VLAN 100 stretched over VNI 10100, configured at deploy | | free, public | sonic-vs 202511, containerlab 0.77.0 and 0.82.0 | [prompt](https://github.com/netpilot-labs/example-prompts/blob/main/data-center/sonic-evpn-vxlan-l2vni.md) | [read](https://www.netpilot.io/solutions/learn-vxlan-evpn-sonic) |
| [chr-two-routers](mikrotik/chr-two-routers) | MikroTik RouterOS | Two CHR routers with OSPF over one link | | free, public | RouterOS 7.24.5, containerlab 0.82.0 | [prompt](https://github.com/netpilot-labs/example-prompts/blob/main/routing/mikrotik-chr-ospf-two-routers.md) | [read](https://www.netpilot.io/blog/mikrotik-chr-containerlab) |
| [mtcna-practice](mikrotik/mtcna-practice) | MikroTik RouterOS | Gateway, ISP, web server and two PCs for DHCP, bridging, NAT, firewall, queues and PPPoE | MTCNA | free, public | RouterOS 7.24.5, containerlab 0.82.0 | [prompt](https://github.com/netpilot-labs/example-prompts/blob/main/routing/mikrotik-routeros-practice-lab.md) | [read](https://www.netpilot.io/blog/mtcna-practice-lab) |
| [dual-wan-pcc](mikrotik/dual-wan-pcc) | MikroTik RouterOS | Dual WAN PCC load balancing with failover on RouterOS 7 | | free, public | RouterOS 7.24.5, containerlab 0.82.0 | [prompt](https://github.com/netpilot-labs/example-prompts/blob/main/routing/mikrotik-dual-wan-pcc-failover.md) | [read](https://www.netpilot.io/blog/mikrotik-load-balancing-pcc) |
| [mikrotrick-hardening](mikrotik/mikrotrick-hardening) | MikroTik RouterOS | An exposed edge router, the audit after MikroTrick, and a firewall that keeps management on the LAN | | free, public | RouterOS 7.24.5, containerlab 0.82.0 | [prompt](https://github.com/netpilot-labs/example-prompts/blob/main/security/mikrotik-firewall-hardening-mikrotrick.md) | [read](https://www.netpilot.io/blog/mikrotik-firewall-hardening) |

Each vendor folder has its own README with how to get the image, the memory each node needs, and what to know about that image: [Cisco](cisco), [Juniper](juniper), [Arista](arista), [SONiC](sonic), [MikroTik](mikrotik).

## Run a lab

You need containerlab and Docker on a Linux host. Some images also need KVM, which the vendor README says.

```bash
git clone https://github.com/netpilot-labs/network-labs
cd network-labs/sonic/bgp-leaf-spine
sudo containerlab deploy -t bgp-leaf-spine.clab.yml
```

Remove it when you are done:

```bash
sudo containerlab destroy -t bgp-leaf-spine.clab.yml --cleanup
```

"Bring your own" images are the vendor's software under the vendor's license, and this repository never includes them. The vendor README says where to get each one and how to build it.

## Tools

- [mikrotik/chr-launcher](mikrotik/chr-launcher): runs the official `mikrotik/chr` image unmodified in containerlab with one launcher script. It became the native `mikrotik_chr` kind, which shipped in containerlab v0.82.0.

## containerlab test data

The test harnesses and results behind our containerlab contributions, so you can rerun them:

- [benchmarks/containerlab/mikrotik-chr-kind-matrix](benchmarks/containerlab/mikrotik-chr-kind-matrix): the test matrix for the `mikrotik_chr` kind (244 checks on amd64 and arm64, with and without KVM, across three RouterOS releases), plus the scripts for the follow-up PRs on interface count, neighbor discovery and the management VRF.
- [benchmarks/containerlab/mikrotik-ros-save-compare](benchmarks/containerlab/mikrotik-ros-save-compare): `containerlab save` on `mikrotik_ros` nodes, `main` against the shared SSH export.

## Contribute

Found a lab that no longer deploys on a newer image, or want a scenario added? Open an issue with the lab and what you ran. A new lab is a folder under its vendor with the topology, the configs and a README that says what it was tested on.

## License

BSD 3-Clause. The topologies, configs and scripts are by the NetPilot team. Vendor images are not included. NetPilot is not affiliated with or endorsed by Cisco, Juniper, Arista, the SONiC project, MikroTik or the containerlab project. All trademarks belong to their owners.

NetPilot is AI for network engineers: https://www.netpilot.io

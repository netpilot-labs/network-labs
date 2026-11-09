# 02: Hub and spoke OSPF on real Cisco IOS, with a fault to plant

A head office and two branches on real Cisco IOS (Cisco IOL 17.12.1): three routers in OSPF area 0, each branch linked only to the head office, a Linux host on each LAN. The configs here are the ones an AI agent designed, wrote and deployed from a written requirement in a recorded run. Then one fault was planted by hand and the agent got only the user's symptom.

Watch the run: [AI for Network Engineers: 5 Real Tasks on a Real Cisco Lab, Scored](https://www.youtube.com/watch?v=H2xePvVEauA). Read the scorecard: [five tasks, one scorecard](https://www.netpilot.io/blog/ai-tools-for-network-engineers#tested-on-a-real-cisco-lab-five-tasks-one-scorecard).

## The lab

| Node | Interface | Address |
|---|---|---|
| HQ-R1 | Ethernet0/1 (to BRA-R1) | 10.0.12.1/30 |
| HQ-R1 | Ethernet0/2 (to BRB-R1) | 10.0.13.1/30 |
| HQ-R1 | Ethernet0/3 (head office LAN) | 10.10.0.1/24 |
| BRA-R1 | Ethernet0/1 (to HQ-R1) | 10.0.12.2/30 |
| BRA-R1 | Ethernet0/2 (branch A LAN) | 10.20.0.1/24 |
| BRB-R1 | Ethernet0/1 (to HQ-R1) | 10.0.13.2/30 |
| BRB-R1 | Ethernet0/2 (branch B LAN) | 10.30.0.1/24 |
| HQ-H1, BRA-H1, BRB-H1 | eth1 | .10 on each LAN |

OSPF process 1, area 0, loopback router IDs 10.255.0.1 to 10.255.0.3, the WAN links point-to-point, the LANs and loopbacks passive.

## The exercise

1. Deploy it (see the [repository README](../README.md)) and check `show ip ospf neighbor` on HQ-R1: both branches FULL.
2. Ping the head office from branch B: `sudo docker exec clab-hub-spoke-ospf-BRB-H1 ping -c 5 10.10.0.10`.
3. Plant the fault on BRB-R1, on its link to the head office:

   ```cisco
   BRB-R1(config)# interface Ethernet0/1
   BRB-R1(config-if)# ip ospf 1 area 1
   ```

4. Ping again, then find the cause on the CLI as if a user had only said "branch B cannot reach the head office". Fix it and prove it.

<details>
<summary>What we saw, and the fix</summary>

HQ-R1 only logged the neighbor going down on its dead timer. BRB-R1 named the cause about every 10 seconds:

```
%OSPF-4-ERRRCV: Received invalid packet: mismatched area ID from backbone area from 10.0.13.1, Ethernet0/1
```

An interface-level `ip ospf 1 area 1` overrides the `network` statement for area 0. The fix removes it:

```cisco
BRB-R1(config)# interface Ethernet0/1
BRB-R1(config-if)# no ip ospf 1 area 1
```

Look fast: IOL's 4096-byte log buffer overwrote these lines about 20 minutes after the fix in our run. `%SYS-5-CONFIG_I` in the same log shows when the change was made.

</details>

## The handover

[`handover.html`](handover.html) is the handover document the agent wrote at the end of the run: sites, addressing, routing, the incident timeline from the router logs, the fix and the health checks. Download it and open it in a browser.

## Build it from one prompt

On NetPilot the same lab builds from a written requirement in the browser, with nothing installed on your machine: [the three prompts we used](https://github.com/netpilot-labs/example-prompts/blob/main/troubleshooting/ai-five-jobs-cisco-ios.md). You upload your Cisco IOL image once.

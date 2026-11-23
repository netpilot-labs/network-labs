# Answer key — branch-tshoot-interview-01

**Interviewer only.** This lab runs on Cisco IOL 17.12.1 in ContainerLab. To reset it to the faulted state, redeploy it, because all three faults are in the startup configs.

## Candidate brief (read this aloud)

> "Branch office AS 65010 cannot reach the internet. Users on 10.10.10.0/24 (test host PC1, 10.10.10.10) can't reach 203.0.113.10. The branch runs OSPF area 0 inside and has two circuits to the same provider, AS 64500: a **primary** on EDGE1 and a **backup** on EDGE2. By design, traffic should use the primary circuit in **both directions**, and the backup should carry traffic only if the primary fails. Get the branch working, then confirm the design intent is met."

You can let the candidate use the ISP router as a "looking glass", or keep it to yourself and run the show commands for them.

## Topology

```
PC1 10.10.10.10 ── Et0/1 CORE Et0/2 ── 10.0.1.0/30 ── Et0/1 EDGE1 Et0/2 ── 198.51.100.0/30 (primary) ── Et0/1 ┐
                         Et0/3 ── 10.0.2.0/30 ── Et0/1 EDGE2 Et0/2 ── 198.51.100.4/30 (backup)  ── Et0/2 ┤ ISP AS64500
                                                                                          Et0/3 203.0.113.1 ┘── INET 203.0.113.10
```

| Device | Role | RID |
|---|---|---|
| CORE | OSPF only, LAN gateway (Et0/1 passive) | 10.10.255.1 |
| EDGE1 | Primary exit. OSPF default metric 10, eBGP MED **50** out | 10.10.255.2 |
| EDGE2 | Backup exit. OSPF default metric 100, eBGP MED **200** out | 10.10.255.3 |
| ISP | AS 64500, sends `default-originate` to both edges | 192.0.2.1 |

**How the design is meant to work.** Outbound, CORE prefers EDGE1's default route (E2 metric 10 vs 100). Inbound, the ISP compares MED between two paths from the same neighbor AS, and the lower MED wins, so EDGE1 (50) should beat EDGE2 (200).

## Faults stack: fixing one reveals the next

| # | Difficulty | Device | Symptom | Root cause |
|---|---|---|---|---|
| 1 | Easy | EDGE1 Et0/1 | CORE has no OSPF neighbor on Et0/2 | `ip ospf hello-interval 5` (dead 20) vs CORE's 10/40 |
| 2 | Medium | EDGE2 BGP | Session Established but advertises 0 prefixes | `network 10.10.0.0 mask 255.255.0.0`: there is no exact /16 in the RIB |
| 3 | Hard | EDGE2 prefix-list | Return traffic enters via the backup circuit | `BRANCH-NETS` lacks `le 24`, so the /24 skips `set metric 200`. Seq 20 then passes it with a MED equal to the IGP metric (20), which beats EDGE1's 50 |

**Starting state (verified):** the branch is fully down. EDGE1's OSPF adjacency is down, so EDGE1 has no route to 10.10.10.0/24 and its `network` statement originates nothing. EDGE2 originates nothing because of its /16 statement. The ISP has no route to the branch at all. CORE takes its default route from EDGE2, so outbound packets leave, but replies get dropped.

---

## Fault 1 — OSPF neighbor won't form (easy)

**What the candidate should notice**
```cli Cisco IOS
show ip ospf neighbor              ! CORE: only 10.10.255.3 on Et0/3
show ip ospf interface brief       ! CORE Et0/2 P2P Nbrs 0/0
show ip ospf interface Ethernet0/1 | include Timer   ! EDGE1
```
Observed on EDGE1: `Timer intervals configured, Hello 5, Dead 20, Wait 20, Retransmit 5`. CORE uses the default 10/40. Running `debug ip ospf hello` would show `Mismatched hello parameters from 10.0.1.2`.

**Fix (EDGE1)**
```config Cisco IOS
interface Ethernet0/1
 no ip ospf hello-interval 5
```
**Verified result:** CORE shows both neighbors FULL. CORE's default route now comes from EDGE1 (`metric 10 ... from 10.10.255.2`). EDGE1 advertises `10.10.10.0/24` to the ISP. PC1 → 203.0.113.10 succeeded 5/5. Traceroutes went PC1 → 10.0.1.2 → 198.51.100.1 outbound and INET → 198.51.100.2 → 10.0.1.1 on the return.

> The **ticket is now solved**, so watch whether the candidate stops here. A strong candidate checks the backup circuit next: "Is EDGE2 advertising?"

**Partial credit:** setting CORE to hello 5 also works, but it changes the reference router rather than the outlier. Ask why that's the worse fix.

## Fault 2 — BGP up, advertises nothing (medium)

**What the candidate should notice**
```cli Cisco IOS
show ip bgp summary                                  ! EDGE2: Established, PfxRcd 1 (the default)
show ip bgp neighbors 198.51.100.5 advertised-routes ! Total number of prefixes 0
show ip bgp 10.10.0.0/16                             ! % Network not in table
show running-config | section router bgp
show ip route 10.10.0.0 255.255.0.0                  ! only the /24 exists (via OSPF)
```
**Root cause:** a BGP `network` statement needs an **exact** prefix-and-mask match in the RIB. The RIB holds 10.10.10.0/24, not 10.10.0.0/16.

**Fix (EDGE2)**
```config Cisco IOS
router bgp 65010
 no network 10.10.0.0 mask 255.255.0.0
 network 10.10.10.0 mask 255.255.255.0
```
**Verified result:** EDGE2 advertised `10.10.10.0/24` (1 prefix). In the lab as deployed, this fix **immediately moves return traffic to EDGE2**: INET's traceroute goes `203.0.113.1 → 198.51.100.6 → 10.0.2.1`. That is fault 3 showing itself.

**Alternative answer to discuss (my reasoning, not tested in the lab):** a candidate could instead add `ip route 10.10.0.0 255.255.0.0 Null0` on EDGE2 to keep the /16. The exact-match /16 would then hit the prefix-list and get MED 200. The ISP would hold the /24 via EDGE1 and the /16 via EDGE2, and longest match would keep return traffic on EDGE1. That would **hide fault 3** without fixing it. Push back: "Your backup now only carries return traffic for the summary. What happens to inbound traffic when EDGE1 fails?"

## Fault 3 — return traffic takes the wrong exit (hard)

**Symptom:** outbound traffic uses the primary and the return uses the backup. Asymmetric routing like this breaks stateful firewalls and NAT, and it bills the backup circuit.
```shell
traceroute -n 203.0.113.10   # on PC1: hop 2 = 10.0.1.2 (EDGE1)
traceroute -n 10.10.10.10    # on INET: hop 2 = 198.51.100.6 (EDGE2)  <- wrong
```
**What the candidate should notice (ISP / looking glass)**
```cli Cisco IOS
show ip bgp 10.10.10.0/24
```
Observed during the live test, with best path via the backup:
```
65010  198.51.100.6 from 198.51.100.6 (10.10.255.3)
    Origin IGP, metric 20, localpref 100, valid, external, best
65010  198.51.100.2 from 198.51.100.2 (10.10.255.2)
    Origin IGP, metric 50, localpref 100, valid, external
```
The key clue is that EDGE2 sends **MED 20**, not the 200 in its config. Then on EDGE2:
```cli Cisco IOS
show route-map TO-ISP
show ip prefix-list BRANCH-NETS        ! seq 5 permit 10.10.0.0/16   <- no "le 24"
show ip bgp 10.10.10.0/24              ! metric 20 = OSPF cost to the LAN
```
**Root cause (both parts are needed for full marks):**
1. `permit 10.10.0.0/16` without `le` matches **only** the exact /16, so the /24 skips seq 10 and its `set metric 200`.
2. Seq 20 is a bare `permit`, so the route still goes out. With no `set metric`, IOS sends the **locally originated route's IGP metric** as the MED: OSPF cost 10 + 10 = **20**. 20 beats EDGE1's 50, and MED comes before oldest-path and router-ID in best-path selection, so this result is deterministic.

Compare with EDGE1, whose prefix-list correctly reads `permit 10.10.0.0/16 le 24`. The two edges' configs are "the same", which is what makes this one hard.

**Fix (EDGE2)**
```config Cisco IOS
no ip prefix-list BRANCH-NETS seq 5 permit 10.10.0.0/16
ip prefix-list BRANCH-NETS seq 5 permit 10.10.0.0/16 le 24
end
clear ip bgp 198.51.100.5 soft out
```
**Verified result:** the ISP table shows `*> 10.10.10.0/24 198.51.100.2 50` and `* 198.51.100.6 200`. INET's traceroute goes `203.0.113.1 → 198.51.100.2 → 10.0.1.1 → 10.10.10.10`, and INET → PC1 succeeded 5/5.

**Bonus points:** `bgp bestpath med missing-as-worst` on the ISP doesn't help here, because a MED *is* sent (20). Hardening options are to make seq 20 a `deny`, or to `set metric` in every sequence. A candidate who says "use AS-path prepend instead" should still explain why the MED wasn't applied.

---

## Scoring guide

| Level | Reaches |
|---|---|
| Junior | Fixes fault 1 with `show ip ospf interface` and stops when pings work |
| Mid | Checks advertised-routes on both edges and fixes fault 2 with the exact-match rule |
| Senior | Notices the asymmetry from traceroutes or the ISP table, follows MED 20 back to the prefix-list, and explains the IGP-metric MED |

## What I verified (agent-run, 2026-11-23)

- **Faulted baseline**, checked on the first deploy and again after the final redeploy. CORE had 1 OSPF neighbor (EDGE2 only). Both eBGP sessions were Established with PfxRcd 1 and 0 prefixes advertised. The ISP table held only the default route. PC1 → 203.0.113.10 got 0/3 replies.
- **Each fix, applied live in order 1 → 2 → 3:** all results are quoted above.
- **Design change during the build:** the first build used MEDs of 10/100. With those values fault 3 had no effect, because EDGE2's unmatched MED of 20 still lost to 10. I raised the MEDs to 50/200, re-tested, and put the new values in the startup configs before the final redeploy.
- **Not tested:** the Null0 alternative for fault 2, and EDGE1 circuit failover.

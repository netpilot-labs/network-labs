# 01 JNCIA practice lab

Two vJunos-routers and two Linux hosts. The startup config holds addresses only, so you do the rest by hand.

```
h1 --- ge-0/0/1 [r1] ge-0/0/0 --- ge-0/0/0 [r2] ge-0/0/1 --- h2
10.1.1.10      10.1.1.1  10.0.12.1/30  10.0.12.2  10.2.2.1   10.2.2.10
```

Loopbacks: r1 `10.255.0.1`, r2 `10.255.0.2`.

Sign in with `ssh admin@clab-jncia-lab-r1`, password `admin@123` (the containerlab default). Run host commands with `docker exec clab-jncia-lab-h1 ping 10.2.2.10`.

## Exercises

1. Set an interface description, read it with `show | compare`, run `commit check`, then commit and `rollback 1`.
2. Add static routes both ways, then ping h2 from h1.
3. Add OSPF while the static routes are still there, and read `Static/5` above `OSPF/10`.
4. Delete the statics and compare the routing table with the forwarding table.
5. Take r2's LAN out of OSPF and bring it back with an export policy. Read `OSPF/150` on r1.
6. Add a firewall filter with a counter. Then remove its accept term under `commit confirmed 2`, and watch OSPF fall and Junos roll back.
7. Save a rescue configuration.

The full walkthrough with real output is in the [JNCIA-Junos practice lab](https://www.netpilot.io/blog/jncia-practice-lab).

## What we measured

On a 16 vCPU cloud VM with nested virtualization, containerlab v0.77.0, vJunos-router 26.2R1.7, with 29 containers from other labs also running:

| Step | r2 | r1 |
|---|---|---|
| `Startup complete` in the log | 20 min 49 s | 24 min 21 s |
| `show chassis fpc 0` reads `Online` | about 31 min | under 37 min |

Each router used 5.1 GiB of memory and 3 to 3.5 cores. Earlier runs on a VM of the same size reached usable in about 18 minutes for one to three nodes.

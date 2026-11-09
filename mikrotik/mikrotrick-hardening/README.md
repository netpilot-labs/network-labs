# MikroTrick hardening lab

An edge router set up the way many end up: NAT for the LAN and no firewall rules, so management answers from the WAN. You scan it from outside, audit it, harden it, and prove the result from outside again. No exploit is run, and RouterOS 7.24.5 is past every MikroTrick fix.

```text
out 203.0.113.1 ── ether2 edge ether3 ── pc1 192.168.88.10
```

Tutorial: [MikroTik firewall hardening after MikroTrick](https://www.netpilot.io/blog/mikrotik-firewall-hardening)

## Run it

```bash
sudo containerlab deploy -t mikrotrick-hardening.clab.yml
```

Wait until `edge` reports `healthy` in `sudo containerlab inspect -t mikrotrick-hardening.clab.yml`.

## 1. Scan from outside

```bash
sudo docker exec clab-mikrotrick-hardening-out nmap -Pn -sT -p 21,22,23,80,2000,8291,8728,8729 203.0.113.2
```

All eight ports answer `open`: FTP, SSH, Telnet, WebFig, the bandwidth test server, WinBox, the API and API-SSL.

## 2. Audit

Log in with `admin` / `admin` (`ssh admin@clab-mikrotrick-hardening-edge`) and read:

```bash
/system resource print
/ip service print
/ip firewall filter print
/user print
/system script print
/system scheduler print
/ip socks print
/ip proxy print
```

## 3. Harden

```bash
scp harden.rsc admin@clab-mikrotrick-hardening-edge:
ssh admin@clab-mikrotrick-hardening-edge "/import harden.rsc"
```

`harden.rsc` keeps management reachable from the LAN only. It also accepts containerlab's management port `ether1` and network `172.20.20.0/24`, so your SSH session survives: drop that rule and that range on a real router, and replace the default `admin` account.

## 4. Prove it

Run the same scan from `out`: all eight ports read `filtered`. From the LAN, the PC still reaches the outside host and the router:

```bash
sudo docker exec clab-mikrotrick-hardening-pc1 ping -c 5 203.0.113.1
sudo docker exec clab-mikrotrick-hardening-pc1 nmap -Pn -sT -p 22,80,8291 192.168.88.1
```

Tested with containerlab v0.82.0 and RouterOS 7.24.5 on 2026-11-03: 8 ports open before, all 8 filtered after, 5 of 5 pings and HTTP 200 from the PC, and SSH, WebFig and WinBox open from the LAN.

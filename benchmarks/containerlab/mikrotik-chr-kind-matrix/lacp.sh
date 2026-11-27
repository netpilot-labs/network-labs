# lacp.sh <runs> <lifecycle 0|1>: the LACP lab (c1 bond1 ether2,3 <-> Linux 802.3ad bond0, c1 bond2 ether4,5 <-> c2 bond2
# ether2,3). Per run: fresh deploy, then with lifecycle=1 containerlab restart --node c1, a reboot of c1 from inside
# RouterOS (REST), and last docker restart c1 (it drops the containerlab veths on any build). Before the restart: one
# Linux bond member down and up, then c1 eth4 deleted and made again with containerlab tools veth create. Each RES line
# ends with the data bridge settings of #3636 5646b9a4 as counts (cable). BRNF=1 loads br_netfilter first. One RES line per check. Binary at ~/clab, LABEL names the build, CHR_TAG the RouterOS version.
. ~/m/lib.sh; [ "${BRNF:-0}" = 1 ] && sudo modprobe br_netfilter; B=${LABEL:-pr}; T=${CHR_TAG:-7.24.5}; RUNS=${1:-3}; LC=${2:-1}; C1=clab-lacp-c1; C2=clab-lacp-c2; L1=clab-lacp-l1
cd ~/m/L && sed "s#\${CHR_TAG:=7.24.5}#$T#" lacp.clab.yml > lacp-$T.clab.yml
ipr() { curl -s -m 10 -u admin:admin -X POST -H 'Content-Type: application/json' -d "{\"bond\":\"$2\",\"duration\":\"1s\"}" http://$(ip_of $1)/rest/interface/bonding/monitor-slaves | python3 ~/m/lacp.py ros; }
lnx() { sudo docker exec $L1 cat /proc/net/bonding/bond0 2>/dev/null | python3 ~/m/lacp.py linux; }
rate() { ros $1 admin admin "/interface ethernet monitor $2 once" | awk '/ rate:/{r=$2; for(i=3;i<=NF;i++) r=r","$i} /full-duplex:/{d=$2; for(i=3;i<=NF;i++) d=d","$i} END{print "rate="(r==""?"none":r)" fdx="(d==""?"none":d)}'; }
pings() { ros $1 admin admin "/ping $2 count=5" | grep -oE 'received=[0-9]+' | tail -1 | tr -dc 0-9; }
brp() { n=0; for c in "$C1:1 2 3 4" "$C2:1 2"; do k=${c%%:*}; for i in ${c#*:}; do for p in eth$i tap$i; do [ "$(sudo docker exec $k cat /sys/class/net/$p/brport/$1 2>/dev/null)" = "$2" ] && n=$((n+1)); done; done; done; echo $n/12; }
mask() { brp group_fwd_mask 0x4; }
converge() { t=0; while [ $t -lt 90 ]; do a=$(ipr $C1 bond1); b=$(ipr $C1 bond2); c=$(ipr $C2 bond2); d=$(lnx); case "$a$b$c$d" in 2/2*2/2*2/2*2/2*) echo $t; return;; esac; sleep 3; t=$((t+3)); done; echo "none(90s)"; }
# cable: the settings #3636 5646b9a4 lists, as counts over the data bridges (c1 br1-4, c2 br1-2), read in the container
cnt() { n=0; for c in "$C1:1 2 3 4" "$C2:1 2"; do k=${c%%:*}; for i in ${c#*:}; do for f in $(eval echo "$1"); do [ "$(sudo docker exec $k cat $f 2>/dev/null)" = "$2" ] && n=$((n+1)); done; done; done; echo $n; }
v6sum() { for k in $C1 $C2; do sudo docker exec $k sh -c 'for f in /proc/net/dev_snmp6/br[1-9]* /proc/net/dev_snmp6/tap[1-9]* /proc/net/dev_snmp6/eth[1-9]*; do [ -e "$f" ] && grep -E "^Ip6OutRequests " "$f"; done' 2>/dev/null; done | awk '{s+=$2} END{print s+0}'; }
v6addr() { for k in $C1 $C2; do sudo docker exec $k cat /proc/net/if_inet6 2>/dev/null; done | awk '$6 ~ /^(br|tap|eth)[1-9]/' | wc -l; }
fdbdyn() { n=0; for c in "$C1:1 2 3 4" "$C2:1 2"; do k=${c%%:*}; p=$(sudo docker inspect -f '{{.State.Pid}}' $k); for i in ${c#*:}; do m=$(sudo nsenter -t $p -n bridge fdb show br br$i 2>/dev/null | grep -vc permanent); n=$((n+m)); done; done; echo $n; }
nf() { [ -d /proc/sys/net/bridge ] || { echo absent; return; }; n=0; for k in $C1 $C2; do for t in iptables ip6tables arptables; do [ "$(sudo docker exec $k cat /proc/sys/net/bridge/bridge-nf-call-$t 2>/dev/null)" = 0 ] && n=$((n+1)); done; done; echo $n/6; }
lldp() { ros $1 admin admin '/ip neighbor print terse' | grep "identity=$2 " | grep -cE ' age=[0-9]{1,2}s '; }
ll() { ros $1 admin admin "/ipv6 address print terse where interface=$2" | grep -oE 'address=fe80::[0-9a-f:]+' | head -1 | cut -d= -f2; }
ping6() { a=$2; [ -n "$a" ] || { echo "noaddr"; return; }; ros $1 admin admin "/ping $a%$3 count=5" | grep -oE 'received=[0-9]+' | tail -1 | tr -dc 0-9; }
cable() { l1ll=$(sudo docker exec $L1 ip -6 addr show dev bond0 scope link 2>/dev/null | grep -oE 'fe80::[0-9a-f:]+' | head -1)
  echo "brmask0xfff8=$(cnt '/sys/class/net/br$i/bridge/group_fwd_mask' 0xfff8)/6 snoop0=$(cnt '/sys/class/net/br$i/bridge/multicast_snooping' 0)/6 v6off=$(cnt '/proc/sys/net/ipv6/conf/br$i/disable_ipv6 /proc/sys/net/ipv6/conf/tap$i/disable_ipv6 /proc/sys/net/ipv6/conf/eth$i/disable_ipv6' 1)/18 v6default1=$(for k in $C1 $C2; do sudo docker exec $k cat /proc/sys/net/ipv6/conf/default/disable_ipv6; done | grep -c '^1$')/2 nf0=$(nf) v6addrs=$(v6addr) v6tx=$(v6sum) fdbdyn=$(fdbdyn) lldp_c1_sees_c2=$(lldp $C1 c2) lldp_c2_sees_c1=$(lldp $C2 c1) ping6_c1_c2=$(ping6 $C1 "$(ll $C2 bond2)" bond2)/5 ping6_c1_linux=$(ping6 $C1 "$l1ll" bond1)/5 couldnot=$(nmark $C1 'could not')/$(nmark $C2 'could not') attached=$(nmark $C1 'attached: bridged')"; }
rep() { cv=$(converge); echo "RES $B $T run=$r $1 lacp_after=${cv}s c1.bond1(linux)=$(ipr $C1 bond1) linux.bond0=$(lnx) c1.bond2=$(ipr $C1 bond2) c2.bond2=$(ipr $C2 bond2) c1.ether2-5 $(rate $C1 ether2,ether3,ether4,ether5) ping_c1_linux=$(pings $C1 10.1.0.2)/5 ping_c1_c2=$(pings $C1 10.2.0.2)/5 ping_linux_c1=$(sudo docker exec $L1 ping -c 5 -W 2 10.1.0.1 | grep -oE '[0-9]+ packets received' | tr -dc 0-9)/5 mask0x4=$(mask) learning0=$(brp learning 0) br0learn1=$(sudo docker exec $C1 sh -c 'cat /sys/class/net/br0/brif/*/learning' 2>/dev/null | tr -d '\n') speedlog=$(nmark $C1 'data NIC speeds') maskfail=$(nmark $C1 'could not enable LACP') learnfail=$(nmark $C1 'could not turn MAC learning off') rebootchk=$(nmark $C1 'RouterOS rebooted: checking') health=$(health $C1)/$(health $C2) $(cable)"; }
for r in $(seq 1 $RUNS); do
  $CLAB deploy -t lacp-$T.clab.yml --reconfigure > /tmp/lacp-deploy.txt 2>&1 || { echo "DEPLOY FAILED $B $T run=$r"; tail -5 /tmp/lacp-deploy.txt; continue; }
  wait_healthy $C1 300 >/dev/null; wait_healthy $C2 120 >/dev/null; [ $r = 1 ] && { ros $C1 admin admin '/system resource print' | grep -E 'version|architecture'; sudo docker exec $C1 ps | grep -o 'virtio-net,id=nic1,[^ ]*' | head -1; echo "MLAGPROBE $T $(ros $C1 admin admin '/interface bridge mlag print' | head -1)"; }
  rep fresh
  # one member down on the Linux side, then back: the bond keeps traffic on the other member and both rejoin
  sudo docker exec $L1 ip link set eth1 down; sleep 6
  echo "RES $B $T run=$r member-down c1.bond1=$(ipr $C1 bond1) linux.bond0=$(lnx) ping_c1_linux=$(pings $C1 10.1.0.2)/5 ping_linux_c1=$(sudo docker exec $L1 ping -c 5 -W 2 10.1.0.1 | grep -oE '[0-9]+ packets received' | tr -dc 0-9)/5"
  sudo docker exec $L1 ip link set eth1 up; sleep 3; rep member-up
  # a link deleted and made again (c1 eth4 to c2 eth2): the launcher's watch_links joins the new veths to their bridges
  p=$(sudo docker inspect -f '{{.State.Pid}}' $C1); sudo nsenter -t $p -n ip link del eth4; sleep 3
  $CLAB tools veth create -a $C1:eth4 -b $C2:eth2 >/dev/null 2>&1 || echo "VETH CREATE FAILED"; sleep 12; rep relink
  if [ "$LC" = 1 ]; then
    n=$(nmark $C1 'RouterOS ready'); $CLAB restart -t lacp-$T.clab.yml --node c1 > /tmp/lacp-restart.txt 2>&1 || { echo "RESTART FAILED"; tail -3 /tmp/lacp-restart.txt; }; wait_new_marker $C1 'RouterOS ready' $n 300 >/dev/null; rep clab-restart-node
    curl -s -m 10 -u admin:admin -X POST -H 'Content-Type: application/json' -d '{}' http://$(ip_of $C1)/rest/system/reboot >/dev/null 2>&1; sleep 20
    for i in $(seq 1 36); do ros $C1 admin admin '/system identity print' | grep -q 'name: c1' && break; sleep 5; done; sleep 10; rep routeros-reboot
    n=$(nmark $C1 'RouterOS ready'); sudo docker restart $C1 >/dev/null; wait_new_marker $C1 'RouterOS ready' $n 300 >/dev/null; rep docker-restart
  fi
  [ $r = $RUNS ] && sudo docker logs $C1 2>&1 | grep -E 'data NIC speeds|LACP|attached|rebooted|re-plug|could not' | sed 's/^/LOG c1: /'
  $CLAB destroy -t lacp-$T.clab.yml --cleanup >/dev/null 2>&1
done

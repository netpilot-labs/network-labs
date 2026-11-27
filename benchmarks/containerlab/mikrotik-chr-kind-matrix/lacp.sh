# lacp.sh <runs> <lifecycle 0|1>: the LACP lab (c1 bond1 ether2,3 <-> Linux 802.3ad bond0, c1 bond2 ether4,5 <-> c2 bond2
# ether2,3). Per run: fresh deploy, then with lifecycle=1 containerlab restart --node c1, a reboot of c1 from inside
# RouterOS (REST), and last docker restart c1 (it drops the containerlab veths on any build). One RES line per check. Binary at ~/clab, LABEL names the build, CHR_TAG the RouterOS version.
. ~/m/lib.sh; B=${LABEL:-pr}; T=${CHR_TAG:-7.24.5}; RUNS=${1:-3}; LC=${2:-1}; C1=clab-lacp-c1; C2=clab-lacp-c2; L1=clab-lacp-l1
cd ~/m/L && sed "s#\${CHR_TAG:=7.24.5}#$T#" lacp.clab.yml > lacp-$T.clab.yml
ipr() { curl -s -m 10 -u admin:admin -X POST -H 'Content-Type: application/json' -d "{\"bond\":\"$2\",\"duration\":\"1s\"}" http://$(ip_of $1)/rest/interface/bonding/monitor-slaves | python3 ~/m/lacp.py ros; }
lnx() { sudo docker exec $L1 cat /proc/net/bonding/bond0 2>/dev/null | python3 ~/m/lacp.py linux; }
rate() { ros $1 admin admin "/interface ethernet monitor $2 once" | awk '/ rate:/{r=$2; for(i=3;i<=NF;i++) r=r","$i} /full-duplex:/{d=$2; for(i=3;i<=NF;i++) d=d","$i} END{print "rate="(r==""?"none":r)" fdx="(d==""?"none":d)}'; }
pings() { ros $1 admin admin "/ping $2 count=5" | grep -oE 'received=[0-9]+' | tail -1 | tr -dc 0-9; }
mask() { n=0; for c in "$C1:1 2 3 4" "$C2:1 2"; do k=${c%%:*}; for i in ${c#*:}; do for p in eth$i tap$i; do [ "$(sudo docker exec $k cat /sys/class/net/$p/brport/group_fwd_mask 2>/dev/null)" = 0x4 ] && n=$((n+1)); done; done; done; echo $n/12; }
converge() { t=0; while [ $t -lt 90 ]; do a=$(ipr $C1 bond1); b=$(ipr $C1 bond2); c=$(ipr $C2 bond2); d=$(lnx); case "$a$b$c$d" in 2/2*2/2*2/2*2/2*) echo $t; return;; esac; sleep 3; t=$((t+3)); done; echo "none(90s)"; }
rep() { cv=$(converge); echo "RES $B $T run=$r $1 lacp_after=${cv}s c1.bond1(linux)=$(ipr $C1 bond1) linux.bond0=$(lnx) c1.bond2=$(ipr $C1 bond2) c2.bond2=$(ipr $C2 bond2) c1.ether2-5 $(rate $C1 ether2,ether3,ether4,ether5) ping_c1_linux=$(pings $C1 10.1.0.2)/5 ping_c1_c2=$(pings $C1 10.2.0.2)/5 ping_linux_c1=$(sudo docker exec $L1 ping -c 5 -W 2 10.1.0.1 | grep -oE '[0-9]+ packets received' | tr -dc 0-9)/5 mask0x4=$(mask) speedlog=$(nmark $C1 'data NIC speeds') maskfail=$(nmark $C1 'could not enable LACP') rebootchk=$(nmark $C1 'RouterOS rebooted: checking') health=$(health $C1)/$(health $C2)"; }
for r in $(seq 1 $RUNS); do
  $CLAB deploy -t lacp-$T.clab.yml --reconfigure > /tmp/lacp-deploy.txt 2>&1 || { echo "DEPLOY FAILED $B $T run=$r"; tail -5 /tmp/lacp-deploy.txt; continue; }
  wait_healthy $C1 300 >/dev/null; wait_healthy $C2 120 >/dev/null; [ $r = 1 ] && { ros $C1 admin admin '/system resource print' | grep -E 'version|architecture'; sudo docker exec $C1 ps | grep -o 'virtio-net,id=nic1,[^ ]*' | head -1; }
  rep fresh
  if [ "$LC" = 1 ]; then
    n=$(nmark $C1 'RouterOS ready'); $CLAB restart -t lacp-$T.clab.yml --node c1 > /tmp/lacp-restart.txt 2>&1 || { echo "RESTART FAILED"; tail -3 /tmp/lacp-restart.txt; }; wait_new_marker $C1 'RouterOS ready' $n 300 >/dev/null; rep clab-restart-node
    curl -s -m 10 -u admin:admin -X POST -H 'Content-Type: application/json' -d '{}' http://$(ip_of $C1)/rest/system/reboot >/dev/null 2>&1; sleep 20
    for i in $(seq 1 36); do ros $C1 admin admin '/system identity print' | grep -q 'name: c1' && break; sleep 5; done; sleep 10; rep routeros-reboot
    n=$(nmark $C1 'RouterOS ready'); sudo docker restart $C1 >/dev/null; wait_new_marker $C1 'RouterOS ready' $n 300 >/dev/null; rep docker-restart
  fi
  [ $r = $RUNS ] && sudo docker logs $C1 2>&1 | grep -E 'data NIC speeds|LACP|attached|rebooted|re-plug' | sed 's/^/LOG c1: /'
  $CLAB destroy -t lacp-$T.clab.yml --cleanup >/dev/null 2>&1
done

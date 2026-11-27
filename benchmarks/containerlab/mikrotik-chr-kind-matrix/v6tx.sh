# v6tx.sh <runs>: which CHR data devices send IPv6 of their own (#3636 5646b9a4, ccf5be6a). The LACP lab in L/, per run: a fresh
# deploy and a containerlab restart --node c1; after each, every brN, tapN and ethN with a nonzero IPv6 send counter in
# /proc/net/dev_snmp6 (Ip6OutRequests, and of those DAD neighbor solicitations, MLDv2 reports, router solicitations).
# The counters start when the device is made in or moved into the container. CHR_TAG picks the RouterOS version,
# BRNF=1 loads br_netfilter first. Each line also carries:
#   early=  the first docker exec into c1 during the fresh deploy: net.ipv6.conf.default.disable_ipv6, the data ethN
#           present, and how many launcher log lines existed (an observation of order, not a proof of it)
#   mgmt=   per CHR: the runtime sysctl net.ipv6.conf.default.disable_ipv6 in docker inspect (sys), disable_ipv6 on
#           eth0 and br0, the launcher's management line naming the containerlab IPv6 (log6), that IPv6 on ether1
#           (ros6), SSH over it (ssh6), and host pings to the management IPv4 and IPv6 (p4, p6, of 3: 0/3 when the host
#           has no ping binary)
#   couldnot= the launcher's "could not" lines on c1/c2
. ~/m/lib.sh; [ "${BRNF:-0}" = 1 ] && sudo modprobe br_netfilter; B=${LABEL:-pr}; T=${CHR_TAG:-7.24.5}; RUNS=${1:-5}; C1=clab-lacp-c1; C2=clab-lacp-c2
NF=$([ -d /proc/sys/net/bridge ] && echo brnf || echo nobrnf)
cd ~/m/L && sed "s#\${CHR_TAG:=7.24.5}#$T#" lacp.clab.yml > lacp-$T.clab.yml
dev() { for k in $C1 $C2; do sudo docker exec $k sh -c 'cd /proc/net/dev_snmp6; for f in br[1-9]* tap[1-9]* eth[1-9]*; do [ -e "$f" ] && { echo "DEV $f"; cat $f; }; done' 2>/dev/null |
  awk -v k=${k#clab-lacp-} 'function out(){ if (d!="" && o>0) printf "%s.%s:out=%d,ns=%d,mld=%d,rs=%d ", k,d,o,n,m,r }
    $1=="DEV"{out(); d=$2; o=n=m=r=0} $1=="Ip6OutRequests"{o=$2} $1=="Icmp6OutNeighborSolicits"{n=$2} $1=="Icmp6OutMLDv2Reports"{m=$2} $1=="Icmp6OutRouterSolicits"{r=$2} END{out()}'; done; }
tot() { for k in $C1 $C2; do sudo docker exec $k sh -c 'ls -d /proc/net/dev_snmp6/br[1-9]* /proc/net/dev_snmp6/tap[1-9]* /proc/net/dev_snmp6/eth[1-9]* 2>/dev/null' ; done | wc -l; }
v6of() { sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.GlobalIPv6Address}}{{end}}' "$1"; }
mgmt() { for k in $C1 $C2; do a6=$(v6of $k); a4=$(ip_of $k)
  sys=$(sudo docker inspect -f '{{index .HostConfig.Sysctls "net.ipv6.conf.default.disable_ipv6"}}' $k); [ -n "$sys" ] || sys=unset
  e0=$(sudo docker exec $k cat /proc/sys/net/ipv6/conf/eth0/disable_ipv6 2>/dev/null); b0=$(sudo docker exec $k cat /proc/sys/net/ipv6/conf/br0/disable_ipv6 2>/dev/null)
  log6=0 ros6=0 ssh6=0 p6=0; p4=$(ping -c 3 -W 2 $a4 2>/dev/null | grep -oE '[0-9]+ received' | tr -dc 0-9)
  if [ -n "$a6" ]; then log6=$(sudo docker logs $k 2>&1 | grep 'chr-launch: management' | grep -cF "$a6")
    ros6=$(ros $k admin admin '/ipv6 address print terse where interface=ether1' | grep -cF "address=$a6/")
    ssh6=$(sshpass -p admin ssh $SSHO admin@$a6 '/system identity print' 2>/dev/null | grep -c "name: ${k#clab-lacp-}")
    p6=$(ping -6 -c 3 -W 2 $a6 2>/dev/null | grep -oE '[0-9]+ received' | tr -dc 0-9); fi
  printf '%s:sys=%s,eth0=%s,br0=%s,v6=%s,log6=%s,ros6=%s,ssh6=%s,p4=%s,p6=%s ' ${k#clab-lacp-} "$sys" "$e0" "$b0" "${a6:+yes}" "$log6" "$ros6" "$ssh6" "${p4:-0}/3" "${p6:-0}/3"; done; }
early() { t=0; while [ $t -lt 600 ]; do o=$(sudo docker exec $C1 sh -c 'printf "%s:" "$(cat /proc/sys/net/ipv6/conf/default/disable_ipv6)"; ls /sys/class/net | grep -E "^eth[1-9]" | tr "\n" ,' 2>/dev/null) && {
  echo "${o}:loglines=$(sudo docker logs $C1 2>&1 | grep -c chr-launch)"; return; }; sleep 0.1; t=$((t+1)); done; echo "none"; }
for r in $(seq 1 $RUNS); do
  $CLAB deploy -t lacp-$T.clab.yml --reconfigure > /tmp/v6-deploy.txt 2>&1 & dp=$!
  e=$(early); wait $dp || { echo "DEPLOY FAILED $B $T run=$r"; tail -5 /tmp/v6-deploy.txt; continue; }
  wait_healthy $C1 300 >/dev/null; wait_healthy $C2 120 >/dev/null; sleep 5
  echo "RES $B v6tx $T $NF run=$r fresh devices=$(tot) sending=[$(dev)] early=$e mgmt=[$(mgmt)] couldnot=$(nmark $C1 'could not')/$(nmark $C2 'could not')"
  n=$(nmark $C1 'RouterOS ready'); $CLAB restart -t lacp-$T.clab.yml --node c1 > /tmp/v6-restart.txt 2>&1; wait_new_marker $C1 'RouterOS ready' $n 300 >/dev/null; sleep 5
  echo "RES $B v6tx $T $NF run=$r clab-restart-node devices=$(tot) sending=[$(dev)] mgmt=[$(mgmt)] couldnot=$(nmark $C1 'could not')/$(nmark $C2 'could not')"
  $CLAB destroy -t lacp-$T.clab.yml --cleanup >/dev/null 2>&1
done

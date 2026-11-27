# v6tx.sh <runs>: which CHR data devices send IPv6 of their own (#3636 5646b9a4). The LACP lab in L/, per run: a fresh
# deploy and a containerlab restart --node c1; after each, every brN, tapN and ethN with a nonzero IPv6 send counter in
# /proc/net/dev_snmp6 (Ip6OutRequests, and of those DAD neighbor solicitations, MLDv2 reports, router solicitations).
# The counters start when the device is made in or moved into the container. CHR_TAG picks the RouterOS version.
. ~/m/lib.sh; B=${LABEL:-pr}; T=${CHR_TAG:-7.24.5}; RUNS=${1:-5}; C1=clab-lacp-c1; C2=clab-lacp-c2
cd ~/m/L && sed "s#\${CHR_TAG:=7.24.5}#$T#" lacp.clab.yml > lacp-$T.clab.yml
dev() { for k in $C1 $C2; do sudo docker exec $k sh -c 'cd /proc/net/dev_snmp6; for f in br[1-9]* tap[1-9]* eth[1-9]*; do [ -e "$f" ] && { echo "DEV $f"; cat $f; }; done' 2>/dev/null |
  awk -v k=${k#clab-lacp-} 'function out(){ if (d!="" && o>0) printf "%s.%s:out=%d,ns=%d,mld=%d,rs=%d ", k,d,o,n,m,r }
    $1=="DEV"{out(); d=$2; o=n=m=r=0} $1=="Ip6OutRequests"{o=$2} $1=="Icmp6OutNeighborSolicits"{n=$2} $1=="Icmp6OutMLDv2Reports"{m=$2} $1=="Icmp6OutRouterSolicits"{r=$2} END{out()}'; done; }
tot() { for k in $C1 $C2; do sudo docker exec $k sh -c 'ls -d /proc/net/dev_snmp6/br[1-9]* /proc/net/dev_snmp6/tap[1-9]* /proc/net/dev_snmp6/eth[1-9]* 2>/dev/null' ; done | wc -l; }
for r in $(seq 1 $RUNS); do
  $CLAB deploy -t lacp-$T.clab.yml --reconfigure > /tmp/v6-deploy.txt 2>&1 || { echo "DEPLOY FAILED $B $T run=$r"; continue; }
  wait_healthy $C1 300 >/dev/null; wait_healthy $C2 120 >/dev/null; sleep 5
  echo "RES $B v6tx $T run=$r fresh devices=$(tot) sending=[$(dev)]"
  n=$(nmark $C1 'RouterOS ready'); $CLAB restart -t lacp-$T.clab.yml --node c1 > /tmp/v6-restart.txt 2>&1; wait_new_marker $C1 'RouterOS ready' $n 300 >/dev/null; sleep 5
  echo "RES $B v6tx $T run=$r clab-restart-node devices=$(tot) sending=[$(dev)]"
  $CLAB destroy -t lacp-$T.clab.yml --cleanup >/dev/null 2>&1
done

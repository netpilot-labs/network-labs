# speeds.sh <runs>: port-speeds on a kind (ether5=2.5G), a group (2..3=25G, 4..5=100G), a node replacing the group list
# (p2: ether2=1G), a node clearing it (p3: []), a node with no group (p4: the kind list). Reads the rate RouterOS reports
# on ether2..ether5 of every node, the launcher's speed line and QEMU's -device speed. Then invalid inputs.
. ~/m/lib.sh; B=${LABEL:-pr}; RUNS=${1:-3}; cd ~/m/P
declare -A WANT=([p1]="25Gbps,25Gbps,100Gbps,100Gbps" [p2]="1Gbps,10Gbps,10Gbps,10Gbps" [p3]="10Gbps,10Gbps,10Gbps,10Gbps" [p4]="10Gbps,10Gbps,10Gbps,2.5Gbps")
for r in $(seq 1 $RUNS); do
  $CLAB deploy -t speeds.clab.yml --reconfigure > /tmp/ps-deploy.txt 2>&1 || { echo "DEPLOY FAILED $B run=$r"; tail -5 /tmp/ps-deploy.txt; continue; }
  for n in p1 p2 p3 p4; do wait_healthy clab-ps-$n 300 >/dev/null; done
  for n in p1 p2 p3 p4; do c=clab-ps-$n
    m=$(ros $c admin admin '/interface ethernet monitor ether2,ether3,ether4,ether5 once')
    got=$(echo "$m" | awk '/ rate:/{print $2","$3","$4","$5}'); fdx=$(echo "$m" | awk '/full-duplex:/{print $2","$3","$4","$5}')
    q=$(sudo docker exec $c ps | grep -oE 'id=nic[1-4],[^ ]*speed=[0-9]+' | sed -E 's/.*id=nic([0-9]).*speed=([0-9]+)/nic\1=\2/' | sort | tr '\n' ' ')
    [ "$got" = "${WANT[$n]}" ] && v=MATCH || v=DIFF
    echo "RES $B speeds run=$r $n $v want=${WANT[$n]} routeros=$got fdx=$fdx qemu=[$q] launcher=[$(sudo docker logs $c 2>&1 | grep 'data NIC speeds' | tail -1 | sed 's/.*Mb\/s)://')]"
  done
  $CLAB destroy -t speeds.clab.yml --cleanup >/dev/null 2>&1
done
# invalid inputs: one bad node each, the error line, and whether a container was left
bad() { printf 'name: inv\ntopology:\n  nodes:\n    x1:\n      kind: mikrotik_chr\n      image: mikrotik/chr:7.24.5\n      port-speeds:\n%s\n' "$2" > inv.yml
  $CLAB deploy -t inv.yml > /tmp/inv.txt 2>&1; rc=$?; left=$(sudo docker ps -a --format '{{.Names}}' | grep -c '^clab-inv-')
  echo "RES $B invalid $1 rc=$rc containers_left=$left error=$(grep -iE 'error|invalid|port-speeds' /tmp/inv.txt | sed 's/\x1b\[[0-9;]*m//g' | head -2 | tr '\n' ' ' | cut -c1-300)"
  $CLAB destroy -t inv.yml --cleanup >/dev/null 2>&1; }
bad port1      '        - {port: 1, speed: 1000}'
bad overlap    '        - {port: 2..4, speed: 1000}
        - {port: 4, speed: 1000}'
bad fraction   '        - {port: 2, speed: 1000.5}'
bad string-1G  '        - {port: 2, speed: 1G}'
bad over-limit '        - {port: 65, speed: 1000}'

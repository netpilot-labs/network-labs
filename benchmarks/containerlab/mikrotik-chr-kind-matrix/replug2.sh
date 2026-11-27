# replug.sh <deploys> <reboots>: two routers bonded on ether32+ether33 (port-speeds 25G there, 32 data NICs: the
# PCI-bridge layout where #3568's launcher re-plugs NICs RouterOS lost). r2 is rebooted from inside RouterOS; after each
# reboot: the launcher's re-plug count, r2's interface count, the rate on ether32/33, LACP on both, a ping over the bond.
. ~/m/lib.sh; B=${LABEL:-pr}; D=${1:-1}; RB=${2:-3}; cd ~/m/Q
ipr() { curl -s -m 10 -u admin:admin -X POST -H 'Content-Type: application/json' -d "{\"bond\":\"bond1\",\"duration\":\"1s\"}" http://$(ip_of clab-rp-$1)/rest/interface/bonding/monitor-slaves | python3 ~/m/lacp.py ros; }
rep() { c=clab-rp-r2; t=0; while [ $t -lt 90 ]; do case "$(ipr r1)$(ipr r2)" in 2/2*2/2*) break;; esac; sleep 3; t=$((t+3)); done
  m=$(ros $c admin admin '/interface ethernet monitor ether26,ether32,ether33 once')
  echo "RES $B replug26 d=$d $1 lacp_after=${t}s r1=$(ipr r1) r2=$(ipr r2) r2.ifaces=$(ros $c admin admin '/interface ethernet print count-only' | tr -dc 0-9)/33 r2.rate(26,32,33)=$(echo "$m" | awk '/ rate:/{print $2","$3","$4}') fdx=$(echo "$m" | awk '/full-duplex:/{print $2","$3","$4}') ping=$(ros clab-rp-r1 admin admin '/ping 10.3.0.2 count=5' | grep -oE 'received=[0-9]+' | tail -1) replug=$(nmark $c 're-plugging') rebootchk=$(nmark $c 'RouterOS rebooted: checking') failed=$(nmark $c 'check FAILED') health=$(health $c)"; }
for d in $(seq 1 $D); do
  $CLAB deploy -t rp2.clab.yml --reconfigure > /tmp/rp.txt 2>&1 || { echo "DEPLOY FAILED replug"; tail -5 /tmp/rp.txt; continue; }
  wait_healthy clab-rp-r1 400 >/dev/null; wait_healthy clab-rp-r2 300 >/dev/null; rep fresh
  for x in $(seq 1 $RB); do
    curl -s -m 10 -u admin:admin -X POST -H 'Content-Type: application/json' -d '{}' http://$(ip_of clab-rp-r2)/rest/system/reboot >/dev/null 2>&1; sleep 20
    for i in $(seq 1 36); do ros clab-rp-r2 admin admin '/system identity print' | grep -q 'name: r2' && break; sleep 5; done; sleep 30; rep reboot$x+30s
  done
  sudo docker logs clab-rp-r2 2>&1 | grep -E 're-plug|rebooted|data NIC' | sed 's/^/LOG r2: /'
  $CLAB destroy -t rp2.clab.yml --cleanup >/dev/null 2>&1
done

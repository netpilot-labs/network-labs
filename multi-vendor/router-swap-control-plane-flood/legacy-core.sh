#!/bin/bash
# legacy-core.sh: makes the lab's Cisco IOL routers behave like legacy equipment that chokes when its control plane is busy.
#
# What it does: every 2 s it counts the TCP RSTs and SYN-ACKs each cisco_iol node sends (tc clsact egress counters it adds
# on the node's eth1+ interfaces). A node answering a connection flood at ON (30) or more a second gets its container
# starved of CPU: 1 ms per PERIOD (1 s), written to the container's cgroup cpu.max. Every PROBE (50) s the cap lifts for
# 3 s to re-test: a node still answering KEEP (10) or more a second is starved again, else it gets full CPU back. A node
# that is not answering a flood is never touched, so the lab runs at full speed until the flood starts.
# This is the condition the recorded run used. On full-speed images the same 250-a-second flood barely registers.
#
# Needs: root (or sudo) on the lab VM host, cgroup v2 with Docker's systemd cgroup driver (container cgroups at
# /sys/fs/cgroup/system.slice/docker-<id>.scope, as on the NetPilot lab VM), and tc and nsenter on the host.
# Run it on the host before the flood:   nohup ./legacy-core.sh > legacy-core.log 2>&1 &
# It stops by itself after RUN s (4 hours). Every setting above can be overridden from the environment, e.g. PROBE=20.
#
# Stop it and restore full CPU:   ./legacy-core.sh --off
# which kills the watcher and, for each cisco_iol container, does the same as
#   echo "max 100000" | sudo tee /sys/fs/cgroup/system.slice/docker-<container id>.scope/cpu.max
# The tc clsact counters it added stay on the nodes' interfaces until the lab is destroyed (they only count packets).
PERIOD=${PERIOD:-1000000}; ON=${ON:-30}; KEEP=${KEEP:-10}; PROBE=${PROBE:-50}; RUN=${RUN:-14400}; T0=$(date +%s); LP=$T0
declare -A tight
cg(){ echo /sys/fs/cgroup/system.slice/docker-$(docker inspect -f '{{.Id}}' $1).scope/cpu.max; }
if [ "$1" = "--off" ]; then
 sudo pkill -f 'legacy-core\.sh$'   # the watcher (started with no arguments), not this --off call
 for c in $(docker ps -q --filter label=clab-node-kind=cisco_iol); do echo "max 100000" | sudo tee $(cg $c) >/dev/null; echo "full CPU $(docker inspect -f '{{.Name}}' $c)"; done
 exit 0
fi
rst(){ local pid=$(docker inspect -f '{{.State.Pid}}' $1) tot=0 i p
 for i in $(sudo nsenter -t $pid -n ip -o link show | awk -F': ' '{print $2}' | cut -d@ -f1 | grep -E '^eth[1-9]'); do
  if ! sudo nsenter -t $pid -n tc qdisc show dev $i | grep -q clsact; then sudo nsenter -t $pid -n tc qdisc add dev $i clsact
   sudo nsenter -t $pid -n tc filter add dev $i egress protocol ip u32 match ip protocol 6 0xff match u8 0x04 0x04 at 33 action pass; sudo nsenter -t $pid -n tc filter add dev $i egress protocol ip u32 match ip protocol 6 0xff match u8 0x12 0x12 at 33 action pass; fi
  p=$(sudo nsenter -t $pid -n tc -s filter show dev $i egress | awk '/Sent/{s+=$4} END{print s+0}'); tot=$(( tot + ${p:-0} )); done; echo $tot; }
declare -A last
while [ $(( $(date +%s) - T0 )) -lt $RUN ]; do
 cs=$(docker ps -q --filter label=clab-node-kind=cisco_iol)
 for c in $cs; do t=$(rst $c); r=$(( (t - ${last[$c]:-$t}) / 2 )); last[$c]=$t
  if [ $r -ge $ON ] && [ "${tight[$c]}" != 1 ]; then echo "1000 $PERIOD" | sudo tee $(cg $c) >/dev/null; tight[$c]=1; echo "$(date -u +%T) tight $(docker inspect -f '{{.Name}}' $c) rst=$r"; fi; done
 if [ $(( $(date +%s) - LP )) -ge $PROBE ]; then LP=$(date +%s); declare -A a
  for c in $cs; do [ "${tight[$c]}" = 1 ] && { echo "max 100000" | sudo tee $(cg $c) >/dev/null; a[$c]=$(rst $c); }; done
  if [ ${#a[@]} -gt 0 ]; then sleep 3
   for c in "${!a[@]}"; do b=$(rst $c); r=$(( (b - ${a[$c]}) / 3 ))
    if [ $r -ge $KEEP ]; then echo "1000 $PERIOD" | sudo tee $(cg $c) >/dev/null; else tight[$c]=0; echo "$(date -u +%T) free $(docker inspect -f '{{.Name}}' $c) probe=$r"; fi; last[$c]=$b; done; fi
  unset a; fi
 sleep 2
done

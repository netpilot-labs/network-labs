# lacp.py ros|linux : summarise LACP state from stdin
# ros: REST JSON of /interface/bonding/monitor-slaves -> "<members collecting+distributing with a partner>/<members> key=<keys> pkey=<partner keys>"
# linux: /proc/net/bonding/bond0 -> "<slaves in the active aggregator with a partner>/<slaves> key=<actor key> pkey=<partner key>"
import json, re, sys
mode, t = sys.argv[1], sys.stdin.read()
Z = "00:00:00:00:00:00"
if mode == "ros":
    try: rows = json.loads(t)
    except Exception: print("0/? err"); sys.exit()
    if isinstance(rows, dict): rows = [rows]
    ok = sum(1 for r in rows if "C" in r.get("flags", "") and "D" in r.get("flags", "") and r.get("partner-sys-id", Z).lower() != Z)
    print(f"{ok}/{len(rows)} key={','.join(r.get('key','?') for r in rows)} pkey={','.join(r.get('partner-key','?') for r in rows)}")
else:
    act = re.search(r"Active Aggregator Info:\s*\n\s*Aggregator ID: (\d+)", t)
    act = act.group(1) if act else None
    ak = re.search(r"Actor Key: (\d+)", t); pk = re.search(r"Partner Key: (\d+)", t)
    sl = t.split("Slave Interface:")[1:]
    ok = 0
    for s in sl:
        a = re.search(r"Aggregator ID: (\d+)", s); p = re.search(r"details partner lacp pdu:.*?system mac address: ([0-9a-f:]+)", s, re.S)
        if a and act and a.group(1) == act and p and p.group(1) != Z: ok += 1
    print(f"{ok}/{len(sl)} key={ak.group(1) if ak else '?'} pkey={pk.group(1) if pk else '?'}")

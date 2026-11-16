#!/usr/bin/env python3
# Misconfig simulator: ~N TCP connection attempts/sec at the Cisco core addresses.
# Non-blocking connects: one SYN fired per attempt, paced; rate holds even when
# the SYNs are dropped/policed (we never wait on a reply).
import socket, time, sys, itertools
rate = int(sys.argv[1]) if len(sys.argv) > 1 else 250
targets = [
    ("10.255.0.1", 179), ("10.255.0.2", 179), ("10.255.0.3", 179),  # core loopbacks
    ("10.0.12.1", 179),  ("10.0.23.1", 179),  ("10.0.13.2", 179),   # core interface IPs
]
interval = 1.0 / rate
cyc = itertools.cycle(targets)
start = time.time(); n = 0; last = start
while True:
    ip, port = next(cyc)
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setblocking(False)
    try:
        s.connect_ex((ip, port))   # fires the SYN, returns immediately
    except OSError:
        pass
    finally:
        s.close()
    n += 1
    now = time.time()
    tnext = start + n * interval
    if tnext > now:
        time.sleep(tnext - now)
    if now - last >= 5:
        sys.stdout.write("attempts=%d elapsed=%.1f achieved_rate=%.1f/s\n" % (n, now-start, n/(now-start)))
        sys.stdout.flush(); last = now

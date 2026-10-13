---
name: nxeon-vm-move-real-runs-2026-10-09
description: "First real dedicated-IP VM moves to node-7 (2026-10-09): 2 of 3 done, mobilkit rolled back; OVH IP-move time varies 4-12+ min; recovery recipe"
metadata:
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-10-09T15:16:00.171Z
---

Real VM-move engine runs, primary -> node-7 (2026-10-09). Engine fix (wait for OVH task, retry 409) is committed on main; it only takes effect after `systemctl restart nxeon-worker` (worker runs tsx from source; the web deploy auto-rolled back on a loaded primary, which does not matter for the worker).

- spyblox-vps: DONE, now VM 88008 on node-7 (IP 15.235.174.195). Source VM 660 kept stopped 7 days.
- terraria-i2ydef (Ahuzams): DONE, now VM 88009 (IP 51.79.181.111). Source VM 109 kept stopped.
- mobilkit (VM 112, IP 15.235.171.120): first attempt ROLLED_BACK (then retried with 30 min timeout and DONE as VM 88011 on node-7). OVH took >720s to move the IP, engine rolled back and restarted the source, then OVH finished the move late, leaving the IP on node-7 with no VM (customer dark ~19 min). Fixed by manually moving the IP back (scratchpad `ovh-moveback-mobilkit.ts`). Retry succeeded 2026-10-09 15:47; source VM 112 kept stopped.

**Why:** OVH IP-move duration is 4 to 12+ min and unpredictable; the engine's 720s timeout can lose the race, and a late OVH finish after rollback strands the IP.
**How to apply:** for any future dedicated-IP move, keep the 30 min timeout and the MOVE_IP timeout (or make rollback cancel/check the OVH task first), pick a quiet hour, and warn the owner. If a move is rolled back, always check `/ip/{ip}` routedTo afterwards, preflight refuses a re-run while the IP is on the wrong service. VMIDs are never reused (88010 was burned by the rollback).

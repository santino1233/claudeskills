---
name: nxeon-node-ram-tuning
description: primary Proxmox node RAM was CRITICAL (85%); fixed via ARC cap + ballooning + orphan-VM cleanup on 2026-08-21
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-09-06T01:18:09.329Z
---

The primary Proxmox host (`ns5002569`, 51.79.162.96, 62 GB) hit CRITICAL at 85% RAM / swap-exhausted on 2026-08-21. Root causes + fixes applied:

1. **ZFS ARC was uncapped at ~14 GB.** Capped to 8 GB — runtime + persistent in `/etc/modprobe.d/zfs-arc.conf` (`zfs_arc_max=8589934592`). If RAM pressure returns, ARC is NOT the cause anymore.
2. **No ballooning on any VM (`balloon=off`).** Enabled with floors via `qm set <id> --balloon <minMB>`: 105→4096, 200→4096, 110→3072, 8000→3072, 106→2048, 107(Eva/primegc1)→1536. Devices are LIVE and armed; Proxmox pvestatd auto-deflates guests toward these floors only when host RAM crosses ~80%. Don't be alarmed that `info balloon` shows actual≈max when the host is calm — that's correct.
3. **Orphan VMs destroyed** (`qm destroy --purge`): 101 test, 102 ggjgjhgjghh(160G), 103 minecraft-mm8w85, 104 movieshack — reclaimed ~285 GB committed disk. **KEPT VM 100 "soulpilates"** (stopped, 15G) — do NOT delete without confirming it's a dead copy; name matches the real client.

Result: 52→43 GB used, ARC 14→8 GB. Running VMs after: 105 studionexis-soul, 106 nexis-app, 107 primegc1(Eva), 110 kodely-app, 200 hosting-1, 8000 nxeon-mail.

Note: the admin panel's disk "130% committed" is a DB-side sum of customer [[nxeon-server-controlpanel]] `Server` plan sizes, NOT the zpool (vmdata was only 25% actually used). Orphan-VM deletion won't move that %; it's a plan-oversell config number. See [[nxeon-server-topology]].

**UPDATE 2026-09-06 — CRITICAL RAM recurred, root-caused via a real OOM-kill, fixed by
migrating 3 VMs to node-2.** The 2026-08-21 fix didn't hold: by tonight, configured VM
memory on primary had grown back to **70,144MB against ~64,084MB physical** (15 running
VMs), swap was 100% full, and the kernel's *global* OOM-killer had killed customer VM
sausaugepro's own kvm process directly — twice in one day (03:50 and 20:17 UTC) — not a
per-VM cgroup limit, a host-wide `constraint=CONSTRAINT_NONE` OOM. This is what actually
caused the "GAME_POWER restart job reported DONE but VM was stopped" symptom the owner
first asked about — the restart job itself was unrelated; the VM was killed 16 minutes
*after* it finished, by the host, for being one of the largest RSS processes when the host
ran out of memory. Root-caused via primary's own `dmesg -T | grep oom` (not the guest's —
the guest sees nothing, since it's killed from outside), which is the lesson: an OOM
symptom on a specific VM always needs a HOST-level dmesg check, not just a guest-level one.

Fixed by migrating three non-dedicated-IP VMs to node-2 (67GB RAM, ~8GB committed at the
time — real headroom): sausaugepro (117→101, 8192MB), rust-w75hko (113→102, 4096MB), and
kaymofilms-vps (116→103, resized 4096→2048MB first since its real usage was ~814MB).
Freed ~16.4GB of configured commitment from primary, bringing it to ~53.8GB against
64GB — comfortably under, for the first time. Full migration mechanics, the two real bugs
found along the way (a missing Rust game-port forward, and a website reverse-proxy
hardcoded to a private IP that would have broken invisibly), and the vmid-collision
incident are in docs/DOCUMENTATION.md's "Migrating a customer VPS/game-server to another
node" section — worth reading in full before the next RAM crisis or the next
cross-node VPS migration, since several of the gotchas there are non-obvious and easy to
repeat. **Also confirms**: the orphaned `ggjgjhgjghh` DB row (vmid 102) from THIS file's
2026-08-21 entry was only ever disk-cleaned (`qm destroy --purge`) — its `Server` row was
never deleted from the DB, and its `vmid` sat there for two weeks as a landmine until it
collided with a real vmid reuse tonight. **Orphan-VM cleanup must delete the DB row, not
just the Proxmox VM**, or the next node/vmid reuse hits the same collision.

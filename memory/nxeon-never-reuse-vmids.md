---
name: nxeon-never-reuse-vmids
description: "Always allocate a brand-new VMID for any Nxeon VM — never reuse an ID whose old server is gone, and never trust `pvesh get /cluster/nextid`"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 238c8842-5d86-4a94-b36d-416254ca5de2
  modified: 2026-09-06T16:26:01.856Z
---

When creating or restoring any VM on the Nxeon fleet, allocate a **VMID that has never
been used before on any node**. Never reuse an ID just because the VM that held it was
destroyed, migrated away, or decommissioned.

`pvesh get /cluster/nextid` is NOT safe for this — it returns the *lowest free* ID, which
is precisely a recycled one. Determine the fleet-wide high-water mark instead (check every
node's `/etc/pve/qemu-server/*.conf` **and** the PVE task logs at `/var/log/pve/tasks/index`
for IDs that existed historically) and go above it.

**Why:** VMIDs are how the platform, the Nxeon DB (`Server.vmid`), NAT rules, backups and
task history all address a machine. A recycled ID silently collides with stale references —
a DB row, an old backup archive, a monitoring series — and makes an action land on the wrong
customer's server. On 2026-09-06 a stale DB↔Proxmox vmid mismatch made three decommissioned
copies look like live customer outages and led to three wrong VMs being started; the same
day a restore was started onto vmid 100, which the DB still maps to `freemc-host`. Both
came from ID reuse. Note VM 120 also appears in node-1's task history, so "not currently
in use" is not the same as "never used".

**How to apply:** Before `qmrestore`/`qm create`, scan both nodes' configs and task logs for
the highest VMID ever seen and pick above it. Reserved ranges stay reserved: 200 (hosting),
8000 (mail), 9000-9010 (templates). Related: [[nxeon-server-topology]],
[[nxeon-migration-reliability]].

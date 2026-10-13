---
name: nxeon-node1-cpu-and-devapp-relocation
description: "Primary node CPU investigation (2026-09-06) traced to concurrent peer-session next builds, not automation — nxeon-sandbox and nxeon-v2 relocated to node-2 as the fix; nxeon-staging is next but gated"
metadata:
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-09-06T11:11:13.193Z
---

**Owner asked what was driving primary CPU load (2026-09-06), then specifically asked about
Nxeon's own internal operations as a possible cause (not just customer VMs).** Investigation found
three distinct contributors, not one: `darkeden-guard-sg` (real customer VM, 233%, expected/normal
for that workload), Nxeon's own prod app (negligible), and — the one the owner's follow-up question
was really asking about — two concurrent `next build` processes (`nxeon-staging`, `nxeon-v2`)
together costing ~286%. Checked both scheduled Claude-platform tasks
(`nexis-nightly-improver`, `nxeon-improve` — see [[nxeon-improve-agent]]) via
`mcp__scheduled-tasks__list_scheduled_tasks`: both disabled, ruling out automation. `ListAgents`
found the real cause: **5 separate peer Claude Code sessions running on this same host**, one
confirmed (by the owner) to be doing manual dev work on `nxeon-v2` at that moment. Nothing was
malfunctioning — ordinary concurrent development work lands on the same physical CPU as every
customer VM's hypervisor load, because node-2 (Hetzner Falkenstein, 12 vCPU, ~67GB RAM, mostly idle)
existed but internal dev/staging apps had never been moved onto it.

**Fix: relocate the internal dev/staging apps to node-2**, one at a time, gated on who was actively
using each:
- Owner said "wait, someone's on v2 right now" → did **nxeon-sandbox** first (full migration: app +
  its own local Postgres DB + web/worker systemd units + nginx `proxy_pass` target, zero code
  changes needed). Verified end-to-end (DB row counts, `/api/health` db/worker operational, external
  HTTPS through the primary's existing TLS), old primary services stopped+disabled (not deleted) as
  rollback safety.
- Owner then said **"we can also move v2 to node 2 now as well"** (work there was done) → migrated
  **nxeon-v2** the same way. Found and correctly worked around one real discrepancy: the nginx
  vhost's own header comment claimed "no backend, no database" (true of the separate, unrelated
  `/opt/nexion-ui` port-3020 sandbox) but `nxeon-v2`'s actual `.env` had a real `DATABASE_URL` —
  trusted the `.env` (ground truth) over the stale comment, and migrated the DB too.
- **nxeon-staging** is the deliberate next candidate but was NOT touched this round — it's what the
  background game-catalog verification agent was actively exercising, so it's gated on that agent
  finishing (or the owner re-authorizing sooner).

**The full runbook, firewall gotchas (reusing `nxeon_agent_allow_v4/v6`, the
`NXEON_FW_REQUIRED_PORTS` override for `firewall-safe-apply.sh`'s primary-shaped 80/443 default
check), and the credential-handling near-miss are all written up in `docs/DOCUMENTATION.md` →
"Relocating an internal dev/staging app to another node (2026-09-06)".** Read that section before
doing this again for staging — don't re-derive it from scratch.

**Why this matters beyond the immediate fix:** this is a reusable pattern (move an app+DB+systemd
stack cross-node while keeping DNS/TLS on the primary via `proxy_pass`), distinct from the
VM-relocation runbook in [[nxeon-migration-reliability]] — same underlying "reverse-proxy from the
primary" architecture as the `kaymofilms.com` customer-website migration, just applied to Nxeon's
own internal tooling instead of a customer's site.

**How to apply:** if the owner asks about primary CPU again, check `ListAgents` for concurrent peer
sessions before assuming a code/automation bug — this was the second time in this area that the real
cause was mundane concurrent dev activity, not a platform defect. If asked to move `nxeon-staging`,
follow the docs runbook above rather than re-investigating firewall/credential mechanics from zero.

**2026-10-06 crash:** the primary HARD-CRASHED (journal stops mid-stream at 15:23:48, no shutdown, no OOM line) while ~8 parallel agents ran `next build` / full test suites / dev servers / Playwright / a JDK on it (load ~48, swap full). All 15 VMs came back on reboot. Afterwards RAM was again at 2-3 GB free (a livechat agent's `next build` alone ~7 GB). Rule: when running several agents, cap them (no `next build` or full suite unless >=12 GB free, nice/ionice, NODE_OPTIONS=--max-old-space-size=3072, stop dev servers right after use), or move agent builds off the primary. The "123.19.175.110" root SSH key (edmem@LAPTOP-7AIMKP15) is the owner's own Claude desktop connection, not an intruder.

**2026-10-07 node-6 / Syntech (VM 667, reserved 0-2,4-6):** guest reported 5–8% CPU steal. Cause = host housekeeping (incl. the 30 s nxeon-cpu-reserve.timer running `qm`) scheduled on his reserved threads. Fix: `systemctl set-property {system.slice,user.slice,init.scope} AllowedCPUs=3,7` (persistent drop-ins in /etc/systemd/system.control/; VMs live in qemu.slice so unaffected). Measured vCPU run-queue wait after: 0.15%. Revert = `systemctl set-property <unit> AllowedCPUs=` . Apply the same pattern on any node with CPU reservations.
**2026-10-07 21:00 MYT:** Syntech upgraded to the whole of node-6: VM 667 = 8 vCPU (affinity 0-7), 54 GB (55296, balloon pinned), 340 GB disk; Plan row d0357d54… updated to match (price/grandfathered renewal unchanged 7580 + IP = $78.79). node-6 `enabled=false` (exclusive to Syntech, agreed in chat; refund promised if issues persist in the 24 h observation). nxeon-cpu-reserve.timer DISABLED (no longer needed). Host slices still on 3,7 (share 2 of his threads). Customer note logged in admin.

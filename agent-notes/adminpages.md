# Admin servers + clients redesign — agent notes (2026-10-01)

Branch `feature/admin-servers-clients-redesign`, worktree `/opt/nxeon-wt-adminpages`.
Screenshots: `/root/agent-notes/adminpages/` (desktop-dark, mobile-dark, desktop-light; `interact_*.png`).

## IA
**/admin/servers/[id]?tab=** overview · network · access · compute · software · files · backups · game (game servers) · move · billing · activity · danger
**/admin/users/[id]?tab=** profile · servers · billing · support · security · partner · actions
**/admin/servers** server-side filtered/paginated list; **/admin/users** state chips + wider search.
Full description: docs/DOCUMENTATION.md → "Admin server & customer pages redesign"; chore mapping: docs/ADMIN-OPS-CATALOG.md (last section).

## Wired vs stubbed
- Real: everything except VM move execution. New audited actions in lib/actions-admin-server.ts / lib/actions-admin-client.ts wrap existing paths (serverAction, reinstallToOs, snapshots, backups, port forwards, firewall, subdomain, rDNS, services, backup schedule, delete, 2FA reset, sessions, verification, password reset, flags, account delete).
- Stub: VM move (preview/run/rollback/cleanup/history) via lib/admin-server/vm-move-bridge.ts — engine is on unmerged feature/vm-node-migration. Integration: set ENGINE_PRESENT=true and call @/lib/vm-move/actions (same shapes). Runs also need VM_MOVE_UI_ENABLED=1.
- Not built (stated in UI): admin comp-resize, rescue mode, account merge execution (preview only).

## Verified
- tsc clean; test/admin-server-360.test.ts 31/31 (+ existing admin guard suites).
- Playwright vs dev server on throwaway DB nxeon_agt_adminpages with fixtures (scratchpad/adminpages/fixtures.ts): every tab 200, no error boundary (after fixing a BarChart function prop); clicks verified: audited password reveal, typed-hostname delete (disabled until exact → DELETE job + audit row), add flag, bulk reconcile (reports failures honestly), CSV export, tab-bar arrow keys.
- No Proxmox reachable in sandbox → live readings show "unreachable" states (that path is verified; the live-data path is not).

## Known issues / risks
- 76px mobile horizontal overflow comes from the A1 admin shell topbar (`div.ml-auto.flex.items-center.gap-1.md:ml-2`), also on /admin and /admin/ops — not this branch.
- A React hydration-attribute warning appeared once on client Servers/Billing tabs in dev; not root-caused.
- Dev server hit its 3 GB heap cap and restarted mid-run twice (heavy.sh NODE_OPTIONS) — a few routes were re-verified in later runs.
- File-manager operations only audited at "opened with reason".
- Rate limits are per-process in-memory (existing lib/rate-limit).

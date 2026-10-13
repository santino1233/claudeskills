# A2 adminops — progress note (2026-10-01)

Branch `feature/admin-ops-actions`, worktree `/opt/nxeon-wt-adminops`. Commits: db52dafe77, 7180b7c0c7.

## Done
- docs/ADMIN-OPS-CATALOG.md — 26 recurring chores mined from owner history, with frequency, manual procedure, portal equivalent.
- lib/admin-ops/* (pure rules + "use server" actions.ts), worker/admin-ops.ts (ADMIN_OPS executor), components/admin/ops/* (embeddable `ServerOpsPanel`), app/admin/ops/** (overview, servers, servers/[id], jobs, fleet, customers).
- Schema: JobType.ADMIN_OPS (additive; pushed only to throwaway DB nxeon_agt_adminops).
- Hook-ups outside area: worker/index.ts (import, handler `ADMIN_OPS: adminOps`, `adminOpsLockKey` in `lockKeyFor`), lib/dedicated-ip.ts (`opts.preferAddress`), lib/admin-groups.ts (nav tab "Ops console"), docs/DOCUMENTATION.md.
- Verified: unit tests 32/33 then fixed the 1 failure (root path) — re-run pending; `tsc --noEmit` whole tree clean except 2 test typing errors (fixed, re-run pending); sandbox end-to-end of executor (diagnose, guest_cmd reject/accept, ip_reassign, ip_release, drift_scan, orphan ip release, orphan-vm refusal, bulk delete fencing) passed.

## Not done / remaining (ordered)
1. Re-run: `heavy.sh bash -c "cd /opt/nxeon-wt-adminops && npx tsx --test test/admin-ops-logic.test.ts test/admin-ops-actions-guards.test.ts && npx tsc --noEmit -p ."`
2. UI never rendered (heavy-lock queue + disk/usage freezes): start dev on port 3107 with NXEON_SANDBOX=1 (.env present, untracked), Playwright screenshots of /admin/ops/* mobile+desktop; then `rm -rf .next`.
3. Integrator: drop `<ServerOpsPanel serverId={server.id} />` into app/admin/servers/[id]/page.tsx (not done by me, per brief).
4. Wire `lib/admin-ops/vm-move.ts` requestVmMove to the VM move engine when feature/vm-node-migration merges.
5. Follow-ups: node-agent probe endpoint for true cross-node reachability; comp (no-charge) resize; resend email (B); game-server grant (C).
6. Cleanup: `sudo -u postgres dropdb nxeon_agt_adminops; sudo -u postgres psql -c "DROP ROLE agt_adminops"`; delete worktree .env.

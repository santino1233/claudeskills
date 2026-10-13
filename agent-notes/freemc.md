# Agent F (freemc) — progress note, 2026-10-01

Branch fix/free-minecraft-stability-upsell, worktree /opt/nxeon-wt-freemc. Commits: b317f0c6f4 (pure libs + tests), 7dc11fbc98 (everything else).

## Done (committed)
- Investigation (read-only via `qm guest exec 100` on node-2). Root cause: Proxmox ballooning (vmid 100 `balloon: 2048`) shrinks freemc-host to ~1.8 GB when node-2 >80% RAM -> all 4 OOM kills this boot are global OOMs; guest swapped in 86 GB. Details: docs/DOCUMENTATION.md Part VII entry 2026-10-01 + Game servers reference section.
- Code: lib/freemc-limits.ts, lib/freemc-health.ts, lib/freemc-upsell.ts, worker/freemc-health.ts (+ 6-line hook in worker/index.ts), lib/actions-freemc-health.ts, app/api/free-minecraft/world-export/route.ts, components/customer/freemc/FreeMcHealthPanel.tsx, admin panels, schema (additive), settings keys, rollout scripts in scripts/freemc/rollout/.
- Data-loss fix: plugin changes now delete jars only (clearPluginJars) — old code wiped LuckPerms/IridiumSkyblock/Towny/Essentials data.

## Half-done / unverified
- `npx tsc --noEmit` NOT run successfully (heavy lock timed out twice). Expect a few type errors; fix first.
- Unit tests: 24/25 passed on the first run; the one failure (apostrophe in seeded server.properties body) was fixed but NOT re-run. test/freemc-limits.test.ts sizing rows were extended after that run.
- No Playwright/dev-server UI verification done (disk + lock pressure). Seed script for the throwaway DB: scratchpad fmc-seed.ts; screenshot script: scratchpad fmc-shots.mjs.
- RCON `tick query` / Paper `tps` parse formats not seen against a live reply.

## Remaining (in order)
1. `cd /opt/nxeon-wt-freemc && npx tsc --noEmit -p .` and fix.
2. `npx tsx --test test/freemc-limits.test.ts test/freemc-health.test.ts test/freemc-upsell.test.ts`
3. UI check of /dashboard/free-minecraft (Overview Performance + upgrade card, Mods tab card, hero queue strip) and /admin/free-minecraft, mobile + light mode.
4. `git merge main` into the branch.

## Owner actions (none applied)
1. `bash scripts/freemc/rollout/01-pin-guest-memory.sh --apply` (balloon=8192 on vmid 100; rollback `--rollback`) — the root-cause fix.
2. Deploy branch (additive db push).
3. `bash scripts/freemc/rollout/02-cleanup-orphans.sh` then `--apply` (43 orphan dirs, 1.4 GB -> trash).
4. `npx tsx scripts/freemc/rollout/03-recreate-asleep.ts --apply --limit 3` (repeat).
5. Optionally enable `free_minecraft_watchdog_autorestart`; consider 5 vCPU (reboot needed).

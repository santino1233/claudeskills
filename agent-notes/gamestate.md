# Agent R (gamestate) — progress note, 2026-10-01

Branch fix/game-runtime-integrity, worktree /opt/nxeon-wt-gamestate, commit caf61415a9 (pushed by hook).

## Done (committed)
- Postmortem + reference docs in docs/DOCUMENTATION.md (Game server control panel chapter, env vars row, 2026-10-01 change-history entry).
- Schema: new model GameRuntime + Server.gameRuntime relation (additive).
- lib/game-runtime.ts (pure rules), lib/game-runtime-probe.ts (probe/cache I/O), worker/game-runtime.ts (non-blocking fleet sweep + provision readiness).
- GAME_POWER/GAME_REINSTALL port-check target fix (forwarded public port), noRetry on post-action failure, intent recording, schedule sweep skips owner-stopped servers.
- GAME_CONFIG run-state reconciliation + "Apply & restart" UI; saveGameConfig keeps `_` markers.
- Auto-update audit + pinned-VERSION bump (vanilla MC, Bedrock) with backup/verify/rollback; honest copy all families; admin override + lock; GAME_AUTO_UPDATE=off.
- Customer hero badge/buttons follow game state; admin GameRuntimeCard on /admin/servers/[id]; /admin/game-health fleet page.
- test/game-runtime.test.ts 48 pass; game-update + provision-health tests pass.

## NOT done / unverified
1. tsc --noEmit on final state: CLEAN (EXIT=0, confirmed after report).
   heavy.sh bash -c "cd /opt/nxeon-wt-gamestate && npx tsc --noEmit -p ."
2. No Playwright/dev-server render (disk was 98-99%). Verify hero states by seeding GameRuntime rows in DB nxeon_agt_gamestate (still exists; drop with `sudo -u postgres dropdb nxeon_agt_gamestate` when done) and rendering a sandbox game server page on PORT 3101.
3. No live run of GAME_POWER/GAME_CONFIG/auto-update against a real VM — staging run required before promote.
4. /admin/game-health has no nav entry (lib/admin-nav.ts is A1's).
5. After deploy: `npx tsx scripts/game-readiness-run.ts --all` (owner) to backfill readiness.

## Owner follow-ups
- Node firewalls DROP unpublished ports -> SRV-less Minecraft clients get silent "timed out" on host:25565. Consider REJECT/tcp-reset, or per-node mc-router.
- Pre-existing failing tests on main (not mine): customer-actions-guards #22, portal-ui-audit #35, promo-race #45/#47.

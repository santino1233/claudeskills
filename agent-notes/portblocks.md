# portblocks agent notes (2026-10-01)
Branch fix/game-port-blocks-and-valheim-gaps, worktree /opt/nxeon-wt-portblocks.
See docs/DOCUMENTATION.md last section "Consecutive game-port blocks, Valheim worlds path and server name".
Files: lib/ipam.ts, lib/games.ts, lib/game-control.ts, lib/game-config.ts, components/customer/GameSettings.tsx,
worker/index.ts, worker/admin-ops.ts, worker/game-config.ts, worker/game-control.ts,
scripts/repair-nonconsecutive-forwards.ts, test/ipam-port-blocks.test.ts, test/valheim-gaps.test.ts.
Owner: run repair script dry-run then --apply after deploy (NXEON_DB_TARGET=nxeon). Never run by agent.
Full suite has 44 pre-existing failures on main (identical count with and without these changes).

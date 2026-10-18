# NX fast deploy (2026-10-18)

Branch `feature/fast-deploy` (worktree /tank/dev-worktrees/nx-fastdeploy), NOT merged. Commits: b69f76d9, b01481d4, 29fb2453.
Everything is OFF by default. `FAST_DEPLOY=1` (or `--fast`, or `scripts/ship-fast.sh`) turns the set on. Docs: docs/DOCUMENTATION.md "Fast deploy". Tests: test/fast-deploy-lib.test.ts (36, pass).

## Measured baseline (logs /root/promote-*.log, node-2 builds, journals)
| step | rc17 | valheim | rc3 | rc6 | assets | portals |
|---|---|---|---|---|---|---|
| promote total | 1187 | 1150 | 812 | 763 | 736 | 752 |
| node-2 total (lock wait + build) | 722 | 679 | 410 | 406 | 392 | 408 |
| fetch 1.1 GB | 118 | 89 | 24 | 35 | 19 | 25 |
| restart to healthy | 115 | 109 | 110 | 109 | 109 | 102 |
| rest on primary (npm, schema, stage, smoke, green, linger, worker) | 232 | 273 | 268 | 213 | 216 | 217 |

Last full ship (10-18, journals): dump 07:47:30-07:50:10 (2m40, prod+staging) -> staging deploy to 08:03 (build 449 s) -> modbuilder build 08:13-08:16 (2m19) -> promote 08:19-08:36 (build 450 s) -> checks 08:41. About 54 min.

Node-2 build phases (scratch, same commit): warm cache 436 s = compile 154, **type check 177**, page data 44, static 26, traces 35. Without the check: 264 s. Cold cache (path change) compile 266-317 s.

## What was found
1. **90 s of every "restart to healthy" is systemd's TimeoutStopSec**: journal `State 'stop-sigterm' timed out. Killing.` (08:32:17 -> 08:33:47). The old Next process never exits on SIGTERM. Cold start after that is ~25 s.
2. Two builds of one commit (staging + prod). Builds are not byte-identical (10,951 of 16,726 files differ for the same commit), so delta fetch against the live release does not help; staging and production also use different build inputs (APP_URL, NXEON_SANDBOX, settings snapshot), so the staging artifact cannot be reused as is.
3. 45 % of the fetch is duplicate or primary-owned (top-level .next/server = copy of standalone/.next/server, standalone/public, standalone static).
4. Webpack cache works (cold 266-317 s vs warm 154 s); the cache key includes the build dir path. Stable build id/actions key did not improve it (153 s vs 154 s) -> kept as explicit-only FAST_STABLE_BUILD.
5. Overlapping tsc with next build FAILS on memory: build 9.8 GB + tsc 4.3 GB > nxeon-build.slice cap 13.9 GB, memory pressure 72-80 %, swap, 13+ min. Rejected; check runs after the build.
6. Biggest hidden cost: node-2 build lock. Agent jobs held it for tens of minutes during my tests (valheim promote waited ~273 s). Not fixed (needs a policy: release builds before agent jobs).
7. Fetch measured: full 71 s / 240 MB wire; slim 29 s / 104 MB. 6 parallel streams only 13 s -> 10 s: not worth it.
8. Not done: faster worker-side npm install (about 10-20 s), webpack tuning, bigger slice (caps are a rule).

## Changes (flag -> effect)
- FAST_SHARED_BUILD: node-2 keeps an immutable artifact per input fingerprint (commit + build env + snapshot + node). deploy-staging --fast sends PRODUCTION's build inputs; promote --fast of the same commit reuses it (no second build). Both build in production's build dir (one warm cache).
- FAST_SEPARATE_TYPECHECK: next build skips its check (NXEON_SKIP_BUILD_TYPECHECK in next.config.ts); same `tsc -p tsconfig.next.json` runs after the build: inline for production, DEFERRED off the critical path for staging (unit keeps the lock, verdict in the artifact; production waits/refuses on failed, died, or >15 min).
- FAST_SLIM_FETCH, FAST_QUICK_STOP (15 s grace then SIGKILL), FAST_PRESMOKE_AS_GREEN (green is the smoke when blue/green exists; dry-run keeps the side smoke).
- `[timing]` lines + SUMMARY in every pipeline (always on).
- scripts/ship-fast.sh: prod-only DB dump only if schema.prisma or manual-migrations changed (backup-db.sh `NXEON_DB_BACKUP_DBS`), no staging dump, modbuilder image only if `deploy-modbuilder.sh --check` (read-only hash compare with the VM) says files differ, `--plan` mode.

## Before / after (estimate; no lock contention, unchanged modbuilder, no schema change)
| step | before | after |
|---|---|---|
| dump | 160 s | 0 (about 75 s prod only, when schema/SQL changed) |
| staging build on node-2 | 450 | about 265 (+ deferred check hidden) |
| staging fetch | 25-120 | 10-30 |
| staging primary side | about 215 | about 175 |
| modbuilder | about 140 + prompts | about 5 (--check) |
| prod build | 390-720 | about 10 (reuse) |
| prod fetch | 25-120 | 10-30 |
| prod restart to healthy | 110 | about 25 |
| prod primary rest | about 215 | about 175 |
| **ship (machine time, no human waits)** | about 45 min | about 12-14 min |

## Turn it on
`FAST_DEPLOY=1 REL=<branch> bash scripts/ship-fast.sh --plan`, then without --plan. Or per command: `scripts/deploy-staging.sh --fast`, `scripts/promote-production.sh --fast`. Off again: `FAST_DEPLOY=0`. To make it the default later, add `: "${FAST_DEPLOY:=1}"` at the top of scripts/lib/fastdeploy.sh. Per feature override FAST_<NAME>=0|1.

## Risks
- Full build + deferred-check path was NOT verified end to end: node-2 was saturated by agent work (memory pressure 80 %, page-data stuck 29 min even without my tsc). Verified instead: reuse path with ok / failed / pending-unit-gone / pending-then-ok verdicts on node-2 (real remote-build.sh), real systemd bounded stop (5.3 s with 5 s grace vs 90 s), slim fetch with fake ssh, key equality staging vs production inputs, 36 unit tests. A bug in the async remote run (infinite wait on failure under set -e) was found by test and fixed.
- Staging now runs production-input artifact: its few prerendered routes (/locations, manifest, icon, opengraph) carry production URL/settings; staging reads production DB public rows (SELECT) for the snapshot.
- Slim fetch drops the top-level `.next/server` from releases (nothing in app/lib/worker reads it; boot smoke covers it). Quick stop cuts long-lived connections at 15 s instead of 90 s.
- A type error is now found after staging is deployed (production refuses; ship-fast checks before asking approval).
- Artifact build output lives 4 deep on node-2 (about 1 GB each, hard links).

## First real fast ship: test plan
1. Merge the branch (owner), `ship-fast.sh --plan`.
2. Wait for a quiet node-2 (`devhost status`, memory PSI < 30).
3. `FAST_DEPLOY=1 scripts/deploy-staging.sh --dry-run`: check `[timing]` summary, artifact key, `ssh node-2 cat /tank/nxeon-deploy/artifacts/<key>/typecheck` becomes ok, fetch size about 650 MB.
4. `FAST_DEPLOY=1 scripts/promote-production.sh --dry-run`: expect "REUSING the artifact", no build, staged, side smoke, no swap.
5. Real ship via ship-fast.sh; watch `journalctl -u nxeon-web` (stop within 15 s), `deploys.log`, SUMMARY.
6. Negative test on staging only: commit a deliberate type error to a throwaway branch, `deploy-staging.sh --fast`, confirm production dry-run refuses.
7. Rollback drill: `scripts/rollback-release.sh --staging` with FAST_DEPLOY=1.

## Incident note
I did not run nginx on the primary. I ran my one light test file (bash/rsync/ssh fakes, no nginx) directly with /opt/nxeon's tsx on the primary several times before the rule; not through devhost. All builds/e2e ran on node-2.

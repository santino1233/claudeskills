# AW: Cyrus release candidate rc1, go/no-go (2026-10-11)

Branch `release/cyrus-rc1` (worktree `/tank/dev-worktrees/cyrus-rc1`) = `feature/cyrus-r2` + main `e62aa07c6d` + r49 QA 1/5-4/5. Nothing deployed. Runbook: `docs/CYRUS-TEST-DEPLOY.md`.

## Verdict: GO for the owner-only test, after a code review of the branch

## Found and fixed
- **The merged tree could not be built.** The type check ran out of memory: 6.3 GB heap against main's 3.5 GB, and the promote runs with Node's 4 GB default. Fixed with a cast in `lib/cyrus/host/nxeon.ts` (one structural PrismaClient comparison cost ~1.1M types), `tsconfig.next.json` and a 6 GB heap in `npm run build`. `npm run build` (the promote's own command) now passes on node-2. `devhost tsc` (5 GB) now dies without a message: use `devhost run -- env NODE_OPTIONS=--max-old-space-size=7168 npx tsc --noEmit`. Earlier "tsc clean" claims on r2 are suspect.
- Two checks the merge exposed (an auth regex test, stale light-theme CSS).
- `smoke-readonly.sh` ran only its first step when given several. Fixed, and it has a new `owner` step.

## Tests compared with main
- Suite: 6820 tests, 50 fail (main: 52). Every leftover fails on main too, or is flaky. Seam, db split, docs coverage, Dockerfile: 27/27. tsc: 0 errors.

## Neutral (every switch off)
Prod has no `CYRUS_*`/ping/`CYRUS_DATABASE_URL` env and no `cyrus_*`/preview setting; the owner is the only Cyrus user. A normal customer and an admin get the same 9 pages on rc1 and main (200, no Cyrus text, `/dashboard/cyrus` 404, pixel diff <= 0.08%; login 1.15% = random wallpaper). File table: runbook appendix.

## Risky (small, reviewed)
- `worker/game-mods.ts` now loads the delivery orchestrator at start. Check that the worker starts after the promote.
- Everyone gets `/cyrus-host*` → 404, the `x-cyrus-host` header stripped, and a slightly changed logout cookie (r49).
- The client IP comes from a new helper. It gives the same IP behind nginx.
- Token defaults changed. They reach only the owner.
- `pg_trgm` is not on prod. If creating it is refused, skip the library file.
- r49 5/5 is not in this branch: re-merge and re-run before the deploy.

## Rehearsal (restored 03:17 backup on a throwaway DB, dropped afterwards)
- Restore: 2m26s.
- 8 manual SQL files: under 0.2 s each.
- db push: 2 s, 10 CREATE statements, no data-loss warning; a second push changes nothing.
- Seed: 3 rows.
- 293 Nxeon tables: row counts and checksums identical. 24 new tables. 0 indexes lost; the expression indexes survive.

## Ready
Pack Loader jar reproducible, sha = pin (`/tank/cyrus-rc1-artifacts/`); nginx `/packs/` snippet 8/8 on a throwaway nginx; build service `/health` checked off the VM (hashes match; `docker build` only possible on VM 88001).

## Owner inputs
- Preview account: `nicholas.sj.albanese@gmail.com`. It is already the default; add nothing.
- Test server: `minecraft-f3izjh`, owned by that account. Paper 1.21.11, 4 GB/2 cores, node-7. Build for 1.21.11.
- Approve: the code review, the subscription usage for test builds, and a Cloudflare WAF skip if a Java client gets a challenge.

## Window
A quiet hour, for example 18:00-21:00 UTC (02:00-05:00 SGT), with no agent build on node-2. Allow about 20 min for the promote and about 1 h for supervised testing.

## Ordered commands (exact lines, smoke + rollback: runbook §0-§8)
ff-merge rc1 into main · 8 manual SQL files (`psql -1`) · `promote-production.sh --skip-staging-check` · seed · `/tank/cyrus-packs` + nginx snippet + canary · Pack Loader jar to `/tank/cyrus-managed` · `TAG=modbuilder:0.6 deploy-modbuilder.sh` · `.env` lines + worker env file + drop-in, restart worker then web · supervised build, Test Flight, Install on minecraft-f3izjh, real-client checks · `smoke-readonly.sh all`.

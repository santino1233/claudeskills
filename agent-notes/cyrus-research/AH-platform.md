# AH: Cyrus platform bundle (r37), 2026-10-11

Branch `feature/cyrus-r37-platform`, worktree `/tank/dev-worktrees/cyrus-r37`, 7 commits (5 parts + docs + fixes) on r2 3c23bfa9d2 (latest r2, merged). Docs: repo
`docs/CYRUS-PLATFORM.md`. Nothing deployed, applied, installed or run against production. No source files moved.

## What was built
1. **Monorepo plan + scaffold.** Target layout (apps/nxeon, apps/cyrus, apps/cyrus-admin, apps/cyrus-site, packages/*).
   `platform/targets.json` holds the rules: what feeds each target and where each file moves. `scripts/platform/depmap.mjs`
   writes `docs/cyrus-platform-depmap.md` (cyrus-core: 508 files, 2 Nxeon imports). `scripts/platform/affected.mjs` maps changed files to
   targets and deploy units. `apps/cyrus-site` holds the live v7 landing plus `publish.sh` (release dirs, atomic symlink
   swap, legacy dir kept as rollback, health check with auto-rollback, dry run unless `--go`). tsconfig gets the
   `@cyrus/core` alias. No workspaces yet (they would change prod `npm install`).
2. **`scripts/ship`** (affected detection, then one locked node-2 gate job: tsc, seam, OpenAPI contract + dual-mode host
   tests, suite; deploys through the unchanged promote-production.sh, promote-cyrus.sh or the site publish; plan only
   without `--go`). **`scripts/promote-cyrus.sh`**: staging first, side-port smoke, atomic cutover, auto-rollback.
   It refuses real runs while Cyrus is embedded, and refuses production without an armed file. Staging spec is in
   `deploy/cyrus/README.md`.
3. **Cloudflare groundwork.** Generated nginx real_ip config with a validated weekly updater, a throwaway-nginx header
   simulation, per-hostname checklist, static-only cache rules, websocket and origin-cert notes, and a runbook with rollback.
   On the app side, three call sites that read the client-written first X-Forwarded-For entry now use `clientIp`.
4. **Data split.** `tables.mjs` derives 42 tables. `split.sh` does plan, trigger freeze, copy, count+checksum verify,
   dual-read and reverse rollback. `CYRUS_DATABASE_URL` switches `nxeonHost.db` (unset = unchanged).
5. **Observability + backups.** `GET /api/cyrus/health`, error hook (scrubbed, deduplicated Discord), cost export,
   uptime list, status page spec, alert rules + checker, nightly encrypted backup script, systemd units.

## Ran (all on throwaway targets)
- Site publish: temp docroot (swap, rollback, health-fail rollback); dry run on /var/www/cyrus.my.
- promote-cyrus: full local simulation (a smoke failure leaves live untouched; an unhealthy cutover rolls back) plus a
  production dry run.
- Real-IP simulation: 6/6 PASS on the primary.
- Data-split selftest on node-2 throwaway DBs: PASS.
- Backup and alert scripts: dry runs only.
- node-2: tsc clean; 2625 tests (Cyrus suite + 11 Nxeon files near the IP code), 0 Cyrus failures. 18 Nxeon failures are pre-existing on r2. Two r2 first-hop-XFF failures now pass.

## Not run
Any nginx, DNS or Cloudflare change. Any production DB command. The backup and alert timers. The remote Cyrus build
(apps/cyrus does not exist yet). The ship `--go` path. Publishing the site.

## Findings
- **Split blocker:** 338 direct Cyrus-table call sites in 55 files outside lib/cyrus still use Nxeon's `db`. A ratchet
  test (`test/cyrus-db-split.test.ts`) stops new ones; parallel bundles that add some will fail it on merge, and should
  switch to `cyrusDb`.
- **Proxy blocker:** the terminal and console WebSocket servers send no pings. Cloudflare drops idle sockets at ~100 s.
- Fixed: the `cyrus/tokens/return` rate limit was keyed on a client-chosen IP.
- Landing adds 3.6 MB to git.

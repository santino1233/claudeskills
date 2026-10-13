# bm-ops PAUSED (2026-10-08, owner near usage limit)

Branch `feature/bm-ops`, worktree `/tank/dev-worktrees/bm-ops`. Not merged, not deployed.

Done and verified on node-2 (under the build lock):
- `npx tsc --noEmit` clean (before the final small edits: cost-floor revert + one test regex).
- `test/dedicated-release-pure.test.ts` 18/19 (the 1 failure was an over-broad regex, fixed after the run, not re-run).
- `test/dedicated-ops.test.ts` incl. the new virtual-MAC mock test: passing; `test/dedicated-order.test.ts` passing.
- `test/dedicated-brand-voice.test.ts` (react-server conditions) 5/5.
- `test/dedicated-pricing.test.ts` 2 failures were caused by a cost floor I added; the floor is REVERTED.

NOT run (blocked by the environment, not by a known bug):
- `test/dedicated-ops-db.test.ts` (13 DB tests: real funds vs credit, renewals, corrections, IP orders in
  the mock, live cache single-flight + the 8 s slow-supplier measurement, tracking, alerts). On node-2 the
  real `server-only` package throws when lib/auth -> lib/geo-ip loads; with `--conditions=react-server`
  React's server build breaks `createContext`. Same for `test/dedicated-gate.test.ts` (2 tests) and
  `test/admin-console-guards.test.ts` (2 tests on app/admin/page.tsx, files this branch does not touch).
- Admin screenshots (another `*-dev` server was running fleet-wide the whole session).

Resume:
1. `cd /tank/dev-worktrees/bm-ops && /opt/nxeon/scripts/devhost db push`
2. Run the DB test with a no-op `server-only` (like the prod worker stub), e.g. create an untracked
   `.bmops-noop/server-only/index.js` (empty) and run
   `devhost run --lock -- env NODE_PATH=.bmops-noop BM_OPS_DB_TEST=1 NXEON_DEDICATED_OVH_MOCK=1 npx tsx --test test/dedicated-ops-db.test.ts`
   (or temporarily `echo > node_modules/server-only/index.js` inside the node-2 copy only). Fix what fails.
   The test prints `[bm-ops measure] ...` with the before/after panel timings.
3. Re-run `bash .bmops-check.sh` (untracked scratch script) under the lock.
4. Screenshots when no other `*-dev.service` runs: `devhost run -- npx tsx .bmops-seed.ts` (prints TOKEN and
   SERVER), `devhost env set NXEON_DEDICATED_OVH_MOCK=1`, `devhost dev`, then
   `devhost run -- env BM_TOKEN=... BM_SERVER=... node bmops-shoot.scratch.mjs` and
   `devhost pull .bmops-shots /root/agent-notes/bm-release/ops/shots`; `devhost stop`.
5. Untracked scratch files to delete before merge: `.bmops-check.sh`, `.bmops-seed.ts`, `bmops-shoot.scratch.mjs`.

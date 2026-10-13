# AO: Cyrus db move (r43), 2026-10-11
Branch feature/cyrus-r43-dbmove, worktree /tank/dev-worktrees/cyrus-r43, on r2 3cd0c6cb6c (merged, up to date). Not deployed.

## Result
Direct `db.cyrus*` / `db.modBuild` call sites outside lib/cyrus: **338 in 55 files -> 0**. Ratchet baseline
(test/fixtures/cyrus-db-split-baseline.json) is now `{}`, so the "split may run only when empty" condition is met.
Mechanical rewrite: `db.<cyrusTable>` -> `cyrusDb.<cyrusTable>` plus an import of `lib/cyrus/db` (relative or `@/` to match the file);
`db` import removed where it became unused. Nxeon tables (Setting, Server, Job...) untouched and still on `db`.
Commits: app/api, app/dashboard, app/admin+components, lib, worker+scripts, baseline+docs.

## Mixed transactions
4 array-form `db.$transaction([...])` calls (lib/actions-cyrus-community x3, lib/actions-cyrus-mods x1) held only Cyrus ops, so they
now use `cyrusDb.$transaction`. No mixed Nxeon+Cyrus transaction exists among the moved sites (admin-flags' transaction is Setting only).

## Verification (node-2, throwaway DB)
tsc clean. Full suite: 6411 pass / 52 fail vs r2 baseline 51 fail. Differences are not regressions: 2 pre-existing MRR/revenue tests
fail on both; 3 test files (admin-fleet, admin-console-guards, ai-agents-page) failed only in the full run because the fresh node-2
workspace has no `server-only` shim until a shim-importing test runs (order dependent); rerun alone they pass. Ratchet + seam tests pass.

## Not moved / caveats
- Nothing left that matches the ratchet. The ratchet only sees `db|tx|prisma.<cyrus*|modBuild>`; aliased clients or
  `db["cyrus..."]` would not be caught (none found by grep).
- Behaviour identical today (cyrusDb delegates to the same client). One side effect: files that now import cyrusDb pull in the host
  module graph (lib/cyrus/host/nxeon -> auth, geo-ip), so pure unit tests importing lib/cyrus-mods or lib/modbuilder need
  `test/_cyrus-server-only-shim`.
- No r41 conflicts at merge time.

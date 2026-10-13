# dirp1 (2026-10-04) branch feature/directory-phase1 (on top of feature/directory-block-other-hosts), worktree /tank/nxeon-wt-dirp1, commit b872644638
Directory phase 1: Steam ingest production-ready. See docs/DOCUMENTATION.md "Steam ingest and liveness" (go-live runbook inside).
- Pure: lib/directory-ingest/{a2s,schedule}.ts, lib/directory-liveness.ts, lib/directory-steam.ts. DB: gates.ts, sweep.ts, prober.ts. Worker: worker/directory.ts (2 sweeps in worker/index.ts).
- Additive schema: ExternalServer probe cols, DirectoryIngestRun blocked/status/trigger/note, DirectorySource table. Needs prisma db push BEFORE code.
- Edited shared: lib/settings.ts (7 keys), lib/actions-listing.ts, lib/server-directory(-data).ts, marketing template tools/nxm/native/server-directory (regen via port_pages.py), worker/index.ts (+2 lines).
- Tests: DATABASE_URL=postgresql://x:x@localhost:5432/x npx tsx --test test/directory-{a2s,liveness,sweep}.test.ts; DB test needs DIRECTORY_TEST_DATABASE_URL (throwaway PG; mine was /tank/pg-dirp1 port 54399, removed).
- Full suite has 46 PRE-EXISTING failures (identical on the blocklist branch without my changes).
- Hazard learned: `git stash` is shared across worktrees; do not use it in a worktree.
- Never run: Steam API, A2S to real hosts. All fixtures synthetic.

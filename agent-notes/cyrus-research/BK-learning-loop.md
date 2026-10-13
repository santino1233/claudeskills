# BK learning loop (2026-10-12) - branch feature/cyrus-learning-loop (worktree /tank/dev-worktrees/cyrus-learning, from main 8c6313d45b), NOT merged, NOT deployed, CYRUS_LEARNING off

## Built (5 commits)
1. lib/cyrus/learning: pure outcome signals from ModBuild rows + result JSON: rework (next change of the lineage within 30 min of the build ending, also discard-and-retry), retry, regression (lost commands / sub-commands / half the classes vs base AND vs the last good build; jar-derived surfaces supported), guard refusal, interruption, unavailable, Test Flight failure, install failure, tier vs outcome, turns / cost / estimated tokens per lane and call kind, event counts and stage times. Anonymized export record (counts, no names / text / user ids). Golden fixture: the 27 real production rows (test/fixtures/cyrus-learning) incl. the ChunkMirror lineage (1.3.0 good; Spawner Wand build and Haiku bolt-on flagged). Additive usage capture in toResult only with CYRUS_LEARNING.
2. scripts/cyrus/learning-report.ts (read-only SELECT, request text hashed) + levers.ts + report.ts. Ran it on production: BJ-token-efficiency-baseline.md.
3. scripts/cyrus/learning-mine.ts: candidates (5 kinds) to a gitignored dir + review.md; never touches rules / sheets / prompts. release-manifest.ts: pure engine release record, eval gate, rollback pointer, diff; not wired to deploys.
4. Admin tab /admin/cyrus/learning (read-only; off without the flag). Small: 1 tab entry + 1 page + test.
5. Docs: docs/cyrus/15-learning-loop.md, README row, D-60 / D-61, LESSONS L8, history, gaps, testing, engine, features / flag notes, references regenerated, DOCUMENTATION.md section.

## RAN
devhost tests: 4 new files (43 cases) + docs-coverage, onboarding, db-split, host-seam, db-seam, cyrus-admin, cyrus, assets, live-test-fixes, customer-app, lifecycle: all green (291 total); tsc exit 0; scripts run on the primary against production (read-only) and on the fixture end to end.

## Findings (27 builds, $6.51)
24 ok, 18 kept. $1.47 (23%) on 4 builds re-requested within 30 min. Saka 47% of spend, $0.77 per kept success vs Katara $0.17. Haiku 18-turn change build mb3445257a: $0.21, dropped 3 commands and all 5 classes of the last good build. ModBuild has NO token counts (toResult drops service usage), no error text, no install failures.

## NOT RUN / open
No eval of any candidate; no live build service; admin page not opened in a browser; mining never reviewed by the owner. Token savings are estimates. Owner: decide Saka on Sonnet 5.5 (MB_TIER_SAKA, eval first), whether to turn CYRUS_LEARNING on to start capturing token usage, review the candidates in review.md, and the regression-guard branch (fix/cyrus-change-regression-guards) can reuse lib/cyrus/learning/surface.ts.

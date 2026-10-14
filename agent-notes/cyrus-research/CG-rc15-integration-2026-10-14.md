# CG rc15 integration (2026-10-14)

Worktree /tank/dev-worktrees/cyrus-int2, branch release/cyrus-rc15. Commits 6a53cee8, 5f8ce02b, 0b3cb692 on top of the merge loop.

## Resolved
- services/modbuilder/server.js: requires LG + LEDGER + PF; change-build first turn = workspace map (promptRec) then ledger block (both passed to changePrompt); /health features = rc13/speed (effortMap, fastHint) + ledger + preflight.
- prompts.js: PROMPT_VERSION single value mb-2026-10-14.1; changePrompt takes workspaceMap and ledgerBlock (ledger before assets/refs, map after refs).
- projects/[rootId]/page.tsx: lane-gap card and "What we verified" card both kept (laneGaps + verified).
- eval report/stats/journal script: Agg/rates carry real pass AND behaviourRan/behaves/behavesPct; taxonomy + realStages + behaviour table all print; stage reads tolerate missing stage keys.
- realpass.ts: behaviour = fail blocks real pass (blocker "behaviour"); not_run/n/a/absent neither pass nor fail. Test added in cyrus-eval-realism.test.ts.
- gate-worker.ts: toFly/bootSummary with engine-aware gateChecks; oracleInput engines = art.engine.name when the engine jar was provisioned (localPath).
- DOCUMENTATION.md: both bullets kept. Docs references regenerated.
- Dockerfile: COPY has every module; RUN order = classpath, class index, MockBukkit+smoke, 26.x, ..., member index (|| true). No change needed.

## Decisions
- MB_PREFLIGHT default changed enforce -> advise (documented in preflight.js header and docs/cyrus/07-operations.md; test pins updated; pipeline test sets MB_PREFLIGHT=1 explicitly). Unknown values now also mean advise.
- MB_LEDGER stays default on (as its branch reported); workspace map, AST perf, member index, oracle flags default OFF (verified).

## Tests
tsc clean. modbuilder*+cyrus* : 3998 tests, 3997 pass, 1 fail = known cyrus-liveassets-e2e timing test. No conflict markers remain.

## Owner paste (rc14 must be pasted first; image 0.20 -> 0.21; image build needs Maven Central for MockBukkit jars)
1. Portal promote of release/cyrus-rc15 (after rc14).
2. cd /tank/dev-worktrees/cyrus-int2 && TAG=modbuilder:0.21 bash scripts/cyrus/deploy-modbuilder.sh
Later, after advise data looks sane: set MB_PREFLIGHT=1 to enforce.

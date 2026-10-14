# BZ: eval realism (2026-10-14)

Branch `feature/cyrus-eval-realism` (worktree `/tank/dev-worktrees/cyrus-eval-real`, from main f347f27a). Verified via devhost (tsc, eval + launch-check + planner suites). NOT promoted. No paid eval run; dry runs only.

## Why
One messy real prompt (goblin creature mod) found two bugs the eval could not see: (1) plugin.yml lacked `depend: BetterModel`, the plugin could not enable, but the eval's `boot` stage (server starts) passed because plugins_enabled was not required; (2) the portal could not save the result (engine.toolchain over 200 chars), the build stuck. The tidy corpus and the headline numbers overstated quality.

## 1. Metric honesty
- New pure module `lib/cyrus/eval/realpass.ts`: seven SEPARATE stages: compiled, scanned, server booted (Test Flight `boot`), plugin enabled (`plugins_enabled`), commands registered, assets delivered (each planned lane shipped), portal sync ok.
- REAL PASS = built AND plugin enabled in the Test Flight AND all planned lanes shipped AND portal sync not failing. Not flown = never a real pass (counted `unverified`). real pass@1 = real pass with 0 repairs.
- Portal sync is OFFLINE (`lib/cyrus/eval/sync-check.ts`): every returned texture/sound/creature/data pack/design goes through the same `checkReturned*` validators as `assets/sync.ts` (an asset the portal would drop = failure), and the engine record the sync would write goes through `validateEngineRecord`. Computed per succeeded build in `runPlan`, stored on the journal result as `real`. Not covered: a real portal submit (dedicated eval user, out of scope), DB/store failures.
- Surfaces: `eval-run` report.md + console line (REAL pass first, old numbers beside), `baseline.json` (same schema id `cyrus-eval-baseline-1`, optional `realMetrics`, `totals.realPass*`, `results[].realPass`), `eval-journal-stats` (stage table, per-lane real pass, `--compare` shows real pass delta), `eval-gate` (metrics `realPassPct`/`realPassAt1Pct`, `realRegressions` with the same limits; only compared when BOTH sides carry it, so the old accepted baseline never fails for a missing field), launch-check `eval` and `eval-run` rows (REAL pass, plugin enabled % of flown, "booted but did NOT enable", old numbers; WARN below `evalMinRealPassPct` 75 PLACEHOLDER).
- Gap closed: the eval never requested the creature lane (`assets.creature`), which is exactly where the goblin bug lives. New eval lane `creature` (assetKinds `creature`), scored by `assetsStage` on `creatures` shipped.
- Docs: `docs/cyrus/07-operations.md` section "Eval realism".

## 2. Corpus
- `services/modbuilder/eval/real-world-v1.json`: 80 prompts (not in `loadEvalSet`, so the gate subset and python harness stay comparable; loaded by `loadRealWorld`). Strata: creature 24 (30%), GUI/economy/quests 20 (25%), items 16 (20%), datapack/world 8 (10%), admin/utility/minigames 12 (15%). Styles: short vague 23, specific 22, run-on 14, typos 10, chaotic 7, wrong-genre 4. Style from the owner's real ModBuild prompts (prompt text only) and `qa-owner-batch-prompts.json`; 12 prompts reuse the owner batch ideas or the owner's real wording, none duplicates the batch keys (all `rw-` prefixed).
- Every prompt: `expectLanes`, `expectOutcome` (build/limited), `mustHave {kind,value}`. Verifiable today by the Test Flight: enabled, command, datapack_loaded. Tagged but NOT yet verifiable: item_give, mob_summon, gui_open (needs an RCON check; honest in the file's `meta`).
- Presets in `scripts/cyrus/eval-run.ts`: `--preset real-world` (80 builds, mid estimate $22.61, range $13.95-$31.26 on Saka, by stratum: creature $3.10-6.89, GUI $4.29-9.82, items $4.36-9.58, datapack $0.89-1.96, admin $1.31-3.01) and `--preset real-world-smoke` (24 stratified 7/6/5/2/4). Dry run prints the stratum estimate. Always run with `--testflight`.

## 3. Failure taxonomy
`lib/cyrus/eval/taxonomy.ts`: one primary class per build that is not a real pass: timeout/limit, budget cap, false refusal, perf guard, compile, safety scan, plugin missing depend, plugin not enabled (other), design none, texture check, asset check, sync/engine record, commands not registered, not flown, other. Printed ranked by `eval-journal-stats` and in report.md. Infra results stay out of rates but appear in the table.

## Measured on existing journals (no spend, re-scored offline)
- fifth1 (24 builds): old pass@1 100%, final 100%; REAL pass 79.2% (19/24). The 5 misses are asset-lane not delivered: 4 designer prompts downgraded to a plain build (cov-warps, cov-playtime-rewards, cov-tablist, cov-bossbar-titles; rc11 `designStrict` auto = downgrade, by design, but the planned design lane did NOT ship) and 1 texture check (ast-hud-icons). Plugin enabled 24/24 flown. Portal sync not_run (journal predates it).
- fourth1: old pass@1 76.7%, REAL pass 97.8%, real pass@1 74.4% (same builds, honest stages).
- Takeaway: the old headline hides the design-downgrade policy; owner decision whether a deliberate downgrade counts as "delivered" (today it does not: honest, and `full` pass already said the same).

## Tests
`test/cyrus-eval-realism.test.ts` (new, 22 tests: goblin shape not a real pass, not-flown unverified, sync validators, taxonomy classes + ranking, old-journal derivation, gate compatibility, corpus proportions/smoke/creature lane/plan estimate, dry-run CLI, stats CLI). Existing eval, launch-check, planner, mc-coverage, asset-quality suites green (190/190 in the relevant set); one existing assertion in `cyrus-eval-run-lib.test.ts` updated for the new row text. tsc clean.

## Owner / next
- Eval runs now need `--testflight` to produce any real pass; the weekly gate should run with it.
- After the next completed run, re-accept the baseline so the real-regression check has a reference.
- When the build service is idle: `npx tsx scripts/cyrus/eval-run.ts --tag rw1 --preset real-world-smoke --budget 12 --testflight` (24 builds, about $6-9) is the cheapest first measurement of messy prompts; then `real-world` (about $23).
- Next metric work: RCON checks for item_give / mob_summon / gui_open; `--through-portal` submit mode with a dedicated eval user.

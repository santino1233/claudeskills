# DJ: no creature cap - 2026-10-15

Owner: "drop this 4 creature cap stuff, there shouldn't be limits like that."
Branch `feature/cyrus-no-creature-cap` (worktree /tank/dev-worktrees/cyrus-nocap, from release/cyrus-rc18 @ 457fc212), commit 63152860. Not pushed, not merged, not deployed. (The repo post-commit hook only pushes `main`, which this did not touch.)

## What changed

| Limit | Before | After | Why (derived) |
|---|---|---|---|
| New rigs per build | 6 (`MAX_CREATURES_PER_BUILD`) | none (constant removed) | The cut ran in `checkWorkspaceCreatures` AFTER the model had written the files, so it never saved generation cost. The real bound is the build's own budget (`MB_BUILD_BUDGET_USD` 4, `MAX_TURNS`, progress ceilings + continuation). A template rig is 461 bytes on average (max 481) of output, 64 rigs ~30 KB. No multi-pass design needed: a pass split would only make sense if count drove cost, and it does not. |
| Animated models per mod | 12 | 64, documented as an ABUSE GUARD | 64 = the existing `assets.creatureCap` schema bound in services/modbuilder/textures.js (a test pins them together). Server cost measured flat only through 24 (CU-more-mobs); 24-64 NOT measured. Over it: base specs kept first, the rest cut with "Built X of Y new animated monsters: 64 animated models per mod is Nxeon's safety ceiling (it stops runaway requests); a, b run as plain named mobs ...". |
| Code mob fallback | everything after the first 6 | only beyond the 64 guard | roster.ts `splitRoster`/`rosterNote`; prompt "MORE MONSTERS THAN MODELS" now applies only beyond the guard (or explicit vanilla mobs). |
| Test Flight files | 32 x 128 KB | (MAX_CREATURES + 8) = 72 x 4 MiB | `scripts/cyrus/creature-budget.ts`: worst valid RigSpec (explicit, 8 clips x 32 wave tracks cycles 8 over 10 s, 32 bones, 64 cubes, 128 px skin) compiles to a 2,989,945-byte .bbmodel (113 ms); key-heavy worst 163,793 B; 64 template rigs max 63,646 B, compile + skin check 0.28-0.35 s total. Mirrored in tools/testflight/lib.js (exported, test pins). engine.ts now names size vs count misses separately. Raw: /tank/nxeon-build/tmp/dj-no-creature-cap-creature-budget.json (node-2). |
| Sound sets per mod | 8 (hard drop beyond) | no set count (`MAX_SOUND_SETS = MAX_EVENTS_TOTAL`, kept as an alias) | The set count is not the cost; events and seconds are. |
| Sound budget per mod | 24 events / 120 s | 256 events / 480 s | `scripts/cyrus/sound-render-budget.ts` through the production runner on node-2 (load ~2): 8 sets 58.5 s audio -> 4.5 s wall, 24 -> 13.6 s, 64 -> 36.2 s; 77-80 ms per estimated audio second, linear; 64 sets = 4.5 MB Ogg. 480 s ~ 37 s wall vs the host's 120 s timeout (3.2x headroom). Over-budget sets are still dropped AFTER the repair rounds, with a visible notice (that is a real render bound, not a count). |

Silent trims found and removed (each would have hidden creatures or their sounds):
- lib/cyrus/assets/sync.ts: `(ar.sounds ?? []).slice(0, 16)` silently skipped sets 17+; now every set is checked and anything past the read guard gets a notice. Intake `dropped` 32 -> 96, `notices` 20 -> 30; the final notice list keeps 29 + "N more items were left out: names".
- lib/cyrus/textures/pack.ts: `sounds.length > 24` refused the whole pack; now `MAX_EVENTS_TOTAL`.
- services/modbuilder/server.js: `assetDowngrades` `.slice(-32)` -> `MAX_DOWNGRADES = 160`; warnings `.slice(0, 30)` -> 29 + "N more warnings" line; more than 5 failed creatures collapse into one sentence naming all of them.
- services/modbuilder/liveassets.js: live verdict feed 32 -> 72 rows.

Also: ASSET_PROMPT_VERSION `mb-assets-2026-10-15.2`; prompt says "one file for EVERY monster ... there is no per-request limit; 64 ... is a safety ceiling" and the sound budget sentence; generated services/modbuilder/creature-spec.js, sound-spec.js, lib/cyrus/sound/runner.bundle.cjs (render host gets the new runner by hash), docs references regenerated; docs/cyrus/02-engine.md "Creature limits", docs/DOCUMENTATION.md change-history bullet + cost-guard lines.

## Owner decisions (not changed)
- Per-plan gating: Free / Katara / Saka = 0 creatures (asset gate `ASSET_MIN_PLAN.model = all`, `CREATURE_CAP_BY_PLAN`). This is PRICING, not a technical cap. To open creatures to a lower plan, edit `lib/cyrus/creature/caps.ts` and the asset gate.
- The 64 abuse guard itself (raise freely; the flight file count follows `MAX_CREATURES` automatically, the service schema bound in textures.js must be raised with it).

## Honest remaining limits
- Build budget ($4/build): explicit-form rigs are up to 48 KB each (~12k output tokens); a request for dozens of explicit rigs can hit the spending cap and FAIL the build (existing behaviour, not a trim). The prompt asks for the template form.
- Sound render budget 256 events / 480 s (measured, see above); the render host is shared, under heavy load the 3.2x headroom shrinks.
- A valid explicit rig can compile to ~3 MB (baked wave keyframes): 64 of those would be a ~190 MB BetterModel pack. Not a count problem; if it matters, the right guard is a compiled-bytes budget per mod (not added; owner call).
- Not measured: server cost from 24 to 64 models, per-viewer display-entity cost, client FPS.
- UI summaries still show only the first few notices (meta.ts 8, studios 6, truth.ts 3); the full list is in the build's notices.

## Verification (all via scripts/devhost on node-2)
- `tsc --noEmit` (10 GB heap): exit 0.
- Suites: cyrus-more-mobs, cyrus-creature, cyrus-creature-db, modbuilder-creature-pipeline, modbuilder-pipeline, cyrus-boss-model, cyrus-testflight, cyrus-testflight-engine, cyrus-docs-coverage, cyrus-sounds, cyrus-sound-studio, cyrus-textures, cyrus-assets, cyrus-assets-db, modbuilder-asset-quality, cyrus-planner: 445/445 pass.
- `build-creature-artifacts --check`, `build-sound-artifacts --check`, `docs-build --check`: current.
- No live build, no real Test Flight with 64 models was run.

## Image bump (required)
Live modbuilder image 0.19 still enforces the old caps (4 per mod in that image). Changed service files: creatures.js, creature-spec.js, prompts.js, server.js, sound-spec.js, liveassets.js, textures.js (comment only), tools/testflight/lib.js (pushed per flight by hash). Owner, after merging this branch into the rc:
`TAG=modbuilder:0.20 bash scripts/cyrus/deploy-modbuilder.sh` (on the primary, from the merged tree; add `REQUIRE_EVAL_GATE=yes` if gating). Deploy order is free: the portal only sends `assets.creatureCap` below the service limit, and an old service just keeps cutting at its own cap with its own notice. Portal side ships with the normal rc promote (sync.ts, pack.ts, roster/planner, testflight). The sound render host picks up the new runner bundle automatically.

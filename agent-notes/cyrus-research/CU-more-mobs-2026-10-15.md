# CU: more mobs (creature cap, version autofix, code mobs) - 2026-10-15

Branch `feature/cyrus-more-mobs` (worktree /tank/dev-worktrees/cyrus-mobs, from release/cyrus-rc16). Not deployed, no live builds.

## 1. Version bug (mb10bc34bfa32b251af434)
- The build's spec files were deleted by the drop logic (only names/reasons survive), so the failure is reconstructed: `version` written as "1.0"/"1"/1.0/"v1" fails `z.literal(1)`. It also cost the build 2 asset repair rounds (41 problems, ~$1.04, 593 s) before dropping 3 rigs; 4 more were cut as "more than 4 creatures".
- Fix: `normalizeRigSpecVersion` in lib/cyrus/creature/spec.ts (missing/null, 1, 1.0, "1", "1.0", "1.0.0", "v1"/"V1", blanks -> integer 1; 2/"2"/"one" still rejected). Applied inside `checkRigSpec` (so the generated service validator and every portal caller agree), by the service workspace check (rewrites the file in place, records an autofix `creature-version`, no model round: services/modbuilder/creatures.js + server.js assetRound) and by the portal `checkReturnedCreature` (stores canonical version 1).
- Tests: test/cyrus-more-mobs.test.ts (reproduces the 3 dropped rigs + 4 cut rigs).

## 2. Measurements (node-2, Paper 1.21.11, BetterModel 2.2.0, real flights, shared load avg ~20+; server side only, no client)
Template rigs (3 archetypes x features x height/scale/palette variants), 20 entities of each model spawned via the TfCreature fixture, models delivered as flight `files` (production engine.ts path). Raw: /tank/nxeon-build/tmp/cyrus-more-mobs-cost-results.json, scripts: test/cyrus-creature-cost-real.ts, scripts/cyrus/creature-cost.ts.

| N models | .bbmodel bytes (sum) | skin PNG bytes | BetterModel build.zip | boot | peak RSS | trackers | mspt at spawn burst / TPS | steady mspt | flight |
|---|---|---|---|---|---|---|---|---|---|
| 0 | 0 | 0 | 183 KB (BM defaults) | 19.7 s | 975 MB | 0 | 0.44 / 20.0 | 0.4 | pass |
| 4 | 179 KB | 1.7 KB | 35 KB | 19.5 s | 968 MB | 80 | 1.35 / 19.5 | 0.3 | pass |
| 8 | 388 KB | 3.7 KB | 74 KB | 21.5 s | 969 MB | 160 | 2.40 / 19.3 | 0.4 | pass |
| 12 | 580 KB | 5.6 KB | 108 KB | 22.1 s | 976 MB | 240 | 3.92 / 19.5 | 0.4 | pass |
| 16 | 772 KB | 7.4 KB | 142 KB | 19.7 s | 988 MB | 320 | 5.12 / 19.5 | 0.5 | pass |
| 24 | 1174 KB | 11.1 KB | 215 KB | 19.3 s | 992 MB | 480 | 7.68 / 19.5 | 0.6 | pass |

- Per model: .bbmodel 36-64 KB (floating_ghost is the largest, max 63.6 KB: 400 bytes under the old 64 KB flight file limit), skin PNG 0.3-0.6 KB (64 or 128 px), RigSpec 0.45 KB (about 150 output tokens), pack +9 KB.
- Boot and RSS are flat (noise from the shared host); BetterModel load time did not separate from boot noise up to 24 models. Spawn burst cost ~0.016 ms per entity.
- Caveat (honest): in flights the zombie base mobs burned in daylight within ~30 s, so steady-state numbers are trackers on mostly dead bases; the burst numbers (20 live of each) are the meaningful TPS figure. Per-viewer display-entity cost (each bone is an item_display per viewer) and client FPS are NOT measured here (no client).
- Limits found: flight runner files 16 x 64 KB (24 models would not fit) -> raised to 32 x 128 KB (lib/cyrus/testflight/spec.ts + services/modbuilder/tools/testflight/lib.js; the runner is pushed from the repo by hash on each flight). Sound sets are capped at 8 per mod (sound spec), so beyond 8 creatures share sets (prompt now says so).

## 3. Chosen caps and why
- Per mod: 12 (was 4). Server cost is flat through 24, so the data allows more; 12 keeps the flight file budget (12 models + config of 32), the 8 sound sets (families share), the compile/skin-quality time in the portal and the model's output (6 rigs x 3 KB) comfortable, and leaves headroom for explicit-form rigs (larger .bbmodel).
- Per build: 6 new rigs (one generation stays inside time/cost; asked for 10 -> "Built 6 of 10 new animated monsters in this build; X, Y run as plain named mobs ... Ask for the rest in a follow-up"). Base specs always count and are kept first; over-cap files are dropped deterministically with no repair round (they used to force a repair + a hard problem).
- Per plan (lib/cyrus/creature/caps.ts, `creatureCapForPlan`): Yakko ("all") 12; Katara/Saka/Free 0 because the asset gate (ASSET_MIN_PLAN.model = all) already denies creature creation. Proposal if creatures open to lower plans: Saka 4, Katara 2 (edit the table). Portal sends `assets.creatureCap` only when it is below the service cap (old services reject unknown keys, so no deploy-order hazard today).
- Constants updated everywhere: spec.ts + generated creature-spec.js (+ JSON schema), creatures.js, prompts.js, server.js, textures.js (assets.creatureCap), portal.ts, request.ts, spec-entry.ts, testflight spec/runner, docs.
- Also fixed: the prompt told the model to REMOVE the base mob when no tracker (a dropped rig made the mob vanish); now it stays as a visible named code mob.

## 4. Code mob pattern
- Prompt (CREATURE section): first N get models, every other monster is a code mob in one data-driven registry class from config.yml (mobs map: name, base EntityType, health, damage, speed, knockback-resistance, scale, gear, abilities, drops; settings floor-health/floor-damage/max-multiplier/max-tracked); spawn gated by NxPerf.spawnAllowed, one NxPerf.timer over a bounded UUID set, event handlers for on-hit effects/lifesteal/slam/summon/drops. ASSET_PROMPT_VERSION -> mb-assets-2026-10-15.1.
- Planner: lib/cyrus/creature/roster.ts (`requestedMonsterCount`, `splitRoster`, `rosterNote`) adds a "code" note to the plan card ("6 of the 10 monsters get their own 3D model...; the other 4 are built as code mobs ...") via planner/decide.ts.
- Golden `mc-code-mob-roster` (12 mobs on 12 vanilla bases, floor scaling, config-driven). Harness compile 1.21.1/1.21.4/1.21.8/1.21.11: pass/pass, 0 javac warnings, 0 scan findings. Real Test Flights (test/cyrus-code-mob-real.ts, results /tank/nxeon-build/tmp/cyrus-more-mobs-code-mob-results.json): passed on all four Paper versions: spawn 12 of 12, tags (execute if entity), max_health attribute per mob via RCON, gear, custom name, death handler, floor 40 cap (88.0). Findings: a SILVERFISH base vanished on 1.21.1/1.21.11 (replaced by ENDERMITE); 1.21.5+ entity data path is `equipment.head` (not ArmorItems).
- Not done: a recipes/*.json entry (recipe schema needs owner review), regeneration of services/modbuilder/golden/results.json + docs/cyrus/minecraft-coverage.md (needs a full `golden-flight.ts results` run).

## 5. Verification
- Unit: test/cyrus-more-mobs.test.ts (40), cyrus-creature, cyrus-creature-db, modbuilder-creature-pipeline, modbuilder-pipeline, cyrus-boss-model, modbuilder-asset-quality: 182/182 pass via devhost (includes generated-file staleness).
- tsc: see the end of this file. Docs references regenerated (docs-build).

## 6. Image bump / owner commands
- Image bump needed: YES (modbuilder service: creatures.js, creature-spec.js, prompts.js, server.js, textures.js; also tools/testflight/lib.js is pushed per flight). Bump `image` in services/modbuilder/server.js health (currently "0.5") with the usual Dockerfile/release steps; portal and service can deploy in either order (creatureCap is only sent below the cap).
- Owner commands (nothing run): merge feature/cyrus-more-mobs into the next rc; rebuild/restart nxeon-modbuilder with the new image; then ask the dungeon build again ("8 new monsters") to see 6 models + 2 code mobs and the honest notice; optional `scripts/devhost run --lock -- npx tsx test/cyrus-creature-cost-real.ts` to re-measure; `npx tsx scripts/cyrus/golden-flight.ts results` to refresh the committed pass matrix.

# CH: planner lane recall and plan-card honesty (2026-10-15)

Branch `feature/cyrus-planner-recall` (worktree `/tank/dev-worktrees/cyrus-planner`, from main 98d82fe0 = rc15 integration). NOT merged, NOT promoted. No model call, no paid eval. Verified via devhost: tsc 0; planner/coach/eval/coverage/modbuilder/docs suites 301 tests pass (the one failure was the stale docs reference, regenerated, 12/12 now); new `test/cyrus-planner-recall.test.ts` (corpus recall floors, recorded owner plans, plain-by-evidence, conflict note, limits).

## 0. Headline
- The "30% planner recall" in BY/fourth1 is the weak EVAL selector (`lib/cyrus/eval/lanes.ts rulesSelector`), not the rules the planner really uses (`lib/cyrus/planner/rules.ts ruleNeeds`) and not the production path (Haiku planner + literal floor). Real rule recall on the same material was 61% raw before this round; the model path had 100% recall but only 58% precision on the owner batch (it plans lanes that ship nothing, and next to a creature a designer lane makes rc13 drop the creature).
- Fixes: (1) word-rule cues for the miss classes; (2) a deterministic POLICY layer after the model (plain-by-evidence, corroboration, limits); (3) creature-vs-designer resolved up front in `decidePlan`; (4) plan card lists what will NOT be built, with reasons.
- Numbers are in-sample for the real-world corpus and owner batch (rules were tuned on them). Held-out check: the 178-prompt eval set and golden did not regress and gained slightly.

## 1. Measurement (offline; `npx tsx scripts/cyrus/planner-measure.ts [--selector rules|eval-rules|recorded|recorded-merged] [--raw] [--fails]`)
Scoring: recall = expected lanes hit / expected (config not scored); precision = hits / (hits + extras not in need and not "optional"). "Raw" = the corpus labels as they are. "Adjusted" excludes the lanes listed in `test/fixtures/cyrus-planner/label-disputes.json` (each has a reason: GAMEPLAY_EXCLUDE auction/trade, fifth1 plain downgrades, creature skin carried by the creature lane, vanilla world gen, ...). Evalset labels are sparse (assetKinds/designer only) so its precision understates; treat its trend, not its level.

| set (prompts) | selector | recall before -> after | precision before -> after |
|---|---|---|---|
| real-world 80, raw | planner rules | 61.5% -> 81.3% | 74.7% -> 85.1% |
| real-world 80, adjusted | planner rules | 73.6% -> 97.2% | 81.5% -> 94.6% |
| evalset 334 (178 matrix + sets) | planner rules | 76.0% -> 78.1% | 44.6% -> 46.2% (plain over-requested 37 -> 33 of 157; adjusted 46.5%) |
| golden 40 | planner rules | 100% -> 100% | 86.0% -> 88.1% |
| owner batch 20 (analyst labels) | planner rules | 85.7% -> 100% | 85.7% -> 87.5% |
| owner batch 20 | RECORDED model plan (portal path, image 0.19) | 100% | 58.3% |
| owner batch 20 | recorded model plan + policy (portal-only) | 100% -> 95.2% | 58.3% -> 95.2% |
| any | eval-rules selector (what the 30% was) | real-world 29.7%, evalset 24%, golden 59.5%, owner 57.1% | n/a |

Per lane (real-world, adjusted, rules): texture 65 -> 95, creature 53 -> 94, designHud 50 -> 100, datapack 75 -> 100, designItem 75 -> 100, sound 90 -> 100; designMenu/Quest/Boss/worldgen stay 100. Remaining misses: rw-night-wolves (a creature described only as "wolves ... glowing red eyes"). Remaining over-planning: golem rock texture (deliberate: planner prompt example), library next to ambient sound (2), "zombie horde" designBoss.

Top miss classes found (before): creature named by a fantasy noun only (goblin, wendigo, mimic, ghost, slenderman, dragn; 9/18), a new item with no look words ("make me a sword", handgun, backpacks, plushies, armor set, grapple hook, lucky pickaxe; 12 texture misses), HUD for sidebar/scoreboard, loot in dungeon chests, guns without "sound". Top false-positive classes: model datapack for code mechanics, designHud/designMenu for minigames and warps, creature for "kill a mob, 2 more spawn" and "iron golems guard", "staff" (admins) read as the staff weapon, vanilla gear in a kit read as a new item.

## 2. Changes
Deterministic (zero tokens):
- `lib/cyrus/planner/rules.ts`: FANTASY_CREATURE / CREATURE_PHRASE (vanilla Ender Dragon, iron/snow golems, item names like "Dragon Scale" and encounter prompts excluded), NEW_ITEM + CREATE_VERB new-item texture cue (vanilla gear, recipe-only, technique tools, "custom enchantments", staff-as-people excluded), gun words -> sound, loot-in-chests -> datapack, sidebar/scoreboard -> designHud (not in minigame context), grapple/hook ability item, model3d not next to a creature, shine words only next to an item, "spinning gui" is not a prop.
- `lib/cyrus/planner/policy.ts` (new): PLAIN_BY_EVIDENCE (warps/homes menu, login streaks/playtime rewards, tab list header/footer, boss-bar countdown/title, player-run shops, bounty: cov-warps, cov-playtime-rewards, cov-tablist, cov-bossbar-titles were downgraded to plain in fifth1; real pass 79.2% was 4 of those); CORROBORATE (designItem/Menu/Quest/Boss/Hud, motion, datapack, worldgen, library, itemStates, model3d must be supported by a word rule or a literal ask; sound needs a cue or confidence >= 0.85; confidence alone did not separate true from false: bad datapacks were 0.80-0.95); LIMITS (vanilla ore/biome edits, voice chat, shaders/minimap, brand-new block types).
- `lib/cyrus/planner/rules.ts mergeNeeds` applies the policy to the model answer (portal-only, no image change).
- `lib/cyrus/planner/decide.ts`: `ModPlan.notes` (kind code | dropped | cannot) and `PlannedLane.note`. Creature next to a designer lane (the service switches creature off there since rc13): boss/menu/quest keeps the designer and the creature model is left out WITH a note; item/HUD/motion designer gives way so the creature is built (fox companion, goblins, hoverboard shape). Notes are informational, never a gate (`mustConfirm` unchanged).
- `components/cyrus/app/NewModFlow.tsx`: plan screen shows "Not built as the request reads" (Cannot be built / Left out / Built as plugin code) under "Cyrus will create".
- Datapack lane when the request is best met in code: model-only datapack is dropped unless recipes/loot/advancement/tag/enchantment-definition/biome words (or literal) appear; custom enchantments keep the adapter's datapack rule (matrix says datapack) and are marked disputed in the labels.
Prompt (`services/modbuilder/planner.js PLANNER_PROMPT`): +329 chars (about +80 input tokens, ~$0.00008 per plan on Haiku): an extended "plain code" list (warps, login rewards, tab lists, boss-bar countdowns, bounties, effect potions/enchantments) and one sentence limiting designHud/datapack/designItem to what the request names. It needs service image TAG bump (services/modbuilder/planner.js is in the Dockerfile COPY already); its effect cannot be measured offline. Everything above runs portal-side and works on image 0.19-0.21 unchanged.

## 3. Owner paste: portal only vs image bump
- Portal-only (normal promote of this branch, recorded-merged column above): plan lane precision on the owner batch 58% -> 95% at 95% recall; no planned datapack for armor set bonus / daily quests / enchantments / crops; fox companion and goblins keep their creature (no designItem next to it); the plan card shows creature-left-out for boss prompts instead of a silent drop; "cannot be built" for ore generation. Nothing in the service changes; a service on image 0.19-0.21 sees only a smaller, more honest `assets.plan`.
- Image bump (planner.js prompt only): expected to reduce model over-planning at the source and the policy's demotions; not measured (needs paid planner calls, ~$0.001 each: 20 owner + 80 real-world prompts = ~$0.10 with `planner-eval.ts --model`; not run). Not required for the gains above.

## 4. Contract problems status
- creature next to designBoss: decided up front, card says so (test: "boss fight + creature"). Note the product choice: designer wins for boss/menu/quest (as rc13), creature wins for item/HUD/motion. The better long-term fix is a service lane that attaches a BetterModel creature to a designer boss; out of scope.
- datapack when best met in code: corroboration gate + plain-by-evidence; food-potions case (planned datapack shipped nothing) now stays plain unless recipes are asked.
- designer vs plain: warps menu, login streak/playtime rewards, tab list, boss-bar countdown are plain by evidence; sidebar/scoreboard stays a HUD design (cov-sidebar shipped as design) except in minigame context.
- Plan honesty beyond this: a lane that is planned and still ships nothing is reported after the build by rc13 `laneGaps` (unchanged). Things the plan cannot know before the build (the model writes the plugin without a spec) remain possible; the up-front list covers the deterministic cases only.

## 5. Caveats and follow-ups
- Rules were tuned on the real-world corpus and the owner batch; the dispute file was written after reading results (each entry has a reason and the raw numbers are given beside). A fresh set of 30-40 messy prompts, labelled blind, is the honest next test; a paid `real-world-smoke --testflight` run (24 builds, ~$6-9, on the first idle build service) would show whether planned lanes now ship (real pass), not just whether they are chosen.
- Texture is now planned for a new named item even without look words ("make me a sword"): one more asset lane means ~$0.25 more per such build (texture $0.41/pass vs plain $0.16). Owner may prefer to ask. One flag-free switch: remove NEW_ITEM from the `texture` formula in rules.ts.
- library stays over-selected next to ambient/music asks (harmless: it only prefers stock sounds).
- Evalset labels for "plain" gameplay prompts (shop, quests, bounties) predate the designer lane; rules plan designMenu for a /shop GUI there (cov-admin-shop shipped as design), counted as extras in the evalset precision.
- Files: lib/cyrus/planner/{rules,policy,decide,lanes,run,measure}.ts, services/modbuilder/planner.js, components/cyrus/app/NewModFlow.tsx, scripts/cyrus/{planner-measure,planner-why}.ts, test/cyrus-planner-recall.test.ts, test/fixtures/cyrus-planner/{owner-batch-labels,label-disputes}.json, docs/cyrus/02-engine.md + regenerated reference pages.

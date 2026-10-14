# BT: Cyrus rc11 first-try round (2026-10-14)

Branch `release/cyrus-rc11` (worktree /tank/dev-worktrees/cyrus-rc11, from release/cyrus-rc10 1ba8aefe), NOT promoted, NOT deployed.
Image impact: services/modbuilder only (autofix.js, textures.js, sounds.js, server.js) -> modbuilder:0.18 (0.17 = rc10, not yet deployed).
Evidence: eval fourth1 on image 0.16, read-only (journal + GET /builds/<id> records, no build started). 70 of 90 builds were done when I read it.

## 1. What the 17 first-try misses were (fourth1, 70 done: pass@1 75.7%; plain 19/20, sound 12/14, texture 11/21, designer 11/15)
| class | n | builds | rc10 | rc11 |
|---|---|---|---|---|
| perf-spawn-in-loop | 6 (+1 in handgun) | ruby-sword, banshee-full, handgun-textured, shotgun-pump, potion-bottles, food-pack | fixed | |
| No design found | 4 | cov-warps, cov-playtime-rewards, cov-tablist, cov-bossbar-titles | | policy fix |
| Texture check: every pixel solid | 2 | tex-shop-counter-gui, ast-gui-textured | | autofix |
| Asset check: sound layers | 1 | ast-handgun-textured | | autofix |
| compile: Collection->List, weaker access | 2 | banshee-full, s04-broadcast | fixed | |
| compile: List<TextComponent> -> List<Component> | 1 | tex-dragon-sword-32 | | autofix |
| setup: plugin.yml not valid YAML | 1 | snd-wand-spells | | autofix |
| compile: no class ConsumableEffect / no Material.SMITHING_TEMPLATE | 2 | honey-bread, armor-set | | not fixed (single hallucinated names; API lookup already points at the right ones) |

## 2. "No design found" (designer lane 11/15): why, and the fix
Facts from the four build records: the planner's lane flags were right (design + gameplay or hud, no plan). In ALL four the model's first tool calls were Write plugin.yml, Write config.yml, then Java: a complete ordinary plugin and no assets/designs file. The 11 designer builds that passed first try wrote the design file FIRST ("Wrote admin_shop.json", "Wrote storm_blade.json"). So the prompt text is not missing (assetsBlock says "write the design file(s) FIRST ... this build fails without") but it also carries an escape hatch ("If NOTHING in this request fits a design, write an ordinary plugin"), and for these four requests the model took it. It was arguably right to: warps need a dynamic list, a countdown needs a command with arguments, a tab list header is not expressible by the HUD lane.
The cost of ignoring it was the rc8 strict policy (MB_DESIGN_STRICT auto = menu/quest/HUD/boss keep a design repair). I read what that repair produced, and it is harmful, not just slow:
- cov-bossbar-titles: a `show: always` boss bar "Countdown Event" for every player, beside the real /countdown bar.
- cov-tablist: a health/food/level SIDEBAR nobody asked for in a tab-list plugin.
- cov-warps: a chest menu with two fixed "Spawn"/"Shop" buttons that only print "type /warp spawn", beside the real dynamic warp menu.
- cov-playtime-rewards: a "survive 10 seconds" daily quest beside the real reward manager.
Fix (server.js designStrict): automatic mode now downgrades to the plain build when a complete ordinary plugin was written (the rc5 behaviour, labelled in events/assetNotes/journal, rec.designDowngraded). MB_DESIGN_STRICT=1 restores rc8 exactly. A build with no complete plugin and no design still gets the single-file design repair. Honest trade: those four ship as plain plugins (no Designer/Config-studio editability), which is what first1/second1 did for 7 of 18 and what the quality evidence says is better than a decorative design. OWNER DECISION: this reverses a polish-round-2 decision; if you want editability back, set MB_DESIGN_STRICT=1 on the service.
Prompt wording was NOT changed (would need model calls to measure, and token cost on every design build). Possible later experiment: when the lane is menu/quest and the request has a fixed list, drop the escape hatch.
Test: test/modbuilder-pipeline.test.ts "HUD lane planned, ordinary plugin and no design" now expects the downgrade (0 repairs, no repair call).

## 3. Deterministic autofixes (all in services/modbuilder, no model round)
1. Texture "every pixel is solid, so the item shows as a square tile" (2 of 3 texture-lane asset repairs; both were /shop menu background panels, and the model's repair was the same edit both times: draw the panel inset by 2). `textures.insetSolidSpec` scales every op about the canvas centre (inset size/8 per side; mirror stays symmetric), applied in checkWorkspaceTextures only when that is the single failing check and the re-rendered texture has verdict != fail; otherwise the model repair runs as before. Palette untouched. Note it as a normalisation (events carry it). Open question for the owner: a background panel that should tile edge to edge is now never full-tile; allowing "solid" for names like *_panel would need the same change in lib/cyrus/textures/quality.ts (both copies must agree), so I did not do it.
2. Sound variant with more than 4 layers ("events[1].variants[0].layers must be a list of 1-4"): `normaliseSoundSpec` keeps 4 layers spread evenly over the sound (first and last kept) and notes it. Inference: the recorded final reload has exactly 4 click layers, and the checker message with a valid list type means the count was the problem; the pre-repair file is not retained by the service.
3. `List<TextComponent> cannot be converted to List<Component>` from `...stream().map(...).toList()`: `autofix.fixListSubtype` rewrites that line's `.toList()` to `.collect(java.util.stream.Collectors.<Component>toList())` (one `.toList()` on the line only, src/main/java only). Java semantics checked by reasoning (Collector<? super T,...>); no JDK on this host, the build service's compile is the real check at eval time.
4. plugin.yml `description: ...spells: fireball...` (unquoted ": ", "setup problems"): `autofix.fixYamlScalars` double-quotes such values (indented command descriptions too), skips block scalars and quoted/flow values, and writes nothing unless the result parses. Run against the real yaml@2.8.1 by hand: the recorded failure now parses to the identical strings.
Tests: test/modbuilder-rc11-first-try.test.ts, 15 tests, fixtures in test/fixtures/cyrus-rc11 (recorded final specs of the repaired builds; the failing shape is rebuilt from the recorded checker message: the pre-repair files are not kept).

## 4. Effect estimate (counterfactual replay of the 70 builds, not a measurement)
- rc10 alone: 6 perf/compile builds fixed -> 59/70 = 84.3%.
- rc10 + rc11: all 17 repaired builds except honey-bread and armor-set (hallucinated API names) would have passed first try -> 68/70 = 97.1% (+9 from rc11: 4 design, 2 panel, wand yaml, dragon sword, revolver layers; the layers one is the least certain).
- By lane: texture 11/21 -> 19/21 (90%), designer 11/15 -> 15/15 (the 4 are plain downgrades, labelled), sound 12/14 -> 14/14, plain 19/20 -> 20/20.
- Money: the 17 repaired builds cost $8.05 of $21.20 (38%). rc11 removes about 9 of them (about $0.2-0.4 each of repair delta plus 15-60 s).
- Caveats: the model is not deterministic, round-1 outputs will differ; the downgrade policy raises pass@1 by redefining a repair class, not by making the model write designs.

## 5. Owner commands (nothing applied by me)
Wait for fourth1 to finish (service must be idle), then accept it per docs/cyrus/07-operations.md. Then deploy rc10+rc11 together as 0.18 (0.17 is not deployed yet; rc11 contains rc10):
`cd /tank/dev-worktrees/cyrus-rc11 && TAG=modbuilder:0.18 bash scripts/cyrus/deploy-modbuilder.sh`
Portal: only the admin flag text changed (lib/cyrus/admin/flags.ts), promote with rc10 if wanted:
`cd /opt/nxeon && git merge --ff-only release/cyrus-rc11 && bash scripts/promote-production.sh --skip-staging-check`
Re-measure with a short eval after 0.18: `--lanes designer:11,texture:10 --tag fifth1 --budget 12`; expect designer pass@1 near 100% (downgrades labelled), texture 85-90%.
Rollback of the policy only: `MB_DESIGN_STRICT=1` on the service env, no image change.

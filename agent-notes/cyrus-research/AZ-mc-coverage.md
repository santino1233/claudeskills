# AZ: Minecraft coverage bundle (2026-10-11)

Branch `feature/cyrus-mc-coverage` (worktree `/tank/dev-worktrees/cyrus-mc1`, from main 22cfdfd90e). Five commits. Not merged, not deployed, no flag flipped, no migration, no paid model call.

## What landed
1. **Coverage matrix**: 85 archetypes (BA reference-corpus demand weights, BB vanilla techniques) with lanes, technique, per-version support, caveats, Bedrock, Cyrus path, planner limits. `lib/cyrus/adapters/minecraft-coverage.json` is a `cyrus.capabilities.v1` catalogue (per-version `{lane, availability, reason, substitute, minVersion}`), rendered to `docs/cyrus/minecraft-coverage.md`. Playbook 1.1.0: a complete catalogue is required before a game leaves `planned` (LESSONS L7).
2. **Golden corpus**: 65 reference plugins + 13 anti-patterns (`services/modbuilder/golden`), run through the service's own checks and one Test Flight per version.
3. **Lane gaps, built and flown**: BetterModel 2.2.0 creatures on 1.21.x; data pack enchantment `postAttack`/`attributes`, `damage_type`, `jukebox_song`, `predicate`, `item_modifier`; note-block custom blocks; worn custom armor.
4. **Eval**: 103 coverage prompts (+6 safe-alternative, +8 bugfix), lane-selection accuracy, per-category scoring, `coverage-first` preset.

## Pass matrix (final, after fixes)
| | compile | scan | boot (Test Flight) |
|---|---|---|---|
| 1.21.1 | 64/64 | 64 (1 warn) | 64/64 |
| 1.21.4 | 65/65 | 65 (1 warn) | 65/65 |
| 1.21.8 | 65/65 | 65 (1 warn) | 65/65 |
| 1.21.11 | 65/65 | 65 (1 warn) | 65/65 |
The warning is the documented runtime permission grant (ranks). Mounts are 1.21.4+ only. Data pack lane: passed on all four. BetterModel 2.2.0: passed on all four. Anti-patterns: 13/13 caught by the expected layer.

## Findings fixed in the knowledge
1.21.11 deprecates every `GameRule.*` for removal (new `GameRules`, renames: sheet + warning rule + deterministic autofix); merchant API deprecated on 1.21.4+; food eat time moved to the consumable component (1.21.1 differs); `setFireResistant`, metadata API and `isOnGround` deprecated; `customName` missing on 1.21.1; name-only ban profiles throw; 1.21.11 has no spawn chunks (entities unload); `#enchantable/sword` removed in 1.21.11; Test Flight misread wrapped `plugins` output (runner fixed). Sheets gained an events catalog, blocks/worlds, metas, OfflinePlayer, Gson/PDC/ServicesManager, displays; 13 failure rules (precheck `unless`); rule 5 now names the safe alternative.

## Impossible without a client mod (honest labels kept)
New block/entity/fluid types and non-cube collision, keybinds beyond vanilla inputs, render pipelines beyond core shaders, new particle types, minimaps/free-form HUD, voice chat. Also out: proxy networks, Votifier/webhooks/update checkers (no networking), packet NPCs (no NMS). Each archetype names the closest vanilla build.

## Ran vs not run
Ran: every compile/scan on node-2 (JDK 21, real API classpaths), 4 golden flights, 4 data pack flights, 4 BetterModel flights, javap probes, vanilla data generator for new id kinds, tsc, Cyrus suite. Not run: any real client; any AI build of the new lanes; the eval (recommended first run: 40 builds on 1.21.11 at Saka, $3.90-$8.90, plus 2 on 1.21.1 $0.16-$0.36); core shaders, glyph-background menus, the client-mod lane.

## Next
Wire `assets/blocks` and `assets/armor` spec kinds into the service and delivery (with the Paper note-block flag); rebuild the build image for the BetterModel 2.x API jars; merge with `fix/cyrus-live-test-1` (its catalogue lanes match this JSON; creature lane now follows the registry on 1.21.x; rules lane recall 35% is the planner's job).

# Valheim world modifiers (branch feature/valheim-world-modifiers, worktree /tank/dev-worktrees/valheim-modifiers)

Verified names/values (primary source: Valheim "A guide to dedicated servers",
https://www.valheim.com/support/a-guide-to-dedicated-servers/ , fetched 2026-10-14; not checked on the running image):
- -modifier combat: veryeasy, easy, hard, veryhard
- -modifier resources: muchless, less, more, muchmore, most
- -setkey: nobuildcost, playerevents, passivemobs, nomap

Changes: lib/valheim-modifiers.ts (new, pure composer + parser), lib/game-config.ts (6 fields, group World),
worker/game-config.ts applyValheim, lib/game-files-roots.ts note, docs/DOCUMENTATION.md (Valheim KB + real-apply section;
no heading is literally numbered 15), test/valheim-gaps.test.ts.
Behaviour: normal/false = no flag; non-default flags appended in order combat, resources, nobuildcost, playerevents,
passivemobs, nomap; absent key leaves SERVER_ARGS unchanged; bool values are coerced to strict booleans in validateConfig.
No recreate from the schema addition alone (existing servers change only on a Settings save; checkout auto-queue only for non-default values).
Panel does not read SERVER_ARGS back from the container; parseValheimModifierArgs gives the round-trip.
Tests: 37/37 pass (valheim-gaps, game-files-roots, game-presets, mod-quality); tsc clean.
Not done: lib/tools/config-generators.ts + generator page still label combat/resources "community" sourced.
Owner promote line (portal only): not determined here; use the standard portal promote procedure for this branch. Not deployed.

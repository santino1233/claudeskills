# CD: Behaviour oracle (oracle-1), 2026-10-14

Branch `feature/cyrus-behaviour-oracle` (worktree `/tank/dev-worktrees/cyrus-oracle`, from main f347f27a), commit 52fc2f60.
Verified: tsc 0 (devhost); tests 52/52 new (`test/cyrus-oracle.test.ts`) + 130 existing Test Flight / playtest / eval /
docs-coverage tests + 272 neighbouring Cyrus suites, all green on node-2. NOT merged, NOT deployed. Switch
`CYRUS_TESTFLIGHT_ORACLE` default OFF. Docs: `docs/cyrus/16-behaviour-oracle.md` (JSON contract), DOCUMENTATION.md,
02-engine, 09-testing, generated reference. Real flight records: `oracle-flights-2026-10-14.json` (this folder).

## What it is (BX card 1)
Before: an eval or gate "pass" meant compiles + scans + boots + enables + commands register (playtest 0/90 run).
Now the same disposable Paper server is asked whether the mod DOES what it says:

1. **Expectations, derived deterministically, no model call** (`lib/cyrus/testflight/oracle/derive.ts`) from plugin.yml,
   config.yml, designer specs (items, abilities, passives, recipes, menus + buttons, quests, bosses, HUDs), data pack
   specs (recipes, loot tables, advancements) and rig specs. 17 kinds: mod_enables, command_responds, reload_command,
   item_given, ability_effect, passive_effect, menu_opens, menu_click, quest_progress, boss_spawns, creature_spawns,
   hud_visible, config_reload, recipe_registered, loot_gives, advancement_reward, model_extra (model-authored extras,
   OFF: `CYRUS_TESTFLIGHT_ORACLE_EXTRAS=1` and a caller that passes them; validated like any playtest step).
   What cannot be tried honestly is `not_testable` with the reason, never dropped.
2. **Executor inside the existing Test Flight** (`compile.ts` + `run.ts`): console probes become optional RCON checks
   (`nxo-*`, `required:false`), player probes become Mineflayer scenarios `T-901..` in the same flight. Console replies
   are judged by the evaluator, so one miss never stops the next check. New bot steps (bot.js + playtest-lib.js, TS
   mirror): look_at, attack_entity, click_window, close_window, use_item.holdMs, expect_window (title / item count /
   slot icons), expect_particle, expect_sound, expect_bossbar, expect_sidebar; action bar packets recorded as chat;
   item labels read from custom_name OR item_name.
3. **Judged with evidence** (`evaluate.ts`): pass only when every judged step ran and matched; setup failed = not_run
   (the mod is not blamed); act / check failed = fail; a server error logged during the scenario = fail; not flown =
   not_run. score = passed / (passed + failed); coverage = tried / total.
4. **Isolation and bounds**: the boot verdict / label / install block are computed from the boot spec alone; an oracle
   derive/evaluate exception = `functional.state: not_run` ("oracle error"); an invalid probe returns the ORIGINAL
   spec; a runner that refuses the probes is re-flown at once without them (both tested). Budget 45 s scenarios +
   15 s join, <= 24 console checks, <= 15 scenarios; over budget = not_run "time cap".
5. **Integration**: `ModBuild.cyrus.testFlight.functional` (gate-worker, `defaultGateDeps.oracleInput` reads the jar +
   CyrusProjectAsset design rows + the flown data packs); portal project page card **"What we verified"** (plain
   words, failures first, footnote on what a server test cannot cover); admin build page "Behaviour (oracle)" table
   with evidence; eval stage **`behaviour`** + `Scored.behaves` (`eval-run.ts --testflight --oracle`), report line and
   `eval-journal-stats` behaviour block (behaves % over builds where it ran + per-kind table).

## "Suspect the oracle"
- Unit level: every kind has a golden (the evidence a working mod produces -> pass) and a one-defect mutant (-> fail,
  no collateral failures); setup failures -> not_run; busy / bot never joined / not flown -> not_run; the new bot steps
  each have a golden + mutant against a fake mineflayer.
- Real level: the first real flights exposed **8 bugs in the oracle itself**, each triaged from the raw evidence, fixed
  and pinned by a test BEFORE the final numbers:
  1. designer items are named with the `item_name` component, not `custom_name`: menus "failed" their icon check;
  2. a console step is an action for the bot, it reset "since the action": the Flame Ring's particles were discarded;
  3. a mod that teaches its recipe on join answers "No new recipes were learned": now `recipe take` first;
  4. `xp query points` is the progress inside a level (float-truncated 10 -> 9): compare the level;
  5. `/meadow <give|tp|..> [item]`: the item names are unknown -> not_testable (was a false fail);
  6. **false PASS**: Paper 1.21 answers a broken plugin command with "An unexpected error occurred" (Brigadier), not
     Bukkit's "An internal error occurred": the disabled goblin's command looked healthy;
  7. a knockback on the player moves it only through client physics (measured 0.00 blocks): not a fair "moved" check;
  8. the oracle's own "stop sneaking" (Flame Ring cleanup) fired the charge-release Flame Dash and put it on cooldown:
     charge abilities now fly first and wait 500 ms after the hold.

## Real flights (node-2, Paper 1.21.11, build lock held per flight; final oracle)
| build | boot | behaviour | pass / fail / not tried / not testable | flight |
|---|---|---|---|---|
| shop-gui (4 menus) | passed | passed | 12 / 0 / 0 / 0 | 48 s |
| fire-sword (item, 4 abilities, HUD, recipe) | passed | passed | 8 / 0 / 0 / 2 | 44 s |
| daily-quests (menus, quests, data pack) | passed | passed | 12 / 0 / 0 / 3 | 47 s |
| boss-minions (boss + items) | passed | passed | 6 / 0 / 0 / 0 | 42 s |
| fox-companion (creature, BetterModel provided) | passed | passed | 3 / 0 / 0 / 3 | 35 s |
| armor-set-bonus (plain + data pack) | passed | passed | 6 / 0 / 0 / 0 | 37 s |
| custom-recipes (plain + data pack) | passed | passed | 10 / 0 / 0 / 0 | 88 s (lock wait) |
| food-potions (plain) | passed | passed | 4 / 0 / 0 / 0 | 33 s |
| magic-wand (plain) | passed | passed | 4 / 0 / 0 / 0 | 36 s |
| economy-config (plain) | passed | passed | 7 / 0 / 0 / 0 | 27 s |
| biome-datapack (plain + worldgen pack) | passed | passed | 4 / 0 / 0 / 1 | 32 s |
| goblins v1 (BetterModel provided) | passed | passed | 3 / 0 / 0 / 2 | 34 s |
| **goblins v1, no BetterModel (= today's main gate)** | failed | **failed** | 0 / **3** / 0 / 2 | 35 s |
| goldens mc-kits, mc-shop, mc-weapon, mc-quest | passed | passed | 9 / 0 / 0 / 0 | 24-73 s |
| mutant shop-gui: Buy Stone gives 1 (config) | passed | **failed** | E4 "LACKS 16x stone (matching 1)" | 48 s |
| mutant shop-gui: shop_blocks title changed | passed | **failed** | E3 menu_opens + E10 "Blocks" button (title), E4/E5 not_run (blocked) | 57 s |
| mutant fire-sword: ability sound replaced | passed | **failed** | E4 "did NOT hear ...fireball_launch; heard note_block.pling" (+ Flame Dash = oracle bug 8, flown before its fix) | 47 s |
| mutant magic-wand: main class broken | failed | **failed** | 4 / 4 fail ("did not start", "Unknown or incomplete command") | 33 s |
| mutant daily-quests: Coin Pouch gives 1 | passed | **failed** | E5 "LACKS 10x emerald (matching 1)" | 47 s |

Totals on the 12 owner builds + 4 goldens: **88 pass, 0 fail, 0 not run, 11 not testable**. Mutants: **5 / 5 caught**,
each by the expectation that matches the defect; 4 of them (shop count, shop title, fire-sword sound, daily-quests count)
pass the boot test, so they are failures nothing in Cyrus caught before.
Time added: the bot stage took 7-31 s (median 8 s, includes the ~2.3 s join), oracle console checks ~0.25 s each
(<= 1.5 s); whole flights 27-51 s vs ~20 s for a boot-only golden. The hard cap is 45 s + 15 s join.

**Genuine catch, honestly stated:** on the 12 real owner builds the oracle found **no behaviour defect beyond what the
boot check already shows**. The one real failure is the owner's goblin class (compiled, booted, did not enable without
BetterModel, which is what the main-branch gate does today): the oracle reports it as "Goblins starts on the server: did
not work", "/goblins answers without an error: did not work", "/goblins give goblin_tooth: did not work" in plain words
on the "What we verified" card. Two earlier "catches" turned out to be oracle bugs (list above), not mod defects.

## Limits (oracle-1)
- creature_spawns is always not_testable (how a creature appears is AI-written; a model is drawn only by a client);
  encounter and motion designs not driven.
- Abilities gated by chance (fox Befriend 35%), the off hand, other worlds, death, projectile hits or block breaks:
  not_testable. Quests started only by a menu button (daily-quests' three) only "not testable"; crafting objectives not
  driven. Recipes are proven registered (`recipe give`), not crafted in a grid.
- Plain AI-written plugins: only enables / commands answer / `give` / reload (their behaviour has no spec). This is the
  next lever: the requirements ledger (BX card 5) would give the oracle a spec for plain mods.
- Particles / sounds are the packets the server sent, not what a client renders. Only 1.21.11 has a verified test player
  (other versions fly the console checks only).
- The gate's oracle input sets `engines: []`: when fix/cyrus-testflight-bettermodel merges, pass `art.engine` name there
  so creature mods get "engine provided" reasons. With CYRUS_PLAYTEST on, the merged plan's `op` is the OR of both plans.
- Eval flights carry no data packs, so data pack expectations do not appear in eval runs (the gate flies them).

## Coordination with feature/cyrus-eval-realism
That branch had no commits at the time. Contract kept: stage name **`behaviour`** (pass / fail / not_run), journal
`result.flight.functional` (trimmed StoredFunctional) and `result.behaves`. Intended "real pass" rule documented in
16-behaviour-oracle.md: real pass needs `behaviour = pass` when it ran; a `not_run` behaviour never makes or breaks one.

## Owner commands
Portal-only change: **no build-service image bump** (the runner files bot.js / playtest-lib.js are pushed to node-2 by
the portal at every flight; runner.js is unchanged). No schema change, no migration.
```
cd /opt/nxeon && git merge --ff-only feature/cyrus-behaviour-oracle   # or merge into the release branch you promote
bash scripts/promote-production.sh --skip-staging-check
# then, when you want it on: add CYRUS_TESTFLIGHT_ORACLE=1 to /opt/nxeon/.env and restart the worker (gate sweep)
```
Recommended order: merge fix/cyrus-testflight-bettermodel first (creature mods otherwise fail mod_enables honestly), then
this branch. Eval with behaviour: `npx tsx scripts/cyrus/eval-run.ts --tag b1 --preset first-run --budget 40 --testflight --oracle`.
Real flights on given jars: `npx tsx scripts/cyrus/oracle-flight.ts --builds DIR --keys a,b` (DIR = `<key>.jar` +
`<key>.build.json` from the build service), `--goldens mc-kits,...`, `--mutant <key>:count|title|sound|main`,
`--engine-from /tank/dev-worktrees/cyrus-tf-bm` until BetterModel provisioning is merged. Not deployed by me.

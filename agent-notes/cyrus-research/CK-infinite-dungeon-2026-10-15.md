# CK: Minecraft: The Infinite Dungeon, staged portal run (2026-10-15)

STATUS: BLOCKED at stage 1 by the real `daily_cap` gate ("5,000 tokens a day"). Nothing was built, nothing charged. Not bypassed.

Account cmrztujaw0002hlazl58i3lsi, balance 11,877, reserved 0 (unchanged). The previous batch (BV note) used ~4.4k of the 5,000/day rolling window between ~18:00 and 19:19 UTC on 2026-10-14. Refused at 06:2x UTC 2026-10-15; the window should free from ~18:43 UTC 2026-10-15 (earliest builds age out first), or the owner raises the cap.

## Prepared (committed, branch feature/cyrus-dungeon-run, worktree /tank/dev-worktrees/cyrus-dungeon, commit 4d273085)
- scripts/cyrus/qa-dungeon.ts: planner (change-aware, coach hook) -> createModBuild(requirePlanAck, model auto, approved lanes, planAck). Stage 1 = fresh build; stages 2-6 and `--fix "text"` = REFINE via `{ baseBuildId, changeRequest }` on the last succeeded journal build (same body app/api/cyrus/generate sends for a refine; plan screen is POST /api/cyrus/plan with change:true). Waits for terminal + Test Flight, writes per-build records.
- scripts/cyrus/qa-dungeon-prompts.json: the 6 stage prompts in the owner's voice.
- Stage 1 plan lanes the planner chose: designBoss, designHud, config build; everything else skip (no creature/texture lane for the core).

## Tracker
1. [blocked] Stage 1 core: rerun after cap frees.
2. [todo] Stages 2-6 refines, one fix refine max per stage, stop on 2nd failure of same stage.
3. [todo] Spend cap 4,500 tokens: at ~400-600 tokens/build the 6 stages (~3,000) will not fit one 5,000/day window together with any other usage; plan on 2 days or a cap raise (>= ~9-10 builds/day per hold sizes).
4. [note] A stage refine of a growing mod will hold more than a small build; expect later stages above 600.

## Commands (owner/QA, from the worktree)
```
/tmp/claude-0/run.sh stage 1      # wrapper: sources /opt/nxeon/.env, NODE_PATH=/opt/nxeon/node_modules, tsx scripts/cyrus/qa-dungeon.ts ... --user cmrztujaw0002hlazl58i3lsi --out /root/cyrus-eval/dungeon-2026-10-15
/tmp/claude-0/run.sh stage 2 ... 6
/tmp/claude-0/run.sh stage 3 --fix "targeted fix text"   # only the one allowed repair refine
/tmp/claude-0/run.sh status
```
Install/try (once a stage succeeds): portal Cyrus library -> the mod -> install on server; in game `/dungeon start`, `/dungeon status`, `/dungeon leave` (or `/dungeon abandon`) returns to the overworld; config in plugins/<PluginName>/config.yml.

Honest outcome so far: no mod exists yet; the "what works / what does not" sections cannot be written.

## Redesign round 2 (2026-10-15, later same day; the STATUS line at the top of this file is stale: the 6 stages DID build, last stage-6 build mb3879f4526e730a7e96b1)
Runner: scripts/cyrus/qa-dungeon.ts in /tank/dev-worktrees/cyrus-dungeon (uncommitted edit: base now = last SUCCEEDED journal build, plus `--base <id>` override). Records in /root/cyrus-eval/dungeon-2026-10-15.

| Stage | Build | Ver | Wall | USD / tokens charged | Result |
|---|---|---|---|---|---|
| 7 shrink to 11 floors | mb3fa7542c798d8a12679e | 1.7.0 | 148 s | 2.88 / 1,798 | succeeded, Test Flight passed (compile/scan/boot/plugins/commands), 1 repair |
| 8 bigger rooms + hidden chests + loot scaling | mbdeca41d1bf0cbebd4d83 | 1.8.1 | 553 s | 2.08 / 1,042 | succeeded, Test Flight passed, 1 asset repair |
| 9a themes + Hollow Banshee (one prompt) | mb134f27061b9f30ccf851 | - | 372 s | 2.54 / 0 (released) | FAILED errorCode budget (spending cap) |
| 9b themes only, banshee dropped | mb8ae6fbd20ac3a5d7e7ff | - | 526 s | 4.09 / 0 (released) | FAILED budget again after 3 repairs; stopped per rule |

Latest good build: mbdeca41d1bf0cbebd4d83 (v1.8.1, jar InfiniteDungeon-1.8.1.jar).

What changed (verified in source): max-floors 11 in config.yml, HUD reads "Floor N / <max-floors>" from config; boss.floor-interval 3 (bosses on 3, 6, 9) and floor 11 is always the final boss (health x3.5 default, extra minions). Interval choice: every 3rd floor. Stage 8 changed room generation and chests; I did not read that source in depth, so verify bigger rooms/secrets/loot scaling in game.
What does not work: themed floors (5-6 themes) and the swamp banshee are NOT delivered. Both refines hit the per-build spending cap on the change call (~$2-2.5 for the change alone; theming 11 floors of room code is too large for one build). Next try, split further: (1) one refine adding a theme registry + 2 themes (castle, lava), (2) 2 more themes, (3) remaining themes, (4) banshee as its own creature refine. Note the creature cap: stage 2 dropped "hollowbanshee" ("more than 4 creatures"), so the banshee has no model in any build; a banshee needs a creature slot (replace one of bonewarden/cinderhusk/direwolf/hexwitch) or a vanilla-mob (vex/allay-skinned) variant shooting soul projectiles from code. Also: the 8 stage-2 sounds sets exist for hollowbanshee/ironrevenant/venomspider/voidwraith, i.e. those 4 monsters run as vanilla mobs with custom names.

Texture bug (floor 1 purple/black mob), evidence from build mb3879f4526e730a7e96b1:
- Floor 1 mob is the bonewarden: base ZOMBIE wearing BetterModel model `nx_oqyxirj4_bonewarden` (MonsterManager.attachModel, BetterModel.model("nx_oqyxirj4_"+id)). Spec assets/creatures/bonewarden.json has a full palette skin; delivered counts: creatures 4, textures 12, sounds 17, pack url+sha256, clientVerified field present, loader required field present.
- plugin.yml `depend: [BetterModel]`; Test Flight enabled BetterModel and "placed 4 models", boot clean.
- The warnings "plugin never uses the model key nx_oqyxirj4_bonewarden" are a FALSE POSITIVE of the creature checker (key is built by string concatenation in code). It is a checker limitation, not a delivery bug. Worth a follow-up so it stops warning.
- I did not download the actual resource pack zip or test with a real client, so this is not proven. Most likely cause: client did not accept/download the BetterModel/Nxeon resource pack (classic purple/black checkerboard). Other possibility not excluded: BetterModel 2.2.0 pack and Nxeon pack both pushed and the second replaced the first. Owner: rejoin and accept the pack (server resource-pack prompt), then check F3+T/refresh; if the checkerboard persists after accepting, send me a screenshot and the client log.

Owner commands to try v1.8.1: portal Cyrus library -> Infinite Dungeon -> pick version 1.8.1 -> install / reinstall on the server, then restart the server (BetterModel needs a restart to hand out its pack); rejoin and accept the resource pack; in game `/dungeon start`, `/dungeon status`, `/dungeon admin setfloor 10` to reach the final boss quickly, `/dungeon leave`.

### Redesign round 2, continuation (split refines, all on base mbdeca41d1bf0cbebd4d83)
| Step | Build | Ver | Wall | USD | Tokens | Result |
|---|---|---|---|---|---|---|
| a castle + lava themes | mbceb7fd88b8b4862a7a3d | 1.9.0 | 166 s | 0.65 | 326 | passed |
| b swamp theme | mb29c267872092cd14e432 | 1.10.0 | 198 s | 0.85 | 425 | passed |
| c Hollow Banshee (vanilla code mob, ghost projectiles) | mb22e52929d18d770fafa7 | 1.11.0 | 526 s | 2.16 | 1,080 | passed, 2 repairs |
| d1 ice + crypt + ruins themes | mb0c1c82809b1ee2aca000 | 1.12.0 | 209 s | 0.75 | 378 | passed |
| d2 boss-floor arenas | mb05dabe83580f8491a546 | 1.13.0 | 353 s | 3.79 | 2,367 | passed, 1 repair |
FINAL: mb05dabe83580f8491a546 v1.13.0. Splitting fixed the budget failures (no further failures). Verified in source: 6 themes (castle, lava, swamp, ice, crypt, ruins) + a "throne" theme for floor 11; ambient particles for swamp/ice/crypt; boss arenas floor 3 ice, 6 swamp, 9 lava, 11 throne; Hollow Banshee is a vanilla mob that shoots projectiles, boosted on swamp. NOT done: three animated BetterModel boss creatures (ice/swamp/lava) - not attempted, blocked by the 4-creature cap (dungeon already uses bonewarden, cinderhusk, direwolf, hexwitch; retiring 3 of 4 would not be coherent); wait for feature/cyrus-no-creature-cap image.
Thumbnail cast vs shipped: banshee = vanilla mob with projectiles, no ghost model (partial); lich king NO; ice golem NO (ice arena only); swamp golem/treant NO (swamp arena only); lava golem NO (lava arena only); skeleton king NO (throne hall only, boss is whatever BossManager already has); giant cave spider NO.

### Round 2, post-rc18 (modbuilder 0.23, no creature cap)
- Cap lifted: build mb6c1ca6ee26430b06081c v1.14.1 delivered 5 creatures, dropped 0 (was 4 max). Health knowledge changed to sheets+rules-2026-10-15.1.
- Ice boss attempts: mbbee4a3822b8cbeb16f9c REFUSED by guard (3 s, $0.003); reworded -> mb6e5e2ece247cc07bf492 FAILED budget ($2.66); split -> mb6c1ca6ee26430b06081c SUCCEEDED v1.14.1, 317 s, $1.70, 849 tokens, 1 repair. Shipped: Frost Colossus creature (humanoid archetype rig, iron golem base) wired to a room via FROST_COLOSSUS_FLOOR with hurt/death/attack sounds; NO custom abilities/phases yet.
- Abilities refine (mbed127678a15c23a6b771, mb7c8b6bb3709d2427fec2) REFUSED by the safety guard twice (4-5 s, $0.003 each). Stopped per rule. Not attempted: swamp boss, lava boss, lich king, skeleton king, cave spider, banshee model.
- Caveat: the Frost Colossus is placed with `!bossFloor && floor == FROST_COLOSSUS_FLOOR`, i.e. a non-boss floor; I did not confirm it is on floor 3's ice arena. Verify in game.

### Round 3: custom creatures only (after rc18/0.23; base mb6c1ca6ee26430b06081c v1.14.1)
All succeeded, Test Flight passed, wiring re-read from source after the final build (BetterModel in plugin.yml depend, MODELED_IDS + literal MODEL_* constants whose values equal the delivered assets/creatures spec names, attach via BetterModel.model(modelKey(id))).
| Step | Build | Ver | Wall | USD | tokens | creatures |
|---|---|---|---|---|---|---|
| castle: Castle Guard, Gargoyle | mbdc21e26b3aacd3254d87 | 1.15.0 | 350 | 1.64 | 818 | 7 |
| lava: Ember Imp, Magma Brute | mb62235d2590ea789fcd6b | 1.16.0 | 170 | 1.36 | 682 | 9 |
| swamp: Bog Lurker, Wisp Hag | mbd2963f9d6e0adfa3b612 | 1.17.0 | 221 | 1.01 | 505 | 11 |
| ice: Frostbitten Wraith, Glacier Hound | mbcf8ec9902c2f973d461f | 1.18.0 | 207 | 1.42 | 709 | 13 |
| crypt: Grave Shambler, Bone Archer | mb61f85d00492eaab67429 | 1.19.0 | 235 | 1.21 | 604 | 15 |
| ruins: Thorn Stalker, Moss Sentinel | mb4263909dad89eae3d493 | 1.20.0 | 202 | 1.14 | 572 | 17 |
| floor 6 Mire Treant | mb1644589ae9860fcbe1d3 | 1.21.0 | 283 | 2.44 | 1526 | 18 |
| floor 9 Molten Colossus | mb6f995ada6d83a8f09b55 | 1.22.0 | 204 | 1.96 | 1222 | 19 |
| floor 11 Lich King | mbd8b9d28373c3e4748e92 | 1.23.0 | 390 | 1.74 | 871 | 20 |
| Skeleton King + Royal Skeleton Guards | mb55639aa1a39e91a3f5fd | 1.24.0 | 346 | 1.72 | 861 | 22 |
| Giant Cave Spider | mb2c6536a4cdb226e21350 | 1.25.0 | 205 | 1.31 | 655 | 23 |
| Hollow Banshee ghost model | mbe94b7e5992e0a1c0df8d | 1.26.0 | 186 | 1.12 | 561 | 24 |
| Frost Colossus abilities | mbc97b0d7ad963f7ca7a8d | - | 3 | 0.003 | 0 | REFUSED by guard (fix not live) |
FINAL v1.26.0 mbe94b7e5992e0a1c0df8d: 24 creature specs, 23 modeled monster ids. Still vanilla-type: the 10 rotating floor bosses in BossManager (gravelord, emberjaw, broodmother, hexarch, ironclad, frosthowl, dreadplate, banshee boss, moltenwarden, voidwraith) are vanilla EntityTypes with names (floors 3/6/9 boss arenas use these unless the new creature room replaces them: Frost Colossus has a dedicated room on a non-boss floor, Mire Treant/Molten Colossus were asked to replace floor 6/9 enemies - read DungeonManager to confirm). Frost Colossus and Gargoyle, Bone Archer have no abilities. Every BetterModel creature still sits on an invisible vanilla base entity (that is how BetterModel works); models need the pack hand-off fix shipping in rc19 to render.

### Round 4 + CORRECTION (read this first)
SILENT REGRESSIONS found by reading config.yml/plugin.yml of every build:
1. max-floors 100 and boss floor-interval 10 came back in v1.8.1 (mbdeca41d1bf0cbebd4d83, the "bigger rooms" refine) and stayed in EVERY build from 1.8.1 through 1.26.0. Only v1.7.0 (mb3fa7542c798d8a12679e) has 11 / 3. My earlier claim that the final build has 11 floors was wrong (I only verified v1.7.0/1.13.0 partly; 1.13.0 also had 100). Test Flight cannot see this.
2. v1.27.0 (mb375d7c58807fd4483998, Siege Warden) and v1.27.1 (mb51322a365e1e9476d7be, config fix) lost BetterModel wiring: no `depend: [BetterModel]`, no BetterModel.model calls (1.27.1 has no BetterModel text at all), Siege Warden has no creature spec. Test Flight still "passed".
3. v1.27.1 did restore max-floors 11 / floor-interval 3 in config.yml.
Last build with creature wiring intact: v1.26.0 mbe94b7e5992e0a1c0df8d (but 100 floors, interval 10). No single build has both.
Round 4 steps: boss-floor replacement mb4fe516c31d51ee5a23d6 REFUSED (guard); miniboss x4 mba78375a41253a370f9b4 FAILED budget; x2 mb69e86cbeb6d9c4275bb2 FAILED budget ($4.08); Siege Warden alone mb375d7c58807fd4483998 succeeded v1.27.0 $3.67 but lost wiring; corrective wiring refine mb843e6c9b5648f8753b69 REFUSED; config fix mb51322a365e1e9476d7be v1.27.1 $1.45 fixed floors but lost wiring again.
Lesson: every refine needs a mechanical post-check of config.yml (max-floors, floor-interval) AND plugin.yml depend + BetterModel.model count; the build service passes regressions silently. Suggested fix for the owner of the portal: ledger/requirements check on config defaults and on creature attach.

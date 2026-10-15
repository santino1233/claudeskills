# CI: Designer boss wears a real creature model (2026-10-15)

Branch `feature/cyrus-boss-model`, commit 04674c3a (one commit on main 98d82fe0), worktree /tank/dev-worktrees/cyrus-boss-model.
Verified, NOT merged, NOT deployed. New switch `MB_BOSS_MODEL` (build service), default OFF.

## Problem (rc13 finding)
The designer route compiles the whole plugin from designs, and a boss design only names a vanilla `entity`. Nothing
could attach a BetterModel model, so rc13 switched the creature lane off up front and reported a lane gap. A prompt like
"a boss mob, the Hollow King, that summons minions" got a plain wither skeleton.

## What was built
1. **Spec (additive to designer schema v1).** On a boss: `"model": {"rig": "<creature name>", "scale"?: 0.5-2 (hard 0.25-4),
   "clips"?: {"attack"|"hurt"|"phase"|"death": "<clip>"}, "sounds"?: {"hurt"|"death"|"attack"|"ambient"|"spawn": "<key>"}}`.
   Minions can carry `summon.rig`, and encounter waves can carry `spawns[].rig` (with `entity` only; `rig_on_boss` is an
   error). The same zod source feeds the TS validator, the generated service checker (`designer-spec.js`) and
   `boss.v1.schema.json`.
   Cross-reference checks: a rig the mod does not have is the warning `rig_unresolved`, and the mob keeps its vanilla body
   (warn, don't block). Without a rig list the warning is `rig_unchecked`. Model sounds go through the normal boss sound
   checks (namespace, asset exists). Non-standard clips give `clip_custom`, and display equipment on a model boss gives
   `model_equipment`.
2. **Compiler.** `designer/BossModels.java` is emitted only when something wears a rig. It is the single class that uses
   `kr.toxicity.model.api`. It only calls members that javap shows in BOTH BetterModel 2.2.0 and 3.5.0: `modelOrNull`,
   `getOrCreate(BukkitAdapter.adapt)`, `scaler(ModelScaler.value)`, `animate`, `isClosed`, `close` and `damageTint`.
   - **Spawn:** the base mob is made silent and invisible before it enters the world, then the tracker is attached.
   - **Hitbox:** the scale attribute is set to rig hitbox height × model scale / vanilla height. This is computed at
     compile time.
   - **Clips:** BetterModel plays idle and walk by itself (its built-in tracker animations). The boss runtime plays the
     attack clip on every cast, the phase clip (default: the attack clip) on a phase change, and hurt (+ tint) and death
     clips. The model closes 3 s after death.
   - **Sounds:** the creature's sounds play on spawn, attack, hurt, death, plus ambient every 8 s.
   - **Cleanup:** models close on despawn, death, chunk unload (a sweep every AI tick) and disable. `/bettermodel reload`
     re-attaches lazily.
   - **Kept from the design:** boss bar, phases and abilities are unchanged.
   - **Declarations:** `depend: [BetterModel]` and the version's compile-only API deps (`bettermodel-api-2` /
     `-bukkit-api-2` on 1.21.x, `bettermodel-api` / `-bukkit-api` on 26.x) are added automatically.
   - **Evidence:** the mob gets the tag `<ns>.model`. `boss status` / `spawn` print
     `model <key> attached, hitbox xN, clips N (missing N), invisible true, silent true`, or
     `vanilla body (<why>), invisible false, silent false`.
   - **Boss mods without a model:** no BetterModel reference anywhere (the hub hooks stay dormant). Their golden hashes
     changed only because of the shared hub source.
3. **Planner / lanes (service).**
   - `parseAssetsRequest` keeps the creature lane next to the designer's bosses part when `MB_BOSS_MODEL=1`
     (`assets.bossModel`). Items- or menus-only designer builds still drop it, as in rc13, and with the switch off it is
     exactly rc13.
   - The design compile gets the workspace's valid rigs and their hitbox heights (`designs.js rigsOf`). The summary carries
     `rigsApplied` / `rigHeights`, and the portal re-compile passes them back, so `serviceAgreed` holds (tested).
   - On the designer route the creature soft checks talk about the design ("add "model":{"rig":...}").
   - `lanegaps`: a creature counts as delivered when something wears it. A creature that nothing wears is a gap with that
     reason.
4. **Prompt.** One line (505 chars, about 126 tokens) is inserted after the BOSSES section. It appears only when design,
   bosses, creature and bossModel are all on; otherwise the system prompt is byte-identical (tested). The user-turn
   creature hint changes to `a boss wears one with "model":{"rig":"<name>"}` (shorter). `BOSS_MODEL_PROMPT_VERSION =
   mb-bossmodel-2026-10-15.1`. The golden example is the Hollow King mod in `test/fixtures/cyrus-boss-model`:
   - a wither skeleton boss wearing the humanoid rig `hollow_king`, with a custom phase clip and four sounds;
   - zombie minions wearing the `hollow_thrall` ghost rig;
   - an encounter with thrall waves and then the boss.
   `scripts/cyrus/boss-model-golden.ts` regenerates it.
5. **Oracle.** For a boss that wears a creature of the build, when BetterModel is in the flight, `boss_spawns` adds two
   probes: the `<ns>.model` tag selector and `boss status` = `model <ns>_<rig> attached`. `creature_spawns` for that rig
   says it is proven by the boss's probes, and that its look still needs a client.

## Verification
- `tsc` reports 0 errors (devhost).
- Full `test/cyrus*` + `test/modbuilder*` suite: **4017 tests, 4016 pass, 1 fail**. The failure is the known pre-existing
  `cyrus-liveassets-e2e` "mid-stream views" timing failure.
- New `test/cyrus-boss-model.test.ts` (19 tests). Boss, HUD and docs goldens and references regenerated.
- **Real javac (node-2, `test/cyrus-boss-model-real.ts`):** 0 warnings and the strict scan is clean (0 blocks / 0 warnings)
  on both lanes:
  - 1.21.11 / JDK 21 against Paper 1.21.11 + the BetterModel 2.2.0 API;
  - 26.2 / JDK 25 against Paper 26.2 + the BetterModel 3.5.0 API.
  The API jars were fetched on node-2 from Maven Central and matched against the `deps.json` sha256. The fallback build
  compiles WITHOUT the API on the classpath. The existing boss fixtures still javac clean on both lanes.
- **REAL Test Flight A** (node-2, build lock held; Paper 1.21.11 + pinned BetterModel 2.2.0 paper jar, seeded libraries,
  the managed config and the two `.bbmodel` files Nxeon compiles from the rigs): **PASSED**, 7 checks, boot 19.5 s,
  peak RSS 1000 MB.
  - Both plugins enabled.
  - The spawn reply says `model nx_b0ssm0de_hollow_king attached`.
  - The `<ns>.model` tag is on the boss, `Silent 1b`, and the status shows `invisible true, silent true`.
  - Scale attribute is **1.21** (2.9 / 2.4); the minions wear their model at **0.82**.
  - BetterModel started the clips with **0 missing** (2 after hurt + cast, 4 after the phase change).
  - **Survival Mineflayer bot inside the arena for 66.5 s, 23/23 steps:** it saw the boss bar "The Hollow King - Ruin".
    Participants stayed at 1 and the tracker was still attached at every 20 s sample. The AI summoned minions 0 -> 6.
  - **TPS** 19.5 / 19.7 / 20.0 (19.1 just after boot). No "Can't keep up".
  - Kill -> the defeat message reached the bot. At stop the log has `cleanup: closed 1 creature models` and
    `removed 1 bosses`.
  - The whole latest.log has **0 plugin error lines and no exception from the mod or BetterModel**. The only exception
    lines are the sandbox's no-internet ones (Yggdrasil key, PaperVersionFetcher).
- **REAL Test Flight B (fallback: BetterModel running, models not delivered): PASSED.** The boss shows
  `vanilla body (BetterModel has no model ... loaded), invisible false, silent false` at scale 1.0. There is no model tag,
  the fight still works (minions spawn), and the log has one warning per model.
- Evidence: `CI-boss-model-flights-2026-10-15.json` (next to this report).
- **Bug found by the first real flight and fixed:** BetterModel's `Tracker.height()` is not the model height. It read
  0.30 for a 2.9-block rig, which clamped the hitbox to x0.25. The hitbox scale is now computed by the compiler from the
  rig's declared hitbox.

## Limits (honest)
- **Not verifiable server-side:**
  - how the model looks and animates for a player (no real client);
  - that BetterModel hides the base mob's held sword and armour (default `EntityHideOption`);
  - nametag height, and that the resource pack download works.
  Bedrock / no-pack players see an invisible mob.
- **The death clip** has about 1 s visible: the game removes a dead mob after 20 ticks.
- **26.x** is javac-verified only; there was no 26.x flight in this round.
- **"BetterModel unavailable" means two different things:**
  - At build time (version without the API, or creature lane off): the boss compiles with a vanilla body and no depend.
  - At runtime: with `depend: [BetterModel]` the plugin will not enable without BetterModel. This is by design, as the
    brief asked; Nxeon installs the managed BetterModel whenever creatures ship. The runtime fallback covers "model not
    loaded".
- **Designer edits** (no-model rebuilds) of mods with creatures are still refused (`designEdit` limit).
- **Planner prompt unchanged:** a request must still lead the planner to plan the creature lane next to `designBoss`.
- **No live model build was run** (no paid builds). The model call writing both specs is prompt + unit-tested, not
  measured.

## Flags
- `MB_BOSS_MODEL` (build service, default OFF; `/health features.bossModel`, admin Flags page entry). Off = rc13
  behaviour exactly.
- No portal flag. The portal changes are inert for builds without `rigsApplied`.

## Owner commands
Image bump needed: YES (services/modbuilder changed: designer-spec.js, designs.js, creatures.js, lanegaps.js, prompts.js,
server.js, textures.js; no new files, so the Dockerfile COPY list is unchanged). The running image is modbuilder:0.21
(rc15), so the next tag is 0.22. With the service idle (GET http://127.0.0.1:7340/health shows running 0, queued 0):

    cd /opt/nxeon && git merge --ff-only feature/cyrus-boss-model   # or merge into the release branch you promote
    bash scripts/promote-production.sh --skip-staging-check
    cd /tank/dev-worktrees/cyrus-boss-model && TAG=modbuilder:0.22 bash scripts/cyrus/deploy-modbuilder.sh
    # to switch it on: add MB_BOSS_MODEL=1 to the build service env, restart it (recommended: an eval subset first)

Re-run the real proof: `cd /tank/dev-worktrees/cyrus-boss-model && /opt/nxeon/scripts/devhost run --lock -- npx tsx test/cyrus-boss-model-real.ts --out /tank/nxeon-build/tmp/cyrus-boss-model/results.json`.
State: nothing deployed, nothing merged.

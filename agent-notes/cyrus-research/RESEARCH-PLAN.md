# Cyrus master-plan: RESEARCH PLAN (not the research itself)

Date: 2026-10-09. Goal: make Cyrus the best AI game-mod studio, Minecraft first. Shared context lives in `BRIEF.md` (same folder).
Status: nothing researched yet. Seven parallel agents were started and stopped before producing anything (weekly usage was at 99%). This plan runs the research **one step at a time, in one session, small and bounded**.

## WHAT WE ARE BUILDING (owner, 2026-10-09): a real game-mod ENGINE, not an AI prompt box
The prompt box is one input. The product is an **engine** whose source of truth is a **structured, versioned mod project**, not a chat transcript. Every feature in this plan is judged by: does it make the engine more real (typed, validated, testable, editable, composable) or is it just another prompt wrapper?

**Engine layers**
1. **Mod project model (the "source").** A typed, versioned project: ModSpec / content IR (items, mobs, abilities, GUIs, quests, recipes, loot, biomes...), code files, assets (textures, models, sounds), data packs, configs, dependencies, tests. Stored as revisions (like git): every change is a diff, every revision reproducible and revertible. The chat history is not the project.
2. **Registries.** Capability registry (what each game/version can do), version registry, **identifier registry** (namespaced IDs for items, models, sounds, commands, permissions, recipes, glyphs), asset registry with licence/provenance. Registries are authoritative for routing, validation, conflict detection and UI.
3. **Generators (compilers).** Deterministic generators turn the IR into code, data packs and resource packs for common mechanics; free-form code generation is the fallback for the unusual. The AI is the **author/planner/editor** that proposes IR changes and writes custom logic; the engine validates and builds. Users can also edit the project directly through designers and studios, with no prompt needed.
4. **Validators + build.** Schema validation, compile, scan, asset validation, pack validation, per-version checks. No stage is skipped silently.
5. **Test Flight (runtime harness).** Real disposable server, mock tests, bot scenarios, performance checks, honest per-check statuses.
6. **Composition layer.** **Conflict engine** + **Mod Packs** (combine mods and assets, resolve or flag clashes, test the combined result, install and roll back as one unit).
7. **Importer.** Bring a mod you own into the engine as revision 0 and keep working on it (see Top priorities below).
8. **Editors.** Texture Studio, Sound Studio, data/GUI/quest/boss designers, ability graph: all edit the same project model.
9. **Delivery + lifecycle.** Pack hosting and multi-pack merge, install/uninstall/update/rollback, diagnostics, version upgrade assistant, NxLabs publishing with evidence-backed labels.
10. **Per-game adapters** on a shared core (Foundation Principle below).

## TOP PRIORITIES (owner, 2026-10-09)
1. **Asset Libraries + Studios, gated by plan tier** (see "Plan-tier gating"). A **Sound Library** (the owner's original 514-file library, tagged, plus synthesized presets, plus the customer's uploads) with the **Sound Studio**; a **Texture Library** (vanilla-style presets, customer uploads) with the **Texture Studio**. Libraries feed Cyrus's automatic asset generation. Every asset carries provenance and licence.
2. **Mod conflict engine + Mod Packs.** Real logic when combining mods or adding several Cyrus mods to one server: detect conflicts before install, resolve what can be resolved, and **compile mods into a versioned Mod Pack** tested as a whole.
3. **Bring your own mod.** Upload a mod you own (source project, jar, datapack/resource pack), work on it in Cyrus, and **build it with Cyrus** (edit by prompt or designers, rebuild, scan, test, version, install).
4. **Foundation for every other game** (Foundation Principle below).
5. **Delivery and economics that hold up:** resource-pack hosting off the primary, multi-pack merging, Bedrock-player honesty, per-feature pricing, and a quality bar for how assets look and sound.

## Plan-tier gating (owner decision, 2026-10-09)
Code reference: `lib/cyrus/tokens/config.ts` (`TOKEN_TIERS = free, katara, saka, all`; `PLAN_TIERS = katara, saka, all`; the model name for the top tier is Yakko).

| Plan | Models | Sound Studio + Sound Library | Texture Studio + Texture Library |
|---|---|---|---|
| Free | starter only | **No** | **No** |
| Katara (lowest) | Haiku | **No** | **No** |
| Saka (mid) | Sonnet | **Yes** | No |
| Top plan (`all`, includes Yakko) | Opus | Yes (assumed: higher tiers include lower) | **Yes** |

**DECIDED by the owner (2026-10-09):**
- Tiers are cumulative: **the top plan gets everything.**
- **Automatic asset generation is gated by what the user has access to and their plan**: Katara/free builds get default vanilla visuals and no custom sounds; Saka builds can get sounds; top-plan builds can get textures and sounds. The same check applies whether an asset is made by Cyrus automatically, in the studio, or from a library.
- **Mod Packs are NOT gated by plan** (the conflict checks that come with them are treated as part of Mod Packs and a server-safety feature, so also ungated).
- **Importing your own mod to work on it is NOT gated by plan.** (Building on it still uses tokens and the model the user's plan allows; an imported mod's assets follow the asset gates above.)
Still assumed: library browsing follows the studio gate.
Engineering notes: gate in one place (the capability/adapter layer reads the user's plan), never in the UI alone; the token reserve table needs per-feature rows for asset operations (it currently keys by `katara/saka/yakko`, while plans are `katara/saka/all`: reconcile the naming); upgrade prompts in the studio ("Sound Studio is on Saka and above") must be truthful and not show a broken feature.

## Ground rules (to protect usage)
- One step at a time. No parallel agents, no workflows. Each step ends by writing ONE short file here, then stops.
- Read-only: no server, repo, database or setting is changed by research.
- Sonnet, low effort. Prefer opening a few primary sources (official docs, repo README + LICENSE) over broad searching. Cap: ~12 source pages per step.
- Every claim is labelled `VERIFIED (url)` or `UNVERIFIED`. Stop a step early if the answer is clear.
- Nothing starts until the weekly usage resets, unless the owner says otherwise. Steps 1-2 are the only ones worth doing first.

## Facts we already have (no research needed)
- Nxeon's own Minecraft fleet (2026-10-09): of the 6 Paper servers with an explicit version, **4 run 26.x** (26.1.2, 26.2, 26.3 x2) and 2 run 1.21.x (1.21.1, 1.21.11); 1 more uses the default. Vanilla/fabric servers are a similar mix. Cyrus supports only 1.21.1/1.21.4/1.21.8/1.21.11, so **it cannot build for most customers' Paper servers today.** This makes 26.x the top compatibility item.
- What exists in code: texture spec + pixel renderer + pack builder (`lib/cyrus/textures`), browser sound synth (`lib/cyrus/sfx.ts`), the Mods install engine, NxLabs pages, token ledger. Owner's own 514-file sound library can be the Sound Studio's built-in library (owner will write the customer-facing licence).
- Delivery model for assets: Nxeon hosts the resource pack and sets `resource-pack` + `resource-pack-sha1` on the customer's server; players accept a prompt, no manual download.

## How this fits the two earlier plans (read this first)
Earlier today the owner attached two documents to the board: the **Revised Master Update Plan** (29 pages, reliability/launch/knowledge/versions/assets, tickets CYR-001..028) and the **Texture & Sound Studio Research Plan** (16 pages). This research plan does NOT replace them. It adds the missing capability questions (creatures, items, blocks, biomes, HUDs, multi-version, auto-generated assets). Rules for reconciling:

1. **Do not redo what they already cover.** The steps below start from their findings and only VERIFY or extend them.
   - Step 1 (versions) starts from Master Plan section 11 (Paper api-version through 26.3, Java 25, version registry design, 26.x lane = CYR-025).
   - Steps 5 and 6 start from the Texture/Sound plan's shortlist (wavesurfer.js, howler/Web Audio, jsfx, Tone.js, ffmpeg.wasm licence caveat, Pixelorama/LibreSprite/Blockbench as references) and its sound-licensing policy, and the 6-milestone roadmap. They check licences by opening the sources, which neither earlier plan did.
   - Step 7 starts from Master Plan sections 3-5, 8-10 (benchmark, MockBukkit + Paper smoke lane, retrieval, safe learning loop) and adds competitors and the Claude-specific techniques.
2. **Launch and reliability work stays in the Master Plan and comes first.** Not research, but it gates everything: deployment evidence + hardened scanner verified live (CYR-001/002/003), build-file protection and sandbox audit (CYR-004/005), launch-flag guard (CYR-006), durable job events and idempotent token settlement (CYR-016/017), benchmark harness (CYR-010). The new asset features must not ship before these.
3. **The asset features depend on a Master Plan piece.** Models/textures/sounds need the **project manifest + revision store (CYR-020)** to hold asset IDs, hashes, licences and edit history, and the build request must carry an asset manifest. So the real order is: launch gates -> manifest -> assets -> content types. Step 2 (gap audit) must confirm exactly where the manifest plugs in.
4. **Conflict to resolve:** the Master Plan says build the *smallest vertical slice on the existing renderer and pack builder first*; the Texture/Sound plan proposes a full editor (layers, AI inpainting, 3D preview, 9-17 weeks). Recommendation carried into the final plan: ship the slice first (spec -> texture -> validated pack, one pinned version, synthesized + library sounds), grow into the editor only on demand.
5. **Corrections to the earlier plans already found** (apply in the final plan): the Master Plan's baseline is out of date (several hardening items are already done; `ModBuild` stores no version/scanner record), neither plan includes resource-pack **delivery** to players, browsers cannot encode Ogg Vorbis (server-side encode needed), assets belong in the server-side project not IndexedDB, AI image generation needs a separate provider decision, free-build abuse limits are missing, and the owner's sound library is original (licence concern withdrawn).

## Third document: the multi-game programme prompt (`/root/agent-notes/cyrus-games-programme-prompt.md`)
That prompt covers **breadth** (finish Minecraft, Rust, Terraria, Valheim, Zomboid, Palworld). The Master Plan covers **reliability**, and this research plan covers **Minecraft depth and assets**. They overlap in places and disagree in a few. How they combine:

**Overlaps (one piece of work, three names)**
- 26.x: prompt 5.1 (JDK 25 + Gradle 9.x image, `sheets/26.2.md`, eval on 26.2) = Master Plan CYR-025 = research Step 1. One ticket, the research only verifies and sizes it.
- Resource-pack delivery + OGG sound generation: prompt P6/5.1 (Nxeon hosts the pack, sets `resource-pack` + sha1; WAV then encode on the build host) already makes the same design call we reached. Research Steps 5-6 verify the details; they do not re-decide it.
- Benchmark: **an eval harness already exists** (`eval/run_eval.py`, `rtcheck.py`, 28 prompts, 28/28 built, 13/13 jars loaded on v6). Master Plan CYR-010 should EXTEND it, not build a new one. Step 2 must inventory it.
- Pattern library (`feature/cyrus-v6-library`, unmerged) = Master Plan retrieval/"verified recipes" idea. Treat it as the starting point for Step 7; its pending A/B (library off vs on) is the evidence.
- "Not live until a real toolchain + real files + scan + install + lifecycle + load test" (prompt's 8-point definition of done) = Master Plan maturity ladder (template -> compile-tested -> runtime-tested -> production-supported). Use ONE ladder; the 8 points are the exit criteria.

**Conflicts, with a recommendation**
- *Breadth vs depth.* The owner's stated goal now is Minecraft first and best. Recommendation: Minecraft depth (launch gates, manifest, 26.x, assets, content types) before the other five games. The prompt's "week-zero P1 multi-language worker refactor" touches the Minecraft path, so do it AFTER Minecraft is stable, not before.
- *Design for games later.* Whatever is built now (project manifest, asset manifest, version registry, worker profile interface) must be **game-agnostic** so the other games plug in later without a rewrite. This is also the Texture/Sound plan's `GameAdapter` idea.
- *Parallel agents.* The prompt assumes one agent per game in parallel. Today's instruction (usage limit) is sequential, one at a time. Keep sequential until the owner says otherwise.
- *Stale facts in the prompt.* It says production is on `fd6bcb7e` and the scan fix is unsent; production is now `676b0176` (router fixes) and whether the scan is on VM 88001 is still unverified. The "stuck at Compiling" cause was found earlier (permissions); re-check before repeating that work.
- *Scope of "assets".* The prompt limits textures/sound to Minecraft first and says other games need their own formats (creators upload art). That matches this plan: assets are a Minecraft feature first.

**Added to the owner-decision list** (from prompt section 7, still open): reference Rust/Oxide, TShock, Valheim and Zomboid servers on node-2 for load tests; Zomboid pack zip vs Workshop; tModLoader variant priority; installing other creators' mods (Minecraft only until a month of scan data); per-game token pricing tables; AI-disclosure wording; 26.x go-ahead for the VM 88001 image change.

**Where the other games sit in the final plan:** a separate Track B after Minecraft, in the prompt's landing order (Rust, Terraria/TShock, Valheim, Zomboid validated-only, Palworld settings-only), reusing the shared `csharp-*` profile work once.

## Fourth document: the Cyrus Minecraft Feature Roadmap (owner-attached, 2026-10-09)
This one is about **what Cyrus can create** (the capability ladder), so it is the closest match to the owner's goal. Its main ideas: a **Mod Specification + Capability Router** (decide plugin vs data pack vs resource pack vs future client mod, tell the user the limits, and plan before spending tokens), a **Data Pack Studio** (recipes, loot, advancements, tags, functions, worldgen), a full **asset pipeline** (textures, models, sounds, packaging, hybrid JAR + pack delivery), **Cyrus Test Flight** (isolated real Paper server + MockBukkit + a Mineflayer-style bot, honest per-check statuses), a **visual Gameplay Designer** (item designer, ability/event graph, quests, bosses, GUIs, minigames), **server-aware context, diagnostics and a Mod Pack Builder**, and a later **Fabric client-mod** path. Its recommended next feature: Spec + Router, then Data Pack Studio.

**How it maps onto the other three documents**
- ModSpec = the Master Plan's `CyrusTaskSpec` (section 4.1) = the asset manifest we need. **One schema**, owned by one ticket, with an `artifacts` field (plugin / data pack / resource pack / client mod) and an `assets` field (models, textures, sound events). This is also where the router's decision is stored.
- Test Flight = Master Plan CYR-012/013/014 (MockBukkit, disposable Paper smoke lane, functional tests) plus the Mineflayer bot lane. Same work; the roadmap adds the bot and the honest-status table.
- Verified component library = the unmerged `feature/cyrus-v6-library` pattern library. Same work; the roadmap names the components worth having (custom-item identity, cooldowns, GUI pagination, config + migrations, boss phases, quests).
- Targeted edits + revisions = Master Plan CYR-020/023 (manifest, minimal patcher).
- Server Context / Diagnostics / Mod Pack Builder / Version Upgrade Assistant / Mod Doctor = new, later (post-launch design topics, not research steps now).
- Fabric/NeoForge client mods = new, explicitly LATER. Everything the owner listed (creatures, HUD, biomes) must first be sorted into "doable on a vanilla client" vs "needs a client mod"; that is research Step 3.

**Where its order conflicts with the owner's current priority, and the resolution**
The roadmap puts assets 5th (after Spec/Router, edits/components, Data Packs) and the Designer 6th. The owner now wants assets (creature model + textures + multiple sounds, automated, then editable) as the headline. Resolution: **Spec + Router goes first because assets need it** (the router is what decides "this request also needs a resource pack and a model", and the spec carries the asset IDs), but keep the first Router minimal: route among {plugin, plugin + resource pack, data pack} and disclose limits. Then the asset slice, then Data Pack Studio, then Test Flight growth, then the Designer. Launch gates stay ahead of all of it.

**New research needs it adds (folded into the steps below)**
- Step 3b: Data Pack Studio (per-version schemas/formats for 1.21.x and 26.x, validators and open-source generators and their licences, how Paper loads datapacks, load tests). Biomes, structures, recipes, loot, advancements land here.
- Step 3 also answers the HUD/UI question honestly: which HUD/GUI effects are vanilla-possible (boss bar/action bar, font glyph tricks, custom inventory GUIs with pack fonts, shaders) versus client-mod-only.
- Step 7 gains a Test Flight sub-question: Mineflayer and MockBukkit support for 26.x, cost of a disposable Paper server per build on the build host.
- Steps 3-4 must verify the roadmap's own claims (it is a proposal; its source links are unopened).

**Scope warning.** Together the four documents describe years of work. The plan's job is to pick the order, not to commit to all of it. Everything not on the minimal path (Designer, Server Context, Mod Pack Builder, client mods, differentiators like screenshot-to-mod and structure generator) is parked as a later design topic and gets research only when it becomes next.

## [SUPERSEDED by the two-week FULL plan below] One-week version (owner: "we can do this in a week", 2026-10-09)
Day 1 = the day weekly usage resets. A week fits ONE strong vertical slice, not all four documents. Research is done just-in-time inside each day (only the questions that day needs), not as a separate phase.

| Day | Build | Just-in-time research | Owner actions needed | Done when |
|---|---|---|---|---|
| 1 | Launch gates: confirm hardened scan is live; per-build version/scan record; launch-flag guard. 26.x decision | Step 1 (versions), Step 2 (gap audit) | Run VM 88001 update; say yes/no to the 26.x image (JDK 25 + Gradle 9) | We can prove what built each mod; 26.x scope decided |
| 2 | ModSpec + minimal Capability Router (plugin / plugin + resource pack / data pack) + asset manifest in the project record | Step 3 (what is vanilla-possible), 3b (datapacks, light) | Review the ModSpec fields | A prompt like "Glock handgun with sounds" routes to plugin + pack with limits shown |
| 3 | Texture slice: LLM-written pixel spec -> existing renderer -> validated pack; Nxeon hosts the pack and sets `resource-pack` + sha1 on the server through the Mods engine; custom item end to end | Step 6 (texture, light), pack format for the pinned version | **Test in a real Minecraft client** | Pack loads in a real client; item shows the custom texture |
| 4 | Sound slice: SoundSpec, tag the 514-file library, synth presets, server-side Ogg encode, `sounds.json`, several events per mod (fire, reload, hit, etc.) | Step 5 (sound, light) | Customer-facing sound licence text; real-client sound test | Plugin plays the right sounds in a real client |
| 5 | Creature slice (banshee): archetype rig + skin + attack/hurt/death/idle sounds. Realistic target: custom skin + full sound set on a vanilla-model mob, and display-entity model only if Step 4 research clears a library | Step 4 (models), only what Day 5 needs | Real-client check | Banshee with its own look and 4+ sounds installs and plays |
| 6 | Studio editing: open a mod's textures and sounds in the studios, edit, rebuild + re-push the pack, keep revisions; simple data-pack path (recipe/loot) | Step 7 (quality), light | Review the editing UX | Customer can change a texture or sound and see it on the server |
| 7 | Test Flight lite (disposable Paper smoke test on node-2), eval run on asset prompts, docs, release package | Step 7 sub-question: test tooling for 26.x | Approve deploy; decide flag flips | Evidence bundle; deploy block ready for the owner |

**In the week:** launch gates, Spec + Router (minimal), pack delivery, custom item (the Glock), multi-event sounds, a banshee reskin with full sounds, asset editing, data-pack basics, Test Flight lite.
**Not in the week:** visual Gameplay Designer and ability graph, quest/boss/minigame designers, custom HUD shaders, biomes and structures beyond datapack basics, Fabric/client mods, Server Context/Mod Pack Builder, the other five games, a full 3D animated creature library, 26.x beyond the Day-1 decision (unless the image change is trivial).

**What can stop it**
- **Weekly usage.** This week hit 99% on mostly diagnosis and planning. A build week of this size is heavier. Stay lean (Sonnet, no parallel agents, small steps) and the owner should check the allowance and whether extra usage is available.
- **Owner-only steps** block days: the VM 88001 update and image rebuild, deploys, flag flips, real-client tests, the sound licence text.
- **Real-client testing** cannot be done from the server; each asset day needs someone with Minecraft open.
- **Day 5 creature** depends on a model-library choice that is unresearched; if it fails the fallback is skin + sounds only.

## FOUNDATION PRINCIPLE: Minecraft work is the base for every future game (owner decision, 2026-10-09)
Everything built for Minecraft in this plan is designed as the **foundation for the other games** (Terraria, Valheim, Palworld, Rust, Zomboid and later ones). Build the platform once, validate each game separately. Rule for every ticket: *if it is not Minecraft-specific, it goes in the shared core, behind an interface; if it is, it goes in the Minecraft adapter.*

**Shared core (game-agnostic, built once)**
- Mod spec + capability router (same schema; each game declares its own routes/artifact types).
- Project manifest + revision store (asset IDs, hashes, licences, known-good revision).
- Build orchestration: queue, stream/replay, token reserve/settle, repair loop, cost metering, abuse limits.
- Scan framework (rule sets per language), eval/benchmark harness, Test Flight runner (headless server per game).
- Install lifecycle (backup, rollback, one copy only, on/off/update/remove), version registry, support-maturity ladder (template -> compile-tested -> runtime-tested -> production-supported).
- Asset system: asset manifest, validators, licence ledger, editor shells (texture, sound), non-destructive revisions.
- Product layer: NxLabs pages and badges, community/remix, diagnostics, edit planner.

**Per-game adapter (the contract each game must fill; extends `lib/cyrus/games/support.ts`)**
1. Artifact types it supports and the routes the router may choose.
2. Toolchain profile: language, compile/validate command, real game files needed, deny-list scan rules.
3. Version registry: supported versions, forced-update dates, "outdated" rule, compatibility checks.
4. Knowledge pack: API sheets, failure rules, verified component recipes.
5. Asset formats and **delivery to players** (Minecraft: server-pushed pack; Valheim: client pack zip installed by hand; Terraria TShock/Palworld: none; tModLoader: client mod) and whether the studios apply.
6. Install paths, restart/hot-reload rule, "what players must install" message.
7. Test lane (headless server) or an honest "validated, not load-tested" label.
8. Maturity level and the exit criteria to reach the next level.

**Consequences for the schedule**
- Day 1-2 produce the adapter interface and the game-agnostic spec/manifest first; Minecraft is the first implementation of it, not a special case.
- Days 3-12 are built against that interface, so Terraria/Valheim/Palworld/Rust/Zomboid (Day 13) add adapters and toolchain profiles rather than new platform code.
- The Texture and Sound Studios are shared editor shells; they only light up for a game whose adapter declares an asset format and a delivery path (full value: Minecraft; partial later: Valheim client packs, tModLoader).
- Reusable pieces get tests that do not mention Minecraft, and Minecraft behaviour must stay byte-identical when the core is refactored (eval + pipeline test are the proof).
- Success measure for the foundation: adding the next game needs only an adapter, a toolchain profile, a knowledge pack and a test lane, with no changes to the core.

## [SUPERSEDED by the 16-DAY ENGINE PLAN, next section] TWO-WEEK FULL PLAN (kept for reference)
Owner: "everything together in the plan, one week, maybe two." Scope = Master Update Plan + Texture/Sound plan + Minecraft Feature Roadmap + the multi-game programme. Day 1 = the day weekly usage resets. Research is just-in-time inside each day. Order is set by dependencies: foundation -> spec/router -> assets -> content types -> testing/versions -> ops -> other games -> client mods. Items marked (T) need a real Minecraft client; (O) need an owner action.

### Week 1 — foundation, assets, content
| Day | Stream | Build | Research (just-in-time) | Done when |
|---|---|---|---|---|
| 1 | Foundation | Verify hardened scan live on VM 88001 (O); per-build version/prompt/scan record on `ModBuild`; launch-flag guard (studio+tokens as one pair); free-build abuse limit; per-build cost cap. Start 26.x lane: JDK 25 + Gradle 9 toolchain on node-2, `sheets/26.x.md` (image change on VM 88001 is O) | Step 1 versions; Step 2 gap audit incl. `eval/` | Can prove what built every mod; flags fail closed; 26.x builds on node-2 |
| 2 | Foundation | **ModSpec + Capability Router**: one schema (plugin / data pack / resource pack / client mod routes, assets, tests, install needs); user sees and edits the plan before tokens are spent; project manifest + revision store (CYR-020) holding asset IDs, hashes, licences | Step 3 feasibility; 3b data packs | "Glock with sounds" routes to plugin + pack with limits shown; spec stored per project |
| 3 | Assets | Texture engine into the build: LLM pixel-spec -> renderer -> validated pack; item textures, block textures, GUI/particle textures; pack builder per pinned version; Nxeon hosts the pack and sets `resource-pack` + sha1 via the Mods engine; hybrid JAR + pack install and uninstall (T) | Step 6 | Custom item shows its texture in a real client |
| 4 | Assets | Sound engine: SoundSpec; tag the 514-file library; synth presets; server-side Ogg encode; `sounds.json`; many events per item/mob/boss (fire, reload, hit, ambient, hurt, death, step); sound licence ledger (O: customer licence text) (T) | Step 5 | Right sounds play for each event in a real client |
| 5 | Assets | Models + creatures: archetype RigSpec (humanoid, quadruped, flyer/ghost), skin UV, procedural animations, display-entity/model library chosen from research; banshee end to end (model, skin, idle/walk/attack/hurt/death sounds); 3D item models (the Glock) (T) | Step 4 | Banshee installs, looks custom, plays sounds, hurts players |
| 6 | Assets | Texture Studio + Sound Studio UIs: open any mod's assets, edit (pixel tools, palettes, layers/undo; waveform, trim/fade/layer), AI edits as non-destructive candidates, revisions, rebuild + re-push the pack, validation report, license manifest (T) | Step 6/5 follow-ups | Customer edits a banshee texture or sound and sees it on the server |
| 7 | Content | **Data Pack Studio** (recipes, loot, advancements, tags, functions, biomes, structures, worldgen where supported) with per-version schemas + load test; import/edit/export | Step 3b | Valid datapack loads on every listed version |

### Week 2 — designers, testing, ops, other games, client mods
| Day | Stream | Build | Research (just-in-time) | Done when |
|---|---|---|---|---|
| 8 | Content | **Gameplay Designer 1**: Custom Item Designer, ability/event graph (typed triggers -> conditions -> actions, compiled to validated Java/data, no arbitrary scripts), verified component library (identity, cooldowns, config + migrations, safe listeners) | Step 7 | Edit cooldown/range/sound without regenerating the whole mod |
| 9 | Content | **Gameplay Designer 2**: GUI designer, quests/NPCs, bosses/encounters (phases, adds, arena), progression, particles/effects, world events, minigames; HUD/UI via vanilla means (boss bar, action bar, font glyphs, pack fonts, shaders) with honest limits | Step 3 follow-up | Each designer produces a working, testable example |
| 10 | Testing | **Test Flight**: MockBukkit, disposable Paper server smoke + functional tests, Mineflayer-style bot scenarios, performance scenarios, honest per-check status table; repair loop fed by runtime failures; targeted edits + diff + regression gate | Step 7 test tooling | No "success" without evidence; edits don't break unrelated features |
| 11 | Versions | Version registry + support matrix: 1.21.1/.4/.8/.11 + 26.x + older popular (1.20.x) per research; ViaVersion decision; version upgrade assistant; per-version pack formats + datapack schemas | Step 1 follow-ups | Each version has a tested status, not a dropdown entry |
| 12 | Ops/AI | Server Context (opt-in), integration profiles, pre-install report, Cyrus Diagnostics (approval-gated), Mod Pack Builder with combined tests, versioned community projects on NxLabs, Explain This Mod, Mod Doctor, performance/exploit audit; screenshot-to-mod, structure generator, simulation + balance assistant | as needed | Each feature reachable in the studio behind its flag |
| 13 | Other games | Worker-profile refactor (game-agnostic orchestrator) then Track B in landing order: Rust (Oxide), Terraria (TShock), Valheim (BepInEx), Zomboid (validated-only), Palworld (settings-only), per the multi-game prompt's per-game plans and 8-point done list | per-game notes | Each game's first working target meets its stated acceptance; no game flips to live without evidence |
| 14 | Client mods + release | Narrow **Fabric** client-mod pipeline (compile, load, package, GameTest) as a separate target; full eval + benchmark on all new prompt classes; docs; deploy block; flag plan (O) | Fabric docs | Reproducible Fabric hello-feature; evidence bundle for the owner |

**Gates that apply every day:** tsc clean, new tests pass on node-2, nothing "live" that is not built, no production deploy or flag flip without the owner, `docs/DOCUMENTATION.md` updated, board cards moved.
**Owner actions to line up before Day 1:** VM 88001 update + image rebuild (JDK 25/Gradle 9), the sound licence text, a person with Minecraft (and later Fabric) for real-client tests, deploy approvals, answers to the open decisions below, and the weekly-usage plan (this scope needs the allowance confirmed or extra usage enabled).
**What compresses least:** real-client testing, owner-only steps, and anything needing a human to judge look and sound. If a day slips, the rule is to finish the dependency chain first (foundation -> spec/router -> assets) and slide the later streams, not skip the gates.

## 16-DAY ENGINE PLAN (supersedes the two-week table; adds the owner's 2026-10-09 additions)
Day 1 = the day weekly usage resets. (T) = needs a real Minecraft client, (O) = needs an owner action. Added to the old plan: asset libraries + plan-tier gating, hosting off the primary, multi-pack merge, pricing, quality bar, Bedrock honesty, conflict engine, Mod Packs, bring-your-own-mod. This is about 3 days longer than the 14-day version; the engine framing (project model, registries, generators) is built on Days 1-3, which is what makes the later days fast.

### Week 1: engine core, assets, content
| Day | Build | Notes / acceptance |
|---|---|---|
| 1 | **Foundation + launch gates:** verify hardened scan live (O); per-build version/prompt/scan record; paired launch-flag guard; free-build abuse limit; per-build cost cap. **Delivery decisions:** pack hosting on object storage/CDN, NOT the primary (size cap, immutable versioned URLs, sha1, bandwidth cost per player join); **pricing model draft** (per-feature token costs, plan-tier gating table above, margins from measured cost). 26.x toolchain on node-2 | Can prove what built each mod; hosting + pricing decided; 26.x builds on node-2 |
| 2 | **Engine core:** mod project model + revision store; ModSpec/IR; **registries** (capability, version, **identifier registry** incl. model IDs, sound keys, commands, permissions, recipe keys, font glyph codepoints); **Capability Router**; **GameAdapter interface**; import schema for bring-your-own-mod | Spec stored per project; router explains limits; Minecraft is adapter #1 |
| 3 | **Texture engine + Texture Library** (top plan only): LLM pixel-spec -> deterministic renderer -> validated pack; vanilla-style palette/style presets; library of presets + customer uploads; pack hosting live; hybrid JAR + pack install/uninstall; **plan-tier gate enforced server-side** (T) | Custom item shows its texture in a real client; gate verified by tests per plan |
| 4 | **Sound engine + Sound Library** (Saka and up): SoundSpec, tag the owner's 514 files, synth presets, server-side Ogg encode, `sounds.json`, many events per item/mob/boss; licence ledger; gate enforced (T) (O: customer sound licence) | Right sounds play per event in a real client; Katara/free correctly blocked |
| 5 | **Models + creatures:** archetype RigSpec, skin UV, animations, display-entity/model library chosen from research; banshee end to end; 3D item model (the Glock) (T) | Banshee installs, looks custom, plays sounds, attacks |
| 6 | **Studios UI + quality bar:** open any mod's assets, edit (pixel tools, palettes, layers/undo; waveform, trim, layer), AI edits as candidates, revisions, rebuild + re-push; library browsing inside studios; **quality bar**: vanilla-style presets, automatic checks (palette size, contrast, noise, loudness), human review gallery the owner signs off (T) | Customer edits a texture/sound and sees it on the server; owner approves 20 samples |
| 7 | **Data Pack Studio** (recipes, loot, advancements, tags, functions, biomes, structures where supported) with per-version schemas + load test | Valid datapack loads on every listed version |

### Week 2+: composition, import, designers, testing, ops, other games, client mods
| Day | Build | Notes / acceptance |
|---|---|---|
| 8 | **Conflict engine + Mod Packs.** *Static checks from jars/packs/datapacks:* plugin name, commands + aliases, permissions, depends/softdepends, api-version, registered events + priorities, namespaced keys / PDC keys, custom model / item_model IDs, recipe keys, sound event keys, **resource-pack path and `sounds.json` merges**, atlas/font glyph codepoint collisions, config file names, bossbar/team/scoreboard names. *Dynamic:* combined smoke + scenario tests on the test server. *Resolution:* namespace/prefix regeneration (Cyrus rebuilds one mod with a prefix), command alias rewrite, **multi-pack merge into one pack per server** (or additional packs where the version supports it, to be verified), priority ordering, severity report (blocking / warn / info). **Mod Pack Builder:** pick mods -> conflict report -> resolve -> compile a **versioned pack** (jars, packs, datapacks, configs, changelog, compatibility matrix, combined test report) -> install/rollback as one unit; shareable on NxLabs | Two deliberately conflicting mods are caught, resolved or blocked; the pack installs and rolls back as a unit |
| 9 | **Bring your own mod:** upload source project / jar / datapack / resource pack; rights attestation; quarantine + archive limits, no script execution at ingestion; detect framework + version; unsupported types (Forge/Fabric) say "not yet". Source projects become **revision 0**; index, run the change planner, **build with Cyrus** (compile, scan, test, version, install). Jar-only: analysis and diagnosis only, no claim of safe modification. Licence recorded; no public publishing without consent. Mod Doctor on imports | An uploaded plugin source is edited by prompt, rebuilt, scanned, tested and installed; its history is kept |
| 10 | **Gameplay Designer 1:** Custom Item Designer, ability/event graph (typed triggers -> conditions -> actions compiled to validated code, no arbitrary scripts), verified component library | Change cooldown/range/sound without regenerating the mod |
| 11 | **Gameplay Designer 2:** GUI, quests/NPCs, bosses/encounters, progression, particles/effects, world events, minigames; HUD/UI by vanilla means with honest limits | Each designer yields a working testable example |
| 12 | **Test Flight + targeted edits:** MockBukkit, disposable Paper smoke + functional tests, bot scenarios, performance scenarios, per-check status table; repair loop fed by runtime failures; diff + regression gate | No "success" without evidence; edits don't break unrelated features |
| 13 | **Versions + Bedrock honesty:** version registry + support matrix (1.21.x, 26.x, older popular per research); upgrade assistant; **Geyser/Floodgate detection** in Server Context; studio and NxLabs labels "custom assets not visible to Bedrock players" unless a verified conversion exists (research item) | Each version has a tested status; Bedrock warning shown where relevant |
| 14 | **Ops/AI extras:** Server Context, integration profiles, pre-install report, Diagnostics (approval-gated), versioned community projects, Explain This Mod, screenshot-to-mod, structure generator, simulation + balance assistant, performance/exploit audit | Each reachable behind its flag |
| 15 | **Other games (Track B):** worker-profile refactor, then Rust, Terraria/TShock, Valheim, Zomboid (validated-only), Palworld (settings-only) as adapters | No game flips live without evidence |
| 16 | **Fabric client-mod pipeline (narrow), full eval/benchmark, docs, deploy block, flag plan (O)** | Reproducible Fabric hello-feature; evidence bundle |

**Gates every day:** tsc clean, tests pass on node-2, nothing called live that is not built, plan-tier gates verified server-side, no production deploy or flag flip without the owner, `docs/DOCUMENTATION.md` updated, board cards moved.
**Owner actions to line up before Day 1:** VM 88001 update + image rebuild (JDK 25/Gradle 9); sound licence text; Minecraft client person for (T) days; object-storage/CDN choice for packs; deploy approvals; weekly-usage allowance (this scope needs it confirmed or extra usage on).

## The steps (ordered by value and by how much they unblock)

| # | Step | Key questions | Sources | Output | Size |
|---|------|---------------|---------|--------|------|
| 1 | **26.x / version matrix** | Which Paper builds exist for 26.1-26.3; Java requirement; `api-version` rules; what API changed vs 1.21.11; pack format numbers per version; item-model/data-component changes; is ViaVersion worth it | Paper docs + release notes, Minecraft release notes, bStats/Paper stats | `E-versions.md` + proposed support registry | S |
| 2 | **Internal gap audit** | Exactly what exists and where an asset manifest plugs in: build request, workspace, packaging, install, DB tables, NxLabs generator; can the Mods engine also deliver a pack and set the server.properties lines; what the texture/pack code really does | Our code only (no web) | `G-gaps.md` with file:line refs | M |
| 3 | **Content feasibility matrix** | Per content type (mob, item, block, biome/structure, HUD/GUI, particles, enchantments, recipes, bosses): technique, what needs a client mod, version sensitivity, which an AI can generate reliably | Paper/Minecraft docs, repos of BetterModel, Oraxen, Nexo, CraftEngine, MythicMobs (licences!) | `A-content.md` + ranked build order | M |
| 3b | **Data Pack Studio** | Datapack formats per version (1.21.x, 26.x); recipes/loot/advancements/tags/functions/worldgen schemas; validators and open-source generators + licences; how Paper loads and reloads datapacks; how to load-test one | Minecraft/Paper docs, misode generators and schema repos (licences), Fabric datagen docs | `A2-datapacks.md` | S-M |
| 4 | **Creature model pipeline** (banshee) | Rig/cuboid model + animations on a vanilla client; display-entity libraries and their licences; LLM-generated RigSpec; archetypes; limits | BetterModel/ModelEngine docs, Blockbench format docs | `B-models.md` + candidate RigSpec schema | M |
| 5 | **Sound Studio** | `sounds.json` per version; full mob sound set; Ogg Vorbis encoding (server-side vs wasm, licences); editing libraries; auto sound design from the owner's library; SoundSpec schema | Minecraft wiki/docs, ffmpeg/libvorbis licences, wavesurfer/Tone/jsfx | `D-sound.md` | M |
| 6 | **Texture Studio** | Embeddable editors and licences; LLM-authored pixel spec vs image models (cost, terms, quality); style consistency across a mod's assets; UV/skin layouts; validation | Repos + licences, image-model terms | `C-texture.md` | M |
| 7 | **AI quality + competitors** | Best techniques for correct generated plugins (spec first, recipes, MockBukkit, headless Paper + bot tests, retrieval, caching); who else does this and what users complain about | Anthropic engineering docs, competitor sites, forums | `F-quality-market.md` | M |

## Order and stopping points
Run **1 then 2** first: they are cheap and decide most of the plan (can we even build for the fleet; what is the real integration surface).
After that run **3 -> 4 -> 5 -> 6 -> 7**. Checkpoint after each: owner reads the file, says continue or redirect.
If usage is tight, the minimum that still produces a useful plan is **1, 2, 3**.

## Final deliverable (after the steps)
`MASTER-PLAN.md`: phased roadmap with effort sizes, the asset-manifest design that ties texture/model/sound to a mod, the version-support registry, build/buy/avoid list with licences, acceptance tests, risks, and a "do first" list. Written by me, from the step files only (no new research).

## Decisions the owner will be asked for (collect as we go)
- Which image provider, if any, for AI textures (or use LLM-authored pixel specs only for MVP).
- Customer-facing licence for the sound library.
- Which versions to support first (data above says: 26.x first, then 1.21.11 stays).
- Whether HUD/UI and biomes are in the first release or later.

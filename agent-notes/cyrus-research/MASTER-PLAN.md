# Cyrus Master Plan: the ultimate game-mod creation studio (Minecraft first)

Date: 2026-10-10. Owner direction: build the ultimate mod creation studio; launch is months away; other concerns later. Sources: the four owner documents (Master Update Plan, Texture & Sound plan, Minecraft Feature Roadmap, multi-game prompt), research files E, G, A, A2, B, C, D, F, and the red-team review GAPS-AND-IDEAS.md, all in `/root/agent-notes/cyrus-research/`. Research claims are labelled VERIFIED or UNVERIFIED in those files; this plan inherits their labels and adds none of its own. Sizes are S/M/L effort.

## 1. What we are building
A real game-mod **engine**, not a prompt box. The source of truth is a typed, versioned **mod project**; the AI is the author and editor inside it; deterministic generators, validators and a real-server test harness turn the project into artifacts; studios and designers edit the same project; mods compose into Mod Packs; users can bring their own mods. Minecraft is adapter #1 on a game-agnostic core.

**Principles**
1. Engine first: every feature must be typed, validated, testable, editable and composable. A prompt wrapper is not a feature.
2. Evidence over claims: no status ("built", "tested", "supported") that did not actually run. Compile, scan, boot test and functional test are separate checks.
3. Foundation for other games: shared core behind interfaces; per-game adapters (Section 4.10).
4. Honest about limits: the router tells users what a vanilla client can and cannot do.
5. Dependencies decide order, not enthusiasm (the review found five dependency inversions in the first schedule; this plan fixes them).

## 2. Decisions already made by the owner
- Plan tiers: Free and Katara get no studios; **Saka gets Sound Studio + Sound Library; the top plan (`all`, includes Yakko) gets everything** including Texture Studio + Texture Library. Tiers are cumulative.
- **Automatic asset generation follows the user's plan and access** (same gate whether Cyrus, the studio or a library creates the asset).
- **Mod Packs are not gated by plan. Importing your own mod to work on it is not gated by plan.**
- Asset libraries and studios are top priorities; the owner's 514-file sound library is the Sound Library seed.
- Everything in scope, ambitious timeline; launch is months away. Research ran as limited Sonnet agents; no parallel agent sprawl.
- Parked by the owner ("later"): Mojang EULA / marketplace question, other-platform AI policies (Modrinth etc.), licence review of dependencies. Not worked in this plan.

**Defaults I set (change any of them):**
- Gate semantics: gates apply to **creating or editing** assets. Installing, keeping, rebuilding unchanged and exporting existing project assets is never gated. The router downgrades (no custom asset) instead of erroring, and gating fails closed when token state is unknown.
- Banshee on 1.21.x = custom skin + full sound set on a vanilla-model mob; **animated custom-model creatures are 26.x first** (BetterModel v3 needs Java 25).
- Generated mods stay on `plugin.yml` (Paper's `paper-plugin.yml` is still experimental).
- Gameplay Designers, full creature pipeline and worldgen come after the foundation, assets and composition (they are mini-languages each).

## 2b. Built to stand alone later (owner decision, 2026-10-10)
Cyrus stays a part of Nxeon for at least the next few months (to build a solid foundation and gather months of real Nxeon-customer usage data), then may become its own product. So:
- **Nothing breaks and nothing changes for customers:** same sign-in, same accounts, same wallet, same billing. No separate Cyrus login now.
- **Design for the split from day one (cheap now, expensive later):** Cyrus code reaches Nxeon only through a small **host seam** (sign-in/user, plan and billing, server access for install, storage, notifications). New code must not add new direct imports of Nxeon internals; where one is unavoidable it goes behind a named adapter. Cyrus tables stay Cyrus-prefixed with opaque ids for users/servers (no new foreign keys into Nxeon tables). The build service already stands alone; the engine core, asset pipelines, Test Flight and pack hosting already live under `lib/cyrus/` and stay game- and host-agnostic.
- **Later, when separating:** Nxeon implements the host side as an API (list servers, push plugin/pack/config, restart); a standalone Cyrus gets its own sign-in, wallet and billing, own database, and a standalone export (jar and pack download). The Kodely-to-Nxeon partner API is the existing pattern.
- **Not now:** no code that exists only to prepare the split beyond the seam rule and a coupling map.

## 3. Reality check on the facts (from the research)
- Cyrus builds only 1.21.1/1.21.4/1.21.8/1.21.11 on JDK 21. Compile is plain `javac --release 21 -proc:none` against a Paper-only classpath (Gradle only builds classpath files). 4 of 6 explicitly versioned Paper servers on Nxeon already run 26.x, so version support is a top lever. 26.x needs Java 25. **Correction (checked on Paper's Fill API and Maven, 2026-10-10):** stable builds exist only for 26.1.2 (build 74) and 26.2 (build 133); 26.3 has only alpha/beta builds, so the version research was wrong that 26.3 is stable. The 26.x lane starts with **26.2**, then 26.1.2; 26.3 stays preview and unpinned until Paper ships a stable build. The registry now holds the exact pins and server-jar hashes.
- No ModSpec, project/revision store, asset manifest or import flow exist. A "project" is a chain of `ModBuild` rows. `textures/` does item textures only; `sfx.ts` is interface sounds only. The Mods installer treats resource packs as unsupported. `packFormatFor` is wrong for 26.x (returns 75; 26.1 is 76-84). Plan tiers gate models only; the single gate is `gateBuild` at `create.ts:72`, bypassed when tokens are off.
- `server.properties` holds one resource pack; Paper's `Player#addResourcePack(UUID, ...)` allows several and `setResourcePack` is deprecated.
- A vanilla client with a server-pushed pack plus datapack can show items, weapons, armor, food, display-entity mobs, glyph HUDs, GUIs, enchantments, recipes, advancements, bosses, abilities, commands, sounds, biomes and structures. Client-mod-only: brand-new block types, native entity models, free-form HUD widgets, custom keybinds, custom sky.
- Build service auth: it can run on a subscription login. Before ANY public launch, switch to an API key and re-measure cost (not blocking development now).
- Jars are not reproducible today (`jar --create` without `--date`).

## 4. Engine design
### 4.1 Mod project model + revisions (size L)
Typed project: `ModSpec`/content IR (items, mobs, abilities, GUIs, quests, recipes, loot, biomes...), code files, assets, datapacks, config, dependencies, tests, requirement IDs. Stored as immutable revisions with diffs; each revision traces to exact inputs and toolchain; the last passing revision is always preserved. `schemaVersion` with explicit migrations; JSON Schema as the portable contract, Zod types in code. New tables (project, revision, asset, namespace) need an owner-approved DB migration deploy. Chat history is not the project.

### 4.2 Registries and reserved namespaces (S-M)
Capability registry, **version registry**, **identifier registry**, asset registry with provenance. Each project reserves a namespace `nx_<hash>` at creation so IDs, keys, permissions, sound keys, glyph ranges and model paths are collision-free by construction. Version registry holds exact pack format per version (one `pack.mcmeta` style per version family), JDK, classpath hash, capability flags (item model definitions from 1.21.4; Dialog API 1.21.7+; Folia support), status (`preview/supported/deprecated/blocked`). Contract-tested against Paper's Fill API.

### 4.3 Capability router + task spec (M)
After the prompt check: classify what the request needs (plugin / plugin + resource pack / datapack / future client mod), disclose limits, show an editable plan and acceptance criteria before tokens are spent. One schema: this is the Master Plan's `CyrusTaskSpec`, the Roadmap's Mod Specification and the asset manifest. Tier gate is applied here and again inside the build service request.

### 4.4 Generators, build and reproducibility (M)
Deterministic generators emit code/data/packs for common mechanics from the IR; free-form AI code is the fallback. Build: `javac` per version lane (JDK 21 and JDK 25 side by side, per-version `--release`, classpath files fetched by checksum, exact stable pin), scan, package. Make jars byte-stable (`jar --date`, sorted inputs); record **engine release id** (prompt version + sheets + rules + scanner hash + image digest), source/classpath/output hashes, scan report and SBOM per artifact. Rename CYR-004 to "immutable javac/classpath/template".

### 4.5 Managed plugins, Pack Loader, pack hosting (M)
- **ManagedPlugin** records: pinned version per Minecraft family, installed on first dependent mod, ref-counted, not user-removable while depended on. Hosts the Pack Loader and BetterModel.
- **Nxeon Pack Loader**: sends N packs by UUID with `addResourcePack`, per-pack required/optional, accept-rate telemetry, Geyser/Floodgate detection. `server.properties` only as fallback. Conflict engine detects an existing pack owner (ResourcePackManager, Oraxen, Nexo).
- **Pack hosting**: object storage on an Nxeon domain (provider not named to customers), content-addressed immutable URLs `/p/<sha1>.zip`, size caps, retention GC; keep it off the primary node.

### 4.6 Test Flight (M, lite first)
Disposable Paper server per target version on node-2 (MEASURED 2026-10-10 with Test Flight lite: 26.x 10.4-10.8 s boot, 722-803 MB peak RSS; 1.21.11 on JDK 21 18.0 s, 878 MB; whole flight 12-20 s; see docs "Cyrus Test Flight (R0)"): boot, plugin enabled, RCON commands, `datapack list`, log matcher, clean shutdown. Later: MockBukkit logic tests, Mineflayer scenario bots (MIT, supports through 26.1), performance scenarios. Honest per-check status table; no "success" if a required stage was skipped. Concurrency capped (a past node crash came from parallel builds).

### 4.7 Asset pipeline and studios
Shared studio core + per-game profile. Minecraft = pixel profile.
- **Texture** (top plan): LLM writes a pixel spec (palette + shapes), deterministic renderer draws it (raise the 400-op / 16-64 px limits for skins and larger atlases), optional pixel-model candidates later; per-mod **Style DNA** (palette ramps, outline rule, noise) for consistency; per-version validation; AI edits arrive as non-destructive candidates.
- **Sound** (Saka+): `SoundSpec` (events -> layers -> processing); tag the 514-file library by filename category; synthesis presets; processing in the browser from WAV, **server-side ffmpeg/libvorbis to mono Ogg Vorbis**; new namespaced sound keys played by the plugin (and silence the vanilla base mob; never override vanilla keys globally); mandatory subtitle keys. A complete mob set: ambient, hurt, death, step, attack, ability, spawn.
- **Models** (26.x first): `RigSpec` compiled by Nxeon code (3 archetypes, 5 procedural clips) to .bbmodel for **BetterModel** (MIT, pinned managed plugin). Handgun and similar items use static item models with display transforms, sounds and particles, no engine. Do not embed Blockbench (GPL app); do not depend on ModelEngine/FreeMinecraftModels/CraftEngine.
- **Quality bar**: rubric + metrics (texture palette size, contrast, edge density, banding, transparent policy; sound mono, true peak, loudness band per role, silence ratio) plus a vision-model judge calibrated on 100 owner-labelled samples; owner reviews a gallery.
- **Studios**: v1 minimal (miniPaint MIT stopgap or a small pixel editor; wavesurfer.js BSD waveform with trim/fade/layer and JSON edit recipes), then the full editors in R3. Library browsing follows the studio gate.

### 4.8 Conflict engine and Mod Packs (L)
- **Server inventory** first: read-only scan of jars' descriptors, `server.properties`, datapacks, existing pack owners. This is the conflict engine's input (and the "Server Doctor" feature below).
- **Static classes**: plugin names, commands/aliases (incl. Brigadier root literals and vanilla overrides), permissions, depend/softdepend/loadbefore DAG, api-version/Java/Folia, registered events + priorities, NamespacedKey/PDC keys, legacy `custom_model_data` integers and `item_model` keys, recipe keys, sound event keys, single-owner resources (Vault economy/permission provider, chat renderer, tab list, sidebar, world rules), datapack `replace:true` tags and double-overridden vanilla ids, resource-pack whole-file overrides, `sounds.json`/atlas/lang merges, font codepoint overlap, unmergeable shaders, budget classes (display entities, tasks, pack size).
- **Resolution**: reserved namespaces prevent most clashes; command alias rewrites; priority ordering; Pack Loader stacking; evaluate Weld/Beet (MIT) as an offline merge subprocess behind golden tests. Severity report: blocking / warn / info.
- **Dynamic**: one combined boot and one differential boot per changed mod; pairwise only for statically flagged pairs.
- **Mod Pack**: an Nxeon manifest shaped like mrpack (files with path/sha1/sha512/downloads/env, override dirs, platform=paper). Third-party jars by URL + hash, only Cyrus-built artifacts embedded. Versioned, changelog, compatibility matrix, combined test report; installs and rolls back as one unit; never contains Paper/vanilla jars. Not gated by plan.

### 4.9 Import your own mod (L)
Source-only first: copy `src/main/java|resources`, drop and ignore the uploader's build files (their build is never run), compile with the service template and a **curated checksum-pinned dependency allowlist** (also the basis for first-class integrations: Vault, LuckPerms, PlaceholderAPI as soft bridge). Unsupported: Kotlin, Lombok, annotation processors. Ingestion limits (zip-slip, zip bomb ratio, nested jars, multi-release, class major), no execution at ingestion, ownership attestation record, detected licence, public sharing only with consent. Two scan profiles: strict for generated, **attested/imported** with warnings and no "safe" claim. Imported source becomes revision 0 and uses the same change planner, tests, versions and install path. Jar-only imports are analysis and diagnosis only (decompile for navigation, never into shared knowledge). Not gated by plan; model use and assets follow tokens and the asset gates.

### 4.10 Per-game adapter contract (S, define in R0)
Artifact types and routes; toolchain profile and deny-list scan; version registry; knowledge pack; asset formats and **delivery** (Minecraft: server-pushed pack; Valheim: client zip; Terraria/Palworld: none; tModLoader: client mod); install rules; test lane; maturity level. Add `game` to every id and registry. Texture/Sound studios light up only where the adapter declares an asset format and delivery path. A realistic 3D/PBR profile is a later track; build only the interfaces now.

### 4.11 Data packs (M)
Typed spec -> per-version emitters (the AI never hand-writes JSON); schema source vanilla-mcdoc (MIT); static validation then boot a real headless Paper and test over RCON. MVP: recipes, loot, advancements, tags, functions, enchantments. Worldgen (biomes, structures, dimensions) later; `/reload` does not reload worldgen, so those changes need a restart.

## 5. Roadmap (ordered by dependency)
Calendar note: the review estimated R0-R2 at about 5-7 weeks including owner waits (UNVERIFIED judgement). The owner has beaten estimates; treat these as sequencing and relative size, not promises. (T) = real Minecraft client needed, (O) = owner action.

### R0 Foundation (about 4 working days)
| Day | Deliver | Done when |
|---|---|---|
| 1 | Launch gates (verify hardened scan live (O), per-build engine-release record, paired flag guard, free-build abuse limit, per-build cost cap). Version registry with exact pack formats; fix `packFormatFor`; reproducible jars; JDK 25 beside 21 on node-2; classpath files by checksum; pin exact stable 26.x; nightly Fill check creates a "preview" row | Can prove what built every mod; 26.x compiles on node-2; pack numbers verified |
| 2 | Project model + revision store (DB migration (O)), ModSpec/IR, identifier registry + reserved namespaces, GameAdapter interface, minimal capability router, server-side tier gate (fail closed) | Spec stored per project; router explains limits; gate matrix test (4 plans x create/edit/keep/install) passes |
| 3 | ManagedPlugin mechanism, pack hosting (object storage + domain (O)), Pack Loader, **Test Flight lite** | A pack reaches a test server through the Pack Loader; boot gate runs on every build |
| 4 | Server inventory (read-only); eval harness extended (100+ prompts, per-version matrix, asset prompts) | Inventory report on a real server; baseline pass rate recorded per version |

### R1 Assets (about 5 days)
| Day | Deliver | Done when |
|---|---|---|
| 5 | Texture slice: spec -> renderer -> validated pack; Style DNA; library of vanilla-style presets + uploads; hybrid JAR + pack install/uninstall (T) | Custom item shows its texture in a real client |
| 6 | Sound slice: tag library, synth presets, server-side mono Ogg, `sounds.json`, subtitles, multi-event per item/mob (T) | Right sounds play per event in a real client; Katara/free correctly blocked |
| 7 | Static 3D item models (the Glock) with display transforms, sounds, particles; vanilla-mob reskin + full sound set (banshee on 1.21.x) (T) | Glock and a banshee skin + sounds install and play |
| 8 | Studios v1: open a mod's assets, edit, re-push pack, revisions, library browsing, quality rubric + gallery (T) | Customer edits a texture/sound and sees it on the server; owner approves the gallery |
| 9 | Hardening: access test matrix, cost estimates per asset op, asset cost caps (2 critique rounds), caching by spec hash | Asset ops priced by measured work; no free bypass |

### R1b Full Texture and Sound Studios (owner priority, added 2026-10-10; Opus for the editor cores)
Moved forward from R3: the studios are a top priority, so the full editors come right after the first asset slice and before composition.
- **Texture Studio (top plan):** full pixel editor (layers, undo/redo, palettes and ramps, selection, tiling and 3D item preview, onion-skin for animated textures), library browsing and search, Style DNA applied across a whole mod, AI edits as non-destructive candidates with before/after diffs, reference-image-to-spec through a vision model, asset history, the quality rubric as a real review screen.
- **Sound Studio (Saka and up):** full waveform editor (zoom, regions, trim, fade, gain, pitch/time, layering, spectrum, loudness and true-peak readouts), library browsing and search by tag, synthesis presets, per-event mob/item sound sets, subtitle keys, non-destructive edit recipes, server-side Ogg export, asset history with waveform diffs.
- **Both:** shared studio core with per-game profiles (Minecraft pixel profile first); plan-tier gates enforced server-side; library follows the studio gate.
- **Done when:** a customer builds a complete set (e.g. banshee skin plus attack/hurt/death sounds) entirely in the studios without touching a prompt, and a real client shows and plays it (T).
- R3 keeps only animated creatures, gameplay designers and playtest scripts.

### Item model states and display contexts (owner question, 2026-10-10; queued after Studio UI part 1)
Today the pack builder emits ONE flat model per texture (handheld parent): one look, no states. Owner needs: how an item looks dropped, in an inventory slot, in first-person and third-person hand, on the head, in an item frame; and stateful items (a bow idle vs pulled back; a gun aiming/reloading).
- **ItemModelSpec v1** (new, in the asset spec): per-context display transforms (gui, ground, fixed/item frame, first/third person right+left hand, head) with per-category defaults (sword, tool, bow, gun, wand, shield) the owner/studio can override; named STATES each with a model/texture and the condition that selects it.
- **Mechanism (1.21.4+ item model definitions; names UNVERIFIED, must be checked against the docs and real servers before building):** `condition` on using_item, `range_dispatch` on use_duration/pull for pull stages, `select` on display_context, and plugin-set custom_model_data flags/strings (e.g. reloading, aiming); a custom bow is built on real bow behaviour with our item_model; a custom gun uses a consumable-style 'using' state for aiming and plugin flags for reload/cooldown. Limits: no free-form animation (texture frame animation via .mcmeta and fast model switching only; no real recoil). 1.21.1 needs the legacy predicate/custom-model-data overrides path (later).
- **Generator:** emits items/<name>.json (definition with conditions/range/select), one model JSON per state with its display block, and tests with golden hashes; the build prompt tells the plugin which states exist and the flag keys; registry capability checked per version.
- **Studio:** context switcher (hotbar, dropped, first-person, third-person, item frame, head) and a STATE scrubber (idle, pull 1-3, aim, reload) in the preview; correct 'in hand' placement (the grip in the hand: the first fix already requested of the Studio UI agent).
- **Later:** true 3D cuboid item models (the model pipeline) for guns/bows that should not be extruded sprites.

### Asset Library (owner requirement, 2026-10-10): one proper, cataloged, searchable library for sounds AND textures
The owner wants every asset cataloged and organized, not just filename-tagged. Shared design for both libraries:
- **Taxonomy as data** (committed JSON, not code): primary category, multi-valued **use cases** (where a mod uses it), free tags, descriptors derived from measured data (sound: duration class, intensity, pitch band, loopable heuristic, channels; texture: size, palette ramp, transparency, tileable, style), synonym table, and a licence/provenance ledger per asset (never asserting originality that has not been documented).
- **Sound categories:** Weapons (gunshot, reload, cocking, ricochet, melee swing, clash, bow), Creatures & Voices, Impacts & Destruction, Movement, Environment & Ambience, Doors & Mechanisms, UI & Alerts, Crowd & Reactions. **Use cases:** weapon_fire, weapon_reload, weapon_impact, melee, mob_ambient/hurt/death/attack/step, ability_cast, magic, boss_event, ui_notification, pickup_reward, block_interaction, door_mechanism, ambience_world, weather, explosion (gunshot + reload are both also tagged `weapon`).
- **Texture categories:** Items (weapon, tool, armor, food, potion, misc), Blocks (stone, wood, ore, plant, glass, decorative), Entity skins (humanoid, quadruped, flyer, ghost), GUI (button, panel, icon, HUD piece), Particles, and **Style DNA presets** (palette ramps, outline rule, noise level); sources: Cyrus-authored original template specs, the customer's uploads, textures from the customer's own projects, later community-shared; every texture carries provenance + licence status and passes the quality bar.
- **Search (both):** free text with synonym expansion and ranking (exact tag > category > name words), facets/filters, pagination, "similar to"; Postgres full-text first, embeddings only later; library browsing follows the studio plan gate (sound = Saka and up, texture = top plan).
- **Builds now (R1, by the sound agent):** the sound library manifest + taxonomy + search API + a human catalog report for the owner to review. **Next:** the texture library (starter template specs authored as DSL, quality-checked) and a **unified catalog layer** (`lib/cyrus/library`) that serves sounds, textures and later models through one interface, with customer uploads stored as Cyrus-prefixed records; then the browse/search UI inside the studios (design mockups in progress).




### Motion, Animation and Effects: FOUNDATION (owner decision, 2026-10-10)
Owner: motion/animation/effects is foundational and NOT Minecraft-only: AI (or a human) creates the motion a mod needs (banshee walk cycle, gun cock/fire/reload, car driving with doors opening and a character getting in, explosions, fire, water), with LIVE playable simulation in the studio, tied to the Texture and Sound studios; per-game specifics are handled in adapters when each game is added, but the foundation exists now.
State today: pieces only. Have: `spawn_particles` in the designer (budgeted), creature clips (BetterModel), item model states (bow pull, gun aim/reload), Model Studio layer 2 pose/animation timeline (in build; told to keep it game-neutral and extensible), sound library, catalog. Missing: the game-neutral Motion core.
- **Motion core (proposal):** tracks with typed kinds (transform, particle, sound-cue, light/material, event/state-machine), clips, triggers from the ability graph (`play_effect`), deterministic sampler, playback clock API (viewport exposes it), simulator contract, per-game exporter/adapter contract, presets in the catalog as kind `effect`/`motion`, caps (entities, particles, duration).
- **First slice that proves it end to end:** gun fire/reload state machine + a door hinge in Minecraft display entities, with sound cues from the library and a muzzle-flash particle preset.
- **Steps:** (1) Sonnet research R-motion-effects.md (running), (2) Opus architecture + design + mockups, (3) build core + Minecraft exporter + studio timeline/preview, (4) vehicle rig + character attach: NOT a Minecraft target (owner clarified 2026-10-10); the neutral core must be able to express it, the build waits for the first vehicle-capable game (FiveM/RedM etc.), (5) other games per adapter.

### Config and Stats Studio: FOUNDATION (owner request, 2026-10-10)
Owner: manual configuration/stat editors for every kind of mod (mob speed/health/attack damage and speed, weapon fire rate/reload/ammo, ability cooldowns, shop prices, boss phases...), so nobody must prompt the AI to change a number; Cyrus must know which tunables to OFFER per mod category; stats with a visual (walk speed, attack speed, scale) reflect live in the viewport/motion simulation. Game-neutral schema, per-game exporters.
State today: only the designers have it (every number becomes a config.yml setting; `edit without regenerating`; /<plugin> params|reload; `planDesignEdit` exposed but NOT wired); plain AI plugins are only told to 'put tunable values in config.yml'; imported mods have their own config.yml; no studio form editor; no category-aware tunable templates.
Plan: ConfigSpec (typed params, units, safe ranges, applies live/reload/restart, visual links), category templates (mob, melee, gun, armor, ability, boss, shop, quest, minigame, world, item, utility), the AI declares tunables and the build verifies they are read, values-only revisions delivered through the delivery orchestrator (no model, no build), schema inference for imported mods, presets, Config page in the studio shell. Agent launched (Opus, branch feature/cyrus-r23-config). Owner decision: ungated (editing numbers is not asset creation), recommended.

### R2 Composition, data packs, import (about 7 days)
| Day | Deliver | Done when |
|---|---|---|
| 10-11 | Static conflict engine on the inventory; severity report; reserved-namespace behaviour; mutation corpus (take a good mod, collide IDs) | Seeded conflicts caught with the right class and severity |
| 12 | Mod Pack Builder: manifest, merge (Weld/Beet evaluation), combined boot + differential boots, install/rollback as one unit | Two conflicting mods are caught, resolved or blocked; pack installs and rolls back as a unit |
| 13-14 | Datapack MVP: typed emitters per version, mcdoc validation, boot + RCON check | Valid datapack loads on every listed version |
| 15-16 | Import (source-only): ingestion limits, allowlist, attestation, strict vs attested scan, revision 0, change planner | An uploaded simple plugin source is edited by prompt, rebuilt, scanned, tested, installed; history kept |
| 16 | Public pass-rate page + evidence badges (boot-tested on exact version, scan hash, SBOM) | Numbers come from real runs |

### R3 Creatures, full studios, designers (L; after R2 is stable)
- **26.x creature pipeline**: BetterModel managed plugin; RigSpec compiler; 3 archetypes; 5 clips; banshee end to end; hitboxes and attacks; performance budget per server (T).
- **Full Texture and Sound Studios**: layers/undo/palettes/selection/tiling preview/onion skin; waveform, spectrum, layering; reference-image-to-spec via a vision model; asset history with diffs.
- **Gameplay Designers**, one at a time: Custom Item Designer; ability/event graph (typed triggers -> conditions -> actions compiled to validated code, no arbitrary scripts) with a verified component library; then GUI, quests/NPCs, bosses, progression, minigames. Auto-generated Dialog config screens (1.21.7+).
- **Playtest scripts** from spec acceptance criteria (Mineflayer).

### R4 World and reach (L)
Biomes, structures, dimensions (restart rule); glyph HUDs with honest limits (avoid core shaders); "Try it" throwaway server link; multi-version build from one ModSpec; legacy `custom_model_data` emitter for 1.21.1; Server Doctor for servers with no Cyrus mods; mod health telemetry (opt-in).

### R5 Beyond Minecraft Java (own programmes)
Fabric client-mod pipeline (narrow); the other five games as adapters (multi-game prompt, per-game maturity ladder); realistic 3D/PBR asset profile; Bedrock conversion. Each starts only when the previous layers are stable.

## 6. Cross-cutting
- **Testing/eval**: extend the existing harness (28 prompts, 28/28 built, 13/13 loaded on v6) to 100+ prompts per version; golden pack snapshots (canonical JSON + sorted file list + sha1); property tests for merge laws (idempotent, order-stable, no key loss); javap-verified API sheets in CI; contract test of the version registry; mutation corpus for conflicts. Per-version pass rates published only when measured.
- **Quality bar**: Style DNA, rubric metrics, vision-judge calibration, owner gallery sign-off.
- **Pricing**: show an estimate before building; price assets by measured work; no charge if validation fails before delivery; per-feature reserve rows (reconcile `katara/saka/yakko` vs `katara/saka/all` naming); free tier gets no assets and per-device/IP caps.
- **Operations**: treat prompt + sheets + rules + scanner + image as one engine release with canary and auto-rollback on eval regression; per-feature kill switches (asset generation, import, packs); node-2 capacity budget for test servers; prompt-injection hygiene (imported text only as quoted data, no network for the model, path allow-list on diffs).
- **Security**: scanner remains a policy check, not proof; fail closed; import profiles warn honestly; supply-chain pinning (sha256, image digests, lockfiles).
- **Telemetry funnel**: prompt -> spec -> build -> pass -> install -> pack accepted -> player joined -> day-7 retention; gate impressions and upgrade conversion.

## 7. Risks
| Risk | Mitigation |
|---|---|
| Schedule: sizes in the research sum to roughly 25-35 engineer-weeks for the asset/composition/designer scope | Dependency-ordered phases; real-client and owner waits scheduled; creature/designers/worldgen after the foundation |
| Real-client tests (T) cannot be automated | Name a standing tester; small matrix per asset day |
| BetterModel v3/v2 split and Java 25 | Creatures 26.x first; pinned managed plugin; test before relying on 1.21.1 |
| Paper experimental APIs (paper-plugin.yml, data components) | Generated mods on plugin.yml; isolate experiments in the Nxeon-owned loader; monthly CI |
| Beta builds via floating coordinates | Pin exact stable; nightly check |
| Import hardness (dependencies, scanner bans reflection/network that legitimate plugins use) | Allowlist + attested profile; source-only first |
| Scanner false sense of safety | Honest labels; no "safe" claim for imports |
| Cost blowout from asset critique loops | Cap rounds, cache by spec hash, per-build cost cap |
| Public pass-rate claims | Publish only measured numbers per version |
| Build service auth (subscription login) | API key + re-measured pricing before ANY public launch |

## 8. Owner actions to line up
VM 88001 update and image rebuild (JDK 25 beside 21) and the hardened scan check; DB migration deploy approval (project/revision tables); object storage + domain for packs; a standing person with Minecraft for (T) days (and later Fabric); confirm or change the defaults in Section 2; weekly-usage allowance for the build weeks; API-key switch before public launch.

## 9. Open questions
1. Is the banshee-on-1.21.x default (skin + sounds) acceptable, with animated creatures on 26.x first?
2. Confirm the gate semantics default (create/edit gated; install/keep/export never).
3. Who is the standing tester and on which days?
4. Do you want Server Doctor (scan any customer server for conflicts) as an early acquisition feature?
5. Which object storage and domain for packs?

## 10. Where the details live
`E-versions.md` (version facts, registry), `G-gaps.md` (code audit with file:line), `A-content.md` and `A2-datapacks.md` (content feasibility, datapacks), `B-models.md` (creatures, RigSpec), `C-texture.md` and `D-sound.md` (studios), `F-quality-market.md` (competitors, test tooling), `GAPS-AND-IDEAS.md` (red-team findings, resources, ranked features), `RESEARCH-PLAN.md` (history, four-document reconciliation).

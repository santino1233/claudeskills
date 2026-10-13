# Advanced mods for the six Cyrus games: how professionals build them, and what Cyrus should add

Research write-up for the Cyrus v6 programme. Compiled 2026-10-08. Research only: no repo changes, no purchases, no sign-ups.

Source tags used throughout:
- **[V]** verified this session from a primary source (official docs, the project's own repo or API, a licence text).
- **[S]** secondary (hosting-provider knowledge bases, news, aggregators, search snippets). Plausible, but re-check before anyone relies on it.
- **[L]** verified locally in the Nxeon repo, the build service or the owner's handoff.
- **[I]** inference or general expert knowledge that was not checked this session.

AI reliability ratings used in each game section:
- **R1** reliable today with guardrails (templates, API sheets, compile and validate loop).
- **R2** works only with an automated verification step plus, for some requests, human review.
- **R3** needs a human (design judgement, binary tooling, or assets the AI cannot author).

---

## 1. Executive summary (one page)

**What "advanced" means.** In every game the same ladder shows up. Rung 1 is configuration and data edits. Rung 2 is scripted behaviour (commands, events, simple GUIs). Rung 3 is new content (items, mobs, recipes, quests). Rung 4 is new systems (economies, minigames, world generation, custom AI). Rung 5 is engine-level work (patching game code, custom assets, cooked packages). AI is good on rungs 1 to 3 and decent on rung 4 where the platform has a high-level API. Rung 5 is mostly a human job.

**The finding that matters most: version drift, not cleverness, is what breaks AI-written mods.**
- Cyrus's own Minecraft build service already learned this. Its reviewed failure-rule file holds 18 rules, and nearly all are API names that changed between Paper versions (`Attribute.GENERIC_*` vs unprefixed, `Material.GRASS`, boats split per wood, `EntityType.POTION` removed) [L: `services/modbuilder/rules/failure-rules.json`].
- Every other game moved under modders' feet in the last 90 days: Palworld 1.0 (2026-07-10), Terraria 1.4.5 (2026-01-27 [S]) which tModLoader does not yet ship for, Valheim 1.0 (2026-09-09, "piece categories overhauled", Jotunn rewritten for 1.0.7), Project Zomboid Build 42.20 stable (2026-07-29), Rust's monthly Thursday update. Training data for these games is mostly pre-change.
- Published evidence agrees: version-controllable code generation is "a significant challenge, even for GPT-4o" ([VersiCode](https://arxiv.org/abs/2406.07411)); valid calls to low-frequency APIs were 38.6% for GPT-4o, rising to 47.9% with documentation retrieval, and badly chosen retrieval cut high-frequency accuracy by 39 points ([CloudAPIBench / DAG](https://arxiv.org/abs/2407.09726)); and compile-pass rate can be anti-correlated with functional correctness ([Mage](https://arxiv.org/abs/2605.07342)).

**Honest AI assessment by game (today).**

| Game | Best-supported "advanced" targets | Needs a human |
|---|---|---|
| Minecraft Paper/Purpur | Commands, GUIs, economies, quests, minigames, admin tooling, custom items via data components (R1 to R2) | World-gen tuning, balance, custom blocks, resource-pack art, Folia-safe rewrites (R3) |
| Terraria tModLoader | Items, buffs, recipes, simple NPCs and projectiles (R1 to R2) | Bosses, tiles, world gen, netcode edge cases, IL patching (R3) |
| Terraria TShock | Server commands, permissions, anti-grief, events (R1 to R2) | Anything needing new items or art (impossible server-only) |
| Valheim (BepInEx + Jotunn) | Config and stat changes, clone-and-modify items, recipes, status effects (R1 to R2) | New models and prefabs (Unity editor), new biomes (R3) |
| Rust (Oxide/Carbon) | Kits, teleports, shops, custom UI, anti-cheat tooling (R1 to R2) | New items or models (impossible server-side), monthly-update triage (needs monitoring) |
| Palworld | PalSchema JSON data mods (R2) | UE4SS Lua without an SDK dump, Blueprint LogicMods, cooked assets (R3) |
| Project Zomboid | Item/recipe scripts and small Lua (R2, once B42 golden examples exist) | Models, maps, anything mixing B41 knowledge (R3) |

**Three hard platform facts Cyrus should surface to customers**
1. **Palworld server-side mods are Windows-server only** per community docs quoting the official docs [S: [XGamingServer](https://xgamingserver.com/docs/palworld/mod-installation), [ConnectHosting](https://connecthosting.net/blog/palworld-server-mods-what-works), [gamever.io](https://gamever.io/knowledge-base/server-side-mods-in-palworld-palmodsettingsini-and-the-flag-that-undoes-everything)]. Nxeon's Palworld image is the native Linux server (config path `.../Config/LinuxServer/PalWorldSettings.ini`) [L: `lib/game-control.ts:239`]. Unless that is wrong, most Palworld mods cannot run on Nxeon's Palworld servers today. This must be checked before the Palworld agent's `side` and `reason` strings are written.
2. **tModLoader and TShock cannot be combined**: tModLoader stable (v2026.08.3.0) targets Terraria 1.4.4; TShock 6.2.1 targets Terraria 1.4.5.8 [V: GitHub release APIs]. tModLoader has an active `1.4.5` branch (last commit 2026-10-07) [V], so this will change; Cyrus's version table must treat them as two products.
3. **Rust and Palworld-style "new item" ideas cannot be delivered server-side.** Vanilla Rust clients only show existing prefabs and Facepunch-approved workshop skins [S]. Cyrus should refuse or reframe those requests honestly.

**What Cyrus should add (ranked; details in section 9).**
1. Per-game **version-and-API knowledge packs** generated from the real jars, SDKs and docs, injected only for the target version (the Minecraft "sheets plus failure rules" pattern, generalised). Highest value, medium effort per game.
2. A **structured spec card** (commands, permissions, configs, GUIs, acceptance tests) before code, shared by all games. It also feeds tests.
3. **Golden examples** per game, human-verified and compile-tested, retrieved by nearest match. These double as regression tests.
4. **Multi-file projects with typed file roles** (code, config, data, lang, assets) and diff-based edits.
5. A **verification ladder** per game (static lint, compile, unit tests of pure logic, live smoke test on a throwaway server where the game allows).
6. **Dependency handling** (declared soft-dependencies, compile-only API digests, install-time "requires X" warnings).
7. **Iterative refinement from real server logs**, then multi-step planning for large mods, then companion asset packs (see `RENDERS-AND-TEXTURES.md`).

---

## 2. Method and limits

- Primary sources were fetched with WebFetch or `curl`, plus the GitHub, Thunderstore and Hugging Face APIs, which were reachable. umod.org, pzwiki.net and pzfans.com sit behind Cloudflare challenges; I did not try to bypass them. Where a fact would have come from them, it is tagged [S] and sourced from alternatives (Carbon's MIT-licensed docs repo, a community Build 42 guide, hosting-provider docs).
- `WebFetch` summarises pages with a small model. Facts that mattered were cross-checked against raw files or APIs where possible (release APIs, raw wiki markdown, licence texts). Anything only seen in a summary is tagged [S].
- Dates and version numbers are from release APIs read on 2026-10-08 unless noted.
- Effort figures in section 9 are my estimates for one engineer using AI assistance [I]. They are not measured.

---

## 3. Cross-game patterns

### 3.1 The capability ladder and who can do what

| Rung | Examples | AI today |
|---|---|---|
| 1 Config and data | Stat tweaks, spawn tables, drop rates, recipe edits | R1 when the schema is validated |
| 2 Scripted behaviour | Commands, listeners, timers, simple GUIs | R1 |
| 3 New content | Items, recipes, enchantments, buffs, simple mobs | R1 to R2 |
| 4 New systems | Economy, minigames, quests, custom AI, admin dashboards | R2 |
| 5 Engine-level | IL patching, Harmony patches of game internals, world generators with tuned noise, cooked Unreal/Unity assets | R3 |

### 3.2 Where mods break (all games)

1. **Game or loader update changes an internal name.** Silent failure is worse than a crash: Rust "boots and then quietly misbehaves" after a monthly update [S: [Low.ms schedule](https://low.ms/blog/rust-wipe-schedule-2026), [ConnectHosting](https://connecthosting.net/blog/palworld-server-mods-what-works)].
2. **Client and server mismatch.** Terraria tML, Valheim (when assets are involved) and Zomboid need identical mods on both sides; Rust and Terraria-TShock need nothing on the client; Minecraft plugins need nothing unless a resource pack is wanted.
3. **Threading rules.** Minecraft main thread vs async vs Folia regions; Unreal game thread (UE4SS); Unity main thread (Valheim); Zomboid's client/server Lua split.
4. **Save-data coupling.** Palworld's own docs warn that mods "may cause save-data corruption or crashes" [S]. Valheim persistence depends on `ZNetView` flags [V]. Minecraft PDC data is not copied automatically between holders [V].
5. **Dependency load order.** Zomboid library mods must load before dependents [S]; Valheim needs Jotunn first and then the mod; Paper plugins declare `depend`/`load` in `paper-plugin.yml` [V].

### 3.3 Why the existing non-Minecraft generators need care [L]
The owner's handoff generators (`palworld.ts`, `rust.ts`, `valheim.ts`, `zomboid.ts`) are deterministic templates built with an indentation-aware `code` tag, not model-written code. `palworld.ts` marks 17 API calls as `plausible:`, meaning the name was not confirmed against a game SDK dump (examples: `UPalUtility::SendSystemAnnounce`, `UPalTimeManager` hour accessor, `DT_PalDropItem` columns). Anything generated from unverified names should carry the "Template preview" label until a per-game agent resolves them. The Valheim template already emits xUnit tests for its pure balance maths, a good model for other C# games.

---

## 4. Minecraft: Paper and Purpur

### 4.1 Platform snapshot
- **Paper** is GPL-3.0 [prior research, [V] at the time]; **Purpur** is "a drop-in replacement for Paper servers designed for configurability, new fun and exciting gameplay features, and performance" [V: [Purpur README](https://github.com/PurpurMC/Purpur)]. Purpur plugins use the Paper API, so Cyrus can target Paper and run on both.
- Version lines in Cyrus today: 1.21.1, 1.21.4, 1.21.8, 1.21.11 [L: `MB_VERSIONS`]. Paper and Purpur also publish a 26.x line (Javadocs exist for 26.2) [V: [Paper 26.2 javadocs](https://jd.papermc.io/paper/26.2/org/bukkit/generator/package-use.html), Purpur README branch badge `ver/26.2`]. The service's Java 21 toolchain would need Java 25 for 26.x [prior research].
- **Side**: server-only. Vanilla clients can join. Custom visuals need a server-sent resource pack: `resource-pack` URL, `resource-pack-sha1`, `resource-pack-id`, `require-resource-pack`, a prompt; pack size limit 250 MiB [V: [Minecraft Wiki server.properties](https://minecraft.wiki/w/Server.properties)]. Since 1.20.3 a server can stack several packs and remove them individually [S: [Paper Adventure docs](https://docs.papermc.io/adventure/resource-pack/)].
- Hot reload: not safely. Needs a restart or a plugin-manager reload (risky). `/reload` is discouraged [I].

### 4.2 What "advanced" looks like, and how professionals do it

| Capability | Professional technique | Libraries / APIs | AI today |
|---|---|---|---|
| **Custom items** with new looks and behaviour | Stack data components (`item_model`, `custom_model_data`, tool, food, lore, enchantments) on a base item, store identity in PDC, ship a resource pack | Paper Data Component API, PDC, Recipes API [V: [data components](https://docs.papermc.io/paper/dev/data-component-api/), [PDC](https://docs.papermc.io/paper/dev/pdc/), [recipes](https://docs.papermc.io/paper/dev/recipes/)] | R1 for stats and behaviour, R2 when it needs a pack (art is R3) |
| **Custom blocks** | There are no truly new blocks on a vanilla client. Pros emulate with note-block states, tripwire, or display entities, and use Nexo or ItemsAdder to manage packs | Nexo docs, display entities [S: [Nexo FAQ](https://docs.nexomc.com/general-usage/faq/itemmodels-vs.-custommodeldata)] | R2/R3 (mining-speed emulation, drops, anti-dupe are fiddly) |
| **GUIs** | Inventory menus with strict click, drag and shift-click handling; 1.21.6+ Dialog API for forms (text input, sliders, dropdowns, confirm dialogs) | triumph-gui, InvUI (MIT) [prior], Dialog API [V: [dialogs](https://docs.papermc.io/paper/dev/dialogs/)] | R1 simple, R2 complex (dupe edge cases) |
| **Commands** | Brigadier via the lifecycle API, registered in a bootstrapper so datapack functions can see them; Cloud or ACF in older stacks | Paper Command API, Incendo Cloud (MIT) [V: [lifecycle](https://docs.papermc.io/paper/dev/lifecycle/)] | R1 (but see the 4.5 note about Cyrus's current `plugin.yml`-only rule) |
| **Custom enchantments, biomes, registries** | Registry API at server bootstrap with `compose` and `entryAdd` lifecycle events | Paper Registry API [V: [registries](https://docs.papermc.io/paper/dev/registries/)]: marked experimental; exceptions during bootstrap shut the server down | R3 for now |
| **Custom mob behaviour** | Add or replace AI goals with the Mob Goals API; use the Pathfinder for movement | `Goal`, `GoalKey`, `MobGoals` [V: [mob goals](https://docs.papermc.io/paper/dev/mob-goals/)] | R2 |
| **NPCs** | Citizens with custom Traits, or packet NPCs; dialogue trees from data files | Citizens API [V: [Citizens wiki](https://wiki.citizensnpcs.co/API)] | R2 |
| **AI-driven NPCs** (LLM dialogue) | Async HTTP to an LLM, never on the main thread; per-player rate limits and cost caps; moderation on input and output; fallback lines; prompts held server-side | Bukkit async scheduler; Mindcraft (MIT, 5.8k stars) shows the agent side [V: [mindcraft repo](https://github.com/mindcraft-bots/mindcraft)] | R2; Cyrus's safety scan currently **blocks all networking**, so this needs a deliberate "Connector" design (section 9) |
| **World generation** | `ChunkGenerator` with separate noise, surface, caves and bedrock steps, plus `BiomeProvider`; they take `WorldInfo`, not `World`, because `World` calls can deadlock during generation [S: [Bukkit/CraftBukkit change notes](https://hub.spigotmc.org/jenkins/view/RSS/job/CraftBukkit-RSS/2198/)]. Datapack worldgen JSON is the safer route | `org.bukkit.generator` [V: Javadoc index] | R2 for datapack JSON, R3 for tuned noise |
| **Economies** | Vault or VaultUnlocked as the abstraction so shops and jobs plugins interoperate [S: [Vault explainer](https://mineguard.pro/en/blog/vault-plugin-economy-permissions-explained)]; balances as integers (cents) or `BigDecimal`; async persistence with write-behind caching; transaction logging | Vault API, SQLite/MariaDB with a pool [I] | R1 basic, R2 with races; **balance design is R3** |
| **Minigames and arenas** | State machine per match, arena templates copied per game, cleanup on quit, kick, death and match end | Scoreboard API (broken on Folia [V]) | R2 |
| **Quests** | Data-driven YAML/JSON quest definitions, event listeners, PDC progress | Configurate (Apache-2.0) [prior] | R1 |
| **Performance mods** | Limit entities and chunk ticking, batch work, move I/O off-thread; measure with a profiler such as spark [I] | Paper scheduler [V: [scheduler](https://docs.papermc.io/paper/dev/scheduler/)] | R2: claims of "faster" must be measured, which Cyrus cannot do today |
| **Admin tooling** | Audit logs, rollback, moderation GUIs, Discord bridges (needs network) | Plugin messaging, PDC | R1 to R2 |

### 4.3 Techniques that separate advanced plugins from tutorial plugins
1. **Item identity in PDC, not names or lore.** PDC survives renames and persists to disk; names and lore collide with players' anvils [V: [PDC](https://docs.papermc.io/paper/dev/pdc/)]. The API also warns that data components may break across Minecraft versions, unlike `ItemMeta` [V].
2. **Item models over CustomModelData override stacks.** From 1.21.4 an `item_model` points at an items definition under `assets/<namespace>/items/`, so packs no longer fight over vanilla model overrides [V: [Nexo](https://docs.nexomc.com/general-usage/faq/itemmodels-vs.-custommodeldata), [Items model definition](https://minecraft.wiki/w/Items_model_definition)]. Supporting clients older than 1.21.4 still needs CMD overrides.
3. **Bootstrap-time registration** when the feature must exist before worlds load (commands for datapack functions, registry entries). Requires `paper-plugin.yml`, with classloader isolation: plugins cannot see each other's classes unless `join-classpath` is set [V: [Paper plugins](https://docs.papermc.io/paper/dev/getting-started/paper-plugins/)].
4. **Libraries via the Paper loader**: `MavenLibraryResolver` instead of shading everything. The docs advise against Maven Central directly and recommend Paper's mirror [V].
5. **Tests**: MockBukkit (MIT) for unit tests of commands and events, mineflayer bots for live behaviour [prior research]. MockBukkit builds a ByteBuddy proxy of your main class, so a `final` main class breaks every test [prior local experiment].
6. **Folia awareness** only when asked. Folia has no main thread; plugins must declare `folia-supported: true` and use region, entity, global and async schedulers; `Entity#teleport` never returns (use `teleportAsync`); the scoreboard API is broken [V: [Folia support](https://docs.papermc.io/paper/dev/folia-support/), [Folia wiki](https://github.com/PaperMC/Folia/wiki/Plugin-Compatibility)].

### 4.4 Pitfalls
- Touching world, entities or inventories from async code. Keep async for I/O, hop back to the main thread to apply results [S: skill pages consistent with Paper docs].
- Long-lived maps keyed by `Player`. Key by UUID; clear on quit, kick, death and match end [S].
- Saving in `onDisable` through the async scheduler: the scheduler refuses new tasks while the plugin disables, so the data is lost [L: rule `ondisable-sync-save`].
- `BukkitRunnable` passed to `runTask*` throws at runtime [L: rule `scheduler-bukkitrunnable`].
- Declaring `isEnabled()`/`getServer()` in the main class: `JavaPlugin` defines them as final [L].
- API drift: `Attribute` is an enum on 1.21.1 and an interface on 1.21.4+; `Particle`, `PotionEffectType` and `Enchantment` constants were renamed [L]. These are exactly what an API sheet per version catches.
- Inventory GUI duplication via drag, number-key and hopper interactions [I].

### 4.5 Performance and compatibility
- Paper vs Purpur: Purpur adds config and gameplay options; its extra API is not in Paper, so Cyrus output should target the Paper API and avoid Purpur-only calls unless the customer picked Purpur [I].
- Folia is a different product: most plugins do not run on it unless rewritten [V].
- Current Cyrus constraints in the build service system prompt [L: `prompts.js`] that matter for "advanced": only Paper API + JDK on the classpath (no Vault, ProtocolLib, LuckPerms API); `plugin.yml` plus `getCommand().setExecutor` only (no Brigadier, no lifecycle events, no `registerCommand`); no networking of any kind; no reflection; single plugin per build. These are sound for safety and reliability, and they are the main ceiling on "advanced". Section 9 proposes controlled relaxations.

### 4.6 What AI can and cannot do (Minecraft)
- **R1:** commands, listeners, config-driven features, simple GUIs, quests from data, many admin tools. Compile-and-scan catches most failures.
- **R2:** custom items with resource packs, economies, minigames, mob goals, datapack worldgen. Needs spec confirmation, tests and a live smoke test.
- **R3:** economy balance and game feel, world-gen tuning, custom blocks, Folia migration, resource-pack art, performance claims.
- Nothing in Paper adds new blocks or items on a vanilla client; say so plainly in the UI [prior research].

---

## 5. Terraria: tModLoader and TShock

### 5.1 Platform snapshot [V: GitHub APIs, 2026-10-08]
- **tModLoader** is MIT. Stable `v2026.08.3.0` (2026-10-01) targets **Terraria 1.4.4**; a preview `v2026.09.2.1` is also 1.4.4. A `1.4.5` branch is under active development (commits on 2026-10-07). Monthly-style version tags and a long "Update Migration Guide" with one section per month show a fast breaking-change cadence, and `tModPorter` exists to help port [V: [wiki](https://github.com/tModLoader/tModLoader/wiki/Update-Migration-Guide)]. Needs the **.NET 8 SDK** (.NET 9 and 10 explicitly "will not work") [V: [developer guide](https://github.com/tModLoader/tModLoader/wiki/tModLoader-guide-for-developers)].
- **TShock** (server mod, vanilla clients can join) `6.2.1` (2026-09-27) targets **Terraria 1.4.5.8**; earlier 6.x covered 1.4.5.5 and 1.4.5.6 [V]; 5.2.x covered 1.4.4.9 [S: one fetch summary]. Built on OTAPI; building needs the .NET 9 SDK [V: [TShock README](https://github.com/Pryaxis/TShock)].
- **Sides.** tML content mods must be on server **and** every client at the same versions; a mismatch blocks joining; clients are usually prompted to download missing mods [S: [FragNet](https://kb.fragnet.net/Games/Terraria/How_to_add_mods_to_your_tModLoader_server/), [Falix](https://client.falixnodes.net/guides/game-servers/terraria-tmodloader-mods), several others]. TShock needs nothing on the client [I, consistent with its design as a server plugin host].
- **Server install for tML:** `.tmod` files plus `enabled.json` in the server's Mods folder, or a management script that installs from a Workshop-exported `install.txt` [V: [Starting a modded server](https://github.com/tModLoader/tModLoader/wiki/Starting-a-modded-server); the page notes it is outdated for 1.4.4 dedicated servers and points to the `DedicatedServerUtils` readme].

### 5.2 Mod anatomy (tML) [V: [Basic Modding Guide](https://github.com/tModLoader/tModLoader/wiki/Basic-tModLoader-Modding-Guide)]
`build.txt` (display name, author, version), `description.txt`, `.csproj`, one `Mod` class, content classes (`ModItem`, `ModNPC`, `ModProjectile`, `ModTile`, `ModBuff`, `ModPlayer`, `ModSystem`, `GlobalItem`, ...), localisation in `Localization/en-US_Mods.<Name>.hjson`, `icon.png` (80x80) and `icon_small.png` (30x30). Output is a `.tmod` file built with Build + Reload.

**Textures are autoloaded by class path:** a PNG next to the `.cs` with the same name as the class. "Items, Projectiles, and NPC all need a texture... any one of these without an associated texture will cause your mod to be unable to load" [V: [Basic Autoload](https://github.com/tModLoader/tModLoader/wiki/Basic-Autoload)]. This is a concrete hazard for any AI generator that emits an item without art.

### 5.3 What advanced looks like (tML)

| Capability | Technique | AI today |
|---|---|---|
| Weapons, armour, accessories, buffs | `ModItem` hooks, `ModPlayer` for set bonuses, `GlobalItem` to change vanilla; recipes in `ModItem.AddRecipes` or `ModSystem.AddRecipes` [V: [recipes](https://github.com/tModLoader/tModLoader/wiki/Basic-Recipes)] | R1 to R2 |
| Minions and projectiles | Custom AI via `ModProjectile.AI`, buff-plus-minion pattern | R2 |
| NPCs and bosses | `ModNPC` AI states, spawn conditions, loot via `ModifyNPCLoot` | R2 simple, R3 boss fights (balance and telegraphing) |
| Tiles and tile entities | Framed tiles, `ModTileEntity`, placement and mining rules | R3 (sprite frames and hitboxes are fussy) |
| World generation | `ModSystem.ModifyWorldGenTasks`, reference the vanilla step list [V: wiki index lists World Generation and Vanilla World Generation Steps] | R3 |
| Custom UI | `UIState` via `ModSystem` interface layers | R2/R3 |
| Config | `ModConfig` (JSON-backed, server-synced) | R1 |
| Saving data | `TagCompound` in `SaveData/LoadData` [V: wiki index "Saving and loading"] | R1 |
| Cross-mod support | `Mod.Call`, weak references [V: wiki index "Expert Cross Mod Content"] | R2 |
| Patching vanilla | IL editing and detours with MonoMod [V: wiki index "Expert IL Editing", "Advanced Detouring"] | R3, and it breaks every Terraria update |
| Shaders | Armour dyes and screen shaders [V: wiki index] | R3 |

### 5.4 Netcode (the usual multiplayer killer)
- Three flows: client to server to clients, client to server, server to client. Use `ModPacket` and `HandlePacket`; keep packets small; prefer deterministic logic so less must be sent [V: [Intermediate netcode](https://github.com/tModLoader/tModLoader/wiki/Intermediate-netcode)].
- "If a mod is actually buggy during multiplayer, it is often because they do not send packets at all and clients aren't synchronized" [V, same page]. AI-generated tML mods that were only reasoned about in single player will desync. A validator can at least flag state mutated in `Update` hooks with no sync call.

### 5.5 TShock (server plugin) techniques
- Plugins are .NET DLLs on OTAPI; "you have direct access to all public fields in the `Terraria` namespace" [V: TShock README]. Typical advanced work: command suites, permission groups, region protection, event rewards, anti-cheat tuning, scheduled events, per-group item rules.
- It cannot add items or art (vanilla clients do not have them), so "custom item" requests belong to tML, not TShock.
- Decompiled server sources are maintained by the TShock team for contributors [V README]; they are proprietary-derived, so Cyrus must not ship them.

### 5.6 Pitfalls
- Wrong .NET SDK (8 vs 9) [V]. Texture and class name mismatches [V]. Missing localisation keys [I].
- "Mod not fully unloaded" memory leaks from static references; the wiki has a dedicated page [V: index link].
- Packet bloat and desync [V]. IL patches breaking on every update [V by cadence].
- The two ecosystems target different Terraria versions today [V]. A tML mod on a 1.4.5 TShock server is not a thing.
- Mods that add content change world and player files, so removing a mod can orphan items or tiles [I].

### 5.7 What AI can and cannot do (Terraria)
- **R1:** a `ModItem` with stats and a recipe, buffs, simple `ModConfig`, TShock commands. The official ExampleMod (MIT) is a strong golden reference; tML `ExampleMod` ships in the repo [V: [ExampleMod](https://github.com/tModLoader/tModLoader/tree/stable/ExampleMod)].
- **R2:** projectiles, minions, simple NPCs, UI panels. Needs compile against the real tML assemblies and a load test.
- **R3:** bosses, tiles, world gen, IL editing, netcode design, sprite frames. A compile check cannot tell if the game plays well.
- Verification: tML can run a headless dedicated server on Linux with the management script [V], so a load-and-join smoke test is plausible. It needs the game's licensed files via SteamCMD, which Cyrus must not redistribute; the Terraria agent owns this call.

---

## 6. Valheim: BepInEx and Jotunn

### 6.1 Platform snapshot
- **Valheim 1.0 shipped 2026-09-09** and "mods broke initially"; Iron Gate said they "cannot guarantee that any mods will be functional" [S: [HostHavoc](https://hosthavoc.com/blog/valheim-1-0-update-server-owners) and the GameServerKings 1.0 guide]. BepInExPack_Valheim `5.4.2351` (2026-09-24) and Jotunn `2.30.2` (2026-09-21) are current [V: Thunderstore API, GitHub API]. Jotunn 2.30.0 notes: "Updated the majority of systems for Valheim 1.0.7... Piece categories are not updated yet, Valheim overhauled the system completely. Custom pieces show up in the build menu, but don't have a category" [V: [release 2.30.0](https://github.com/Valheim-Modding/Jotunn/releases/tag/v2.30.0)].
- **Engine:** Unity **6000.0.61** for asset work [V: [Jotunn asset-creation tutorial](https://github.com/Valheim-Modding/Jotunn/blob/prod/JotunnLib/Documentation/tutorials/asset-creation.md)].
- **Language / loader:** C# plugins on BepInEx (LGPL-2.1) with Harmony patches; Jotunn is MIT [prior research; Jotunn MIT re-verified via API]. Jotunn supplies entity wrappers: `CustomItem`, `CustomPiece`, `CustomRecipe`, `CustomCreature`, `CustomStatusEffect`, `CustomLocation`, `CustomVegetation`, `CustomItemConversion`, `KitbashObject`, `Mocks`, plus managers for commands, GUI, input, localisation, minimap, skills, zones, rendering, undo and network sync [V: [Jotunn README](https://github.com/Valheim-Modding/Jotunn)].
- **Sides.** Mods are server-side only, client-side only, or both; for "both", the client and server must have matching files or the handshake refuses [S: [Hosthavoc](https://hosthavoc.com/de-DE/wiki/game-servers/valheim/install-bepinex), [Berrybyte](https://berrybyte.net/wiki/games/valheim/best-mods)]. Jotunn's `NetworkCompatibility` attribute enforces this: levels `NotEnforced`, `VersionCheckOnly`, `EveryoneMustHaveMod`, `ClientMustHaveMod`, `ServerMustHaveMod`, with `VersionStrictness` (major/minor/patch semantics) [V: [NetworkCompatibility tutorial](https://github.com/Valheim-Modding/Jotunn/blob/prod/JotunnLib/Documentation/tutorials/networkcompatibility.md)]. This is the exact data Cyrus's `GameSupport.install.side` needs.

### 6.2 What advanced looks like

| Capability | Technique | AI today |
|---|---|---|
| Config-synced balance mods | BepInEx `ConfigEntry` with Jotunn config sync (`SynchronizationManager`) | R1 |
| New items by cloning vanilla | `PrefabManager.OnVanillaPrefabsAvailable` then `CustomItem(name, basePrefab, config)`; edit the cloned `ItemDrop` stats; add a `CustomRecipe` [V: Jotunn items tutorial + docs layout] | R1 to R2 |
| New icons without a Unity project | `RenderManager` renders a prefab to a sprite at runtime; `AssetUtils.LoadSpriteFromFile`, `LoadTexture`, `LoadMesh` (OBJ) load from files [V: [render queue](https://github.com/Valheim-Modding/Jotunn/blob/prod/JotunnLib/Documentation/tutorials/renderqueue.md), `AssetUtils.cs`] | R2 (a no-Unity art path) |
| Status effects and skills | `CustomStatusEffect`, `SkillManager` | R2 |
| Creatures | Clone and edit vanilla creatures; new rigs need Unity | R2 clone, R3 new |
| Build pieces | `CustomPiece` with a piece table and category (broken for categories in 1.0.7 [V]) | R2, version-fragile |
| World content | `CustomLocation`/`CustomVegetation` via `ZoneManager`. A zone is 64 by 64 m and holds **one** location, so the number of location slots is limited [V: [zones](https://github.com/Valheim-Modding/Jotunn/blob/prod/JotunnLib/Documentation/tutorials/zones.md)] | R3 |
| Networking | `NetworkManager.CustomRPC` compresses and splits big payloads; use ZNetView RPCs for small per-object data [V: [RPCs](https://github.com/Valheim-Modding/Jotunn/blob/prod/JotunnLib/Documentation/tutorials/rpcs.md)] | R2/R3 |
| Compatibility with other mods | `ModCompatibility`, mod registry, soft dependencies via `BepInDependency` [V: file listing; usage [I]] | R2 |
| New assets | Author prefabs in a Unity 6000.0.61 project that holds the game's components, build an AssetBundle, load it in the plugin [V] | R3 |

### 6.3 Pitfalls
- 1.0 broke systems wholesale (piece categories); a mod generated against pre-1.0 docs will compile and misbehave [V].
- Cloned objects: references to vanilla prefabs resolve at runtime through Jotunn "Mocks" [V]; a hand-built prefab that references vanilla materials directly can end up with pink or missing shaders [I].
- `ZNetView.m_persistent` must be true for objects to save [V: zones tutorial]. Missing it means objects vanish.
- Unity version lock: bundles must be built with the exact Unity version the game uses [V]. Wrong version means the bundle refuses to load.
- Harmony patches on internals break whenever the method signature changes [I].
- Dedicated-server load of client-only code (UI) throws; guard with `ZNet.instance.IsDedicated()` style checks [I].

### 6.4 What AI can and cannot do (Valheim)
- **R1:** config-and-stat mods, recipe tweaks, clone-and-modify items, status effects, console commands, with a per-version API sheet taken from the game's decompiled assemblies and the Jotunn docs.
- **R2:** items with generated icons (via `RenderManager`/PNG loading), creatures cloned from vanilla.
- **R3:** new models and rigs, new biomes or bosses, anything needing the Unity editor. The editor is a proprietary tool with its own licence; check Unity's terms before building a hosted pipeline around it [I, unverified].
- Golden examples exist with permissive licences: `JotunnModStub` and `JotunnModExample` are MIT-0 [V: GitHub API].

---

## 7. Rust: Oxide (uMod) and Carbon

### 7.1 Platform snapshot
- **Oxide.Rust** is MIT; release `2.0.7815` on 2026-10-08 [V: GitHub API]. **Carbon** is GPL-3.0, a "self-updating, lightweight, intelligent mod loader" with backward compatibility for Oxide plugins; releases `v2.4.341` (Rust release branch, 2026-10-03) and `v2.3.1481` (staging) [V: [Carbon](https://github.com/CarbonCommunity/Carbon)]. Carbon's docs repo (MIT) has full developer documentation [V: [Carbon.Documentation](https://github.com/CarbonCommunity/Carbon.Documentation)].
- **They cannot coexist.** "Oxide and Carbon can NOT coexist in the same server install"; migrating requires reverting Facepunch DLLs to vanilla [V: [Oxide porting](https://github.com/CarbonCommunity/Carbon.Documentation/blob/main/docs/owners/oxide-porting.md)].
- **Plugins are C# source files the server compiles itself; players install nothing and join with a normal client** [S: [VibeGames help](https://vibegames.com/help/rust/how-to-install-oxide-or-carbon-on-your-rust-server), [Respawn Host](https://respawnhost.com/en/wiki/games/rust/rust-plugins/)]. Modded servers appear under the "Modded" tab; gameplay-altering plugins on the "Community" tab break Facepunch's guidelines [S].
- **Update cadence.** Monthly update on the first Thursday, which is also the forced wipe; protocol changes mean every server must at least map-wipe. Most popular plugins are patched within hours, niche ones in a day or two. Failure is quiet: "a server that boots and then quietly misbehaves" [S: [Low.ms](https://low.ms/blog/rust-wipe-schedule-2026), [GameServerKings](https://gameserverkings.com/knowledge-base/rust/wipe-day-guide)].

### 7.2 What advanced looks like

| Capability | Technique | AI today |
|---|---|---|
| Kits, teleports, homes, shops, clans | Hooks (`OnPlayerConnected`, `OnEntityDeath`, ...), permissions, JSON data files, language files | R1 |
| Permissions and groups | Oxide permission system: permission strings and groups, config under `oxide/` [S: [Corrosion Hour guide](https://www.corrosionhour.com/umod-permissions-guide/)]; Carbon permissions and SQL permissions [V: Carbon docs index] | R1 |
| **Custom UI** | CUI/LUI panels, images from an image database, modals, colour/date/file pickers as Carbon modules [V: [LUI](https://github.com/CarbonCommunity/Carbon.Documentation/blob/main/docs/devs/features/lightweight-ui.md)] | R2 |
| **Client-only visuals** | `ClientEntity` spawns prefabs visible only to chosen clients (cheap fake structures, markers) [V: [client entities](https://github.com/CarbonCommunity/Carbon.Documentation/blob/main/docs/devs/features/client-entities.md)] | R2 |
| HUD vitals | `CustomVitalManager` for shared and per-player vital icons with countdowns [V: [custom vitals](https://github.com/CarbonCommunity/Carbon.Documentation/blob/main/docs/devs/features/custom-vitals-manager.md)] | R2 |
| Large plugins | `.cszip` packages: one plugin split across many partial-class files [V: [zip scripts](https://github.com/CarbonCommunity/Carbon.Documentation/blob/main/docs/devs/features/zip-script-packages.md)] | R1 (a natural multi-file container) |
| Economy and progression | Plugin-to-plugin APIs (`[PluginReference]`), data files, timers | R2 |
| Map and wipe automation | Carbon modules such as AutoWipe, Stack Manager, Gather Manager [V: docs index] | R2 |
| Anti-cheat and admin | Server-authoritative checks on hooks; audit logs | R2 |
| Profiling | Carbon.Profiler and mono profiler feature [V: docs index] | R2 |

### 7.3 Hard limits
- **No new items, models or textures from the server.** Plugins can reuse existing prefabs and apply workshop skin IDs; the server only sends a skin number and the client renders what it already has [S: [umod skins thread](https://umod.org/plugins/skins), [oxidemod thread](https://oxidemod.org/threads/workshop-skins-not-working-in-plugins.29292)]. Facepunch accepts workshop skins for existing items, with rules about worn style, text and IP [V: [Getting Skin Accepted](https://wiki.facepunch.com/rust/Getting_Skin_Accepted)].
- **uMod approval policy** (two reviewers; no backdoors, no abuse tools) does not mention AI-generated code in what I could read; it requires original work or authorisation [S: search snippet of the [approval guide](https://umod.org/documentation/api/approval-guide); page itself blocked]. Cyrus must not auto-submit anything to uMod.

### 7.4 Pitfalls
- Hook rename or removal after the monthly update; the usual log symptoms are `Failed to call hook 'OnServerInitialized'` or a `NullReferenceException` during Carbon load [S].
- Per-tick hooks (`OnPlayerTick`, `OnEntityTakeDamage`, `OnEntitySpawned`) with allocations; use pooling and early exits [I].
- Entity spawn counts and Unity object leaks; always kill spawned entities on unload [I].
- Running two loaders; stale DLLs after a framework migration [V].
- Plugins compiled on the server means a syntax error is found at the customer's server, not in Cyrus. Cyrus should compile-check offline against pinned Oxide/Carbon reference DLLs; this needs the Facepunch managed DLLs, which are proprietary (download via SteamCMD per run, never redistribute) [I].

### 7.5 What AI can and cannot do (Rust)
- **R1:** the large catalogue of conventional plugins (kits, shops, teleports, join messages, protection rules, simple UI). Plugin tutorials and open-source plugins are plentiful in training data.
- **R2:** custom UI and multi-file Carbon plugins, tested against a throwaway server.
- **R3:** performance-critical hooks, new gameplay requiring assets, any request needing a new item, and the monthly-update triage (can be automated only partially, via diffing hook lists from [Carbon's hooks reference](https://github.com/CarbonCommunity/Carbon.Documentation/blob/main/docs/references/hooks/index.md)).

---

## 8. Palworld and Project Zomboid

### 8.1 Palworld

**Snapshot.**
- Palworld **1.0 released 2026-07-10** (Japan time). Pocketpair told players to delete old mods because "disabling them is not enough", warned of crashes and corrupted saves, and expected effectively all mods to be incompatible until updated; 1.0.2 later improved stability "when playing with MODs" [S: [PC Gamer headline](https://www.pcgamer.com/games/survival-crafting/palworld-studio-says-delete-your-old-mods-before-the-1-0-release-disabling-them-is-not-enough/), [PCGamesN](https://www.pcgamesn.com/palworld/1-0-mod-warning), search summaries].
- **Official server-mod system** (post-1.0): `Mods/PalModSettings.ini` with `bGlobalEnableMod` and a repeated `ActiveModList` keyed by each mod's `PackageName` in `Info.json` (not the folder name); `"IsServer": true` marks a server-capable mod; changing `Version` makes the server uninstall the old copy and redeploy the new one; `ManagedMods/<PackageName>/InstallManifest.json` records deployment to fixed paths for UE4SS, Lua, PalSchema, LogicMods and Paks; `-NoMods` disables everything; `bAllowClientMod=True` lets modded clients connect [S: gamever.io, XGamingServer, ConnectHosting]. The "Windows dedicated server only" statement is quoted from the official docs by these sources; I could not open the official page [S].
- **UE4SS** is "a Lua scripting system, C++ modding API, SDK generator, blueprint mod loader, live property editor" for Unreal 4/5 games, and says plainly it is "not... a plug-n-play solution that always works with every game" [V: [UE4SS docs](https://docs.ue4ss.com/)]. Palworld needs its own RE-UE4SS build since patch 0.4.1.5 [S].
- **PalSchema** (MIT) edits data tables and blueprints through JSON without overwriting whole assets, with JSON-schema autocompletion. Folders: `appearance`, `blueprints`, `buildings`, `enums`, `helpguide`, `items`, `pals`, `raw`, `skins`, `spawners`, `translations` [V: [PalSchema repo](https://github.com/Okaetsu/PalSchema), [docs](https://okaetsu.github.io/PalSchema/docs/gettingstarted)]. Its UE4SS version must match the release.

**The five formats, cheapest first** [S: [palmods.gg choose-a-format](https://www.palmods.gg/docs/authors/creating-mods/choose-a-format)]: PalSchema (data), UE4SS Lua (hooks, runtime), resource paks (cooked textures, meshes, audio), LogicMods (cooked Blueprint actors; community Modding Kit on **Unreal 5.1** with pinned .NET 6, VS 2022 MSVC 14.38, Wwise 2021.1.11), native C++. Guidance from the community: use "the least powerful format that fully expresses the idea" [S].

**What advanced looks like.** Pal stat and spawn rebalancing, new items and recipes via data, spawner rules, drop tables, base-building changes, UI tweaks, quality-of-life automations in Lua, and in the extreme new Blueprint systems. Co-op and dedicated servers can host server mods; console players cannot install mods but can join servers running server-only mods [S: XGamingServer].

**Pitfalls.**
- Engine and 1.0-scale changes break `.pak`/LogicMods hardest [S].
- `PackageName` vs folder name mismatch is the commonest silent failure [S].
- LogicMods: content landing in chunk 0, wrong ModActor naming, cooking unrelated skeleton content, shipping the editor project instead of cooked output [S: [Modding Kit](https://www.palmods.gg/docs/authors/creating-mods/modding-kit)].
- Missing IoStore files (`.utoc`/`.ucas`) cause "ModClass invalid" in UE4SS [S].
- `plausible:` API names in the handoff template (17 of them) will fail at runtime on a real SDK [L].
- **Hosting platform gap.** Nxeon runs the native Linux `PalServer` [L], and official server mods need the Windows server [S]. PalSchema requires Windows and "doesn't run on a native Linux server" [S: search summary of survival-servers/others]. Resolve before promising Palworld mod installs.

**AI assessment.** **R2** for PalSchema JSON where a schema validator exists (data edits are checkable and the format is designed to be safe). **R3** for UE4SS Lua without a CXXHeaderDump of the exact game build (these dumps are derived from the proprietary game and must be generated per build, never redistributed), and for LogicMods and cooked assets.

### 8.2 Project Zomboid

**Snapshot.**
- **Build 42.20 stable on 2026-07-29** brought multiplayer to the stable branch; B42 multiplayer first appeared in the unstable 42.13 branch (2025-12-11) [S: [Shockbyte](https://shockbyte.com/blog/project-zomboid-build-42-multiplayer)]. **B41 mods do not work on B42**: "the engine, the map format, the crafting system and much of the modding API changed" [S: [ConnectHosting](https://connecthosting.net/blog/project-zomboid-b42-server-not-loading-workshop-mods), [Build 42 guide](https://build42guide.wiki/multiplayer/build-42-mods)].
- **Structure** (B42): `Contents/mods/<ModId>/42/{mod.info, media/{scripts,lua/{client,server,shared},textures,models}}`, optional `common/` shared by both builds, plus `workshop.txt` and a preview image. A mod with only a root `media/` folder will not load in B42 [V: [B42 modding guide](https://github.com/gotmayonase/pz-modding-guide), mod-structure.md and b42-changes.md].
- **Breaking syntax changes** [V, same guide]: `Type = Container` became `ItemType = base:container`; the `recipe {}` block became `craftRecipe Name { inputs {...} outputs {...} }`; several item IDs gained a `2` suffix (`Base.TreeBranch2`, `Base.WoodenStick2`); skill IDs (`Woodwork`, `Blacksmith`) and tags (`base:sharpknife`) differ from B41.
- **Multiplayer pattern** [V, same guide]: Lua runs in client, server and shared contexts. State changes go client to server through `sendClientCommand`, the server validates and changes state, and the engine syncs it. Guard functions `isClient()`, `isServer()`, `isMultiplayer()` exist, but prefer file placement over guards. A listen-server host runs both contexts, so client code can run twice.
- **Tooling:** Umbrella provides EmmyLua type stubs for the Lua API (language-server completion and type checks) [V: [PZ-Umbrella/Umbrella](https://github.com/PZ-Umbrella/Umbrella)]; `/reloadlua` reloads Lua without a restart, but item and recipe scripts need a full restart [V]; StarlitLibrary is a general-use modding library [V: repo listing]; the Project Zomboid Community Modding workshop project maintains shared tools [V: [pz-community-modding](https://github.com/Project-Zomboid-Community-Modding/pz-community-modding)]; an emerging Java mod loader (Avrix, Mixins) exists [V: repo listing, early].
- **Server config:** `WorkshopItems=` (numeric IDs) and `Mods=` (mod IDs; in B42 each ID needs a trailing backslash in the guide's example), semicolon-separated; commas silently break it [S: two hosting sources; contradictory examples exist, see unknowns]. Library mods must load first [S]. "Most gameplay mods need to be installed on both client and server" [S].
- **Official docs are thin:** "Official B42 documentation is sparse. The PZwiki lags behind." [V: guide README].

**What advanced looks like.** New items, containers and clothing; crafting trees with skill requirements; Lua for traits, sandbox options and events; loot-table injection; vehicle and weapon models; map mods (tile sheets, `.tiles` files, cells) [S]; server-side admin Lua; multiplayer-safe systems. `OnPlayerUpdate` fires every tick for every player, so handlers must exit early and avoid allocations [V].

**Pitfalls.**
- Following B41 tutorials (most of the internet) silently fails in B42 [V].
- Item script/recipe parse errors appear only in the log at startup [V: testing.md].
- 16-bit PNG icons are rejected silently; icon files must be `Item_<Name>.png` while the script says `Icon = <Name>` [V, community guide; treat as [S]].
- Per-patch breaks even within B42 (42.16 removed a vanilla location, renamed occupations and traits, changed a sandbox option from boolean to dropdown, and shipped a 42.16.0 regression where mods did not load) [V: version-changelog.md of the guide, a community source].
- Client and server version mismatches stop players joining [S].

**AI assessment.** **R2**, conditional on B42 golden examples and a script-syntax validator: item and recipe scripts are structured text a validator can check; Lua is small and reasonable. The danger is stale B41 knowledge, which makes this the game where retrieval of B42-specific examples matters most. **R3** for models, maps, animations. A live test needs a Zomboid dedicated server; the free dedicated-server app is installable via SteamCMD [I, unverified], which the Zomboid agent should confirm.

---

## 9. What Cyrus should add (ranked by value)

Scale: **Value** 1 to 5 (5 = changes what Cyrus can reliably do). **Effort**: S ≤ 3 person-days, M 4 to 10, L 11 to 30 (one engineer with AI assistance [I]). "Per game" means repeated for each game.

| # | Addition | Value | Effort | Why (evidence) | Main dependencies |
|---|---|---|---|---|---|
| 1 | **Version-and-API knowledge packs** per game and version: a verified API sheet generated from the real artefacts (Paper jar, Jotunn + game assemblies, tML assemblies, Carbon references, PalSchema schema, PZ scripts), plus reviewed failure rules, injected only for the target version | 5 | M per game (3 to 5 d) after a shared generator (M) | Minecraft already does this [L]; failures are mostly API drift [L]; documentation retrieval lifts low-frequency API validity (38.6% to 47.9%) but should be triggered selectively because bad retrieval hurts [V: CloudAPIBench] | Per-game agents' `GameSupport.versions`; SDK/jar acquisition that avoids redistributing proprietary files |
| 2 | **Structured spec card** (commands, permissions, configs, GUIs, data tables, acceptance tests) approved by the user before generation | 5 | M (4 to 6 d, shared across games) | Intermediate structure improved fidelity (F1 up to 1.00) while raw NL-to-code produced "structurally vacuous" output, and compile-pass was anti-correlated with correctness [V: Mage]. The earlier mod-builder plan already specifies it [prior research] | UI work with studio/routing agents |
| 3 | **Golden examples per game** (human-verified, compile-tested, MIT/CC0-compatible); retrieve the 1 to 2 nearest as few-shot context and use them all as regression tests | 4 | S to M per game (2 to 3 d) | tML ExampleMod (MIT), JotunnModExample/Stub (MIT-0), Carbon docs (MIT), PZ community repos [V]. B42 Zomboid especially needs them | Licence check per source |
| 4 | **Multi-file projects with typed roles** (code, config, data, lang, assets, tests, manifest) and diff-based edits that touch only the named files | 4 | M (5 to 8 d) | Advanced mods are many files (Carbon `.cszip`, tML folders, PZ `42/media/...`, Valheim projects). Existing service handles one Gradle workspace; edits already exist as "change requests" [L] | Efficiency agent (cost), lifecycle agent (versions) |
| 5 | **Verification ladder** per game: schema/syntax validators (PalSchema JSON schema, PZ script parser, `plugin.yml`/`Info.json`/`mod.info`/`build.txt` manifests) then compile against pinned references then unit tests of pure logic then live smoke test | 5 | S to M per validator; L for live tests per game | MockBukkit + mineflayer already prototyped [L: `eval/rt-bot.js`, `rtcheck.py`] but not in the production pipeline; Valheim template already emits xUnit tests [L] | Throwaway servers (never on the primary); per-game licensing of server files |
| 6 | **Dependency handling**: a per-game allow-list of soft dependencies (Vault, PlaceholderAPI, LuckPerms API, Jotunn, PalSchema, StarlitLibrary, Carbon/Oxide references) with compile-only API digests; auto-fill `depend`/`softdepend`, `BepInDependency`, `require=` | 4 | M (5 to 8 d) | Real advanced mods interoperate (Vault abstraction [S]; Jotunn `NetworkCompatibility` [V]; Zomboid `require=` [V]). Today the service forbids every outside library [L] | Safety scan extension; lifecycle agent "requires X" warnings |
| 7 | **Iterative refinement from real server logs**: parse a stack trace or log excerpt, map it to the failing file and API, propose a minimal diff | 4 | M (5 to 8 d) | Rust and Palworld failures are quiet and appear after updates [S]. Small Haiku-class log triage was in the earlier plan [prior research] | Install/lifecycle log access |
| 8 | **Selective documentation retrieval** (trigger only when the model is unsure or the API is low-frequency) | 3 | S to M | The same CloudAPIBench result: blanket retrieval hurts common APIs [V] | #1 |
| 9 | **Multi-step planning** for large mods: a planner step decomposes into modules and a budget, implementers write modules, a reviewer step checks cross-file consistency | 3 | M to L | Needed beyond roughly a dozen files; raises cost so it must be gated by tier and token estimate | Efficiency agent; token economy [L: ECONOMY.md] |
| 10 | **Controlled relaxation of the Minecraft sandbox rules**: allow Brigadier/lifecycle commands, `paper-plugin.yml`, MavenLibraryResolver for an allow-list, soft-dependency APIs, and a declared "Connector" capability for outbound HTTP with a host allow-list | 4 | M (needs scanner, prompts, rules, tests) | These are the main ceiling on "advanced" [L: system prompt rules]. Safety scan today hard-blocks any network class [L: `scan.js`], so AI NPCs and Discord bridges are impossible | Security review; moderation design |
| 11 | **Companion packs**: generated resource pack and datapack as build outputs, with hosting and `ResourcePackInfo` delivery | 4 | M to L | Needed for any custom item look; see `RENDERS-AND-TEXTURES.md` | Asset pipeline and storage |
| 12 | **Honest capability labels per request**: classify a request against `GameSupport` capabilities and say "needs a human", "template preview" or "not possible server-side" before charging | 4 | S to M | Prevents fabricated promises (e.g. new Rust items, vanilla-client custom blocks) [V/S above]; fits owner's honesty rule | Routing agent's classifier |
| 13 | **Outdated-mod signals**: poll loader and game releases (tML tags, Jotunn, BepInExPack, Carbon, Oxide, Paper builds) and map them to `GameSupport.outdatedSignals` | 3 | S to M | Release feeds are all public APIs [V]; lifecycle agent owns warnings | Lifecycle agent |
| 14 | **Per-game eval suite** (about 30 prompts each plus 10 adversarial), designed but run only with an approved budget | 3 | M per game | The Minecraft service eval shows the method [L: `services/modbuilder/eval`] | Budget approval (owner's rule 5) |
| 15 | **Provenance and AI disclosure metadata** in each mod's manifest and listing | 2 | S | Modrinth bans primarily AI-generated public listings; Steam requires disclosure only for player-facing AI content [prior research; S: Steam policy Jan 2026] | Community agent |

### 9.1 Suggested build order
1. Items 12, 3 and 1 (cheap, and they improve every game immediately), with item 5's static validators.
2. Items 2, 4 and 6 together (spec, multi-file, dependencies), since they share the project model.
3. Items 7 and 10 (log-driven fixes; carefully scoped sandbox relaxation).
4. Items 9, 11 (planning, companion packs) once the earlier steps hold pass rates steady.
5. Live smoke tests (inside item 5) per game as each game moves toward `live`.

### 9.2 Things Cyrus should not promise
- New blocks or items for vanilla Minecraft clients; any new item or model for Rust; Palworld mods on a Linux image until the Windows-server question is settled; performance improvements it cannot measure.
- Public marketplace listings of AI-generated mods: Modrinth bans them [prior research, [Modrinth policy](https://modrinth.com/news/article/ai-policy-and-disclosures/)]. Position output as tooling for the customer's own server, and never auto-publish.

---

## 10. Unknowns and things to confirm

1. Official Palworld modding page (docs.palworldgame.com) was not opened; Windows-only server mods, `Info.json` field list and `InstallRule` come from hosting-provider summaries [S]. Confirm on the official page.
2. Whether Nxeon's Palworld image can run Windows server mods (Wine/Proton images exist for other Nxeon games [L: `lib/game-applier-specs/arkasa.ts`, `conan.ts`]).
3. Whether Zomboid's `Mods=` format in B42 uses a trailing backslash on every ID. Sources conflict between a hosting article (semicolons only) and a Build 42 guide (backslash). Test on a real 42.20 server.
4. Unity's licence terms for a hosted AssetBundle-building pipeline (Valheim) were not checked.
5. Whether uMod/Oxide plugin submissions have an AI policy. Page unreachable.
6. Paper API exact component names beyond those seen in the docs (`consumable`, `equippable`, etc.) were not enumerated; the Minecraft agent should regenerate from the jar.
7. The tModLoader 1.4.5 release date; only branch activity is known.
8. All effort estimates are guesses until the first game's knowledge pack is built.

---

## 11. Sources

Minecraft / Paper:
- Paper developer docs index: https://docs.papermc.io/paper/dev/api/
- Data components: https://docs.papermc.io/paper/dev/data-component-api/
- PDC: https://docs.papermc.io/paper/dev/pdc/
- Lifecycle and registries: https://docs.papermc.io/paper/dev/lifecycle/ , https://docs.papermc.io/paper/dev/registries/
- Paper plugins vs Bukkit: https://docs.papermc.io/paper/dev/getting-started/paper-plugins/
- Mob goals, dialogs, recipes, scheduler, Folia: https://docs.papermc.io/paper/dev/mob-goals/ , /dialogs/ , /recipes/ , /scheduler/ , /folia-support/
- Folia compatibility: https://github.com/PaperMC/Folia/wiki/Plugin-Compatibility
- Purpur: https://github.com/PurpurMC/Purpur
- Citizens: https://wiki.citizensnpcs.co/API ; Mindcraft: https://github.com/mindcraft-bots/mindcraft
- Nexo item models vs CMD: https://docs.nexomc.com/general-usage/faq/itemmodels-vs.-custommodeldata
- Minecraft Wiki (read-only reference; content is CC BY-NC-SA, not copied): Server.properties, Items_model_definition, Pack_format
- Local: `/opt/nxeon/services/modbuilder/{prompts.js,scan.js,precheck.js,route.js,rules/failure-rules.json,eval/}`, `/root/agent-notes/ai-modbuilder/RESEARCH.md`

Terraria:
- tModLoader wiki (raw markdown, GitHub): Home, Basic-tModLoader-Modding-Guide, Basic-Autoload, Intermediate-netcode, Starting-a-modded-server, Update-Migration-Guide, tModLoader-guide-for-developers
- tModLoader releases API: https://api.github.com/repos/tModLoader/tModLoader/releases ; branches API (1.4.5)
- TShock: https://github.com/Pryaxis/TShock , releases API
- Hosting guides for tML sides: FragNet, Falix, WinterNode, XGamingServer (see inline links)

Valheim:
- Jotunn repo and docs: https://github.com/Valheim-Modding/Jotunn ; tutorials `networkcompatibility.md`, `asset-creation.md`, `renderqueue.md`, `zones.md`, `rpcs.md`; `AssetUtils.cs`; release v2.30.0
- Thunderstore API (BepInExPack_Valheim 5.4.2351, Jotunn 2.30.2): https://thunderstore.io/c/valheim/api/v1/package/
- 1.0 coverage: https://hosthavoc.com/blog/valheim-1-0-update-server-owners

Rust:
- Oxide.Rust: https://github.com/OxideMod/Oxide.Rust ; Carbon: https://github.com/CarbonCommunity/Carbon ; Carbon.Documentation (MIT) pages cited inline
- Rust update cadence and plugin breakage: https://low.ms/blog/rust-wipe-schedule-2026 , https://gameserverkings.com/knowledge-base/rust/wipe-day-guide
- Facepunch skin rules: https://wiki.facepunch.com/rust/Getting_Skin_Accepted
- Not reachable (Cloudflare): umod.org documentation and guides

Palworld:
- UE4SS: https://docs.ue4ss.com/ ; PalSchema: https://github.com/Okaetsu/PalSchema , https://okaetsu.github.io/PalSchema/
- palmods.gg guides: choose-a-format, modding-kit
- Hosting summaries: XGamingServer, ConnectHosting, gamever.io (inline)

Project Zomboid:
- B42 modding guide: https://github.com/gotmayonase/pz-modding-guide
- Umbrella: https://github.com/PZ-Umbrella/Umbrella ; community modding: https://github.com/Project-Zomboid-Community-Modding/pz-community-modding ; FWolfe's older guide: https://github.com/FWolfe/Zomboid-Modding-Guide (B40/B41)
- Hosting/Build 42 articles: ConnectHosting, build42guide.wiki, Shockbyte (inline)
- Not reachable: pzwiki.net, pzfans.com (403)

Research on LLM code generation:
- VersiCode: https://arxiv.org/abs/2406.07411
- CloudAPIBench / DAG: https://arxiv.org/abs/2407.09726
- Mage: https://arxiv.org/abs/2605.07342

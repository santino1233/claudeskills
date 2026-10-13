# BD: GitHub mod-tools survey (ranked summary)

Date: 2026-10-12. Scope: tools and skill packs Cyrus could use for Minecraft and other games, found after universal-modder was added. Full per-game detail lives in the repo at docs/cyrus/onboarding/skills/games/ and docs/cyrus/onboarding/skills/tools/ (branch feature/cyrus-skills-universal-modder, commit de9b92e9ea); this file is the ranked summary.

Labels: V = verified this session from the GitHub search API / LICENSE file / cloned repo / fetched docs; U = not verified. All licence, last-push and star values in the tables are V (GitHub API 2026-10-12; `gh` is not installed so the unauthenticated REST API was used, which allows 60 core and about 10 search requests per minute, so some repos were checked by search only). Window: last push on or after 2026-04-12. Licence rule: MIT, Apache-2.0, BSD, CC0, ISC, MPL, Zlib usable; GPL, AGPL, LGPL, custom or unlicensed = reference only.

## 1. Ranked table

Effort: S = under a day, M = a few days, L = a week or more. Effort is a judgement (U).

### Adopt now

| Repo | Licence | Last push | What for / how | Effort | Seen in |
|---|---|---|---|---|---|
| PrismarineJS/mineflayer | MIT | 2026-10-11 | Scripted bot client. Cyrus's stress bot already uses it; add a survival-mode variant for mob and boss checks (finding 1 in MINECRAFT-FINDINGS.md). | S | minecraft, tools |
| luau-lang/luau | MIT | 2026-10-10 | MIT Luau language, analyser and type checker; run `luau-analyze` style checks on generated code (U for binary name). | S | roblox, tools |
| tModLoader/tModLoader | MIT | 2026-10-09 | MIT mod loader and ExampleMod; the primary target. Build via its own Mod Sources flow. | L | terraria, tools |
| MockBukkit/MockBukkit | MIT | 2026-10-11 | Unit-test generated Paper plugins against a mocked server in CI before they touch a real server; fastest gate in Test Flight. | M | minecraft, tools |
| Incendo/cloud | MIT | 2026-10-10 | MIT command framework; give generated plugins one command layer so codegen stops hand-rolling parsers. | S | minecraft |
| SpyglassMC/Spyglass | MIT | 2026-10-05 | Datapack language server and validator (mcdoc schemas); run headless to lint generated datapacks and resource-pack JSON. | M | minecraft, tools |
| jpenilla/run-task | Apache-2.0 | 2026-10-08 | Gradle tasks that start a Paper server for a plugin build; use in the build sandbox for smoke runs. | S | minecraft, tools |
| toxicity188/BetterModel | MIT | 2026-10-10 | Already Cyrus's custom-model engine (Blockbench models to server-side entities). Keep pinned; watch release notes. | S | minecraft, tools |
| PrismarineJS/mineflayer-pathfinder | MIT | 2026-10-06 | A-to-B navigation for bots; needed so a survival bot reaches the mob under test. | S | minecraft, tools |
| justarandomgeek/vscode-factoriomod-debug | MIT (LICENSE.txt) | 2026-10-01 | MIT VS Code extension: Lua language server data, debugger and mod packaging for Factorio; the toolkit that gives an agent proper API completions. | S | factorio, tools |
| luttje/glua-api-snippets | MIT | 2026-10-01 | MIT Lua Language Server stubs generated from the Garry's Mod wiki: gives an agent API completions. | S | garrys-mod, tools |

### Adopt later

| Repo | Licence | Last push | What for / how | Effort | Seen in |
|---|---|---|---|---|---|
| icsharpcode/ILSpy | MIT | 2026-10-11 | MIT .NET decompiler for local recon; decompiled output never enters git. | M | rimworld, terraria, tools, valheim |
| itzg/docker-minecraft-server | Apache-2.0 | 2026-10-11 | Apache-2.0 container with modpack, plugin and Paper support; compare with Cyrus's own server images. | M | minecraft, tools |
| pardeike/Harmony | MIT | 2026-10-11 | MIT runtime patching library used by essentially every Unity/.NET mod. | M | cities-skylines, rimworld, stardew-valley, terraria +2 |
| mindcraft-bots/mindcraft | MIT | 2026-10-03 | LLM-driven Mineflayer agent that plays survival; read for the tool/skill loop, possible LLM playtester later. | M | minecraft, tools |
| Querz/mcaselector | MIT | 2026-09-24 | Chunk selection and export or deletion on a world folder; ops tool for resetting generated test worlds. | M | minecraft, tools |
| maximegmd/CyberEngineTweaks | MIT | 2026-10-01 | MIT scripting framework with Lua and an in-game console; the general entry point for quick mods. | M | cyberpunk-2077, tools |
| GDRETools/gdsdecomp | MIT | 2026-10-11 | MIT Godot project recovery/reverse-engineering. | M | tools |
| LavaGang/MelonLoader | Apache-2.0 | 2026-10-06 | Apache-2.0 universal Unity mod loader (Mono and IL2CPP). | M | tools |
| Facepunch/Facepunch.Steamworks | MIT | 2026-10-09 | MIT C# Steamworks wrapper. | M | rust |
| Mojang/brigadier | MIT | 2026-07-17 | Command parser used by vanilla and Paper; MIT. | M | minecraft |
| thijsvanloef/palworld-server-docker | MIT | 2026-09-30 | MIT dedicated-server container; verification harness building block. | M | palworld, tools |
| UE4SS-RE/RE-UE4SS | MIT | 2026-10-12 | MIT injectable Lua scripting system and SDK generator for Unreal games. | M | palworld, tools |
| SamboyCoding/Cpp2IL | MIT | 2026-09-15 | MIT IL2CPP reverse tool. | M | tools |
| KSP-CKAN/CKAN | MIT (LICENSE.md) | 2026-10-01 | MIT mod manager and metadata index; its NetKAN repo (CC0) is a ready-made list of mod metadata. | M | kerbal-space-program, tools |
| nesrak1/UABEA | MIT | 2026-05-11 | MIT Unity asset bundle editor (GUI). | M | tools |
| FabricMC/fabric-example-mod | CC0-1.0 | 2026-10-10 | CC0 Fabric template for the client-mod lane. | M | minecraft |
| ThirteenAG/Ultimate-ASI-Loader | MIT | 2026-10-10 | MIT proxy DLL that loads .asi plugins; common bootstrap for old titles. | M | fallout-3, fallout-new-vegas, gta-iv, gta-v +1 |
| ebkr/r2modmanPlus | MIT | 2026-10-08 | MIT mod manager built on the Thunderstore API; reference for resolving dependency graphs. | M | tools, valheim |
| JohnnyMorganz/StyLua | MPL-2.0 | 2026-10-11 | MPL-2.0 formatter. | M | roblox, tools |
| rojo-rbx/rojo | MPL-2.0 | 2026-10-06 | MPL-2.0 filesystem-to-Studio sync; lets generated code live in git. | M | roblox, tools |
| K0lb3/UnityPy | MIT | 2026-10-05 | MIT Python Unity asset reader for scripted recon on the build node. | M | tools, valheim |
| PrismarineJS/node-minecraft-protocol | BSD-3-Clause | 2026-10-06 | Protocol layer under Mineflayer; use directly only for protocol-level load tests. | M | minecraft |
| scripthookvdotnet/scripthookvdotnet | Zlib | 2026-10-08 | Zlib-licensed ASI plugin that runs C# scripts; the safest scripting surface for single-player. | M | gta-v, tools |
| roblox-ts/roblox-ts | MIT | 2026-10-05 | MIT TypeScript-to-Luau compiler. | M | roblox |
| atenfyr/UAssetGUI | MIT | 2026-08-31 | MIT Unreal asset editor. | M | tools |
| packwiz/packwiz | MIT | 2026-09-06 | MIT modpack tool (Modrinth + CurseForge); only if Cyrus ships client modpacks. | M | minecraft, tools |
| REDxEYE/SourceIO | MIT | 2026-10-11 | MIT Blender add-on for Source models/materials/maps; asset-pipeline reference only on content the owner owns. | M | garrys-mod, left-4-dead-2, tools |
| lune-org/lune | MPL-2.0 | 2026-10-11 | MPL-2.0 standalone Luau runtime: run test scripts outside Studio. | M | roblox, tools |
| Pathoschild/StardewMods | MIT | 2026-05-10 | MIT collection of well-known mods; real-world SMAPI mod source to learn from. | M | stardew-valley |
| misode/misode.github.io | MIT | 2026-09-18 | Reference generators for loot tables, worldgen, recipes; mine schemas and edge cases, not the UI. | M | minecraft, tools |
| TES5Edit/TES5Edit | MPL-2.0 | 2026-10-11 | MPL-2.0 xEdit family (FO3Edit is a build target, U); record-level inspection and conflict checks. | L | fallout-3, fallout-4, fallout-new-vegas, skyrim +2 |
| FabricMC/fabric-loader | Apache-2.0 | 2026-08-28 | Apache-2.0 loader (runtime dependency of Fabric mods). | M | minecraft |
| PolyhedralDev/Terra | MIT | 2026-09-28 | Config-driven worldgen platform (YAML packs) for Paper; candidate engine for generated worlds. Compare to vanilla worldgen datapacks first. | M | minecraft, tools |
| Kampfkarren/selene | MPL-2.0 | 2026-10-01 | MPL-2.0 linter. | M | roblox, tools |
| craftablescience/VPKEdit | MIT | 2026-09-15 | MIT VPK reader/writer for pack tooling. | M | garrys-mod, left-4-dead-2, tools |
| vawser/Smithbox | MIT | 2026-10-01 | MIT data editor for Elden Ring, Armored Core VI, Sekiro, DS3 (param, map, text). | M | elden-ring, tools |
| arkmanager/ark-server-tools | MIT | 2026-07-11 | MIT Linux server manager for ASE (ASE only). | M | ark |
| nesrak1/AssetsTools.NET | MIT | 2026-09-10 | MIT reader/writer for Unity asset bundles; build custom asset bundles. | M | terraria, tools, valheim |
| GodotModding/godot-mod-loader | CC0-1.0 | 2026-08-21 | CC0 mod loader for GDScript-based Godot games. | M | tools |
| rwmt/Multiplayer | MIT | 2026-08-03 | MIT multiplayer mod; large reference of Harmony patch patterns. | M | rimworld |
| FabianFG/CUE4Parse | Apache-2.0 | 2026-10-11 | Apache-2.0 Unreal archive and asset parser. | M | tools |
| garyttierney/me3 | Apache-2.0 | 2026-09-30 | Apache-2.0 framework for modding and instrumenting FromSoftware games; the active loader, already used in a KB case. | M | elden-ring, tools |
| wiremod/wire | Apache-2.0 | 2026-10-10 | Apache-2.0 large addon; reference for GLua architecture (Wiremod is also a content ecosystem). | M | garrys-mod |
| JohnnyMorganz/luau-lsp | MIT | 2026-10-10 | MIT language server for Luau. | M | roblox, tools |
| WesJD/AnvilGUI | MIT | 2026-10-12 | MIT anvil text-input GUI. | M | minecraft |
| jac3km4/redscript | MIT | 2026-06-09 | MIT compiler/decompiler toolkit for redscript. | M | cyberpunk-2077, tools |
| atenfyr/UAssetAPI | MIT | 2026-08-31 | MIT Unreal .uasset library. | M | tools |
| UpliftGames/wally | MPL-2.0 | 2026-09-26 | MPL-2.0 package manager. | M | roblox |
| rojo-rbx/rokit | MIT | 2026-09-27 | MIT toolchain manager. | M | roblox |
| LlamaLad7/MixinExtras | MIT | 2026-08-28 | MIT companion library for Mixin injectors in Fabric/NeoForge mods. | M | minecraft |
| NichtStudioCode/InvUI | MIT | 2026-09-26 | MIT inventory GUI library for Paper; generated menus. | M | minecraft |
| OxideMod/Oxide.Rust | MIT | 2026-10-11 | MIT Rust extension for Oxide: the primary hook layer for server plugins. | M | rust, tools |
| FabricMC/fabric-loom | MIT | 2026-10-10 | MIT Fabric build plugin. | M | minecraft |
| Revxrsal/Lamp | MIT | 2026-10-07 | Alternative annotation-based command framework (MIT). | M | minecraft |
| nothub/mrpack-install | MIT | 2026-09-02 | MIT installer for .mrpack servers. | M | minecraft, tools |
| mcbeet/beet | MIT | 2026-10-02 | Python pack development kit (datapack + resource pack pipeline); useful if generation moves from templates to a build graph. | M | minecraft, tools |
| elBukkit/MagicPlugin | MIT | 2026-10-11 | MIT spell and wand plugin with a large config schema; template for an ability component library. | M | minecraft |
| misode/deepslate | MIT | 2026-09-27 | Render structures and worldgen in the browser for preview thumbnails. | M | minecraft, tools |
| DenizenScript/Denizen | MIT | 2026-10-07 | MIT NPC and event scripting language for Spigot; a safe, sandboxed target for LLM-written behaviour instead of free-form Java. | M | minecraft |
| trumank/retoc | MIT | 2026-08-13 | MIT Unreal IoStore packing/unpacking. | M | tools |
| pardeike/HarmonyRimWorld | MIT | 2026-08-16 | MIT mod that installs Harmony for all other mods. | M | rimworld |
| Valheim-Modding/Jotunn | MIT | 2026-09-27 | MIT library for custom items, pieces, recipes, localisation; the sensible abstraction for generated Valheim content. | M | tools, valheim |
| PrismarineJS/mineflayer-statemachine | MIT | 2026-07-08 | Behaviour-tree style bot scripting. | M | tools |
| ClaudeMetz/FactoryPlanner | MIT | 2026-10-11 | MIT mod; large real-world control-stage example. | M | factorio |
| WopsS/RED4ext.SDK | MIT | 2026-07-30 | MIT SDK for C++ plugins. | M | cyberpunk-2077, tools |
| psiberx/cp2077-tweak-xl | MIT | 2026-08-20 | MIT TweakDB editing mod. | M | cyberpunk-2077 |
| fpsacha/zomboid-control-panel | MIT | 2026-10-12 | MIT web admin panel and RCON for dedicated servers; ops reference. | M | project-zomboid, tools |
| modmuss50/mod-publish-plugin | MIT | 2026-09-21 | MIT Gradle publisher to Modrinth/CurseForge for the client-mod lane. | M | minecraft, tools |
| psiberx/cp2077-codeware | MIT | 2026-09-20 | MIT library/framework for script mods. | M | cyberpunk-2077 |
| psiberx/cp2077-archive-xl | MIT | 2026-10-08 | MIT mod that lets mods add resources without conflicts. | M | cyberpunk-2077 |
| jacobsjo/mc-datapack-map | MIT | 2026-10-11 | Biome map for worldgen datapacks; visual check of the Gloam-style dimensions. | M | minecraft, tools |
| WeaponMechanics/WeaponMechanics | MIT | 2026-06-17 | MIT config-driven weapon framework (hitscan, projectiles, spread, recoil). Compare with building hitscan/beam/area_blast designer components (MINECRAFT-FINDINGS.md finding 5); mine its mechanics list first. | M | minecraft |
| Okaetsu/PalSchema | MIT | 2026-10-03 | MIT JSON-driven mods (items, pals, spawns) on top of UE4SS: very LLM-friendly data format. | M | palworld, tools |
| SpaceWarpDev/SpaceWarp | MIT | 2026-10-12 | MIT C# modding API for KSP2. | M | kerbal-space-program, tools |
| KSP-CKAN/NetKAN | CC0-1.0 | 2026-10-12 | CC0 metadata for the CKAN index. | M | kerbal-space-program, tools |
| IceCoffee1024/7DaysToDie-ServerKit | MIT | 2026-07-07 | MIT dedicated-server mod with REST APIs; verification hook idea. | M | 7-days-to-die |
| ArkServerApi/AsaApi | MIT | 2026-10-04 | MIT server plugin API for ARK: Survival Ascended. | M | ark, tools |
| Roblox/jest-roblox | MIT | 2026-10-02 | MIT testing framework for Luau. | M | roblox, tools |
| Drownek/plugwright | MIT | 2026-10-04 | End-to-end test framework for Paper plugins in TS/JS; evaluate against Cyrus's own Test Flight before adopting (45 stars, young). | M | minecraft, tools |
| sosadly/blockbench-mcp | MIT | 2026-09-21 | MCP server plus Blockbench plugin so an agent drives Blockbench; evaluate for the model studio. | M | minecraft, tools |
| DonovanMods/donovan-7d2d-modlets | MIT | 2026-07-19 | MIT collection of modlets; real XML patch examples. | M | 7-days-to-die |
| openzomboid/log-extender | MIT | 2026-10-10 | MIT mod for administering servers (log extension). | M | project-zomboid |
| ArranzCNL/SkyrimSE-Plugin-Template | MIT | 2026-08-10 | MIT CMake template for SKSE plugins. | M | skyrim, tools |
| Brov3r/Avrix | MIT | 2026-10-06 | MIT Java mod loader using Mixins (15 stars). | M | project-zomboid |
| lveillard/factorio-ai-companion | MIT | 2026-09-13 | MIT, 14 stars: AI companions via MCP using 51 RCON commands; relevant to a live verification oracle (not read). | M | factorio, tools |
| rcav8tr/CS2-Modding-Instructions | MIT | 2026-07-01 | MIT instructions for setting up and building CS2 mods; clone-worthy knowledge candidate (13 stars, not read). | M | cities-skylines |
| Pollux12/gmod-glua-ls | MIT | 2026-09-12 | MIT GLua language server (12 stars, young). | M | garrys-mod, tools |
| vietnd69/dst-api-webdocs | MIT | 2026-05-27 | MIT API documentation generated from the game's scripts; docs only. The game scripts repo it links to are game files and are NOT used. | M | dont-starve-together |
| mayor-modder/Cities2-MCP | MIT | 2026-09-18 | MIT MCP plus agent skills for CS2 knowledge and mod project workflows (9 stars, not read). | M | cities-skylines |
| KSPModdingLibs/KSPBuildTools | MIT | 2026-05-15 | MIT build tools for KSP1 mods. | M | kerbal-space-program |
| epinter/skse-clibng-template | CC0-1.0 | 2026-08-27 | CC0 SKSE plugin template using CommonLibSSE-NG; permissive starting point. | M | skyrim, tools |
| liminalwarmth/modkit-StardewValley | MIT | 2026-09-10 | MIT bootstrap template and rules file for building Stardew mods with an AI agent (3 stars, not read). | M | stardew-valley |
| PZ-Umbrella/torch-zomboid | MIT | 2026-09-29 | MIT Python generator of Lua type stubs for the PZ API. | M | project-zomboid, tools |
| Svi-ra/pz-mcp-server | MIT | 2026-08-21 | MIT MCP server for Build 42 mod development (2 stars; not read). | M | project-zomboid |
| Lakuna/RimWorld-Mod-Template | MIT | 2026-04-25 | MIT template for Harmony mods (1 star; verify quality before relying on it). | M | rimworld |
| LichByte/TabbedOut | MIT | 2026-07-29 | Tiny MIT NVSE plugin; example plugin layout. | M | fallout-new-vegas |
| ExtReMLapin/ts4-unofficial-fixes | MIT | 2026-10-04 | MIT script mods that fix gameplay bugs, one .ts4script per fix; a real packaging example. | M | sims-4 |
| SalyyS1/pluginscope | Apache-2.0 | 2026-08-23 | Apache-2.0 static audits of plugin packaging and shading (0 stars, not read). | M | tools |

### Reference only

| Repo | Licence | Last push | What for / how | Effort | Seen in |
|---|---|---|---|---|---|
| ValveSoftware/source-sdk-2013 | Valve SDK licence (NOASSERTION) | 2026-10-10 | Valve SDK licence; reference for engine behaviour. | - | left-4-dead-2 |
| BepInEx/BepInEx | LGPL-2.1 | 2026-09-20 | LGPL-2.1 loader; players install the release, we never vendor its source. | - | tools, valheim |
| AssetRipper/AssetRipper | GPL-3.0 | 2026-10-10 | GPL-3.0 extractor; it writes game assets to disk, so use only on the owner's own copy and never commit its output. | - | tools, valheim |
| JannisX11/blockbench | GPL-3.0 | 2026-10-10 | Model editor, GPL-3.0; run as a tool in the model studio, do not vendor. | - | minecraft, tools |
| ThirteenAG/GTAIV.EFLC.FusionFix | GPL-3.0 | 2026-10-09 | GPL-3.0 fix pack; study only. | - | gta-iv |
| Minestom/Minestom | Apache-2.0 | 2026-10-11 | Apache-2.0 server framework; reference for lightweight instanced mini-game servers, not a Paper replacement. | - | minecraft |
| 4sval/FModel | GPL-3.0 | 2026-10-11 | GPL-3.0 Unreal archive explorer. | - | tools |
| ThirteenAG/WidescreenFixesPack | MIT | 2026-10-09 | MIT set of widescreen/ini fixes; patch-style plugin examples. Contains no game files (U) but is a patch collection, not a framework. | - | gta-iv |
| ModOrganizer2/modorganizer | GPL-3.0 | 2026-10-05 | GPL-3.0 mod manager; reference for load-order and VFS behaviour. | - | fallout-3, fallout-4, fallout-new-vegas, skyrim +1 |
| Pryaxis/TShock | GPL-3.0 | 2026-10-11 | GPL-3.0 server wrapper with anti-cheat and permissions; reference for server-side moderation design. | - | terraria |
| Pathoschild/SMAPI | LGPL-3.0 | 2026-09-28 | LGPL-3.0 modding API; installed by players, not vendored. Its docs define the mod manifest. | - | stardew-valley, tools |
| neoforged/NeoForge | LGPL-2.1 | 2026-10-11 | LGPL-2.1 loader; client-mod lane runtime dependency, reference only for vendoring. | - | minecraft |
| loot/loot | GPL-3.0 | 2026-10-11 | GPL-3.0 load-order sorter; reference. | - | fallout-3, fallout-4, skyrim, starfield +1 |
| Nexus-Mods/Vortex | GPL-3.0 | 2026-10-11 | GPL-3.0 mod manager. | - | skyrim, tools |
| Norbyte/bg3se | Commons Clause (not OSI) | 2026-10-10 | Script Extender under the Commons Clause (not OSI/permissive). Players install it; Cyrus never vendors it. | - | baldurs-gate-3, tools |
| SkriptLang/Skript | GPL-3.0 | 2026-10-11 | GPL-3.0 scripting plugin; reference for what server owners expect to be scriptable. | - | minecraft |
| lucko/spark | GPL-3.0 | 2026-10-07 | Reference profiler for TPS and lag. GPL-3.0: run the released plugin jar on test servers if legal agrees; never bundle or vendor it. | - | minecraft, tools |
| Facepunch/garrysmod | none | 2026-09-16 | No licence file: read-only reference for base game Lua. | - | garrys-mod |
| RimSort/RimSort | GPL-3.0 | 2026-10-10 | GPL-3.0 load-order manager; reference. | - | rimworld |
| WilliamVenner/gmpublisher | GPL-3.0 | 2026-07-29 | GPL-3.0 Workshop publisher. | - | garrys-mod, tools |
| FabricMC/yarn | CC0-1.0 | 2026-05-27 | CC0 mappings, last push 2026-05; Mojang names are the better default now. | - | minecraft |
| WolvenKit/WolvenKit | GPL-3.0 | 2026-10-10 | GPL-3.0 community mod editor; reference and run-only tool, never vendored. | - | cyberpunk-2077, tools |
| alliedmodders/sourcemod | none detected by API | 2026-10-08 | SourceMod (for other Source games); API shows no detected licence. | - | garrys-mod, left-4-dead-2 |
| PrismarineJS/minecraft-data | none (no LICENSE file) | 2026-10-11 | Registry data extracted from the game; no LICENSE file at the repo root. npm dependency use only, never vendored. | - | minecraft, tools |
| mockingbirdnest/Principia | MIT | 2026-10-10 | MIT gravity mod; large C++/C# reference, but it ships native code beyond Cyrus's scope. | - | kerbal-space-program |
| carrot-hu23/dst-admin-go | GPL-3.0 | 2026-08-27 | GPL-3.0 server panel; ops reference. | - | dont-starve-together |
| ComunidadAylas/PackSquash | AGPL-3.0 | 2026-10-11 | Resource-pack optimiser (AGPL-3.0). Run unmodified as an external binary on the build node if legal agrees; never vendor. | - | minecraft, tools |
| xNVSE/NVSE | none (no LICENSE file) | 2026-09-27 | The current script extender; no licence file, so reference only. | - | fallout-new-vegas, tools |
| Roblox/creator-docs | CC-BY-4.0 | 2026-10-10 | CC-BY-4.0 documentation (attribution content licence); reference, not code. | - | roblox |
| ZeqMacaw/Crowbar | custom (NOASSERTION) | 2026-08-08 | Licence flagged non-standard by the API. | - | garrys-mod, left-4-dead-2, tools |
| oraxen/oraxen | custom (LICENSE.md) | 2026-09-30 | Custom items and resource-pack generator, custom licence (not OSI). Design reference only. | - | minecraft |
| CitizensDev/Citizens2 | OSL-3.0 | 2026-10-10 | NPC API under OSL-3.0 (not on the permissive list). Reference only. | - | minecraft |
| misode/mcmeta | none | 2026-10-06 | Processed copies of Mojang's generated data and assets: ships game-derived data. Do not vendor; fetch from the game jar at build time instead. | - | minecraft, tools |
| NeighTools/UnityDoorstop | LGPL-2.1 | 2026-09-26 | LGPL-2.1 managed-code injector used by BepInEx. | - | tools |
| alliedmodders/metamod-source | custom (NOASSERTION) | 2026-10-12 | Custom licence in the API. | - | left-4-dead-2 |
| jasonjgardner/blockbench-mcp-plugin | GPL-3.0 | 2026-10-11 | Larger Blockbench MCP plugin (506 stars) but GPL-3.0: reference only. | - | minecraft, tools |
| BepInEx/Il2CppInterop | LGPL-3.0 | 2026-07-08 | LGPL-3.0 IL2CPP interop used by BepInEx 6. | - | tools |
| clusterio/clusterio | custom (NOASSERTION) | 2026-10-11 | Multi-server clustering for Factorio; licence flagged non-standard by the API. | - | factorio |
| satisfactorymodding/SatisfactoryModLoader | GPL-3.0 | 2026-09-26 | GPL-3.0 loader; reference. | - | satisfactory, tools |
| Animated-Java/animated-java | custom (NOASSERTION) | 2026-10-09 | Blockbench to datapack animation exporter; custom licence flagged by the API. | - | tools |
| Xiao-MoMi/craft-engine | GPL-3.0 | 2026-10-11 | Custom blocks/items/furniture engine, GPL-3.0. Design reference for pack-generation features. | - | minecraft |
| HangarMC/Hangar | MIT | 2026-10-11 | MIT plugin repository for Paper; reference for how plugins are published and versioned. | - | minecraft, tools |
| MagmaGuy/EliteMobs | GPL-3.0 | 2026-10-02 | GPL-3.0 custom-boss RPG plugin; reference for boss and dungeon design. | - | minecraft |
| thunderstore-io/Thunderstore | AGPL-3.0 | 2026-10-09 | AGPL-3.0 Thunderstore server. | - | tools |
| spacechase0/StardewValleyMods | custom (NOASSERTION) | 2026-09-01 | Custom licence flagged by the API; read only. | - | stardew-valley |
| Mutagen-Modding/Mutagen | GPL-3.0 | 2026-10-06 | GPL-3.0 record library; Fallout 3 support not confirmed (U). | - | fallout-3, fallout-4, skyrim, tools |
| FPtje/GLuaFixer | LGPL-2.1 | 2026-09-12 | LGPL-2.1 GLua linter; run as a tool in CI, do not vendor. | - | garrys-mod, tools |
| joelday/papyrus-lang | custom (NOASSERTION) | 2026-09-23 | Papyrus language tools for editors; licence reported as non-standard by the API, check before use. | - | fallout-4, skyrim |
| Mutagen-Modding/Spriggit | GPL-3.0 | 2026-07-10 | GPL-3.0 text serialisation of plugins for git diffs; idea source. | - | fallout-4, skyrim, starfield, tools |
| modrinth/minotaur | LGPL-2.1 | 2026-09-16 | LGPL-2.1 Modrinth Gradle publisher. | - | tools |
| CarbonCommunity/Carbon | GPL-3.0 | 2026-10-11 | GPL-3.0 alternative loader; reference. | - | rust, tools |
| PZ-Umbrella/Umbrella | none | 2026-09-28 | Type stubs for the modding API; no licence file, so read-only. | - | project-zomboid |
| CFC-Servers/GLuaTest | GPL-3.0 | 2026-10-10 | GPL-3.0 unit-test framework for GLua; reference. | - | garrys-mod, tools |
| satisfactorymodding/ficsit-cli | GPL-3.0 | 2026-07-09 | GPL-3.0 mod manager CLI. | - | satisfactory, tools |
| krzychu124/Traffic | none | 2026-09-22 | Active CS2 traffic mod, but no licence: read only. | - | cities-skylines |
| Project-Zomboid-Community-Modding/pz-community-modding | GPL-3.0 | 2026-08-12 | GPL-3.0 community docs; reference. | - | project-zomboid |
| Avick3110/houseCARL | GPL-3.0 | 2026-10-12 | GPL-3.0 load-order data access for Claude; idea source. | - | skyrim |
| satisfactorymodding/Documentation | none | 2026-10-07 | Docs repo with no licence; read-only. | - | satisfactory |
| Nexus-Mods/node-nexus-api | GPL-3.0 | 2026-10-07 | GPL-3.0 Nexus API client. | - | tools |
| Fixed-Seed/game-changer | MIT | 2026-10-10 | MIT fork of universal-modder with a similar knowledge base; mostly duplicates what is already vendored (see Skills section below). | - | minecraft |
| satisfactorymodding/FICSIT-Fred | MIT | 2026-08-04 | MIT Discord bot; low value. | - | satisfactory |
| bj0urne/Fallout3-TEMPO | MIT | 2026-10-11 | Small MIT FOSE plugin; example of a modern FOSE plugin layout. | - | fallout-3 |
| dnavaria/sims4ai | MIT | 2026-04-26 | MIT LLM-driven Sims 4 characters (Ollama or Anthropic); design reference (last push 2026-04-26, near the window edge). | - | sims-4 |
| TGWA0/RustPluginTemplate | none | 2026-07-10 | Template with no licence file. | - | rust |

### Reject

| Repo | Licence | Last push | What for / how | Effort | Seen in |
|---|---|---|---|---|---|
| Perfare/Il2CppDumper | MIT | 2024-08-18 | MIT IL2CPP dumper; last push 2024-08. | - | tools |
| sinai-dev/UnityExplorer | GPL-3.0 | 2023-03-13 | GPL-3.0 in-game Unity inspector; archived. | - | tools |
| soulsmods/ModEngine2 | MIT (ARCHIVED) | 2024-07-19 | Archived MIT loader; replaced by me3. | - | elden-ring |
| Norbyte/lslib | MIT | 2026-03-31 | MIT LSLib (LSX/LSF/GR2 conversion), last push 2026-03-31: 12 days outside the window, but it is the de facto tool. Near-miss; re-check before use. | - | baldurs-gate-3, tools |
| cheahjs/palworld-save-tools | MIT | 2024-10-06 | MIT, last push 2024-10: stale. | - | palworld |
| dexyfex/CodeWalker | none | 2025-04-11 | No licence, last push 2025-04; also an asset explorer for game files. | - | gta-v |
| soulsmods/DSMapStudio | MIT | 2025-05-25 | MIT map editor, last push 2025-05: stale. | - | elden-ring |
| niftools/nifskope | custom (NOASSERTION) | 2024-06-03 | Mesh viewer, last push 2024-06 and licence flagged non-standard. | - | skyrim |
| trumank/repak | Apache-2.0 | 2026-02-20 | Apache-2.0 Unreal .pak CLI/library (last push 2026-02, stale). | - | tools |
| Roblox/studio-rust-mcp-server | MIT (ARCHIVED) | 2026-04-03 | MIT but archived 2026-04-03: Roblox's own Studio MCP server is no longer maintained there. | - | roblox |
| WopsS/RED4ext | MIT | 2026-03-09 | MIT loader, but last push 2026-03-09 is just outside the window; check the successor repo before use. | - | cyberpunk-2077 |
| Ryan-rsm-McKenzie/CommonLibSSE | MIT | 2023-07-20 | MIT but last push 2023-07: stale. | - | skyrim |
| JKAnderson/SoulsFormats | GPL-3.0 (ARCHIVED) | 2025-05-26 | Archived GPL-3.0 format library. | - | elden-ring |
| kleientertainment/ds_mod_tools | custom (NOASSERTION) | 2023-05-14 | Klei's tools: custom licence, last push 2023. | - | dont-starve-together |
| Orvid/Champollion | LGPL-3.0 | 2023-10-17 | LGPL-3.0 Papyrus decompiler, last push 2023: stale and copyleft. | - | fallout-4, skyrim, tools |
| Orvid/Caprica | MIT | 2024-06-18 | MIT Papyrus compiler, last push 2024-06: stale. | - | fallout-4, skyrim |
| Starfield-Reverse-Engineering/CommonLibSF | GPL-3.0 (ARCHIVED) | 2025-09-16 | Archived GPL-3.0. | - | starfield |
| Ryan-rsm-McKenzie/CommonLibF4 | MIT | 2025-11-14 | MIT but last push 2025-11-14: outside the 6-month window. | - | fallout-4 |
| boformer/CitiesHarmony | MIT | 2023-01-14 | MIT Harmony provider for CS1, last push 2023-01: stale. | - | cities-skylines |
| mcbeet/bolt | MIT | 2025-12-08 | Archived MIT scripting layer. | - | tools |
| jazzisparis/JIP-LN-NVSE | GPL-3.0 | 2024-06-10 | GPL-3.0 and last pushed 2024: stale and copyleft. | - | fallout-new-vegas |
| mcbeet/mecha | MIT | 2025-12-08 | Archived MIT command parser/linter. | - | tools |
| soulsmods/Paramdex | none | 2026-03-06 | Param definitions without a licence file; reference. | - | elden-ring |
| OxideMod/Oxide.Core | MIT | 2026-03-04 | MIT, last push 2026-03-04 (outside window). | - | rust |
| OxideMod/Oxide.CSharp | MIT | 2026-03-04 | MIT, last push 2026-03-04 (outside window). | - | rust |

### Skill packs and knowledge bases (cloned read-only to /tank/cyrus-library-incoming/skills-reference/, none vendored)

| Repo | Licence | Last push | Verdict | Notes (V from the clone) |
|---|---|---|---|---|
| MrPippi/MJP-Paper-Skills | MIT | 2026-10-11 | Adopt now | 31 compile-verified Paper/NMS skills; safe-teleport and disposable-world map to MINECRAFT-FINDINGS items 2 and 4 |
| Jahrome907/minecraft-agent-skills | MIT | 2026-10-11 | Adopt now | 13 Minecraft skills incl. datapack, resource-pack, testing, world-generation |
| WingedGuardian/skyrimvr-claude-toolkit | MIT | 2026-10-12 | Adopt later | 13 Skyrim skills + tools; contains hooks/setup scripts, skills only |
| HardHeadHackerHead/valheim-claude-tools | MIT | 2026-10-12 | Adopt later | 8 Valheim skills; has a prebuilt DLL in dist/ (do not vendor) |
| MSayib/roblox-dev-skill | MIT | 2026-10-11 | Adopt later | 1 SKILL + 14 references; pipe-to-shell installers (do not vendor) |
| gamedev-skills/awesome-gamedev-agent-skills | Apache-2.0 | 2026-10-09 | Adopt later | 74 engine-generic skills (Godot/Unity/Unreal/web) |
| OGMatrix/mcmodding-mcp | MIT | 2026-08-28 | Reference only | an MCP service, not prose |
| Fixed-Seed/game-changer | MIT | 2026-10-10 | Reject | fork of universal-modder, duplicates the vendored set |

## 2. Minecraft top 10

1. **MockBukkit (MIT, V)** - mocked-server unit tests for generated Paper plugins; add as a CI stage before Test Flight (S-M).
2. **Mineflayer + mineflayer-pathfinder (MIT, V)** - build the survival-mode scripted player (MINECRAFT-FINDINGS item 1); mindcraft (MIT, V) shows an LLM-driven survival loop worth reading.
3. **Spyglass (MIT, V)** - run headless to lint every generated datapack and resource-pack JSON before it reaches a server.
4. **MJP-Paper-Skills + Jahrome907 skills (MIT, V)** - 44 Paper/datapack/pack skills; vendor after sign-off into docs/third-party; its safe-teleport skill answers finding 4.
5. **WeaponMechanics (MIT, V)** - config-driven hitscan/projectile weapons; mine its mechanics list before building the three new designer components (finding 5), or adopt it as a runtime engine.
6. **BetterModel (MIT, V)** - already Cyrus's model engine; keep pinned. Oraxen (custom licence) and craft-engine (GPL) are reference only.
7. **Terra (MIT, V)** - YAML-configured worldgen platform for Paper; compare against vanilla worldgen datapacks for the Gloam-style dimensions. Iris (GPL) reference only.
8. **Denizen / MagicPlugin (MIT, V)** - constrained scripting and spell configs: a safer target for LLM-written behaviour than free-form Java.
9. **Cloud command framework + run-task (MIT/Apache, V)** - standardise generated plugin commands and let the build sandbox smoke-run a Paper server.
10. **itzg/docker-minecraft-server (Apache-2.0, V) + Paper Fill API (V)** - reproducible server images and a keyless download API for exact Paper builds.

Reference only (do not vendor): spark (GPL-3.0; run the released jar on test servers only), PackSquash (AGPL-3.0; external binary only), Blockbench (GPL-3.0), Citizens2 (OSL-3.0), EliteMobs/Skript (GPL-3.0), NeoForge and Minotaur (LGPL-2.1). Rejected: misode/mcmeta and PrismarineJS/minecraft-data (ship game-derived data), mecha/bolt (archived), nbtlib (2022), yuniko-software/minecraft-mcp-server (last push 2026-04-04, 8 days outside the window).

## 3. Knowledge and skills worth vendoring like universal-modder

Permissive and active, ranked: MJP-Paper-Skills, Jahrome907/minecraft-agent-skills, then (only when the game is chosen) skyrimvr-claude-toolkit, valheim-claude-tools, roblox-dev-skill, awesome-gamedev-agent-skills, Cities2-MCP and CS2-Modding-Instructions, modkit-StardewValley, pz-mcp-server. Vendor skills and prose only; exclude installers, hooks, prebuilt binaries and tools directories. Owner sign-off first. The last four were not cloned or read (U).

## 4. Part C notes (V where fetched)

- Modrinth API: unique User-Agent mandatory, 300 requests per minute per IP (V).
- CurseForge API: x-api-key from the Studios console, non-game-developers must apply, per-file allowModDistribution flag can forbid third-party redistribution (V).
- Nexus Mods API policy: register public apps, no mass-fetch to rehost, never store users' keys on your servers (V).
- Thunderstore: community package list works keyless (HTTP 200, very large) (V); write API and limits (U).
- Paper Fill v3 downloads API works keyless; Paper is at 26.3 (V).
- Pack formats: Modrinth .mrpack and CurseForge manifest, packwiz (MIT, V) and mrpack-install (MIT, V) exist; the .mrpack format page 404ed (U).

## 5. Could not verify (U)

- Minecraft usage guidelines (fetch timed out); Steam Workshop, mod.io and uMod terms (not fetched; uMod site returned 403 to a script).
- CommonLibSSE-NG and SKSE/F4SE/SFSE licences and repos (not found by the API search); xNVSE has no LICENSE file.
- Whether GPL spark/PackSquash may be run unmodified inside a paid service (needs legal).
- tModLoader, Garry's Mod, Roblox, Rust, Palworld, ARK and most other loader statements beyond licences and dates are background knowledge (U) pending a real vertical slice.
- Skill repos Cities2-MCP, CS2-Modding-Instructions, modkit-StardewValley, pz-mcp-server, brokkr and the MCP servers in the Minecraft table were not read.
- Searches for Terraria, GTA IV, FNV and Satisfactory agent skills partly hit the unauthenticated search rate limit.

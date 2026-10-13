# A2. Data pack studio: formats, loading, validation, build-vs-adopt

Date 2026-10-10. Labels: VERIFIED (url) = opened; UNVERIFIED = memory/inference.

## 1. Formats per version
- Folder names are **singular** in current versions: `function/`, `loot_table/`, `recipe/`, `advancement/`, `tags/item|block|entity_type/`; content dirs `worldgen/`, `dimension/`, `enchantment/`, `damage_type/`, `jukebox_song/`. VERIFIED (https://minecraft.wiki/w/Data_pack). The plural-to-singular rename happened in 1.21 (1.21.1 already singular; pre-1.21 plural) UNVERIFIED for exact release; Cyrus' floor is 1.21.1 so it only ever needs singular.
- `pack.mcmeta`: since 1.21.9 uses `min_format` / `max_format` as `[major, minor]` (e.g. `[88, 0]`) and supports `overlays` for per-version content. VERIFIED (same URL). Older (<1.21.9) use `pack_format` (+ `supported_formats`): UNVERIFIED detail.
- Data pack format numbers (VERIFIED, minecraft.wiki/w/Pack_format, via E-versions.md): 1.21.1 = 48; 1.21.4 = 61; 1.21.7-8 = 81; 1.21.9-10 = 88.0; 1.21.11 = 94.1; 26.1-26.1.2 = 101.1; 26.2 = 107.1; 26.3 = 121.0.
- Practical consequence: Cyrus' supported set 1.21.1 / 1.21.4 / 1.21.8 / 1.21.11 (+26.x) spans **four different datapack schemas and two mcmeta styles**. Use `overlays` (VERIFIED to exist) only where one pack must span versions; otherwise emit one pack per target version from one version-neutral spec.
- JSON schema drift that matters (UNVERIFIED, must be proven by validating against each version): recipe `result` object + item-stack components (1.20.5+), loot function names/predicates (components replaced NBT in 1.20.5), enchantment data-driven format (1.21), item predicate rewrite in advancements/loot (1.21.5), attribute modifier ids (1.21), worldgen noise/density function tweaks per release. Never trust the model's memory of these.

## 2. Schemas by content
| Data type | Path | Notes |
|---|---|---|
| Recipes | `recipe/*.json` | shaped, shapeless, smelting/blasting/smoking/campfire, stonecutting, smithing_transform/trim, crafting_transform. Bukkit API is an alternative for plugins. |
| Loot tables | `loot_table/**` | pools, entries, functions, conditions; types: block, entity, chest, gift, fishing... |
| Advancements | `advancement/**` | criteria triggers, display, rewards, parent chain. |
| Tags | `tags/<registry>/**` | item/block/entity_type/biome/enchantment etc.; `replace:false` merges. |
| Functions | `function/**.mcfunction` | command text; `#minecraft:tick` / `#minecraft:load` tags run them. |
| Enchantments | `enchantment/*.json` | data-driven since 1.21; also writable from Paper bootstrap `RegistryEvents.compose()` (VERIFIED https://docs.papermc.io/paper/dev/registries/). |
| Worldgen | `worldgen/biome`, `configured_feature`, `placed_feature`, `structure`, `structure_set`, `template_pool`, `processor_list`, `noise_settings`, `density_function`, `world_preset`; plus `dimension`, `dimension_type`; structure NBT in `structure/` | Structures need binary NBT templates. |
Machine-readable truth for all of these: **vanilla-mcdoc** (MIT; schemas for datapack and resource pack JSON/NBT, version-aware). VERIFIED (https://github.com/SpyglassMC/vanilla-mcdoc).

## 3. How Paper loads / reloads
- Plugin-shipped packs: unzipped folder in the jar resources, `DatapackRegistrar#discoverPack(URI,id)` inside the `DATAPACK_DISCOVERY` lifecycle event from a `PluginBootstrap` (needs `paper-plugin.yml`); loaded pack name `<Plugin>/<id>`; discovery does not decide whether the pack is enabled, check with `/datapack list enabled`. VERIFIED (https://docs.papermc.io/paper/dev/lifecycle/datapacks/). Runtime reload: not documented there (UNVERIFIED conclusion: discovery is boot-time).
- World packs: drop into `<world>/datapacks/` (zip or folder) - UNVERIFIED but standard; Cyrus installer already places datapacks (G-gaps :455-465).
- `/reload` re-reads recipes, loot tables, advancements, functions, tags but **not worldgen**; worldgen changes need a restart. VERIFIED (https://minecraft.wiki/w/Data_pack). New biomes/structures only appear in chunks generated after load (UNVERIFIED). A new dimension needs restart + world creation.
- Custom registry content from Java: `RegistryEvents` `compose()`/`entryAdd()` fire after vanilla/datapack content loads; errors abort startup; Paper plugin only. VERIFIED (registries URL).
- Datapack worldgen on a customer's existing world can produce chunk borders and biome-id mismatch (UNVERIFIED); studio should default to "new dimension / new world" for big worldgen and warn for existing worlds.

## 4. Validators and open-source generators
| Tool | What | Licence | Use |
|---|---|---|---|
| **misode.github.io** | Generators for loot tables, recipes, advancements, worldgen, dimension, predicates; supports 1.15-1.21 + 26.1 per README | **MIT** VERIFIED (https://github.com/misode/misode.github.io) | Reference UI/logic; can be forked/self-hosted; 26.2/26.3 coverage unverified. Uses mcdoc schemas in `public/mcdoc`. |
| **vanilla-mcdoc** | Authoritative schemas (CODEC/JSON/NBT) | **MIT** VERIFIED | **Adopt as the schema source** for validator + type generation. |
| **Spyglass** (SpyglassMC core / language server) | Parses mcdoc, validates datapack text | licence UNVERIFIED (believed MIT) | Candidate engine for a Node-based CLI validator; confirm licence + 26.x support. |
| **misode/mcmeta** | Per-version vanilla data, registries, reports | UNVERIFIED | Source of version-accurate registry id lists. |
| **Vanilla data generator** (`java -DbundlerMainClass=net.minecraft.data.Main -jar server.jar --server`) | Dumps vanilla data pack + registries/command-tree reports; flags `--server`, `--dev`, `--input` documented. VERIFIED (https://minecraft.wiki/w/Tutorial:Running_the_data_generator). A `--validate` flag is NOT confirmed there (UNVERIFIED). | Mojang EULA; run only on our build host, do not redistribute output | Generate per-version registry id lists (blocks, items, entity types, sounds, biomes, features) that the generator uses to reject unknown ids. |
Mojang's own jar is the ultimate validator (see section 5).

## 5. Headless load-test (proposed; none of it run)
1. Static: JSON parse + mcdoc/schema validation + id existence check against the per-version registry dump + pack.mcmeta format check. Fast, deterministic, no JVM.
2. Dynamic: boot the real Paper jar for the target version in a throwaway container (the build service already compiles against the real jars; the same image family can start one) with the pack in `world/datapacks` (or bundled in a test plugin), flat/void world, RCON enabled. UNVERIFIED design:
   - Parse startup log for datapack load errors (Minecraft logs failed resources as "Couldn't parse data file ..." / "Failed to load datapack" - UNVERIFIED exact strings; build the matcher by deliberately breaking a pack on each version).
   - `datapack list enabled` shows it loaded; `reload` then re-check; `recipe give @a *`/`advancement grant` to prove they resolve; `function ns:test` and read RCON replies; `loot spawn`/`loot give` to exercise tables; `place feature|structure|template` and `locate biome` for worldgen; `execute in <dimension> run ...` for dimensions.
   - Boot time ~tens of seconds per version; budget one test per supported version per build. Cost is CPU/time on the build VM, not tokens.
3. Regression: keep a golden corpus of known-good packs per version (misode examples + vanilla dump) to detect when the validator itself drifts on a new release.

## 6. What the AI writes vs what a generator produces
- **AI writes**: the intent as a small typed *spec* (e.g. `{type:"recipe", shape:[...], ingredients, result}`), `.mcfunction` command logic (short, line-oriented, validated against the command tree from the data generator), names/lore/text, balance numbers, loot weights, and the Java glue for enchant/ability behaviour.
- **Schema-driven generator produces**: all JSON for recipe, loot_table, advancement, tags, enchantment, damage_type, jukebox_song, biome, features, dimension, `pack.mcmeta`, overlays, folder layout - from the spec, per version, using the mcdoc-derived types and registry dumps. The model should never emit raw version-specific JSON for these.
- **Programmatic builders (not LLM)**: structure NBT (build a block grid or Paper `StructureManager` capture from a template, write gzip NBT), noise settings / density functions (parameterised presets: "tropical-ish", "flat plains+custom ores"; expose a few knobs), biome colour/precipitation/spawn tables from presets.
- AI is reliable for recipes, loot tables, advancements, tags, functions, enchantments (via spec). It is unreliable for hand-written worldgen noise, structure jigsaw pools, and any field name from memory across versions.

## 7. MVP scope
1. Spec types: recipe, loot_table, advancement, tag, function, enchantment, jukebox_song/sound event. (No worldgen in MVP.)
2. Per-version emitters for 1.21.1, 1.21.4, 1.21.8, 1.21.11, 26.x (one table of format numbers, one adapter per schema delta).
3. Static validator (schema + registry ids) + dynamic Paper boot test per target version in CI of the build service.
4. Output either (a) plugin-bundled pack via `DATAPACK_DISCOVERY` or (b) standalone zip placed by the installer; plus a Studio editor that shows/edits the spec and the generated JSON (misode-style forms).
5. Phase 2: biomes (preset + colours), custom ore/tree features, simple structures from a block grid, new dimension from preset.

## 8. Build vs adopt, effort
| Item | Decision | Size |
|---|---|---|
| Schema source | Adopt vanilla-mcdoc (MIT); pin per-version snapshot | S |
| Registry/id dump per version | Build script around Mojang data generator on build host | S-M |
| Spec -> JSON generators (7 types x 5 version adapters) | Build (mcdoc types give structure; adapters hand-tuned) | M |
| Static validator | Adopt Spyglass core if licence OK, else Build thin JSON-schema layer from mcdoc | M |
| Studio UI | Reuse patterns from misode (MIT) but build in Nxeon theme; do not iframe misode | M |
| Dynamic headless load test | Build (RCON harness on existing build VM) | M |
| Worldgen presets + structure NBT builder | Build | L |
| Overlays/multi-version single pack | Build later (VERIFIED feature exists) | S |

## 9. Not determined
Spyglass and mcmeta licences; whether the vanilla data generator has a usable validation mode; exact error strings for load failures; 26.2/26.3 coverage in misode and mcdoc; Paper runtime datapack reload semantics; exact version where folders became singular.

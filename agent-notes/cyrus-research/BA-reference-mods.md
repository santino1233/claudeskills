# BA: private reference-mod corpus and analysis (2026-10-11)

PRIVATE. Every item is third-party, private-only, game-derived-class reference. Nothing is redistributed, served, committed or pasted into Cyrus output; only script-derived aggregate facts leave the staging dir. Data: `/tank/cyrus-library-staging/_reference-mods/` (README.md, catalog.jsonl, analysis/aggregate.json, per_item.jsonl, scripts). Source: official Modrinth API v2 only, UA `nxeon-cyrus-research/1.0 (https://cyrus.my)`, ~3 req/s, sha512 verified, 0 hash failures, 0 429s. No model calls; JDK absent, so a small Python class-file parser did the constant-pool scan.

## Corpus
| Type | Files | Disk | Matched 1.21.1 / .4 / .8 / .11 | Licence mix |
|---|---|---|---|---|
| plugin (paper/spigot/bukkit/purpur/folia) | 173 | 508 MB | 121 / 133 / 136 / 151 | MIT 50, GPL 54, ARR 34, LGPL 11, Apache 7 |
| datapack | 141 | 178 MB | 81 / 45 / 47 / 81 | MIT 46, ARR 41, CC-BY-NC* 13 |
| resourcepack | 43 | 107 MB | 31 / 25 / 28 / 33 | ARR 20, MIT 8, CC/other 15 |
| other-loader (not-buildable-by-cyrus) | 29 | 123 MB | 14 / 1 / 2 / 15 | ARR 6, MIT 6, LGPL 6 |

Total 386 files, 1.05 GB (cap 25 GB). Plugin category membership (a plugin may be in several): utility 110, game-mechanics 75, management 46, adventure 40, social 27, equipment 25, library 21, decoration/economy/technology/transportation 17, minigame/optimization/storage 16, cursed/food/magic/mobs/worldgen 15. Datapacks: adventure 65, game-mechanics 60, utility 49, worldgen 36, equipment 25, mobs 23, others 10-19 each. Resource packs: vanilla-like 24, tweaks 16, modded 14, utility 10, themed 9, others 5-6.

## What real plugins do (n=173, top by downloads, so large and legacy-friendly: median 512 classes, 1.1 MB)
- api-version: 1.13 (32%), 1.21 (24%), 1.16 (9%), 1.19 (6%), exact 1.21.x (13%). Class major: Java 8 (60%), 21 (56%), 17 (33%).
- Most-used API classes: Player, PluginManager, Bukkit, Listener, Server, World, CommandSender, Location, BukkitScheduler (75%), Material, Block, ItemStack, YamlConfiguration (62%), NamespacedKey (58%), ItemMeta, ChatColor (51%), Component (39%). Top events (plugins): PlayerJoin 114, PlayerQuit 98, PlayerInteract 70, InventoryClick 64, BlockBreak 62, BlockPlace 51, PlayerMove 50, InventoryClose 39, PlayerDeath 39, EntityDamageByEntity 39.
- Scheduling: sync runTask-family 60%, Bukkit async 43%, ExecutorService 36%, CompletableFuture 32%, extends BukkitRunnable 26%, legacy scheduleSync* 24%, Folia region schedulers 42%.
- Persistence: NIO files 64%, YAML 62%, Gson JSON 53%, JDBC 37% (Hikari 5%, SQLite/MySQL/H2 each under 2% as direct refs), PDC 34%, Java serialization 22%, none 12%.
- Config: config.yml in 47%; median 47 keys, 8 top-level, depth 3; 85% commented; top keys debug, language, enabled, database, messages, storage.
- Commands: 53% declare commands (median 1); 58% have aliases; 39% set a permission field; permission nodes start with the plugin name 90%; depth 3 most common; frequent suffixes `*`, others, reload, admin, use, bypass.
- Deps: any depend/softdepend 64%; softdepend PlaceholderAPI 62, Vault 38, WorldGuard 27, LuckPerms 23, ProtocolLib 17, ViaVersion 14, floodgate 14.
- Telemetry/network: bStats 58%, update checker (modrinth/spiget/github) 28%, http/socket classes 64%. Reflection 66%, NMS/CraftBukkit 23%, Brigadier/Lifecycle commands 24%, paper-plugin.yml 10%, `libraries:` 10%, shading other packages 51%, Kotlin 2%.

## Top gaps vs Cyrus (sheets, prompts.js, rules, minecraft.ts, designer; word-match, 146/300 popular API classes mentioned)
1. Events used by 10-20% of plugins and absent from Cyrus text: PlayerChangedWorld, PluginDisable, PlayerCommandPreprocess, InventoryOpen, WorldLoad/Unload, ChunkLoad/Unload, Block Piston Extend/Retract, PlayerSwapHandItems, CreatureSpawn (+SpawnReason), PlayerFish, EntityShootBow, ProjectileLaunch, FoodLevelChange, SignChange, PlayerLogin/AsyncPlayerPreLogin, AsyncTabComplete.
2. APIs unmentioned: OfflinePlayer (49% of plugins), BlockFace, BlockState/BlockStateMeta, Chunk, SkullMeta, PotionMeta, BookMeta, DyeColor, Biome, Villager/merchant, ExperienceOrb, FixedMetadataValue (metadata), ServicesManager, Bukkit BossBar (BarColor/Style/Flag; Cyrus teaches only Adventure), InventoryType/InventoryView, PermissionDefault, ConsoleCommandSender, Bukkit.getConsoleSender, NamespacedKey.fromString, Block.getRelative/setType/getBlockData, isPrimaryThread.
3. Pattern conflicts (real plugins do it; Cyrus forbids or never mentions): networking, reflection/Class.forName (62%), NMS, Brigadier, Folia schedulers, bStats, shading, Vault/PlaceholderAPI/WorldGuard softdepends (no lane for new plugins), JSON/SQL storage (Cyrus teaches YAML only), legacy ChatColor.translateAlternateColorCodes (still 31%).
4. Datapacks: dialog, predicate (23%), item_modifier (18%), damage_type, worldgen structure/template_pool/processor_list (23%) and `execute`-heavy functions (66k `execute` vs 17k `scoreboard` lines) sit outside the spec; Cobblemon-style species/spawn packs skew the sample.
5. Archetypes with ~0 keyword hits in Cyrus text and eval: minigame arena/lobby/queue, party/guild/clan, moderation/punishments, region claims/protection, backpack/storage, machines/automation, custom blocks/furniture, entity-limit/lag tools, voice/proxy messaging.
Resource packs: models 42%, item/block textures ~40%, optifine CIT 30%, gui 26%, lang 19%, core shaders 9%, fonts 9%, custom sounds 5%; median zip 0.3 MB; none use custom_model_data files (the 1.21.4+ item-model path is the norm).

## Recommendations
- API sheets: add an events catalog (the ~20 above, cancel/async semantics), a block/world sheet (BlockFace, BlockState, Chunk), head/potion/book metas, OfflinePlayer (warn: name lookup is blocking), Bukkit BossBar equivalence, metadata API.
- Failure rules (precheck): Bukkit.getOfflinePlayer(String) on main thread, Player.spigot(), translateAlternateColorCodes, Class.forName, PlayerMove without hasChangedBlock, async Bukkit calls.
- Templates: Gson JSON per-UUID store (Gson is on the classpath), PDC item tags, listener skeletons for the top 10 events.
- Coverage matrix: add rows weighted by category counts above (minigame, social, management, storage, technology, decoration).
- Eval set: one prompt per new event and per missing archetype, plus 1.21.1 enum-era variants; keep refusal cases for network/reflection/NMS.

## Not fetched / caveats
- Skipped >60 MB: puffradio (131 MB), cobblemon-music-pack (342 MB), cobblemon mod (139 MB).
- Plugin/resourcepack sets are smaller than the nominal quota (173, 43) because per-category tops overlap the overall tops; the `features`/`resolutions` resource-pack headers were not treated as categories.
- Top-by-downloads is skewed to big multi-platform projects (Simple Voice Chat, WorldEdit); several client-only mods leaked into other-loader (server_side optional). No compile check (no source). Relocated shaded libs inside the plugin package count as own code.

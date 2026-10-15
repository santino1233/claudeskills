# Paper API diff 1.21.8 -> 1.21.11

Generated 2026-10-15 by scripts/cyrus/api-diff.js (javap, public API only). Candidate rules are for human review.

| | 1.21.8 | 1.21.11 |
|---|---|---|
| API types | 2075 | 2135 |
| types removed | 6 | |
| types added | 66 | |
| breaking items | 46 | |
| newly deprecated | 97 | |
| items that hit our sheets / rules / goldens | 3 | |

## Impact on Cyrus (sheets, rules, prompts, golden plugins)

| change | symbol | rename? | golden plugins | knowledge files |
|---|---|---|---|---|
| constant-removed | `Material.CHAIN` | `COPPER_CHAIN` |  | sheet:services/modbuilder/sheets/1.21.1.md, sheet:services/modbuilder/sheets/1.21.4.md, sheet:services/modbuilder/sheets/1.21.8.md, rules:services/modbuilder/rules/failure-rules.json |
| deprecated | `GameRule.KEEP_INVENTORY` |  | mc-events | sheet:services/modbuilder/sheets/1.21.1.md, sheet:services/modbuilder/sheets/1.21.4.md, sheet:services/modbuilder/sheets/1.21.8.md |
| deprecated | `GameRule.DO_INSOMNIA` |  | mc-events |  |

## Removed API types

- `io.papermc.paper.generated.GeneratedFrom`
- `io.papermc.paper.registry.event.RegistryFreezeEvent`
- `org.bukkit.packs.DataPack$Compatibility`
- `org.bukkit.packs.DataPack$Source`
- `org.bukkit.packs.DataPack`
- `org.bukkit.packs.DataPackManager`

## Breaking member changes (top 60 types by count)

- `EnchantmentWrapper` (9): method removed `displayName(int)`; method removed `translationKey()`; method removed `isTradeable()`; method removed `isDiscoverable()`; method removed `getMinModifiedCost(int)`; method removed `getMaxModifiedCost(int)`; method removed `getRarity()`; method removed `getDamageIncrease(int,EntityCategory)`; ...
- `PotionEffectTypeWrapper` (7): method removed `isInstant()`; method removed `getColor()`; method removed `getKey()`; method removed `getEffectAttributes()`; method removed `getAttributeModifierAmount(Attribute,int)`; method removed `getEffectCategory()`; method removed `translationKey()`
- `BiomeTagKeys` (5): field removed `HAS_CLOSER_WATER_FOG`; field removed `INCREASED_FIRE_BURNOUT`; field removed `PLAYS_UNDERWATER_MUSIC`; field removed `SNOW_GOLEM_MELTS`; field removed `WITHOUT_PATROL_SPAWNS`
- `GameRule` (3): constant removed `SPAWN_CHUNK_RADIUS`; method removed `equals(Object)`; method removed `toString()`
- `EntityPushedByEntityAttackEvent` (2): method removed `isCancelled()`; method removed `setCancelled(boolean)`
- `Material` (2): constant removed `CHAIN` -> `COPPER_CHAIN`; method removed `isEnabledByFeature(World)`
- `WorldCreator` (2): method removed `keepSpawnInMemory(boolean)`; method removed `keepSpawnInMemory()`
- `RegistryEventProvider` (1): method removed `freeze()`
- `BlockTypeKeys` (1): field removed `CHAIN` -> `COPPER_CHAIN`
- `ItemTypeKeys` (1): field removed `CHAIN` -> `COPPER_CHAIN`
- `ItemTypeTagKeys` (1): field removed `ENCHANTABLE_SWORD`
- `Bukkit` (1): method removed `getDataPackManager()`
- `Server` (1): method removed `getDataPackManager()`
- `Tag` (1): constant removed `ITEMS_ENCHANTABLE_SWORD`
- `BlockType` (1): field removed `CHAIN` -> `COPPER_CHAIN`
- `EntityType` (1): method removed `isEnabledByFeature(World)`
- `ItemType` (1): field removed `CHAIN` -> `COPPER_CHAIN`

## Newly deprecated (top 60)

- `MaterialTags.LANTERNS`
- `LookupProfileEvent.getPlayerProfile()`
- `PlayerBedFailEnterEvent$FailReason.valueOf(String)`
- `PlayerBedFailEnterEvent.getFailReason()`
- `WorldBorderBoundsChangeEvent.getDuration()`
- `WorldBorderBoundsChangeEvent.setDuration(long)`
- `GameRule.ANNOUNCE_ADVANCEMENTS`
- `GameRule.COMMAND_BLOCK_OUTPUT`
- `GameRule.DISABLE_PLAYER_MOVEMENT_CHECK`
- `GameRule.DISABLE_ELYTRA_MOVEMENT_CHECK`
- `GameRule.DO_DAYLIGHT_CYCLE`
- `GameRule.DO_ENTITY_DROPS`
- `GameRule.DO_FIRE_TICK`
- `GameRule.DO_LIMITED_CRAFTING`
- `GameRule.PROJECTILES_CAN_BREAK_BLOCKS`
- `GameRule.DO_MOB_LOOT`
- `GameRule.DO_MOB_SPAWNING`
- `GameRule.DO_TILE_DROPS`
- `GameRule.DO_WEATHER_CYCLE`
- `GameRule.KEEP_INVENTORY`
- `GameRule.LOG_ADMIN_COMMANDS`
- `GameRule.MOB_GRIEFING`
- `GameRule.NATURAL_REGENERATION`
- `GameRule.REDUCED_DEBUG_INFO`
- `GameRule.SEND_COMMAND_FEEDBACK`
- `GameRule.SHOW_DEATH_MESSAGES`
- `GameRule.SPECTATORS_GENERATE_CHUNKS`
- `GameRule.DISABLE_RAIDS`
- `GameRule.DO_INSOMNIA`
- `GameRule.DO_IMMEDIATE_RESPAWN`
- `GameRule.DROWNING_DAMAGE`
- `GameRule.FALL_DAMAGE`
- `GameRule.FIRE_DAMAGE`
- `GameRule.FREEZE_DAMAGE`
- `GameRule.DO_PATROL_SPAWNING`
- `GameRule.DO_TRADER_SPAWNING`
- `GameRule.DO_WARDEN_SPAWNING`
- `GameRule.FORGIVE_DEAD_PLAYERS`
- `GameRule.UNIVERSAL_ANGER`
- `GameRule.BLOCK_EXPLOSION_DROP_DECAY`
- `GameRule.MOB_EXPLOSION_DROP_DECAY`
- `GameRule.TNT_EXPLOSION_DROP_DECAY`
- `GameRule.WATER_SOURCE_CONVERSION`
- `GameRule.LAVA_SOURCE_CONVERSION`
- `GameRule.GLOBAL_SOUND_EVENTS`
- `GameRule.DO_VINES_SPREAD`
- `GameRule.ENDER_PEARLS_VANISH_ON_DEATH`
- `GameRule.ALLOW_FIRE_TICKS_AWAY_FROM_PLAYER`
- `GameRule.TNT_EXPLODES`
- `GameRule.LOCATOR_BAR`
- `GameRule.PVP`
- `GameRule.SPAWN_MONSTERS`
- `GameRule.ALLOW_ENTERING_NETHER_USING_PORTALS`
- `GameRule.COMMAND_BLOCKS_ENABLED`
- `GameRule.SPAWNER_BLOCKS_ENABLED`
- `GameRule.RANDOM_TICK_SPEED`
- `GameRule.SPAWN_RADIUS`
- `GameRule.MAX_ENTITY_CRAMMING`
- `GameRule.MAX_COMMAND_CHAIN_LENGTH`
- `GameRule.MAX_COMMAND_FORK_COUNT`

## Candidate failure rules (review, then add to rules/failure-rules.json by hand)

- `api-diff-1-21-11-material-chain`: On 1.21.11 Material.CHAIN is gone; use Material.COPPER_CHAIN.  pattern `\bMaterial\.CHAIN\b`  fix `Material.COPPER_CHAIN`

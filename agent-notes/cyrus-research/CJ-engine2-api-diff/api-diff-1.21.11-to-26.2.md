# Paper API diff 1.21.11 -> 26.2

Generated 2026-10-15 by scripts/cyrus/api-diff.js (javap, public API only). Candidate rules are for human review.

| | 1.21.11 | 26.2 |
|---|---|---|
| API types | 2135 | 2192 |
| types removed | 3 | |
| types added | 60 | |
| breaking items | 90 | |
| newly deprecated | 45 | |
| items that hit our sheets / rules / goldens | 1 | |

## Impact on Cyrus (sheets, rules, prompts, golden plugins)

| change | symbol | rename? | golden plugins | knowledge files |
|---|---|---|---|---|
| deprecated | `WorldCreator` |  | mc-worlds | sheet:services/modbuilder/sheets/1.21.1.md, sheet:services/modbuilder/sheets/1.21.4.md, sheet:services/modbuilder/sheets/1.21.8.md, sheet:services/modbuilder/sheets/1.21.11.md |

## Removed API types

- `org.bukkit.block.data.type.PointedDripstone$Thickness`
- `org.bukkit.event.world.TimeSkipEvent$SkipReason`
- `org.bukkit.inventory.meta.BookMeta$BookMetaBuilder`

## Breaking member changes (top 60 types by count)

- `UnsafeValues` (30): method removed `componentFlattener()`; method removed `plainComponentSerializer()`; method removed `plainTextSerializer()`; method removed `gsonComponentSerializer()`; method removed `colorDownsamplingGsonComponentSerializer()`; method removed `legacyComponentSerializer()`; method removed `resolveWithContext(Component,CommandSender,Entity,boolean)`; method removed `getDefaultAttributeModifiers(Material,EquipmentSlot)`; ...
- `BlockTypeTagKeys` (8): field removed `BAMBOO_PLANTABLE_ON`; field removed `BIG_DRIPLEAF_PLACEABLE`; field removed `CONCRETE_POWDER` -> `CONCRETE_POWDERS`; field removed `DRY_VEGETATION_MAY_PLACE_ON`; field removed `MUSHROOM_GROW_BLOCK`; field removed `SMALL_DRIPLEAF_PLACEABLE`; field removed `SNOW_LAYER_CAN_SURVIVE_ON`; field removed `SNOW_LAYER_CANNOT_SURVIVE_ON`
- `EnchantmentTagKeys` (7): field removed `TRADES_DESERT_SPECIAL`; field removed `TRADES_JUNGLE_SPECIAL`; field removed `TRADES_PLAINS_SPECIAL`; field removed `TRADES_SAVANNA_SPECIAL`; field removed `TRADES_SNOW_SPECIAL`; field removed `TRADES_SWAMP_SPECIAL`; field removed `TRADES_TAIGA_SPECIAL`
- `VanillaGoal` (5): field removed `FOLLOW_BOAT`; field removed `SLIME_ATTACK`; field removed `SLIME_FLOAT`; field removed `SLIME_KEEP_ON_JUMPING`; field removed `SLIME_RANDOM_DIRECTION`
- `PointedDripstone` (5): method removed `getVerticalDirection()`; method removed `setVerticalDirection(BlockFace)`; method removed `getVerticalDirections()`; method removed `getThickness()`; method removed `setThickness(PointedDripstone$Thickness)`
- `TimeSkipEvent` (5): method removed `getSkipReason()`; method removed `getSkipAmount()`; method removed `setSkipAmount(long)`; method removed `isCancelled()`; method removed `setCancelled(boolean)`
- `Slime` (3): method removed `getSize()`; method removed `canWander()`; method removed `setWander(boolean)`
- `LimitedRegion` (3): method removed `setBlockData(Vector,BlockData)`; method removed `getBlockState(Vector)`; method removed `getBlockData(Vector)`
- `BookMeta` (3): method removed `toBuilder()`; return-changed `title(Component)` (Book -> BookMeta); return-changed `author(Component)` (Book -> BookMeta)
- `CreeperIgniteEvent` (2): method removed `getHandlers()`; method removed `getHandlerList()`
- `DamageResistant` (2): method removed `damageResistant(TagKey)`; return-changed `types()` (TagKey -> RegistryKeySet)
- `Breedable` (2): method removed `setAgeLock(boolean)`; method removed `getAgeLock()`
- `PlayerInteractAtEntityEvent` (2): method removed `getHandlers()`; method removed `getHandlerList()`
- `AsyncTabCompleteEvent.Completion` (1): method removed `examinableProperties()`
- `BlocksAttacks.Builder` (1): method removed `bypassedBy(TagKey)`
- `BlocksAttacks` (1): return-changed `bypassedBy()` (TagKey -> RegistryKeySet)
- `ItemComponentTypesBridge` (1): method removed `damageResistant(TagKey)`
- `ItemTypeTagKeys` (1): field removed `DYEABLE`
- `PaperComponents` (1): method removed `plainSerializer()`
- `Tag` (1): constant removed `ITEMS_DYEABLE`
- `CommandSender` (1): method removed `sendMessage(Identity,Component,MessageType)`
- `ProxiedCommandSender` (1): method removed `sendMessage(Identity,Component,MessageType)`
- `LibraryLoader` (1): field removed `REMAPPER`

## Newly deprecated (top 60)

- `Effect.STEP_SOUND`
- `Effect.CLICK2`
- `Effect.CLICK1`
- `Effect.BOW_FIRE`
- `Effect.SOUND_STOP_JUKEBOX_SONG`
- `Effect.ENDERDRAGON_SHOOT`
- `Effect.ZOMBIE_CONVERTED_VILLAGER`
- `Effect.SOUND_WITH_CHARGE_SHOT`
- `Effect.DRAGON_BREATH`
- `Effect.SMOKE`
- `Effect.SHOOT_WHITE_SMOKE`
- `Effect.ENDERDRAGON_GROWL`
- `Effect.PARTICLES_SCULK_CHARGE`
- `Effect.PARTICLES_SCULK_SHRIEK`
- `Effect.PARTICLES_AND_SOUND_BRUSH_BLOCK_COMPLETE`
- `Effect.PARTICLES_EGG_CRACK`
- `Instrument.getType()`
- `Instrument.getByType(byte)`
- `Material.getCreativeCategory()`
- `Tag.SNOW_LAYER_CANNOT_SURVIVE_ON`
- `Tag.SNOW_LAYER_CAN_SURVIVE_ON`
- `Tag.MUSHROOM_GROW_BLOCK`
- `Tag.SMALL_DRIPLEAF_PLACEABLE`
- `Tag.BIG_DRIPLEAF_PLACEABLE`
- `Tag.BAMBOO_PLANTABLE_ON`
- `Tag.DRY_VEGETATION_MAY_PLACE_ON`
- `Tag.CONCRETE_POWDER`
- `World.setSpawnFlags(boolean,boolean)`
- `World.getAllowAnimals()`
- `World.getGameRuleDefault(GameRule)`
- `WorldCreator`
- `WorldCreator.ofNameAndKey(String,NamespacedKey)`
- `PointedDripstone`
- `Vex.getSummoner()`
- `Vex.setSummoner(Mob)`
- `PigZapEvent.getLightning()`
- `PigZapEvent.getEntity()`
- `PlayerKickEvent$Cause.KICK_COMMAND`
- `ItemMeta.getDamageResistant()`
- `ItemMeta.setDamageResistant(Tag)`
- `TropicalFishBucketMeta.hasVariant()`
- `AttributeInstance.getDefaultValue()`
- `PotionMix.createPredicateChoice(Predicate)`
- `Mob.setDespawnInPeacefulOverride(TriState)`
- `Mob.getDespawnInPeacefulOverride()`

## Candidate failure rules (review, then add to rules/failure-rules.json by hand)

None.


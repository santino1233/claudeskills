# Paper API diff 1.21.11 -> 26.1.2

Generated 2026-10-15 by scripts/cyrus/api-diff.js (javap, public API only). Candidate rules are for human review.

| | 1.21.11 | 26.1.2 |
|---|---|---|
| API types | 2135 | 2153 |
| types removed | 1 | |
| types added | 19 | |
| breaking items | 33 | |
| newly deprecated | 16 | |
| items that hit our sheets / rules / goldens | 1 | |

## Impact on Cyrus (sheets, rules, prompts, golden plugins)

| change | symbol | rename? | golden plugins | knowledge files |
|---|---|---|---|---|
| deprecated | `WorldCreator` |  | mc-worlds | sheet:services/modbuilder/sheets/1.21.1.md, sheet:services/modbuilder/sheets/1.21.4.md, sheet:services/modbuilder/sheets/1.21.8.md, sheet:services/modbuilder/sheets/1.21.11.md |

## Removed API types

- `org.bukkit.event.world.TimeSkipEvent$SkipReason`

## Breaking member changes (top 60 types by count)

- `BlockTypeTagKeys` (7): field removed `BAMBOO_PLANTABLE_ON`; field removed `BIG_DRIPLEAF_PLACEABLE`; field removed `DRY_VEGETATION_MAY_PLACE_ON`; field removed `MUSHROOM_GROW_BLOCK`; field removed `SMALL_DRIPLEAF_PLACEABLE`; field removed `SNOW_LAYER_CAN_SURVIVE_ON`; field removed `SNOW_LAYER_CANNOT_SURVIVE_ON`
- `EnchantmentTagKeys` (7): field removed `TRADES_DESERT_SPECIAL`; field removed `TRADES_JUNGLE_SPECIAL`; field removed `TRADES_PLAINS_SPECIAL`; field removed `TRADES_SAVANNA_SPECIAL`; field removed `TRADES_SNOW_SPECIAL`; field removed `TRADES_SWAMP_SPECIAL`; field removed `TRADES_TAIGA_SPECIAL`
- `TimeSkipEvent` (5): method removed `getSkipReason()`; method removed `getSkipAmount()`; method removed `setSkipAmount(long)`; method removed `isCancelled()`; method removed `setCancelled(boolean)`
- `DamageResistant` (2): method removed `damageResistant(TagKey)`; return-changed `types()` (TagKey -> RegistryKeySet)
- `Breedable` (2): method removed `setAgeLock(boolean)`; method removed `getAgeLock()`
- `PlayerInteractAtEntityEvent` (2): method removed `getHandlers()`; method removed `getHandlerList()`
- `VanillaGoal` (1): field removed `FOLLOW_BOAT`
- `BlocksAttacks.Builder` (1): method removed `bypassedBy(TagKey)`
- `BlocksAttacks` (1): return-changed `bypassedBy()` (TagKey -> RegistryKeySet)
- `ItemComponentTypesBridge` (1): method removed `damageResistant(TagKey)`
- `ItemTypeTagKeys` (1): field removed `DYEABLE`
- `Tag` (1): constant removed `ITEMS_DYEABLE`
- `LibraryLoader` (1): field removed `REMAPPER`

## Newly deprecated (top 60)

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
- `World.getGameRuleDefault(GameRule)`
- `WorldCreator`
- `WorldCreator.ofNameAndKey(String,NamespacedKey)`
- `ItemMeta.getDamageResistant()`
- `ItemMeta.setDamageResistant(Tag)`
- `AttributeInstance.getDefaultValue()`

## Candidate failure rules (review, then add to rules/failure-rules.json by hand)

None.


# Paper API diff 26.1.2 -> 26.2

Generated 2026-10-15 by scripts/cyrus/api-diff.js (javap, public API only). Candidate rules are for human review.

| | 26.1.2 | 26.2 |
|---|---|---|
| API types | 2153 | 2192 |
| types removed | 2 | |
| types added | 41 | |
| breaking items | 57 | |
| newly deprecated | 29 | |
| items that hit our sheets / rules / goldens | 0 | |

## Impact on Cyrus (sheets, rules, prompts, golden plugins)

None found.

## Removed API types

- `org.bukkit.block.data.type.PointedDripstone$Thickness`
- `org.bukkit.inventory.meta.BookMeta$BookMetaBuilder`

## Breaking member changes (top 60 types by count)

- `UnsafeValues` (30): method removed `componentFlattener()`; method removed `plainComponentSerializer()`; method removed `plainTextSerializer()`; method removed `gsonComponentSerializer()`; method removed `colorDownsamplingGsonComponentSerializer()`; method removed `legacyComponentSerializer()`; method removed `resolveWithContext(Component,CommandSender,Entity,boolean)`; method removed `getDefaultAttributeModifiers(Material,EquipmentSlot)`; ...
- `PointedDripstone` (5): method removed `getVerticalDirection()`; method removed `setVerticalDirection(BlockFace)`; method removed `getVerticalDirections()`; method removed `getThickness()`; method removed `setThickness(PointedDripstone$Thickness)`
- `VanillaGoal` (4): field removed `SLIME_ATTACK`; field removed `SLIME_FLOAT`; field removed `SLIME_KEEP_ON_JUMPING`; field removed `SLIME_RANDOM_DIRECTION`
- `Slime` (3): method removed `getSize()`; method removed `canWander()`; method removed `setWander(boolean)`
- `LimitedRegion` (3): method removed `setBlockData(Vector,BlockData)`; method removed `getBlockState(Vector)`; method removed `getBlockData(Vector)`
- `BookMeta` (3): method removed `toBuilder()`; return-changed `title(Component)` (Book -> BookMeta); return-changed `author(Component)` (Book -> BookMeta)
- `CreeperIgniteEvent` (2): method removed `getHandlers()`; method removed `getHandlerList()`
- `AsyncTabCompleteEvent.Completion` (1): method removed `examinableProperties()`
- `BlockTypeTagKeys` (1): field removed `CONCRETE_POWDER` -> `CONCRETE_POWDERS`
- `PaperComponents` (1): method removed `plainSerializer()`
- `CommandSender` (1): method removed `sendMessage(Identity,Component,MessageType)`
- `ProxiedCommandSender` (1): method removed `sendMessage(Identity,Component,MessageType)`

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
- `Tag.CONCRETE_POWDER`
- `World.setSpawnFlags(boolean,boolean)`
- `World.getAllowAnimals()`
- `PointedDripstone`
- `Vex.getSummoner()`
- `Vex.setSummoner(Mob)`
- `PigZapEvent.getLightning()`
- `PigZapEvent.getEntity()`
- `PlayerKickEvent$Cause.KICK_COMMAND`
- `TropicalFishBucketMeta.hasVariant()`
- `PotionMix.createPredicateChoice(Predicate)`
- `Mob.setDespawnInPeacefulOverride(TriState)`
- `Mob.getDespawnInPeacefulOverride()`

## Candidate failure rules (review, then add to rules/failure-rules.json by hand)

None.


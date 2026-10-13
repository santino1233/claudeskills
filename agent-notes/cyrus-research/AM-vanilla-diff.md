# AM: vanilla 26.1.2 reference vs what Cyrus assumes (R42, 2026-10-11)

Source: owner zip `minecraft-assets-26.1.2.zip` (sha in `lib/cyrus/versions/vanilla/26.1.2/registries.json` `source`), indexed by
`/tank/cyrus-library-staging/_reference/tools/mc_index.py`. 23,487 vanilla files (1,369 mirror `_all/_list.json` files skipped).
Enforced by `test/cyrus-mcref.test.ts` (12 tests, pass).

## Matches exactly (no action)
- Items (1,506), loot tables (1,326), recipes (1,515), advancements (1,617), biomes, structures, configured/placed features,
  structure sets, template pools, processor lists, noise settings, carvers, dimension types, enchantments, item/block/biome/
  entity/enchantment tags, timelines, world clocks: identical to `datapack/data/vanilla-ids.json` (jar data generator).
- `dataPackFeatures("26.1.2")`: ingredients are strings (1,406 string, 15 list, 0 object); advancement backgrounds are ids;
  icons carry no `count`; `smithing_transform` has no `group`; cooking results are objects; titles are text objects.
- Display defaults `GENERATED_FULL / HANDHELD_FULL / BOW_FULL / CROSSBOW_FULL` equal vanilla `item/{generated,handheld,bow,crossbow}`
  after parent merge + the left-hand fallback (all 8 contexts).
- Bow `use_duration` scale 0.05, thresholds 0.65/0.9; crossbow `crossbow/pull` 0.58/1.0: same as `items/bow.json`, `items/crossbow.json`.
- The 52 `LEGACY_CARRIERS` exist in 26.1.2 with the same `{parent, layer0}` model as the 1.21.1 fixture (the CMD path itself
  is 1.21.1-only; no 1.21.1 asset zip was supplied, so 1.21.1 itself rests on the existing jar fixture).
- Every item-model property Cyrus emits that vanilla also uses (`display_context, using_item, use_duration, crossbow/pull,
  charge_type, broken`) is used by vanilla's own items.

## Differences (reported, not bugs in Cyrus)
1. **`on_shelf` display context** (new with shelves): 11 vanilla models define it (`block/block`, `item/shield`, heads, beds...).
   `DISPLAY_CONTEXTS` has 8; for flat items vanilla's `item/generated` does not define it either, so the result is the same
   (identity). Matters only for a future block-item or shield category. Not fixed (needs a client check of older versions).
2. **`swap_animation_scale`** at the item-definition root (7 spears). Cyrus never writes it; a "spear" category would need it.
3. `minecraft:selected`, `custom_model_data`, `damage` are not used by any vanilla item, so the assets cannot confirm them
   (they are real properties; the test fails if vanilla starts using them, so they can move to the verified list).
4. Blockstates include `item_frame` / `glow_item_frame` (entity models), which are not blocks in the registry.
5. Sounds: `sounds.json` has `entity.chicken_picky.step` (a data-driven variant event, not in the sound-event registry);
   the registry's `intentionally_empty` has no `sounds.json` entry. Sound-event validation treats both as vanilla.
6. Particles: `assets/.../particles/` lists only textured particles (106); 12 registry particles have no file
   (`block`, `dust_pillar`, ...) and the mirror carries a stale `ambient_entity_effect.json`. Use the registry
   (`vanillaIds("particle_type")`) for particle ids, never the asset folder.
7. Entity ids from lang keys (164) include 7 non-entity keys (`boat`, `potion`, `killer_bunny`...): the registry (157) stays the authority.
8. New mcmeta key `texture.mipmap_strategy` (45 textures). Cyrus writes no texture mcmeta yet; any future one should allow it.
9. Pack format: the zip has no pack metadata, so 84.0 (resource) and 101.1 (data) still rest on the Paper `version.json`; not re-verified here.

## `minecraft.zip` (older-looking resource tree)
Not an exact match for any version in `vanilla-ids.json`: it has every 26.2 item plus 125 more (156 more than 26.1.2;
e.g. concrete/wool slabs and stairs, cushions, explorer maps), so it is NEWER than 26.2 (probably a 26.3 snapshot or beta, not
verified). Indexed privately as `unknown-b8815fde`. Committed facts only: `lib/cyrus/versions/vanilla/minecraft-zip-diff.json`.
Not used by any validator until its version is known.

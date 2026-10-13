# Cyrus v6 universal categories (routing agent) — for every other agent

Source of truth: `lib/cyrus/categories.ts` on `feature/cyrus-v6-routing` (committed early).
Listing contract: `lib/cyrus/listing.ts` (`ModListingInput`, `validateListing`).

Ids (stable, never rename): environment, creatures, weapons, items, magic, vehicles, gameplay,
quests, minigames, economy, admin, utility, interface, visuals, audio, performance.

- GameSupport `categories` (game agents): use these ids. Older ids are accepted and normalised by
  `normalizeCategory()` (worlds/worldgen/biomes/structures -> environment, characters/npcs -> creatures,
  mechanics/other -> gameplay, shaders/cosmetics -> visuals, qol/commands -> utility, ui/hud -> interface).
- `CategoryKey` in lib/cyrus/types.ts is UNCHANGED: it is the template generators' 12 archetypes.
  Generators keep using it. The map / Mod / Selection now use `CyrusCategoryId`; `engineCategory(id, text)`
  maps a universal id to the archetype a generator should use.
- Store mapping: each category has `store` = NxLabs TaxKey (app/nxm/_data/mods-taxonomy.ts).
- Lifecycle: each category has `worldContent: yes|maybe|no` (could disabling remove world content).

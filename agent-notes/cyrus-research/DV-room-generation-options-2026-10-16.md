# DV: How Cyrus should make cool dungeon rooms (2026-10-16)

Question from the owner: "the dungeon rooms Cyrus generates are small and basic... is there any other way that I generate cool rooms?"
Read-only research. No builds run, no node-2 jobs, no code changed.

## TL;DR

**Recommendation: hybrid. Hand-built room templates now (A), then Cyrus's own Room Studio later (B). Both use the same file format and the same placer.**

1. **This week (owner + about 5 agent-days):** the owner builds 10-15 large rooms per theme in a creative world. Each room is saved with a **vanilla structure block** (works with a vanilla client, up to 48x48x48, so a 40x24x40 room fits in one save) or with WorldEdit `//schem save`. He marks spots with **glazed terracotta marker blocks** (the legend is in section 5). Cyrus gets a `structures` asset lane. It checks and cleans the file, converts it to vanilla `.nbt`, and puts it in the jar under `structures/<theme>/<id>.nbt` next to a sidecar `.json`. The generated plugin runs a small **data-driven placer**: Bukkit `StructureManager.loadStructure(InputStream)`, read the markers from the palette, paste in batches over several ticks, then spawn mobs, fill chests and set traps and doors at the markers.
2. **Next (8-12 agent-days):** Room Studio. The model writes a compact layered room spec (palette, layers, symmetry/array ops, decoration passes, marker legend). Cyrus validates it, renders a preview, and compiles it to the **same `.nbt` + sidecar** using the compiler that already exists in `lib/cyrus/datapack/worldgen/template.ts`. The owner's rooms become the gold training and eval set for it.
3. **Later:** procedural layouts (D) over the same kit, so runs connect 3-6 hand-quality modules through standard doorways. Skip vanilla jigsaw/datapack worldgen (C) for the instanced dungeon. Do not import community schematics (E) unless the licence is explicitly CC0, CC-BY or the owner's own.

## 1. Why code-generated rooms end up basic (evidence)

Source: the latest Infinite Dungeon build `mb51322a365e1e9476d7be` (stage 33, `/root/cyrus-eval/dungeon-2026-10-15`). The Java source is not stored anywhere (`ModBuild.result.files` only lists paths), so this was read from the jar's class constants and `config.yml`.

| Fact | Value in the shipped plugin |
|---|---|
| Room footprint | `ROOM_WIDTH = 10`, `ROOM_LENGTH = 14` (static final ints in `DungeonManager`) |
| Room height | `room-min-height: 6` to `room-max-height: 9` |
| Boss arena | 10+8 by 14+6 (18x20), `height: 12`, "kept inside each run's **32-block slot**" |
| Palette per theme | 3 blocks: `wall-block`, `floor-block`, `accent-block` (castle: STONE_BRICKS / POLISHED_ANDESITE / CHISELED_STONE_BRICKS) |
| Decoration vocabulary | about 12 materials across the whole generator: IRON_CHAIN, POINTED_DRIPSTONE, SHROOMLIGHT, VINE, RED_MUSHROOM, SKELETON_SKULL, WHITE_WALL_BANNER, CHEST, STRING, BARRIER... |
| "Variety" features | `buildFloor`, `buildCatwalk`, `buildSecretRoom`, `placeWallFixture`, `placeIcicle`, `placeRuinsVine`, pit (`pit-chance 0.45`, `pit-depth 3`), lights every 4 blocks |
| Stage 8 ask | "The rooms feel small and boring. Make room generation build bigger, more varied layouts..." It succeeded ($2.08, 553 s), but the room is **still 10x14**. It only added a pit, a catwalk and a secret room. |
| Golden it learns from | `services/modbuilder/golden/plugins/mc-instanced-dungeon-lite`: `blocks-per-tick` default 64 (8-256) every 2 ticks |

Root causes:

| Cause | Why it caps quality |
|---|---|
| Every detail costs a line of code | A Java loop can say "wall of X, pillar every N". It cannot cheaply say "this broken arch, that cobweb in this corner". Detail density scales with tokens and fix turns, and each fix turn is a diff against a 54 KB class. |
| No eyes | The model never sees the room. Test Flight checks boot/enable/commands, not looks. No feedback loop means safe, boxy output. |
| Palette = config knobs | Themes became 3 configurable materials so `config.yml` stays editable. Real builds use 15-30 blocks (stairs, slabs, walls, trapdoors, fences, block-state variants). |
| Hard size constraints | The 32-block slot per run plus the golden's slow build rate (64 blocks per 2 ticks is about 640 blocks/s; a 40x24x40 shell with about 15k blocks would take about 25 s) push the model to small rooms. |
| Block states are hard in code | Stairs facing, slab halves, wall connections and lantern hanging all need `BlockData` casts. LLM code avoids them, so the result is flat full blocks. |
| Stage pressure | The 33-stage run spent its turns on creatures and bosses. Rooms got one fix turn (stage 8). |

## 2. Options compared

| | A. Hand-built templates + placer | B. Room Studio (model writes a spec, Cyrus compiles it) | C. Vanilla datapack jigsaw / template pools | D. Procedural grammar over a module kit | E. Community schematics |
|---|---|---|---|---|---|
| Quality ceiling | Highest: human build, any block or state | Medium-high: limited by the spec ops plus decoration passes, and rises with good examples | As good as its templates | As good as its modules, with endless layouts | Varies; often great |
| Size | 48x48x48 per structure-block save (bigger rooms = 2+ pieces); WorldEdit has no cap | Compiler cap today 48 per side, 32,768 blocks, 32-entry palette (`WORLDGEN_LIMITS`) | Pieces up to 48³; jigsaw depth up to 20, `max_distance_from_center` up to 128 | Same as modules | Any |
| Works for an instanced void-world dungeon | Yes: the plugin controls when, where and how | Yes, same placer | **Poor**: worldgen applies to new chunks only, needs a restart, gives no per-run control. `/place jigsaw` from the plugin is possible, but template_pool is a worldgen registry, so it needs a restart and processors have no emitter yet | Yes | Yes, but see licence |
| Vanilla client | Yes (server-side blocks only) | Yes | Yes | Yes | Yes |
| Owner effort | 30-90 min per room in creative | None (prompt) | None | Builds modules with connectors | Low |
| Cyrus effort (agent-days) | about 5 (lane + placer golden + flight probe) | 8-12 after A | 4-6 (jigsaw/pool/processor emitter) | 5-8 after A | about 3 plus legal review |
| Already in repo | `nbt.ts` reader/writer (8 MB read cap), `template.ts` compiler, `mc-structures` golden (StructureManager) | `template.ts` (ASCII layers to `.nbt`, deterministic), `versions.ts` block-state tables per version, modelstudio Playwright preview | worldgen lane emits single-piece jigsaw (`emitTemplatePool`, `size: 1`) | nothing | library ledger types (`licence`, `licenceStatus`) |
| Training-data value | **Gold**: (theme brief, sidecar) to (`.nbt` and its reverse-compiled layer spec) pairs for B | Self-play: spec, preview, owner rating | Low for the dungeon | Medium: layout graphs | Low (unclear provenance taints data) |
| Main risk | Upload security (block entities), paste lag | Generic-looking output without examples | Restart and new-chunk-only rules; a broken pack stops the server | Doorway alignment bugs | Licence |
| Verdict | **Do first** | **Do second** | Skip for dungeon | Third | Avoid unless CC0/CC-BY |

### Tools the owner can build with (facts)

| Tool | Client need | Export | Licence / cost | Use for |
|---|---|---|---|---|
| **Vanilla structure block** (`/give @s structure_block`, SAVE mode) | none | `.nbt` to `<world>/generated/<namespace>/structures/<name>.nbt`, max 48x48x48 | vanilla | **Recommended default.** Zero setup; the file is exactly what Bukkit `StructureManager` loads |
| WorldEdit (Paper plugin) `//pos1 //pos2 //copy //schem save <name>` | none (wand works in vanilla) | Sponge `.schem` (v3 on WE 7.3+) in `plugins/WorldEdit/schematics` | GPL-3.0, free | Bigger rooms, fast fills, `//replace`, `//smooth`, brushes; Cyrus converts `.schem` to `.nbt` on upload |
| FAWE | none | `.schem` | GPL-3.0 | Same as WE, faster on the build server. **Not** a runtime dependency of generated mods |
| Axiom (Fabric client mod + MIT Paper plugin) | Fabric client for the builder only | Blueprints (`.bp`); `.schem` import/export to verify in his version | Free for non-commercial use; commercial licence for professional builders; multiplayer needs a licence or whitelist | Best-in-class sculpting/painting if the owner is willing to run Fabric while building |
| Litematica (Fabric client) | Fabric for the builder | `.litematic`; can export a vanilla structure in recent versions (verify) | LGPL-3.0 | Optional; Cyrus can also convert `.litematic` (NBT, packed long arrays) |

Players never need any of these. Only the builder's own creative session does.

## 3. Recommended hybrid and staged roadmap

### Stage 0 (this week, owner, no code): build the kit

- Use a creative superflat world on the same MC version as the server (1.21.11 recommended; DataVersion must not be newer than the server).
- **Size standard:** footprint 40x40 (also allowed: 24x24, 32x32, 48x48 boss arenas), height up to 24, origin at the north-west bottom corner. Entry on the south wall centre, exit on the north wall centre, doorway 3 wide x 4 high. A standard doorway lets stage D join modules later.
- Per theme (castle, lava, swamp, ice, crypt, ruins, throne): 8-10 combat, 2 treasure, 1 shrine, 1 trap, 1 elite, 1 boss arena. That is about 13 rooms per theme, 15 maximum.
- Place markers (section 5), save with a structure block named `<theme>_<type>_<nn>` (for example `crypt_combat_03`), and collect the `.nbt` files.

### Stage 1 (about 5 agent-days): `structures` asset lane + placer

**Files the owner hands over**

```
rooms.zip
  rooms/castle/castle_combat_01.nbt      (or .schem / .litematic -> converted)
  rooms/castle/castle_combat_01.json     (optional sidecar; Cyrus fills defaults)
  rooms/lava/...
```

**Sidecar** (Cyrus generates it from the markers if missing; the owner edits weights in the studio):

```json
{ "id": "castle_combat_01", "theme": "castle", "type": "combat", "weight": 1,
  "minFloor": 1, "maxFloor": 11, "size": [40, 24, 40],
  "markers": { "entry": 1, "exit": 1, "mob": 9, "elite": 1, "chest": 2, "trap": 3 },
  "rotate": true, "mirror": true, "author": "owner", "licence": "owner-original" }
```

**Upload / validation rules** (new; today the portal only takes images: `CYRUS_MAX_IMAGE_BYTES` 5 MB x 4 in `lib/cyrus/uploads.ts`, and studio uploads are PNG-only and switched off in production, `lib/cyrus/studios/uploads.ts`):

| Rule | Value |
|---|---|
| Accepted | `.nbt` (gzip), `.schem` (Sponge v2/v3), `.litematic`; or a `.zip` of them |
| Size | 2 MB compressed per file, 8 MB decompressed (reuse `NBT_READ_LIMITS`), 120 files / 40 MB per zip |
| Dimensions | each side 48 or less (raise `templateSide` for rooms only if needed); 60k non-air blocks or fewer |
| DataVersion | 1.21.x and no newer than the target version (`versions.ts` dataVersion) |
| Block whitelist | refuse `command_block` (all 3), `structure_block` except DATA mode markers, `jigsaw`, `spawner` with entity NBT (v1), and `barrier` outside allowed use. Validate block states against `versions.ts` `blockStates` |
| Block-entity sanitiser | keep chest/barrel (drop items, LootTable set by placer), sign text (**strip clickEvent/run_command**), banner patterns, skull (vanilla profiles only), decorated pot, lectern (strip book), flower pot. Drop anything else |
| Entities | v1: drop entities (armour stands, item frames, paintings). v2: allow paintings/item frames with sanitised NBT |
| Provenance | `CyrusProjectAsset` new kind `structure`, origin `upload`, ledger "uploaded by the customer: rights declared, not verified" (same as `library/upload.ts`) |
| Preview | render an isometric/three.js voxel view (reuse the modelstudio Playwright preview pipeline) plus a marker overlay and counts |

**Packaging:** the build service copies `structures/<theme>/<id>.nbt` + `.json` into `src/main/resources/structures/...` (binary resources, not Java, so the scan's "encoded blobs" rule does not apply; whitelist `.nbt` in the jar profile). About 72 rooms x 20-60 KB each is about 2-4 MB of jar.

**Plugin API (Paper 1.21.x), which the placer golden must show:**

| Step | Call |
|---|---|
| Load | `StructureManager sm = getServer().getStructureManager(); Structure s = sm.loadStructure(getResource("structures/castle/castle_combat_01.nbt"));` then `sm.registerStructure(new NamespacedKey(this, "room/castle/castle_combat_01"), s)` |
| Read markers | `s.getPalettes().get(0).getBlocks()` returns a list of `BlockState` with relative positions. Collect marker blocks (glazed terracotta type plus `Directional` facing) and DATA structure blocks (`org.bukkit.block.Structure#getUsageMode()==DATA`, `getMetadata()`) |
| Rotate/mirror | `StructureRotation` x `Mirror` (8 variants), with marker coordinates transformed the same way |
| Paste | **Batched**: walk the palette block list and call `block.setBlockData(state.getBlockData(), false)` N per tick through the existing `NxPerf.Queue`. Start at about 2,000 blocks per tick and tune from flight timings. Markers become air. Alternative one-shot: `s.place(loc, false, rot, mirror, 0, 1f, rnd)` for rooms under about 8k blocks |
| Populate | mobs at `mob` markers (MonsterManager roster by theme/floor), `LootTable`/the existing LootManager for chests, traps from the trap legend, exit door = iron bars/barrier in the doorway until the room objective is done |
| Cleanup | before the next floor: clear the room's bounding box batched (or delete the run's void world on leave, as today) |
| Slot | raise the per-run slot from 32 to **128 blocks** (48 room + margins; boss arenas fit) |

**Planner/prompt:** add lane `structures` next to `datapack`/`worldgen` in `services/modbuilder/planner.js` (it triggers when the project holds structure assets or the prompt names "rooms from my builds"). Add a sheet rule in `services/modbuilder/sheets/*.md`: "Rooms: load prebuilt templates from `structures/`, never hand-place room shells in loops." Add a new golden `mc-room-templates`.

**Test Flight validation** (pattern from `lib/cyrus/testflight/worldgen.ts` probes):
1. Boot, then run `dungeon admin paste <theme>/<id> <rot>` for every room (or a sample of 8) in the void world.
2. The plugin prints `PASTE ok id=.. blocks=.. ms=.. maxTickMs=.. markers=mob:9,chest:2,...`; the runner compares this with the sidecar.
3. Probe: `execute in <dungeon world> run fill <box> air replace lime_glazed_terracotta` reports 0 (no marker left behind). Spot-check the light level at mob markers. Run a reachability check (entry to exit) offline on upload.
4. Record `maxTickMs`. Fail if above 50 ms, warn if above 25 ms. Never blocks Install (like the existing worldgen probes).

### Stage 2 (8-12 agent-days): Room Studio (Cyrus authors rooms)

| Piece | Design |
|---|---|
| Spec | `room.v1`: `size` (20-48 x 3-24 x 20-48), `palette` (32 or fewer chars mapping to block + state, validated by `versions.ts`), `layers` (ASCII y-slices; `.` = void) **or** ops: `box`, `hollow`, `pillar_grid`, `arch`, `stairs`, `pit`, `bridge`, `lava_pool`, `balcony`, `mirror(x|z)`, `array(n, dx, dz)`, `rotate`; decoration passes `cobweb(density, corners)`, `moss(spread)`, `cracks(%)`, `lanterns(spacing, hang)`, `chains`, `banners`, `rubble`; `markers[]` |
| Compile | ops to layers (pure TS), then `compileTemplate()` (existing, deterministic) to `.nbt`, plus the sidecar |
| Validate | walkable path entry to exit (BFS with 2-high headroom and gaps of 1 or less), every mob marker reachable, light level of 8 or more on the main path (configurable), no floating lava source over the path, block count and palette caps |
| Preview | voxel render plus top-down slice view in the studio (same Playwright pipeline as modelstudio/creature previews); the owner can click "regenerate this pass" |
| Learn | few-shot from the owner's Stage 0 kit (reverse-compile `.nbt` to layers with `nbt.ts` `readNbt`); rate and keep in a room library |

### Stage 3 (5-8 agent-days): procedural floors from modules (D)

- A floor becomes a graph of 3-6 modules (start, combat x N, treasure/shrine side branch, exit), laid out on a 48-grid with BSP or a simple graph walk. Doorways match because of the Stage 0 standard. Corridors are their own small modules (8x8, 16x8).
- WFC is optional, over corridor tiles only. Hand-quality rooms plus random arrangement gives every run a different layout without bland rooms.

## 4. Capability gaps, file pointers, effort, risks

| Gap | Where | Effort (agent-days) | Training value |
|---|---|---|---|
| No structure/schematic upload (portal takes images only) | `lib/cyrus/uploads.ts`, `lib/cyrus/studios/uploads.ts` (prod upload store pending owner decision) | 1.5 | provenance-tagged gold rooms |
| `.schem`/`.litematic` to `.nbt` converter + sanitiser | new `lib/cyrus/structure/` (reuse `datapack/worldgen/nbt.ts`) | 1.5 | - |
| Asset kind `structure` | `CyrusProjectAsset.kind`, `lib/cyrus/assets/kinds.ts` (`BUILD_ASSET_KINDS` = texture, sound, creature), `structure/parts.ts` PART_META | 0.5 | - |
| Placer golden + sheet rule | `services/modbuilder/golden/plugins/mc-room-templates` (new); sheets say "Structures (no schematic files)" today | 1.5 | teaches the model the data-driven pattern |
| Coverage rows | `docs/cyrus/minecraft-coverage.md`: `structure_placement` row ("building from a schematic file is not supported"; "WorldEdit schematics are not supported"), `dungeon_crawler` limit ("room templates placed a few blocks per tick"), gap #4 (jigsaw pools) | 0.25 | - |
| Planner lane `structures` | `services/modbuilder/planner.js` (lanes today: texture, itemStates, sound, model3d, creature, design*, motion, config, datapack, worldgen, library) | 0.5 | - |
| Test Flight paste probe | `lib/cyrus/testflight/` + runner `services/modbuilder/tools/testflight/` | 1.5 | paste timings dataset |
| Template caps for rooms | `WORLDGEN_LIMITS` in `datapack/worldgen/spec.ts` (side 48, 32,768 blocks, palette 32, loot 16) | 0.25 | - |
| Room Studio | new `lib/cyrus/roomstudio/` + studio UI + preview | 8-12 | highest long-term |
| Multi-piece jigsaw emitter (C) | `datapack/worldgen/emit.ts` (`size: 1` only; "multi-piece jigsaw structures" listed as unsupported) | 4-6 | low for dungeon |
| Module-graph floors (D) | placer extension | 5-8 | medium |

| Risk | Mitigation |
|---|---|
| Paste lag (one-tick `Structure.place` of 15-30k blocks causes a visible hitch) | batch through `NxPerf.Queue`, measure `maxTickMs` in flight, paste the next room while the player is in the reward screen |
| Chunk loading | force-load the room's chunks (`setChunkForceLoaded`/plugin chunk ticket) before pasting, release after cleanup; 48x48 spans up to 4x4 chunks |
| Lighting | Paper's light engine relights asynchronously after `setBlockData(...,false)`. Expect a few ticks of dark patches; paste lights last; verify by light-level probe |
| Physics/fluids | `applyPhysics=false`; place lava/water last; avoid sand/gravel over air in templates (validator warning) |
| Block-entity payloads (command blocks, sign click commands) | the sanitiser whitelist above; refuse otherwise |
| FAWE async paste | do not depend on it: generated mods are self-contained (no soft deps by policy), FAWE is GPL-3.0 and not on test servers. Vanilla `StructureManager` + batching is enough at about 40k cells |
| Cleanup/regeneration | clear the bounding box batched or reuse the slot; on leave/abandon the existing per-run void world cleanup still applies |
| Instance isolation | one 128-block slot per run in the existing void world; never paste outside the slot; slot free-list already exists (`freeSlots`) |
| DataVersion skew | refuse templates newer than the target; older ones are upgraded by the server's DataFixer on load |
| Licence | owner-original or customer-declared only; no scraped schematics |

## 5. Marker legend v1 and an example room

### Marker legend

Markers are placed **where the thing's feet go** (one block above the floor). The placer replaces them with air (or with `"replace"` from the sidecar). The glazed terracotta arrow shows facing.

| Marker block | Meaning | Optional DATA string (structure block in DATA mode, same spot) |
|---|---|---|
| `light_blue_glazed_terracotta` | **Player entry** (exactly 1), arrow = facing | `entry` |
| `magenta_glazed_terracotta` | **Exit door**: bottom-centre of the 3x4 doorway (exactly 1); placer seals it with iron bars until cleared | `door:exit` / `door:secret` |
| `lime_glazed_terracotta` | Normal mob spawn point | `mob:melee` / `mob:ranged` / `mob:swarm:4` |
| `red_glazed_terracotta` | Elite (combat/elite rooms) or **boss** (boss arena, exactly 1) | `elite` / `boss` |
| `orange_glazed_terracotta` | Trap trigger; type from DATA, else random by theme | `trap:arrow` / `trap:fire` / `trap:spikes` / `trap:collapse` |
| `chest` / `barrel` (real ones) | Loot: placer clears items and sets the loot tier by room type + floor | `chest:treasure` / `chest:hidden` |
| `trapped_chest` | Mimic or trapped loot | `chest:mimic` |
| `yellow_glazed_terracotta` | Objective object (shrine altar, lever puzzle spot) | `objective:shrine` |
| `purple_glazed_terracotta` | Doorway **connector** for future module joining (3x4 opening, centre bottom) | `connector:n|s|e|w` |

Rule: do not use glazed terracotta as decoration in these rooms, or set `"markerSet": "data-only"` in the sidecar so only DATA structure blocks count.

### Example: "Crypt of the Fallen Kings" (crypt_combat_01), 40 x 24 x 40

Coordinates relative to the save origin (x east, z south, y up). Exit is north (z=0), entry south (z=39).

| Layer / part | What to build |
|---|---|
| Shell (y0-23) | Walking floor surface at y3 (solid y0-2 under it, except the nave pit): `deepslate_tiles` with 15% `cracked_deepslate_tiles` and `cobbled_deepslate` patches. Walls 2 thick: outer `deepslate_bricks`, inner face `polished_deepslate` with `chiseled_deepslate` every 6 blocks. Ceiling y23: `deepslate_tiles`, vaulted with stair arches every 8 blocks (`deepslate_brick_stairs` upside-down) |
| Main hall (x8-31, full z) | Two rows of 5 pillars (3x3) at x=10 and x=29, every 7 blocks in z. Pillar = `polished_basalt` core, `deepslate_brick_wall` corners, `chiseled_deepslate` cap at y8, lower then upper capital at y16. Hanging `soul_lantern` on 4-long `chain` from the ceiling between pillars |
| Sunken nave (x14-25, z8-31) | 3 blocks deep: y0 is the pit bottom, the main hall walking floor is a 3-thick slab at y0-2 (top surface y3) everywhere else. Pit floor `soul_soil` + `soul_fire` in 4 braziers (`polished_blackstone` rim). Two `deepslate_brick_slab` bridges cross the pit at z=14 and z=26, with `iron_bars` railings |
| Side crypts (x2-7 and x32-37) | 5 alcoves per side, 4 wide, 4 deep, 5 high, under `deepslate_brick_stairs` arches. Each holds a "sarcophagus": 1x2 `polished_deepslate` + `deepslate_brick_slab` lid, `skeleton_skull` on top, `cobweb` corners (30%), `sculk_vein` drips on the walls |
| Balcony (y10-11 ring) | 3-wide gallery around the room on `deepslate_brick_slab` supported by upside-down stairs corbels; railing `deepslate_brick_wall`; reached by spiral stairs in the NE and NW corners (2x2 core, `deepslate_brick_stairs`). Archers stand here |
| North end: exit dais (x14-25, z1-6) | 3 steps up (y3 to y6), `chiseled_deepslate` throne-like statue of a king: `polished_deepslate` body, `deepslate_brick_wall` arms, `skeleton_skull` head with `soul_lantern`s flanking. Black and purple `banner`s on the wall. Exit doorway 3x4 at x18-20, z0, y6 |
| South end: entry (x18-20, z39) | 3x4 doorway at y3, a short landing, cracked floor, a broken `chain` hanging |
| Decoration pass | `cobweb` in upper corners (density about 25 per room), `moss_carpet` 0, `sculk` patches on the pit floor, `candle`s (purple, 1-4) on sarcophagi, a few `bone_block` piles, `soul_lantern` light every 7 blocks along the walls at y5. Keep light level of 8 or more on the path; let alcoves stay dark |

| Markers | Where |
|---|---|
| `light_blue_glazed_terracotta` facing north | (19, 4, 37) |
| `magenta_glazed_terracotta` | (19, 7, 0), bottom-centre of exit doorway |
| `lime` x6 `mob:melee` | the alcove fronts: (6,4,8) (6,4,18) (6,4,28) (33,4,8) (33,4,18) (33,4,28) |
| `lime` x3 `mob:ranged` | balcony: (3,12,20) (36,12,20) (19,12,38) |
| `red` x1 `elite` | pit centre (19, 1, 20) |
| `orange` x2 `trap:collapse` | bridge mid-points (19,4,14) and (19,4,26), with the slabs above falling into soul fire |
| `orange` x1 `trap:arrow` | (19, 4, 33), dispensers hidden in the side walls at y5 |
| `chest` x1 `chest:treasure` | behind the statue (19, 7, 2) |
| `barrel` x1 `chest:hidden` | inside the 3rd west alcove behind a `cracked_deepslate_bricks` false wall (3, 4, 18) |

Block count is roughly 16-20k non-air, palette about 28 entries, so it fits one structure-block save (48³ maximum). Build time for a practised builder with WorldEdit is about 60-90 minutes.

## Evidence index

- `/root/cyrus-eval/dungeon-2026-10-15/journal.json` (33 stages; stage 8 rooms fix; stage 33 build `mb51322a365e1e9476d7be`)
- `/var/lib/nxeon/modbuilds/mb51322a365e1e9476d7be.jar`: `DungeonManager.class` constants, `config.yml`
- `/opt/nxeon/services/modbuilder/golden/plugins/mc-structures/src/.../Structures.java` (StructureManager golden; no files)
- `/opt/nxeon/services/modbuilder/golden/plugins/mc-instanced-dungeon-lite/src/.../Dungeon.java` (64 blocks per 2 ticks)
- `/opt/nxeon/lib/cyrus/datapack/worldgen/{template.ts,nbt.ts,spec.ts,emit.ts,versions.ts}`
- `/opt/nxeon/lib/cyrus/testflight/worldgen.ts` (probe pattern)
- `/opt/nxeon/docs/cyrus/minecraft-coverage.md` lines 161, 1164-1202, 1225
- `/opt/nxeon/lib/cyrus/uploads.ts`, `/opt/nxeon/lib/cyrus/studios/uploads.ts`, `/opt/nxeon/lib/cyrus/library/upload.ts`
- Web: Axiom Paper plugin page on Modrinth (MIT plugin; client free for non-commercial use, commercial licence for pros). Microsoft Learn jigsaw reference (horizontal `max_distance_from_center` 1-128).

## To verify before building (not checked here)

- Paper 1.21.11: `StructureManager.loadStructure(InputStream)` and `Palette.getBlocks()` on the exact API jar (add to `sheets/api-facts.json`). Also whether the `place(..., Collection<BlockTransformer>, ...)` overload exists on 1.21.1.
- Real paste cost per tick on node-2 hardware (first flight of the placer golden).
- Axiom and Litematica export formats in the owner's versions.

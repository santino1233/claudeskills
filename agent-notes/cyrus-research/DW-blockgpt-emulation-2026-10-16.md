# DW: Emulating blockgpt.ai as a Cyrus "Structure Studio" (2026-10-16)

This is research only. No accounts were created, nothing was paid for, and the paywall was not touched. No code was changed.
Companion note: **DV-room-generation-options-2026-10-16.md** covers the in-plugin placer, the marker legend v1, hand-built room kits and the Room Studio spec sketch. This note does not repeat DV. It adds the competitor facts, the file formats, the user-facing studio, pricing and differentiation. The DV marker legend is used here unchanged.

Evidence labels used throughout:
- **FACT**: seen on a public page or in a public file. The source is listed in section 9.
- **INF**: inference from that evidence.
- **VERIFY**: from memory or unconfirmed. Check it before building on it.

## TL;DR

- **What BlockGPT is (FACT).** A Next.js web app. Text or an image goes in, and about 30 s later you get one static schematic: `.schem`, `.litematic`, legacy `.schematic` or Bedrock `.mcstructure`.
  - 5 free previews a day, which cannot be downloaded.
  - $1 for a 24 h trial, then Standard at $19/mo for 50 builds. Basic is $9/mo for 12 builds and Pro is $49/mo for 200 builds.
  - Commercial use is allowed only on Pro.
  - The public gallery holds about 15k builds (261 pages) and its downloads are free.
  - It also has a sister product, **"BlockGPT Mods"** (mods.blockgpt.ai): a no-code visual mod creator in the style of Blueprints. On 2026-01-17 it was "coming soon" for Pro users. **That product competes directly with Cyrus's core business.**
- **How it probably works (INF, medium-high confidence).** It is not an LLM placing blocks. It looks like text or image → 3D mesh → voxelise → match each voxel's colour to a block from an "all release blocks" palette.
  - The one public gallery file inspected was 185×118×185.
  - It used 86 palette entries, all full cubes.
  - It had **zero block states, zero block entities and zero entities**.
  - Blocks were picked for colour, not function: ores, glazed terracotta, sculk, bedrock, reinforced deepslate.
- **What it cannot do (FACT/INF).** It outputs no gameplay data at all: no loot chests, spawners or markers, no stairs/slabs/doors with orientation, no lighting plan and no guaranteed walkable paths. BlockGPT's own blog admits AI builds are often "pretty shells" with missing doors and bad lighting.
- **The Cyrus plan.** An LLM writes a typed **room spec**: ops, palette, symmetry, decoration passes and a marker legend. A deterministic TypeScript validator and compiler then always produces a valid, walkable, lit room. That room is:
  1. previewed in a three.js studio with a slice view,
  2. exported as `.schem` / `.litematic` / `.nbt` / `.mcstructure`, and
  3. **wired directly into the generated dungeon plugin**, which places the mobs, loot, traps, doors and boss.
- **Cost.** About 40-60 Cyrus tokens per standard generation (about $0.08-0.12 of model cost). That is roughly $0.35-0.50 at current top-up prices, comparable to BlockGPT's $0.25-0.75 per build.
- **Effort.** About 14-19 agent-days to reach a paid v1, plus 4-6 for image-to-room later.
- **Biggest risk.** LLM spatial quality at 64×32×64. A spec that is valid but generic gives "boxy rooms" again. The mitigations are an op vocabulary with strong defaults, theme kits, decoration passes, a few-shot set taken from the owner's hand-built rooms (DV stage 0), and a render-and-critique repair loop.

---

## 1. What BlockGPT does (facts)

### 1.1 Product and limits

| Item | Value | Evidence |
|---|---|---|
| Input | Text prompt, or an uploaded image ("characters, objects, people, buildings ... rebuilt as 3D, not flat pixel art") | FACT, homepage |
| Generation time | about 30 s | FACT, homepage FAQ |
| Options before generating | size/scale, block palette, export format, "Basic or Pro model" | FACT, homepage FAQ; build page shows "Scale: 120% of default size", "Palette: all release blocks" |
| Export | Java: `.schem` (WE/FAWE), `.litematic`, `.schematic` (legacy, 1.12 and older). Bedrock: `.mcstructure` | FACT, homepage, /how-to, /pricing |
| Size caps | No numeric cap is published. /how-to warns that Bedrock structure blocks can't place builds wider or deeper than 64. Gallery prompts ask for 200×200 up to 1200×1200; the inspected file was 185×118×185 | FACT (how-to), FACT (one file) |
| Free tier | 5 previews/day, no account. "Full renders but not downloadable." The FAQ also says "no free plan" | FACT, homepage |
| Trial / paywall | "Get 24 hours of full access for $1. Then $19/mo, cancel anytime", "50 builds in 24 hours", "Text or an image, both work", "BlockGPT Super, coming soon, included at no extra cost" | FACT, owner screenshot 26.png (`/try?prompt=…`) |
| Plans | Basic $9/mo, 12 builds, personal use. Standard $19/mo, 50 builds, personal use. Pro $49/mo, 200 builds, **commercial use**, "premium packs", priority queue | FACT, /pricing |
| Refunds | 14-day money-back guarantee | FACT, /pricing, /terms |
| Gallery | "15,000+ public builds", free download with no account. 261 pages, static PNG thumbnails, a public Supabase storage URL per `.schem` | FACT, homepage, /gallery, /build/* |
| Hosting | Next.js (`/_next/image`, Vercel-style `dpl_` deploy id). Supabase Storage for files and thumbnails, plus some Tencent Cloud COS | FACT (URLs); "Vercel" is INF |
| Roadmap | Visual scripting mod creator ("Think Unreal Engine's Blueprint system, but for Minecraft ... export a working mod"), Pro beta "coming soon". Goal: "builds that need less manual adjustment after import" | FACT, blog 2026-01-17; mods.blockgpt.ai is a title-only page |
| Social | X @blockgptai (pinned post 2025-12-13; X returned 402 to fetch). No Reddit, YouTube or Product Hunt traction was found | FACT / absence |
| Operator / law | "BlockGPT", governed by Australian law; terms last updated 26 Jul 2026 | FACT, /terms |
| Name collisions | Unrelated "BlockGPT" Spigot and Modrinth chat-help plugins exist | FACT |

### 1.2 Output quality: one public gallery file

The owner's screenshot shows the boss-room output: a circular dark arena with lava, stalagmite-like pillars and an orange "fire" blob.

To check output quality, one file was downloaded **once**, by hand, from the public link that the gallery offers as a free download ("A Large Gothic Mega Fortress ..."). No API was called and nothing was automated beyond that single GET. It was parsed offline with a small stdlib NBT reader.

| Property | Value |
|---|---|
| Format | Sponge **v2**, root compound `Schematic`, `DataVersion 3105` (1.19.x) |
| Size | 185 × 118 × 185 = 4.04 M cells, 134,592 non-air (3.3%) |
| Palette | 86 entries. **Every one is a plain full-cube id with no block-state properties** |
| Block entities / entities | none / none |
| Notable picks | black_concrete 38k, sculk 14k, light_gray_glazed_terracotta 12k, coal_block 10k, sea_lantern 9k (the only light source), deepslate_emerald_ore / diamond_ore / emerald_ore, **bedrock**, **reinforced_deepslate**, netherite_block |
| Missing | No stairs, slabs, walls, fences, doors, trapdoors, glass panes, chests or torches |

**What this means (INF, medium-high confidence):**
- Blocks were chosen by **colour match**. Ores, glazed terracotta and sculk are used as pigments, and survival-unobtainable blocks are used freely.
- The pipeline is most likely **text → (image) → 3D mesh → voxeliser → nearest-colour block palette**.
  - This is the same family of technique as ObjToSchematic. The image-to-3D step could be TRELLIS-class or Hunyuan3D-class models; this is unconfirmed, and the Tencent COS bucket is a weak hint only.
  - "Pro holds more detail" most likely means a higher voxel resolution or a better 3D model.
  - "Scale" most likely sets the voxel grid size.
- The 3D preview on `/try` is probably a rendered voxel view, or a PNG, of the same grid. Gallery pages only show PNGs.
- One sample is not the whole product. The pipeline may have changed since November 2025, so **VERIFY with 2-3 more public gallery files** if this matters. That would be manual fetches only, never scraping.

### 1.3 What it cannot do (for game use)

| Gap | Evidence |
|---|---|
| No gameplay data: no markers, spawners, loot tables, trap or boss metadata | FACT (sample has no block entities); the product sells "a schematic" only |
| No functional block states (stairs facing, slab halves, doors, lanterns) | FACT (sample); INF (consistent with voxelisation) |
| No guaranteed access or lighting. BlockGPT says AI builds are often "decorative ... pretty shells", with "missing doors, stairs that lead nowhere", and AI "rarely places torches" | FACT, BlockGPT blog 2026-01-16 |
| Survival-unfriendly palette (bedrock, reinforced deepslate, ores) | FACT (sample) |
| Interiors are hollow or arbitrary: 3.3% fill, a mostly shell volume | FACT (sample); INF (room interiors are not designed) |
| No editing after generation except regenerating or swapping the palette | FACT (how-to: "swap blocks in settings and regenerate") |
| No plugin, datapack or mod integration (the "Mods" product is separate and unreleased) | FACT |
| Bedrock above 64 wide/deep needs Amulet | FACT (how-to) |

### 1.4 ToS points relevant to us (FACT, /terms, updated 26 Jul 2026)

- The terms forbid "reverse engineer, scrape, or use automated means to access the Service". **We must not scrape the gallery or call their endpoints.** This note used only public pages and one manual download.
- Users keep their inputs and may use the builds. BlockGPT takes a licence to display public builds.
- Commercial use is Pro-only per /pricing.
- Many public gallery builds depict copyrighted characters ("Batman", "Charizard", "Spongebob house", "Ironman"). That is BlockGPT's IP exposure. **Cyrus must not import gallery files** as training data or templates.

---

## 2. Likely technical approach, and why Cyrus should do something different

| Stage | BlockGPT (INF) | Evidence level | Cyrus Structure Studio (proposal) |
|---|---|---|---|
| Prompt to geometry | Text → image / 3D generator → mesh | medium (palette fingerprint, "not flat pixel art", ~30 s) | LLM → **typed room spec** (ops + markers), compiled deterministically |
| Geometry to blocks | Voxelise + colour quantise to the full-cube palette | high (sample) | Ops expand to block **states** (stairs facing, slabs, walls) from theme kits |
| Function | none | high | Validator: BFS walkability, headroom, light ≥ N, door rules, marker counts |
| Preview | Rendered voxel image | low | Client three.js greedy-meshed voxels, Y-slice, marker overlay; server PNG via the existing Playwright golden pipeline |
| Image input | Image-to-3D model | medium | Phase 2: vision LLM → spec (layout/theme/palette), **not** a mesh |
| Output | Static schematic | high | Schematic **plus** sidecar JSON **plus** wired into the plugin |

Why not copy the mesh-voxel route? It is good at statues and sculptures but bad at rooms that must be playable. It also needs a GPU image-to-3D model (TRELLIS is MIT but needs a GPU host; Hunyuan3D has a restrictive regional licence, VERIFY). Cyrus's lane is **functional game spaces**. Statue or "build my friend" mode could be an optional Phase 3 using TRELLIS.2 (MIT) plus our own voxeliser.

---

## 3. Open-source and academic state of the art

| Work | What it does | Representation | Reusable? Licence |
|---|---|---|---|
| **T2BM**, "3D Building Generation in Minecraft via LLMs" (arXiv 2406.08751, IEEE CoG 2024) | Prompt refinement → interlayer representation → repair; facades, interiors, doors, beds | Intermediate JSON-like building description + repair loop | Idea only (paper under the arXiv non-exclusive licence; no code found) |
| **APT** (arXiv 2411.17255) | Chain-of-thought layout → blueprint of (block, x, y, z) tuples → Mineflayer agent builds it; reflection loop | Coordinate tuples | Idea only (VERIFY code) |
| **Word2Minecraft** (arXiv 2503.16536) | Story → 2D tile grid (LLM) → blocks; A* and BFS playability checks; objectives (enemy, NPC, maze, waves, collect) | ASCII tiles + scaling algorithm | **Closest to our idea** (playability validation). Code at github.com/JMZ-kk/Word2Minecraft, licence not stated, so treat as unusable |
| MC-Bench / minebench (2025-26) | LLM build arenas; models get primitives (Line, Box, Square ...) and write JS | Code calling voxel primitives | Confirms that **primitive ops beat raw voxel lists** for LLMs. Licence unknown |
| CyniaAI **BuilderGPT** | NL → `.schem` / `.mcfunction` via an LLM; paused, successor "MineClawd" | MCBench-style JS representation | Apache-2.0: patterns reusable with notice; we don't need its code |
| GDMC settlement challenge (2018-) | Procedural settlement generation on unseen maps; human-judged | Python HTTP interface | Evaluation ideas (adaptivity, functionality, narrative, aesthetics) |
| Voyager / MineDojo | Embodied agents (skills / code); not structure generators | Mineflayer JS | MIT (VERIFY) but not useful here |
| Craftax | 2D JAX Minecraft-like RL benchmark | n/a | Irrelevant |
| **ObjToSchematic** (Lucas Dower) | Mesh → voxels → block palette by colour → `.schematic/.litematic/.schem/.nbt` | Mesh voxelisation | BSD-3-Clause. The best reference for a Phase 3 statue mode and for colour palettes. v1 repo is unmaintained; v2 is the website |
| **TRELLIS / TRELLIS.2** (Microsoft) | Image (and v1 text) → 3D; TRELLIS.2 uses a sparse voxel "O-Voxel" | Sparse voxels / mesh | MIT (model card); needs a GPU. Phase 3 only |
| BrickGPT (arXiv 2505.05469) | Fine-tuned LLM emits physically stable brick structures token by token with a validity check and rollback | Brick sequence + physics check | Idea: **constrained decoding + rollback**, which maps to our validator-repair loop |

**Takeaways for the design:**
1. LLMs are reliable at *layout + ops + semantics* and unreliable at long raw voxel arrays. A 64×32×64 room is 131k cells, which is too many tokens to write raw.
2. Validation and repair loops (T2BM, Word2Minecraft, BrickGPT) are what make output playable.
3. The few-shot quality bar comes from good examples, which DV stage 0 hand-built rooms supply.

---

## 4. File formats and libraries

### 4.1 Formats

| Format | Encoding | Key structure | Size notes | Who loads it |
|---|---|---|---|---|
| **Sponge `.schem` v2** | gzip, big-endian NBT | Root `Schematic`{Version 2, DataVersion, Width/Height/Length (short), Offset int[3], PaletteMax, Palette{state→idx}, BlockData varint bytes, BlockEntities[{Pos, Id, ...}], Entities} | index = `x + z*W + y*W*L`; shorts mean up to 65535 a side | WorldEdit / FAWE (all modern) — what BlockGPT ships |
| **Sponge `.schem` v3** | gzip NBT | Unnamed root → `Schematic`{Version 3, DataVersion, Width/Height/Length, Offset, Metadata{Name, Author, Date, RequiredMods}, **Blocks**{Palette, Data varint, BlockEntities[{Pos, Id, Data}]}, Biomes{Palette, Data}, Entities[{Pos, Id, Data}]} | same index order | WorldEdit 7.3+ (VERIFY minimum); **write v3 by default, offer v2 for older WE** |
| **Litematica `.litematic`** | gzip NBT | Root {Version (6/7, VERIFY per 1.21.x), SubVersion, MinecraftDataVersion, Metadata{Name, Author, Description, EnclosingSize, TimeCreated, TimeModified, TotalBlocks, TotalVolume, RegionCount}, Regions{name:{Position, Size, BlockStatePalette[{Name, Properties}], BlockStates long[] bit-packed (bits = max(2, ceil(log2 n))), values may span longs, TileEntities, Entities, PendingBlockTicks, PendingFluidTicks}}} | index = `x + z*sx + y*sx*sz`; palette index 0 = air | Litematica (Fabric/NeoForge client) |
| **Vanilla structure `.nbt`** | gzip NBT | {DataVersion, size[3], palette[{Name, Properties}], blocks[{pos, state, nbt?}], entities[]} | Structure block UI caps at **48³** (Java). Bukkit `StructureManager.loadStructure` and `/place template` load larger files (VERIFY on Paper 1.21.x in a flight) | Vanilla, datapacks, **our plugin placer** (DV). Cyrus already compiles this: `lib/cyrus/datapack/worldgen/template.ts` |
| **Bedrock `.mcstructure`** | **little-endian, uncompressed** NBT (VERIFY) | {format_version 1, size[3], structure{block_indices[[layer0], [layer1 waterlog]], entities[], palette{default{block_palette[{name, states{}, version}], block_position_data{idx:{block_entity_data}}}}}, structure_world_origin} | index order z fastest: `(x*sy + y)*sz + z` (VERIFY); structure block 64×384×64 (VERIFY) | Bedrock structure block. **Needs a Java→Bedrock block-name and state map**, which is the hardest export |
| Legacy `.schematic` (MCEdit) | gzip NBT, numeric ids | 1.12 and older only | — | Skip |

### 4.2 Libraries (Node/TS)

| Library | Licence | Read/Write | 1.21.x states | Fit for Cyrus |
|---|---|---|---|---|
| **In-repo `lib/cyrus/datapack/worldgen/nbt.ts`** | ours | big-endian NBT write (deterministic `gzipStored`), `readNbt` with `NBT_READ_LIMITS` | n/a (format-agnostic) | **Use this.** Add `writeNbtLE` for mcstructure and a varint / bit-pack helper. No new dependency |
| In-repo `worldgen/versions.ts` `blockStates` | ours | per-version block → property values | yes, per supported version | **The validator's block-state source of truth** |
| prismarine-nbt | MIT | read/write BE/LE/varint NBT | n/a | Not needed; good reference for LE NBT |
| prismarine-schematic | MIT | Sponge v1-3 read, **writes v2**, MCEdit read | via minecraft-data / prismarine-block (heavy) | Don't add it (pulls minecraft-data); reference only |
| @enginehub/schematicjs | **GPL-3.0** | Sponge v1-3, .nbt, MCEdit read/write | — | **Do not use or copy** (GPL); spec-reading only |
| deepslate (misode) | MIT | NBT + WebGL structure renderer (gl-matrix); needs a resource pack | yes | Optional reference; it needs vanilla assets |
| lodestone (mattzh72) | MIT (includes deepslate code) | `.litematic` load + **three.js** render, bundled default pack | yes | Reference for bit-packed BlockStates decoding; don't bundle its pack (asset provenance unclear) |
| Nucleation (Schem-at) | MIT | Rust + WASM, many formats incl. Java↔Bedrock translation (VERIFY list) | yes | **Candidate for the `.mcstructure` block mapping** (data tables or a WASM call in the build service, not the web bundle). VERIFY quality |
| ObjToSchematic | BSD-3 | writes `.schematic/.litematic/.schem/.nbt` | yes | Reference for writers and colour palettes (Phase 3) |

**Recommendation.** Write about 400 lines of TS writers in a new `lib/cyrus/structure/formats/` folder on top of `nbt.ts`: `schem.ts` (v3 + v2), `litematic.ts`, `nbt-vanilla.ts` (reuse `compileTemplate`) and `mcstructure.ts`.
- Golden-test each writer by reading the output back with `readNbt`, and do a flight probe loading `.schem` with WorldEdit on node-2.
- Use the Java→Bedrock map only for blocks in our theme kits, which keeps it to a few hundred rows that can be checked by hand. Fail closed: unmapped block → nearest kit substitute plus a warning.

### 4.3 Preview: no new heavy dependency

The repo pattern (FACT, from the Explore pass):
- `three` ^0.186.1 is the only 3D dependency.
- `components/cyrus/studios/model-viewport.ts` does `loadThree()` = `import("three")`, so three is code-split to the studio route.
- It uses DataTexture with nearest filtering and a render budget in `lib/cyrus/modelstudio/budget.ts`.
- Server goldens come from `lib/cyrus/modelstudio/preview/*`: Playwright + SwiftShader.
- There is no voxel renderer yet.

Proposal: a new `components/cyrus/studios/structure-viewport.ts`.

| Piece | Approach |
|---|---|
| Meshing | **Greedy mesh per Y layer in a Web Worker** (pure TS, about 200 lines) into one BufferGeometry with per-vertex colour and AO. A 64×32×64 room with 30-60k blocks gives about 20-80k quads, well inside budget. Partial shapes (stairs, slabs, walls) use a small set of shape primitives keyed by state |
| Colours | A **block → average-colour table** (about 600 rows JSON) plus procedural noise per face. **Do not ship Mojang textures.** Optional: the user's own resource pack textures through the existing texture studio atlas |
| Interaction | Orbit, **Y-slice slider** (cut the roof to see the interior; BlockGPT's exterior-only preview can't show a room), floor-plan 2D view, marker overlay (sprites for mob / elite / boss / chest / trap / door), "show walk path" (BFS result as a line), light-level heatmap toggle |
| Edits | Click a cell: change block or move a marker. Re-run only the decoration pass. All edits are ops appended to the spec (an oplog, like `modelstudio/oplog.ts`) |
| Thumbnails | Server PNG via the existing `modelstudio/preview` Playwright pipeline for the gallery, listings and the Test Flight report |
| Streaming | Reuse `lib/cyrus/liveassets/partial-json.ts` to grow the room as the spec streams in (op by op), for the "it's building" moment |

---

## 5. Cyrus Structure Studio design

### 5.1 Spec the model writes (`room.v2`, extends DV's room.v1)

```jsonc
{ "spec": "room.v2", "id": "lava_boss_01", "theme": "inferno", "type": "boss",
  "size": [56, 28, 56],                         // up to 64 x 32 x 64
  "symmetry": "radial4",                        // none | mirror_x | mirror_z | mirror_xz | radial4
  "kit": "inferno",                             // theme kit: palette roles -> block states
  "palette": { "floor": "basalt_mix", "wall": "blackstone_bricks_mix", "accent": "gilded_blackstone",
               "hazard": "lava", "light": "shroomlight" },        // roles, resolved by the kit
  "ops": [
    { "op": "shell", "shape": "cylinder", "r": 26, "h": 24, "wall": 2, "roof": "dome" },
    { "op": "floor", "y": 3, "material": "floor" },
    { "op": "ring_moat", "r_in": 14, "r_out": 18, "depth": 3, "fill": "hazard" },
    { "op": "bridge", "from": [28,3,46], "to": [28,3,10], "width": 3, "rail": "wall" },
    { "op": "pillar_ring", "r": 21, "n": 8, "h": [6,14], "style": "broken" },
    { "op": "platform", "center": [28,3,28], "r": 10, "raise": 1, "edge": "stairs" },
    { "op": "obstacle_scatter", "region": "arena", "count": 10, "kinds": ["rubble","magma_spike"], "keep_clear": "path" },
    { "op": "alcove", "wall": "e", "w": 3, "d": 4, "h": 4, "hidden": true, "door": "secret" }
  ],
  "decorate": [ { "pass": "cracks", "pct": 15 }, { "pass": "lanterns", "spacing": 7, "hang": true },
                { "pass": "chains" }, { "pass": "ember_particles_hint" } ],
  "markers": [
    { "kind": "entry", "at": [28,4,52], "facing": "n" },
    { "kind": "boss", "at": [28,5,28], "data": "boss:inferno_lord" },
    { "kind": "mob", "at": "pillar_ring:*", "data": "mob:ranged", "count": 6 },
    { "kind": "chest", "at": "alcove:0", "data": "chest:hidden", "loot": "boss_t3" },
    { "kind": "trap", "at": "bridge:mid", "data": "trap:fire" },
    { "kind": "door", "at": [28,4,2], "data": "door:exit", "seal_until": "boss_dead" }
  ],
  "rules": { "min_light_path": 8, "headroom": 3, "hall_width": 2, "max_lava_adjacent_path": 0.15 } }
```

| Spec rule | Why |
|---|---|
| Palette by **role**, resolved by a **theme kit** to concrete block states (stairs, slab, wall, trapdoor variants per role) | Real block-state variety without the model writing states; kits are validated against `versions.ts blockStates` |
| Ops vocabulary (about 30): shell, floor, room_grid, corridor, stairs, ramp, pit, moat, bridge, pillar_ring, pillar_grid, arch, balcony, platform, alcove, window_row, obstacle_scatter, lava_pool, cage, throne, altar, bookshelf_wall, crypt_row, carve, fill, replace, array, mirror, rotate, `raw_layers` (escape hatch for a small detail ≤ 16³) | Matches the MC-Bench / APT finding that primitives beat raw voxels |
| Anchor references (`pillar_ring:*`, `bridge:mid`, `alcove:0`) for markers | Markers stay attached when ops change |
| Markers compile to the **DV legend v1** (glazed terracotta + DATA structure blocks) in exports, and to sidecar JSON for the plugin | One legend everywhere; human builders and AI rooms are interchangeable |

### 5.2 Validator + compiler (deterministic, pure TS, never garbage)

| Step | Check / action | On failure |
|---|---|---|
| 1. Schema | Zod `RoomSpecSchema` (strict), size ≤ 64×32×64, ops ≤ 120, markers ≤ 64, palette roles ≤ 24 | Return issue list to the model (repair turn, max 2) |
| 2. Expand | Ops → cell grid (Uint16 palette indices), symmetry applied, kit resolves roles → states | Deterministic; same spec + seed = same bytes |
| 3. Block legality | Every state in `versions.ts blockStates` for the target version; deny list = `DENIED_BLOCKS` + command / structure (except DATA markers) / jigsaw / barrier (outside the seal) / spawner-with-NBT | Auto-substitute from the kit + warning |
| 4. Physics | No floating gravity blocks, fluids contained (lava cannot spill onto path cells), no lava directly under the walk path | Auto-fix: add a container rim / replace with magma |
| 5. Walkability | 3D BFS from entry: feet cell air + 2 (rule `headroom`) air above + solid below, step ≤ 1, gap ≤ 1. Every marker and the exit reachable; boss arena radius clear | Auto-carve the shortest path (A*), then re-check; else repair turn |
| 6. Light | Block-light flood fill (light sources from a kit table); path cells ≥ `min_light_path`, except DARK rooms by design | Auto-place kit lights (lanterns / shroomlight) on walls near dark path cells |
| 7. Marker counts | Exactly 1 entry, ≥ 1 exit (unless dead-end type), boss = 1 for type boss, loot ≤ 16 (`LOOT_CONTAINERS`), traps not on the only path unless telegraphed | Repair turn |
| 8. Budget | Non-air ≤ 80k (paste cost), palette ≤ 64 entries, estimated paste ms from DV batch rate | Warn / downscale decoration density |
| 9. Emit | `.nbt` (via `compileTemplate`, raised caps for the studio only), `.schem` v3/v2, `.litematic`, `.mcstructure`, `room.json` sidecar, PNG thumbnails | Golden round-trip test in CI |

### 5.3 Theme kits and decoration passes

- Ship 8 kits: inferno (lava/fire), crypt, castle, ice, swamp, ruins, sky temple and sci-fi lab.
- Each kit is a JSON file under `lib/cyrus/structure/kits/` that maps roles to weighted states, light blocks, hazard blocks, 3-5 prop "stamps" (small hand-authored 3×3 to 7×7 pieces such as a brazier, throne, sarcophagus or forge) and decoration-pass defaults.
- Stamps are **owner/agent-authored originals**, licensed as Cyrus content.
- Decoration passes are deterministic noise passes (seeded): cracks, moss, cobwebs, chains, banners, rubble, edge erosion, embers (props), drips and vines.

### 5.4 Studio UX (portal)

| Step | UI |
|---|---|
| Prompt | Text box, theme picker (kits), room type (combat / treasure / trap / boss / shrine / hub), size presets (24², 40², 56², 64² × height), edition (Java / Bedrock), model tier (fast / standard / best) |
| Generate | Streaming build-up preview (ops appear), then the validator report ("walkable ✓, lit ✓, 6 mobs, 2 chests, 1 boss, paste ≈ 0.9 s") |
| Iterate | "Regenerate decoration only" (cheap, no LLM: new seed), "Change theme" (no LLM: kit swap), "Ask for change" (LLM edit of the spec, diff-applied), click-edit markers |
| Export | `.schem` v3 / v2, `.litematic`, `.nbt`, `.mcstructure`, plus `room.json` |
| **Use in my mod** | "Add to project": becomes a `structure` asset (DV stage 1 lane) → the dungeon plugin's placer loads it with markers, loot tables, mob rosters and boss logic. Test Flight pastes it and reports `maxTickMs` |
| Library | My rooms / project rooms; share to community with a licence picker (5.8) |

### 5.5 Pricing hooks (existing token economy)

The economy (FACT, from `lib/cyrus/tokens/config-pure.ts` and `economy.ts`):
- Spend is `tokensForCost = max(minSpend 5, ceil(usd × 500 × tierMult))`.
- Top-ups sell at **120 tokens per USD** (`cyrus_tok_topup_tokens_per_usd`).
- New users get 70 starter tokens.
- Model prices (`services/modbuilder/usage.js` `PRICES`, $/Mtok in/out): haiku-4-5 1/5, sonnet-5/5-5 2/10, opus-5-5 4/20. Cache reads cost 0.1× input.

Per-generation estimate. Assumptions: about 14k input (system + kit + 3 few-shot rooms, mostly cached) + about 5-7k output spec, and 0.6 repair turns on average.

| Tier (model) | Model cost / gen | Tokens charged (×500, mult) | ≈ user price at 120 tok/$ | BlockGPT equivalent |
|---|---|---|---|---|
| Fast (haiku-4-5) | ~$0.03-0.05 | **15-25** | $0.13-0.21 | Basic $0.75/build |
| Standard (sonnet-5-5) | ~$0.08-0.12 | **40-60** | $0.33-0.50 | Standard $0.38/build |
| Best (opus-5-5, mult 1.25 if mapped to yakko) | ~$0.18-0.26 | **110-165** | $0.92-1.38 | Pro $0.245/build (volume) |
| Decoration reroll / theme swap / export | $0 (no LLM) | **0** | free | regenerate = new build |
| Edit-by-prompt | ~half a generation | 20-30 (standard) | — | not offered |
| Image-to-room (Phase 2, vision input +1-2k tokens per image) | +$0.005-0.01 | +5 | — | included |

Hooks:
- Reuse `estimateTokens` / `reserveRange` with a new `structure` complexity class. Hold the high end, then settle at actual cost.
- **Free previews.** 3 per day at the Fast tier from the daily grant (`cyrus_tok_grant_*`). Downloads are free once generated. Do **not** copy the "preview but can't download" dark pattern; the product is the room working in the mod.
- Gate on the existing tier models (`TIER_MODELS`) and keep `cyrus_tok_daily_spend_cap` in force.
- Measure real cost in the first 50 flights before the price ships. Put admin config keys `cyrus_tok_structure_*` next to the others.

### 5.6 Image-to-room (Phase 2)

- The user uploads 1-4 images through the existing `lib/cyrus/uploads.ts` path (PNG/JPG/WebP, 5 MB × 4; already forwarded to the model).
- A vision pass writes a **style brief**: palette roles from dominant colours mapped to kit blocks, layout hints (circular, nave, tiers) and props.
- The brief then goes through the same spec → validator pipeline.
- No mesh reconstruction is needed. Concept art of a "lava boss arena" becomes a playable arena, not a sculpture.
- Phase 3 option: "statue mode" for props and boss statues via TRELLIS.2 (MIT, GPU) + our voxeliser + colour palette, capped at 48³ and placed as a prop stamp.

### 5.7 Training-data capture

- Per generation, store (under the D-60 rules in `lib/cyrus/learning/export.ts`: anonymised, no user ids) the following: prompt class, kit, spec (it is our format, not user code), validator issues before and after repair, auto-fixes applied, cost, user actions (rerolls, edits, exported formats, **added to mod**, deleted), Test Flight paste metrics and an optional 1-5 rating.
- Owner gold set: DV stage 0 rooms are reverse-compiled `.nbt` → layers → (where possible) ops, plus brief. Use them for few-shot and eval.
- An eval harness in `lib/cyrus/eval/` scores walkability, light, marker validity, palette diversity (entropy), and a judge-model score on the PNG (render-and-critique), tracked per model.
- Raw prompt text needs an owner decision. D-60 currently excludes prompt text, so store it only if the owner opts in.

### 5.8 Differentiation vs BlockGPT

| | BlockGPT | Cyrus Structure Studio |
|---|---|---|
| Output | Static schematic (colour-voxel shell) | Valid schematic **+ sidecar + live in a working mod** |
| Gameplay | none | Mob spawns by role, boss spot + boss logic, loot tables by tier, traps, sealed doors, objectives |
| Guarantees | none ("starting point") | Walkable, lit, contained hazards, marker counts, paste-time budget, tested in Test Flight |
| Block quality | Full cubes only, ores as pigment, unobtainable blocks | Theme kits with real block states, survival-legal palettes optional |
| Edit loop | Regenerate | Reroll decoration free, kit swap free, prompt edits, click edits |
| Preview | Exterior view | Slice / interior, floor plan, path and light overlays, markers |
| Pricing | $1 trial → $19/mo subscription; downloads paywalled | Pay per generation with existing tokens; free daily previews that *can* be downloaded |
| Scope | Any object/statue up to large sizes | Rooms and arenas ≤ 64×32×64 (v1). Statues are a later phase |

### 5.9 Staged build plan

| Stage | Scope | Agent-days | Depends on |
|---|---|---|---|
| S0 | DV stage 0 (owner hand-builds kit rooms) + DV stage 1 placer / `structures` lane | (DV: ~5) | — |
| S1 | Format writers (`schem` v3/v2, `litematic`, vanilla `.nbt` with raised studio caps, `mcstructure` + kit-only Bedrock map) + round-trip goldens + node-2 WE/Litematica load check | 3 | `nbt.ts` |
| S2 | `room.v2` schema, op expander, 2 kits (inferno, crypt), symmetry, decoration passes | 4 | S1 |
| S3 | Validator: block legality, physics, BFS walk + auto-carve, light flood + auto-light, marker rules, budget | 3 | S2 |
| S4 | LLM lane: prompt + few-shot + repair loop (max 2) + streaming; token estimate / settle hooks; daily free previews | 2 | S3 |
| S5 | Studio UI + `structure-viewport.ts` (worker greedy mesh, slice, overlays) + server thumbnails | 3-4 | S2 |
| S6 | "Use in my mod": asset kind `structure`, sidecar → placer, Test Flight paste probe | 1-2 (on top of DV S1) | DV S1 |
| S7 | 6 more kits + stamps, eval harness, pricing calibration from 50 flights | 2-3 | S4 |
| **v1 total** | | **≈ 18-21** (≈ 14-19 excluding DV) | |
| P2 | Image-to-room (vision → brief) | 2 | S4 |
| P3 | Edit-by-click oplog, community room library + licences | 3-4 | S5 |
| P4 | Statue mode (TRELLIS.2 GPU service + voxeliser) | 5-8 + GPU host | optional |

### 5.10 Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| **Generic or boxy LLM layouts** (the DV problem moved into a spec) | High | Rich ops with good defaults, kits + stamps, owner gold few-shot, render-and-critique repair, eval gate before paid launch |
| Bedrock block mapping wrong | Medium | Kit-only mapping table, golden-tested; label `.mcstructure` "beta"; Nucleation as a cross-check |
| 64-wide `.nbt` won't load in some path (the structure block UI caps at 48) | Medium | Document "WorldEdit/Litematica for >48"; plugin uses `StructureManager` (flight-verify); split into 2 pieces if needed |
| Paste lag of 60-80k blocks | Medium | DV batching via `NxPerf.Queue`, budget in the validator, `maxTickMs` probe |
| Cost overruns from repair loops | Low-Med | Max 2 repairs, auto-fixes before LLM repair, hold / settle with the daily cap |
| Copyright prompts ("Hogwarts", "Batman arena") | Medium | `prompt-check.ts` / guard: refuse named-IP replicas, suggest "inspired" originals |
| BlockGPT ships "Mods" (Blueprint-style) and closes the gap | Medium | Our moat is end-to-end tested mods (Test Flight, server delivery, loot/mob/boss logic). Ship S6 first-class |

---

## 6. Legal and ethical

| Topic | Rule for Cyrus |
|---|---|
| Ownership of generated rooms | The user owns or may use their generations, consistent with the existing Cyrus terms (VERIFY current wording). Cyrus keeps a licence to host / display / use as anonymised training signals (D-60 scope). Default community share licence: **CC-BY-4.0**, with CC0 or "all rights reserved, not listed" as options |
| Kits, stamps, ops library | Cyrus-original content. Ship under Cyrus terms; generated output containing stamps is freely usable by the user |
| No copyrighted structures | Refuse replicas of named copyrighted builds, characters or logos (guard). No importing BlockGPT gallery files, Planet Minecraft or other community schematics unless explicitly CC0/CC-BY with attribution recorded (DV rule) |
| Mojang assets | Do not bundle vanilla textures in the web preview (colour table only; the user's own resource pack is optional). Follow the Minecraft EULA / usage guidelines: "not affiliated with Mojang/Microsoft" footer, no Minecraft logo |
| Competitor | Emulate the concept only. Do not use their name, branding, UI copy ("Your Minecraft build is ready!"), pricing page layout or assets; do not scrape or call their service (their ToS forbids automated access) |
| Third-party code | MIT/BSD/Apache references are OK with notices. **GPL (schematicjs, WorldEdit, FAWE) must not be copied** into our code; read the specs only. Word2Minecraft has no licence: ideas only |
| Credit | Sidecar and `.schem` v3 `Metadata.Author` = the user's display name (or "Cyrus" if anonymous), `Metadata.Name` = room name; community remixes keep a remix chain (existing `RemixTree`) |

---

## 7. Existing Cyrus code to extend (file pointers, /opt/nxeon)

| Purpose | File |
|---|---|
| NBT writer / reader (deterministic gzip, read limits) | `lib/cyrus/datapack/worldgen/nbt.ts` (`writeNbt`, `gzipStored`, `readNbt`, `NBT_READ_LIMITS`) |
| ASCII-layers → vanilla `.nbt` compiler, loot containers | `lib/cyrus/datapack/worldgen/template.ts` (`compileTemplate`, `templateShapeIssues`, `LOOT_CONTAINERS`) |
| Template schema + caps (48 side, 32,768 blocks, palette 32, loot 16) | `lib/cyrus/datapack/worldgen/spec.ts` (`StructureTemplateSchema`, `WORLDGEN_LIMITS`): add separate `STUDIO_LIMITS`, don't loosen worldgen |
| Block states per version / DataVersion | `lib/cyrus/datapack/worldgen/versions.ts` (`blockStates`, `worldgenFeatures`) |
| Denied blocks / file checks | `lib/cyrus/datapack/worldgen/check.ts` (`DENIED_BLOCKS`), `worldgen/files.ts` (`checkTemplateNbt`) |
| Loot table emitter | `lib/cyrus/datapack/emit/loot.ts` |
| three.js viewport pattern (dynamic import, budget) | `components/cyrus/studios/model-viewport.ts`, `lib/cyrus/modelstudio/budget.ts`, `modelstudio/oplog.ts` |
| Server PNG goldens | `lib/cyrus/modelstudio/preview/*` (`playwright.ts`, `page-script.ts`, `golden.ts`) |
| Streaming partial spec | `lib/cyrus/liveassets/partial-json.ts`, `interpret.ts` |
| Studio shell / tabs | `components/cyrus/studios/StudioShell.tsx`, `AssetsTab.tsx`, `lib/cyrus/studio-nav.ts` |
| Image uploads for image-to-room | `lib/cyrus/uploads.ts` |
| Tokens | `lib/cyrus/tokens/config-pure.ts` (`CYRUS_TOKEN_DEFAULTS`, `DEFAULT_RESERVE_TABLE`), `economy.ts` (`tokensForCost`, `estimateTokens`, `settleCharge`, `TIER_MODELS`), `spend.ts`; prices in `services/modbuilder/usage.js` `PRICES` |
| Training signals | `lib/cyrus/learning/signals.ts`, `export.ts` (D-60) |
| Planner / mega staging (dungeon) | `lib/cyrus/planner/mega.ts`, `planner/policy.ts` (roguelike → plugin code); `services/modbuilder/planner.js` (add `structures` lane per DV) |
| New code | `lib/cyrus/structure/room-spec.ts`, `ops/*.ts`, `kits/*.json`, `validate.ts`, `formats/{schem,litematic,mcstructure,nbt-vanilla}.ts`, `bedrock-map.json`; `components/cyrus/studios/StructureStudio.tsx`, `structure-viewport.ts`, `structure-mesh.worker.ts`. Note: `lib/cyrus/structure/parts.ts` is unrelated (build parts UI); keep the new modules separate or rename the folder to avoid confusion |

## 8. Open questions for the owner

1. Is the Studio sold standalone (export-only users, a BlockGPT-style audience) or only inside projects? The recommendation is both: standalone to acquire users, with "use in my mod" as the upsell.
2. Should we store prompt text for training (a D-60 change)?
3. Is Bedrock `.mcstructure` in v1 (adds about 1 day plus mapping risk) or v1.1?
4. Default community licence: CC-BY-4.0 or CC0?

## 9. Sources (accessed 2026-10-16)

- BlockGPT homepage + FAQ: https://blockgpt.ai/
- Pricing: https://blockgpt.ai/pricing
- Terms (updated 26 Jul 2026): https://blockgpt.ai/terms
- How-to / import guide: https://blockgpt.ai/how-to
- Gallery: https://blockgpt.ai/gallery
- Sample build page (Nov 2025): https://blockgpt.ai/build/a-large-gothic-mega-fortress-built-on-a-jagged
- Its public download (inspected once): https://gpqbppurvxuclcxrpqeg.supabase.co/storage/v1/object/public/structures/final/4a5f2de6-5de5-4ba7-8c21-6a97044141c6-1764194844672.schem
- Blog index: https://blockgpt.ai/blog
- Blog: Getting Started (2026-01-14): https://blockgpt.ai/blog/getting-started-with-blockgpt
- Blog: How to Generate Minecraft Schematics Using AI (2026-01-15): https://blockgpt.ai/blog/how-to-generate-minecraft-schematics-using-ai
- Blog: How to Turn AI Builds Into Usable Minecraft Worlds (2026-01-16): https://blockgpt.ai/blog/how-to-turn-ai-builds-into-usable-minecraft-worlds
- Blog: What's Next for BlockGPT (2026-01-17): https://blockgpt.ai/blog/whats-next-for-blockgpt
- BlockGPT Mods: https://mods.blockgpt.ai
- X: https://x.com/blockgptai (fetch returned 402; seen via search snippet)
- Owner screenshot: `/tmp/claude-0/-/4400f828-d7f0-408f-8666-b0db1ce3383f/images/26.png`
- T2BM: https://arxiv.org/abs/2406.08751
- APT: https://arxiv.org/abs/2411.17255 (summary via https://pith.science/paper/2411.17255)
- Word2Minecraft: https://arxiv.org/html/2503.16536v1 (code: https://github.com/JMZ-kk/Word2Minecraft)
- BrickGPT: https://arxiv.org/pdf/2505.05469
- MC-Bench coverage: https://techcrunch.com/2025/03/20/a-high-schooler-built-a-website-that-lets-you-challenge-ai-models-to-a-minecraft-build-off
- minebench: https://gittrend.io/repo/Ammaar-Alam/minebench
- GDMC: https://cog2025.inesc-id.pt/gdmc/
- CyniaAI BuilderGPT (Apache-2.0): https://github.com/CyniaAI/BuilderGPT
- ObjToSchematic (BSD-3): https://github.com/LucasDower/ObjToSchematic
- TRELLIS.2 (MIT): https://huggingface.co/microsoft/TRELLIS.2-4B
- Sponge Schematic v3 spec: https://github.com/SpongePowered/Schematic-Specification/blob/master/versions/schematic-3.md
- prismarine-schematic (MIT): https://github.com/PrismarineJS/prismarine-schematic
- @enginehub/schematicjs (GPL-3.0): https://github.com/EngineHub/schematicjs
- deepslate (MIT): https://github.com/misode/deepslate
- lodestone (MIT): https://github.com/mattzh72/lodestone
- Nucleation (MIT): https://github.com/Schem-at/Nucleation
- Litematic format (litemapy docs): https://litemapy.readthedocs.io/en/latest/litematics.html
- Industry.co.id mention of BlockGPT: https://www.industry.co.id/read/153367/minecraft-cara-bangun-otomatis-dengan-ai-terbaru-coba-sekarang
- Companion: `/root/claudeskills/agent-notes/cyrus-research/DV-room-generation-options-2026-10-16.md`

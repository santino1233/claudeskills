# EG: Full texture packs + shaders for Cyrus (research + plan), 2026-10-18

Labels: **V** = verified (code read this session, or fetched page/licence), **U** = unverified (memory, search snippet, estimate). No builds/tests were run; code read from `/tank/dev-worktrees/cyrus-r51/lib/cyrus` (read-only). Web tooling was weak this session: the minecraft.net Usage Guidelines and help.minecraft.net pages TIMED OUT, so the EULA/usage-guideline section is U and must be read by the owner or a follow-up agent before any sale.

## 0. Answer in five lines
1. **(A) Full texture packs: YES, build it, as "Pack Studio"**, original-style only, 16x/32x first. Strong SEO term, and the existing procedural DSL + palette ramps + lookalike guard are the right base. The missing part is breadth (3,664 textures + models/blockstates/atlases), not the pixel engine.
2. **(B1) Iris/OptiFine shaderpacks: do NOT build a from-scratch generator now.** Offer a **"Shader Studio lite"**: parametric presets (a curated, owner-written permissive base pack + a settings/profile/colour-grade generator), not AI-written GLSL pipelines.
3. **(B2) Resource-pack core shaders: ship only as small, version-banded "effects" (tint, fog tint, outline, text/UI effects)**; never in the main texture pack by default. They break at 1.21.2/1.21.5/1.21.6/26.x.
4. **(C) Bedrock: nothing moddable by shaders**; skip.
5. Build order: Pack Studio prototype (16x, ~400 families) -> SEO pages -> 32x/64x -> effects lane -> shader presets.

## 1. What Cyrus already has (all V, code read)

| Piece | Where | State |
|---|---|---|
| Procedural pixel DSL | `lib/cyrus/textures/dsl.ts` | Ops: fill/px/rect/line/circle/poly/gradient/noise/shade/outline; mirror; sizes 16/32/64 (item), 64/128 (skin); MAX_OPS 400, MAX_PALETTE 24 (skin: 3000 ops, 96 colours). Deterministic, no code execution. |
| Renderer / PNG / zip / quality | `textures/render.ts, png.ts, zip.ts, quality.ts` | Own PNG encoder, quality scoring. |
| Texture library | `lib/cyrus/texture-library` (`templates-tiles.ts` 1116 lines, `templates-items.ts` 942, `templates-misc.ts`), `library.manifest.json` | **82 templates**, ramps per material (e.g. `ramps:{m:"iron",h:"leather"}`), "dna" style tag (`pixel_classic`), descriptors (size, paletteSize, transparency, tileable), `specSha256`. This IS the family/ramp/palette-lock mechanism a full pack needs, at small scale. |
| Lookalike guard | `texture-library/lookalike.ts` | 16x16 fingerprint (alpha mask + luminance + mean RGB per cell); `similarity()` = maskIoU, luminance correlation, colour distance; `isNearCopy` = IoU>=0.9 and lumCorr>=0.9. `checkNearCopy` against vanilla returns **"not_run"** when no reference set is passed (honest stub). The reference set is not in git; an operator builds fingerprints on the build host. |
| Pack builder | `textures/pack.ts` `buildPack()` | One item model per texture (1.21.4+ `assets/<ns>/items/<name>.json`), sounds, glyph fonts, 1.21.1 legacy CMD path. **Hard cap: 24 textures per pack** (`textures.length > 24`). New namespaced keys only, never `minecraft:` replacement (one 1.21.1 carrier exception). |
| Delta-only / game-derived handling | `gameassets/delta.ts`, `leftOut` in BuiltPack | Game-derived textures are NOT packed (retention rules). Shows the project already treats vanilla pixels as untouchable. |
| Version registry | `versions/registry.json/.ts` | RP format: 1.21.1=34, 1.21.4=46, 1.21.8=64 (U), 1.21.11=75, 26.1.x=84, 26.2=88, 26.3b=97.1. `resourcePackClientVerified=false` everywhere: **no pack has been loaded in a real client from this registry**. Capabilities include `itemModelDefinitions` (1.21.4+) and `legacyCustomModelData`. |
| Pack hosting / delivery | `packhost/*` (local + S3 sigv4, publish, `zipcheck.ts`, `loader-config.ts`) | Hosting + Pack Loader delivery exist. |
| Item model states | `itemmodel/*` (emit, spec, legacy, display) | Emits item model definitions, not vanilla-wide retexture. |
| Studios | `lib/cyrus/studios/paint.ts, candidates.ts, editor.ts` | Layered paint docs, AI candidate workflow, spec-as-source-of-truth editing. |
| Creature skins | `creature/*` skin profile 64/128 | Box-UV atlases for custom mobs, own quality bar. |

**Gap list for a FULL pack** (V from the reference index, see section 2):
- The builder only makes *new namespaced items*. A retexture pack overrides `assets/minecraft/textures/**` paths. That needs a **new pack mode ("replace vanilla paths")** with a manifest of expected paths per version (a checklist, names only), and a hard guard that the builder otherwise never emits `minecraft:` keys. Tension with the current "new keys only" rule: keep it as a separate builder (`buildRetexturePack`) so the money-path pack builder is untouched.
- No texture-path list per version in code. Needs a **names-only index** distilled from the private reference (path, size, frame-count, family, render type), shipped as JSON (names are facts, not Mojang pixels; confirm with owner, section 3).
- Models/blockstates: a retexture pack normally **needs no model files** (vanilla models point at `minecraft:block/xxx` texture ids). Only needed for style changes (3D items, CTM, overrides). So: skip models in v1.
- Animated textures (`.png.mcmeta`): not emitted today. 169 mcmeta files exist in 26.1.2. Needs frame-strip generation (procedural: scroll/phase-shift of one tile for water/lava/fire/portals; cheap).
- Atlases (`atlases/*.json`, 17 files) and 26.1 sprite objects: not touched, not needed unless sprites are renamed.
- Connected textures (Continuity / OptiFine CTM, `optifine/ctm/*.properties`): client-mod dependent; **not vanilla**. Treat as an optional add-on (U on exact format, needs client test).
- Emissive: not vanilla. OptiFine `_e`/Iris emissive suffix, or CIT Resewn; vanilla-only trick is the `rendertype_entity_translucent_emissive` core shader (version-fragile). Skip in v1.
- GUI / fonts / sky / panorama: plain PNG replacements, 523 GUI PNGs, 5 font PNGs, 14 environment, 3 colormaps (grass/foliage tint maps matter for look). GUI sprites exist since 1.20.2 under `textures/gui/sprites` (V from reference tree: 523 gui PNGs).
- Item models in 1.21.4+: retexturing needs nothing new (vanilla item definitions reference models that reference textures). Only custom 3D-item styles need `assets/minecraft/items/*.json` overrides (1,508 files in 26.1.2): **out of scope for v1**.
- Entity textures: 761 PNGs, fixed per-entity UV layouts. This is the hardest family: needs per-entity UV template overlays (not in repo for vanilla mobs; creature module has custom-rig atlases only).
- Client verification: none. Prerequisite for selling anything: one real-client load per format band (also a gate in registry).

## 2. Texture counts (V, names/counts only from `/tank/cyrus-library-staging/_owner-mc/Minecraft GFX and SFX/minecraft-assets-26.1.2.zip`; pixels never copied or extracted)

| Group (26.1.2) | PNGs | Note |
|---|---|---|
| block | 1,112 | many are variants/stages (doors top/bottom, crops 0-7, copper x4 states, wood x12) |
| item | 792 | 16x16 mostly; armor trims, spawn eggs, potions, music discs, tools x tier |
| entity | 761 | fixed UV sheets; mobs, boats, chests, banners, armor layers, signs |
| gui | 523 | sprites, container backgrounds, hotbar, widgets, advancements |
| particle | 254 | |
| trims 57, painting 52, mob_effect 40, map 37, environment 14, misc 13, font 5, colormap 3, effect 1 | 222 | |
| **Total** | **3,664** (3,689 incl. non-texture PNGs) | `.png.mcmeta` animation files: 169 |

Size distribution for block+item: 1,827 are exactly 16x16, 23 are 32x32, the rest are animation strips (16x64, 16x512 etc.). Other assets in the tree: 3,681 model JSON, 1,172 blockstates, 1,508 item definitions, 92 shader files, 47 equipment, 8 post_effect, 150 lang files.

Older `minecraft.zip` has 3,992 PNGs (older version). Per-version lists differ; each supported version needs its own names index (distill with a script; names + size + frame count only).

**Family compression (the key to cost).** Real unique "designs" are far fewer than 3,664: 16 colours x (wool, concrete, concrete powder, terracotta, glazed, stained glass, carpet, bed, banner, shulker) are recolours of ~10 bases; 12 wood types x (log, planks, stairs->same texture, door, trapdoor, sign, boat, hanging sign) ; tool/armor tiers x 6 materials; ore x 8 over 3 stone bases; copper x 4 oxidation. Estimate (U, from category knowledge, to be measured in prototype): **~450 to 600 distinct families** for blocks+items, **~120 to 160** entity sheets (each needs a UV template), **~60 families** of GUI. So ~700 designed families yield 3,664 PNGs through ramp/recolour/variant expansion. Matches the existing library model (`templateId` + `ramps` + `dna`).

## 3. Generation strategy and cost

**Principle: the bulk is deterministic and model-written-as-spec, heroes are optional AI images that go through the same quantise/palette/lookalike pipeline.**

Pipeline per pack:
1. **Style brief to tokens (1 call):** user prompt/style dropdown ("cozy hand-painted", "dark gothic", "clean flat", "neon") -> `StyleTokens`: master palette (<= 48 colours), material ramps (stone, dirt, wood, metal, leaf, water ...: 4-5 steps each), outline rule (none/dark/selective), noise amount, light direction (top-left, fixed), shading model (flat / dithered / banded), size. Stored with the pack; all later calls get it verbatim. This extends the existing `dna` + `ramps` concept.
2. **Family planning (deterministic, no model):** from the names-only index group paths into families with expansion rules (recolour via ramp swap, rotate/flip, stage ramp for crops, oxidation shift). One *base* per family is designed; variants are code.
3. **Base design, three tiers:**
   - T1 deterministic generators (no model): noise-stone, dirt, sand, gravel, planks (grain), logs, ores (overlay on stone), wool/concrete/terracotta, glass, leaves, planks, bricks, water/lava frames. Write ~40 hand-authored generator functions once (owner/Claude, reusable, SEO-neutral). Cost ~$0 per pack. Covers ~45% of block files.
   - T2 LLM-authored DSL spec per family (existing mechanism, strict op caps) with palette from tokens, followed by a vision critique pass (render upscaled -> model checks readability/style, one revise). ~300 families. This is where tokens go.
   - T3 hero textures (~100 to 150): items (sword, pickaxe, apple...), GUI frames, sky, logo-level blocks. Optional pixel-art image model (see section 6 for the unresolved question of model/vendor), then downscale + quantise to the style palette + alpha clean. Never an image-to-image from any vanilla pixel.
4. **Consistency:** (a) palette locked: every output is snapped to the master palette (reject if > N% pixels off-palette before snapping); (b) shared ramps per material; (c) outline and light-direction rules applied post-hoc by code (`outline`, `shade` ops); (d) a "consistency score" like quality.ts: mean luminance contrast per family, palette usage histogram; outliers are re-rolled automatically (max 2).
5. **Resolution rules:** 16x is native. 32x/64x: **do not upscale pixels**; re-run family rendering with the same spec at larger canvas (specs use proportional coordinates; DSL currently absolute pixel coords, so add a spec "scale" op or ask the model for 2x details on a second pass). Upscale nearest-neighbour only for flat colours; add detail ops (grain, highlights) at 32x; at 64x+ prefer T3 hero images quantised to ramps for organic content. 128x: DSL is poor (blocky, per C-texture.md); needs T3 for nearly everything -> expensive and inconsistent; ship as "experimental" or not at all in v1.
6. **Validation:** per-version path checker (names index), power-of-two, animation strips divisible, tile edge continuity for tileable blocks (edge difference metric), alpha rules, pack size < 50 MB (U), pack.mcmeta from `resourcePackFormat()`.
7. **Preview/edit/re-roll UX:** family grid (cards per family: block cube preview, 4x4 tile, inventory slot render, dark/light), re-roll one family (seed + temperature) or a whole category with "keep these" locks, style slider ("more contrast", "more noise"), palette editor (change a ramp and everything using it re-renders deterministically; this is the killer feature because specs are the source), per-texture paint overlay (existing Studio editor), side-by-side with previous. Never overwrite silently; revision per family (hash).

**Cost estimate per full pack (U; Sonnet-class pricing assumed ~$3/M in, $15/M out; real gateway cost to be measured in prototype by `ai-gateway-budget.ts`):**

| Resolution | Scope | Calls | Est. cost | Time (parallel x8) |
|---|---|---|---|---|
| 16x, blocks+items+GUI (~3,000 PNGs) | 300 T2 specs (~3k in, ~1.5k out, +1 critique) ~ $0.04 each = $12, 120 heroes ~$0.05 = $6, retries 30% | ~900 | **$15 to 30** | 15 to 30 min |
| 16x + entities (UV templates needed) | +130 entity sheets at 64x64 skin profile (3000 ops, ~5k out) ~ $0.10 each | +260 | +$15 to 30 | +20 min |
| 32x | same families, detail pass; more tokens | ~1,300 | **$30 to 60** | 30 to 45 min |
| 64x | many heroes via image model, more ops | ~1,800 | **$70 to 150** | 1 to 2 h |
| 128x | mostly image-model + manual fix | n/a | **$200+, quality low (U)** | hours; do not promise |

These are order-of-magnitude. Sell by tokens at the existing Cyrus price model; the free tier gets a **partial pack** (one category, e.g. "blocks only 16x", or a 24-texture starter which already fits the current builder cap).

## 4. Legal / IP guardrails

Owner rules (V from memory/tracker): vanilla zips are game-derived; private reference only; never public, served or in git; library CC0-only; nothing derived from third-party packs.

**Keep it original:**
- Generation inputs are only: user text, style tokens, CC0 library templates, Cyrus-authored generators. **Never** vanilla pixels (no img2img, no "make it like the vanilla grass", no vanilla image in prompts or vision-critique calls; the vision critique sees only our render).
- Prompt guard: reject prompts naming Mojang/Minecraft *art* to copy, other packs ("Faithful", "Sphax", "Bare Bones", "John Smith Legacy", "Vanilla Tweaks") or "recreate vanilla". Style words ("pixel", "cartoon") are fine. (Policy U, matches existing `prompt-check.ts` pattern; confirm it is extended.)
- Lookalike gate (existing, today a **stub**): compute the 16x16 fingerprints of the private vanilla set on the build host (operator step, not in git), then run `similarity()` per texture against the same-path vanilla fingerprint AND the whole set. **Proposed thresholds:** reject/re-roll if maskIoU >= 0.85 and lumCorr >= 0.85 (stricter than today's 0.9/0.9 near-copy rule, because the cost of a false reject is a re-roll); warn at >= 0.75/0.75. Caveat (V from code): the fingerprint is coarse (16 cells); a 16x16 texture where a stone-like block with grey noise is *semantically* similar will correlate. A stone-like base will often be flagged: the fix is a different design language (outline, banding, different grain) not weaker thresholds. **Must report a pack-level "originality report"** (share of textures with max similarity below the warn line). Never a pass when `not_run`: the builder must refuse "publishable" status with `not_run`.
- Add a **perceptual hash / DCT hash** second check for non-16 sizes (so the guard also works at 32x/64x after downscaling to 16 grid, already how `fingerprint()` box-samples).
- Ledger: every texture gets provenance row {source: t1_generator|dsl_model|image_model, model/version, seed, style tokens hash, lookalike max score, reference-set hash}. No reference *pixels* in the ledger.
- Names-only index: the path list (`textures/block/stone.png`) is a functional interface fact (a pack must use those paths to work); distilling it is low risk. Still ask the owner to confirm; do not publish the full path list verbatim as SEO content in a way that implies Mojang endorsement.

**Minecraft EULA / Usage Guidelines (U: the official pages timed out this session; only secondary snippets).**
- From a search snippet quoting an older diff (U): selling under the Guidelines was capped (about $5,000 per calendar year) in the 2015 text; the July 2023 update (minecraft.net/article/commercial-usage-guidelines-updated) mostly changed *server* monetisation. Third-party sites disagree on whether selling core assets is allowed; none are official.
- My working understanding (U, to be confirmed by reading minecraft.net/usage-guidelines and the EULA): creators may make and distribute resource packs/mods for free and may monetise within the published Usage Guidelines; you may **not** distribute Mojang's assets/code themselves and may not imply endorsement; "Not an official Minecraft product, not approved by or associated with Mojang" wording is required for fan content.
- **Action for owner/follow-up agent:** read both pages in a browser, record the exact current text of (i) resource-pack/texture monetisation, (ii) the per-year cap if it still exists, (iii) mandatory disclaimer, (iv) rules on AI-generated content. Until then: **free downloads of original packs only; no paid pack sales**. Charging for *generation tokens* is the same pattern as the rest of Cyrus and is much safer than selling packs per se, but still confirm.

**Platforms:**
- **Modrinth (V from a search result, not the page itself):** since 2026-08-13 its Content Rules restrict generative AI: content *entirely or primarily* AI-generated is not permitted; any AI-generated or AI-assisted textures/models/logos must be disclosed with the "Contains AI-generated content" tag; creators must own or be licensed for everything uploaded. **This is a direct risk for pack distribution to Modrinth.** Position: Pack Studio output is a user's work built with a tool; the user decides where to upload and must disclose. Cyrus should NOT auto-publish to Modrinth/CurseForge on a user's behalf, and the UI should state the disclosure requirement.
- **CurseForge:** rules not fetched (U): expect an original-work/permission requirement and its own AI policy. Same stance: user uploads, we show a checklist.
- Cyrus's own hosting (`cyrus.my/packs`) is fine, but as a public download page it must carry the unofficial-content disclaimer and avoid Mojang marks.

## 5. Shaders

### 5a. Iris/OptiFine shaderpacks
- **Iris** (V: github.com/IrisShaders/Iris README): **LGPL-3.0**; dependency glsl-transformer is **AGPL-3.0** and "may affect distribution of Iris" (V from README). Aims for existing OptiFine packs to work unmodified; requires Sodium; OptiFine is incompatible with Sodium. Players install Iris (Fabric/Quilt/NeoForge builds) + put the pack zip in `shaderpacks/`. **Do not bundle or redistribute Iris** in Cyrus products; link to it. A shaderpack zip we generate is *our* work and is not combined with Iris code, so LGPL does not touch it.
- **Format (U, from long-standing community docs; confirm against the Iris docs/shaderlabs):** `shaders/` folder with GLSL stage programs by name (`gbuffers_terrain`, `gbuffers_water`, `gbuffers_entities`, `shadow`, `composite`..`composite15`, `deferred`, `final`; `.vsh/.fsh/.gsh`), `shaders.properties` (options, sliders, screen layout, blend/alpha/buffer flags), `block.properties` (block id mapping), `lang/` strings, optional dimension subfolders `world-1`, `world1`, `#include`, and `#define` option macros. OptiFine-era GLSL 120/330 dialects; Iris adds a few extensions (custom uniforms, extra buffers). Version-sensitive: block id mapping and uniforms change across MC versions; packs typically target a range.
- **Can an AI write a good one?** A *basic* pack (colour grading, simple fog, bloom, vignette, gentle sky tint, composite-only) is realistic: a few hundred lines and a few passes. A *quality* pack (shadow maps, PBR, SSAO, volumetrics, water, TAA, shadow bias handling, per-dimension behaviour, performance across GPUs) is a multi-month specialist job; LLMs make subtle bugs (shadow acne, banding, flicker, precision) that compile fine but look wrong, and driver/Iris differences cause "works on my GPU" failures. **Conclusion (U): AI-from-scratch full shaderpack = no. Parametric presets on a vetted base = yes.**
- **Validation:** `glslangValidator` / `glslc` compile checks catch syntax only (U that the Iris-specific preprocessor macros like `#include`/`#ifdef` options need a stub header). **Headless render feasibility (U):** Mesa llvmpipe (software GL) plus a headless Minecraft with Sodium+Iris (xvfb/`-Djava.awt.headless` is not enough; needs a real GL context via Xvfb + llvmpipe). Possible but **very slow (seconds per frame at tiny resolutions, minutes to load a world)**, needs the game jar (game-derived, build-host only, never served), and a node that is not node-2 (overloaded, customer VMs). Cheaper proxy: render the pack's composite/final passes over a **pre-captured G-buffer** in a small standalone GL harness. Do not start before there is demand.
- **Permissive base code:** I could not verify any popular pack as permissively licensed in this session (the BSL LICENSE URL returned 404; the search returned no list). From memory (U, all must be checked in each repo's LICENSE file): BSL has a custom licence; Complementary/Rethinking Voxels/Photon are custom or restrictive (permission / attribution / no-redistribute-modified clauses); SEUS is closed/paid; Chocapic13 (Unbound lineage) is custom no-derivatives; some small packs on GitHub are MIT/GPL but low quality. **Plan:** treat all as unusable; the base must be **owner-commissioned or Cyrus-authored** (CC0/MIT). The Iris "Aperture-Example-Pack" snippet said "use however you like" but its licence was not shown (U): candidate to verify first, along with the IrisShaders docs repo (MIT per search result) which is documentation, not a pack.

### 5b. Resource-pack core shaders (server-deliverable)
- Mechanism (V from `BB-vanilla-techniques.md` + the reference tree): files under `assets/minecraft/shaders/core/*.vsh/.fsh` (the 26.1.2 reference lists 92 shader files, e.g. `rendertype_text`, `rendertype_outline`, `rendertype_lightning`, `position_tex_color`, `gui`, `particle`, `block`, `entity`, `item`, `lightmap`, `panorama`) and `shaders/post/*` (8 post_effect JSONs). Unsupported-but-working; one pack's file wins on conflicts.
- Version bands (V from BB, sources minecraft.wiki Shader page): JSON programs in 1.21.1; preprocessor flags 1.21.2; program JSON removed + only default uniforms 1.21.5; uniform blocks 1.21.6; 26.x ShaderC, `#include`, stricter syntax; 26.3+ order-independent transparency replaces `transparency`. **So four re-authoring bands**: each effect is written per band.
- Typical safe effects: text effects (gradient/rainbow/shadow-free text via `rendertype_text` colour tricks, used by Oraxen/ItemsAdder for glyph HUDs; BB item 14), per-item tint, dimension fog tint by vertex colour, entity outline recolour, custom sky/cloud tint, UI panel blur-free effects, "emissive" via lightmap bypass on marked vertex alphas, screen-space post effects (`post_effect` pipelines such as a scripted vignette, only 26.x/1.21.5+ variants differ).
- **Ship in mods?** Only as an **opt-in "Effects" asset in the pack with a per-version band check**; Cyrus's own plugin lane never depends on them. Risks (V from BB): break under Iris/OptiFine, conflict with other text-shader packs, fail on version bumps. Fail closed on any band not tested.
- **Testing per version:** (1) static: parse + compile via `glslangValidator` with a stub of vanilla uniform/`#moj_import` headers (U feasibility); (2) real: load in a real client on each band (not done today: `resourcePackClientVerified=false`); an automated real-client run needs the headless GL stack above. So **no core shader ships before the client-verification harness exists**. This matches the tracker's "ship last".

### 5c. Bedrock
- Bedrock uses **RenderDragon**; "Vibrant Visuals" (Mojang's own deferred-lighting upgrade announced 2025) is a first-party feature, not a moddable shader API (U, from memory: shader customisation is limited to `.material.bin` files on Windows/Android; Marketplace-restricted, partly unsupported on iOS/console). **Nothing to build for Bedrock shaders.** Bedrock *texture packs* are possible later (different folder layout, different format, `manifest.json`, `.texture_set.json` for PBR), Geyser can map Java packs (U); not in scope.

## 6. Open question: the image model for T3 heroes
`lib/cyrus` today has no Cyrus-wide pixel image generator outside Room Studio references (grep found no image-model provider module for textures). C-texture.md lists Retro Diffusion/FLUX options but vendor terms/price were not verified and the owner rule says **no paid third-party tools without sign-off**. Plan: v1 uses **no image model** (T1+T2 only, 16x/32x): that is already enough for the "free, original, consistent" pitch. T3 is a phase-3 option needing owner approval and a vendor licence read.

## 7. Product plan

**Lanes**
1. **Pack Studio (new):** wizard "Style -> Scope (blocks/items/GUI/mobs) -> Resolution -> Generate -> Review families -> Download / Deliver". Output: a `.zip` resource pack (and optionally hosted at cyrus.my/packs with the existing publish path). Mobs/entities are a later scope.
2. **Effects (small):** "Add tint/fog/outline/glow effect" picker producing a version-banded core-shader overlay (behind a flag, last).
3. **Shader Studio lite:** after the owner-authored base exists: choose preset (cozy/vibrant/dark/cinematic/low-end), sliders (bloom, fog, saturation, shadow softness), emit `shaders.properties` + option defaults + a screenshot gallery. Distribute as zip with "install Iris" instructions.

**SEO (coordinate with `DZ-minecraft-seo-2026-10-18.md` and `MC-PAGES-PLAN-2026-10-17.md`)**
- Join the existing `/minecraft` cluster (`lib/cyrus/minecraft-seo`, flag `CYRUS_MC_SEO`): new pages `minecraft/texture-pack-generator`, `minecraft/texture-packs` (gallery of 8 example packs, each with a real downloadable zip and 12 contact-sheet previews), per-theme style pages ("cozy", "medieval", "gothic", "cartoon", "low-poly flat" -- words, never "faithful"/"vanilla-like"), `minecraft/shader-presets` later, version pages reuse pack_format table (V from the registry).
- The public generator model matches `public-builder`: first free partial generation (blocks only, 16x, ~96 textures, ~$1 to 3), anonymous daily caps, global spend guard, signed-in full pack. Public example packs must pass the originality report; publish its summary on the page ("original art, no Mojang textures").
- Do not target keywords implying copies of other packs.

**Pricing hooks (U):** free partial; full 16x ~ tokens-equivalent to $25 to 40 (margin on a $15 to 30 cost); 32x 2x; 64x 4x; re-rolls billed at the actual cost. Included in higher tiers. Reuse the hold-then-settle policy hook in `RoomStudioDeps.policy` (V per DZ).

**Verification plan**
- Unit: names-index coverage (no missing/extra paths per version), palette lock, lookalike gate on a fixture set (owner-run on build host), determinism (same spec -> same bytes), animation strip divisibility.
- Real-client: load the 16x pack on 1.21.1/1.21.4/1.21.11/26.1 clients; screenshot grid (client is game-derived, build host only). Nothing is claimed "works on version X" before this.
- Human review: 20-sample style eval (C-texture.md recommended a 30-sample eval before promising quality).
- Legal gate: originality report >= 95% of textures under warn line, else block "download".

**Phases and effort (U, in agent-days):**
| Phase | Deliverable | Effort |
|---|---|---|
| P0 | Read Usage Guidelines/EULA + CurseForge/Modrinth rules; owner decisions | 0.5 |
| P1 | Names-only path index per version (script on private reference); lookalike fingerprint set builder; `StyleTokens`; family planner; 40 T1 generators | 5 to 7 |
| P2 | `buildRetexturePack` (replace-vanilla paths, mcmeta animations, pack.mcmeta from registry, zipcheck), blocks+items 16x, family grid preview UI, re-roll, palette edit | 8 to 12 |
| P3 | Real-client verification harness on 2 versions, SEO pages + free partial generator, 8 example packs | 6 to 8 |
| P4 | 32x/64x detail pass, GUI + particles + colormaps | 5 |
| P5 | Entity sheets (UV templates per mob; creature module reuse) | 8 to 12 |
| P6 | Effects lane (core shader overlays, one band first) | 6 to 8 |
| P7 | Shader presets on an owner-commissioned/verified-permissive base; headless render harness | 10 to 20 |
| Optional | T3 image model hero pass (after owner OK) | 4 |

**Recommendation: build P0 -> P1 -> P2 first (blocks+items at 16x).** Why: reuses the strongest existing assets (DSL, ramps, lookalike, pack host); biggest SEO term where an *original-style* tool is differentiated; cheapest ($15 to 30/pack); fails safely (no vanilla pixels involved, honest "not_run" -> refuse). Shaders come later: highest effort, weakest verification, licensing blockers.

**Risks (ranked)**
1. **Platform/legal:** Modrinth's August 2026 AI-content rules, Mojang commercial terms (unread this session), and the lookalike guard being a coarse 16-cell stub that could miss a close copy or over-flag. Mitigation: free-only until read; stricter gate + originality report; never auto-publish.
2. **Quality:** procedural 16x can look "samey/cheap" (owner's design feedback history: "cheap, vibe-coded"); 64x/128x look blocky. Mitigation: T1 generators with strong shading, vision critique loop, palette editing, honest resolution limits.
3. **No real-client verification yet** (`resourcePackClientVerified=false`): packs could mis-render or break on a format band.
4. **Cost drift** at higher res / image model; mitigate with `ai-gateway-budget.ts` hard stops and per-pack reserve.
5. **Shader complexity and licence** (no verified permissive base; core shaders break across 4 bands).
6. **Scope creep to entities/CTM/emissive** (client-mod dependent; keep out of v1 and label honestly).

## Sources
Code (V): `/tank/dev-worktrees/cyrus-r51/lib/cyrus/{textures,texture-library,packhost,versions,itemmodel,studios}`; `texture-library/lookalike.ts`; `library.manifest.json` (82 templates). Notes: `C-texture.md`, `BB-vanilla-techniques.md`, `ED-minecraft-studios-gap-2026-10-18.md`, `DZ-minecraft-seo-2026-10-18.md`, `CYRUS-TRACKER.md` (owner assets). Counts: private reference zip name listing only. Web: github.com/IrisShaders/Iris (V: LGPL-3.0, AGPL dependency), a Modrinth AI-policy search result (modrinth.com/news/article/ai-policy-and-disclosures; U until the page is read), Minecraft commercial-usage-guidelines search results (U). Failed fetches: minecraft.net/usage-guidelines, help.minecraft.net guidelines (timeouts), BSL LICENSE (404).

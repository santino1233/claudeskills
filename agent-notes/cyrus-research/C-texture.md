# C - Texture Studio research (step 6), 2026-10-10

Labels: VERIFIED (url) = opened this session; UNVERIFIED = memory or search snippet. Pages used: 12 of 12 (three fetches failed/403/404, noted). The fetch tool returns summaries, so exact LICENSE text was not read; "licence" below is what the repo page states.

## 1. Libraries and editors

| project | licence | notes | verdict |
|---|---|---|---|
| Piskel | Apache-2.0 (VERIFIED https://github.com/piskelapp/piskel) | vanilla JS + jQuery, canvas, 1,982 commits; maintainers say they are "unlikely to merge/review" complex features; no mobile; ships as an app, not an npm component. Layers/onion skin/palettes/tiled preview are well known (UNVERIFIED here, excerpt did not list them). | Reference + UX model; embedding as an iframe app is possible but awkward (jQuery globals, no clean API). |
| miniPaint | MIT (VERIFIED https://github.com/viliusle/miniPaint) | layers w/ transparency, undo/redo, selection, pixel grid, PNG/JSON layer data; HTML5 + Webpack; iframe embed documented; 828 commits. General image editor, not pixel-art-specific (no palettes/tiling preview listed). | Best "drop-in" start if we want a fast editor; iframe-embed, own layer JSON. |
| Klecks (the open source of Kleki) | MIT, but the brand "Kleki" is proprietary - cannot offer a service branded as Kleki (VERIFIED https://github.com/bitbof/klecks); first guess URL bitbof/kleki 404'd | layers, undo, selection, a "pixel" brush, embed example in `/examples/embed/`; 417 commits; painting-oriented (smooth brushes), no confirmation of nearest-neighbour small canvases. | Embeddable and well-built, but painting-centric. Possible. |
| Pixelorama | MIT (VERIFIED https://github.com/Orama-Interactive/Pixelorama) | Godot app with HTML5 web export; layers with clipping masks and non-destructive effects, tilemap/seamless mode, animation timeline, palettes. Not a React component; wasm bundle is large (UNVERIFIED size). | Feature-wise the best pixel editor; iframe only. Heavy (Godot runtime), integration through file import/export only. |
| Konva | MIT, react-konva exists, active, 4,186 commits (VERIFIED https://github.com/konvajs/konva) | scene graph for custom editor; page did not mention `imageSmoothingEnabled`; one can set it on the canvas context. | Good base to BUILD our own editor in React. |
| Fabric.js, PixiJS | MIT (UNVERIFIED, memory) | Fabric = object editor, PixiJS = WebGL renderer. | Fabric not suited to pixel work; PixiJS only if we need GPU for 3D-ish later. |
| pngjs / UPNG.js / fast-png | MIT (UNVERIFIED) | PNG encode/decode; our own `lib/cyrus/textures/png.ts` already encodes. | Keep own encoder; use `pngjs` only if decode of uploads is needed. |
| skinview3d | MIT, three.js, 1.8 and HD skins, slim arms, capes (VERIFIED https://github.com/bs-community/skinview3d) | player skins only (UV fixed to the player model). Last release date not shown. | Adopt for player-skin preview; irrelevant for custom mobs. |
| deepslate | MIT, v0.27.2, WebGL structure/block rendering, loads resource packs (VERIFIED https://github.com/misode/deepslate) | summary found no entity/item model support. | Use for block preview/structures later; not for mobs. |
| minecraft-render, prismarine-viewer | UNVERIFIED (not opened) | | Not evaluated; cap hit. |

**Opinion**: no OSS editor gives layered, non-destructive, AI-candidate-aware, Minecraft-aware editing out of the box. The honest choices: (A) iframe miniPaint/Pixelorama as a quick "edit this PNG" tool, (B) build a small purpose-built pixel editor on a plain canvas or Konva (pencil, fill, line, rect, select, mirror, palette, layers, undo, tile preview). B is M-L effort but is what makes AI candidates, per-version validation and the shared studio core fit. Start with A only if time-to-market matters; replace later. Do not use Kleki branding.

## 2. Generating textures automatically

**(a) LLM-authored pixel specs rendered deterministically** (the existing `lib/cyrus/textures` DSL: palette, <=400 ops fill/px/rect/line/circle/poly/gradient/noise/shade/outline, per G-gaps).
- Strengths: free of copyright-lookalike risk from a model trained on game art (UNVERIFIED but logical), deterministic and editable (the spec IS the non-destructive source), exact palette and size, perfect alpha, trivial to keep style consistent (one shared palette per mod), cheap (a few thousand output tokens; approx. cents on Haiku/Sonnet, UNVERIFIED estimate).
- Weaknesses: organic subjects (faces, fur, glow) look blocky/amateur. Sizes above 32x32 get poor.
- Is Claude good enough? For 16x16 items, simple blocks, symbols and flat-shaded creatures: yes with a good prompt and a vision critique loop (render -> show Claude the PNG upscaled -> revise). For detailed creature skins: mediocre. I have not benchmarked this (UNVERIFIED); recommend a 30-sample eval before promising quality. Tricks: symmetry ops, a "ramp" palette (3-5 shades per material), outline-after-shade, noise-for-grain, row-string authoring for tiny sprites (16 chars per row as palette indices), and generate silhouettes first.

**(b) Image models + pixelation + quantisation.**
- FLUX: licensing page shows commercial use via tiered plans (Builder/Platform/Professional/Enterprise); output ownership text was not on the page (VERIFIED https://bfl.ai/licensing). Models named: FLUX.2 [klein] Base 9B and [dev] sit behind paid tiers. Self-hosting needs a GPU.
- Retro Diffusion (Astropulse): pixel-art-specific models, "Minecraft items/textures", sprites, tilesets, 90+ styles, API and MCP server; used by Replicate, Poe, Scenario (search snippet, UNVERIFIED https://mcpservers.org/servers/retro-diffusion/retro-diffusion-mcp; direct fetch returned 403). Commercial terms are in its ToS (not read) and price per image not found. Strongest pixel-art candidate; check seamless tiling and transparency options before use.
- Generic pipeline: generate at 512-1024, downscale with nearest/box to 16/32/64, quantise to a fixed palette (median-cut or an owner-chosen mod palette), clean alpha with threshold/flood fill. Without a pixel-tuned model, results look like blurry downscaled images with dithering noise. Seamless tiling: generate with tileable flag if offered or enforce by offset-and-inpaint (hard). Style consistency across a mod: reuse seed/palette/style reference; hardest for (b).
- Copyright risk: image models can reproduce vanilla Minecraft look or other IP; a vanilla-lookalike policy check (reject prompts naming Mojang/other games' IP, perceptual-hash against vanilla textures) is advisable (UNVERIFIED approach). Mojang's usage rules for assets are separate (not researched).
- Hosted vendor terms and cost: not determined; third-party name must not appear to customers (brand rule).

**(c) Hybrid (recommended)**: Claude plans an asset sheet (palette, silhouette, materials) -> produce candidate A from the DSL; optionally candidate B from a pixel model; both snapped to the mod palette; Claude vision picks/flags; user sees both as candidates. Raise (b) later; keep (a) as the default free path. Cost per texture: (a) cents, (b) UNVERIFIED cents to tens of cents.

**Entity skins/UV**: A custom mob on a vanilla base entity (zombie) uses that entity's fixed UV layout (e.g. `textures/entity/...`), so the studio needs a per-base-model UV template and region overlay. The player layout is 64x64 with an outer overlay layer, slim arm = 3px, inner layer must be opaque on Java (VERIFIED https://minecraft.wiki/w/Skin). Fully custom models (Blockbench-style JSON via item/display-entity tricks) need their own UVs: that is a model-pipeline question outside this file (see mob-model research, if any).

## 3. Validation checklist (per version)

- PNG only; item/block textures may be non-square since 1.13 but stretch on default models (VERIFIED https://minecraft.wiki/w/Resource_pack). Keep square, power-of-two (16/32/64/128) by default (UNVERIFIED best practice).
- Paths: `assets/<ns>/textures/{item,block,entity}/...` (VERIFIED same page); lowercase `[a-z0-9_/.-]`, no spaces (UNVERIFIED but standard).
- Animation: sidecar `<name>.png.mcmeta` with `animation:{frames, frametime(default 1 tick), interpolate(default false), width, height}`; the PNG is a strip of frames; frame size must divide image (VERIFIED same page for fields; divisibility check UNVERIFIED).
- Pack format: 1.21 line 34-53 through 1.21.5; 26.1 = 76-84; 26.2 = 85-88; 26.3 = 89-97; 26.4 (upcoming) = 98-100 (VERIFIED same page); `min_format`/`max_format` supported in pack.mcmeta; 26.1 resource pack format 84.0 (VERIFIED https://minecraft.wiki/w/Java_Edition_26.1). Existing `packFormatFor` returns 75 for 26.x, which is wrong; flag stale (this wiki data is current only as of fetch date).
- 1.21.4+ item models go through `assets/<ns>/items/<id>.json` plus `models/item` (existing pack.ts does this per G-gaps); 26.1 block-model textures can be objects with `sprite` and `force_translucent` (VERIFIED 26.1 page).
- Emissive/overlay conventions (e.g. `_e` emissive suffix, `_overlay`): these are mostly OptiFine/CIT/Iris-style or entity-specific (eyes layers for spiders/endermen) conventions, NOT vanilla for custom textures - UNVERIFIED, do not promise emissive glow in vanilla.
- Alpha: skin inner layer opaque (Java); cutout vs translucent behavior depends on the model/block render type (26.1 `force_translucent`).
- Pack size: warn if > ~50 MB (UNVERIFIED client-prompt behaviour).

## 4. Editing UX for opening a mod's textures

- Source of truth = `TextureSpec` (DSL) plus optional raster layers; PNG is a build artifact. Open asset -> editor loads spec -> user edits in raster layers placed above the generated base layer ("generated" layer locked/regenerable; "paint" layers editable).
- AI edit = a **candidate**: model returns a new spec or PNG; shown side-by-side/onion-skinned; user accepts into a new layer or discards. Never overwrite silently; every accepted change is one undo step with provenance row.
- Version history per asset (content-hash) so "revert to generated" works. Live preview: 16x tile preview (tiling), item preview in inventory slot size, 3D preview via skinview3d (player skins) or three.js for simple cube blocks (deepslate for structures).
- Ledger: same provenance model as Sound (D-sound.md): source = dsl/ai-model/upload, licence, hash.

## 5. Shared studio core with per-game profiles (survey)

Core (game-agnostic): asset registry + versioning, layer stack with non-destructive recipes, undo history, candidate/AI-suggestion workflow, provenance ledger, preview host, export pipeline interface (`validate`, `render`, `package`), plan gating hooks. Both studios (sound recipes, texture layers) share these.
**Pixel profile (Minecraft)**: fixed sizes (16/32/64), nearest-neighbour, palette-first, index/colour limits, tile preview, per-asset UV templates, .mcmeta animation editor, pack-format validator, 16-colour-ramp helpers.
**Realistic/PBR/3D profile (later)**: multi-channel maps (albedo, normal, roughness/metallic, AO, emissive), 2K-4K sizes, GPU-based viewport (three.js/PixiJS), mesh + UV unwrap import (glTF/FBX), engine-specific exporters (Unreal/Unity/Source/Rust-style bundle formats), seamless-tiling synthesis and AI texture models (different tools: diffusion + height-to-normal). Mostly separate editor features, so keep the core small and let profiles plug in tools and validators. UNVERIFIED survey from knowledge; no sources opened for PBR.

## 6. MVP vs later (S <= 2 days, M ~ 1 wk, L multi-week)

MVP: wire existing `textures/` to the build (items) and extend `pack.ts` for blocks/entities/mcmeta + corrected `packFormatFor` (M); Claude spec generation + render + vision critique loop (M); validator (S-M); studio v1 = purpose-built pixel editor (pencil/fill/line/rect/select/mirror/layers/undo/palette/tile preview) (L), or iframe miniPaint stopgap (S-M); candidate workflow + ledger (M); skinview3d preview (S). Later: pixel image model path (M-L), UV templates for vanilla base mobs (M each), animation editor (M), PBR profile (L+).
Build: DSL, validators, editor, candidate workflow. Adopt: miniPaint (stopgap), skinview3d, three.js. Avoid: Kleki branding; Piskel as embed; any generator whose terms were not read.

Risks: model art lookalikes; vendor ToS unread; editor scope creep; wiki pack-format tables change monthly. Could not determine: Claude's actual pixel quality (needs eval), image-API prices, minecraft-render/prismarine status, exact LICENSE files, last-release dates for several repos.

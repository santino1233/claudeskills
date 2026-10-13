# Renders, textures, models and sounds for Cyrus mods: how to plug in AI-generated assets later

Research write-up for the Cyrus v6 programme. Compiled 2026-10-08. Research and design only: no repo changes, no purchases, no sign-ups, no vendor picked.

The owner's words: "how we can potentially plug in the ability later down the road for making renders for people's mods (textures and such)."

Source tags: **[V]** verified this session from a primary source (docs, repo, API, licence text); **[S]** secondary (vendor blogs, hosting KBs, aggregators, search snippets); **[L]** verified in the Nxeon repo or notes; **[I]** inference or general knowledge, not checked this session.

---

## 1. Executive summary (one page)

**The idea in one sentence.** Treat generated art as just another *build artefact*: a generator-agnostic `AssetProvider` interface produces candidates, deterministic code validates and repacks them to each game's exact constraints, the customer picks one, and a per-game packager delivers it (a resource pack for Minecraft, PNGs inside the `.tmod` for Terraria, and so on). Cyrus never trusts a generator's raw output.

**What each game can actually take** (details in section 3):

| Game | What AI-made assets can reach players | Delivery | Ease |
|---|---|---|---|
| Minecraft (Paper/Purpur) | Item and block-item textures, custom item models (cuboid JSON), sounds, GUI/font art, via a server resource pack | Server-hosted pack (<= 250 MiB), SHA-1, UUID, optional required prompt [V] | Easiest, biggest audience |
| Terraria (tModLoader) | Item, NPC, projectile, tile sprites (PNG), icons, sounds (.wav/.ogg/.mp3); no art possible on TShock | Packed inside the `.tmod`; every client needs the mod [V/S] | Easy for single sprites, hard for frame-exact sheets and armour |
| Project Zomboid | Item icons (PNG, `Item_` prefix), model textures, FBX models, poster art | In the Workshop mod; both sides need the mod [V/S] | Easy for icons, medium for 3D |
| Valheim | Icons and textures loaded from PNG at runtime, OBJ meshes, or Unity AssetBundles | In the mod zip; clients need it when `EveryoneMustHaveMod` [V] | Medium: a no-Unity path exists (Jotunn loads PNG/OBJ) |
| Rust | **Only UI images and icons inside custom UI**; no new items, models or textures from a server; skins go through Facepunch-curated Workshop | Sent by the server at runtime through Rust's file storage [V/I] | Narrow scope only |
| Palworld | Nothing practical soon: new textures, meshes and audio need cooked Unreal 5.1 `.pak`/IoStore packages and a Windows server | Client-side install of cooked packages [S] | Defer |

**Recommendation in short.**
1. **Build the interface and pipeline first, with no paid provider.** Ship a "Baseline" provider that has Claude (already paid for through the token economy) author **SVG or palette-indexed pixel grids**, rasterised deterministically. It costs cents, needs no new vendor, and exercises every validator, cache, moderation and delivery path.
2. **Start with the use that is already requested:** listing art (mod icon, banner) for the post-forge listing dialog, then **Minecraft item icons and resource packs**, then simple PNG games (Terraria, Zomboid), then Valheim, then sounds, then 3D.
3. **Evaluate, in this order, once the owner approves a bounded budget (design in section 8, about $15 to $40 total):** (a) the Baseline; (b) one general-purpose text-to-image API; (c) one pixel-art specialist API; (d) only later, 3D and audio providers; (e) self-hosted open weights only if volume justifies GPUs (none was seen on the primary node [L]). The criteria are in section 7.
4. **Be strict on rights.** Several popular open models are non-commercial or revenue-capped, free 3D tiers require attribution, and Modrinth bans primarily AI-generated public listings. Every asset must carry provenance, and AI-made packs should be positioned as "for your own server" until counsel reviews.

**Costs in Cyrus tokens** (token = $0.002 of measured cost, min spend 5 [L: ECONOMY.md]): an LLM-authored icon is roughly 10 to 25 tokens; a mid-priced image is roughly 15 to 70 tokens; one textured 3D model is roughly 100 to 500. A $8.99 server's first-month grant is 245 tokens [L], so **image and 3D generation need their own estimate, reserve and cap**, not an unbounded draw from the build allowance.

---

## 2. Principles

1. **Generator-agnostic.** The product must survive vendors changing price, terms or models. Meshy, for example, is retiring two legacy models on 2026-10-10 and 2026-10-30 [V: [Meshy API pricing](https://docs.meshy.ai/api/pricing)]. Hide every vendor behind one interface and log the provider, model version and seed.
2. **Deterministic after generation.** Resizing, palette quantisation, alpha cleanup, tiling checks, packing and naming are plain code with unit tests. Only the first step is probabilistic.
3. **Hard gates before humans.** A file that would crash a game or show a magenta-black "missing texture" is rejected automatically. For tModLoader a missing texture can stop the whole mod loading [V: [Basic Autoload](https://github.com/tModLoader/tModLoader/wiki/Basic-Autoload)].
4. **The customer approves.** Show 2 to 4 candidates, let them pick, retry or edit. Never silently insert an asset into a build.
5. **Cost is visible and capped**, using the existing reserve, settle and refund pattern in the token economy [L: ECONOMY.md section 5].
6. **Provenance on everything.** Each asset records how it was made so listings, licences, moderation appeals and takedowns work.
7. **Honest labels.** An asset made by a baseline or template provider is labelled as such. Never present a placeholder as finished art.

---

## 3. Per-game asset formats and constraints

### 3.1 Minecraft Java (Paper/Purpur, via a resource pack)

| Item | Detail | Source |
|---|---|---|
| Pack container | Directory or `.zip` with `pack.mcmeta` and `assets/<namespace>/...`. Since snapshot 25w31a the `pack_format` field is replaced by `min_format`/`max_format` (the wiki's example for 1.21.9+ uses 88). The wiki says its format tables are "severely out of date", so read the number from the target version's `version.json` or the server jar, not from memory | [V: [Pack format](https://minecraft.wiki/w/Pack_format)] |
| Textures | PNG, RGBA. Blocks and items are conventionally 16 x 16. Since 1.13 non-square textures work but "look stretched/squashed on default models". Animations are a vertical strip with a `<name>.png.mcmeta`; if the frame size does not divide the image, the client shows the magenta-black missing texture | [V: [Textures](https://minecraft.wiki/w/Textures), [Resource pack](https://minecraft.wiki/w/Resource_pack)] |
| Item look | `item_model` component points to an items definition at `assets/<namespace>/items/<id>.json`; definitions can branch on conditions and compose models. This replaced override stacks on vanilla models from 1.21.4. `custom_model_data` (floats, flags, strings, colours) is still needed for clients older than 1.21.4 | [V: [Items model definition](https://minecraft.wiki/w/Items_model_definition), [Nexo FAQ](https://docs.nexomc.com/general-usage/faq/itemmodels-vs.-custommodeldata), [Paper data components](https://docs.papermc.io/paper/dev/data-component-api/)] |
| 3D models | Vanilla item/block models are JSON elements (cuboids with per-face UVs). Arbitrary triangle meshes are not supported, so 3D generators must be converted to voxels/cuboids or used as a reference | [I]; Blockbench (GPL-3.0 app, so a separate user tool, never embedded) exports these [prior research] |
| Sounds | `.ogg` (Vorbis) plus `sounds.json`; `.mp3` "isn't fully supported" | [V: Resource pack page] |
| Server delivery | `server.properties`: `resource-pack` (URL), `resource-pack-sha1`, `resource-pack-id` (UUID), `require-resource-pack`, `resource-pack-prompt`. **The pack may not be larger than 250 MiB.** Paper's `addResourcePack` with `ResourcePackInfo` (UUID, URI, SHA-1) stacks packs since 1.20.3 | [V: [Server.properties](https://minecraft.wiki/w/Server.properties)]; [S: [Paper Adventure docs](https://docs.papermc.io/adventure/resource-pack/)] |
| Client | Vanilla clients download the pack on join (optional or required). Players can decline unless it is required | [V] |
| Hard limits | Plugins cannot add genuinely new blocks or items; textures only change how existing base items look | [prior research] |

Notes for Cyrus:
- **Never use or derive from Mojang vanilla textures** as a style source, an image-to-image input or a shipped base. They cannot be redistributed [prior research: EULA summary [S]].
- A server may already run a pack. Stack (1.20.3+) or merge rather than overwrite `server.properties` [S].
- Pack changes mean a new UUID or hash, which forces every client to re-download. Version packs and avoid churn.
- Cyrus's Minecraft builder already accepts **reference images** from the customer (PNG/JPEG/WebP/GIF, up to 4 images, 5 MB each, type sniffed from magic bytes) [L: `services/modbuilder/live.js`]. The same sniffing code is the right first validator for any asset.

### 3.2 Terraria

| Item | tModLoader | TShock |
|---|---|---|
| Textures | PNG only. A texture is **autoloaded** by matching the class name and namespace folder (`Content/Items/MySword.cs` + `MySword.png`). Items, projectiles and NPCs without one can prevent the mod from loading [V: Basic Autoload, [Spriting](https://github.com/tModLoader/tModLoader/wiki/Spriting)] | No custom art possible (vanilla clients) [I] |
| Frames | Animated or variant sprites are a single sheet divided into equal frames; the code declares the frame count (example in the wiki: a 96 px tall sheet with 4 frames) [V: Spriting]. Tiles have framed and non-framed rules and need the programmer's input [V] | n/a |
| Icons | `icon.png` 80 x 80 and `icon_small.png` 30 x 30 for the mod list [V: Basic Modding Guide] | n/a |
| Armour | Separate textures per slot; a dedicated "Armor and Equipment Textures" guide exists [V: wiki index] | n/a |
| Glow masks | A separate guide exists [V: wiki index] | n/a |
| Sounds | `.wav`, `.ogg`, `.mp3`; `SoundStyle` wraps the asset and playback settings; vanilla ones are `.xnb` [V: [Basic Sounds](https://github.com/tModLoader/tModLoader/wiki/Basic-Sounds)] | n/a |
| Delivery | Everything is packed into the `.tmod`; clients need the same mods and versions [V/S] | n/a |

Practical constraint: AI image models are poor at **exact pixel grids and frame alignment**. The pipeline should generate larger, then downscale with nearest-neighbour, quantise to a small palette, and snap to the sprite size the code declares.

### 3.3 Project Zomboid (Build 42)

All of this comes from one community guide for B42.15+, so treat it as [S] until confirmed in game [S: [pz-modding-guide visual-assets](https://github.com/gotmayonase/pz-modding-guide)].
- **Item icons:** PNG, "8-bit color only (16-bit is rejected silently)" [ambiguous: probably 8 bits per channel], normally 32 x 32 (64 x 64 works). File `42/media/textures/Item_<Name>.png`; the script says `Icon = <Name>` without the prefix or extension. Food can have `_Cooked`, `_Rotten`, `_Burnt` variants.
- **3D:** a `model {}` script block points at an `.fbx` (`42/media/models_X/`) plus a texture PNG (typically 128 x 128). Export at 0.01 scale with transforms applied; poly counts like vanilla (hundreds to low thousands of triangles). `.glb` is "still being established".
- **Mod art:** `preview.png` 256 x 256 under 1 MB (Workshop), `poster.png` 256 x 256 under 1 MB in `42/`.
- **Sounds:** scripts reference named vanilla sounds; custom sound authoring is not covered in the sources I could read [unknown].
- **Map tiles:** `.tiles` files and tile sheets exist [S: search results; pzwiki.net unreachable] [unknown details].
- **Delivery:** Workshop; most gameplay mods must be on both client and server [S].

### 3.4 Valheim

| Item | Detail | Source |
|---|---|---|
| Engine | Unity **6000.0.61** for AssetBundles; use the same version the game uses | [V: [Jotunn asset-creation tutorial](https://github.com/Valheim-Modding/Jotunn/blob/prod/JotunnLib/Documentation/tutorials/asset-creation.md)] |
| Full path | Item prefab in a Unity project with the game's components, built into an AssetBundle, loaded by the plugin, then registered (`CustomItem`) | [V] |
| **No-Unity path** | Jotunn's `AssetUtils` loads textures (`LoadTexture`, `LoadImage`), sprites from files (`LoadSpriteFromFile`), OBJ meshes (`LoadMesh`) and AssetBundles at runtime; `RenderManager` renders a prefab into a sprite to make icons | [V: `AssetUtils.cs`, [render queue](https://github.com/Valheim-Modding/Jotunn/blob/prod/JotunnLib/Documentation/tutorials/renderqueue.md)] |
| Cloning | New items are usually clones of vanilla prefabs with changed stats, icon and texture; Jotunn "Mocks" resolve vanilla material references at runtime | [V] |
| Sides | `NetworkCompatibility`: `EveryoneMustHaveMod` etc., because a client missing the asset mod sees a different game | [V: [NetworkCompatibility](https://github.com/Valheim-Modding/Jotunn/blob/prod/JotunnLib/Documentation/tutorials/networkcompatibility.md)] |
| Version risk | Valheim 1.0 (2026-09-09) overhauled pieces and categories; Jotunn caught up for 1.0.7 | [V: Jotunn release v2.30.0] |
| Unknown | Valheim texture size limits, audio clip specs, Unity Personal/Pro licence terms for an automated bundle-building service | [unknown] |

Implication: **icons and re-textured clones are feasible without Unity** by writing PNGs the plugin loads. New meshes are feasible as OBJ. Real prefabs and rigs need Unity and a human.

### 3.5 Rust

- A server cannot give vanilla clients new items, models or textures. Existing prefabs and Workshop skin IDs are all a plugin can show [S: [umod skins](https://umod.org/plugins/skins), [oxidemod thread](https://oxidemod.org/threads/workshop-skins-not-working-in-plugins.29292)].
- Workshop skins are for existing items, curated by Facepunch; rules include "dirty and worn" style, matching item tier, no unlicensed IP or logos, and no words that cannot be localised [V: [Getting Skin Accepted](https://wiki.facepunch.com/rust/Getting_Skin_Accepted)]. Texture sizes, submission mechanics and AI policy were not stated on that page [unknown].
- **Where AI art can reach vanilla clients:** custom UI. Carbon's LUI/CUI builds panels with an image database module, and custom vitals take an icon given as a Rust file-storage CRC [V: Carbon docs: [LUI](https://github.com/CarbonCommunity/Carbon.Documentation/blob/main/docs/devs/features/lightweight-ui.md), [custom vitals](https://github.com/CarbonCommunity/Carbon.Documentation/blob/main/docs/devs/features/custom-vitals-manager.md)]. Practical caps (suggest <= 512 x 512 PNG and a small byte budget) are [I] and should be tested.
- Skins as a product: a Steam Workshop submission by a human, with Facepunch review. Out of scope for an automated Cyrus flow.

### 3.6 Palworld

- Palworld mod formats: PalSchema (JSON data, including `skins`/`appearance` entries that reference existing assets), UE4SS Lua, **resource paks** ("textures, meshes, audio, cooked asset replacements" as "cooked content, not runtime logic"), LogicMods, native C++ [V: [PalSchema](https://okaetsu.github.io/PalSchema/docs/gettingstarted); S: [palmods.gg](https://www.palmods.gg/docs/authors/creating-mods/choose-a-format)].
- Cooked content needs **Unreal Engine 5.1** with a pinned toolchain (.NET 6, VS 2022 MSVC 14.38, Wwise 2021.1.11) and often `.pak` + `.utoc` + `.ucas` files [S: [Modding Kit](https://www.palmods.gg/docs/authors/creating-mods/modding-kit)].
- Server-side mods are Windows-server only per community docs [S], and Nxeon's Palworld image is the native Linux server [L], so even the delivery path is unresolved.
- Verdict: **not a candidate for AI textures in the first phases.** If revisited, start with PalSchema data referencing existing assets, which needs no new art.

### 3.7 Cross-game summary table

| Asset kind | MC | Terraria tML | Zomboid | Valheim | Rust | Palworld |
|---|---|---|---|---|---|---|
| 2D item icon / texture | Yes (pack) | Yes (PNG in mod) | Yes (PNG) | Yes (runtime PNG) | UI only | Cooked only |
| Animated sprite | Yes (`.mcmeta`) | Yes (sheet frames) | Limited [unknown] | Via Unity | No | Cooked only |
| 3D model | Cuboid JSON only | n/a (2D game) | FBX | OBJ runtime / Unity | No | Cooked only |
| Sounds | `.ogg` | `.wav/.ogg/.mp3` | Unknown | Bundles | No | Cooked only |
| Client must install | Pack download (can be required) | Whole mod | Whole mod | Depends on compatibility level | Nothing | Package install |
| Listing art (icon/banner) | Yes | Yes | Yes (poster/preview) | Yes | Yes | Yes |

**Listing art is the one asset kind that is identical for every game** and has no engine constraints. The owner has already asked for "logo/icon, brief description" after a forge; that is the natural first consumer.

---

## 4. A generator-agnostic provider interface (TypeScript sketch)

This is a design sketch, not code to commit. It follows existing Cyrus conventions: pure types in `lib/cyrus`, a registry like `lib/cyrus/games/support.ts`, token accounting through `lib/cyrus/tokens`, and server-only adapters.

```ts
// lib/cyrus/assets/types.ts  (PURE, client-safe)
export type AssetKind =
  | "icon"          // small item/UI icon
  | "texture"       // surface texture, optionally tileable
  | "sprite"        // character/item sprite, optionally a multi-frame sheet
  | "ui-image"      // image inside a game UI panel
  | "listing-art"   // mod logo / banner for the NxLabs listing
  | "model-3d"      // mesh (voxel/cuboid, OBJ, FBX, glTF)
  | "sound-effect"
  | "music";

/** Hard constraints a game target imposes. Validators enforce these, never the provider. */
export interface AssetSpec {
  kind: AssetKind;
  game: string;                       // CyrusGame.id
  width?: number; height?: number;    // exact pixels, if fixed
  frames?: number;                    // animation frames, stacked vertically unless frameLayout says otherwise
  frameLayout?: "vertical" | "horizontal" | "grid";
  tileable?: boolean;
  format: "png" | "svg" | "ogg" | "wav" | "obj" | "fbx" | "glb" | "json";
  alpha: "required" | "forbidden" | "optional";
  maxColors?: number;                 // palette cap (pixel-art targets)
  maxBytes?: number;
  maxTriangles?: number;
  nameStem: string;                   // exact stem the loader expects ("Item_MySword", class name, ...)
}

export interface AssetRequest {
  id: string;                         // idempotency key (one per user action)
  accountId: string; projectId: string;
  spec: AssetSpec;
  prompt: string;                     // customer intent in plain words
  style?: {
    paletteHex?: string[];            // from the mod's palette or listing branding
    referenceAssetIds?: string[];     // OUR stored assets only; never third-party game art
    mood?: string;
  };
  count: number;                      // candidates wanted (1 to 4)
  seed?: number;
  budget: { maxUsd: number };         // hard cap enforced before and during the call
}

export interface CostEstimate { lowUsd: number; highUsd: number; basis: string; }

export interface ProviderCapabilities {
  kinds: AssetKind[];
  nativeSizes?: { min: number; max: number };   // e.g. pixel specialists cap near 512 px
  supportsSeed: boolean; supportsTransparency: boolean;
  supportsTiling: boolean; supportsImageReference: boolean;
  deterministic: boolean;
  /** Where the vendor's terms stand; set from a human-reviewed record, never from the API. */
  rights: { commercialUse: "yes" | "conditional" | "no" | "unreviewed"; attributionRequired: boolean; reviewedAt: string; notes: string };
  moderation: { builtIn: boolean; notes: string };
  retention: { trainsOnInputs: "yes" | "no" | "unknown"; storesOutputsDays?: number };
}

export interface RawCandidate {
  bytes: Uint8Array; mime: string;
  providerModel: string;              // vendor model id + version string
  providerJobId?: string;
  seed?: number;
  costUsd: number;                    // actual
  meta?: Record<string, unknown>;
}

export interface AssetProvider {
  readonly id: string;                // "baseline-svg", "vendor-x-image", ...
  capabilities(): ProviderCapabilities;
  estimate(req: AssetRequest): Promise<CostEstimate>;
  generate(req: AssetRequest, signal: AbortSignal): Promise<RawCandidate[]>;
  /** Optional: poll-style vendors (3D, audio) return a job instead of blocking. */
  start?(req: AssetRequest): Promise<{ jobId: string }>;
  poll?(jobId: string): Promise<{ state: "queued" | "running" | "done" | "failed"; candidates?: RawCandidate[]; error?: string }>;
  cancel?(jobId: string): Promise<void>;
}

// ---- moderation -----------------------------------------------------------------
export interface ModerationVerdict {
  stage: "prompt" | "image" | "audio" | "model";
  allowed: boolean;
  categories: string[];               // "sexual-minors", "hate-symbol", "real-person", "protected-ip", ...
  score?: number;
  checker: string;                    // which classifier/version produced this
}
export interface Moderator { check(input: { text?: string; bytes?: Uint8Array; mime?: string }, stage: ModerationVerdict["stage"]): Promise<ModerationVerdict>; }

// ---- pipeline outputs -----------------------------------------------------------
export interface Provenance {
  providerId: string; providerModel: string; seed?: number;
  promptHash: string;                 // sha256 of normalised prompt; store the text separately and privately
  requestId: string; createdAt: string;
  moderation: ModerationVerdict[];
  rights: ProviderCapabilities["rights"];
  postProcess: string[];              // "downscale-nearest 64->16", "quantize 16 colors", ...
  aiGenerated: true;
}

export interface ValidatedAsset {
  id: string; sha256: string; mime: string; bytes: number;
  width?: number; height?: number;
  spec: AssetSpec; provenance: Provenance;
  costUsd: number; tokens: number;
  status: "candidate" | "approved" | "rejected" | "published";
}

// ---- per game target ------------------------------------------------------------
export interface GameAssetTarget {
  game: string;
  supports(kind: AssetKind): boolean;
  /** Turn a loose request into the exact spec for this game and version. */
  specFor(kind: AssetKind, ctx: { version: string; modId: string; slug: string }): AssetSpec;
  /** Hard checks (format sniffing, dimensions, alpha, palette, frame divisibility, size). */
  validate(raw: RawCandidate, spec: AssetSpec): Promise<{ ok: boolean; problems: string[]; fixed?: RawCandidate }>;
  /** Place approved assets into the mod's file tree and produce any pack. */
  package(assets: ValidatedAsset[], tree: ModFileTree): Promise<{ files: ModFile[]; packs?: DeliverablePack[] }>;
}

export interface DeliverablePack {
  kind: "resource-pack" | "datapack" | "bundle";
  fileName: string; sha256: string; sha1?: string; bytes: number; uuid?: string;
}

// ---- delivery -------------------------------------------------------------------
export interface PackHost {
  /** Content-addressed upload; returns a stable HTTPS URL for server.properties or the Paper API. */
  put(pack: DeliverablePack, bytes: Uint8Array, opts: { ttlDays?: number }): Promise<{ url: string }>;
  revoke(url: string): Promise<void>;
}
```

### 4.1 Orchestrator contract

```ts
// server-only
export interface AssetPipeline {
  quote(req: AssetRequest): Promise<{ estimate: CostEstimate; tokensHigh: number; provider: string }>;
  run(req: AssetRequest): AsyncIterable<
    | { type: "moderated"; verdict: ModerationVerdict }
    | { type: "candidate"; asset: ValidatedAsset; previewUrl: string }
    | { type: "rejected"; reason: string[] }
    | { type: "done"; settledUsd: number; tokens: number }
  >;
  approve(assetId: string): Promise<void>;
  regenerate(assetId: string, tweak: { prompt?: string; seed?: number }): Promise<void>;
}
```

### 4.2 Design choices

- **Provider selection** is policy, not a global: choose by `kind`, `game`, size, budget and the owner's allow-list. A fallback chain (cheap first, escalate on failed gates) mirrors the build service's model routing [L: `route.js`].
- **Rights are metadata maintained by humans.** `capabilities().rights` is filled from a reviewed record with a date, and an `unreviewed` provider cannot serve customer assets (hard stop in code).
- **Assets live beside the mod, not inside the DB.** Store bytes in object storage addressed by SHA-256; keep a row per asset (id, project, kind, hash, size, spec JSON, provenance JSON, cost, tokens, status). If this needs a Prisma model, add it at the end of `schema.prisma` with a comment per the programme rules [L: CONTEXT.md]; this research adds none.
- **`GameSupport` extension, additive:** an optional `assets?: { kinds: AssetKind[]; specs: ...; delivery: "resource-pack" | "bundled" | "runtime-load" | "ui-only" | "none" }` so the same contract that already holds install, versions and risks says what art each game can take.

---

## 5. The pipeline

```
Customer intent (+ optional reference images from the customer)
  1. Prompt moderation (text)                          -> block / allow
  2. Spec resolution (GameAssetTarget.specFor)         -> exact size/format/frames/name
  3. Prompt compiler (Claude): expand intent into a provider-specific prompt, palette hints,
     negative prompt, and a size plan (e.g. generate at 512, target 16)
  4. Cost quote -> token estimate -> reserve (high end)  [existing economy pattern]
  5. Provider.generate -> N candidates (parallel, capped)
  6. Output moderation (image/audio) + provider's own filter result
  7. Post-process (deterministic code): background removal if needed, nearest-neighbour downscale,
     palette quantisation to <= maxColors, alpha cleanup, edge/tile seam fix, frame slicing
  8. Hard validation (GameAssetTarget.validate): PNG magic + decode, exact dimensions, alpha, palette
     cap, frame divisibility, byte limits, filename stem, no embedded metadata/text chunks
  9. Soft validation (vision model, small tier): "is this a <thing>? any text, logo, watermark, face,
     protected character?"; flags go to the customer, serious ones reject
 10. Customer picks / retries / edits (crop, recolour, flip)
 11. Package (GameAssetTarget.package): put files in the mod tree, build the resource pack, hash
 12. Store (content-addressed) + provenance record
 13. Deliver: PackHost URL + install step, or bundled in the mod zip
 14. Settle cost (refund unused reserve); free if the failure was ours
```

### 5.1 Stage details worth getting right

- **Validation reuse.** `sniffImage` (magic-byte type detection) and `parseImages` limits already exist for reference images [L: `services/modbuilder/live.js`]; extend rather than write new parsers. Decode with a safe library, strip metadata chunks, and reject decompression bombs by capping pixel count before decode.
- **Pixel-art discipline.** General image models do not produce exact pixel grids. Generate larger, downscale with nearest-neighbour after a smart crop, quantise with a fixed palette, and snap to the declared sprite size. For Minecraft, a 16 x 16 icon is the default; offer 32 x 32 as an opt-in because large textures cost client memory [I].
- **Palette consistency.** A mod with five items should look like one mod. Store a per-project palette and style note and feed it to every request; the prompt compiler owns this, not the vendor.
- **Tiling.** For tileable textures, test seams by wrapping the image and measuring edge difference; reject or auto-blend.
- **Animations.** Prefer deterministic animation (palette cycling, frame offsets) done in code over asking a model for frames, because frame-to-frame consistency is poor in general models [I]. Specialist tools do offer sprite animation, but check output sizes and cost per animation [S: Retro Diffusion advanced animations $0.14 to $0.25 [V: [repo README](https://github.com/Retro-Diffusion/api-examples)]].
- **Sounds.** Normalise loudness, trim silence, convert to `.ogg` for Minecraft, cap length, and reject clipping; music is a licence minefield (see 7).
- **3D.** Convert to the target's representation: voxelise to cuboids for Minecraft JSON, decimate and export FBX at 0.01 scale for Zomboid [S], export OBJ for Valheim's `LoadMesh` [V]. Generators often yield messy topology that needs cleanup [S: [Tripo P2.0 review](https://digitalproduction.com/2026/09/29/tripo-p2-0-put-quad-mesh-generation-to-the-test/)].
- **Visual QA with Claude.** The build service already shows images to Claude as reference input [L]. A small-tier vision pass for "matches the request, no text/logos/watermarks, silhouette readable at target size" is cheap and catches many failures before the customer sees them. Treat its output as advisory, not proof.

### 5.2 Caching

- **Key:** `sha256(kind | normalised prompt | provider id | provider model | params | seed | target spec)`. Deterministic providers (and the Baseline) get true cache hits; stochastic ones cache by `requestId` to make retries idempotent.
- **Scope:** within an account/project by default. Do not share private generations between customers. A curated public library (assets Nxeon or the community explicitly publish with a licence) can be shared.
- **Never cache moderation approvals across policy versions**; re-check when the policy version changes.

### 5.3 Storage and delivery

- **Object storage, content-addressed** with versioned references from the mod manifest. Keep candidates for a short TTL (for example 7 days) and approved assets for the life of the mod.
- **Minecraft:** generate the pack with `pack.mcmeta`, `assets/<slug>/items/*.json`, models, textures and sounds. Compute SHA-1 and a stable UUID per pack lineage. Host at a stable HTTPS URL on Nxeon's own domain (no third-party host named to customers). The install step either writes `resource-pack`, `resource-pack-sha1`, `resource-pack-id` to `server.properties` (one pack, needs a restart) or adds the pack through Paper's `addResourcePack` from a tiny generated companion plugin, which **stacks** with an existing server pack (1.20.3+) [S]. Warn if the server already sets a pack. 250 MiB is the hard cap [V]; set a lower internal budget.
- **Terraria / Zomboid / Valheim:** bundle into the mod archive the existing install flow already moves; no separate hosting. For updates, bump the manifest version so loaders and clients notice (lifecycle agent's domain).
- **Rust:** keep UI images small and bundled with the plugin or its data folder, loaded at runtime.
- **Revocation:** if an asset is later taken down (moderation, rights complaint), revoke the host URL and flag every mod version that references the hash so lifecycle warnings can tell the creator.

---

## 6. Cost control and token-pricing considerations

### 6.1 Reference numbers (verify again before any decision; prices move)

| Provider type | Price signal | Source |
|---|---|---|
| LLM-authored SVG or pixel grid (Baseline) | Output tokens only: Sonnet 5.5 is $2 in / $10 out per MTok, so a 2,000-token reply is about $0.02 | [L: ECONOMY.md price table] |
| General image API, token-priced | For one OpenAI family the pricing page lists per-million-token rates (for example $30 output per MTok for the current top models, $8 for the mini); the page itself gives no per-image table and points to a calculator. A third-party aggregator listed an older model at about $0.009 / $0.034 / $0.133 per 1024 x 1024 image at low / medium / high quality | [V: [OpenAI pricing](https://developers.openai.com/api/docs/pricing)]; [S: [pricepertoken](https://pricepertoken.com/gpt-image-pricing)] |
| Pixel-art specialist | Retro Diffusion lists about $0.03 (Fast), $0.06 (Plus), $0.18 (Pro) per image; sizes 12 to 512 px with most styles capped near 256 to 384 px; wang tilesets at 16 to 32 px tiles; low-poly 3D $0.25 to $3.00; it has a "check cost before generating" call | [V: repo README] |
| Text-to-3D API | Meshy API: text-to-3D preview 20 credits (5 on a lite model), texture refine 10 to 15, remesh 5; Tripo about $0.20 per text-to-3D, $0.30 image-to-3D; Rodin charges per download | [V: Meshy pricing]; [S: aggregators] |
| Subscriptions | Pixel tools such as PixelLab list $12 / $24 / $50 per month plans | [S: [devtoollab](https://devtoollab.com/ai-tools/pixellab-ai)] |

### 6.2 Converting to Cyrus tokens

The economy defines `tokens = max(5, ceil(costUsd x 500 x multiplier))` with Katara and Saka at x1.0 and Yakko at x1.25 [L: ECONOMY.md section 1]. Applying it to assets gives, for multiplier 1:

| Cost | Tokens |
|---|---|
| $0.02 (Baseline icon) | 10 |
| $0.06 | 30 |
| $0.134 | 67 |
| $0.40 (one textured 3D model, low end) | 200 |
| $1.00 | 500 |

For scale, an $8.99 monthly server grants 245 tokens initially and 80 on renewal [L]. Three medium images could consume a third of a month's grant; one 3D model could consume all of it.

### 6.3 Controls to build in

1. **Quote before spend**, and show the number in tokens in the dock (the economy's reserve table pattern).
2. **Reserve the high end, settle actual, refund the rest** (same as builds) [L: ECONOMY.md section 5]. Failures on Cyrus's side are free within the account's existing free-failure allowance; a provider returning garbage that fails hard gates should count as ours.
3. **Per-request, per-day and per-mod caps** (candidates per request <= 4, regenerations <= N, daily asset spend), plus an admin kill-switch per provider.
4. **Tier gating:** keep the Baseline and small pixel icons in every tier; allow 3D and audio only where the cost is covered, perhaps as separate priced actions rather than drawing from the code allowance.
5. **Cheap first:** generate small, preview small, upscale only the chosen one; fail hard gates before paying for a second pass.
6. **Cache and reuse**; discourage silent regeneration loops.
7. **Instrument:** log cost per accepted asset by provider and kind. That number, not the price list, decides which provider stays.
8. **Provider failure budget:** vendors deprecate models (Meshy retires two on 2026-10-10 and 2026-10-30 [V]); record model versions and alert on deprecation notices.

---

## 7. Providers: kinds, caveats and selection criteria (no vendor picked)

### 7.1 Kinds of provider

| Kind | Good at | Weak at | Rights and licence notes |
|---|---|---|---|
| **A. LLM-authored vector or pixel grids** (Cyrus's own model tiers) | Flat icons, logos, simple item silhouettes, UI glyphs; deterministic re-render; tiny cost; no new vendor; already moderated by Cyrus's refusal rules [L: system prompt rule 7] | Painterly or detailed art, anything photographic | Output ownership follows the existing Anthropic terms (verify, [S] in prior research) |
| **B. General text-to-image APIs** | Concept art, listing banners, painterly textures, flexible prompts | Exact pixel grids, transparency, tileability, consistent character across items | Often assign output rights to the user "to the extent permitted by law" (OpenAI terms quoted via [S: [terms.law comparison](https://terms.law/ai-output-rights/comparison)]), subject to content policy; check each vendor |
| **C. Pixel-art specialists** | Fixed small sizes, palettes, tilesets, sprite animation | Large or realistic art; coverage limited to listed styles; some are subscription tools without an API | Commercial terms not stated in the repo README I read; confirm with the vendor [unknown] |
| **D. Open weights, self-hosted** | Control, privacy, no per-image fees | Needs GPUs (none seen on the primary node [L]); licence limits (below); ops burden | Licences below |
| **E. Text/image-to-3D** | Rough meshes and textured props quickly | Topology, small parts merging, holes, need retopology; engine conversion needed | Free tiers are CC BY with attribution; paid tiers grant ownership [S: [Tripo licensing blog](https://www.tripo3d.ai/blog/commercial-use-ai-3d-models) and aggregator summaries]. Read each vendor's terms directly |
| **F. Voxel / cuboid tools** | Matches Minecraft's model format; Blockbench is a manual editor (GPL-3.0, so a separate user tool) | Not generators | Output is the user's |
| **G. Audio generation** | Short sound effects, ambience | Music licensing, length caps (Stable Audio Open: up to 47 s stereo at 44.1 kHz) | See licences below |

**Open-weights licence facts checked this session [V]:**

| Model | Licence (from the model card or licence text) | Consequence for a paid Cyrus service |
|---|---|---|
| FLUX.1 [schnell] | Apache-2.0 | Usable commercially |
| FLUX.1 [dev], FLUX.2 [dev] | Non-commercial licences; the licence text bars use "for any commercial or production purposes" of the model, while saying the vendor claims no ownership of outputs. The two statements are in tension, so counsel must read it | Do not host for a paid service without a commercial agreement |
| Stable Diffusion 3.5 (large) | Stability AI Community License: free for research and non-commercial use and for commercial users under US$1,000,000 annual revenue (registration required); above that, an enterprise licence | Possible while small; terminates above the cap; track revenue |
| Qwen-Image | Apache-2.0 | Usable commercially |
| Hunyuan3D-2 | Tencent community licence that **does not apply in the EU, UK and South Korea**, and requires a licence above 1 million monthly active users | Territory exclusion is a serious problem for a global product |
| TRELLIS (image large) | MIT | Usable commercially |
| MusicGen small | CC-BY-NC-4.0 | Not usable commercially |
| Stable Audio Open 1.0 | Stability AI Community licence (same revenue cap structure) | Possible while small |

Sources: Hugging Face model cards and licence files fetched via the Hugging Face API and file URLs (FLUX licence from the `black-forest-labs/flux` repo, Stability licence at `stable-diffusion-3.5-large/LICENSE.md`, Hunyuan3D licence at `Tencent-Hunyuan/Hunyuan3D-2/LICENSE`). Re-read the current text before use; licences change.

### 7.2 Selection criteria (score each 0 to 5, weights suggested)

| # | Criterion | Weight | What to check |
|---|---|---|---|
| 1 | **Rights and ToS** | 20 | Commercial use of outputs by our customers; attribution; no revenue cap or territory exclusion; indemnity; what happens if terms change |
| 2 | **Moderation and safety** | 10 | Built-in input/output filters; ability to run our own; false-positive rate on benign game art (swords, blood, zombies) |
| 3 | **Fit to constraints** | 15 | Native small sizes, transparency, palette control, tiling, seed support, reference-image support |
| 4 | **Quality at target size** | 15 | Blind human preference on our eval set after our post-processing |
| 5 | **Cost per accepted asset** | 15 | Accepted rate x price, including retries; price transparency; pre-flight cost API |
| 6 | **Reliability and latency** | 5 | P50/P95 latency, error rate, rate limits, queueing for 3D/audio |
| 7 | **API stability** | 5 | Versioned models, deprecation notice, SDK maturity |
| 8 | **Data handling** | 5 | Trains on our inputs? retention; region; prompt privacy |
| 9 | **Determinism and reproducibility** | 5 | Seeds, stable model versions (matters for caching and support) |
| 10 | **Lock-in and portability** | 5 | Can we swap the provider without changing prompts and specs |

A provider with **0 on criterion 1** is disqualified regardless of score.

### 7.3 What to evaluate first (recommendation)

1. **B0: the Baseline** (kind A). Lowest risk, builds the whole pipeline and moderation path. Measure how many Minecraft-style 16 x 16 icons and listing icons the customer accepts without regeneration.
2. **B1: one general text-to-image API from kind B** with the clearest commercial terms and built-in moderation, plus our post-processor. Targets listing banners, painterly textures and larger concept art.
3. **B2: one pixel-art specialist from kind C**, only if B0 plus B1 do not meet Minecraft, Terraria and Zomboid sprite needs. Check its commercial terms first.
4. **Later:** kind E (3D) for Minecraft cuboids via voxelisation and Zomboid FBX; kind G (audio) for sound effects. Evaluate after at least one 2D provider has proven the review-and-package flow.
5. **Self-hosting (kind D)** only if monthly volume justifies a GPU node and the licence is Apache-2.0 or MIT. No GPU was visible on the primary node [L: `lspci`, `nvidia-smi` absent]; other nodes were not inspected.

---

## 8. A bounded evaluation to run later (design only; do not run without approval)

- **Prompt set:** 30 prompts across six asset kinds (item icon, block texture, tileable texture, sprite, listing banner, short sound), written by a human, 10 per game family (Minecraft, Terraria, Zomboid), plus 10 adversarial prompts (real people, protected characters, hateful symbols, sexual content, "in the style of" a named game, attempts to smuggle text into textures).
- **Run:** 3 candidates per prompt per provider, same post-processor and validators.
- **Measure:** hard-gate pass rate before and after post-processing; blind pairwise preference by two humans; accepted-asset rate; cost per accepted asset; P50/P95 latency; moderation true/false positives on the adversarial set; reproducibility with a fixed seed; any ToS surprise recorded from the written terms.
- **Rough budget:** 30 prompts x 3 candidates x about $0.05 is under $5 per general or pixel provider; allow $15 to $40 total including a 3D trial of 5 models (Meshy-style credits: a few dollars) and a Claude QA pass. [I] This needs the owner's explicit approval first (rule 5), and sign-ups for trial keys were not done.

---

## 9. Content moderation

1. **Layers:** (a) prompt moderation before any spend, reusing Cyrus's refusal logic; (b) the provider's own filter, recorded; (c) output classification of every candidate (image, audio, model preview renders); (d) a Claude vision QA pass; (e) human report-and-review path for NxLabs listings. OpenAI's multimodal moderation model is free to call for text and images [S: [Analytics Vidhya, 2026-05](https://www.analyticsvidhya.com/blog/2026/05/openai-omni-moderation/)]; other options include open classifiers and each vendor's built-in filter. Choose by false-positive rate on game art (violence is normal in Zomboid and Rust).
2. **Categories to block:** sexual content involving minors; sexual content generally on a 13+ product; real people's likenesses; hate symbols; self-harm; doxxing or personal data in textures; malware lures (QR codes, URLs, "download here" text inside textures, a real risk in Workshop-style distribution).
3. **IP protection:** do not accept prompts that name protected characters or ask for copies of another game's art. Block "Pal"-style requests that mimic named Palworld, Pokemon or Mojang assets. Never feed vanilla game textures into image-to-image or style transfer (Mojang art cannot be redistributed; official art is forbidden by programme rules [L: CONTEXT.md]).
4. **Text in images:** games render these in many languages and at small sizes; text is a moderation and IP risk (Facepunch even rejects skins with words, because they cannot be localised [V]). Default the negative prompt to "no text, no logo, no watermark" and reject any candidate where OCR finds text.
5. **Private by default.** Candidates are visible only to their owner; publishing to NxLabs triggers a fresh moderation pass and shows the "AI-generated" marker.
6. **Logging:** store the verdict, checker version and policy version with each asset; keep an audit trail for appeals.
7. **Minors:** the earlier plan assumed a 13+ age gate [prior research]; images are the area where an under-age user's exposure is highest, so keep strict defaults.

---

## 10. Licensing and ownership

This section lists questions and facts, not legal advice.

**Facts gathered**
- US Copyright Office, *Copyright and Artificial Intelligence, Part 2: Copyrightability*, published 2025-01-29 [V: [copyright.gov/ai](https://www.copyright.gov/ai/)]. The earlier research summarised it as: prompts alone do not make a user an author, while human selection, arrangement or modification can be protected [S/prior]. The Supreme Court declined review in *Thaler v. Perlmutter* on 2026-03-02, leaving the human-authorship requirement [S/prior].
- Vendor terms commonly assign the vendor's rights in outputs to the user, subject to content policy. OpenAI's terms say the user owns input and output "to the extent permitted by applicable law" [S: via terms.law]. Terms differ per vendor and change.
- **Free tiers of some 3D vendors are CC BY** (attribution required), while paid tiers grant ownership [S]. Cyrus must never route customer work to a free tier.
- **Model licences** differ, as in 7.1 (non-commercial, revenue caps, territory exclusions).
- **Platform rules:** Modrinth bans primarily AI-generated public projects, requires disclosure for AI-assisted ones, and bans AI images in listings [V prior: [Modrinth policy](https://modrinth.com/news/article/ai-policy-and-disclosures/)]. Steam (January 2026) requires disclosure of generative AI content that players consume, not behind-the-scenes tools, and holds developers responsible for copyright and safety [S: [Gigazine summary](https://gigazine.net/gsc_news/en/20260120-steam-updates-ai-disclosure-guidelines), others]. Facepunch's skin rules on IP and localisation apply to Rust Workshop submissions [V]. Hangar and uMod policies on AI-generated assets were not found [unknown].
- Game-specific: the Minecraft EULA wording on selling mods and the brand guidelines that forbid official art are [S] and unconfirmed (prior research flagged this for counsel).

**Recommended defaults for Cyrus**
1. The customer owns what they generate **to the extent the law allows**; Cyrus gives no copyright guarantee.
2. Cyrus keeps a licence to host and deliver it for the customer's purposes, and the customer grants a separate licence if they publish to NxLabs (so others may remix it, which the community agent's fork/remix features need).
3. Record `aiGenerated: true`, the provider, model version and licence on every asset and in the mod manifest. Show an "AI-generated art" notice on NxLabs listings and let creators choose a licence for the pack.
4. Position AI-made packs as tooling for the customer's own server; never auto-publish to third-party marketplaces.
5. Do not use any model whose licence excludes commercial use or whole territories where Nxeon sells. Re-review terms on a schedule (suggest quarterly) and when a vendor announces changes.

**Questions for counsel**
- Does the Minecraft EULA and Mojang's brand policy affect packs sold or distributed from a paid service?
- Are Palworld, Terraria, Valheim, Rust and Zomboid mod licences or EULAs relevant to asset distribution through a paid generator?
- How to handle takedown notices on generated assets that resemble existing IP.
- Whether a customer-facing licence grant for NxLabs remix is enough for AI-assisted works.

---

## 11. Rollout plan

| Phase | Scope | Why this order | Gate |
|---|---|---|---|
| 0 | `AssetProvider`/`GameAssetTarget` types, Baseline provider, listing icon and banner in the post-forge dialog, validators, storage, token quote | Cheap, universal, no vendor, directly serves the owner's "logo/icon" request | Hard-gate pass rate, moderation tests, token accounting tests |
| 1 | Minecraft: item icons, item-model definitions, resource-pack build, pack host, install step with stacking | Biggest audience; the platform has a native delivery path | A real Paper test server loads the pack; vanilla client shows the item |
| 2 | Terraria tML sprites and Zomboid icons | Plain PNGs into the mod tree; moderate size rules | Load tests on real games (owned by game agents) |
| 3 | Valheim icons and re-textures via runtime PNG loading | The no-Unity path exists | Test against Jotunn and the current game build |
| 4 | Sound effects (Minecraft `.ogg`, Terraria) | Needs a provider decision and loudness tooling | Moderation and licence review for audio |
| 5 | 3D (Minecraft cuboids, Zomboid FBX, Valheim OBJ) | Highest cost and cleanup effort | Cost per accepted model within cap |
| Later | Rust UI imagery, Palworld cooked assets, skins | Narrow or blocked by platform | Re-assess |

Effort guesses [I], one engineer: Phase 0 about 8 to 12 days, Phase 1 about 8 to 12 days, Phases 2 to 3 about 5 to 8 days each, Phase 4 about 5 days, Phase 5 about 10 to 20 days.

---

## 12. Open questions and unknowns

1. Zomboid custom sound and tile specifics; Valheim texture/audio limits; Rust UI image size and byte limits; Terraria armour texture layout details. All need game-side testing.
2. Whether the chosen provider's retention and training terms permit sending customers' prompts and reference images (privacy policy impact).
3. Whether Nxeon has any GPU capacity (only the primary node was checked, and it showed none).
4. Hosting pack files for Minecraft at scale: bandwidth, CDN, and who pays for downloads by every joining player.
5. Interaction with the lifecycle agent: asset hash changes should produce update notices; takedowns should raise creator warnings.
6. Unity's licence for an automated AssetBundle service (Valheim).
7. Whether to expose "AI art" to NxLabs search filters and categories (community agent).
8. Current prices and terms in section 6 and 7 are from one day's reading and aggregators; re-verify at decision time.

---

## 13. Sources

Minecraft:
- Server.properties, Items model definition, Pack format, Textures, Resource pack (Minecraft Wiki, read only; content is CC BY-NC-SA and was not copied): https://minecraft.wiki/w/Server.properties , https://minecraft.wiki/w/Items_model_definition , https://minecraft.wiki/w/Pack_format , https://minecraft.wiki/w/Textures , https://minecraft.wiki/w/Resource_pack
- Paper data components: https://docs.papermc.io/paper/dev/data-component-api/ ; Paper Adventure resource packs: https://docs.papermc.io/adventure/resource-pack/
- Nexo ItemModel vs CustomModelData: https://docs.nexomc.com/general-usage/faq/itemmodels-vs.-custommodeldata
- Modrinth AI policy: https://modrinth.com/news/article/ai-policy-and-disclosures/

Terraria: tModLoader wiki raw pages (Spriting, Basic-Autoload, Basic-Sounds, Basic-tModLoader-Modding-Guide, Home index) at https://github.com/tModLoader/tModLoader/wiki

Zomboid: https://github.com/gotmayonase/pz-modding-guide (visual-assets.md, item-scripting.md)

Valheim: Jotunn docs and source at https://github.com/Valheim-Modding/Jotunn (asset-creation, renderqueue, networkcompatibility tutorials; `JotunnLib/Utils/AssetUtils.cs`; release v2.30.0)

Rust: https://wiki.facepunch.com/rust/Getting_Skin_Accepted ; Carbon docs https://github.com/CarbonCommunity/Carbon.Documentation (lightweight-ui, custom-vitals-manager) ; https://umod.org/plugins/skins ; https://oxidemod.org/threads/workshop-skins-not-working-in-plugins.29292

Palworld: https://okaetsu.github.io/PalSchema/docs/gettingstarted ; https://www.palmods.gg/docs/authors/creating-mods/choose-a-format ; https://www.palmods.gg/docs/authors/creating-mods/modding-kit

Providers and licences:
- Meshy API pricing: https://docs.meshy.ai/api/pricing
- Retro Diffusion API examples: https://github.com/Retro-Diffusion/api-examples
- OpenAI pricing: https://developers.openai.com/api/docs/pricing ; aggregator: https://pricepertoken.com/gpt-image-pricing
- Tripo licensing blog: https://www.tripo3d.ai/blog/commercial-use-ai-3d-models ; Tripo P2.0 review: https://digitalproduction.com/2026/09/29/tripo-p2-0-put-quad-mesh-generation-to-the-test/
- Hugging Face model cards and licences: black-forest-labs/FLUX.1-schnell, FLUX.1-dev, FLUX.2-dev; stabilityai/stable-diffusion-3.5-large, stable-audio-open-1.0; tencent/Hunyuan3D-2 (licence at github.com/Tencent-Hunyuan/Hunyuan3D-2); microsoft/TRELLIS-image-large; facebook/musicgen-small; Qwen/Qwen-Image
- Copyright Office AI page: https://www.copyright.gov/ai/ ; Steam AI disclosure coverage: https://gigazine.net/gsc_news/en/20260120-steam-updates-ai-disclosure-guidelines ; output rights comparison: https://terms.law/ai-output-rights/comparison ; OpenAI moderation overview: https://www.analyticsvidhya.com/blog/2026/05/openai-omni-moderation/

Local: `/root/agent-notes/cyrus-economy/ECONOMY.md`, `/opt/nxeon/services/modbuilder/{live.js,route.js,prompts.js}`, `/root/agent-notes/cyrus-v6/CONTEXT.md`, `/root/agent-notes/ai-modbuilder/RESEARCH.md`

Not reachable (Cloudflare or 403): umod.org, pzwiki.net, pzfans.com, openai.com/api/pricing (the developers.openai.com mirror worked).

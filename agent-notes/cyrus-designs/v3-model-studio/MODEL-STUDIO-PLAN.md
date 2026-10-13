# Cyrus Model Studio: plan (design only, 2026-10-10)

Labels: **V** = I read it in code (cyrus-r2 `lib/cyrus`, cyrus-r13 `assets3d/manifest.ts`, `adapters/asset-profile.ts`, `jobs/asset-jobs.ts`). **U** = unverified. Every quality claim about AI output is **U until a paid eval runs**. Mockups: `*.html` + `shots/` in this folder.

## 1. What exists today (V)
| Piece | Where | Fact that matters here |
|---|---|---|
| RigSpec v1 | `creature/spec.ts` | Zod `strictObject`; bones/cubes/clips; caps 32 bones, 64 cubes, 8 clips, 48 KB; model never writes UVs |
| Compiler | `creature/compile.ts` | box UV `boxFaces` + shelf `layoutSkin` (64/128), deterministic `.bbmodel` (rig-c1) |
| Preview | `creature/preview.ts` | pure software rasteriser, byte-stable PNG |
| Item states | `itemmodel/*` | 8 display contexts, per-category transforms, states; gun transform U in client |
| Texture Studio | `studios/paint.ts`, `editor.ts`, `service.ts` | `TextureDoc` = locked spec + sparse paint layer; `History<T>` 200 steps; save = new revision + asset row, `expectedHeadId` → 409 `stale_head` |
| Gate | `engine-core/asset-gate.ts` | `ASSET_MIN_PLAN.model = "all"`; only create/edit gated; unknown plan fails closed |
| Foundation (r13) | `assets3d/manifest.ts`, `asset-profile.ts`, `asset-jobs.ts` | glTF + sidecar, legal ledger, `libraryEligible`, `WORKER_CLASSES`, in-memory queue + object store (no DB tables yet) |

## 2. Architecture per layer
| Layer | Serves | Canonical data | Human edits | Runtime |
|---|---|---|---|---|
| L1 viewport + paint | every model | `ModelDoc` + `TextureDoc` per texture (reused) | paint, fill face, pick, decals | three.js (MIT) client, lazy route chunk |
| L2 cuboid + bone editor | MC creatures (RigSpec), MC 3D items (`ItemCuboidSpec`), Hytale | RigSpec v1.1 / ItemCuboidSpec v1 | cubes, bones, pivots, UV boxes, keys | client ops on the spec; compile server-side |
| L3 retexture + light edit | FiveM/RedM liveries, later GMod/Zomboid, Palworld/ARK | glTF 2.0 + sidecar, per-channel lossless layers | layers, decal transforms, material values, small transforms | client; unwrap/convert/pack on workers |
| L4 AI mesh | hard-surface and organic props | glTF + sidecar (`ai-mesh`) | transform, material, UV tweaks only (no sculpting) | `linux-cpu` Blender or `gpu` worker |

### Data model additions (Cyrus-prefixed, opaque ids, no FKs into Nxeon)
| Addition | Shape | Why |
|---|---|---|
| `ModelDoc` v1 (asset row, kind `model`, mime `application/vnd.cyrus.modeldoc+json`) | `{v, kind: creature\|item3d\|mesh, spec, ids, textures: {key: TextureDoc}, layers, pins}` | one saveable unit; spec stays the build-service contract |
| RigSpec **v1.1** (additive) | optional cube `id`, `uv: [u,v]` pin, `skin.paint` ref | stable ids for merge; pinned UV keeps paint in place. Needs compiler rig-c2 + regenerated build-service copy (strict schema rejects new keys) |
| `ItemCuboidSpec` v1 (new) | elements from/to, single-axis rotation, per-face UV auto/pinned, materials, decal layers; links `ItemModelSpec` states | the real 3D gun; emits one model JSON per state into the existing pack |
| `CyrusModelDraft` | `projectId, ownerRef, assetKey, baseAssetId, baseHeadId, doc, updatedAt`, unique per owner+key | autosave, not a revision |
| `CyrusAssetJob`, `CyrusObject` | DB backing for r13 `JobQueue` / `ObjectStore` | workers, previews, exports |
| `CyrusPreviewRender` | key = sha(specSha + renderer + preset) → object key | cache |
| `CyrusLibraryAsset`, `CyrusLibraryReport` | `assetSha, kind, creatorRef, state, filters Json, legalClass, licenceVersion` | community asset library (today's `CyrusLibraryItem` is a mod-page bookmark, a different thing) |
| `AssetProfile.meshBudget` (proposed) | `{maxTriangles, lods: number[], maxMaterials}` | L4 cleanup target and checks |
| manifest `provenance.generator` (proposed) | `"ai-mesh" \| "ai-spec" \| "studio" \| …` | flags AI-mesh output; library + filters read it |

### Save, revisions, undo, autosave, AI edits
| Concern | Design |
|---|---|
| Undo/redo | client op log on the `ModelDoc`; reuse `History<T>` (200 steps); one gizmo drag / stroke / accepted candidate = one step |
| Autosave | debounce 5 s idle, max 30 s, to `CyrusModelDraft`; reload restores; drafts are never built or shared |
| Save | explicit "Save revision": validate (spec + quality) → compile → revision kind `asset` + asset row; `expectedHeadId` → 409 stale_head, same as textures |
| AI edit mid-session | AI never touches the working copy. It returns a candidate built from base revision R. If the user has unsaved edits: 3-way merge per node id (bone, cube, key, layer); disjoint changes merge, overlaps listed ("1 overlap"); human wins by default; Apply / Apply part / Reject (mockup b) |
| AI writes, human fixes | prompt → spec (never raw mesh, never UVs) → deterministic render + look check → user opens it and fixes; each save is a revision (mockup f) |

## 3. L2 editor operations (cut line for v1)
| v1 | Later |
|---|---|
| select (click, outliner), add/delete/duplicate cube and bone, reparent (drag) | box/lasso multi-select |
| move/resize cube (gizmo + fields, 1/16 snap), inflate | free rotation for items (if version allows, U) |
| bone pivot move, bone rotation, tag none/head/glow | IK, constraints (never: new rigging tools) |
| mirror X (paired `_l/_r`), material + solid/fade | per-face UV editing beyond box UV |
| UV: auto-pack / pinned, show net on the sheet | UV pack optimiser |
| clips: the 5 required + up to 8, keys (rotation, position, scale), linear/smooth, wave tracks, scrub, play, loop | onion skin, curve editor |
| budgets live (RigSpec caps), validator issues inline | |
| decals on faces (existing `DecalZ` ops) | |

## 4. Viewport requirements
| Requirement | Target |
|---|---|
| Channels | profile-aware: Lit, Albedo, Normal, Rough, Metal, AO, Emissive, UV checker, Wire. Channels a profile cannot ship are shown disabled with the reason (MC Java item: albedo only) |
| In-hand / contexts | the 6 `PREVIEW_CONTEXTS` + state scrubber from `ItemModelSpec`, using the pack's own display numbers (fixes the gun-not-in-hand bug: grip anchor check `grip_in_hand`) |
| Performance budget | 60 fps desktop for ≤ 64 cubes; L3/L4 ≤ 150k tris in view, ≤ 4 × 2048² channel textures, GPU memory ≤ 512 MB; stroke-to-pixel ≤ 16 ms at 2048²; three.js chunk lazy-loaded only on studio routes |
| Mobile (< 760 px) | read-only orbit + Approve/Reject; DPR capped 1.5; falls back to the server turntable PNG if WebGL fails |

## 5. Server-side preview render (node-2)
| Lane | How | Determinism |
|---|---|---|
| Cuboid (L1/L2, all MC + Hytale) | extend `creature/preview.ts` software rasteriser (no GPU, pure TS) | byte-identical; golden **hashes** |
| Mesh/PBR (L3/L4) | headless Chromium (Playwright already on node-2) + three.js on SwiftShader, fixed camera presets, DPR 1, no clocks, fixed tone mapping | pinned Chromium build; golden **images** with tolerance (≤ 0.5 % pixels off by > 2/255) |
Runs as `linux-cpu` jobs in the capped `nxeon-build-agents.slice` (2 GB, 200 % CPU, 60 s timeout, no network), same pattern as the sound render host. Never on the primary. Output: 6 context shots + 8-angle turntable, cached by key.

## 6. Hytale `.blockymodel` emitter
New emitter from RigSpec v1.1, behind the Hytale adapter `maturity: experimental`; export unlocks per item only after a real client loads it (mockup d). **All U** (from memory and host wikis, not official docs): node/shape schema (box vs quad, offset vs position, stretch); per-face `textureLayout` (offset, mirror, angle); units, pivot origin, quaternion orientation; `.blockyanim` keyframe format vs our 5 baked clips; texture size rules; asset pack `manifest.json` and server streaming handshake; Linux dedicated server availability. Keep it a pure function with versioned fixtures so a format change is one file.

## 7. L4: AI mesh generation (owner addition)
| Route | How | Quality / cost (all U) |
|---|---|---|
| (a) Script geometry | Claude writes Blender-Python (bmesh, modifiers, bevels, booleans) run headless in a sandboxed `linux-cpu` worker (no network, allow-listed modules, 10 min cap); render 6 views → vision model compares to the prompt → Claude revises the script, max 4 passes | best for hard-surface (guns, crates, lanterns); token cost per pass unknown; organic shapes weak |
| (b) Parts library | Cyrus-owned kits (receiver, barrel, stock, grip, magazine; wheels, cabins) assembled by script with sockets | the main quality lever; needs authoring time; parts are `platform-library` class |
| (c) Image/text-to-3D | self-hosted TRELLIS (MIT) on a `gpu` worker; Meshy/Tripo only with owner spend approval; Hunyuan3D excluded (licence excludes EU/UK/KR) | blobby topology, no rig, unknown UVs; always goes through cleanup |
| Cleanup (all routes) | decimate/retopo to `meshBudget.maxTriangles`; xatlas UV; bake normal (and AO) from the high-poly; LOD chain per `meshBudget.lods`; manifold, watertight, UV-overlap, scale/units checks | fails closed: an asset that misses budget or checks is not saved |
Lands in: `AssetProfile.meshBudget`, manifest `provenance.generator: "ai-mesh"`, legal class `ai-generated-for-user`. Human step stays: transform, material values, UV tweaks in Model Studio, never sculpting (mockup a, `?mesh=1`). Not for Minecraft Java (no meshes); useful for FiveM props and later UE games.

## 8. What Claude can and cannot produce (say this in the product)
| Layer | Realistic | Not |
|---|---|---|
| L2 | blocky items, creatures, props for MC and Hytale | smooth/organic shapes |
| L1 | paint, stickers, decals, wear | photo-real textures |
| L3 | realistic vehicles/clothing **only** as a retexture of a template the user supplies | new realistic meshes, anything shipping the base mesh |
| L4 | stylised or simple hard-surface props within a budget | rigged characters, hero assets, guaranteed likeness |
Quality for every row is unverified until the paid eval (100 owner-labelled samples, the existing vision-judge plan).

## 9. Community asset library (owner decisions: automatic, not opt-in)
- **Flow:** asset saved → if `libraryEligible(manifest)` → `pending checks` → filters → `published` or `held for review` → (report) → `removed`. States shown as badges in the studio and "My contributions" (mockup e).
- **Never enters:** game-derived, third-party-licensed, imported. **Gap found (V):** `libraryEligible` only excludes `provenance.source === "import"`; a file the user **uploaded** is `source: "user"` and passes. Add an `uploaded` source (or flag). Also exclude anything whose `derivedFrom` hits a game-derived hash (a livery is only meaningful on the game's mesh).
- **Filters (lib-1):** provenance, trademark/logo (text + vision), real-weapon names (AK-47, Glock... a hold, not a block), adult content (vision on 6 renders), near-copy of known game assets (perceptual hash vs a reference set). All thresholds U.
- **Rights:** licence grant in the Terms of Service at sign-up and repeated in the studio; creator keeps copyright; attribution `@handle` kept in pack credits; report + takedown queue with a person; removal does not break mods already using the asset (U: owner decision).
- **Gate:** browsing open to all; "Use in project" = asset create → follows `canAsset` for the kind (today: model/texture = All models, sound = Saka). The owner's "usable by anyone" conflicts with this; decision needed.

## 10. Plan placement (proposal, owner decides)
Model Studio paint, edit and retexture at **All models** (matches `ASSET_MIN_PLAN.model`). Never gated: view, orbit, in-game preview, install, export, rebuild, Mod Packs, import, library browsing. Server checks every create/edit; unknown plan fails closed for edits only. Alternative: give Saka **paint-only** on existing models (cheap upsell) — it writes textures, so it would contradict the Texture Studio gate.

## 11. Testing
| Level | What |
|---|---|
| Unit | spec v1.1 / ItemCuboidSpec validators, merge (3-way per node), op log undo/redo, UV pin + resample, budgets, gate per op, `libraryEligible` cases |
| Golden | cuboid renderer hashes per fixture; mesh lane image diffs; compiler output hashes (`.bbmodel`, item JSON per state, `.blockymodel`) |
| Integration | save → revision → pack, workers on the memory queue, stale_head + overlap paths |
| Real Test Flight | MC 26.x: BetterModel creature load + item states in hand (player client, owner) |
| Stays unverified without a real client | Hytale everything; FiveM YTD in-game; GMod VTF; gun display transforms until a person looks; vision-judge scores |

## 12. Phased tasks (size, model)
| # | Task | Size | Model | After |
|---|---|---|---|---|
| F1 | DB tables for jobs/objects/drafts/preview cache + host seam wiring | M | Sonnet | r13 |
| F2 | `ModelDoc` + RigSpec v1.1 + rig-c2 + regenerated service copy | M | Opus | F1 |
| F3 | ItemCuboidSpec v1 + emitter into the pack + states | L | Opus | F2 |
| F4 | Cuboid preview lane on node-2 (jobs, cache, contexts, turntable) | M | Sonnet | F1 |
| L1a | three.js viewport shell, orbit, channels, contexts/state scrubber | L | Opus | F2 |
| L1b | paint-on-model (raycast → texel → TextureDoc), decals, UV panel | M | Opus | L1a |
| L2a | editor ops v1 + gizmo + outliner + op log + autosave | L | Opus | L1a |
| L2b | timeline + keys + clip validation | M | Opus | L2a |
| L2c | candidate 3-way merge UI | M | Opus | L2a |
| H1 | `.blockymodel` emitter behind maturity flag + fixtures | M | Sonnet | F2 |
| L3a | glTF import, sidecar, legal class, job retention, channel layers | L | Opus | F1 |
| L3b | UV island view, layer transforms, export picker; mesh preview lane | M | Sonnet | L3a |
| L3c | FiveM YTD packing on the Windows worker | L | Opus | L3a + worker |
| L4a | Blender script worker + look loop + cleanup pipeline + meshBudget | L | Opus | F1, paid eval |
| LIB | library tables, filters, states, report/takedown, My contributions | L | Opus (filters) / Sonnet (UI) | F1, ToS |
| QA | golden suites, Test Flight scripts | M | Sonnet | each |
Order: F1 → F2 → (F3, F4, L1a) → L1b → L2a → L2b/L2c → H1 → L3a → L3b → L3c → L4a; LIB can start after F1 once the ToS text exists.

## 13. Owner decisions
1. Plan placement (section 10), and whether Saka gets paint-only.
2. Library "usable by anyone" vs the plan gate on "Use in project".
3. Library: does removal pull the asset from mods already using it?
4. Real-weapon names: hold for review (proposed) or block; allowed in private mods (proposed yes).
5. L4 spend: paid eval budget; Meshy/Tripo API use; a GPU worker at all.
6. Hytale emitter now (experimental) or after a real client is available.
7. L3 template retention: session only (proposed) vs a short encrypted cache (legal call).
8. ToS licence wording (needs a lawyer); AI-output copyright position per region.

## 14. Honest risks
| Risk | Mitigation |
|---|---|
| Paint lost when a painted cube is resized/relaid | UV pin + nearest resample + warning |
| RigSpec schema bump breaks the build service copy | additive v1.1, generated copy, test checks both |
| Display transforms for guns unverified | `grip_in_hand` check + one owner Test Flight before launch |
| Hytale format churn | experimental flag, export gated on real-client check |
| AI mesh quality below "not cheap" bar | parts library first, budget/cleanup fail closed, paid eval before marketing |
| Community library legal exposure (trademarks, real guns, near-copies, AI copyright) | filters + hold + takedown; lawyer on ToS before launch |

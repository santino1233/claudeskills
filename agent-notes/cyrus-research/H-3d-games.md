# H: Cyrus 3D texture/model support for many games (research, 2026-10-10)

Label key: **V** = verified at the URL given (many are hosting-provider docs, i.e. secondary sources); **U** = unverified (my knowledge, not opened). Official docs.fivem.net / Pocketpair / Facepunch wiki pages returned 404, so those games rest on secondary sources. Effort: ~13 pages fetched, ~20 searches, licence lookups via GitHub API/raw LICENSE for ~25 repos (not counted as pages).

## 0. Verdict
Real 3D support is not one feature, it is a **delivery problem first**. Only games where the server pushes (or Workshop auto-delivers) assets to players fit a hosting business. Hytale is the standout (new, server-first, open-ish formats). Rust, Fallout, GTA single-player and Valheim are poor fits. Build the foundation as **texture-first, PBR-channel-aware, delivery-aware**; do not build a mesh editor or text-to-3D now.

## 1. Per-game go/no-go

| Game | Formats / toolchain / OS | How assets reach players | Dedicated server fits Nxeon | Policy stance | AI retexture feasibility | Diff | Verdict |
|---|---|---|---|---|---|---|---|
| **Hytale** | `.blockymodel` + PNG + JSON, asset pack = zip/folder with `manifest.json`; Blockbench (GPL-3, V api) + official plugin; no Windows-only tool (V: blog.curseforge.com/hytale-asset-editor-guide/, hytalemodding.dev/en/docs/guides/plugin/creating-block) | **Server streams to client at join, nothing installed by players** (V: curseforge blog; handshake detail U via host wikis) | Yes (server software availability on Linux U) | Server Operator Policies v1.1 cover monetisation/cosmetics/gambling, silent on mod ownership and AI (V: hytale.com/server-policies); EULA governs (U not read) | High: blocky low-res UV, PNG-only, same shape as our Minecraft bbmodel/RigSpec work | S-M | **START** |
| **FiveM / RedM** | YTD/YDR/YFT/YMAP/YTYP + `fxmanifest.lua` `stream/` folder; authoring via CodeWalker (Windows, **no licence declared**, V api) / Sollumz (Blender, GPL-3, V api) / OpenIV (closed, U) | **Server streams `stream/` assets to clients** (V: xgamingserver.com/blog/how-to-stream-custom-assets-fivem/) | Yes, already in Nxeon code behind flag | Take-Two: tolerated for non-commercial, but excludes importing other IP, new maps/missions, and online services; "not a license", revocable (V: support.rockstargames.com/en-US/articles/5NVOAYjcTomO8v6SX2k76k/pc-single-player-mods; RP server rules V: rockstarintel.com/...roleplay-servers...). Cfx.re (now Rockstar) names Tebex the only authorised monetisation partner (V: gameserverkings.com/knowledge-base/fivem/server-monetisation/) | Medium: retexture liveries/clothing/props on a **user-supplied** UV template; new meshes weak | M (texture-only) / L (mesh) | **START (texture-only, bring-your-own template)** |
| GTA V single-player | Same formats; OpenIV/ScriptHookV | Manual client install | No server | Same Take-Two page; no commercial | Same as FiveM | M | **NO** (no hosting fit; FiveM covers the asset side) |
| **Garry's Mod** | MDL/VTF/VMT, `.gma` addon; whitelist of folders; Crowbar (no licence found, U) / Source SDK `studiomdl` need game install, Windows-first (V: wiki.facepunch.com/gmod/Workshop_Addon_Creation) | Workshop; `resource.AddWorkshop` forces client download on join, 8,192-file cap (V: wiki.facepunch.com/gmod/resource.AddWorkshop) | Yes (Linux srcds, U) | Workshop rules: own content or creator consent (V, same page) | High for materials (VTF DXT1/5, 512-1024) | S (textures) / L (models) | **LATER** (cheapest second texture-only Workshop game) |
| **Palworld** | UE pak (swap models/textures), UE4SS Lua (MIT, V api); official experimental Workshop; needs UE cook toolchain (Windows) (V: connecthosting.net/blog/palworld-server-mods-what-works) | Server-side mods only on **Windows** dedicated server; visual mods are client-only (same page); Workshop experimental; Pocketpair "July 2026 mod support improvement" announced, no detail (V: search result, not opened) | Awkward: Linux binary is what hosts run | "Mods welcome, use at your own risk" (V connecthosting) | Medium (UE materials), rigged Pals hard | L | **LATER** (needs Windows worker + UE cook; moving target) |
| **Rust** | Facepunch Workshop skins via Unity-based submission (U) | Client downloads Workshop skin by ID; **server cannot add models/textures** (V: umod.org/community/rust/24417-adding-new-custom-models-like-weapon-vehicles-or-player) | Yes, but nothing to push | Workshop submission is accepted/curated by Facepunch (U) | Skin retexture feasible, but we cannot deliver | n/a | **NO** (only a "skin submission helper" idea; revisit later) |
| **Fallout 4 / Skyrim SE** | NIF meshes, DDS BC7/BC5, BA2 archives; Creation Kit, NifSkope (V: nexusmods.com/fallout4/articles/341/ via search) | Manual client install or Bethesda Creations | **No server** | EULA: mods must be free; Bethesda sells its own Creations (V: techraptor.net/content/fallout-4s-eula-says-mods-must-remain-free) | High for texture swaps | M | **NO** (no hosting fit, no delivery; only a standalone tool, not a hosting feature) |
| **ARK ASA / ASE** | UE5 DevKit (ASA, Epic store, huge download), UE4 DevKit (ASE) (V: ark.wiki.gg/wiki/Modding, store.epicgames.com/p/ark-survival-ascended--devkit) | ASA: CurseForge ID in server args, clients auto-download (V: xgamingserver.com/docs/ark-survival-ascended/installing-mods) | Yes | CurseForge terms (U) | Medium | L | **LATER** (UE cook needed) |
| Project Zomboid | `.fbx`/`.X` models, PNG textures, Lua; Blender (V: github.com/FWolfe/Zomboid-Modding-Guide) | Workshop; server lists IDs, clients fetch (U) | Yes | Steam Workshop terms (U) | High for PNG clothing/vehicle skins | S (textures) | **LATER** (cheap with GMod) |
| Valheim | BepInEx (LGPL-2.1, V api) plugins + Unity asset bundles | **Manual: every client needs same mods** (V: xgamingserver.com/blog/how-to-add-install-mods-to-a-dedicated-valheim-server/) | Yes | n/a | Texture packs only, client-side | M | **NO** (delivery impossible server-side) |
| Terraria / tModLoader | 2D PNG sprites, C# mod, tModLoader MIT (V api) | **Server prompts clients to auto-download mods** (V: nodecraft.com/support/games/terraria/tmodloader-server-guide-for-1-4) | Yes | tML community norms (U) | High, but 2D = existing pixel studio | S | **LATER** (not 3D; 2D profile) |
| 7 Days to Die | XML + Unity asset bundles | XML pushed from server; **asset bundles/icons need client install, EAC off** (V: winternode.com/help/games/7-days-to-die/setup/installing-mods + search summary) | Yes | EAC must be disabled (V) | Low | M | **NO** (for assets) |
| Space Engineers | `.mwm` = FBX + Havok `.hkt` + XML; Blender add-on; MwmBuilder + Havok tools (Windows) (V: spaceengineers.wiki.gg/wiki/Modding/Reference/Models) | Steam Workshop / Mod HUB auto-download (V: search snippet, press release) | Yes (Windows server common, U) | Keen EULA (U) | Medium | L | **LATER** |
| **Unturned** (found) | Unity asset bundles + Workshop | **Server downloads Workshop items, players auto-download on join** (V: supercraft.host/wiki/unturned/workshop-mods-not-downloading/) | Yes | Developer mod-friendly (U) | Medium; needs Unity editor (licence U) | M-L | **LATER** |
| **Arma Reforger** (found) | Enfusion Workbench (Windows), Workshop | Server pulls mods from the Workshop on boot, clients download on join, console too (V: xgamingserver.com/docs/arma-reforger/mod-setup) | Yes | BI licence (U) | Medium | L | **LATER** |
| Roblox-likes | Platform-hosted | n/a | n/a | n/a | n/a | n/a | **OUT** |

## 2. Recommended starting order
1. **Hytale** (new profile, same family as our Minecraft work: blocky mesh + low-res PNG, server-pushed so no player action, no game-derived assets, no Windows tools, policy silent rather than hostile). Reuses RigSpec to Blockbench-model compiler idea (new emitter `.blockymodel`) and the pixel Texture Studio. Risk: young game, formats may change (U); keep it behind a maturity flag.
2. **FiveM/RedM texture-only lane** (liveries, clothing, props retexture on user-supplied templates). Largest paying audience, already in code, server-pushed. Needs the Windows worker for YTD packing, so it is also the forcing function that proves the worker. No new meshes, no map/mission content (Take-Two excludes those), no Tebex/monetisation features.
3. Then the "Workshop-delivered texture-only" pair **GMod + Zomboid** (PNG/VTF materials; delivery = user publishes to Workshop; tool-light).
Everything else waits until delivery or Windows/UE tooling is proven.

## 3. Architecture needed now

**Canonical asset model (decision):** glTF 2.0 (meshes, UV sets, skeleton, metallic-roughness PBR) plus a Cyrus sidecar manifest (provenance, legal class, per-slot role, units). Alternatives rejected: USD (heavy, no web viewer ecosystem), FBX (proprietary SDK), engine-native formats (lock-in). **Store channels as separate lossless layers** (albedo sRGB, normal, roughness, metallic, AO, emissive, height, masks) and **pack only at export** per engine. Units: metres, +Y up (glTF); the adapter converts axis/handedness.

**Per-engine packing (adapter's job; all U, verify per game before shipping):**

| Target | Typical channel convention |
|---|---|
| Unreal (Palworld, ARK) | BaseColor, Normal (DirectX, -Y), ORM pack (AO/Rough/Metal) |
| Unity (Unturned) | Metallic in R, smoothness in alpha; OpenGL normal |
| Source (GMod) | VTF DXT1/DXT5, `$basetexture`/`$bumpmap`, phong masks |
| GTA/RAGE (FiveM) | Diffuse + normal + spec in YTD (DDS inside RSC container) |
| Fallout 4 | DDS BC7 diffuse, BC5 normal (V: nexusmods Fallout 4 guides via search) |
| Hytale | PNG per model (flat albedo, U) |

**Libraries (licence verified from repo LICENSE/GitHub API on 2026-10-10 unless marked):**

| Need | Pick | Licence | Note |
|---|---|---|---|
| BCn encode (Windows worker) | DirectXTex `texconv`, DirectXMesh | MIT (V) | Windows exe, ok in worker |
| BCn/KTX2 on Linux | Basis Universal (UASTC/ETC1S, BC7 transcode) | Apache-2.0 (V) | also web delivery |
| KTX2 tooling | KTX-Software | Apache-2.0 for repo files, third-party mixed (V) | check bundled deps |
| Compressonator | GPUOpen | no licence detected by GitHub (U: MIT in practice) | avoid until checked |
| Mesh optimise/LOD | meshoptimizer | MIT (V) | |
| UV unwrap/atlas | xatlas | MIT (V) | |
| Import/convert | assimp | BSD-style (V header) | |
| glTF processing | glTF-Transform / gltf-pipeline | Apache-2.0 (gltf-pipeline V; glTF-Transform U) | |
| Viewer | three.js | MIT (V) | server-side preview via headless Chromium or a small Node renderer |
| Heavy DCC | Blender headless, **separate process only** | GPL (V "NOASSERTION", GPL in practice U) | glTF-Blender-IO Apache-2.0 (V) |
| Do not embed/ship | Blockbench (GPL-3, V), Sollumz (GPL-3, V), CodeWalker (no licence, V), Crowbar (none found) | | Run only in isolated workers on user data, never redistribute; legal review before CodeWalker use |

**Windows build worker:** one more worker class beside node-2 Linux builds. Ephemeral VM per job (or snapshot revert), no outbound network except the broker, **pull-based** job queue, signed job manifest, allow-listed tools only, hard timeout and CPU/RAM caps, no Proxmox or Nxeon credentials on the guest, outputs returned through object storage and re-scanned on Linux (format validators, size caps, forbidden-content scan). Game installs (Creation Kit, UE dev kits, GTA files) are legal-gated: only if the game's EULA allows hosted use (U for all); default = user supplies templates.

**AI texturing (reality check):**

| Option | Facts | Use |
|---|---|---|
| LLM spec + procedural/deterministic render (existing approach) | cheap, reproducible | default; masks per UV region from adapter |
| Image model into UV space with region masks, then seamless tiling | image models do not understand UVs; works with masks/templates | texture lane |
| PBR estimation | Material Palette (MIT, V search); normals from height and heuristic roughness are deterministic and free | derive channels, do not hallucinate them |
| Meshy / Tripo APIs | paid plans own the output; Meshy free tier is CC BY 4.0 (V: docs.meshy.ai/en/webapp/pricing; tripo3d.ai blog); low-poly modes exist, quality claims are vendor marketing | prototype props only, per-call cost |
| Hunyuan3D-2 | Community licence **excludes EU, UK, South Korea** and forbids using outputs to train other models (V: repo LICENSE) | **NO** |
| TRELLIS | MIT (V api) | optional self-host prop prototypes; still no game-ready topology/UV/rig |

Text-to-3D gives static prop blobs, not game-ready characters or vehicles: no rig, wrong topology, unknown UVs. Do not promise it.

**Storage/jobs:** S3-compatible content-addressed store (sha256 keys), 4K PBR sets run 100+ MB uncompressed so cap per tenant and store derivatives lazily. Jobs get a `workerClass` (`linux-cpu`, `windows-tools`, `gpu`); start API-based for image models, no own GPU cluster.

**Asset-profile contract fields each adapter declares:**
`game, engineFamily, meshFormats[], textureFormats[], compression[] (BC1/3/5/7, PNG), channelMap{role->file/channel}, normalConvention, colorSpace per slot, maxRes/budget per class, uvRules (reuse-template vs new), skeletonPolicy (reuse|none|forbidden), packaging (zip, pak, ytd, gma, asset pack), delivery (server-streamed | workshop-user-publishes | workshop-platform-publishes | client-manual | none), workerClass, requiredGameFiles (none|user-supplied|platform-licensed), legal{ policyUrl, commercialOk, aiOk, redistributeBase:false, monetisationRule, attestationRequired, retrievedAt }, validators[], previewShader, maturity`.

**Legal ledger rule:** every asset row carries a class: `user-original`, `ai-generated-for-user`, `platform-library` (Nxeon-owned/CC0 only), `third-party-licensed`, or `game-derived`. **Game-derived assets are never stored beyond the job, never added to any library, never redistributed**; deliverables must contain only user-original or delta content (a retexture ships the texture, not the base mesh). A per-game policy flag (from the table above, with source URL and date) gates export, commercial sharing and the community library; owner reviews each policy page when it changes.

## 4. What NOT to build yet, and the 3 cheapest decisions now
**Do not build:** a full 3D mesh editor, text-to-3D, rigging/animation, UE/Unity cooking, Palworld/Rust/Fallout/GTA-SP adapters, a Windows fleet, our own GPU cluster, a Blender/Blockbench embed, any monetisation/Tebex-style feature.

**Three cheap decisions to lock now (interfaces only):**
1. Canonical asset = glTF 2.0 + sidecar manifest with **per-channel lossless layers and provenance/legal class**; packing is export-time only.
2. The **adapter profile contract above**, especially `delivery`, `legal`, `requiredGameFiles` and `workerClass`, added to `lib/cyrus/games/support.ts` as optional fields with Minecraft filled in.
3. Job queue with a `workerClass` label and a **content-addressed object store**, so a Windows or GPU worker can plug in later without reworking the build service.

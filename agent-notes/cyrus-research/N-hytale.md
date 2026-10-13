# N: Hytale verification (read 2026-10-10)

Label key: V = VERIFIED (fetched/seen, url, 2026-10-10), V-s = seen only in a search-result snippet, U = UNVERIFIED. Official pages support.hytale.com returned HTTP 403 to fetch, so server-manual and auth-guide claims are community-sourced (V-s).

## Verdict: CONDITIONAL GO (adapter at maturity "planned"/"template", not "beta")
The earlier H-3d-games.md claims (blocky model, PNG, server streams assets, policy silent) hold up. Blockers are not technical: (a) hosting for customers needs Hytale's Game Server Provider entitlement, (b) AI-asset terms unread, (c) EA formats change weekly.

## Findings
| # | Topic | Finding | Label / source |
|---|---|---|---|
| 1 | Status | Early Access since 2026-01-13; homepage lists Update 7 pre-release (2026-09-03), Update 6 stable (2026-08-27); weekly pre-releases, stable every 2-6 weeks | V hytale.com (homepage); V-s hytale.com/news/2026/2/hytale-patch-notes-update-3 |
| 1 | Server software | Public via official `hytale-downloader` CLI (Linux x64/arm64); needs an owned game account | V-s pimylifeup.com/linux-hytale-dedicated-server, supercraft.host wiki |
| 2 | Model format | `.blockymodel` (JSON-ish, U), animation `.blockyanim`, textures PNG | V-s curseforge.com/hytale/mods/bbb; V hytalemodding.dev/en/docs/guides/plugin/creating-block |
| 2 | Pixel density | Blocks 32 px/unit; player, mobs(likely), equipment 64 px/unit; wrong density only mis-scales, no import failure | V hytalemodding.dev/es-ES/docs/established-information/server/content-categories/art-assets |
| 2 | Geometry | Only cuboids and quads (2D planes); materials fixed, artists cannot create custom materials | same page, V |
| 2 | Max texture size, node limits, anim fps, atlas rules | Not stated in docs | U |
| 2 | Tools | Official Blockbench plugin (replaced Hytale Model Maker), restricts to engine-legal elements; in-game Asset Editor for JSON data | V same page; V blog.curseforge.com/hytale-asset-editor-guide/ |
| 3 | Delivery | Installing an asset pack/mod on server: players joining get content automatically, no player install | V blog.curseforge.com/hytale-asset-editor-guide/ |
| 3 | Size limits / caching | Not documented | U |
| 4 | Plugins | Java 25+, Gradle (Maven ok), API from maven.hytale.com/release; `manifest.json` with `IncludesAssetPack: true`; jar or zip dropped in server `mods/` folder, restart | V hytalemodding.dev/en/docs/guides/plugin/setting-up-env and /creating-block; V-s docker hub READMEs (restart needed) |
| 4 | Pure asset pack | `manifest.json` + folders (Server/Item/Items, Blocks/<n>/model.blockymodel, BlockTextures/*.png) | V creating-block |
| 4 | Hot reload | Not found | U |
| 5 | Requirements | Java 25 (Temurin), UDP 5520 (QUIC, not TCP), min 4 GB RAM (8+ rec.), 4+ cores, 10-20 GB disk; layout HytaleServer.jar, Assets.zip, mods/, universe/ | V-s pimylifeup, hosthavoc.com, wiki.deinserverhost.de |
| 5 | Docker | Works; several community images wrap the downloader; expose 5520/udp | V-s hub.docker.com/r/indifferentbroccoli/hytale-server-docker |
| 5 | Server auth | OAuth2 device-code per licence; max 100 concurrent servers per licence; hosting providers apply to Hytale Support for `sessions.unlimited_servers` (Game Server Provider account; 0-click tokens, up to 500 servers per doc); sessions expire 1 h, auto-refresh | V-s xgamingserver.com guide, citadelservers KB; official page 403 so U on exact terms |
| 6 | EULA | Mods may be created, used, distributed; creator owns; Hypixel gets perpetual irrevocable sublicensable licence to Mods shown in game; **paid downloads/donations/ads allowed** if no game files included and not implied official; no NFTs/crypto; may not distribute game files/keys; interop reverse engineering preserved; operators of monetised servers may owe revenue share later | V hytale.com/eula |
| 6 | Server Operator Policies | Monetisation/cosmetics/gambling only; 0% revenue share through Jan 2028; silent on mods, AI, hosting for customers, third-party services | V hytale.com/server-policies |
| 6 | AI-generated assets | No clause found in what was fetched (fetch is summarised, not full text) | U |
| 6 | Third-party mod-creation services | Not addressed | U |
| 7 | Stability | EA, weekly pre-releases; mod UI warns when a mod targets another game version; hotfix mentions asset patching | V-s dexerto / insider-gaming patch-note results |

## DRAFT AssetProfile (reviewed:false)
| Field | Value | Source |
|---|---|---|
| game / engineFamily | "hytale" / "hytale" | V |
| meshFormats | [".blockymodel"] (cuboid+quad only) | V |
| textureFormats | ["png"]; compression ["png"] | V (png); compression U |
| channelMap | {albedo: {file:"<model>.png", channels:"rgba"}}; no normal/PBR (fixed materials) | V-s partial; U on alpha use |
| normalConvention / colorSpace | "none" / {albedo:"srgb"} | U (inferred) |
| maxTextureRes | UNKNOWN (use 256 as a conservative placeholder, flag it) | U |
| uvRules | "new" (Cyrus-generated box UVs at 32 or 64 px/unit) | density V; rest design |
| skeletonPolicy | "own" for props/blocks; "reuse" for player/mob (U) | U |
| packaging | zip/folder with manifest.json (+ optional Java plugin jar if IncludesAssetPack) | V |
| delivery | "server-streamed" | V |
| workerClass | "linux-cpu" | V (no Windows tools; Blockbench is optional, we emit files) |
| requiredGameFiles | "none" for generated props; "user-supplied" if editing base models | design; Assets.zip comes from licensed download, never redistribute |
| legal | {policyUrl:"https://hytale.com/eula", commercialOk:"unknown", aiOk:"unknown", redistributeBase:false, monetisationRule:"mods may be monetised if no game files included; server monetisation per server-policies; possible future revenue share", attestationRequired:true, retrievedAt:"2026-10-10", reviewed:false} | V excerpts; human must read |
| validators | manifest.json schema, every referenced path exists, .blockymodel only cuboids/quads, PNG, density 32/64, no Hytale base files in pack, version-target field | derived |
| previewShader | "unlit-nearest" | design |
| maturity | "planned" | verdict |

## Biggest unknowns
1. Full EULA/ToS text on AI-generated content and on a service selling mod creation (summaries only; fetch of ToS blocked).
2. Exact Game Server Provider terms (support pages 403), and whether Nxeon's customers can run servers under Nxeon's licence/entitlement.
3. Hard limits: texture size, model node count, asset-pack size, hot reload.
4. Format churn: weekly pre-releases; no stability guarantee in EA.
5. `.blockymodel` / `.blockyanim` schema not officially published in what we read; derive from a Blockbench plugin source/real files.

## Owner must decide
- Apply for the Game Server Provider (`sessions.unlimited_servers`) account before any Hytale hosting; without it, 100 servers per licence and each customer auth is awkward.
- Read the EULA/ToS personally (AI, resale of generated mods, hosting); only then flip legal.reviewed.
- Accept EA churn: ship Cyrus Hytale as "planned/beta" behind a flag, with a game-version field on every pack.
- Hosting pricing: 4-8 GB RAM, 4+ cores per server is heavier than Minecraft; no Hytale SKU exists yet.

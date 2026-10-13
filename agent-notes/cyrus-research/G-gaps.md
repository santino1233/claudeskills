# G. Cyrus code today vs. the target "mod engine" (read-only audit)

Worktree: /tank/dev-worktrees/golive (HEAD 676b01763f, 2026-10-09). Every claim cites file:line from files I read or grepped; "UNVERIFIED" marks inference. ~22 files read, no builds, no state changes.

## (a) Capability inventory (what really exists)

| Capability | Reality | Evidence |
|---|---|---|
| Real AI build pipeline, Minecraft Paper plugins only | Yes. Node service: POST /builds -> Claude CLI (Read/Write/Edit only) in throwaway workspace -> `javac` (not Gradle) vs a pre-resolved classpath -> `jar --create` -> bytecode+source scan -> artifact.jar. | services/modbuilder/server.js:4-15 (API), :511-521 (javac/jar), :789-793 (artifact), scan.js:1-9 |
| Auto-repair loop, deterministic autofix | Up to 3 repairs (`MB_MAX_REPAIRS`), mechanical autofix before model turns, escalation one model tier up after 2 | server.js:58, autofix.js (175 lines), :405 |
| Pre-check, failure rules, API sheets | 18 reviewed rules, 4 per-version sheets (~15 KB each) | precheck.js (188 lines); rules/failure-rules.json (version rules-2026-10-07.4); sheets/*.md |
| Versions | 1.21.1, 1.21.4, 1.21.8, 1.21.11 only. Hardcoded in four places | lib/modbuilder/types.ts:3, Dockerfile:11,49, lib/cyrus/games/minecraft.ts:24-28, lib/cyrus/games.ts:29 |
| Project / revisions | A "project" = a chain of `ModBuild` rows via `rootBuildId`/`baseBuildId`; project metadata lives in the root build's `cyrus` JSON; "restored head" = `headBuildId` | prisma/schema.prisma:8590-8643; lib/cyrus/meta.ts:16-33; lib/cyrus/projects.ts:43 groupProjects |
| NxLabs pages | `CyrusModPage` per rootBuildId (slug, visibility, licence, generated `doc` JSON), forks, remixes, stars, ratings, library, community-tested badge | schema.prisma:9168-9200, 9244, 9365-9430; lib/cyrus-mods/{doc,pages,tested}.ts |
| Install / uninstall / rollback | Through the shared Mods engine: `GameMod` (source "cyrus") + `ServerMod` + worker `GAME_MOD_SYNC`; state file on guest, backup, staged write, rollback | lib/modbuilder/install.ts:1-17, :122-171; lib/mods/engine.ts:27-60; lib/mods/installers/cyrus.ts; installers/minecraft.ts:455-518 |
| Conflict handling | Engine only checks file conflicts against files it does not own plus dependency ref-counting. No mod-vs-mod semantic conflicts, no mod packs | lib/mods/engine.ts:5, :281 |
| Token economy + plan tiers | reserve then settle; tiers free/katara/saka/all gate MODELS only | lib/cyrus/tokens/{builds,economy,config}.ts |
| Other games | Valheim/Terraria/Zomboid/Palworld/Rust have knowledge/validate files and template engines; all listed "soon" except Minecraft in the game registry; no compile/build service | lib/cyrus/games.ts:29-36; lib/cyrus/games/*.ts; lib/cyrus/engine/games/ |
| "Template engine" (1701 lines) | A canned code-template generator for previews of non-Minecraft games and the demo (NOT AI). Not part of the real pipeline | lib/cyrus/engine/templates.ts:1634 buildModFiles; forge.ts:1-12 ("every other game is the handoff's template preview") |
| Reference images | User pastes up to 4 images (5 MB each); written to workspace `reference/` only during AI calls, removed before compile | server.js:5, prompts.js refsBlock; lib/cyrus/uploads.ts:1-12 |
| Network/AI capability manifest for mods | `nx-capabilities.yml` checked by the service | services/modbuilder/capabilities.js:5, lib/cyrus/capabilities.ts |
| Import your own mod | **Not found**. `grep` for import/upload-jar/bring-your-own in lib/cyrus, lib/modbuilder, app/api/mod-builder returned nothing. The only inbound files are reference images and the "adopt legacy jar" path | install.ts:73-100 (adoptLegacyJars is for Nxeon's own old copies) |
| Typed project model / ModSpec / asset manifest | **Does not exist.** No type or table describes a mod's entities (mobs, items, blocks, sounds, textures). `modbuilder.json` is only a human summary (commands, permissions, config) | prompts.js:56-72 (modbuilder.json schema), lib/modbuilder/types.ts:21 |

## (b) How the model gets API knowledge

- System prompt per version is byte-stable for cache: hard rules + modbuilder.json spec + `knowledge(mcVersion)` appended (prompts.js:35-58 area). `PROMPT_VERSION = "mb-2026-10-09.1"` (prompts.js:10).
- **Sheets**: `services/modbuilder/sheets/<ver>.md`, 4 files (1.21.1, 1.21.4, 1.21.8, 1.21.11), each ~15 KB, 42 bullet facts in the 1.21.11 file; **the whole sheet for the requested version is injected on every build** (prompts.js `sheetFor`, not retrieval). Generated once by `sheets/gen-sheets.py` (hand-written template with version branches, claims "checked with javap" against the Paper jar). They are the source of truth after generation; regenerate = rerun/edit script. No sheet exists for 26.x. They cover attributes, sounds, etc.; the only texture/resource-pack related line is `setItemModel(NamespacedKey)` and datacomponent mention (sheets/1.21.11.md:61).
- **Rules**: `rules/failure-rules.json` (12 KB; 18 rules: 12 for `*`, 3 for 1.21.4-1.21.11, 1 for 1.21.1, 1 for 1.21.11, 1 for 1.21.8-1.21.11); mined with `tools/mine-rules.py`. Injected as "LESSONS FROM EARLIER FAILED BUILDS".
- Note: `GameSupport.knowledge` / `KnowledgePack` (lib/cyrus/games/support.ts:55-60) describes a retrieval design ("retrieval injects only the lines for the APIs a plan touches") but the Minecraft build service does not use it; that path belongs to Valheim/Terraria knowledge files (lib/cyrus/games/valheim.knowledge.ts). Two knowledge systems.
- Size: sheet + rules is roughly 4-5k tokens per build (UNVERIFIED estimate from 15 KB).

## (c) Where the new pieces plug in

1. **ModSpec / project model**: new typed JSON stored per project. Natural home: a new table keyed by `rootBuildId` (same convention as `CyrusModPage.rootBuildId @unique`, schema.prisma:9171) and a per-revision snapshot, not more fields in `ModBuild.cyrus` JSON (that column is already overloaded: per-build model/attachments + per-project title/listing, meta.ts:16-33). Revision identity today = `ModBuild.id`; so "revision" should reference `ModBuild.id` (one row per build/spec snapshot).
2. **Build request**: `POST /builds` body and `lib/modbuilder/create.ts:30-115` (builds the service payload; `attachmentIds` -> `images`). Add `spec` and `assets` here; service side `server.js:866` handler and `initialPrompt/changePrompt` (prompts.js:77-100) to pass the spec as a file in the workspace (e.g. `spec.json`, allowed write area is `src/main/**` + `modbuilder.json`, prompts.js rule 2).
3. **Workspace/packaging**: resources already land in the jar from `src/main/resources/**` (jar built from javac output dir, server.js:521, UNVERIFIED whether resources are copied into `out/` before `jar`; see server.js ~518 "Resources (plugin.yml, config.yml, ...)"). A resource pack must be a SEPARATE zip artifact (alongside `artifact.jar`, `jarPath` in `ModBuild`, schema.prisma `jarPath/jarSha256`). `ModBuild` has no pack columns; stored jars at `MODBUILD_DIR/<id>.jar` (lib/modbuilder/store.ts:16-17). Add `packPath/packSha1` or a generic `ModBuildArtifact` table.
4. **Install**: `lib/mods/installers/minecraft.ts` `place()` returns `PlacedFile[]` of arbitrary paths (types.ts), so the engine can already write extra files with backup/rollback; `resolveCyrus` (installers/cyrus.ts:45) returns the jar via `loadCyrusJar` (cyrus-mods/registry.ts:54). Add a second package (pack zip) there.
5. **DB**: new tables (see 1), and `GameMod`/`ServerMod` already model per-server installs (schema.prisma:3610).
6. **NxLabs generator**: `lib/cyrus-mods/doc.ts:170 buildModDoc(chain)` creates the page doc from builds; add an "assets" section sourced from the spec; `CyrusModMedia`/`ModMedia` exist for images (schema.prisma:3800, 9342).
7. **Studio UI state**: client store keeps a studio-side `Mod`/`ModVersion` model (lib/cyrus/types.ts, real.ts maps ModBuild -> Mod, real.ts:1-14); files load lazily from `/api/mod-builder/builds/:id/source`.

## (d) Can the Mods engine deliver a resource pack and set server.properties on a customer's itzg server?

- Layout: Minecraft servers are itzg/minecraft-server in a Docker container named `mc` on a customer VM; `/opt/mc` on the VM = container `/data`; env in `/root/mc.env`; run flags `-v /opt/mc:/data --env-file /root/mc.env` (worker/game-config.ts:782, installers/minecraft.ts header). Files are reached over SSH (`SshGuestFs`, lib/modbuilder/install.ts:56-61; lib/mods/guest-fs.ts).
- **Placing a pack file**: yes, mechanically (PlacedFile path under `/opt/mc`), but a Minecraft `resource-pack` setting needs an **HTTP(S) URL** and SHA-1; a local file on the server is not served (no web server in the container). So the pack zip must be hosted by Nxeon (the NX Labs mirror exists, installers/cyrus.ts doc comment; `lib/mods/mirror.ts`; UNVERIFIED that it serves arbitrary public URLs).
- **Setting server.properties**: possible. `applyMinecraft` finds `server.properties`, rewrites keys with `updateKeyValue` via SFTP (worker/game-config.ts:793-826). But **no resource-pack field exists** in the game-config schema (grep for `resource-pack|RESOURCE_PACK` returned nothing in lib/ or worker/ apart from unrelated "Resource Packs" category labels: lib/mods-browse.ts:99, installers/minecraft.ts:51-55 which actively marks resource packs "unsupported: run on players' own game"). itzg also supports env vars `RESOURCE_PACK`/`RESOURCE_PACK_SHA1`/`RESOURCE_PACK_ENFORCE` (UNVERIFIED from memory, not opened); since the container is built from `mc.env` and recreated on version change (worker/game-config.ts:880-900), env vs file precedence must be settled by testing.
- The engine has no "post-install config step" hook, no uninstall of properties (engine uninstall removes files it placed, engine.ts:442), and `restartRequired: true` (installers/minecraft.ts:~495). Needed: a typed "server settings patch" operation recorded in the state file so uninstall can revert it.
- Alternative: Paper plugin generated by Cyrus calling `Player#setResourcePack(url, sha1bytes, prompt, force)` on join (needs no server.properties change; uses the plugin path that already works). Also requires the URL to be reachable. Note the safety scan forbids networking for the plugin itself (rules/net-policy.json, prompts rule 5), but setResourcePack only hands a URL to the client (UNVERIFIED whether scan.js flags it).

## (e) What `textures/` and `sfx.ts` actually do

- `lib/cyrus/textures/*` (7 files, ~350 lines): `dsl.ts` = declarative `TextureSpec` (16/32/64 px, palette, <=400 ops: fill/px/rect/line/circle/poly/gradient/noise/shade/outline); `render.ts` = deterministic RGBA rasteriser; `png.ts` encoder; `zip.ts`; `pack.ts` `buildPack()` = 1-24 **item** textures -> `assets/<ns>/{textures/item,models/item,items}/<name>` (1.21.4+ `items/` model definitions for `setItemModel`) + pack.mcmeta + sha1. Nothing else: no mobs/blocks/entity models/animations/GUI/particles/sounds.json. **Not wired to the build pipeline or UI**: only used by the marketing demo (`components/cyrus/marketing/PixelForge.tsx:4-6`) and a unit test (`test/cyrus-textures.test.ts`). `packFormatFor` is wrong for 26.x (returns 75; see E-versions.md).
- `lib/cyrus/sfx.ts` (155 lines): **UI feedback sounds** synthesised in the browser with Web Audio (tick, ping, whoosh, stage, success, error, thump), off by default, `localStorage "cyrus-sfx"`; imported only by `lib/cyrus/fx.ts:12` and `CyrusDemo.tsx:26`. It cannot produce game sound effects and writes no files. So "Sound Studio" has no code beyond this; the owner's 514-MP3 library is not referenced anywhere in code (no grep hits needed; UNVERIFIED negative).
- Studio copy still says coming soon (`components/cyrus/marketing/StudioArt.tsx` matched the "coming soon" grep).

## (f) Plan-tier reading and where to gate asset features

- `TOKEN_TIERS = free|katara|saka|all` (lib/cyrus/tokens/config.ts:10), `PLAN_TIERS` without free (:12). Effective tier: `effectiveTier({plan, override, ...})` (tokens/economy.ts:44-59; handles active/trialing/past_due/canceled windows and admin override); loader `tierOf(userId)` (tokens/access.ts:37). Tier -> allowed models only: `TIER_MODELS` (economy.ts:15-20), `canUseModel` (:25).
- Single enforcement point for builds: `gateBuild` (tokens/builds.ts:25-50), called once from `lib/modbuilder/create.ts:72`. It is only active when `tokensActiveFor` (live flag or preview list, access.ts:18-27); otherwise builds pass through untracked.
- Gate asset features there: extend `gateBuild`'s input with requested asset features and return a new `code` (e.g. `asset_locked`), and read the tier via `tierOf` for UI (`buildTokenState`, tokens/state.ts:13-26). Model names (katara/saka/yakko) double as tier names in the UI and in `engine/kit.ts:365 MODEL_NAME`; do not conflate with feature tiers. No feature-flag table keyed by tier exists (UNVERIFIED beyond grep of tierOf/canUseModel usage).
- Note: NxLabs publication has its own gate (lib/cyrus/public-gate.ts, lib/cyrus-mods/gate.ts); asset licensing checks (owner's SFX licence) should go there.

## (g) Ranked missing pieces / debt that will hurt scaling

1. **No project/spec/asset data model** and `ModBuild.cyrus` JSON overloaded; revisions are build rows with no diff/rollback of assets (schema.prisma:8590; meta.ts). Blocks everything below.
2. **Version support is hardcoded in 4+ places** and tied to JDK 21/`--release 21`/Gradle template toolchain 21 (types.ts:3, Dockerfile:11,49, server.js:513, template/build.gradle.kts:21-25). 26.x cannot be added without a registry + JDK 25 (E-versions.md).
3. **Knowledge = whole-sheet injection per version, hand-generated, no 26.x**; two incompatible knowledge systems (`KnowledgePack` retrieval vs services sheets). Sheets will not scale to creatures/models/GUI/particles/datapack APIs; token cost per build rises with every addition.
4. **Asset pipeline missing end-to-end**: textures only items, unwired; no model/entity/animation/sound generation; no sounds.json; sfx.ts is UI-only; pack format table wrong for 26.x.
5. **Delivery path for client assets missing**: no resource-pack URL hosting, no `resource-pack`/sha1 config field, no pack artifact in `ModBuild`, engine has no settings-patch step; installer marks resource packs unsupported (installers/minecraft.ts:55).
6. **Plugin-only ceiling**: Paper-plugin sandbox (no reflection/NMS/networking rules) cannot express custom mobs with custom models, blocks, dimensions without datapacks/resource packs; datapack placement exists in the installer (installers/minecraft.ts:455-465) but the generator never produces datapacks (UNVERIFIED but no code does).
7. **No mod-vs-mod conflict engine or mod packs**: engine handles file ownership only (engine.ts:281); no pack/bundle entity.
8. **No import-your-own-mod flow** (no code, no scanner path for foreign jars; scan.js works on freshly compiled bytecode in the workspace).
9. **Eval coverage thin**: 30 prompts (13 runtime-loaded) on 1.21.x only; rtcheck uses `eclipse-temurin:21-jre`, mineflayer bot, per-version Paper jars on the build VM (eval/rtcheck.py:1-15); no assets, no multi-version matrix, ops live on a single VM (`/root/...` paths, run_eval.py reads `/root/modbuilder.env`).
10. **Simulated template engine (1701 lines) alongside the real path** — risk of divergence and confusion for non-Minecraft games (lib/cyrus/engine/templates.ts).
11. **Single build VM**: concurrency 2, 20 min timeout, `/data` on one host (server.js:44-60); no queue/scale-out story (UNVERIFIED beyond defaults).
12. **Tier model conflation**: plans gate models, not features; `gateBuild` only tracks when economy is live.

## Could not determine
Whether `jar` includes `src/main/resources/**` via an explicit copy (read only lines ~511-521, ~518 comment); the NX Labs mirror's ability to host public pack URLs; whether scan.js flags `setResourcePack`; itzg env/file precedence; any use of the 514-MP3 library in code (not searched beyond the Cyrus dirs).

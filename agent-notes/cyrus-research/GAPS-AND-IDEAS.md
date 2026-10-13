# Cyrus: gaps, contradictions, resources and new ideas (red team + opportunity scout)

Date 2026-10-10. Read-only. Inputs: BRIEF, RESEARCH-PLAN, E/G/A/A2/B/C/D/F files, Master Update Plan, games-programme prompt, architecture doc; plus about 40 pages/APIs opened today. Labels: VERIFIED Sn = I opened source Sn (list at the end); UNVERIFIED = memory, inference or search snippet. "Internal" = I read the code in /tank/dev-worktrees/golive (read-only).

## (A) Top 15 findings, ranked by how much they change the plan

| # | Finding | Why it matters | Change |
|---|---|---|---|
| 1 | **The build service may be serving customers through a Claude subscription login.** Internal: `server.js:26` ("CLAUDE_CODE_OAUTH_TOKEN (owner subscription, testing)"), `entrypoint.sh` accepts a login file, and the architecture doc says the service runs on "a single Claude login session file". Anthropic: third parties may not "route requests through Free, Pro, or Max plan credentials on behalf of their users", and plan limits "assume ordinary, individual usage" (VERIFIED S3). | A launch-blocking terms problem and a hidden capacity cap (the weekly 99% usage you already hit). Unit economics are also computed on the wrong cost basis. | Day 1, before anything: read `/health` field `auth` on the VM (`api_key` vs `subscription`). If subscription: move to an API key under Commercial Terms, re-measure cost per build, re-price tokens. Never go public on a login file. |
| 2 | **Mojang's EULA says mods are yours "as long as you don't sell them for money / try to make money from them"** (VERIFIED S1). Usage Guidelines: charging for a server is fine only if everyone gets the same access to all enabled mods; no gambling or mature content; no play-to-earn; no mod that checks out-of-game ownership (NFT example) (VERIFIED S2). | A "creator marketplace / revenue share on mods" is the one idea here that directly contradicts the EULA text. Cyrus can sell compute, hosting and tooling, not mods. Also needs prompt-level policy (see E-9). | Drop marketplace/rev-share. Add policy classes to prompt-check: gambling/crates for real money, pay-to-win, play-to-earn, ownership-gated content, NFTs. Get counsel to confirm "token fee for generation" is not "selling a mod". |
| 3 | **Modrinth bans fully/primarily AI-generated uploads and requires an AI disclosure (effective 2026-08-13)** (VERIFIED S4). `.mrpack` has no Paper/Bukkit dependency ID (only minecraft, forge, neoforge, fabric-loader, quilt-loader) (VERIFIED S5). | Cyrus mods cannot be distributed to Modrinth; "export to .mrpack" is the wrong target for plugin Mod Packs. NxLabs is the channel; every other platform's AI policy is unchecked (Hangar/Spigot: UNVERIFIED). | Define an own manifest (`nxpack.json`) shaped like mrpack (files[] with path/sha1/sha512/downloads/env, overrides dirs) but with platform=paper. Add an "AI-made" disclosure everywhere Cyrus exports (honesty, and matches the direction of the ecosystem). |
| 4 | **The 16-day order contains dependency inversions** (detail in B): version registry (Day 13) is needed by Days 1-3; Test Flight (Day 12) is needed by Day 7 and Day 8 acceptance; Server Context (Day 14) is needed by the conflict engine (Day 8); a managed-plugin mechanism and a dependency allowlist appear nowhere. | Days 3-8 cannot meet their own "done when" as written. | Re-sequence (section G). Test Flight lite, version registry and pack loader move to the first block. |
| 5 | **A server can have only ONE pack via server.properties** (resource-pack, -id, -sha1, -prompt, require- keys; VERIFIED S9), but Paper has `Player#addResourcePack(UUID, url, hash, prompt, force)` and `removeResourcePack(UUID)`; `setResourcePack` is deprecated (VERIFIED S8). G-gaps and B-models propose `setResourcePack`. | Multi-pack needs no merging in the common case if Nxeon ships one managed "Pack Loader" plugin that sends N packs by UUID. Resource packs stack bottom-to-top, with higher packs replacing or merging (VERIFIED S10). Many customer servers will already run a pack manager (ResourcePackManager, Oraxen, Nexo; VERIFIED S19). | Build the Pack Loader (E-2). Use `server.properties` only as fallback. Conflict engine must detect an existing pack owner on the server. |
| 6 | **BetterModel is two products.** v3 (default branch, release 3.5.0 on 2026-09-20): Minecraft 1.21.4~26.3.x, **Java 25**. v2 branch: 1.21~1.21.11, Java 21, last commit 2026-03-31 (VERIFIED S11; MIT, S13). This resolves the A/B/E contradiction. | Customer 1.21.x servers run Java 21 images (internal `game-config.ts:190`). The banshee on 1.21.x means depending on a v2 line that is already stale. BetterModel also generates its own pack (third pack producer). | Banshee is a 26.x feature first. On 1.21.x: skin + sounds on a vanilla mob only. Treat BetterModel as a pinned managed plugin per version family. |
| 7 | **Import-your-own-mod is much harder than one day.** Internal `server.js:513`: compile is plain `javac --release 21 -proc:none` against a Paper-only classpath. Real plugins need Vault/PlaceholderAPI/Kotlin/Lombok/shaded libs; build scripts must not run; the policy scanner bans reflection/network that many legitimate plugins use (update checkers, bStats). | As specified, most real uploads will fail at compile or scan. Acceptance "uploaded plugin source is edited, rebuilt, scanned, installed" holds only for simple plugins. | Curated, checksum-pinned dependency allowlist (also the basis for first-class integrations, C). Separate "attested/imported" scan profile with warnings vs the strict "generated" profile. Day 9 becomes L, source-only. |
| 8 | **26.x is cheaper than E-versions' "L" if you stay on javac.** Compile is `javac` + classpath file (internal); Gradle only builds the classpath files. But Paper's newest 26.3 build on Fill is **BETA (build 169, 2026-10-09)** and the Maven repo lists `26.3.build.N-beta` (VERIFIED S17), so floating `26.3.build.+` is unsafe, and E's "26.3 stable build 25" must be re-checked before pinning. | Faster 26.x lane; avoid shipping against betas. | JDK 25 beside 21, per-version `--release`, classpath files fetched by checksum from the Paper repo, pin exact stable. Nightly Fill check creates a "preview" row. |
| 9 | **Reproducibility claim is false today.** Internal: `jar --create` without `--date`; the pack zip writer IS deterministic (fixed timestamps, `zip.ts`). | The plan's provenance, caching and "same hash passed validation" rules need byte-stable jars. | Add `jar --date`/fixed mtimes, sorted inputs; record toolchain digest. Gradle 9 makes archives reproducible by default (VERIFIED S23) but you do not use Gradle for packaging. |
| 10 | **Plan-tier gating has holes.** Create vs keep vs consume is undefined: a Katara user installs a Mod Pack (ungated) containing textures a top-plan user made; imports a mod with assets; remixes an NxLabs mod. `gateBuild` only runs when tokens are live (G-gaps). Day 5 (creature) needs textures AND sounds, so it is top-plan only. Token reserve keys (katara/saka/yakko) differ from plan keys (katara/saka/all). | Either a broken-looking free experience or a bypass. | Rule: gates apply to **generating or editing** assets; **installing, keeping, rebuilding unchanged, and exporting** assets in an existing project is never gated. Router downgrades (no asset) instead of erroring. Server-side check inside the build service request, fail closed when tokens are off. |
| 11 | **Paper plugin (paper-plugin.yml) is still marked "Experimental... may be subject to change"; it has classloading isolation, split load order and different command handling, "not a drop-in"** (VERIFIED S14). Datapack discovery and `RegistryEvents` need a bootstrapper (A2). Generated mods use plugin.yml. | If every generated mod became a paper-plugin, you inherit instability and the conflict engine must model two descriptor formats. | Keep generated mods on plugin.yml. Ship datapacks as world/`datapacks` files or via the single Nxeon-owned managed loader (which may use paper-plugin.yml). |
| 12 | **Licences are tighter than the research tables suggest.** `paper-api` is GPL-3.0 (VERIFIED S12). Citizens: Open Software License 3.0 (VERIFIED S13). Also GPL: FreeMinecraftModels, CraftEngine, ViaVersion, Folia, Rainbow, PlaceholderAPI, EssentialsX; AGPL: PackSquash (S13/S25). `misode/mcmeta` declares no licence (S13), so A2 cannot treat it as usable data. | Distribution of generated jars and any bundled helper must be reviewed; "avoid bundling" must be enforced by a list. | Counsel review of "plugin compiled against GPL paper-api, distributed on NxLabs" (industry practice treats plugins as separate works; UNVERIFIED legally). NxLabs licence picker must not offer options that contradict this. |
| 13 | **Prior art exists for pack merging; do not hand-write all of it.** Beet (MIT, Python pipeline; S26) and Weld (MIT, "built on beet", S27) merge packs; ResourcePackManager documents per-format strategies and its unfixable classes (GUI unicode spacing, duplicate item model IDs, shaders) (S19). | Saves most of Day 8's pack-merge work and gives a conflict taxonomy. | Run Weld/Beet as an offline subprocess on the build VM behind your own golden tests; implement only detection + policy yourself. Whether Weld handles 26.x format fields: UNVERIFIED. |
| 14 | **Bedrock: Geyser does not convert Java packs or auto-generate custom-item mappings; a Bedrock pack is mandatory** (VERIFIED S18). Geyser is MIT, Floodgate MIT, Rainbow (converter) GPL-3.0 (S13). | The "Bedrock honesty" label is correct and cheap; a conversion feature is a separate L project. | Detect Geyser/Floodgate, label NxLabs pages; defer conversion. |
| 15 | **Asset legal limits.** "Assets" in Mojang's guidelines include textures, models, sounds and audio from the games (VERIFIED S2); US Copyright Office: prompts alone do not give human authorship, so pure AI output is not copyrightable (VERIFIED S24). The owner's 514 SFX will be extractable from every pack a player downloads. | The "vanilla-style" presets must be original, the NxLabs licence picker says less than it appears to, and the sound licence must explicitly allow redistribution inside packs. | Perceptual-hash lookalike check against vanilla (on the build host only); licence text drafted for pack redistribution; "licence to the extent of rights" wording; process (trim/pitch/layer) rather than ship raw library files. |

## (B) Contradictions and holes, with fixes

| # | Issue | Fix |
|---|---|---|
| B1 | Master Plan/architecture say "Gradle compile"; code is `javac` (internal `server.js:513`). CYR-004 "immutable Gradle toolchain" and E's Gradle 8.14 vs Java 25 question are largely moot for the AI path. | Rename CYR-004 to "immutable javac/classpath/template"; Gradle only at image build for classpath files. |
| B2 | G-gaps: "unverified whether resources are copied into the jar". Internal: `copyDir(src/main/resources, out)` then `jar` (resolved). | Close the question. |
| B4 | `packFormatFor` returns 75 for 26.x and pack.mcmeta mixes `pack_format`, `supported_formats`, `min_format: 46`, `max_format: 999` (internal `pack.ts:26`). 26.2 resource format is unknown (E). Wiki tables are ranges in C and exact numbers in E. | Registry holds exact major.minor per version; emit one mcmeta style per version family; test on real 26.1/26.3 clients (T). Do not rely on 999 ceilings. |
| B5 | Dialog API: A-content says 1.21.6+ (UNVERIFIED). Paper's API needs **1.21.7+** (VERIFIED S15). Not on 1.21.1/1.21.4. | Capability flag `dialogApi` in the version registry; fall back to chest GUI. |
| B6 | Day 7 acceptance ("datapack loads on every version") and Day 8 ("combined smoke tests") need the disposable-server harness, which is Day 12. | Move Test Flight lite (boot, RCON, `datapack list`, log matcher) to Day 3. |
| B7 | Day 8 conflict engine needs the list of plugins/packs already on the customer server; Server Context is Day 14. | Build a read-only **server inventory** (jars' descriptors, server.properties, datapacks, existing pack owners) first; it is the conflict engine's input. |
| B8 | Day 3 pack format numbers and Day 2 registries need the version registry (Day 13). | Version registry is Day 1-2 work (E already designs it). |
| B9 | Day 5 needs BetterModel as a "managed system plugin"; the Mods engine has no such concept (G-gaps: resource packs "unsupported" in installer; no settings-patch step). | Add `ManagedPlugin` records (pinned version per MC family, auto-install on first dependent mod, ref-counted, never user-removable while depended on). Same mechanism hosts the Pack Loader. |
| B10 | Day 8 "dynamic: combined smoke test" for Mod Packs is O(n) boots at best, O(n^2) for pairwise. | One combined boot + one differential boot per changed mod; pairwise only for statically flagged pairs. |
| B11 | Day 9 "no script execution at ingestion" vs "build with Cyrus": building imported Gradle/Maven projects runs arbitrary code. | Never run the uploader's build; copy `src/main/java|resources`, drop build files, compile with the service template. Dependencies via allowlist or "unsupported: X". |
| B12 | Texture DSL limit is 400 ops and 16/32/64 px (G-gaps); creature skins and 128px atlases need more (B-models). | Add region/UV-aware ops or raise the limit per asset class; keep op limits as a cost guard. |
| B13 | Day 6 packs "pixel tools, layers/undo, waveform, AI candidates, revisions, library, quality gallery" into one day; C and D size the editor alone at L and studio v1 at M-L each. | See G: stopgap editor, real editor on demand. |
| B14 | Mod Packs "not gated" but their assets follow gates; imports "not gated" but assets "follow asset gates" (RESEARCH-PLAN). | Adopt the create/edit-vs-keep rule in A-10 and write it as a test matrix (4 plans x create/edit/keep/install). |
| B15 | Sound licence: BRIEF calls the 514 files "original", D records the owner will write a customer licence, memory says the concern was withdrawn. | Require written provenance for the 514 (source per file group); the licence must permit redistribution in hosted packs. Without it the ledger value "owner-original" is an assertion. |
| B17 | `gateBuild` is bypassed when the economy is off; asset ops could run for free in preview. | Asset gate defaults to deny when token state is unknown. |

## (C) Extra resources, APIs and libraries

| Resource | Licence | Status | Recommended use |
|---|---|---|---|
| Modrinth API v2 (`/tag/loader`, `/project/{id}/version`, hash lookup) | API terms: UNVERIFIED; unique User-Agent mandatory, 300 req/min/IP (VERIFIED S6/S29) | Loaders include paper, spigot, bukkit, folia, purpur, velocity (VERIFIED S6). Version objects expose `loaders`, `game_versions`, `dependencies`, `files[].hashes{sha1,sha512}` (VERIFIED S6) | Dependency/version metadata for Mod Packs and import dependency lookup. Read only; never re-host. |
| Hangar API v1 (public, no key for reads) | Per-project licence field; AI policy UNVERIFIED | Versions expose platform downloads, `sha256Hash`, `downloadUrl`, channel, review state (VERIFIED S7) | Resolve third-party plugin jars by reference and verify sha256. |
| `.mrpack` format | Open spec | VERIFIED S5: files[] (path, hashes sha1+sha512, `downloads` HTTPS, `env`, fileSize), `overrides/`, `server-overrides`, `client-overrides`; Modrinth restricts upload hosts | Copy the shape, not the dependency IDs. Reference third-party jars by URL+hash; embed only Cyrus-built artifacts (avoids redistributing others' licences and the CurseForge-style distribution flag problem). |
| Beet / Weld (Smithed) | MIT / MIT (S26/S27, S13) | Weld "built on beet"; merge rules per file not documented in what I read | Evaluate for pack/datapack merge behind golden tests (Python subprocess on build VM). |
| PackSquash | **AGPL-3.0** (S25) | Optimiser; does not validate sounds.json | Avoid in a proprietary service or run only as a customer-facing downloadable tool. Own zip writer already deterministic. |
| Spyglass / vanilla-mcdoc | MIT / MIT (S13) | Active Oct 2026 | Datapack validation source (resolves A2's unverified Spyglass licence). |
| Geyser, Floodgate | MIT, MIT (S13) | Rainbow converter GPL-3.0 | Detect only; do not bundle Rainbow. |
| Paper Dialog API | part of Paper | Needs 1.21.7+; notice/confirm/multi-action/list/server-links dialogs; inputs: checkbox, dropdown, text, slider; callbacks via `PlayerCustomClickEvent` (VERIFIED S15) | Auto-generated in-game config screens (E-7). |
| Folia | GPL-3.0 (S13) | Needs `folia-supported: true` and region/entity schedulers (VERIFIED S16) | Generated mods: use only schedulers that work on Paper and Folia, set the flag; conflict class "not Folia-safe". |
| Vault / VaultUnlocked | LGPL-3.0 / LGPL-3.0 (S13) | Vault last push 2024-03; VaultUnlocked 2026-09 | `compileOnly` from a pinned jar; economy/permission provider is a **single-owner resource** in the conflict model. |
| PlaceholderAPI | GPL-3.0 | active | Soft integration only via Nxeon-owned bridge class; do not shade. |
| LuckPerms | MIT | active | First-class: permission-node registry and group templates (freemc already uses it). |
| Citizens | **OSL-3.0** (S13) | active | Avoid linking; model as "NPC owner" in conflicts. FancyNpcs: old repo MIT but archived, new repo not found by API: UNVERIFIED. |
| BetterModel | MIT (S13) | v3 Java 25 / v2 Java 21 (S11) | Managed plugin, 26.x first (A-6). |
| MockBukkit, Mineflayer | MIT, MIT (S13) | active | Test Flight (already planned). |
| Vineflower / CFR | Apache-2.0 / MIT (S13) | active 2026 | Analysis-only decompile of attested jars, never into shared knowledge. |
| MCAntiMalware / jNeedle / PluginScan | GPL-3.0 / MIT (last push 2024-04) / GPL-3.0 (2022) (S13) | signature scanners | Optional second opinion run as separate processes; jNeedle stale; none replaces scan.js. |
| YARA / ClamAV | BSD-3 / GPL-2.0 (S13) | active | YARA rules for known Minecraft malware families; ClamAV as separate daemon. |
| CycloneDX Gradle plugin, Syft, Cosign | Apache-2.0 (S13) | active | SBOM from classpath manifest (Syft on the jar), signed attestation (Cosign) for provenance. |
| fast-check | MIT (S13) | active | Property-based tests (D). |
| three.js / Babylon.js | MIT / Apache-2.0 (S13) | active | 3D item/model preview. |
| Cloudflare R2 | commercial | "No charges for egress bandwidth" (VERIFIED S20) | Pack hosting; serve from `packs.<nxeon domain>` so no provider is named to customers. |

## (D) Improvements to existing plan items

**Engine quality**
- IR: JSON Schema (portable contract) + Zod types, `schemaVersion` plus explicit migrations (the DataFixer idea), content-addressed registries. Cache key = hash(spec, registry version, generator version, toolchain digest, asset hashes); AI-authored steps are stored outputs, not re-run on replay (UNVERIFIED analogy to Unity/Godot importers; standard practice).
- Build record per artifact: engine release id (prompt version + sheets + rules + scanner hash + image digest), source hash, classpath hash, output hash, SBOM, scan report; SLSA Build L1 now ("provenance exists") and L2 with a signed attestation from the build service (levels VERIFIED S21).
- Testing: property-based (fast-check) for merge laws (idempotent, order-stable, no key loss), golden pack snapshots (canonical JSON + sorted file list + sha1), javap-verified sheets in CI, contract test of the version registry against the Fill API and the pack-format wiki, mutation corpus for conflicts (take a good mod, rename ids to collide).

**Conflict engine: classes beyond the Day-8 list**

| Class | Detection |
|---|---|
| Single-owner resources: Vault economy/permission provider, chat renderer, tab list, sidebar, join/quit messages, world border/time/weather/gamerules, GUI title glyphs, spawn handling | Bytecode registration scan + known-API table (extend `scan.js` constant-pool parse) |
| Legacy `custom_model_data` integer collisions (1.21.1) and `item_model` keys | Global allocator + registry; static scan of data components |
| Event semantics: two plugins mutate/cancel the same event at the same priority; MONITOR misuse | Register-call extraction (event class + priority); report as warn |
| Brigadier root literal and alias collisions, overrides of vanilla commands, permission default clashes | Descriptor + bytecode scan |
| Datapack: `replace:true` tags, same `minecraft:` loot/recipe id overridden twice, load/tick function tag order, enchantment/biome id collisions | JSON path index across packs |
| Resource: whole-file overrides (models, blockstates, items, shaders, pack.mcmeta), font provider codepoint overlap (PUA), unmergeable shaders, sound-event `replace:true` of vanilla events (affects all mobs), atlas sources | Path index + format-aware merge; ResourcePackManager documents shader/GUI-spacing/duplicate-model-id as unfixable (S19) |
| Budget classes: display-entity count, ticking tasks, pack size, entity cap | Spec-declared budgets summed per server |
| Platform: missing `folia-supported`, api-version/Java mismatch, mod needs 1.21.4+ item_model but server is 1.21.1 | Registry capability flags |
| Policy: Mod Pack containing a server jar ("Modded Version" distribution is forbidden, S1) | Pack validator: no vanilla/Paper binaries ever |

Resolution that is cheap and robust: **reserve a namespace per project at creation** (`nx_<short hash>`) so ids, keys, permissions, sound keys, glyph ranges and model paths are collision-free by construction; keep regeneration-with-prefix only for imports. Version resolution: plugin `depend/softdepend/loadbefore` is a DAG plus platform/Java ranges; a small custom resolver is enough (PubGrub-style solvers are overkill; UNVERIFIED).

**Import: safe ingestion**
Zip-slip and zip-bomb ratio limits, nested jar limit, multi-release and class-major checks, strip signatures, no execution; detect build system by `settings.gradle(.kts)`, `pom.xml`, `plugin.yml`/`paper-plugin.yml` location, then ignore the build files; Kotlin/Lombok/annotation processors are unsupported because `-proc:none`. Attestation record: typed name, checkbox text version, timestamp, upload hash, licence detected (SPDX scan) and licence claimed; public sharing requires consent plus a licence compatible with redistribution; jar-only imports are analysis-only. Takedown: published page with contact, strike policy, kill switch that unpublishes a page and flags installs (US designated-agent registration: UNVERIFIED, ask counsel).

**Premium studio features** (beyond the plan): 3D preview (three.js) for item display transforms and server-rendered turntables; tile preview and onion skin for animated textures; pixel palette ramps with contrast and colour-blind checks; waveform with spectrum, LUFS and true-peak readouts; per-mod **Style DNA** (palette ramps, outline rule, noise, sound mood) applied to every asset for consistency; reference-image-to-spec through a vision model that proposes palette and silhouette (not image generation); asset history with visual/waveform diffs; library search by tag first, embeddings later in the existing Postgres; mandatory subtitle keys for custom sounds (accessibility and `sounds.json` already supports `subtitle`); mobile-friendly read-only preview and approve flow (editing stays desktop).

**Quality bar:** replace "owner approves 20 samples" with a rubric plus metrics: texture (palette size, contrast ratio, edge density, banding, transparent-pixel policy), sound (mono, true peak, LUFS band per event role, silence ratio, DC offset), plus a vision-model judge calibrated against 100 owner-labelled samples, tracked per release.

**Operations**
- Test servers: 1-1.5 GB each, 20-45 s boot (UNVERIFIED, from F); cap concurrency (node-1 hard-crashed from parallel builds, memory) and reuse a warm image; run on node-2.
- Pack bandwidth: R2 egress is free (VERIFIED S20); use content-addressed immutable URLs `/p/<sha1>.zip`, `Cache-Control: immutable`, retention GC; record accept/decline via `PlayerResourcePackStatusEvent` from the Pack Loader.
- Pipeline incident/rollback: treat prompt+sheets+rules+scanner+image as one **engine release**, canary at 5%, auto-rollback on eval regression, per-feature kill switches (asset generation, import, packs).
- Model/provider risk: the whole pipeline is the Claude Code CLI (A-1 applies); add a thin provider interface for the planning step only; log cost per stage.
- Prompt injection (OWASP LLM01 indirect injection; VERIFIED S22): imported README/comments/docs enter the model only as quoted data files; the model keeps Read/Write/Edit with no network; reject diffs touching paths outside the allow-list; every output still passes compile + scan; never feed imported content into shared memory.
- Supply chain: pinned jars with sha256 (Fill API gives hashes; UNVERIFIED for plugins beyond Hangar sha256 field S7), image digests, lockfiles for studio npm deps, Mojang data-generator output kept on the build host only.

**Future games (short):** add `game` to every id and registry; ModSpec has `artifactKinds` per adapter; assets have a `kind` registry (pixel texture, mesh, audio clip, config); delivery strategy is an adapter method (server-pushed pack / client zip / none). Realistic 3D profile: glTF 2.0 mesh + PBR maps, per-game budgets and exporters (Unity asset bundles for Valheim/Rust, UNVERIFIED), 2D sprite sheets for tModLoader and Zomboid (UNVERIFIED). Build none of this now beyond the interfaces.

## (E) New feature ideas, ranked by value/effort

| # | Idea | Value | Effort | Depends on | Risk | Competitors? |
|---|---|---|---|---|---|---|
| 1 | Per-project namespace reservation + global identifier registry | High (kills most conflicts) | S | project model | low | No |
| 2 | **Nxeon Pack Loader** managed plugin: N packs by UUID, config-phase delivery, per-pack required/optional, accept-rate telemetry, Bedrock detect | High | M | managed-plugin mechanism, pack hosting | Paper API churn | No |
| 3 | **Server Doctor**: read-only scan of a customer's whole server (all jars, datapacks, pack owners) with a conflict report; works on servers with no Cyrus mods | High (acquisition) | M | server inventory | scanning many 3rd-party jars | No |
| 4 | **Evidence badges + public pass-rate page** (boot-tested on exact version, scan hash, SBOM) | High (trust, SEO) | S-M | Test Flight lite, build record | claim must stay true | Only Player Games claims a pass rate (F) |
| 5 | Signed provenance + SBOM per artifact | Med | S-M | reproducible jar | low | No |
| 6 | **Style DNA** per mod | High (visible quality) | S-M | texture/sound slices | taste | No |
| 7 | Auto-generated **Dialog config screen** for every mod (1.21.7+) | Med-High (polish, no art) | S-M | version registry | API limit | No |
| 8 | Mandatory subtitles/captions for custom sounds | Med (a11y) | S | sound slice | low | No |
| 9 | Policy classifier for gambling/pay-to-win/play-to-earn/NFT prompts | High (EULA) | S | prompt-check | false positives | No |
| 10 | Lookalike/dup checks (perceptual hash vs vanilla and vs NxLabs, audio fingerprint vs library) | High (legal) | M | build-host vanilla assets | storage | No |
| 11 | Playtest scripts from spec acceptance criteria (Mineflayer) | Med-High | M | Test Flight, ModSpec | flaky bots | Partly |
| 12 | "Try it" throwaway server link (10 min) | High (conversion) | M-L | Test Flight, abuse limits | abuse, cost | Orca has a bundled server (F) |
| 13 | Multi-version build from one ModSpec (1.21.11 + 26.x) | Med-High | S after registry | registry | version drift | No |
| 15 | Mod Health telemetry opt-in (own timers, errors) feeding the community badge | Med | M | Pack Loader style managed plugin | privacy | No |
| 16 | Reference-image-to-spec | Med-High | M | texture slice | quality unproven | Partly |
| 20 | Free-Minecraft-tier funnel: one-click Cyrus mod on a free server | High (growth) | S-M | install engine | free-tier abuse | N/A |

Growth/GTM: programmatic NxLabs pages per version and mod type with evidence badges (ChatGPT is the top channel, memory); "made with Cyrus" credit in each plugin's help output (opt-out on paid); templates gallery that doubles as eval fixtures; creator partner program reused for Cyrus authors. Funnel events: prompt -> spec -> build -> pass -> install -> pack accepted -> player joined -> retained day 7; plus gate impressions and upgrade conversion. Pricing: show an estimate before building; price assets by measured work (spec + critique rounds + encode), not flat; no charge when validation fails before delivery; free tier gets no assets and per-device/IP caps (starter grant already once per verified account). Moderation: vision classification of textures at publish time, uploads scanned, uploaded audio only after attestation, takedown page and strike log.

## (F) Risks and legal

| Risk | Evidence | Mitigation |
|---|---|---|
| Subscription login serving customers | A-1 | Fix before launch; verify `auth` field |
| EULA "don't sell mods" and Usage Guidelines (all-ages, no gambling, no p2e) | S1, S2 | No marketplace; policy classifier; counsel review of token pricing wording |
| Mojang "Modded Version" and assets | S1/S2 | Mod Packs never contain Paper/vanilla jars; lookalike checks |
| GPL paper-api linkage for distributed jars | S12 | Counsel; document position; licence picker |
| Platform AI policies (Modrinth bans primarily-AI uploads) | S4 | NxLabs only; disclosure labels; check Hangar/Spigot rules before any cross-posting (UNVERIFIED) |
| Copyrightability of AI output | S24 | Licence wording "to the extent of rights"; encourage human edits (studio edits strengthen authorship) |
| Third-party plugin redistribution inside Mod Packs | S5 pattern | Manifest by reference + hash |
| Experimental Paper features (paper-plugin.yml, data-component API) | S14, A-content | Isolate in one Nxeon-owned loader; registry capability flags; monthly CI |
| Beta builds pulled by floating coordinates | S17 | Pin exact stable |
| Scanner false sense of safety for imports | internal | Attested profile with explicit warnings, no "safe" claim |
| Pack tampering/abuse of public URLs | | Content-addressed names, no directory listing, size caps |
| Real-client tests cannot be automated | F | Human gate per asset day (T), small matrix |
| Usage/cost blowout from asset critique loops | F | Cap rounds (2), cache by spec hash |

## (G) Cut list, must-keep, and a realistic schedule

**Arithmetic on the research files' own sizing (UNVERIFIED, my sum):** texture MVP about 4 weeks (editor alone L), sound about 3-4, models about 6, data packs about 5, conflict engine + Mod Packs and import each L, designers L each. Days 3-11 as written equal roughly 25-35 engineer-weeks. Even with agents, the real limiters are the owner-only steps, (T) real-client tests, usage allowance and node capacity. **Sixteen days is not credible for the full list; it is credible for the foundation plus one asset slice.**

**Must keep (in this order)**
1. Auth/ToS fix; launch gates (scan live, flag guard, per-build record, abuse limit, cost cap).
2. Version registry (exact pack formats, JDK, classpath, capabilities) + 26.x lane on javac; reproducible jar.
3. ModSpec/project model + revision store + identifier registry with reserved namespaces + GameAdapter interface.
4. Pack hosting + Pack Loader + managed-plugin mechanism + Test Flight lite (boot, RCON, datapack/pack checks).
5. Texture slice (items, the Glock) and sound slice (library tags, server-side Ogg, `sounds.json`, subtitles), with server-side gates and the access test matrix.
6. Server inventory + static conflict engine + Mod Pack manifest installed/rolled back as one unit (reference third-party jars by hash).
7. Import: source-only with allowlist, attestation, strict vs attested scan.
8. Datapack MVP: recipes, loot, advancements, tags, functions, enchantments with per-version emitters and the boot check.
9. Eval harness extension (100+ prompts, per-version matrix, asset prompts) with a public pass-rate page.

**Cut or defer**
- Full creature pipeline (Day 5): defer to after 26.x lane is stable; ship "skin + full sound set on a vanilla mob" and static item models now.
- Gameplay Designers 1 and 2 (ability graph, quest/boss/GUI builders): each is a mini-language; defer. Keep only "edit parameters of a generated mod".
- Biomes/structures/worldgen (Data Pack Studio phase 2): defer.
- Full pixel/sound editors: ship an iframe or minimal editor stopgap (miniPaint MIT per C) and wavesurfer trim/fade; build the real editor on demand.
- Namespace-regeneration resolution for arbitrary imports; dynamic pairwise combined scenario tests; AI image/audio providers; Bedrock conversion; marketplace; Day 14 extras (screenshot-to-mod, structure generator, simulation); Day 15 other games (own programme); Day 16 Fabric; 1.21.1/1.21.4 retirement decision by usage data; core-shader HUDs (A already says avoid).

**Suggested sequence:** R0 foundation (about Days 1-4 of work) -> R1 asset slice (about Days 5-9) -> R2 composition + datapacks + import (about Days 10-16). Realistic calendar for R0-R2 including owner waits: 5-7 weeks (UNVERIFIED judgement).

## (H) Open questions for the owner

1. Which credential does the production build service actually use today (API key or subscription), and what is the contract with Anthropic for customer-facing use?
2. Do you accept dropping the creator marketplace/revenue-share on mods, given the EULA wording, in favour of selling generation, hosting and tooling?
3. Will counsel review (a) token fees vs "selling mods", (b) GPL paper-api linkage, (c) the AI disclosure wording, (d) the sound-pack redistribution licence?
4. Can you provide written provenance for the 514 sound files?
5. Is Banshee on 1.21.x acceptable as "skin + sounds only", with BetterModel creatures on 26.x only (Java 25)?
6. Gate semantics: confirm that installing/keeping existing assets is never gated and only creating/editing is.
7. Who is the standing human for (T) real-client tests, and on which days?
8. Are you willing to approve R2-first scheduling (Pack Loader, Test Flight lite, registry before assets), moving Designers/creature/other games/Fabric out of this 16-day window?
9. Object storage and domain for packs (provider unnamed to customers) and the deploy approvals needed for the DB migration (project/revision store).
10. Do you want Server Doctor (scan any customer server for conflicts) as an acquisition feature even without Cyrus mods?

## Sources (opened 2026-10-10)
S1 https://www.minecraft.net/en-us/eula ; S2 https://www.minecraft.net/en-us/usage-guidelines ; S3 https://code.claude.com/docs/en/legal-and-compliance ; S4 https://modrinth.com/news/article/ai-policy-and-disclosures/ ; S5 https://support.modrinth.com/en/articles/8802351-modrinth-modpack-format-mrpack ; S6 https://api.modrinth.com/v2/tag/loader and /v2/project/luckperms/version ; S7 https://hangar.papermc.io/api/v1/projects/ViaVersion/versions ; S8 https://jd.papermc.io/paper/1.21.11/org/bukkit/entity/Player.html ; S9 https://minecraft.wiki/w/Server.properties ; S10 https://minecraft.wiki/w/Resource_pack ; S11 https://github.com/toxicity188/BetterModel (v3 and v2 README, releases/branches via GitHub API) ; S12 https://raw.githubusercontent.com/PaperMC/Paper/main/paper-api/LICENCE.txt ; S13 https://api.github.com/repos/<owner>/<repo> licence fields (fetched 2026-10-10; repo list in section C) ; S14 https://docs.papermc.io/paper/dev/getting-started/paper-plugins ; S15 https://docs.papermc.io/paper/dev/dialogs ; S16 https://docs.papermc.io/paper/dev/folia-support/ ; S17 https://fill.papermc.io/v3/projects/paper and https://repo.papermc.io/repository/maven-public/io/papermc/paper/paper-api/maven-metadata.xml ; S18 https://geysermc.org/wiki/geyser/custom-items/ ; S19 https://modrinth.com/plugin/jmQaa0X3 ; S20 https://developers.cloudflare.com/r2/pricing/ ; S21 https://slsa.dev/spec/v1.1/levels ; S22 https://genai.owasp.org/llmrisk/llm01-prompt-injection/ ; S23 https://docs.gradle.org/current/userguide/working_with_files.html ; S24 https://copyright.gov/newsnet/2025/1060.html (search result summary, not opened in full) ; S25 https://github.com/ComunidadAylas/PackSquash ; S26 https://github.com/mcbeet/beet ; S27 https://github.com/Smithed-MC/smithed-python ; S28 https://github.com/packwiz/packwiz ; S29 https://docs.modrinth.com/api/ . Internal: services/modbuilder/{server.js,entrypoint.sh,run.sh}, lib/cyrus/textures/{zip.ts,pack.ts}. Failed/blank: docs.modrinth.com/modpacks/format (404, used support article instead), Hangar publishing docs (no API info), CurseForge terms (404).

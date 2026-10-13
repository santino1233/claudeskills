> **CORRECTION 2026-10-10 (checked directly on Paper's Fill API and Maven repo):** this file says 26.3 is stable ("26.3.build.25-stable"). That is wrong: Fill lists only ALPHA/BETA builds for 26.3 (build 25 is ALPHA, newest 169 is BETA) and Maven has no `26.3...-stable` coordinate. Stable builds exist for 26.1.2 (build 74, `26.1.2.build.74-stable`) and 26.2 (build 133, `26.2.build.133-stable`). The recommended order below should read: **26.2 first, then 26.1.2, 26.3 when a stable build appears.** The registry (`lib/cyrus/versions/registry.json`) holds the verified pins.

# E. Minecraft / Paper version landscape and what Cyrus must do (as of 2026-10-10)

Labels: VERIFIED (url or file:line) = I opened it. UNVERIFIED = memory/inference. Web budget used: 12 pages (some 404). Stale-risk: Paper pages show builds as of their publish date; re-check the Fill API before building.

## (a) Versions, Paper builds, Java, api-version

| Line | Paper status | Java | Notes |
|---|---|---|---|
| 1.21.1 / 1.21.4 / 1.21.8 / 1.21.11 | Cyrus builds these today (services/modbuilder/Dockerfile:11,49). 1.21.11 is the last "old-scheme" version: dependency `1.21.11-R0.1-SNAPSHOT`. | 21 | VERIFIED: docs.papermc.io/paper/dev/project-setup ("Before 26.1 (1.21.11 and earlier) `{VERSION}-R0.1-SNAPSHOT`"). Java 21 for 1.20.5-1.21.11: VERIFIED internally, lib/game-config.ts:190-196 (checked there against Docker Hub tags). |
| 26.1 / 26.1.2 ("Tiny Takeover", released 2026-03-24) | Builds exist (e.g. `26.1.2.build.23-alpha` named in the announcement). | **25** | VERIFIED: papermc.io/news/26-1 (new `<mcversion>.build.<n>-<status>` scheme); Java 25 first required by 26.1 (web search summary, supercraft/Chunky release notes: UNVERIFIED page-level). Internal cutover table VERIFIED: lib/game-config.ts:191. |
| 26.2 | Stable builds exist; ships Adventure 5. | 25 (inferred, UNVERIFIED for this exact version) | VERIFIED: papermc.io/news/26-2. |
| 26.3 (MC released 2026-09-15 per search snippet; Paper announcement says **Stable, 2026-09-26**) | Stable. Example pinned build `26.3.build.25-stable`. | 25 | VERIFIED: papermc.io/news/26-3; docs project-setup shows `toolchain.languageVersion.set(JavaLanguageVersion.of(25))` and `paper-api:26.3.build.+`. |
| 26.4 | Not out. Paper plans a config-file merge (Bukkit/Spigot/Paper configs) "in 26.4". | ? | UNVERIFIED (search-snippet only). |

Key rules:
- **Dependency coordinate for 26.x**: `io.papermc.paper:paper-api:26.3.build.+` (floating) or an exact `26.3.build.25-stable`. VERIFIED (project-setup page). The `-stable/-alpha` suffix is the build status; a floating `.+` can pull alpha builds, so Cyrus should pin one exact stable build per version in its registry (it compiles offline against a frozen classpath file anyway, services/modbuilder/server.js:511).
- **api-version**: Paper docs only show `api-version: '26.3'` in the paper-plugin.yml example (VERIFIED, docs.papermc.io/paper/dev/getting-started/paper-plugins). The exact string for a patch release like 26.1.2 (`'26.1'` or `'26.1.2'`) is UNVERIFIED; Cyrus pins api-version to the exact mcVersion today (server.js:473-483) because of the 2026-10-07 "Growth incident"; for 26.x test on a real Paper 26.1.2 server before shipping the same rule.
- **Support/EOL**: Paper states it does not backport exploit fixes after a version has been stable for a while, and worlds cannot be downgraded after upgrading (VERIFIED, news/26-2, 26-3). So owners drift to the newest version fast; there is no published EOL calendar (not determined). Paper's old v2 download API was sunset (cubecoders thread, UNVERIFIED); Cyrus's mirror already uses fill.papermc.io v3 (lib/cyrus/games/minecraft.ts:77).
- **Platform changes in 26.x** (VERIFIED, news/26-1): world dimensions moved into `world/dimensions/`; clocks are per-world by default (`time.affects-all-worlds`); Mojang no longer ships obfuscated jars and Paper dropped the internal remapper. Cyrus forbids NMS/reflection so the remapper change does not touch generated plugins.

## (b) What breaks between 1.21.11 and 26.x for generated plugins

VERIFIED from Paper news pages:
1. **Adventure 5 (26.2)**: previously deprecated APIs removed; `BookMeta` no longer extends Adventure `Book`; deprecated `ClickEvent`/`HoverEvent` use removed. Impact: any generated code using old click/hover constructors or book meta. Add rules to the failure-rule set for 26.2+.
2. **Beds are no longer block entities (26.2)**: PersistentDataContainer on beds is gone (`AsyncServerDataFixerRemoveBlockEntityEvent` to migrate).
3. **26.3**: `@Experimental` removed from the data-component API (so it is now a stable path for item_model, custom_model_data, equippable via `io.papermc.paper.datacomponent`); deprecations: `PlayerAnimationEvent` -> `PlayerArmSwingEvent`, `PotionEffectTypeCategory`, `PotionBrewer`; new events (EntityBreakEvent, EntityConstructEvent, EntityCollideWithEntityEvent, SulfurCubeSwallowItemEvent, PlayerCodeOfConductSendEvent).
4. **26.1**: new `World#locateNearestPoi`, `WorldCreator#forcedSpawnPosition`, `EntityLungeEvent`, `ItemCraftedEvent`; per-world clock changes affect any "set time / eternal day" plugin (eval prompt `s07-daynight` is a natural regression test).

UNVERIFIED (must be proven with javap against each jar, as `services/modbuilder/sheets/gen-sheets.py` does for 1.21.x): enum-to-registry-interface changes (Attribute, Sound, Particle, Enchantment), command API (Brigadier `LifecycleEvents.COMMANDS`), `ItemMeta.setItemModel` vs `DataComponentTypes.ITEM_MODEL`, scheduler (BukkitScheduler vs Folia-style `getScheduler()` on Paper). The 1.21.11 sheet already says `setItemModel(NamespacedKey)` and `io.papermc.paper.datacomponent.Dat...` exist (sheets/1.21.11.md:61). Do not assume the 1.21.11 sheet is valid for 26.x.

**Pack format numbers** (VERIFIED, minecraft.wiki/w/Pack_format):
- Data pack: 1.21-1.21.1 = 48; 1.21.4 = 61; 1.21.7-8 = 81; 1.21.9-10 = 88.0; 1.21.11 = 94.1; 26.1-26.1.2 = 101.1; 26.2 = 107.1; 26.3 = 121.0.
- Resource pack: 1.21-1.21.1 = 34; 1.21.4 = 46; 1.21.7-8 = 64; 1.21.9-10 = 69.0; 1.21.11 = 75.0; 26.1-26.1.2 = 84.0; 26.3 = 97.1. **26.2 resource-pack number not returned: UNVERIFIED**.
- Since 25w31a (1.21.9) `pack.mcmeta` uses `min_format`/`max_format` instead of `pack_format`; versions are now major.minor.
- Internal finding: `lib/cyrus/textures/pack.ts` `packFormatFor` returns 75 for anything not 1.21.x (so 26.x gets the wrong number) and writes a pack.mcmeta that mixes `pack_format`, `supported_formats`, `min_format: 46`, `max_format: 999`. Whether mixed legacy+new keys with 999 are accepted by 26.x clients is UNVERIFIED; the registry should hold exact per-version numbers and the pack builder should be tested on a real 26.3 client.

## (c) Public usage stats

bStats (bstats.org/global/bukkit) renders charts client-side; WebFetch returned only "Loading chart data". **Could not determine** public version share. Do not cite numbers. Recommendation: use Nxeon's own data: 7 Paper servers with an explicit version = 5 on 26.x, 2 on 1.21.x (owner-given; the list in the brief names only 4 26.x servers, so the count needs a re-check). Next step: query `ServerGameConfig`/pin records (see worker recordPin) across all Minecraft servers, not only Paper, to size demand before choosing which versions to build.

## (d) ViaVersion / ViaBackwards

- ViaVersion licence: API is **MIT**, everything else **GPLv3** (VERIFIED, github.com/ViaVersion/ViaVersion). Runs on Paper/Velocity as a plugin jar from Hangar/Modrinth/GitHub. ViaBackwards is a separate project (licence not opened: UNVERIFIED, believed GPLv3).
- What it does: lets newer clients join older servers (ViaBackwards: older clients on newer servers). It does NOT make a plugin compiled for 1.21.x load on a 26.x server; plugin compatibility depends on the server API, not the client protocol. So it does not solve Cyrus's problem.
- Worth it only as an optional companion on the mods/plugins catalogue ("let players on other versions join"), installed as a normal third-party plugin via the existing Hangar/Modrinth installer (lib/mods/installers/minecraft.ts). Cyrus must not bundle, link or redistribute it (GPL). Whether it supports 26.x today: not found (UNVERIFIED). Effort S as a catalogue entry; not a Cyrus dependency.

## (e) Proposed version-support registry (replaces MB_VERSIONS in lib/modbuilder/types.ts:3, the Dockerfile ARGs, minecraft.ts `versions`, games.ts, packFormatFor)

One data file (JSON, read by both Next.js and the Node build service) with one row per Minecraft version:
`id` ("26.3"), `family` ("1.21" | "26"), `paperCoordinate` (exact pinned, e.g. "26.3.build.25-stable" or "1.21.11-R0.1-SNAPSHOT"), `paperBuildStatus`, `javaToolchain`/`javaRelease` (21|25), `itzgImage` (java21|java25), `pluginApiVersion` (string to write in plugin.yml), `dataPackFormat`, `resourcePackFormat` (both as major.minor), `sheetFile`, `ruleTags`, `capabilities` (e.g. `itemModel`, `dataComponentsStable`, `adventure5`, `registryAttribute`), `status` (current|supported|legacy|preview|retired), `buildable` (bool, set only after eval passes), `evalPassRate`, `rtVerifiedAt` (runtime-load check date), `addedAt`, `retireAt`, `classpathFile`.
Derived views: build-service allowlist, portal picker, lifecycle outdated logic, pack builder numbers, JDK selection, Docker args.

## (e) Recommended support matrix, order and effort

Build-service changes needed once, before any 26.x row (effort **M**): second JDK 25 in the image next to JDK 21 (Dockerfile pins Temurin 21.0.12.1 + Gradle 8.14.3; `javac --release 21` is hardcoded at server.js:513 and the Gradle template at template/build.gradle.kts:21-25 sets toolchain 21); per-version `--release`; per-version classpath files (CP_DIR/`<ver>.txt`); the Gradle `writeClasspath` task must resolve `26.x.build.N` coordinates (Gradle 8.14 vs Java 25 compatibility: UNVERIFIED, may need Gradle 9.x); rtcheck.py uses `eclipse-temurin:21-jre` and `/root/mbeval/paper/paper-<ver>.jar` and must switch to a 25 image for 26.x; failure-rule/sheet generation for new versions.

| Order | Version | Effort | Why |
|---|---|---|---|
| 1 | **26.3** (current stable) | L (includes the infra work above + sheet from javap + rules + eval/rt run) | Most customers and Paper's own newest; Paper backports nothing, owners move up. |
| 2 | **26.2** | S-M | Same infra; Adventure 5 rules already apply; sheet delta from 26.3 small. |
| 3 | **26.1.2** | S-M | Same infra; 4 of the 5 known 26.x servers include 26.1.2/26.2; confirm api-version string form first. |
| 4 | Keep 1.21.11 and 1.21.8 | none | Two known 1.21.x servers; already verified. |
| 5 | Demote 1.21.1 and 1.21.4 to legacy/retire by usage | S | Keep only if Nxeon usage data shows servers pinned there. |
| Avoid | 1.20.x and older | L each | Different API (enum Attribute/Sound, no item_model before 1.21.4); no demand evidence. |
| Optional | ViaVersion catalogue entry | S | Player-side only. |

Gate: a version flips `buildable=true` only after (1) the 30-prompt eval (services/modbuilder/eval/prompts.jsonl) meets the pass rate of 1.21.11 and (2) the 13 runtime-checked prompts pass on a real Paper server of that exact version. Re-run on every new Paper stable build (add a nightly Fill API check that creates a "preview" row automatically).

## Could not determine
bStats version shares; Java requirement stated by Paper for 26.2 specifically; 26.2 resource-pack number; whether mixed legacy+new `pack.mcmeta` keys are valid; the api-version string form for patch releases; ViaBackwards licence and 26.x support; Gradle 8.14 behaviour on Java 25.

## Sources (opened)
papermc.io/news/26-1, 26-2, 26-3; docs.papermc.io/paper/dev/project-setup/; docs.papermc.io/paper/dev/getting-started/paper-plugins; minecraft.wiki/w/Pack_format; github.com/ViaVersion/ViaVersion; bstats.org/global/bukkit (empty); two web searches (Java 25 / migration; snippets only). 404: docs.papermc.io/paper/versions, /paper/reference/plugin-yml/. Internal: lib/game-config.ts:190-237; services/modbuilder/{Dockerfile,server.js,template/build.gradle.kts,eval/rtcheck.py}.

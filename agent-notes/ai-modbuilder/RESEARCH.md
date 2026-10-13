# AI Mod & Plugin Builder: Research Findings

Compiled 2026-10-06. Method: web research (three parallel research passes, fetched mostly through the GitHub REST API and primary pages), a read-only review of the Nxeon and Kodely codebases, and one small local experiment.

Tags:
- **[V]** verified from a primary source: repo LICENSE or API, vendor page, or a local run.
- **[S]** secondary: a search snippet or a third-party summary.
- **[I]** inference.

This is not legal advice.

Known gaps:
- minecraft.net (EULA, usage guidelines), Reddit r/admincraft and the SpigotMC forums all blocked or timed out for the fetcher.
- Every quote from those sources is secondary and must be re-read by a human before it is relied on.

---

## 1. Local experiment (Phase 0 pre-spike) [V]

Location: `/tank/ai-modbuilder-research/` (JDK Temurin 21.0.12 and Gradle 8.14.3 downloaded there; the `hello-plugin/` project).

**What was built:** a Paper 1.21.11 plugin with a `/heal` command, a join greeting using Adventure `Component`, a `plugin.yml` with a permission, and two MockBukkit 4.116.3 JUnit 5 tests.

**Results:**
- Cold build: **2 m 45 s**. That includes first-time dependency resolution, which grew the Gradle cache by about 113 MB.
- `compileJava` succeeded and produced a 2.3 KB jar.
- **Both MockBukkit tests failed** with `IllegalArgumentException: Cannot subclass primitive, array or final types: class cloud.nxeon.hello.HelloPlugin`.
  - MockBukkit 4.x builds a ByteBuddy proxy subclass of the plugin's main class.
  - A `final` main class, which is an idiomatic LLM choice, breaks every test.
  - Fixed in source (removed `final`).
  - **Not re-run.** Host RAM fell to 1–3 GB free, and the coordinator ordered no heavy JVM work while below 8 GB.

**Lessons:**
1. The pipeline needs a prewarmed offline dependency cache. The cold build time is dominated by downloads.
2. Small ecosystem gotchas like this one are exactly what the template, lint and pattern layer must encode.
3. MockBukkit has no paper-api dependency in its POM, so the plugin must pin both versions consistently.

**Not done (resource rule):**
- booting a real Paper server from the mirror;
- a mineflayer bot test.

The Phase 0 spike must do both on a farm VM, not on the primary node.

**Available locally and reusable:** `/tank/nxlabs-mirror/minecraft/paper/` has pinned Paper jars for 1.12 through 26.3, including `1.21.11-131/132` [V].

## 2. Open-source building blocks and licences

### Licence table

| Project | URL | Licence | Verified | Use mode | Notes / risk |
|---|---|---|---|---|---|
| **Paper (server + API)** | github.com/PaperMC/Paper | GPL-3.0 (contributors may opt into MIT for own code); no classpath exception | V (LICENSE.md) | Compile against API; run unmodified server in sandbox | Don't fork/modify+distribute. See GPL analysis |
| **Bukkit API** | github.com/Bukkit/Bukkit | GPL-3.0 | V | Compile against | Same |
| Spigot API | hub.spigotmc.org | GPL-3.0 | I (via Paper LICENSE.md) | Compile against | Same |
| CraftBukkit / BuildTools | hub.spigotmc.org | LGPL → GPL chain; 2014 DMCA (Wesley Wolfe) history | I/S | **Don't use**; use Paper's distribution (Paperclip patches Mojang jar at runtime) | Never bundle Mojang or remapped jars |
| Purpur | github.com/PurpurMC/Purpur | MIT label (inherits GPL Paper code) | V (label) | Run as test target | Treat effective server licence as GPL [I] |
| Velocity | github.com/PaperMC/Velocity | GPL-3.0 | V | Run unmodified (network tests) | |
| Paperweight userdev | github.com/PaperMC/paperweight | LGPL-2.1 | partial V | Build tool (internals/NMS only, avoid at MVP) | Downloads/remaps Mojang jars, so they must never be redistributed |
| **run-task / run-paper** (jpenilla) | github.com/jpenilla/run-task | Apache-2.0 | V | Build-on (dev/test server boot) | |
| **MockBukkit** | github.com/MockBukkit/MockBukkit | MIT | V | Build-on: unit tests of generated plugins | Artifacts `mockbukkit-v1.21` (4.116.3), `mockbukkit-v26.1.2`, `mockbukkit-v26.2` on Maven Central [V] |
| **mineflayer** | github.com/PrismarineJS/mineflayer | MIT | V | Build-on: bot-driven live tests | v4.39.0 released 2026-09-06; supports MC 1.8 → 26.1 [V] |
| node-minecraft-protocol | github.com/PrismarineJS/node-minecraft-protocol | BSD-3 | V | Build-on | |
| **minecraft-data** | github.com/PrismarineJS/minecraft-data | MIT per README (no LICENSE file, API shows null) | V (README) | Registries cross-check / RAG | README: some data came from wiki.vg/gamepedia and "license might change"; `language` files are Mojang strings. Audit per file. Covers pc up to 26.1 [V] |
| prismarine-viewer | github.com/PrismarineJS/prismarine-viewer | MIT | V | Maybe (3D replays) | Needs Mojang client textures, which we cannot redistribute |
| itzg/docker-minecraft-server | github.com/itzg/docker-minecraft-server | Apache-2.0 | V | Test-server image pattern (Nxeon already uses it) | Pin jars from our mirror; it re-downloads otherwise (lq4amk incident) |
| fabric-example-mod | github.com/FabricMC/fabric-example-mod | CC0-1.0 | V | Copy as template | |
| Fabric API / Loom | github.com/FabricMC/fabric, fabric-loom | Apache-2.0 / MIT | V | Build against / build tool (v1) | |
| **Adventure / MiniMessage** | github.com/PaperMC/adventure | MIT | V | Template dependency (bundled in Paper) | |
| Configurate | github.com/SpongePowered/Configurate | Apache-2.0 | V | Template dependency | |
| **Incendo Cloud** | github.com/Incendo/cloud | MIT | V | Command framework in templates | |
| ACF | github.com/aikar/commands | MIT | V | Alternative | |
| **triumph-gui** / **InvUI** | github.com/TriumphTeam/triumph-gui, NichtStudioCode/InvUI | MIT / MIT | V | GUI framework in templates | IF (stefvanschie): API says Unlicense; re-check |
| bStats | github.com/Bastian/bStats-Metrics | MIT | V | Off by default | Phones home |
| **Misode generators** | github.com/misode/misode.github.io | MIT | V | Learn from / reuse UI ideas for datapack forms | Data comes from mcmeta |
| misode/mcmeta | github.com/misode/mcmeta | **No licence**; Mojang-derived | V | Reference only, **don't bundle** | |
| **Beet** | github.com/mcbeet/beet | MIT | V | Datapack build pipeline | Bolt: status unclear (possibly archived); verify |
| Sandstone | github.com/TheMrZZ/sandstone | MIT | V | Optional TS datapack DSL | |
| **Spyglass** | github.com/SpyglassMC/Spyglass | MIT | V | Datapack linter / LSP as a service | |
| Skript | github.com/SkriptLang/Skript | GPL-3.0 | V | Output *target* (run on test server); don't embed | Docs GPL-3.0 [S] |
| Denizen | github.com/DenizenScript/Denizen | MIT | V | Optional target / learn | |
| MCreator | github.com/MCreator/MCreator | GPL-3.0 + §7 exceptions | V | **Learn from only** | Its "AI" features are mob-AI blocks, not generative AI [S] |
| Blockbench | github.com/JannisX11/blockbench | GPL-3.0 | V | Users' separate tool; adopt `.bbmodel` format | Don't embed |
| Oxide.Rust (uMod) | github.com/OxideMod/Oxide.Rust | MIT | V | v2 target | |
| Carbon (Rust) | github.com/CarbonCommunity/Carbon | GPL-3.0 | V | v2 target | Same plugin-vs-host GPL question |
| BepInEx / Jotunn | github.com/BepInEx/BepInEx, Valheim-Modding/Jotunn | LGPL-2.1 / MIT | V | v2 target | |
| **OW2 ASM** | gitlab.ow2.org/asm/asm | BSD-3 | I | Bytecode safety scanner core | |
| **SpotBugs + find-sec-bugs** | github.com/spotbugs/spotbugs, find-sec-bugs/find-sec-bugs | LGPL-2.1 / LGPL-3.0 | V | Run unmodified as CLI | |
| PMD | github.com/pmd/pmd | BSD-style | V | Style/quality lint | |
| Semgrep engine / rules | github.com/semgrep/semgrep, semgrep-rules | LGPL-2.1 / "Semgrep Rules License v1.0" | V / I | Engine OK; **write our own rules** | Registry rules restrict SaaS/competing use [I]; read before use |
| **gVisor** | github.com/google/gvisor | Apache-2.0 | V | Build sandbox runtime | |
| **Firecracker** | github.com/firecracker-microvm/firecracker | Apache-2.0 | V | Test-server microVMs (needs KVM; we have Proxmox nodes) | |
| Kata Containers / Sysbox | github.com/kata-containers/..., nestybox/sysbox | Apache-2.0 | V | Alternatives | |
| Voyager (MineDojo) | github.com/MineDojo/Voyager | MIT | V (stale since 2024) | Learn from: skill library + iterative self-verification loop | |
| Mindcraft | github.com/kolbytn/mindcraft | MIT | V | Learn from / possible exploratory test bot | |
| Nekodetector / jNeedle | github.com/MCRcortex/nekodetector | Not confirmed | — | Learn from (fractureiser-class detection) | Check licence |

### GPL / LGPL / AGPL implications

No AGPL components were found in the stack.

**(a) Our closed backend.** It is safe as long as we never link, fork or embed GPL code into it.
- Run GPL programs (Paper, Velocity, Skript, ViaVersion) **unmodified, as separate processes** inside the sandbox.
- SaaS use without distributing those programs triggers no GPL obligation.
- LGPL tools (SpotBugs, Semgrep engine) are used unmodified as CLIs.

**(b) Generated plugins.** They compile against GPL-3 APIs that carry no linking exception.
- The ecosystem norm is that plugins are not derivative works, and thousands of closed-source paid Spigot plugins exist.
- That norm has never been tested in court [S/I].
- Lowest-risk default: **ship MIT-licensed output with full source included.** MIT is GPL-compatible.
- Never shade GPL libraries into output jars. Shading MIT or Apache libraries is fine; include their NOTICE files.

**(c) Our templates and patterns.** Author them ourselves and license them MIT.
- Templates may be seeded from CC0 or MIT sources such as fabric-example-mod.
- Never copy MCreator, Skript or Blockbench code.

## 3. Competitive scan

| Product | URL | Output | Compiles / tests? | Pricing (seen 2026-10-06) | Notes / gaps |
|---|---|---|---|---|---|
| **Player.Games**, the main competitor | player.games/en-US/minecraft-plugin-maker | Spigot/Paper plugins, Fabric/NeoForge mods, datapacks, Bedrock, Hytale, Cobblemon; JAR plus full source [V] | Claims each build is compiled and "booted on a real Paper server"; self-reported "98.2% pass rate" [V] | Free credits through Discord activity (25, up to 75 a day); packs from **$8 for 500 credits** [V] | Builds take minutes, up to about 30 min. The boot test does not show the plugin does what was asked. No visible version history, visual editor or install flow. Its "best AI mod maker" ranking is self-published. |
| **Orca** (YC S24) | ycombinator.com/companies/orcaengine | Fabric/Forge/NeoForge mods, Paper plugins, Bedrock add-ons, textures; desktop plus web [S] | Claims compile, test and deploy to a free bundled 8 GB server; crash-log analysis [S] | Free tier; Pro about **$19.99/mo** [S] | VC-backed and bundles hosting, so it competes directly with Nxeon. Test depth unknown. |
| genesix Blocks | builtbybit.com thread 738955 | Paper plugins [S] | Claims Gradle compile, returns a JAR [S] | Unknown | Marketing claims only |
| ModCrafter | mod-crafter-java.lovable.app | Datapacks as a zip [V] | No validation claim [V] | None shown | Indie project on Lovable |
| MCD Generator, Codingfleet | shapes.inc/mcdgenerator, codingfleet.com | Command and datapack snippets [S] | No | — | LLM wrappers |
| CreativeMode.net | creativemode.net | No-code mod wizards, JAR export [S] | Exports a JAR | Freemium [S] | Strong community angle; AI depth unclear |
| MCreator | mcreator.net | Visual mod maker (Forge/NeoForge/Fabric/Bedrock) | Gradle build | Free, open source | No generative AI [S]; plugins cannot add new element types |
| Hosts (Aternos, Apex, Shockbyte, Bisect, Pebble, Exaroton) | — | None found offering generation [S/I] | — | — | **Open lane for a host (Nxeon)** |
| Roblox Assistant (analogue) | about.roblox.com newsroom 2026-04 | Luau, meshes; Planning Mode; beta Playtest Agent; Studio MCP [V/S] | Playtest agent (beta) | Free first-party | Complaints: inconsistent code, weak cross-system reasoning, false-positive bans |
| UEFN Verse tools (analogue) | uefncentral.com | Verse code | Validates against Epic's API digest [S] | 1 free generation a month [S] | Worth copying: validation against a real API digest |
| Rosebud, Bezi (analogues) | rosebud.ai, bezi | Games / Unity assistant | — | $15–$50/mo; $20–$200/mo [S] | Users say credits run out fast |

**Name checks.** No credible live product was found for "Pluginator", "PluginGPT", "BukkitGPT", "SkriptGPT", "ModGen" or "Kodari". In-game LLM chat plugins (CraftGPT, mcGPT, AIConstructor on Hangar) are adjacent, not competitors.

### Market gaps we can own
1. **Behaviour verification.** Bot-driven acceptance tests derived from the user's spec, shown as a replayable timeline. Competitors stop at "it boots".
2. **A safety and capability report on every build.** The SpigotMC thread "Spigot has a serious problem with low effort AI generated plugins" exists, but only its title could be read. Trust is the selling point.
3. **Install, rollback and fix-from-logs on the user's actual server.** A host can do this natively; standalone generators cannot.
4. **Iterative editing with versions and diffs.** Competitors look like one-shot generators [I].
5. **Skript, datapacks, Rust and Valheim.** No validated generators exist.
6. **Price honesty.** Show the price before running, and never charge for failed builds.

### Community and platform signals
- **Modrinth AI policy** [V], https://modrinth.com/news/article/ai-policy-and-disclosures/:
  - effective 2026-08-13; the grace period ended 2026-09-27;
  - fully or primarily AI-generated projects cannot be publicly listed;
  - AI-assisted projects must carry a disclosure;
  - no AI images in listings.
- **Hangar guidelines** [V], https://hangar.papermc.io/guidelines: no obfuscation, no paywalled or licence-keyed functionality. No AI-specific rule.
- **r/admincraft sentiment:** not verified (fetch blocked). A human should read it manually before launch messaging.

## 4. Data and asset library sources

### Game data
| Source | Licence | Redistributable? | Plan |
|---|---|---|---|
| Mojang data generator (`java -DbundlerMainClass=net.minecraft.data.Main -jar server.jar --reports --server --all`) | Mojang IP under the EULA | Not as raw dumps [I] | Run it ourselves per version, from jars in Nxeon's mirror, into internal lookup tables. Expose derived facts (IDs, names, schemas), not the raw files. |
| PrismarineJS minecraft-data | MIT (README) [V], mixed provenance | Mostly; audit the wiki-derived and `language` files | Primary static source and cross-check. Includes blocks, items, entities, recipes, biomes, effects, enchantments, particles, sounds, commands, foods, attributes and protocol, up to 26.1 [V]. |
| misode/mcmeta | No licence, Mojang-derived [V] | No | Reference only |
| Minecraft Wiki (minecraft.wiki) | **CC BY-NC-SA 3.0** [V] | **No (NC clause)** | Don't ingest. Optionally ask Weird Gloop for a licence. |
| Fandom wikis | CC BY-SA by default, varies per wiki [S] | Avoid | — |
| Paper, Spigot and Bukkit javadoc | Generated from GPL source | Index signatures; keep prose internal [I] | Build our own symbol and event index from the `paper-api` jar (ASM or reflection) per version |
| Skript docs | GPL-3.0 [S] | — | Write our own syntax descriptions |
| Unobfuscated jars [S] | Still covered by the Mojang EULA | No | Mojang announced in October 2025 that obfuscation would be removed. 26.1 (2026-03-24, Java 25) is the first fully unobfuscated release, so NMS-level work gets easier. Readable does not mean redistributable. |

### Art and audio for resource packs
| Source | Licence | Verdict |
|---|---|---|
| Mojang vanilla textures, sounds, models | EULA: no commercial use or redistribution [S] | **Never ship** |
| Kenney (voxel pack and others) | CC0 [S] | Use first |
| Poly Haven | CC0 [I] | Use (needs pixel-art processing) |
| OpenGameArt | Per asset | CC0 assets only, licence recorded per asset |
| Freesound | Per sound: CC0, BY or BY-NC | CC0 (and BY with credit); never NC |
| Sonniss GDC bundles | Royalty-free when embedded; bans standalone redistribution and AI training [S] | Avoid for a library product |
| Luanti/Minetest Game, VoxeLibre/MineClone2, Pixel Perfection | CC BY-SA 3.0/4.0 [S] | Avoid by default (share-alike propagates; possibly derivative of Mojang's look) |
| Faithful | Custom Faithful License v3 [S]; a derivative of Mojang textures | Don't bundle |
| Our own pixel art (commissioned, or AI-assisted then human-cleaned) | Ours | The core of the GUI icon set and texture starter kit |

### Knowledge-base layers and indexing
See PLAN §8.

| Layer | Index type |
|---|---|
| Registries and API signatures | **Structured, exact lookup** |
| Patterns and how-to docs | **Embeddings** (pgvector) |

Everything is version-scoped.

## 5. Model strategy research

Pricing from the bundled Claude API reference, cached 2026-09-25:

| Model | Input $/MTok | Output $/MTok | Notes |
|---|---|---|---|
| Opus 5.5 | 4 | 20 | Cache read 0.20 |
| Sonnet 5.5 | 2 | 10 | Cache read 0.20 |
| Haiku 4.5 | 1 | 5 | |
| Fable 5.1 | 10 | 50 | |

- **Batch API:** 50% off.
- **Cache writes:** about 1.25x the input price.
- **Behaviour notes for Opus 5.5 and Sonnet 5.5:**
  - Thinking cannot be disabled. Control it with `output_config.effort`; Opus 5.5 defaults to `medium`.
  - Forced `tool_choice` returns a 400. Use `auto` with `strict: true` tools.
  - Server-side refusal `fallbacks: "default"` is available.
  - Mid-conversation `system` messages are available, which helps operator rules without breaking the cache.
  - Task budgets (beta) are available.
- **Kodely's real numbers:** a first site build costs about $0.29 and an edit about $0.34 on Sonnet 5 (`/root/kodely-dev/lib/credits.ts`). A failed build is recorded but never charged. That is a good precedent.
- Cost model and role split are in PLAN §10. Headline: **about $0.95 of LLM per medium plugin**, range $0.50–$2.50 [I]. Phase 0 must measure the real figure.

## 6. Legal and policy

| Topic | Finding | Source | Tag |
|---|---|---|---|
| EULA: what a "Mod" is | "an original plug-in that extends the functionality of Minecraft but that doesn't contain a substantial part of our copyrightable code or content" | minecraft.net/eula (via TLDRLegal) | S |
| EULA: selling mods | Mods "belong to you… as long as you don't sell them for money / try to make money from them" | same | S. **Key open question for a paid generator; needs counsel** |
| EULA: modded versions | "You may not distribute any Modded Versions of our game" | same | S |
| Server monetization | Access may be charged for; no pay-to-win gameplay sales | pcgamesn.com coverage of the guidelines | S |
| Brand use | "Minecraft" only in secondary or descriptive use, with the disclaimer "Not an official Minecraft product. Not approved by or associated with Mojang or Microsoft." No official art | minecraft.net commercial-use guidelines | S |
| AI output copyright (US) | Copyright Office Part 2 report (2025-01-29): prompts alone don't make you an author; human selection, arrangement or modification can be protected | blogs.loc.gov, Feb 2025 | S |
| Thaler v. Perlmutter | Supreme Court denied cert on 2026-03-02; the human-authorship requirement stands | mayerbrown.com, March 2026 | S |
| Anthropic outputs | Commercial Terms: Anthropic assigns its rights (if any) in outputs to the customer | anthropic.com/legal/commercial-terms | S (verify) |
| Modrinth | Bans primarily AI-generated public projects; disclosure required | modrinth.com news | V |
| Hangar | No obfuscation, no paywalled features, no per-user access grants | hangar.papermc.io/guidelines | V |
| Malware precedents | fractureiser (June 2023) jar-infecting worm; Stargazers Ghost Network (2025) fake mods via GitHub, more than 1,500 devices | prismlauncher.org, research.checkpoint.com | S |
| COPPA | Amended rule effective 2025-06-23, compliance due 2026-04-22; verifiable parental consent required under 13 | dlapiper.com | S |

### Recommended policies
These are folded into PLAN §9 and §13.
- Charge for the service, never for plugins as products.
- Ban pay-to-win generation.
- Ship MIT output with source included.
- Assign outputs to the user, with no copyright guarantee.
- Never auto-publish to marketplaces.
- Never obfuscate output.
- Store CC0 assets only, with a per-asset licence manifest.
- Service is 13+; payments need 18+ or a guardian.
- Use the "not official" disclaimer.

## 7. Existing Nxeon and Kodely assets to integrate later (read-only review)

| Area | What exists | Location |
|---|---|---|
| Mods engine | Install engine with guest state file `/root/.nxeon-mods/state.json`, staged writes, 5 backups, rollback, enable/disable/update, sha256, 256 MB/512 MB caps; `GAME_MOD_SYNC` worker job | `lib/mods/engine.ts`, `lib/mods/installers/minecraft.ts`, `worker/game-mods.ts` |
| Catalogue | `GameMod` (32k+ Modrinth rows for Minecraft), `ServerMod`, `ModVersion`, `ModBlockedHash` | `lib/mods-catalog.ts` (NxLabs store); `/dashboard/nxlabs`, `/mods` |
| Nxeon Verified | Preflight checks (licence, hash, archive safety) and smoke tests on throwaway `qa-modverify-*` servers on non-primary nodes, always torn down, owner-run CLI | `lib/mod-verify/{checks,preflight,smoke,store}.ts`, `scripts/mod-verify.ts` |
| Server-jar mirror | Vanilla, paper, folia, purpur, fabric, quilt, forge, neoforge, bedrock, with pinning | `lib/mcjars/*`, `/tank/nxlabs-mirror/minecraft` |
| Partner layer | HMAC SSO (`/sso/authorize` + `/api/partner/sso/token`), wallet *balance*, checkout deep links, `notifyPartner` webhooks, `partnerSource` attribution | `lib/partner.ts`, `/api/partner/*` |
| Free-MC tier | Docker + mc-router on node-2; RAM caps only, no disk quota | — |
| Kodely | Agent loop (Sonnet 5, write_file/delete_file tools, cached system prompt); credit ledger at $0.002/credit with failed builds free; publish-time secret scan; admin cost dashboard | `/root/kodely-dev/lib/{agent,credits,secret-scan}.ts` |

## 8. Open research items
1. Read the minecraft.net EULA, usage guidelines and commercial-use pages first-hand, and get counsel's view on paid generation versus "don't make money from mods".
2. Read r/admincraft and the SpigotMC AI-plugin thread manually for sentiment and launch messaging.
3. Confirm the licences of IF, ASM, Bolt, Reposilite and Nekodetector, and read the full Semgrep Rules License.
4. Measure Player.Games and Orca hands-on: build three identical prompts in each and compare behaviour. About $10 of credits.
5. Run the Phase 0 spike (PLAN §15). It replaces every [I] cost and success number with measurements.

# BX: Improvement research, "ultimate AI modding engine" (2026-10-14)

Scope: fresh re-mine of universal-modder (UM), survey of open projects in nine buckets, adoption cards for the top 15. Research only: no code changes, no deploys, nothing in /opt/nxeon. Scratch clones in `/tank/cyrus-knowledge/_scratch/{um,probe}` (not in git).

Labels. **V** = verified this session (GitHub API / `git clone --filter=blob:none` + LICENSE read / npm or PyPI / Maven Central / fetched doc page). **V-s** = second-hand from a note or doc page I fetched. **U** = unverified or estimate. Licence rule: MIT, Apache-2.0, BSD, CC0, ISC, MPL, Zlib, Unlicense usable. GPL/AGPL/LGPL, custom, noncommercial, no licence = ideas and clean-room only, or an external tool process that is never linked, copied or shipped to customers.

GitHub API quota (60/h unauthenticated) ran out after 56 repos; the remaining repos were checked by shallow `git clone` (date + LICENSE, no star count; "n/a").

## 0. Where Cyrus is today (so the ranking is honest)

- Latest measured state: eval fourth1 (90 builds, 1.21.11, Saka, $27.21): final pass 100%, **pass@1 76.7%**, boot 100%, cost/pass $0.30; by lane pass@1 plain 95, sound 85, designer 70, texture 63.3. fifth1 (24 builds, after rc11): pass@1 100% on designer+texture, full pass 79.2% (5 asset-stage fails, 4 of them "designer: the service returned no asset result" = the rc11 plain-build downgrade being scored as an asset failure; V from `/root/cyrus-eval/fifth1/report.md`).
- **The eval stages `playtest` = 0 pass / 0 fail / 90 not run, `quality` 21 not run** (fourth1). So the headline numbers measure "compiles, scans, boots", not "does what the user asked". This is the largest measurement gap (see card 1).
- Failure classes already fixed in rc10-rc12: perf-spawn-in-loop autofix path, Collection->List, weaker access, designer "no design" policy, texture all-solid autofix, sound layers autofix, plugin.yml depend autofix, Test Flight provides BetterModel. Remaining: hallucinated single names (ConsumableEffect, Material.SMITHING_TEMPLATE), lane selection recall 30% (but see quick win Q1: some expected labels are wrong), slow generation (planning = 51% of wall time, BJ; asset builds 4-5 min, journals show up to 8 min).
- Change builds are 44% of spend (BL section 1: 13 calls, 221 turns, $3.24) and the change prompt tells the model to "Read the existing files you need first" (`services/modbuilder/prompts.js` changePrompt, V): there is **no workspace map** (card 2).
- Static rules are **line regexes** (`perf.js` `{id:"perf-spawn-in-loop", re:/\.(spawnEntity|spawn|...)\(/, ctx:"loop"}`, `autofix.fixPerf` "plain braced shape", V). AST-level analysis is not present (card 4).
- Already adopted/parked, so not re-proposed as new: mineflayer survival bot, RCON ore probe, mutant-testing of the harness, 55 failure rules, 10 recipes, API facts verification via javap, BetterModel, perf watchdog, learning loop, token plan BL. Parked and still open: MockBukkit, Spyglass, cloud, run-task (BM audit line 209).

## 1. Ranked table (payoff / effort, licence-safe)

Payoff is against today's measured classes. Effort: S under a day, M a few days, L a week or more (U, my judgement).

| # | Item | Problem it hits | Payoff | Effort | Risk | Licence | Source |
|---|---|---|---|---|---|---|---|
| 1 | **Functional acceptance oracle in the eval** (golden RCON expectations + survival bot per archetype, scored as `behaves`) | pass@1/boot measure compile+boot only; playtest 90/90 not run | Very high (decides every later choice) | M | Low | own code; mineflayer MIT | UM oracles + Cyrus goldens |
| 2 | **Workspace map for change builds** (class/method/command/config-key outline from tree-sitter-java injected in the first turn) | change builds 44% of spend, 12-31 turns of reads | High | S-M | Low | tree-sitter MIT; aider repo-map idea Apache-2.0 | aider, tree-sitter-java |
| 3 | **MockBukkit pre-flight smoke** inside the build service (seconds, generated harness, not model-written tests) | "build succeeded, plugin did not enable" (goblin/BetterModel, rc12), NPE on command/config in the first second | High | M | Med (running generated code on the build host) | MockBukkit MIT | MockBukkit |
| 4 | **AST rules + rewrites** (tree-sitter-java or ast-grep) replacing line-regex perf/API rules | perf-spawn-in-loop = biggest class (11 hits first1..fourth1), shape-specific autofix | High | M | Low | ast-grep MIT, tree-sitter MIT | ast-grep, tree-sitter |
| 5 | **Requirements ledger** (`requirements.json`: each user ask -> evidence command/config/event/class; persists across versions) | dropped features ($1.30 wasted on builds that dropped commands), ChunkMirror lane flip, "re-requested within 30 min" 23% of spend | High | S | Low | own; UM MODLOG idea MIT | UM mod-any-game |
| 6 | **Latency package**: effort/thinking A/B (`MB_EFFORT` exists, unset), plan-from-recipe skeleton, keep-warm cache, lane-parallel sessions | 8-minute builds; planning 51% of wall time | High | S (A/B) to L (parallel) | Med (coherence between lanes) | n/a (Claude-side) | BJ, BL, server.js |
| 7 | **Member index + did-you-mean + iterative grounding** (javap-derived per-version member table; De-Hallucinator pattern) | compile errors from hallucinated Paper API (5/90 builds fourth1) | Medium | M | Low | own; idea from arXiv 2401.01701 | De-Hallucinator |
| 8 | **Headless real-client smoke** (Fabric client game test on Xvfb: pack loads, item/model/texture screenshot) | tracker gap #1 "no real client has loaded a pack"; creature look unverified | High | L | Med (Mojang EULA, GPU-less render) | Fabric API Apache-2.0 | UM technique note |
| 9 | **Spyglass headless validator** for datapack / resource-pack JSON | datapack + designer JSON schema errors discovered only at server boot | Medium | M | Low | Spyglass npm MIT | SpyglassMC |
| 10 | **Cheap-repair ladder + circuit breaker** (same error signature twice -> change strategy; Haiku first repair on tier builds) | repair share 31% of spend (fourth1 snapshot), BL row 6 says cheap repair inactive on tier builds | Medium | S | Low | own; UM 3x rule | UM game-worker |
| 11 | **Typed-spec compilers for more archetypes** (JavaPoet emit; only 18 of 85 archetypes today) | tokens 70-90% lower per hit, removes whole failure classes | High (long) | L | Med | palantir/javapoet Apache-2.0 | BL section 0.4 |
| 12 | **"Already exists?" + dependency/compat lookup** (Modrinth/Hangar APIs) before credits are spent | capability-disclosure rule, wasted spend, soft-depend correctness | Medium | M | Low (API ToS, UA) | APIs: ToS; Hangar MIT | Modrinth docs |
| 13 | **Release lint** (`um publish check` ideas: secrets, decompiler fingerprints, byte-identical vanilla assets, archives) on jars, packs, library contributions, imports | licence/IP safety of outputs and the CC0 library | Medium | S-M | Low | UM MIT (reimplement) | um/publish.py |
| 14 | **Evidence levels + "skipped never passes" audit** in Test Flight, eval, portal wording | headline metrics overstating (boot 100% vs not flown) | Medium | S | Low | UM MIT | UM techniques |
| 15 | **Release-day API diff pipeline** (japicmp between consecutive paper-api jars -> candidate rename rules + sheet delta) | stays current on 26.x; rules like Attribute/GameRule renames are found by hand today | Medium | M | Low | japicmp Apache-2.0 | siom79/japicmp |

Below the line (cards not written): vision critic for textures (UM `sprite preview` idea), Error Prone custom checks as the JVM alternative to #4, PMD XPath rules, Geyser custom-item mapping emitter (bet), Folia scheduler shim (bet), packaging Cyrus knowledge as a Claude/Codex plugin (marketing).

## 2. universal-modder re-mine (fresh clone 2026-10-14)

Repo: https://github.com/rehan-remade/universal-modder, MIT, HEAD "kb: Crash N. Sane, quick boot..." (#308), 2026-10-14 12:07 -0700 (V, `git clone --depth 1`). Layout verified: 11 skills (`skills/*/SKILL.md`), 3 agents (`agents/mod-orchestrator.md`, `mod-game-worker.md`, `mod-offline-worker.md`), `um` CLI (`um/{scan,kb,publish,win,sprite,render3d,fal,comfy,video,backup}.py`), `knowledge/` (74 games, ~117 game notes, ~75 technique notes, `index.json`), engine playbooks (`skills/mod-any-game/references/engines/*.md`, 15 files), 7 plugin manifests (Claude, Codex, Cursor, Gemini, OpenCode, .mcp.json, VS Code), 6 worked examples, 7 tests, CI workflow.

Honest finding: it is still **mostly non-Paper**. Minecraft content = `engines/minecraft.md` (Fabric/NeoForge/Forge client mods, Bedrock one paragraph), 8 Minecraft game notes, 6 Minecraft technique notes. The earlier mine (tracker section 53, BD, BF) already took the Minecraft-relevant facts. What is NOT yet adopted is mostly **method**, not facts:

| # | Idea | What it is | Why it helps Cyrus | Effort | Risk | Where in repo |
|---|---|---|---|---|---|---|
| U1 | Evidence levels (creator report / proposal / source inspection / derived / synthetic / real run) + "things that look like proof and aren't" list | A 6-row vocabulary and 14 anti-patterns (test that checks little, conditional test that skips, badge percentage, clean run on author's PC, docs stronger than code) | Cyrus reports "boot 100%", "quality 0.998", "success" while playtest is 90 not run; portal says "succeeded" while the flight failed (rc12). Put the level on every verdict | S | Low | `knowledge/techniques/evidence-levels-for-mashup-claims.md` |
| U2 | "When the first real run fails, suspect the oracle": triage failures from raw traces by someone who did not write the checker; mutate real traces to prove the corrected checker can still fail | Process for eval/Test Flight red runs, with 6 steps and a "write down what the fix gives up" rule | Stops "fix the mod to satisfy a checker" and "relax the checker to go green" (fifth1's 4 designer "no asset result" fails are exactly a mis-scored checker) | S | Low | `knowledge/techniques/when-the-first-real-run-fails-suspect-the-oracle-re-deriving.md` |
| U3 | Prove the bench can fail: one-defect mutant builds; check each mutant really changes behaviour; match each failure to its message; false reds from stale cache keys | BE adopted mutants for the Test Flight harness. NOT yet applied to the **eval harness** (`scripts/cyrus/eval-run.ts`, cache keys, resume) or to autofix rules | Eval resume/dedupe and rule gates are exactly the "interrupted run leaves a stale key" shape | S | Low | `knowledge/techniques/prove-your-replay-bench-can-fail-mutant-builds-exposed-four-.md` |
| U4 | Circuit breaker: after about 3 identical failures stop, write down what is known, change approach; offline study vs live probing | Policy line in every worker brief | Repair loop spends 31% of cost; no same-signature detection found in `server.js` (grep, U) | S | Low | `agents/mod-game-worker.md`, `techniques/oracles-how-agents-know-a-mod-works.md` |
| U5 | MODLOG journal + REFINE LATER + STATUS.md + HANDOFF.md per project | Persistent journal of facts, dead ends, "never call X on Y" rules, surviving context compaction | Becomes the per-project requirements/decisions ledger that every change build reads (card 5) | S | Low | `skills/mod-any-game/SKILL.md` section 0, `agents/mod-orchestrator.md` |
| U6 | Orchestrator + two workers: only one process drives the real game; offline worker batches end with a named list of live probes; "do not let unproven offline work pile up" | Agent-team protocol | Fits Cyrus's own agent development (node-2 build lock = "one game worker"); not product code | S | Low | `agents/mod-orchestrator.md` |
| U7 | Publish check: byte-identical vs install (size then SHA-1), secrets patterns (Anthropic, OpenAI, GitHub, AWS, fal), decompiler fingerprints (Ghidra/IDA names, ILSpy headers), engine archives, absolute user paths, missing credits | 120-line lint | Cyrus `scan.js` is bytecode-capability oriented (V); a hash match against the vanilla jar (AM-vanilla-diff has the 26.1.2 reference) and a secrets/decompiler scan on packs, library contributions and imports is not evident | S-M | Low | `um/publish.py` |
| U8 | Note lint: front-matter schema, required sections, unfilled-template text, secrets, code block limits (warn 25 / fail 40 lines), links resolve, image size | Quality gate for knowledge notes | Apply to `services/modbuilder/recipes/*.json` provenance, golden notes, distilled sheets (no pasted third-party code) | S | Low | `um/kb.py` `check_note` |
| U9 | KB retrieval facets (`--game --engine --route`), whole-word term match (`rust` != `trust`), `index.json` | Search design | Recipe/rule retrieval at plan time: closed facets (lane, archetype, version) + whole-word match is cheaper and more precise than free text | S | Low | `um/kb.py` search, `_term` |
| U10 | Asset pipeline: `sprite palette --from stock`, `pixelate --colors --outline`, `preview --scale 6` "LOOK at it before shipping", one nearest-neighbour fit, mask/team colours, `render3d` presets | Palette snapping to the host game's own palette and a mandatory visual look | Cyrus texture lane has numeric quality (palette count, rim darkness, solidity) but no vision critic; a Haiku vision pass over a contact sheet is about $0.002 (U) | M | Low | `skills/asset-pipeline/SKILL.md`, `um/sprite.py` |
| U11 | Fabric scenario harness / client game tests: real clicks through `ClientPlayerInteractionManager`, two clients, screenshots after `isTerrainRenderComplete`, "prove the requirement" (refusal before grant, success after) | Real-client oracle on Xvfb | Only route to client-verified looks (card 8); "prove the requirement" trick is reusable in plugin goldens | L | Med | `knowledge/techniques/a-scenario-harness-in-a-minecraft-fabric-dev-client-real-cli.md` |
| U12 | Port-a-mod method: pinned source of truth, private remapped decompile, adaptation matrix, data extracted by scripts not retyped, unit-by-unit GameTests, audits by layer, resumable status docs | Process for large ports | Template for "port this plugin to another MC version" and for imports | M | Low | `skills/port-a-mod/SKILL.md` |
| U13 | Research protocol: Wayback CDX enumeration, archive.today fallback, query formulation (quote exact errors, name the engine), rank by evidence not stars, "never fetch leaks" | Dead-forum recovery | For Cyrus research agents when old Spigot/Bukkit threads vanish; also feeds failure-rule mining | S | Low | `skills/game-research-websearch/SKILL.md` |
| U14 | Multi-agent packaging manifests (`.claude-plugin`, `.codex-plugin`, `.cursor-plugin`, `gemini-extension.json`, `opencode.json`, `.mcp.json`) + SessionStart hook that puts the CLI on PATH | One repo distributed to six agent hosts | Cyrus could publish its (clean) Paper rules/sheets/recipes as a plugin: SEO and trust | M | Med (exposes knowledge) | `.claude-plugin/plugin.json`, `hooks/hooks.json` |
| U15 | Facts worth a rule check (V-s, from `engines/minecraft.md`): config written in place while a watcher re-reads truncates it (write temp file then rename); "a changed default never reaches existing users"; mono-only positional sounds; test the shipped jar not the dev run (Mojang vs SRG names); explicit network protocol version | Gotchas | Paper analogues: new config keys never reach servers on Refine (needs `getConfig().options().copyDefaults(true)` + save or an add-missing-keys step), stereo sources in sounds (Cyrus synth is mono? U) | S | Low | `skills/mod-any-game/references/engines/minecraft.md` |

Not adopted on purpose from UM: `um fal` / `um comfy` (paid fal.ai API, closed models), `um win` (Windows input driving), `um video` (showcase), `um scan` (installed-game fingerprinting), proxy-DLL/native-hook playbooks, anti-cheat guidance (not our surface). Its MIT licence allows reuse of anything, but none of those fit a hosted Paper lane.

## 3. Survey by bucket (verified metadata)

Columns: stars / last push / licence / use verdict. All V unless marked. "n/a" = stars not read (API quota).

### (a) AI code-gen for Minecraft, benchmarks, MCP servers

| Project | Stars | Last push | Licence | Verdict |
|---|---|---|---|---|
| https://github.com/mindcraft-bots/mindcraft | 5,887 | 2026-10-03 | MIT | LLM + Mineflayer survival agent. Read the skill/tool loop for an LLM playtester later; not for product. |
| https://github.com/MineDojo/Voyager | 7,260 | 2024-04-03 (stale) | MIT | Code-as-policy skill library with verification and self-reflection. Idea only (skill library with verified entries = Cyrus recipes). |
| https://github.com/PrismarineJS/mineflayer | 7,582 | 2026-10-11 | MIT | Already used (stress bot). Extend to functional acceptance (card 1). |
| https://github.com/OGMatrix/mcmodding-mcp | 68 | 2026-08-28 | MIT | Doc-search MCP for Fabric/NeoForge. Fabric lane only; reference. |
| https://github.com/AnCarsenat/minecode-mcp | 15 | 2026-09-09 | GPL-3.0 | Datapack-focused MCP (wiki, Mojira, Spyglass lookups). Reference only. |
| https://github.com/jasonjgardner/blockbench-mcp-plugin | 522 | 2026-10-14 | GPL-3.0 | Blockbench MCP. Reference only; our models are generated, not edited in Blockbench. |
| https://github.com/pickaid/mc-developing-mcp (listed "PickAID") | 2 | 2026-05-13 | NOASSERTION; search snippet says PolyForm Noncommercial | Reject (NC, tiny). |
| https://github.com/sickn33/agentic-awesome-skills | 47,600 | 2026-10-14 | MIT (repo) | Contains a `minecraft-bukkit-pro` skill (seen via claudeskills.info mirror; content not read). Low value next to MJP-Paper-Skills already vendored. |
| MineCEraft, arXiv 2608.28884 (Lee, Sidhu, Hockenmaier, Jung; submitted 2026-08-28; EMNLP 2026 Findings) | n/a | n/a | paper CC BY 4.0; data/code link not found on the abstract page | 723 expert instructions, 17 categories, programmatic verification of builds. It is a **world-building** benchmark, not plugin code. Take only the idea: programmatic verification per instruction (card 1). https://arxiv.org/abs/2608.28884 |

**Finding: no public benchmark for Paper/Bukkit plugin generation exists** (WebSearch twice, plus arXiv query; the closest are MineCEraft and MC-Bench-style voting). Cyrus's 178-prompt evalset with real Paper boots is already the only plugin-generation eval I could find. Publishing it (with the functional oracle from card 1) would be a first-mover asset (U: owner decision).

### (b) Static analysis / verification for Java and Paper plugins

| Project | Stars | Last push | Licence | Verdict |
|---|---|---|---|---|
| https://github.com/MockBukkit/MockBukkit | 755 | 2026-10-14 | MIT | Adopt (card 3). Maven Central: `mockbukkit-v1.21` 4.116.3 (2026-08-19), `mockbukkit-v26.1.2`, `mockbukkit-v26.2` 4.117.0 (2026-10-06) (V). Unimplemented ops throw `UnimplementedOperationException` (skip, not fail). |
| https://github.com/ast-grep/ast-grep | n/a | 2026-10-13 | MIT | Adopt for structural rules + rewrites; Java is a built-in language (V-s docs). Single binary, YAML rules. |
| https://github.com/tree-sitter/tree-sitter-java | 277 | 2026-09-13 | MIT | npm `tree-sitter` 0.25.1 MIT, `web-tree-sitter` 0.27.1 MIT, `tree-sitter-java` 0.23.5 MIT (V). Native Node use in the build service (cards 2, 4). |
| https://github.com/google/error-prone | 7,251 | 2026-10-14 | Apache-2.0 | Needs JDK 21+ and `--add-exports/--add-opens` flags (V-s docs). Best for type-aware checks (is this receiver a `World`?). Heavier than tree-sitter; second step. |
| https://github.com/pmd/pmd | n/a | 2026-10-11 | BSD-style | XPath-authored rules over the AST, no JVM compiler hooks. Alternative to ast-grep if we want a JVM tool. |
| https://github.com/spotbugs/spotbugs | 3,954 | 2026-10-13 | LGPL-2.1 | Bytecode bug patterns; external tool only. We already scan bytecode ourselves. Low. |
| https://github.com/semgrep/semgrep | n/a | 2026-10-14 | LGPL-2.1 (engine) | Pattern rules in Java; run as external CLI only; heavier than ast-grep. Alternative. |
| https://github.com/openrewrite/rewrite | n/a | 2026-10-14 | Apache-2.0 (core; some Moderne recipes under a different licence, U) | JVM refactoring recipes for API migrations. Later, for imports porting. |
| https://github.com/javaparser/javaparser | 6,161 | 2026-10-12 | NOASSERTION; README fetch 404 | Licence not verified by me (believed dual LGPL/Apache, U). Drop in favour of tree-sitter. |
| https://github.com/PaperMC/PaperLib | 285 | 2024-12-21 | MIT | **Archived**. Not needed; Cyrus targets exact versions. Note: no Bukkit/Paper-specific linter exists in Error Prone/SpotBugs/Checkstyle (WebSearch, no hit). The rules Paper documents as "not API" (do not implement non-extension interfaces, do not construct events, do not use `Simple*`) are pattern-matchable and none are in our 55 rules (U; check). |

### (c) Datapack / resource pack toolchains and validators

| Project | Stars | Last push | Licence | Verdict |
|---|---|---|---|---|
| https://github.com/SpyglassMC/Spyglass | 477 | 2026-10-14 | MIT | npm `@spyglassmc/core` 0.4.57, `java-edition` 0.3.70, `mcdoc` 0.3.61, `language-server` 0.4.70 (bin `spyglassmc-language-server`), all MIT, modified 2026-10-13 (V). Headless use via the core Service needs a spike (U). Card 9. |
| https://github.com/SpyglassMC/vanilla-mcdoc | 58 | 2026-10-14 | MIT | Version-aware schemas for datapack/resource-pack JSON and NBT; data source for a thin validator if Spyglass embedding is awkward. |
| https://github.com/mcbeet/beet | 304 | 2026-10-14 | PyPI shows no licence field (repo says MIT per BD); PyPI `beet` 0.119.1 requires Python >=3.14 (V) | Pack generation/merge pipeline; **no built-in validator** (V-s README). Python 3.14 requirement is a build-image burden. Reference. |
| https://github.com/mcbeet/mecha | 55 | 2025-12-08 (archived) | MIT | mcfunction parser/linter library; archived, last PyPI 0.106.0 (V). Reference for grammar only. |
| https://github.com/misode/misode.github.io | 923 | 2026-10-14 | MIT | Generators; mine schema edge cases, not the UI. |
| https://github.com/misode/mcmeta | 632 | 2026-10-13 | none | Version-controlled vanilla generated data; facts (ids, tags) only, as already used. |
| https://github.com/ComunidadAylas/PackSquash | 862 | 2026-10-14 | **AGPL-3.0** | Optimiser; reject for embedding. Cyrus's zip writer is already deterministic. |
| https://github.com/packwiz/packwiz | 1,022 | 2026-10-14 | MIT | Only if Cyrus ships client modpacks (it does not). |
| https://github.com/Gamemode4Dev/GM4_Datapacks | 137 | 2026-10-07 | GPL-3.0 | Quality reference for modular packs; do not copy. |

### (d) Model / animation / texture tooling

| Project | Stars | Last push | Licence | Verdict |
|---|---|---|---|---|
| https://github.com/toxicity188/BetterModel | 348 | 2026-10-14 | MIT | Already the creature engine. Pin 2.2.0; 3.x needs Java 25 / 26.x (tracker 55). |
| https://github.com/JannisX11/blockbench | 6,057 | 2026-10-10 | GPL-3.0 | The `.bbmodel` JSON format is the interchange; run Blockbench only as an external tool, never embed code. |
| https://github.com/JannisX11/blockbench-plugins | 184 | 2026-10-10 | none at repo level (per-plugin) | Reference for animation helpers. |
| https://github.com/bs-community/skinview3d | n/a | 2026-05-02 | MIT | Skin viewer; a possible preview for player-skin items. Low. |
| https://github.com/Orama-Interactive/Pixelorama | n/a | 2026-10-14 | MIT | Pixel editor; reference for palette and onion-skin UX. Low. |
| https://github.com/InventivetalentDev/minecraft-assets | 845 | 2026-10-14 | none (vanilla assets, Mojang copyright) | Never ship; private diff reference only. |
| https://github.com/Mojang/bedrock-samples | 1,773 | 2026-10-02 | LICENSE.md: "(c) Mojang AB. All rights reserved", EULA applies (V) | Reference only; not redistributable. |

Procedural texture and pixel art: no open-licence generator beats the in-house DSL (palette ramps + ops + quality bar). UM's contribution is the **vision look** step (U10), not a library.

### (e) Sound / audio

| Project | Stars | Last push | Licence | Verdict |
|---|---|---|---|---|
| https://github.com/KilledByAPixel/ZzFX | 801 | 2026-10-01 | MIT | 20-parameter procedural SFX in about 1 KB; compare parameter ranges with `synth-params.ts`. Idea source for new presets. |
| https://github.com/chr15m/jsfxr | 456 | 2026-05-05 | Unlicense | sfxr port; mutate/randomize operators for variant generation. |
| https://github.com/Tonejs/Tone.js | n/a | 2026-10-04 | MIT | Browser synth framework; useful only for the Sound Studio preview, not the renderer. |
| CC0 sets | | | | Kenney, OpenGameArt CC0, FSD50K CC0 half: already in the staging library (tracker section 4). No new open source found that beats it. |

### (f) Runtime safety / performance

| Project | Stars | Last push | Licence | Verdict |
|---|---|---|---|---|
| https://github.com/lucko/spark | 1,343 | 2026-10-07 | GPL-3.0 | Run as an external plugin only inside Test Flight (never ship, never copy). `/spark profiler start --timeout N --only-ticks-over 50`, `stop --save-to-file`, `/spark health show --memory` (V-s docs). Use `health show` text for the soak verdict; parse the file only with our own reader (format not documented on that page). |
| https://github.com/async-profiler/async-profiler | 9,164 | 2026-10-14 | Apache-2.0 | CPU/alloc flame for a worst-offender investigation on node-2. Admin tool, not product. |
| https://github.com/YouHaveTrouble/minecraft-optimization | 2,878 | 2026-09-17 | none | Facts source for rules (entity limits, view distance); no copying. |
| https://github.com/PaperMC/Folia | 4,489 | 2026-09-22 | GPL-3.0 | 81 of 173 reference plugins carry a Folia tag (BN S0). Bet: a scheduler shim so generated plugins declare `folia-supported`. Not now. |

### (g) Prompt / knowledge techniques

| Project / paper | Stars | Last push | Licence | Verdict |
|---|---|---|---|---|
| https://github.com/Aider-AI/aider | 49,551 | 2026-05-22 | Apache-2.0 | Repo-map: tree-sitter signature outline ranked by relevance, fed to the model so it does not read whole files. Idea for card 2. |
| https://github.com/SWE-agent/SWE-agent | 20,553 | 2026-10-12 | MIT | Agent-computer interface design (few, concise tools, linted edits that reject syntax errors). We already have Read/Write/Edit only; idea: reject an edit that does not parse (tree-sitter) before it costs a javac round. |
| De-Hallucinator, arXiv 2401.01701 (Eghbali, Pradel; v3 2024-06-19) | n/a | n/a | paper | Retrieve API references related to the first draft, re-prompt; +23-51% edit distance, +63% fixed hallucination-failed tests (V-s abstract). Card 7. https://arxiv.org/abs/2401.01701 |
| https://github.com/microsoft/LLMLingua | 6,755 | 2026-09-10 | MIT | Prompt compression. Reject for sheets: exact signatures must not be paraphrased; always-on prompt is only ~10k tokens (BL). |
| https://github.com/vllm-project/vllm | n/a | 2026-10-14 | Apache-2.0 | Speculative decoding / prefix caching exist **only when self-hosting**. Cyrus uses hosted Claude, so not applicable now; long-term bet (section 6). |
| https://github.com/multi-swe-bench/multi-swe-bench | n/a | 2025-12-18 | Apache-2.0 | Java issue-fix benchmark; not Paper-specific. Skip. |

### (h) Cross-loader / Bedrock (future second lane)

| Project | Stars | Last push | Licence | Verdict |
|---|---|---|---|---|
| https://github.com/GeyserMC/Geyser | 5,911 | 2026-10-14 | MIT | Reaches Bedrock players on the Java server Cyrus already targets. Custom items via JSON mappings (format v2) or `GeyserDefineCustomItemsEvent`; Geyser does **not** convert Java packs (V-s docs), so a Bedrock pack is still needed. |
| https://github.com/GeyserMC/Floodgate | 696 | 2026-09-17 | MIT | Detect Bedrock players; already planned (Pack Loader). |
| https://github.com/GeyserMC/PackConverter | 165 | 2026-10-14 | MIT | Java->Bedrock **textures only**, "work in progress, do not use in production" (V-s README). Not yet. |
| https://github.com/jaredlll08/MultiLoader-Template | 769 | 2026-10-01 | CC0-1.0 | Best template if a Fabric/NeoForge lane ever opens. |
| https://github.com/architectury/architectury-loom | 151 | 2026-09-12 | MIT | Gradle plugin; ok. |
| https://github.com/architectury/architectury-api | 450 | 2026-10-09 | LGPL-3.0 | Reference only (LGPL). |
| https://github.com/Bedrock-OSS/regolith | 108 | 2026-07-17 | MIT | Bedrock add-on compiler pipeline (filters). Only for a real Bedrock-add-on lane. |
| https://github.com/Mojang/minecraft-scripting-libraries | 55 | 2026-10-14 | MIT | `@minecraft/server` typings for Bedrock Script API. |
| https://github.com/Blockception/minecraft-bedrock-language-server | 22 | 2026-10-09 | BSD-3-Clause | Bedrock JSON validation (Spyglass analogue). |

### (i) Mod discovery / dependency / compat databases

| Source | Facts | Verdict |
|---|---|---|
| Modrinth API https://docs.modrinth.com/api/ | 300 req/min per IP; unique `User-Agent` required; project, version, dependencies, tags (loaders, game versions, licences); **version by file hash and bulk latest-by-hash** endpoints (V-s). Code monorepo `modrinth/code` is mixed/AGPL (NOASSERTION), API use only. | Card 12. |
| Hangar https://github.com/HangarMC/Hangar | MIT, last push 2026-10-12 (V). REST docs page is JS-only (not readable by me, U). | Card 12, verify endpoints in a spike. |
| Spiget | not verified (docs repo guess did not exist). | Drop until verified. |
| https://github.com/siom79/japicmp | Apache-2.0, last push 2026-10-03 (V). Compares two jars, reports API breaking changes. | Card 15. |
| https://github.com/PrismarineJS/minecraft-data | 953 stars, 2026-10-13, no licence field | Facts source only; Paper jar already authoritative. |

## 4. Adoption cards (top 15)

Each card: problem, plan (Cyrus file/module), effort, risk, licence verdict, measurement. Measurement uses the existing eval (`scripts/cyrus/eval-run.ts`, baseline fourth1 / fifth1) unless stated. Never run a card against a customer server.

### Card 1. Functional acceptance oracle in the eval
- **Problem.** fourth1: playtest 90 not run, quality 21 not run. A 100% boot rate cannot tell a mod that does the job from one that boots and does nothing (the ChunkMirror lineage in tracker 58b booted every time while the mirroring code was missing).
- **Plan.** Reuse what exists: 54 golden plugins with RCON expectations (`services/modbuilder/golden/plugins/*/golden.json`, V: BL notes "54 of 63 plain archetypes have a golden"), the survival bot (BE), `eval/rt-bot.js`, `eval/rtcheck.py`. Per evalset prompt add `accept: [{rcon|bot step, expect}]`; the runner executes them after boot and scores `behaves` separately from `final pass`. Start with the 40 plain/gameplay/stateful prompts (not assets). Use UM "prove the requirement" (action without precondition must be refused, then granted, then succeed). Report `behaves` per lane next to pass@1.
- **Effort** M. **Risk** low (flaky bot steps: judge CPU-aware as in BE; counted apart). **Licence** own code + mineflayer MIT; MineCEraft (programmatic verification per instruction) is idea only.
- **Measure.** New headline "behaves@1"; expected to be 10-30 points below pass@1 (U) and to re-rank the next fixes. Mutation-check the new assertions with one-defect builds (UM U3).

### Card 2. Workspace map for change builds
- **Problem.** Change builds are 44% of spend and 12-31 turns (BL). The change prompt only says "Read the existing files you need first".
- **Plan.** In `services/modbuilder` add `workspacemap.js`: tree-sitter-java parse of every `.java` in the base workspace -> JSON/markdown of package, class, extends/implements, public/private method signatures (names + params, no bodies), `@EventHandler` events, commands from plugin.yml, permissions, config keys with defaults, assets/designs list, `modbuilder.json` "changes". Cap about 2-3k tokens; inject in `changePrompt` before `<request>`. Keep "read files you need" but now targeted. Order of the prompt stable for cache hits.
- **Effort** S-M. **Risk** low; wrong map = same as today. **Licence** tree-sitter + tree-sitter-java MIT (V npm); aider's repo-map is an idea (Apache-2.0).
- **Measure.** Same 20 change prompts (`eval/sets/change.jsonl`) with/without: turns, $, first-try pass, and regression guard hits (lost commands). Expect turns -20% (U).

### Card 3. MockBukkit pre-flight smoke in the build service
- **Problem.** "Build succeeded" then "did not load" (rc12 goblin: missing depend; rc9-rc11 fixed by autofix, but NPE in onEnable, null `getCommand`, missing config key, `NoClassDefFound` on a soft dependency are still discovered only by the minutes-long async Test Flight, after settlement).
- **Plan.** After javac+scan, generate (deterministically, no model) a JUnit-less runner class: `MockBukkit.mock()` -> `MockBukkit.load(MainClass)` -> for each plugin.yml command run it as a mock player with 0 args and with a sample arg -> fire the top 10 events the plugin registers via `PluginManager` (collected from `@EventHandler` signatures) -> `server.getScheduler().performTicks(200)` -> assert no exception in the plugin logger, config keys read, `onDisable` clean. `UnimplementedOperationException` = skipped check, never a failure. Run in a throwaway JVM with no network, tight CPU/RAM, inside the build service container; result becomes a repair-loop signal (deterministic first, model only if it fails). Artifacts: `mockbukkit-v1.21` 4.116.3 (covers 1.21.x? U: verify on 1.21.1/4/8/11), `mockbukkit-v26.2` 4.117.0.
- **Effort** M. **Risk** medium: it executes model-written code on the build host (the scan gate already limits capabilities; still use a subprocess with seccomp/timeout; Test Flight remains the real gate). MockBukkit lags newest Paper API (README targets 26.2; 1.21 on a separate artifact).
- **Licence** MIT (V). 
- **Measure.** Replay all 254 stored build records + fourth1 jars: how many Test Flight failures it predicts, false-red rate, wall time (target under 10 s), and cost saved by failing before settlement.

### Card 4. AST rules and rewrites (perf-spawn-in-loop and API shapes)
- **Problem.** perf-spawn-in-loop: 11 hits across first1..fourth1, 6-7 of 17 first-try misses in fourth1. Detection is `re:/\.(spawn...)\(/` with `ctx:"loop"` and the fix handles "the plain braced shape" only (BS section 2.1). Lambdas, streams, nested helper methods and `forEach` slip through or fall to a model repair.
- **Plan.** `services/modbuilder/astrules.js` using `tree-sitter` + `tree-sitter-java` (or ast-grep as a subprocess with YAML rules, one file per rule, easier for the owner to audit). Rules first: spawn/drop/summon inside `for`/`while`/`forEach`/lambda bodies reachable from an event or scheduler task; unbounded `runTaskTimer` with no cancel; `getNearbyEntities` in `PlayerMoveEvent`; sync `getChunkAt` in loops; non-extension interface implemented (Paper "not API" rules). Rewrite to the `NxPerf` bounded call where the receiver type is certain (fall back to message for the model otherwise). Keep the regex path as a second line.
- **Effort** M. **Risk** low (type info is syntactic only; Error Prone adds types later, needs JDK 21+ and `--add-exports` flags, V-s). **Licence** MIT (tree-sitter, ast-grep); Error Prone Apache-2.0.
- **Measure.** Unit fixtures from the 11 stored hits; then eval texture + sound lanes (they were the carriers): count of `perf` repairs per 90 builds before/after; false-fix rate by diffing jars.

### Card 5. Requirements ledger (cross-version)
- **Problem.** Owner re-requests within 30 minutes cost 23% of spend (BJ); builds that dropped commands $1.30; ChunkMirror lineage lost its mirroring code through a lane flip (tracker 58b). UM's MODLOG idea is exactly a persistent "facts, dead ends, rules" file.
- **Plan.** Model writes `requirements.json` in `modbuilder.json`: `[{id, text, evidence:{kind:"command|config|event|class|permission|asset", ref}}]` (about 100-200 tokens). Deterministic checker confirms each evidence ref exists in the jar/yml; a missing ref is a repair message, not a refusal. Persist per lineage; change builds receive the ledger and must keep every requirement unless the user text removes it (extends the existing "regression guard vs base build"). Surface in the portal as "what this mod does (checked)".
- **Effort** S. **Risk** low (more output tokens, small). **Licence** own; idea from UM (MIT).
- **Measure.** Dropped-feature rate on `eval/sets/change.jsonl`; rework within 30 min from the learning loop.

### Card 6. Latency package
- **Problem.** "8-minute generation"; planning = 51% of wall time, coding 40%, repairing 9% (BJ); change builds 17 turns per call at about $0.015/turn; cold prefix 12-28k tokens.
- **Plan (in order, each separately measurable).** (a) `MB_EFFORT` A/B: it exists in `server.js` (line 181, `--effort`) and is unset; run plain+gameplay lanes at `medium` and `low` (Haiku unaffected). (b) Plan-from-recipe: for archetypes with a verified recipe/golden, give the model the skeleton and ask only for deltas (recipes dir has 10; BL planned this behind flags). (c) Keep-warm: a Haiku no-op ping inside the 1 h cache TTL when a user session is active (U: measure cacheRead share first, BL section 9). (d) Lane-parallel sessions: texture/sound/design specs generated by separate calls in parallel with the plugin code, merged by keys; coherence risk is the S1 sound-key class (BP), so the spec keys must be fixed by the plan before the fan-out. (e) Not applicable: speculative decoding / prefix caching need a self-hosted model.
- **Effort** S for (a), M (b), S (c), L (d). **Risk** medium for (d). **Licence** n/a.
- **Measure.** Wall time p50/p90 and cost per pass by lane over 30 fixed prompts, same image, quality gates unchanged (pass@1 must not drop).

### Card 7. Member index, did-you-mean, iterative grounding
- **Problem.** Single hallucinated names still reach javac and cost a model repair: `ConsumableEffect`, `Material.SMITHING_TEMPLATE` (BT), `Collection->List`, `GENERIC_` prefixes. Autofix already handles packages and renames when the real jar has exactly one answer.
- **Plan.** From the existing per-version javap pass (`sheets/verify-api-facts.py`) emit `members-<version>.json`: for each public type in `org.bukkit`, `io.papermc`, `net.kyori`: methods (name, params, return), fields, enum constants. (1) Extend `autofix.fixCompile`: for "cannot find symbol: method/variable/constant X in Y" propose the unique nearest candidate by (edit distance, arity, return type) only when unambiguous. (2) Otherwise append to the repair prompt the member list of the failing receiver type (60-200 tokens) so the repair is one turn. (3) Optional pre-compile grounding: after the first draft, extract referenced types, inject their members, ask only for corrections (De-Hallucinator, arXiv 2401.01701).
- **Effort** M. **Risk** low (index generated from the real jar). **Licence** own code; paper-api is GPL-3.0 (GAPS S12): store only names/signatures as facts, as the sheets do today.
- **Measure.** Replay the compile-error corpus (all `error:` lines in the 254 records): share fixed deterministically, repair turns and $ saved; new hallucination rate stays covered by the eval.

### Card 8. Headless real-client smoke
- **Problem.** Tracker section 5: "No real Minecraft client has loaded a pack, texture, sound or model"; creature look/animation unverified; texture lane quality is numeric only.
- **Plan.** Fabric client game tests (`fabric-client-gametest-api-v1`, 1.21.4+, simulated input, screenshot comparison, per the UM technique note, V-s) on node-2 under Xvfb with software GL. Scenario: join the Test Flight server with the build's resource pack, `/give` the item, hold it, screenshot; compare with a vanilla baseline (differs = the pack loaded) and fail on client log lines `Missing texture` / `Failed to load`. Pack-load errors in the client log are the real signal, which the server flight cannot see. Start with a single golden item and one creature.
- **Effort** L. **Risk** medium: Mojang EULA/usage guidelines for automated QA are parked in the tracker (legal); Linux software rendering speed and memory (node-2 build slice 13 GB); Fabric client version pins per MC version.
- **Licence** Fabric API Apache-2.0 (V from BD: loader Apache-2.0), Loom MIT; Minecraft client is Mojang-owned (download at run time, never redistribute).
- **Measure.** Share of builds where the client log shows zero pack errors; number of items whose screenshot differs from vanilla; time per check.

### Card 9. Spyglass headless validator
- **Problem.** Datapack, worldgen and designer JSON errors surface at server boot (Test Flight) or as the owner's "datapack reload failed" (r35 found a real 1.21.9+ import bug).
- **Plan.** Spike: Node script using `@spyglassmc/core` + `java-edition` + `mcdoc` (MIT, V npm) with `vanilla-mcdoc` for the target version; run on `data/` and `assets/` trees of every pack Cyrus emits, output diagnostics as repair messages. Fallback if embedding is awkward: JSON-schema layer from mcdoc. Keep Cyrus's own checks (`datapack-spec.js`) as is; this is a second opinion that is version-aware.
- **Effort** M. **Risk** low-medium (26.x coverage U; start with 1.21.x). **Licence** MIT.
- **Measure.** Corpus of the 141 reference datapacks (private, BA): false-positive rate must be near zero on real packs; catch rate on mutated copies.

### Card 10. Cheap repair ladder and circuit breaker
- **Problem.** Repair spend is 14-31% of cost in several runs; BL row 6: the cheap first repair is "not active on tier builds" because `rec.override` is set. No same-signature detector found by grep.
- **Plan.** (1) Normalise each failure to a signature (error class + symbol + file) and stop re-asking the model for the same signature after two tries: escalate (one tier up, already exists) or return a plain "could not fix" plus partial result (user rule "warn, don't block"). (2) Re-enable the Haiku `--resume` first repair for small compile errors on tier builds when the estimate says it is cheaper. (3) UM 3x rule as the cap.
- **Effort** S. **Risk** low. **Licence** own.
- **Measure.** Repair share of spend, repaired-build cost multiple (fourth1: 1.87x), final pass unchanged.

### Card 11. Typed-spec compilers for more archetypes
- **Problem.** Only 18 of 85 archetypes use a typed spec; typed specs save 70-90% of code tokens per hit and remove failure classes (BL). Designer lanes are where "no design" and hallucination vanish.
- **Plan.** Pick the 8 most requested non-designer archetypes from the learning loop (homes/warps, cooldown abilities, economy shops, chat formats, scoreboard/tab, rewards) and define specs + a Java emitter (JavaPoet for correctness: imports, escaping, no string-concatenated code; the r32 audit found Java-code injection via names). Reuse the designer compile path (`lib/cyrus/designer/compile.ts`) and NxPerf bounded wrappers.
- **Effort** L. **Risk** medium (spec expressiveness; BT showed forcing a design lane on a tab-list mod is harmful, so keep "plain" as a fallback). **Licence** palantir/javapoet Apache-2.0 (V, last push 2026-10-14).
- **Measure.** Tokens and $ per build for those archetypes, behaves@1 (card 1), and share of user prompts matched.

### Card 12. "Already exists?" and compat lookup
- **Problem.** Owner rule: capability disclosure before credits are spent; many requested mods exist as free plugins; soft-depend correctness is guessed from a small table (`deps.json`).
- **Plan.** Plan screen adds a read-only panel: top 3 Modrinth/Hangar matches (name, downloads, licence, Paper versions) via search, with "Build mine anyway". Use the Modrinth `version_file` hash endpoints in the Import lane to resolve a dropped jar to project/version and its declared dependencies (replaces guessing). Cache 24 h; unique User-Agent; 300 req/min limit (V-s). Never auto-install third-party plugins.
- **Effort** M. **Risk** low; product risk: sends users away (the owner decides). **Licence** API ToS (modrinth.com/legal/terms); Hangar MIT.
- **Measure.** Share of plans where the user continues; refunds/complaints; import dependency resolution accuracy.

### Card 13. Release lint (UM publish check, reimplemented)
- **Problem.** Outputs ship packs, sounds and models; the CC0 library takes automatic contributions; imports bring third-party code. IP and secrets hygiene should be a deterministic gate.
- **Plan.** `lib/cyrus/safety/release-lint.ts`: (a) size+SHA-1 match of every pack/jar entry against the vanilla reference index (AM has the 26.1.2 index) and against known third-party plugin jars from the import list; (b) secret patterns from `um/publish.py` list; (c) decompiler fingerprints in source/yml (`FUN_xxxx`, `sub_XXXX`, "Decompiled with"); (d) absolute user paths; (e) missing licence/credits in imports. Output = warnings; block only (a) on library contribution and on Install of imports flagged as copies. UM's own comment: "a lint, not legal advice".
- **Effort** S-M. **Risk** low. **Licence** UM MIT; reimplement, do not vendor Python.
- **Measure.** Detection on seeded fixtures; zero false blocks on the 386 reference items' own metadata.

### Card 14. Evidence levels and "skipped never passes"
- **Problem.** Verdict words overstate: "succeeded" with a failed flight (rc12), "boot 100%" while the stress phase / playtest is not run, `quality 0.998` computed over 49 of 90 builds.
- **Plan.** Add `evidence: synthetic | static | flown | client` to every check record (Test Flight, eval stages, portal chips), UM table wording. Eval report: print coverage next to every percentage ("quality 0.998 over 49/90"); a `not_run` can never contribute to a pass count (assert in `eval-run-lib`). Audit the pass-rate page for the same.
- **Effort** S. **Risk** low. **Licence** UM MIT (idea).
- **Measure.** Review of the page and report; unit test that fails if a skipped stage increments pass.

### Card 15. Release-day API diff pipeline
- **Problem.** New Paper builds rename things (Attribute prefixes, GameRule -> GameRules in 1.21.11, 26.x); rules were found by hand after failures (`attr-generic-prefix-*`, `gamerule-constants-1-21-11`). The 26.x lane is coming (R0).
- **Plan.** Script: download consecutive `paper-api` jars from the Paper Maven repo, run `japicmp` (Apache-2.0, V) in report mode, filter to types in the member index (card 7), emit a candidate `failure-rules.json` entries + `autofix` rename table + sheet delta for human review (never auto-merged; same discipline as the learning loop). Runs when a new version appears in `versions/registry.json`.
- **Effort** M. **Risk** low. **Licence** japicmp Apache-2.0 as a build-time tool; paper-api is GPL-3.0, so only names go into rules, as today.
- **Measure.** On the 1.21.4 -> 1.21.8 -> 1.21.11 triplets: fraction of the existing 55 rules (renames) that the diff would have proposed; time to add a version.

## 5. Quick wins (no new dependency; prompt, knowledge, rules, process)

| # | Change | Evidence | Where |
|---|---|---|---|
| Q1 | **Fix the eval's lane labels before trusting lane recall 30%.** fourth1/fifth1 score `cov-tablist`, `cov-warps`, `cov-playtime-rewards`, `cov-bossbar-titles` as expected designHud/designMenu/designQuest, but BT showed the designer repair for exactly these builds was harmful and the rc11 policy correctly downgrades them to plain. fifth1 then counts them as "assets: no asset result" failures. Relabel to plain or mark the stage "not applicable" | BT section 2; fifth1 report | `services/modbuilder/eval/prompts.jsonl`, `coverage.jsonl`, `scripts/cyrus/eval-run-lib` |
| Q2 | Mark `not applicable` vs `not run` as different eval stage states | fifth1: 4 of 5 asset "fails" are N/A | eval-run-lib |
| Q3 | `config.yml` merge rule: on change builds, new config keys must be added to existing servers (`copyDefaults(true)` + `saveConfig`, or add-missing-keys step); add a failure rule + recipe line | UM `engines/minecraft.md` "changed default never reaches existing users" (V-s); Paper analogue is U, check against Cyrus delivery "values-only revisions" | failure-rules.json, prompts.js |
| Q4 | Rules from Paper's own "not API" list (do not implement non-extension interfaces, do not construct events, avoid `Simple*` classes) as 3 failure rules (U: check overlap with `no-server-internals`) | Paper javadoc statement via WebSearch | failure-rules.json |
| Q5 | Prompt: write `plugin.yml` `api-version` and `depend` in the first Write; keep the "write design FIRST" line but drop the "if nothing fits write an ordinary plugin" escape hatch **only for the four chosen lanes where a design is expressible** (BT found the escape hatch was correct for tab list/warps) - i.e. keep rc11 policy; no change | BT | n/a |
| Q6 | Evidence words in the portal and eval reports (card 14 wording only) | U1 | docs |
| Q7 | Eval triage protocol: a second agent re-derives each red from raw journals before any code change; write "what the fix gives up" in the report | U2 | agent briefs COMMON-RULES |
| Q8 | `MB_EFFORT=medium` A/B run on plain+gameplay lanes (no code) | server.js line 181 | env |
| Q9 | Stable prompt order: put the volatile `<request>` last (already), keep sheet/rules/lane blocks byte-stable per version; log first-turn cacheRead/cacheWrite split (BL section 9 "measure first") | BL | prompts.js, journal |
| Q10 | Ingest https://github.com/PaperMC/docs (BSD-2-Clause) dev pages as a diff source against the 55 rules and sheets; facts only, rewrite in our words | repo verified, 75 stars, 2026-10-09 | research agent |
| Q11 | Publish the Cyrus evalset (178 prompts) and methodology as an open benchmark after card 1: no Paper plugin-generation benchmark exists (WebSearch, arXiv) | section 3a | marketing / owner |
| Q12 | Add a journal line to every build record: `requirements` missing-evidence list (cheap version of card 5) | card 5 | server.js record |

## 6. Long-term bets

1. **Bedrock reach through Geyser** (MIT): Cyrus knows each item's base item, `custom_model_data` and texture, so it can emit Geyser custom-item mapping JSON (v2) next to the Java pack; the Bedrock resource pack is still required (Geyser does not convert packs, V-s) and PackConverter is texture-only WIP. Honest "Bedrock players see X" panel first (GAPS item 14), emitter later.
2. **Fabric/NeoForge server-side lane** with MultiLoader-Template (CC0) once Paper is boring; Fabric client game tests (card 8) are the oracle.
3. **Self-hosted small repair model** (vLLM, Apache-2.0: speculative decoding, prefix caching) trained on Cyrus's own repair pairs from the learning loop (never user code, per owner rule); only worth it at volume.
4. **Folia-ready output** via a scheduler shim, once the plugin market share justifies it (81/173 reference plugins tag Folia).
5. **Open benchmark + public leaderboard** (Q11) as the credibility asset; pairs with the pass-rate page.
6. **Vision critic** for textures and creature turntables (UM U10): Haiku looks at a 6x contact sheet with a checklist; keep numeric gates as the floor.
7. **Knowledge as a plugin** (UM U14): publish clean sheets/rules as a Claude/Codex plugin for community goodwill and SEO, after the licence review of facts vs paper-api GPL.

## 7. Rejected list (with reasons)

| Item | Reason |
|---|---|
| PackSquash (AGPL-3.0) | AGPL; our zip writer is deterministic; do not embed or link. |
| pickaid/mc-developing-mcp | Noncommercial licence per search snippet; 2 stars. |
| minecode-mcp, blockbench-mcp-plugin (GPL-3.0) | GPL; reference only; we do not edit in Blockbench. |
| Blockbench itself (GPL-3.0) | Never embed; `.bbmodel` is a data format. |
| GM4_Datapacks (GPL-3.0), Folia (GPL-3.0), spark (GPL-3.0) as code | Not copied; spark only as an external plugin in Test Flight. |
| architectury-api (LGPL-3.0) | LGPL; reference only. |
| SpotBugs (LGPL-2.1), Semgrep engine (LGPL-2.1) | LGPL tools, little new over tree-sitter/ast-grep; external CLI only if ever. |
| javaparser | Licence could not be verified (README 404, API NOASSERTION); tree-sitter covers the need. |
| PaperLib | Archived (last push 2024-12-21); Cyrus targets exact versions. |
| beet / mecha | Python 3.14 requirement for beet; no validator; mecha archived 2025-12-08. Reference only. |
| LLMLingua | Compressing exact API sheets risks wrong signatures; always-on prompt is only about 10k tokens. |
| Speculative decoding, prefix caching (vLLM, SGLang) | Only for self-hosted models; Cyrus uses hosted Claude. Bet only. |
| Voyager | Stale (last push 2024-04-03); Minecraft agent, not plugin generation. |
| minecraft-assets, bedrock-samples, mcmeta as shipped content | Mojang copyright / no licence; private reference only. |
| um fal / comfy (UM) | Paid fal.ai and closed models; owner library is CC0-only. |
| MC-Bench (voting site) | Could not resolve the domain (mcbench.ai ENOTFOUND); not a code benchmark anyway. |
| Spiget | Docs repo guess did not exist; not verified. Dropped. |
| UM native-hook, proxy-DLL, Windows-input, anti-cheat playbooks | Not our surface (hosted Paper lane). |
| agentic-awesome-skills `minecraft-bukkit-pro` | Content not read; MJP-Paper-Skills already vendored and higher quality. |
| MineCEraft as a benchmark to run | World-building tasks, no released data found; idea only. |

## 8. What I could not verify (so nothing here is fabricated)

- Stars for ast-grep, semgrep, openrewrite, pmd, Pixelorama, skinview3d, multi-swe-bench, Tone.js, Hangar, javapoet, vllm, japicmp (API quota).
- Whether `mockbukkit-v1.21` exercises 1.21.11 APIs (artifact exists; coverage is U). Whether Spyglass core can run headless without the language-server (docs page silent; npm packages exist; spike needed).
- Error Prone custom-check/patching docs (page not fetched). japicmp output format vs Paper jars (U).
- Hangar REST endpoints (JS page), Modrinth bulk hash endpoint exact hash type.
- MineCEraft data/code link. Any Paper-specific Error Prone/SpotBugs plugin (none found, absence not proof).
- The "8-minute" figure is the owner's; fourth1 says asset builds 4-5 min, BJ planning 51%; I did not re-measure wall time.

## 9. Summary (15 lines)

1. Cyrus is past the "obvious tools" stage: BD/BF/BN already mined the Minecraft-relevant facts; the remaining gains are measurement, structure and speed.
2. Biggest gap: eval stages `playtest` 90/90 not run; pass@1 76.7% and boot 100% say "compiles and boots", not "does the job". Card 1 (functional oracle) first.
3. Change builds are 44% of spend with no workspace map; tree-sitter-java (MIT) outline fixes that cheaply (card 2).
4. Line-regex perf/API rules are why perf-spawn-in-loop keeps recurring; ast-grep/tree-sitter AST rules + rewrites (card 4).
5. MockBukkit (MIT, `mockbukkit-v1.21` and `v26.2` on Maven Central) as a seconds-long pre-flight before the async Test Flight (card 3).
6. Requirements ledger persisted across versions kills dropped-feature and lane-flip regressions (card 5).
7. Latency: planning is 51% of wall time; `MB_EFFORT` is unset and untested; recipe-skeleton planning and lane-parallel sessions follow (card 6).
8. Hallucinated API: javap member index + did-you-mean + De-Hallucinator-style grounding (card 7); japicmp release-day diff (card 15).
9. Real-client headless smoke (Fabric client game tests on Xvfb) is the only route to "a client loaded the pack" (card 8; legal parked).
10. Spyglass npm packages are MIT and fresh (2026-10-13): version-aware datapack/resource-pack validation (card 9).
11. No public Paper-plugin generation benchmark exists; publishing the 178-prompt evalset with a behaviour oracle is a credibility asset.
12. UM's real value now is method: evidence levels, "suspect the oracle", mutants for the eval harness, circuit breaker, MODLOG ledger, publish-check lint.
13. Quick win Q1: fix eval lane labels (4 designer prompts are mis-expected); fifth1's asset "fails" are N/A, not failures.
14. Licence-clean: everything recommended is MIT/Apache/BSD; rejected for licence: PackSquash (AGPL), blockbench-mcp/minecode-mcp (GPL), mc-developing-mcp (NC), architectury-api (LGPL).
15. Report: /root/claudeskills/agent-notes/cyrus-research/BX-improvement-research-2026-10-14.md

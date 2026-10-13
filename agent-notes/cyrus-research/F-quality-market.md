# F: Quality + market research (step 7), 2026-10-10

Pages opened: 15 of 16 cap. Labels: VERIFIED (url) = opened; UNVERIFIED = memory/inference or search snippet only. Internal facts come from BRIEF.md/G-gaps.md (owner-verified).

## 1. Competitor landscape (AI game-mod creation)

Best single source: Player Games' own comparison page (VERIFIED https://www.player.games/de-DE/best-ai-minecraft-mod-maker, "last verified 2026-07-15"). It is vendor-authored, so treat rankings as marketing; the facts about rivals are still useful.

| Product | Generates | Price | Quality evidence | Strengths | Weaknesses |
|---|---|---|---|---|---|
| **Player Games** | Fabric, NeoForge, Spigot/Paper, datapacks, Bedrock add-ons, Hytale mods | Free via Discord credits (25 on link, up to 75/day); packs from $8/500 credits (VERIFIED player.games compare + https://www.player.games/create-spigot-plugins-ai) | Claims every build is booted on a real server first and publishes a **98.2% pass rate** (VERIFIED compare page; self-reported, not independently audited). Plugins "finish in a few minutes, complex within 30" | Full source delivered; boot-validation as a headline feature; multi-loader; Hytale | No Forge; no bundled server; daily credit limits; version support not stated on plugin page |
| **Orca** (YC S24) | Fabric/Forge/NeoForge, Bedrock, Paper/Spigot | Free tier with bundled 8 GB server (40 players); Pro $19.99/mo (VERIFIED compare page) | Advertises pre-delivery testing, crash-log analysis and auto-patch (VERIFIED snippet via search; no numbers) | Describe -> reload -> play in browser, hosting included (it is both a rival studio and a rival host) | Young (June 2026 debut per compare page); best model paywalled |
| **CreativeMode** | Java + Bedrock mobs, items, blocks, structures, full mods | 300 free coins/week; Pro tier (VERIFIED creativemode.net header; compare page) | None advertised: no real-server validation, source export not advertised (VERIFIED compare page) | Community remixing, leaderboards, claimed 500k+ players (vendor claim) | Opaque quality; closed output |
| **MCreator** | Forge/NeoForge/Fabric/Bedrock via visual editor; AI only via extensions | Free, open source (VERIFIED compare page) | Decade of history | Offline, visual control, huge community | Manual assembly, desktop learning curve; AI not core (VERIFIED compare page). Details of its AI extensions: UNVERIFIED |
| **Mod Builder (stork.ai listing)** | Mods | Freemium; Pro GBP5/mo or GBP99 once (search snippet only) | Unknown | Cheap | UNVERIFIED, thin evidence |
| **BukkitCode / Bolt.new-style agents** | Whole Bukkit plugin project from chat | Unknown | Unknown | Project-level context vs one-shot chat (search snippet, UNVERIFIED) | Unknown |
| **Plain ChatGPT/Claude** | Code text | Subscription | The standing complaint is a broken-code/fix loop that "takes 30 minutes or more" (search snippet of mineacademy.org/ai-plugins-guide; page itself returned 403, so UNVERIFIED in detail) | Free-form | No compile, no test, hallucinated or outdated APIs (UNVERIFIED generally; consistent with Cyrus's own need for version sheets) |
| **Tynker** | Skins, add-ons, mini-mods | Education subscriptions | n/a | Learning | Not production (VERIFIED compare page) |

Honest gap in evidence: I found **no** Reddit/forum threads with first-hand user reviews of these tools (searches returned vendor pages and chatbot plugins only). Treat "what users praise/complain about" as vendor-positioned, not community-verified. Recommend a manual 1-hour Reddit/Discord pass before roadmap commitments.

### White space and what "number one" requires
- Rivals sell code (jar/mod) and increasingly "boot-tested" code. **None advertise** (VERIFIED absence on compare page): generated models/textures/multiple sounds as a coherent asset set, server-pushed resource packs, an editable studio for those assets, or one-click install with rollback onto the customer's own hosted server. Orca is the closest (bundled server) but ships no asset studios advertised.
- To be credibly #1 Cyrus needs: (a) a **published, reproducible pass rate** at least equal to 98% on a public prompt set, per version, including 26.x; (b) the asset pipeline (mob = model + texture + 4-6 sounds) delivered in a pack players actually receive; (c) iterate/remix on an existing mod; (d) source + undo.

## 2. Techniques that raise correctness and cut cost

Anthropic guidance (all opened):
- **Verification is the lever.** "Give Claude a check it can run: tests, a build, a screenshot"; no check means "looks done" is the only signal. Also: have an independent fresh-context reviewer subagent, scoped to correctness only, to avoid over-engineering. VERIFIED https://code.claude.com/docs/en/best-practices
- **Spec first.** Interview then write a self-contained spec naming files/interfaces, out-of-scope items and an end-to-end verification step; execute in a fresh session. VERIFIED same URL. Maps directly to a Cyrus ModSpec (missing today per G-gaps).
- **Context engineering.** Smallest set of high-signal tokens; just-in-time retrieval over loading everything; sub-agents return 1-2k token summaries; minimal non-overlapping tools. VERIFIED https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents. Implication: replace whole-sheet injection (~15 KB per version, G-gaps) with per-feature sheet slices selected from the plan.
- **Evals.** Start with 20-50 tasks drawn from real failures; code-based graders (cheap, brittle) + model rubric + human calibration; report **pass@k** and **pass^k** (consistency); read transcripts. VERIFIED https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents. SWE-bench-style = run hidden tests, pass only if target tests pass and nothing else breaks (same page).
- **Prompt caching.** Reads cost 0.1x base (0.05x on Opus/Sonnet 5.5); 5-min write 1.25x, 1-hour write 2x; min cacheable 512 tokens on 5.5-family models; breakpoint on the last identical block; changing tools, effort or thinking settings invalidates the cache. VERIFIED https://platform.claude.com/docs/en/build-with-claude/prompt-caching. Cyrus already keeps the system prompt byte-stable; check that the Claude Code CLI path actually gets cache reads (log `cache_read_input_tokens`). A 1-hour TTL suits sheets reused across a user's iteration session.
- **Effort levels** low/medium/high/xhigh/max. For Sonnet 5.5 agentic coding: start `medium` for well-specified tasks, `high` for harder ones; Haiku 5.5 default medium, `low` can skip checks; run an effort sweep on your own evals; per-message effort changes preserve the cache (beta). VERIFIED https://platform.claude.com/docs/en/build-with-claude/effort. Implication: the Haiku/Sonnet/Opus classifier should also pick effort, and a well-formed ModSpec makes `medium` viable (cost cut).

Minecraft-specific verification stack (ordered cheap to expensive):
1. Structured ModSpec + recipe selection (UNVERIFIED design; consistent with sources above).
2. Compile vs real Paper jar + auto-fix loop (already exists, G-gaps).
3. Static policy scan (exists).
4. **MockBukkit unit tests** the model writes alongside the code (or test-first from the spec's acceptance criteria). MIT licence; per-version artifacts `mockbukkit-v26.1.2` exist on Maven Central and the repo's current release is `mockbukkit-v26.2` for Paper API 26.2 (VERIFIED https://github.com/MockBukkit/MockBukkit; central listing from search snippet). **Limit:** unimplemented methods throw `UnimplementedOperationException` (VERIFIED same URL), so it cannot verify rendering, resource packs, custom entities' real behaviour or NMS-level code. Use it as a fast logic gate, not the acceptance gate. Older 1.21.x coverage: repo keeps older branches "not actively patched" (VERIFIED same URL) so 1.21.1/1.21.4 may be stale; UNVERIFIED which artifacts exist for each.
5. **Disposable headless Paper boot** ("Test Flight"): load the jar, assert no startup exceptions, run commands via RCON/console. Player Games' 98.2% claim shows rivals do this (VERIFIED compare page). Cyrus has eval/rtcheck already (eclipse-temurin:21-jre, mineflayer, per-version jars, G-gaps).
6. **Protocol bot** (Mineflayer): MIT licence and supports "Minecraft 1.8 to 26.1" including 1.21.11 and 26.1 (VERIFIED https://github.com/PrismarineJS/mineflayer; 7.6k stars, active). Good for joining, running commands, checking chat/inventory/entities/GUI windows/resource-pack prompt. Cannot see textures/models. 26.2 support: UNVERIFIED.
7. LLM-judge/screenshot review for assets (UNVERIFIED approach; needs a headless client, which is costly; defer).

Cost reduction levers (ranked): sheet slicing by plan; caching with stable prefix; effort per tier; ModSpec lets Haiku/Sonnet do routine builds; verified "recipes" (parametrised, compiled-in-CI snippets for mob/GUI/particle/recipe) so the model assembles instead of inventing; cap repair loops at 2-3 and retry from a fresh context after two failed corrections (VERIFIED best-practices page); cache identical builds (hash of ModSpec).

## 3. Test Flight practicalities

- Paper 26.1+ requires **Java 25**; docs suggest a 4 GB heap for a normal server (VERIFIED https://docs.papermc.io/paper/getting-started). A test server needs far less: 1-2 GB heap with a tiny flat world, `view-distance=2`, offline-mode, no spawn chunks beyond minimal (UNVERIFIED tuning; measure it). Note the existing rtcheck image uses Java 21 (G-gaps), so 26.x needs a second Java 25 image.
- MEASURED 2026-10-10 (Test Flight lite on node-2, -Xmx1g, flat world, offline, private netns): Paper 26.2 boot 10.6 s / peak RSS 762-803 MB; 26.1.2 10.4-10.8 s / 722-729 MB; 1.21.11 (JDK 21) 18.0 s / 878 MB; whole flight incl. RCON checks + stop 12-20 s, 2 visible CPUs. (Earlier estimate of 20-45 s and 1.0-1.5 GB was pessimistic.) A pre-generated world copied from a template and a warm Docker image keep it near the low end. On a node-2 build host this is cheap compared with the model call, but concurrency must be capped (the primary node hard-crashed from parallel builds, per memory note).
- Isolation: container, no network except loopback, read-only jar mount, CPU/mem/pids limits, hard 90 s timeout, destroy on exit. The server runs untrusted AI code, so treat it like the compile sandbox.
- Resource-pack testing needs `resource-pack` prompt acceptance from a bot; Mineflayer can observe the resource-pack packet but not render (UNVERIFIED detail).

## 4. Differentiators worth testing
- **Iterative editing ("change this mod")** on the stored ModSpec + source; rivals mostly push regenerate. Measure edit success vs full regenerate.
- **Remix** of NxLabs mods (CreativeMode has remixing/leaderboards, VERIFIED compare page; Cyrus has remix already).
- **Templates/recipes gallery** doubling as test fixtures.
- **Live preview**: one-click "try it" on a temp Test Flight server, or on the customer's own server with rollback (Cyrus already has backup + rollback; Orca's bundled test server is the rival bar).
- **Project import** (upload existing plugin source/jar for edit): UNVERIFIED demand; Mineacademy-type users (owners with existing plugins) likely want it.
- **Quality signals shown to customers**: "booted on Paper X, N tests passed, bytes scanned" badge and public pass-rate page (mirrors Player Games' differentiator).

## 5. Prioritised capability list

| # | Capability | Size | Measure |
|---|---|---|---|
| 1 | Public **eval harness v2**: 100+ prompts, per-version matrix incl. 26.x, pass@1 / pass^3, cost per pass, repair-loop count; seed from real failed customer builds | M | pass rate per version/feature class; target >=95% pass^3 on core classes |
| 2 | **ModSpec** (typed plan: entities/items/blocks/sounds/textures/commands + acceptance criteria) feeding build and asset studios | M | spec-to-built fidelity; first-try compile rate |
| 3 | **Test Flight boot gate** (Java 21 and 25 images, RCON smoke script) and show badge | M | boot-pass %, p95 time, RAM; correlation with post-install failures |
| 4 | **Sheet retrieval** (per-feature slices + 26.x sheet) replacing whole-sheet injection; verify claims with javap in CI | M | input tokens/build; API-hallucination compile errors |
| 5 | 26.x support (Java 25 toolchain, Paper 26.x jar, MockBukkit v26.x dependency) | M | eval pass rate on 26.x vs 1.21.x |
| 6 | Cache audit + effort-by-tier + spec-driven Haiku/Sonnet routing | S | cache hit %, $/successful build, quality at each effort level |
| 7 | **Verified recipes** (mob w/ model+sounds, GUI, particles, recipes, boss, command) compiled and Test-Flown in CI | L | % of builds using a recipe; pass rate delta vs freeform |
| 8 | MockBukkit tests generated test-first for logic-heavy mods | M | bug catch rate before boot; extra token cost |
| 9 | Mineflayer scenario checks from spec (join, command, GUI, resource-pack prompt) | M | scenario pass %, flake rate |
| 10 | Iterative edit + project import | M | edit success vs regenerate; adoption |
| 11 | Reviewer-subagent pass (fresh context, correctness-only) for high-effort tier | S | defects caught per $ |
| 12 | Public quality page + badge (pass rate, versions, scan) | S | conversion and trust (A/B) |

## Could not determine
Independent user reviews (Reddit/forums) of rivals; MCreator's AI extension specifics; exact MockBukkit artifacts for each 1.21.x; real Test Flight RAM/time on our host (needs a measurement run); Mineflayer on 26.2.

## Sources
- https://www.player.games/de-DE/best-ai-minecraft-mod-maker
- https://www.player.games/create-spigot-plugins-ai
- https://creativemode.net/blog/top-ai-minecraft-modding-tools-in-2026 (nav only, no content)
- https://github.com/MockBukkit/MockBukkit
- https://github.com/PrismarineJS/mineflayer
- https://docs.papermc.io/paper/getting-started
- https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents
- https://code.claude.com/docs/en/best-practices
- https://platform.claude.com/docs/en/build-with-claude/prompt-caching
- https://platform.claude.com/docs/en/build-with-claude/effort
- https://mineacademy.org/ai-plugins-guide (403, snippet only)

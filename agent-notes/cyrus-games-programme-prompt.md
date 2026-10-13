# PROMPT: finish and improve Cyrus for Minecraft, Rust, Terraria, Valheim, Zomboid and Palworld

Paste everything below the line into a fresh Claude Code session on the Nxeon primary (cwd /root). It is self-contained.

---

You are continuing the Cyrus programme for Nxeon (owner: haxkodi@gmail.com; prefers concise replies; hates anything that looks cheap or vibe-coded; Malaysia/Vietnam timezone). Cyrus is Nxeon's AI mod studio: a person describes a mod, Cyrus plans, writes, compiles, safety-checks and installs it on their Nxeon game server. Your job is to take every game on the map from its CURRENT standing to FINISHED and IMPROVED, in a safe order, without breaking what is already live.

## 0. Read first (in this order, do not skip)
1. `/root/.claude/projects/-root/memory/MEMORY.md`, then these memories in full: `nxeon-cyrus-release-pass-2026-10-09.md`, `nxeon-golive-decisions-2026-10-08.md`, `nxeon-cyrus-v6-programme.md`, `nxeon-build-host-node2.md`, `nxeon-pkill-nextstart-incident.md`, `nxeon-never-reuse-vmids.md`.
2. `/root/agent-notes/BUILD-HOST.md`, `/root/agent-notes/cyrus-release-backlog.md`, `/root/agent-notes/cyrus-backend-prompts.md` (exactly what the build service sends to Claude today).
3. Per-game notes: `/root/agent-notes/cyrus-v6/game-{rust,palworld,terraria,valheim,zomboid}/` (READINESS.md and PAUSED.md in each), `/root/agent-notes/cyrus-v6/library/PAUSED.md`, `/root/agent-notes/cyrus-v6/capabilities/THREAT-MODEL.md`.
4. Code: `lib/cyrus/games/support.ts` (the GameSupport contract) and one file per game in `lib/cyrus/games/`, `lib/cyrus/engine/` (template generators), `lib/cyrus/data.ts` (the six-game registry), `lib/cyrus/categories.ts`, `lib/cyrus/game-status.server.ts`, `lib/modbuilder/*`, `services/modbuilder/*` (the build service), `docs/DOCUMENTATION.md` sections "Cyrus release pass", "Cyrus v6: ..." per game.

## 1. Ground truth today (2026-10-09) — verify, do not trust
- **Live in production now:** release `20261009T095149Z-fd6bcb7e` (main = integ/golive `fd6bcb7e53`). Studio, tokens, marketing page, mod pages are built but GATED OFF until the owner flips `cyrus_studio_public_enabled` + `cyrus_tok_live` (flags `cyrus_public_enabled` and `cyrus_mods_public_enabled` stay off until the owner reviews `/cyrus`).
- **Only Minecraft really builds.** The build service (VM 88001, `services/modbuilder`, image 0.5, reached over a tunnel via `MODBUILDER_URL`) runs the Claude Code CLI headless in Docker with Read/Write/Edit only, compiles with Gradle against the real Paper API (JDK 21), scans bytecode with `scan.js`, and returns a jar. Versions: 1.21.1, 1.21.4, 1.21.8, 1.21.11. For every OTHER game the studio today produces template code from `lib/cyrus/engine/*` ("template preview"), nothing is compiled by a real toolchain in the pipeline, and no game is installable.
- **GameSupport files exist and are merged** for Minecraft, Terraria, Valheim, Zomboid. **Rust and Palworld are NOT merged**: branches `feature/cyrus-v6-game-rust` (a6cf731b0c) and `feature/cyrus-v6-game-palworld` (c91c296099), both paused. Pattern library `feature/cyrus-v6-library` (c4b5dd6288) is also unmerged.
- The hardened safety scan (`services/modbuilder/scan.js`, constant-pool scan, reflection/DNS/JNDI/etc. blocked, secrets blocked) is in the repo and in production code but must still be copied to VM 88001 and the image rebuilt (the owner does VM changes; agents never touch VM 88001).
- Texture renderer + resource-pack builder exist (`lib/cyrus/textures/*`, tested) but are not wired to the studio. Cyrus sound is synthesised in the browser only (`lib/cyrus/sfx.ts`).
- Token economy works end to end on a throwaway DB (reserve 70 -> settle, starter grant 70 once per verified account). Real Stripe top-up test never run (staging has test keys; devhost refuses staging credentials).
- Minecraft 26.x: Paper 26.2 API is Java 25 bytecode (class major 69); the service is JDK 21 + Gradle 8.14. Not supported.
- Test suite baseline: 52 failures identical on main before this work (stale pricing tests etc.). Do not "fix" them as part of this programme; do not add new ones.

## 2. Hard rules (from the owner and from past incidents)
- **Use Sonnet 5.5 for everything** (subagents too) unless the owner says otherwise. Never Fable.
- Work only in your own worktree under `/tank/dev-worktrees/<name>` (`git -C /opt/nxeon worktree add /tank/dev-worktrees/<name> -b <branch> main`). Never edit or build in `/opt/nxeon` or `/opt/nxeon-staging`. All heavy work (tsc, tests, next build/dev, Playwright, compilers, dotnet, game servers) runs on node-2 through `/opt/nxeon/scripts/devhost` (one dev server fleet-wide, always `devhost stop all`). Never `git add -A` in a worktree that has a node_modules symlink. Never `pkill -f <pattern>`; kill by PID or systemd unit.
- No production deploys, merges to main, prod DB writes, VM 88001 changes, DNS, or live supplier/OVH/Stripe-live actions without the owner. Prepare exact command blocks for the owner instead. Never reuse a VM id (allocate a brand-new one; `pvesh nextid` is unsafe). No real-money tests.
- Anything shown to customers must be true: nothing "live" that is not built; no invented stats, reviews, or screenshots; future features say "coming soon". Never name a third-party infrastructure provider to customers. Marketing is dark-only. Keep the "47 seconds" tagline.
- Commit with the attribution line the harness gives you. Keep `docs/DOCUMENTATION.md` current for every change. Put reusable operational knowledge in `/admin/docs`/DOCUMENTATION, bugs outside scope in spawn_task.
- Safety: generated code is untrusted. Every language gets a deny-list scan on the COMPILED artifact (not only the source), secrets blocked, no networking by default (`cyrus_mod_networking_enabled` stays off). A change to scanner rules needs tests with real compiler output.
- Report in short checkpoints (what is done, what is verified how, what needs the owner). Never claim verified without saying what you actually ran.

## 3. Definition of done for a game to flip from `soon` to `live`
A game is LIVE only when ALL of these are true and demonstrated:
1. **Real toolchain in the pipeline:** the build service compiles/validates the AI's output with the game's real toolchain against REAL game files (not stubs), and failed compiles feed a repair loop like Minecraft's.
2. **Real AI generation**, not template code: system prompt + verified API sheet + failure rules for that game, in the same shape as `services/modbuilder/prompts.js`; the prompt-check, tokens (reserve/settle), prompt refusal and abuse limits apply unchanged.
3. **Scan** for that language with tests built from real compiler output, and zero false positives on a corpus of generated good mods.
4. **Install path** on Nxeon servers for that game (correct folder, restart/hot-reload rule, backup, rollback, one copy only), plus the per-game "what players must install" message.
5. **Lifecycle:** version compatibility (outdated warning when the game updates, forced-update dates where they exist), on/off/update/remove from the server Mods tab.
6. **Load test** on a real running server of that game where one can run headless on node-2 (details per game below); if not possible, say so on the page.
7. **Studio + marketing + admin truth:** status flipped through the admin games tab (setting-backed), categories reconciled with `lib/cyrus/categories.ts`, `/cyrus` page and readiness doc regenerated from data, cost estimate and token reserve table retuned from real build costs.
8. Docs and tests committed; tsc clean; all new tests pass on node-2.

## 4. Shared platform work (do this FIRST; every game depends on it)
**P1. Multi-language build workers.** Today `services/modbuilder/server.js` is Minecraft-specific (Gradle/Java/javap). Refactor into: a game-agnostic orchestrator (queue, stream, tokens, repair loop, usage meter, dedupe) + per-game "worker profiles" (workspace template, compile command, artifact type, scan, sheets/rules). Profiles needed: `java-paper` (exists), `csharp-oxide` (Rust), `csharp-tshock` (Terraria), `csharp-bepinex` (Valheim), `lua-zomboid` (Zomboid), `ini-palworld` (settings, no compiler). Keep the model-facing prompt shape; keep Claude's tool set to Read/Write/Edit; keep compiling and scanning outside the model. Image rebuild is an owner step on VM 88001; develop and test on node-2 with the fake-CLI pipeline test (`test/modbuilder-pipeline.test.ts`) and a capped number of real builds on the owner's subscription (ask before more than ~10).
**P2. Per-game verified knowledge.** For each game generate (from the real game files, not memory) an API sheet + failure-rule file like `services/modbuilder/sheets/<ver>.md` and `rules/failure-rules.json`; mine rules from failed builds with `tools/mine-rules.py`.
**P3. Install + lifecycle adapters per game** in `lib/modbuilder/install.ts` / `lib/cyrus-mods/*` / the game panel Mods engine: target folders, restart vs hot-reload, backups, version metadata.
**P4. Status + economy plumbing:** `lib/cyrus/game-status.server.ts` and admin `/admin/cyrus` Games tab drive `soon`/`live`; `lib/cyrus/estimate.ts` and the token reserve table need per-game numbers measured from real builds; reconcile `DEFAULT_GAME_CATEGORIES` with each game's `categories`.
**P5. Safety review:** write a per-language threat table (extend `THREAT-MODEL.md`), per-language scan tests, and a short list for a human reviewer (the owner declined to hire one for now; keep a "reviewed by: nobody yet" note in the docs honest).
**P6. Assets (textures + sound):** wire `lib/cyrus/textures` into the build service for games where it makes sense (Minecraft first: resource pack hosted by Nxeon and applied to the server with `resource-pack` + sha1; Terraria/Valheim need their own formats and the owner said creators upload art there). Sound pack needs OGG output; design the generator (synth to WAV then encode on the build host) before promising it. The Assets studio on `/cyrus` is marked "Coming soon": keep it truthful.

## 5. Per-game plans (current standing -> finished + improved)

### 5.1 Minecraft (Paper) — public first; finish and harden
Standing: live path complete on 1.21.1/.4/.8/.11 with Katara/Saka/Yakko, token economy, scan hardened (repo), install with backup/rollback, community/lifecycle code merged (gated). Eval v6: 28/28 built, 13/13 runtime jars load.
To do:
- Deploy the hardened scan to VM 88001 (owner), then re-run `eval/run_eval.py` + `rtcheck.py` and compare with v5; add scan corpus tests from the eval jars.
- **Root-cause "stuck at Compiling"** (watchdog only mitigates): trace the real service stream end to end on VM 88001 read-only timing (`follow.ts`, nginx buffering, tunnel), fix properly.
- **26.x support:** second toolchain (JDK 25 + Gradle 9.x) in the image, javap-verified `sheets/26.2.md`, template toolchain selection by version, `MB_VERSIONS` + portal `MB_VERSIONS`, lifecycle "Outdated" logic for 26.x servers, eval on 26.2, real Paper 26.2 load test (the owner already runs a 26.2 server). Build and test on node-2 first; image change is an owner step.
- **Textures + sound wired:** service emits `textures/*.json` specs (validated by `lib/cyrus/textures/dsl.ts`), portal builds/hosts the pack, install step sets the resource pack on the server and tells players; plugin uses `ItemMeta.setItemModel` (1.21.4+) or CustomModelData on 1.21.1. Sound: per above. Ship behind a flag.
- Pattern library (`feature/cyrus-v6-library`): finish the real-server verification, run the A/B (v6-off vs attach), merge only if cost/quality improve.
- Networking capabilities (`feature/cyrus-v6-capabilities` is merged but OFF): keep OFF until the owner decides on a human review.
- Quality loop: expand the eval prompts to cover the seven showcase categories (world event, island world, weapon, biome, admin tools, performance overlay, quest board); target first-try success >= 90% on Saka, track cost per build, retune `estimate.ts`.
- Real Stripe test-mode top-up on staging (needs a staging deploy approved by the owner).
- Installing OTHER people's published mods stays off until the scan has run on a real corpus for a while.
Acceptance: the seven showcase prompts each produce a compiling, scanning, loading plugin on 1.21.11 and 26.2; 10 consecutive builds with zero stalls; texture demo pack loads in a real client or the pack validator.

### 5.2 Rust (Oxide/uMod C# plugins) — largest finished code, not merged
Standing: branch has verified GameSupport (version table 2634.289.1, 737 hooks, API sheet 38 lines, 9 failure rules), validator, generator on verified APIs, Roslyn stub-compile harness (`tools/cyrus/rust-check`, .NET 8 on node-2). Last full run 502/540; a real generator bug (`using Oxide.Core.Plugins;`) was fixed in the WIP commit but NOT re-run; tsc never confirmed clean. Routing branch excludes magic/visuals/audio for Rust while rust.ts includes them.
To do: re-run tests + rust-check (expect 540/540) + tsc; squash the WIP commit; reconcile categories; merge into your integration branch. Then P1 `csharp-oxide` profile: Oxide compiles `.cs` on the server, so the artifact is source; the service compile check must use the REAL Oxide/Rust DLLs (owner approved keeping free Rust server files on node-2 for compile checks; they never go in git). Add the C# deny-list scan on the SYNTAX + referenced assemblies (System.Net, Process, reflection, file access outside oxide/data, WebRequests, unsafe, dynamic load). Install: `oxide/plugins/<Name>.cs` hot-loads; backup; show load errors from the server log back to the user. Lifecycle: monthly forced wipe/update (first Thursday) -> "may break" warning using `nextRustForcedUpdate`; Oxide/uMod version compat. Load test: run RustDedicated + Oxide headless on node-2 only if memory allows (it is heavy; ask the owner first) else do a staged test on one owner-approved Rust server.
Improve: popular-use categories first (kits, teleports, shops, claims, event bosses), ensure no plugin references paid/Discord webhooks. Acceptance: 20 diverse prompts -> 20 plugins that load on a real Oxide with zero errors in the log.

### 5.3 Terraria — TShock live path, tModLoader later
Standing: merged GameSupport; 78/78 generated mods compiled for real (18 TShock .dll on TShock 6.2.1 / Terraria 1.4.5.8; 60 tModLoader .tmod on tML v2026.08.3.0); 104 tests. Two products: **TShock plugins run on Nxeon today** (players install nothing); **tModLoader mods cannot run on Nxeon** (no server variant; owner: add a variant LATER; creators upload their own art; no Docker on the build host).
To do: P1 `csharp-tshock` profile (compile against the real TShock + Terraria server DLLs from node-2 cache, `.dll` into `ServerPlugins`); scan for C# (same deny-list as Rust plus TShock-specific: command execution, SQL against the TShock DB outside its API); install + restart rule; version watch (TShock minor releases break plugins; use the version table in `terraria.ts`); load test by running TShock headless on node-2 with `dotnet` (no Docker needed) and loading each generated plugin. Keep tModLoader code paths behind an "unsupported on Nxeon yet" reason on the page. Improve: boss/loot/NPC/item archetypes with TShock hooks, permissions via TShock groups.
Acceptance: 15 diverse prompts -> TShock plugins that load and a command responds on a real headless TShock.

### 5.4 Valheim — BepInEx + Jotunn
Standing: merged GameSupport; 47/47 generated mods compile against REAL Valheim 1.0.17 dedicated-server DLLs (node-2 cache, never in git); generated unit projects pass; 56 tests. Valheim 1.0 shipped 2026-09-09 (most mods broke); BepInExPack 5.4.2351, Jotunn 2.30.2. Content mods need the SAME mods on the server and on every player's PC. Thunderstore rejects untested AI mods and requires an AI disclosure.
To do: P1 `csharp-bepinex` profile (compile with real DLLs; `.dll` into `BepInEx/plugins`); confirm the Nxeon Valheim server image has BepInEx (add a variant/toggle if not) and how the Mods tab installs there; client distribution page (exact files + Thunderstore-style install steps per mod; zip download "client pack"); scan; lifecycle (game update -> BepInExPack/Jotunn compat warning); headless load test on node-2 (Valheim dedicated runs natively on Linux). Do not publish to Thunderstore; owner decisions pending on AI-disclosure wording.
Acceptance: 15 prompts -> plugins that load on a headless BepInEx Valheim server with a client-pack zip and honest "players must install" messaging.

### 5.5 Project Zomboid — Lua (Build 42)
Standing: merged GameSupport; 216 generated mods statically linted only (no real-game load test); stays `soon`. Owner: no load-test VM; Zomboid mods must stay free and credit forks (Modding Policy); lifecycle must refuse Cyrus mods on b41 servers; Workshop vs server-pack distribution undecided.
To do: P1 `lua-zomboid` profile: Lua syntax check (`luac -p`) + `luacheck` with a Zomboid globals stub + the existing validator + a deny-list (os.execute, io.popen, loadstring on dynamic text, file access outside the mod dir); install into `Zomboid/mods/<id>` + server `Mods=`/`WorkshopItems=` ini lines + restart; client distribution is the big issue: Zomboid clients download server mods from Steam Workshop or must have the mod folder, so decide (recommended: generate a mod pack zip + clear steps, and say Workshop publishing is the creator's own account action; do NOT upload to Workshop on Nxeon's account). Lifecycle: b41 refusal. Load test: owner said no extra VM; run PZ dedicated headless on node-2 only if the owner changes that; otherwise be explicit that mods are "validated, not load-tested" on the page.
Acceptance: 20 prompts -> mods that pass syntax + lint + deny-list; honest "validated, not load-tested" label until a real test exists.

### 5.6 Palworld — only what is truly possible (Linux-only decision)
Standing: paused WIP (c91c296099): settings presets + client tips, tests 22/23, tsc not run. Owner decision: Palworld is LINUX ONLY (our servers run the native Linux dedicated server; no Windows/Wine). Real code mods (UE4SS, PAK) are Windows/client oriented, so on Nxeon they are unsupported with an honest reason.
Scope that IS possible: a **server rules designer**: `PalWorldSettings.ini` presets and custom rules (difficulty, rates, breeding/hatch times, base/guild limits, death penalty, PvP), validated against the real settings schema, installed through the existing Palworld settings panel (restart rule), plus client-side tips for players. Finish that, make the page say exactly this ("server rules, not code mods"), and keep real mods "not supported on Linux servers: <reason>".
To do: finish the 23rd test + tsc; wire a `ini-palworld` profile (no compiler: schema validation only; the AI writes the ini/JSON preset; scan = value-range validation + no unknown keys); lifecycle for Palworld version changes that rename/remove settings; category list limited to what settings can do (Gameplay, Economy-ish rates, Admin). Label it "Beta".
Acceptance: 15 prompts -> valid ini presets accepted by a real headless Palworld server on node-2 only if memory allows (ask); else schema-validated + applied on an owner-approved test server.

## 6. Order, parallelism and checkpoints
1. Week-zero (shared): P1 refactor + P4 plumbing, one agent, then freeze the interface. Minecraft items (26.x, stall root cause, textures, eval) can run in parallel in a separate worktree because they only touch Java paths.
2. Then one agent per game in parallel (separate worktrees, separate branches `feature/cyrus-games-<name>`; node-2 only; at most 2 heavy jobs at once). Suggested order of landing: Rust, Terraria (TShock), Valheim, Zomboid (validated-only), Palworld (settings-only). Rust and Terraria/Valheim share the C# profile work: do `csharp-*` once.
3. After each game: tsc, its test file, the pipeline test, a real-route browser pass through the studio (screenshots), then an integration branch off main (`integ/games-<date>`) that the coordinator merges in landing order, resolving conflicts in `CyrusApp.tsx`, `lib/cyrus/store.ts`, `prisma/schema.prisma`, `lib/cyrus/categories.ts`.
4. Never flip a game to `live` yourself in production; produce the exact `set-setting.sh` / admin steps for the owner and the evidence for the 8-point definition of done.
5. Checkpoint format every ~hour of work: `DONE / VERIFIED (what command, what result) / BLOCKED (needs owner) / NEXT`.

## 7. Open owner decisions (ask once, together, with a recommendation)
1. Keep a reference RustDedicated + Oxide install on node-2 for real-DLL compiles? (recommend yes, never in git) and may we run it headless for a load test?
2. Run headless TShock and Valheim servers on node-2 for load tests (no Docker)? (recommend yes, capped slice)
3. Zomboid: server-pack zip vs Workshop; run a headless PZ server on node-2 for load tests? (recommend zip + yes, one test run)
4. tModLoader server variant on Nxeon: later, confirm priority after TShock ships.
5. Allow installing OTHER creators' published mods per game, and from when? (recommend Minecraft only until a month of scan data)
6. Per-game pricing: keep Katara/Saka/Yakko tiers for all games or per-game reserve tables? (recommend per-game tables measured from real builds)
7. AI disclosure wording for Thunderstore/Workshop style pages; who reviews (the owner declined a paid security reviewer for now).
8. Minecraft 26.x go-ahead for the VM 88001 image change (JDK 25 + Gradle 9).

## 8. Your first moves
1. `git -C /opt/nxeon worktree add /tank/dev-worktrees/games-platform -b feature/cyrus-games-platform main` and read section 0.
2. Write `/root/agent-notes/cyrus-games/PLAN.md` (a one-page restatement of this plan with a task list and who/what/where), then ask the owner the section 7 questions in one message.
3. Start P1 (worker-profile refactor) on node-2 behind the existing tests; keep Minecraft behaviour byte-identical (the pipeline test and eval are the proof).
4. In parallel, resume Rust: run its tests/rust-check/tsc and report real numbers.

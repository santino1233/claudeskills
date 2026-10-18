# EB: new Cyrus features from our research + open source (2026-10-18, Opus bundle D)

Branch `feature/cyrus-newfeat` (worktree `/tank/dev-worktrees/cyrus-newfeat`, from main af5a1d55 = live rc21). NOT merged, NOT deployed, every new switch OFF. No real model spend ($0 of the $8 cap: the build-service image cannot carry these changes without a deploy, so paid builds would not have exercised them).

## 1. Ranked candidate list (verified against main before building)

Sources: BF technique catalogue top 20 + json, BD modtools survey (adopt-now), GAPS-AND-IDEAS, docs/cyrus/12-gaps-and-roadmap.md, MINECRAFT-FINDINGS, minecraft-coverage.json archetypes, `git log main`.

| # | Candidate | Value for a server owner | State on main 2026-10-18 | Decision |
|---|---|---|---|---|
| 1 | Dialog windows + confirm-before-buying (BF #9) | modern UI, fewer mis-buys | sheet facts only (`dialog_forms` partial, chest dialogues only) | **BUILT** |
| 2 | Forms (applications, reports, polls) | staff applications are a top-requested plugin type | not built | **BUILT** (dialog on 1.21.8+, chat elsewhere) |
| 3 | LuckPerms ranks (rank shop, rank rewards; BD "soft-depend") | "buy VIP for 30 days" is the #1 monetisation ask | `luckperms-api` in deps allowlist but unused; ranks only as own groups (mc-ranks) | **BUILT** (`grant_group`) |
| 4 | Pets / companions (mob_ai partial) | pets are a classic premium feature | plain golden mc-pets only, no designer action | **BUILT** (`summon_pet`, MobGoals) |
| 5 | GUI skins: tooltip styles (BF #7) | visible polish, cheap | not built (HUD_EXCLUDE refuses "custom gui textures") | **BUILT** (tooltip presets; client look unverified) |
| 6 | Client-mod lane (Fabric) | unlocks minimaps, keybinds, real models | not built | **design + proof** |
| 7 | Menu backgrounds via glyph title + negative space (BF #16) | custom GUI look | not built | next (same pack plumbing as #5, needs a client check) |
| 8 | Minigame templates (spleef / KOTH / parkour) as a designer kind | big demand (minigame 16 cat.) | plain goldens mc-arena / mc-parkour only | next (L: own kind) |
| 9 | PlaceholderAPI expansion hook | scoreboards/tab plugins show quest / form data | `placeholderapi` jar in allowlist (GPL-3.0) | **owner decision**: licence rule says MIT/Apache/BSD/CC0 only; compile-only GPL API = not built |
| 10 | Dynamic lights (BF #15) | 7.8M downloads | not built | next (M) |
| 11 | Economy ledger / auction (BF #19) | auction is a coverage gap | plain goldens mc-economy / mc-auction | later |
| 12 | Jigsaw structures (BF #20) | worldgen leap | not built | later (L) |
| - | Survival bot, vein miner, capture mob, weapons, combat tag, per-player fx, armor + note-block lanes, MockBukkit pre-flight, Spyglass | | ALREADY on main | not rebuilt |

## 2. What was built (all on the branch; compile = javac per lane; fallbacks are explicit warnings, never silent)

See `docs/cyrus/02-engine.md` "EB dialogs, forms, ranks, pets, tooltip skins" for the full spec. Byte identity: mods that use none of them compile exactly as before (patches applied only when used; `test/cyrus-eb-dialogs.test.ts` checks the gameplay golden hash and every patch anchor).

| Feature | Switches (OFF) | Files |
|---|---|---|
| Native dialogs (dialogue `display: dialog`), confirm (`confirm` / `confirmText`), forms (`style: form`) | CYRUS_DIALOGS / MB_DIALOGS | `lib/cyrus/designer/gameplay/dialogs.ts` (Dialogs.java 1.21.8+, Forms.java, NativeUi, patches), gameplay spec/compile/simulate, studio UI (MenuQuestDesigner), route FORM_WORDS, prompt EB_DIALOGS_PART |
| LuckPerms `grant_group` (menu action + quest reward, temporary or permanent) | CYRUS_PERM_HOOKS / MB_PERM_HOOKS | Ranks.java (LuckPerms API 5.5 MIT compile-only), RankHook, softdepend, deps `luckperms-api`, route RANK_WORDS, prompt EB_PERMS_PART |
| Pets `summon_pet` (follow / guard) | CYRUS_PETS / MB_PETS | `lib/cyrus/designer/components/pets.ts`, item spec/compile/simulate, palette template, ItemDesigner labels, route PET_WORDS, prompt PETS_SECTION, sheet facts (MobGoals group) |
| Tooltip skins (`tooltip` preset on items) | CYRUS_UI_SKINS / MB_UI_SKINS | `lib/cyrus/designer/skins.ts` (CC0 procedural nine-slice sprites), setTooltipStyle on 1.21.4+, pack builder + sync plumbing, prompt UI_SKINS_SECTION |
| Client-mod lane design + Fabric probe | CYRUS_CLIENT_MOD_LANE | `docs/cyrus/34-client-mod-lane.md`, `lib/cyrus/clientmod/lane.ts` |
| Test Flight bot: `expect_dialog`, `dialog_click` | (harness) | `tools/testflight/bot.js`, `playtest-lib.js`, `lib/cyrus/playtest/plan.ts` |

Paper facts (javap, node-2): Dialog API identical on 1.21.8 / 1.21.11 / 26.2, absent on 1.21.1 / 1.21.4; MobGoals / Goal / GoalKey / Pathfinder / AsyncChatEvent / PlainTextComponentSerializer present on all four; 11 new entries in `sheets/api-facts.json` (version apifacts-2026-10-18.1), `api-facts.verified.json` regenerated (176 facts x 4 versions), sheets regenerated (new "Pets and custom mob AI" and "Dialog forms and chat answers" lines). LuckPerms API 5.5 checked with javap (LuckPermsProvider, UserManager.modifyUser, GroupManager.getGroup, InheritanceNode.builder, NodeBuilder.expiry, NodeMap.add(Node, TemporaryNodeMergeStrategy)).

Golden examples / fixtures: `test/fixtures/cyrus-eb-dialogs/` (rank_shop, guide, apply, welcome), `test/fixtures/cyrus-eb-pets/` (wolf_whistle, bee_charm). Eval prompts: 5 rows `cov-eb-*` in `services/modbuilder/eval/sets/coverage.jsonl`. Coverage archetypes updated: dialog_forms, ranks_permissions, mob_ai.

## 3. Tests and real runs
RESULTS: see section 5 (filled after the node-2 runs).

## 4. Client-mod lane proof (node-2, 2026-10-18 10:19 UTC)
- Fabric mod (`fabric.mod.json` environment `*`, main + client entrypoints) compiled with JDK 21 `javac --release 21 -Xlint:all` against `fabric-loader-0.19.5.jar` ONLY (no Loom, no Minecraft classes): 0 warnings; jar sha256 `1c5cd63907596d4836e9a8ae9c59b4ec6303465b3cf19c8bb9502184e79ea3ac`.
- Fabric server launcher (loader 0.19.5, installer 1.1.2, Minecraft 1.21.11) on node-2: `Loading 5 mods: cyrus_probe 0.1.0, fabricloader 0.19.5 (mixinextras 0.5.5), java 21, minecraft 1.21.11`, then `[STDOUT]: [cyrus_probe] Cyrus client-mod lane probe loaded (common entrypoint)`, `Done (0.415s)`. Files: `/tank/nxeon-build/tmp/cyrus-eb/fabric/` (server/run.log).
- Not done: a headless CLIENT (cost estimate and owner decisions in docs/cyrus/34).

## 6. What is next (priority)
1. Owner: switch decisions (each pair together, after a promote + image bump `MB_*` twins): CYRUS_DIALOGS, CYRUS_PERM_HOOKS, CYRUS_PETS, CYRUS_UI_SKINS. Real-client test-day steps for dialogs, tooltip skins and pets.
2. Owner: PlaceholderAPI (GPL-3 compile-only) yes/no; client-mod lane decisions (docs/cyrus/34).
3. Build next: menu backgrounds (glyph titles), minigame designer kind (spleef / KOTH / parkour), dynamic lights.
4. A paid eval subset with the five `cov-eb-*` prompts once the image carries the new prompt parts (est. ~$2).

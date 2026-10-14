# Cyrus inventory and gap analysis (2026-10-14)

Author: analyst pass, read-only. Sources: /opt/nxeon (main f347f27a), services/modbuilder, lib/cyrus, production DB aggregates (ModBuild, CyrusRevision, CyrusToken*), .env CYRUS_* names, Setting table, CYRUS-TRACKER.md sections 100-110, /root/cyrus-eval/fourth1/report.md, docs/cyrus/12-gaps-and-roadmap.md.
Status words: LIVE = on in production env and exercised; BUILT-OFF = code exists, switch off; PARTIAL; MISSING.
Honesty notes: I did not run any build, flight or deploy. "Production env" = /opt/nxeon/.env on this host; I did not verify the build-service VM's own env (MB_* flags, image tag 0.19 is from the tracker, not checked). Some tracker rows (rc10/rc11/rc12, BetterModel flight fix) are stated NOT promoted; I did not verify what is now deployed beyond the tracker.

## 0. Headline
- Cyrus is live on cyrus.my / nxeon.cloud for Minecraft (Paper) only. 36 CYRUS_* switches are ON in .env, including designer, creatures, worldgen, datapack, armor, noteblock blocks, config studio, delivery, Test Flight gate + block-on-fail, API v1, wallet pay, storage.
- Real usage is tiny: 45 ModBuild rows ever, 1 distinct user (the owner/QA), all on 1.21.11. All 30-day stats below are essentially the owner's QA, not customers. Treat rates as indicative only.
- Quality evidence is strongest from the paid eval fourth1 (90 builds, saka, 1.21.11): final pass 100%, pass@1 76.7%, full pass 97.8%, boot 100%, $27.21, $0.30/pass; playtest stage 0/90 run.
- Biggest risks: build service still on a subscription login (shared session limit, "testing only" per runbook); no real Minecraft client has ever loaded a Cyrus pack/model/HUD; one build VM / one build lock; single-user data; owner-only decisions (API key, price, legal) outstanding.

## 1. Build lanes and mod kinds

| Kind | Status | How generated | Verified how | Weak spots / evidence |
|---|---|---|---|---|
| Code plugins (Paper plugin.yml, Java) | LIVE | Model (katara=Haiku 4.5, saka=Sonnet 5, yakko=Opus 5) writes Java against per-version API sheets (services/modbuilder/sheets/1.21.{1,4,8,11}.md) | javac (JDK 21), safety scan (scan.js), autofix rules, Test Flight boot + plugins_enabled + commands_registered | pass@1 plain 95% (fourth1 20 builds); hallucinated-API compile errors remain (2 in rc11 analysis) |
| Config-only settings (config.yml, Config Studio) | LIVE (CYRUS_CONFIG_STUDIO=1) | ConfigSpec, 12 templates, values-only revisions; deliverConfig | Real flights 1.21.11 + 26.2 (tracker r23); 2 `config` revisions in DB | "send to server" path reported 501 early on; later delivery wiring r29/r31. NxPerf adds undeclared config keys (13 seen in QA batch) |
| Items + abilities (designer) | LIVE (CYRUS_DESIGNER=1, CYRUS_DESIGNER_BUILDS=1) | typed designer spec, triggers/cooldowns/effects; no-model builds repack jar | RCON/log flights on 1.21.11 + 26.2 only; eval designer lane pass@1 70%, full 95% | No javac classpath for other versions in designer; handgun grip fix flag ON but unratified |
| Menus / shops / dialogues | LIVE (designer) | menu design kind | designer flights; coverage: dialog_forms partial (1.21.8+ only) | auction house = gap; economy is own-balance only (no Vault) |
| Quests | LIVE (designer) | quest design kind | RCON verified | max active quests soft limits |
| Bosses / encounters | LIVE (designer) | boss design kind | real 1.21.11 flight | "boss creature not delivered" finding in owner QA batch BV |
| HUD / glyphs | LIVE (designer) | HUD design kind (action bar, boss bar, sidebar) | real 1.21.11 flight | designStrict downgrade: 5 HUD/menu eval prompts shipped as plain plugins (rc8), later changed in rc11 to "downgrade to plain" |
| Motion / animated props | LIVE-ish (motion kind, 9 presets) | MotionSpec core; display-entity props | 39/39 RCON on 1.21.11 + 26.2 | no studio timeline UI, no vehicles; not client-verified |
| Creatures / mobs (BetterModel) | LIVE (CYRUS_CREATURES=1) but flaky | creature spec + BetterModel 2.2.0 managed jar | flights: depend fix works; QA batch BV: creature mods failed flight because BetterModel was not on flight server (fixed on unpromoted branch d5379429) | Creature look/animation never seen in a real client; goblin mod previously shipped without depend |
| Textures (item/block looks, pack) | LIVE | texture spec, procedural + library; resource pack hosting (CYRUS_PACK_STORE=local) | pack structure checks; eval texture lane pass@1 63% (fourth1 30 builds), full 100% | worst first-try lane (45% at 41/90 snapshot); full-solid panel textures; no real-client load |
| Sounds | LIVE (CYRUS_SOUND_RENDER=relay, library cleared flag ON) | sound spec, layered render via relay; library of ~6k sounds (staging) | assets stage; pass@1 85%, 1 miss "nothing shipped for sounds" | relay dependency on 127.0.0.1:47380; licence of proprietary SFX needs lawyer; 2 `assets` stage failures in eval |
| Armor (worn looks) | LIVE flag (CYRUS_ARMOR_LANE=1) | equippable + generated equipment textures | server-side flights; client unverified | tracker: not wired as spec kind in service in some rounds; verify |
| Food / consumables | PARTIAL | plain plugin / datapack | goldens (mc-food) | no first-class food kind |
| Enchantments | PARTIAL | datapack/plugin; "custom enchantment definitions beyond spec" listed as stillCannot | golden mc-enchant | custom NEW effect/enchant types impossible |
| Blocks / furniture | PARTIAL (CYRUS_NOTEBLOCK_LANE=1) | note-block states with custom models; display-entity furniture (mc-furniture golden) | server flights only | Real new block types need client mod; coverage: custom_blocks partial, custom_blocks_new impossible |
| Crafting recipes / loot / advancements | LIVE (CYRUS_DATAPACK_STUDIO=1, DELIVERY_REAL=1) | typed datapack spec | datapack_loaded Test Flight check (shows not_run when none) | advancements: 7 triggers only; dialogs/damage types missing |
| World / biome / structures | LIVE flag (CYRUS_WORLDGEN=1, TESTFLIGHT_WORLDGEN=1) | worldgen datapack spec, rollback | one real worldgen flight + tests | custom dimensions/jigsaw processors listed MISSING; worldgen probes informational |
| Commands / custom commands | LIVE | plain plugin / config lane | commands_registered check | Brigadier/paper-plugin.yml not supported |
| Minigames / arenas | PARTIAL | plain plugin (mc-arena golden) | boot + golden | arena reset is the weak part; spleef QA build failed `budget` ($1.02) |
| Economy | PARTIAL | own-balance plugin only | golden mc-economy | no Vault/LuckPerms interop by policy |
| Imports / Modrinth jars | BUILT-OFF at tracker time (cyrus_import_enabled, not in .env; setting not in Setting table) | import.js scan + wrap | unit tests; "import refused 1.21.9+ datapacks" bug fixed | verify current state with owner; no real third-party jar corpus run |
| Mod Packs (conflict engine) | LIVE flag (CYRUS_MODPACK_INSTALL_REAL=1) | pack of mods + conflict check | tests, node-2 flight | install with warnings needs ack; networking mods consent |
| Starter bank (16 prebuilt) | BUILT-OFF (CYRUS_STARTER_BANK / MB_STARTER_BANK not in .env) | prebuilt jars, zero tokens | 16 x 4 versions compile+scan; real flights 1.21.11 + 1.21.4 | bank charge placeholder 5 tokens; needs image + baseline |
| Recipe memory | BUILT-OFF (MB_RECIPES) | holdback A/B; 10 recipes in recipes/ | unit + eval gate script | no measured saving yet |
| Client mods (Fabric/NeoForge), shaders, new blocks/entities | MISSING | n/a | n/a | in coverage stillCannot list |
| Other games (Rust, Palworld, Valheim, Hytale, FiveM) | MISSING / parked | installers parked; Hytale exporter draft | none | legal holds |

Coverage matrix (lib/cyrus/adapters/minecraft-coverage.json, 91 archetypes): 55 covered, 28 partial, 3 gap (anti_cheat, anti_grief_log, auction_house), 5 impossible (voting, voice_chat, discord_webhook, proxy_network, custom_blocks_new). Plus 11 "stillCannot" families (client mods, new registries, shaders, big worldgen, plugin interop, network I/O, packet-level, databases, missing datapack kinds, Folia/paper-plugin.yml, 26.x).

## 2. Architecture inventory

| Component | Status | Evidence |
|---|---|---|
| Planner (Haiku lane detection + rules fallback, 15 lanes) | LIVE | services/modbuilder/planner.js, lib/cyrus/planner/{lanes,decide,rules}.ts. Eval: lane recall only 30% (precision 92%, exact 17.9%), config implied |
| Coach (prompt score/rewrite) | LIVE (CYRUS_PROMPT_COACH=1) | lib/cyrus/coach/*, coach.js; tuned on golden set, never on real customer prompts |
| Guard / safety scan | LIVE | scan.js, precheck.js, rules/net-policy.json; security reviews r32, rc9 (0 critical, 1 high fixed) |
| Router/models | LIVE | katara (Haiku 4.5, cost 0.5x), saka (Sonnet 5, default), yakko (Opus 5, 2.5x); lib/cyrus/models.ts |
| Repair/autofix rules | LIVE | rules/failure-rules.json 55 rules (version 18); autofix.js 681 lines (rc10-12 added weaker-access, Collection->List, List subtype, YAML scalars, depend fixes) |
| API sheets | LIVE | 4 version sheets (1.21.1, .4, .8, .11) ~130 lines each + api-facts.json/verified |
| Goldens | LIVE | golden/plugins: 77 golden mods (mc-*), 13 antipatterns, results flown 1.21.1/.4/.8/.11 |
| Recipes / starter bank | BUILT-OFF | recipes/ 10 JSON, bank/ 16 mods |
| Library (textures/sounds) | PARTIAL | staging 62,777 CC0 entries (not served); DB CyrusCatalogEntry=0 and CyrusLibraryItem=0 rows (not imported to production); sound library ~6k incl. 2,964 proprietary SFX; CYRUS_LIBRARY_CONTRIBUTE=1 |
| Eval harness + gates | LIVE (offline) | eval/ prompts 178 (matrix, sets/*.jsonl 11 sets), scripts/cyrus/eval-run.ts, eval-gate.ts; baseline.json written by fourth1; gate needs owner-accepted baseline |
| Capacity scheduler | LIVE (image 0.16+) | scheduler.js 184 lines, capacity.js: priority classes, reserve 1 of 2 slots, fair share, AI circuit breaker |
| Test Flight | LIVE (GATE=1, BLOCK_ON_FAIL=1) | checks: compile, scan, boot, plugins_enabled, commands_registered, datapack_loaded, packs, plugins; 38/45 builds ran through gate; one flight at a time, no container limits; playtest bot only on 1.21.11 |
| Delivery paths | LIVE (CYRUS_DELIVERY=1) | /api/cyrus/delivery/v1 server install + restart, resource pack host cyrus.my/packs (local /tank/cyrus-packs) |
| Token economy | LIVE | CyrusTokenAccount/Lot/Ledger/Reservation; reserve -> settle/release; cyrus_tok_free_failures=10; daily cap 5000 tokens/day applied in QA; plan token amounts are placeholders |
| Admin tools | LIVE | app/admin/cyrus, cyrus-tokens, cyrus-mods; alerts timer installed, no webhook yet |
| Notifications | PARTIAL | lib/cyrus/notify; bell/consent flows unit-tested only, no browser run |
| Public pages / mod pages / featured | LIVE | cyrus.my landing, 25 CyrusModPage rows, featured excludes failed flights (rc12 unpromoted) |
| Remix / fork | BUILT, UNUSED | CyrusFork=0, CyrusRemix=0 rows |
| API v1 + webhooks | LIVE flag (CYRUS_API_V1=1) | 0 CyrusPersonalApiKey rows; Nxeon-side client unexercised cross-machine |
| Versions | 1.21.1 / 1.21.4 / 1.21.8 / 1.21.11 buildable; 26.x preview not buildable (needs JDK 25) | matrix.json; all 45 DB builds are 1.21.11 |
| Games | Minecraft only | game slots per plan (placeholders) |

## 3. Flags and settings

ON in /opt/nxeon/.env (35 names): CYRUS_API_V1, ARMOR_LANE, BYO_GAME_ASSETS, CONFIG_STUDIO, CREATURES, CUSTOMER_APP, DATAPACK_DELIVERY_REAL, DATAPACK_STUDIO, DELIVERY, DESIGNER, DESIGNER_BUILDS, DOMAIN_MODE, GDPR_ERASE, HANDGUN_GRIP_FIX, ITEM_STATES, LEARNING, LIBRARY_CONTRIBUTE, LIVE_ASSETS, MANAGED_PLUGINS_REAL, MC_TECHNIQUES, MODPACK_INSTALL_REAL, NOTEBLOCK_LANE, PROMPT_COACH, SOUND_LIBRARY_CLEARED, STORAGE, STORAGE_ADDONS, TESTFLIGHT_BLOCK_ON_FAIL, TESTFLIGHT_GATE, TESTFLIGHT_WORLDGEN, WALLET_PAY, WORLDGEN, plus config values (PACK_STORE=local, PACK_LOCAL_DIR, PACK_PUBLIC_BASE, MANAGED_PLUGIN_DIR, SOUND_RENDER=relay, SOUND_RELAY_URL/TOKEN, PERF_WATCH_ACTION=notify). Secrets not printed.
Absent from .env (so off or default): CYRUS_STARTER_BANK, CYRUS_CATALOG_TOOLS/INDEX, CYRUS_LEGACY_TEXTURES, CYRUS_API_V1_IDENTITY_CLIENTS (default nxeon), cyrus_studio_public_enabled / cyrus_tok_live / cyrus_import_enabled / cyrus_studios_enabled (not found in Setting table; I could not verify where these live now). Tracker 106 says "launch pair still OFF" (public launch pair).
Setting table has only 2 cyrus_* rows: cyrus_tok_charge_refused=false, cyrus_tok_free_failures=10. Not verified: whether other tunables are config-file or code defaults.
Build-service side (MB_*): not verified (VM 88001 env not read).

## 4. Real-world data (DB, 30 days, owner QA only)

Sample: 45 ModBuild rows total (all 30-day), 1 user, 1.21.11; 18 CyrusProject, 18 CyrusRevision (16 generated, 2 config, all passed), 25 mod pages.

| status / errorCode | n | avg cost | p50 s | p90 s | avg attempts |
|---|---|---|---|---|---|
| succeeded | 39 | $0.455 | 184 | 445 | 1.56 |
| failed budget | 1 | $1.02 | 602 | | 1 |
| failed compile | 1 | $1.55 | 456 | | 4 |
| failed ai_unavailable | 1 | 0 | 4 | | 1 |
| failed refused | 1 | $0.003 | 3 | | 0 |
| failed unavailable | 1 | 0 | | | 0 |
| failed interrupted | 1 | $0.005 | | | 0 |

- Success rate 39/45 = 87%; total spend about $20.4 across all builds ($17.75 on successes).
- Attempts (finished builds): 1 attempt 27, 2: 9, 3: 3, 4: 2, 5: 1, 0: 3. First-try (attempts=1 among succeeded) roughly 27/39 = 69% (approx; n small).
- By model (succeeded): katara 13 builds avg $0.129 p50 90 s; saka 21 avg $0.644 p50 258 s; yakko 3 avg $0.637 p50 127 s; 2 unlabeled. Saka is more expensive here than eval ($0.30) because QA prompts are asset-heavy.
- Cost by lane: lane is not a ModBuild column; fourth1 eval gives lane costs: plain $0.16/pass, designer $0.27, sound $0.31, texture $0.41. (Production lane split not verified.)
- Test Flight verdicts (45 rows): passed 34, failed 4, not_run 1, none/pre-gate 6. State: done 38, running 1 (stuck "running" row, tfgate-1).
  - Failed flights: 2 are genuine plugins_enabled failures (FoxCompanion "NOT enabled", Goblins enableError=true); FoxCompanion also commands_registered fail. The other 2 (Growth) fail only on infrastructure notes ("pack config not part of this flight: no Pack Loader jar on this host" and "clean_stop failed ... 2 shutdown log hits") although all listed checks passed. That is a false-fail class.
- Token ledger (30 d): reserve 40, spend 35 (-8,368 tokens), release 5, grant 2 (20,245). Reservations: settled 35 costing $16.22; released 5 with $2.58 held-then-refunded. Actual spend $16.22 for 8,368 tokens = about $1.94 per 1,000 tokens (informational; plan prices not verified).
- Refunds: 5 releases out of 40 reservations (12.5%), all on failures with no charge.
- Eval fourth1 (90 builds, $27.21): pass@1 76.7%, full 97.8%, boot 100%, repair share about 31% at snapshot; designer pass@1 70%, plain 95%, sound 85%, texture 63%; 2 asset-stage fails.

## 5. Gap analysis (ranked by likely demand)

Capability gaps (example prompts):
1. Real new blocks / items / mobs: "add a ruby ore block with its own model and tools" -> only note-block/display look-alikes; custom_blocks_new impossible. High demand, needs client mod.
2. Economy/permissions interop: "make a shop that uses Vault and LuckPerms ranks" -> refused by policy (self-contained).
3. Cross-server / DB: "MySQL-backed stats shared across my lobby and survival servers", "Discord webhook on kill" -> scan refuses network.
4. Better/bigger minigames: "full bedwars with arena reset and shop" -> partial, reset is weak.
5. Anti-cheat / claims logger / auction house -> gap.
6. Custom dimensions, big structures, advanced datapack (damage types, dialogs) -> missing.
7. Client-side polish: HUD anywhere, GUIs with custom screens, shaders -> impossible server-side.
8. Versions: 26.x not buildable; users on new versions or Folia/Spigot-only get nothing.
9. Other games: Rust/Palworld/Valheim/Hytale parked.
10. Import and fix an existing jar: "fix this plugin" -> import lane off/untested at scale.

Reliability gaps: creature builds fail flight (BetterModel not provisioned; fix not promoted); 2 false-fail Test Flight classes (clean_stop, Pack Loader jar missing) block good mods under BLOCK_ON_FAIL; texture first-try 63%; designer first-try 70%; planner lane recall 30%; hallucinated API compile errors; one stuck flight row; first-boot config bug fixed only on rc8+ images.
Speed gaps: p50 3 min, p90 7.4 min per build (saka), asset builds worse; one flight at a time; one build VM, 2 slots; AI backend session limit shared with agents.
Cost gaps: saka $0.64 avg on QA vs $0.30 eval; repair share 23-31% of spend; budget cap hit on spleef at $1.02 (caps since raised to 2.5/4); no live per-lane cost reporting; Anthropic Admin API key unset (cost margin preview unverified).
UX gaps: no real-client verification of any visual (pack, HUD, creature); preview is server-side/fake-CLI-driven; refine exists (baseBuildId used on 17/45 builds) but "explain what changed" and rollback UX not verified; designer edits reaching servers just landed; failed-flight banner/refine unpromoted; notifications unit-tested only.
Trust/safety gaps: ToS licence grant for library contribution (lawyer), trademark list stub, Mojang EULA/AI policy parked, telemetry privacy wording, copyright report abuse mitigations partial, no real-client safety review.
Operations gaps: subscription login (not API key), single build VM, single tank disk (backups to Dropbox restic added 10-14, owner must move keys/rotate token), no webhook for alerts, no uptime/synthetic monitor verified, launch-check beta NO-GO (backup now PASS; disk 83%), nginx fallback serves unknown paths to app, single account (no teams/multi-account), 0 API keys issued, DB URL appeared in old journal lines.

## 6. Top 25 improvements

| # | Title | Why | Evidence | Effort | Risk | Depends on | Owner type | Needs owner? |
|---|---|---|---|---|---|---|---|---|
| 1 | Switch build service to Anthropic API key | Subscription shares session limit; ai_unavailable failures | tracker 103, BUILD-SERVICE-ACCOUNT-SWAP.md | S | Low | key | Sonnet | Yes (key, billing) |
| 2 | Promote rc10-rc12 + image 0.17-0.19 | Fixes top repair class, creature depend, honest flights | tracker 107-109 | S | Med | idle service | Sonnet | Yes (paste/approve) |
| 3 | Promote BetterModel-in-flight fix | Creature mods falsely fail | BW report, BV batch | S | Low | #2 | Sonnet | Yes |
| 4 | Fix false-fail Test Flight classes (clean_stop, no Pack Loader jar) | Good mods blocked/flagged failed | 2 of 4 failed flights in DB | M | Med | none | Sonnet | No |
| 5 | Real-client test day (pack, HUD, creature, armor, blocks) | No visual ever client-verified | tracker section 5 | M | High if fails | tester | Opus | Yes |
| 6 | Raise texture/designer first-try (63% / 70%) | Cost + speed | fourth1 | M | Low | #2 | Opus | No |
| 7 | Planner lane recall (30%) | Wrong lanes = wrong cost/quality | fourth1 lane table | M | Low | none | Sonnet | No |
| 8 | Turn on starter bank for zero-token hits | $0 per hit; speed | tracker 102 | S | Low | image, price | Sonnet | Yes (price) |
| 9 | Accept eval baseline + gate in CI | Prevent regressions | eval-gate.ts | S | Low | baseline | Sonnet | Yes |
| 10 | Playtest stage in eval (0/90 run) | Boot != behaves | fourth1 stages | M | Med | bot per version | Opus | No |
| 11 | Multi-version verification (1.21.1/.4/.8 builds in production) | All 45 builds are 1.21.11 | DB | M | Med | #2 | Sonnet | No |
| 12 | 26.x compile lane (JDK 25) | New versions demand | matrix.json | L | Med | image | Opus | No |
| 13 | Capacity: second build worker / VM | One VM, 2 slots | scheduler.js | L | Med | infra | Opus | Yes (cost) |
| 14 | Alert webhook + synthetic uptime checks | No paging | tracker 106 | S | Low | webhook URL | Sonnet | Yes |
| 15 | Off-box backup hardening (key custody, token rotation) | Single disk | tracker 107 | S | Med | owner | Sonnet | Yes |
| 16 | Tighten nginx cyrus.my fallback | Proxies unknown paths | tracker 107 | S | Low | none | Sonnet | Yes (apply) |
| 17 | Library to production DB + browse UI | CyrusLibraryItem=0 | DB counts | M | Med | legal ToS | Sonnet | Yes (legal) |
| 18 | Legal pack: ToS licence grant, trademark list, EULA stance | Launch blocker | docs 12 | M | High | lawyer | n/a | Yes |
| 19 | Price/plan tokens finalised, daily cap tuning | 8/20 QA prompts hit 5,000/day cap | BV | S | Med | decision | Sonnet | Yes |
| 20 | Per-lane cost and refund telemetry in DB | Lane not a column; no token counts in ModBuild | docs 12 item 12 | S | Low | none | Sonnet | No |
| 21 | Vault/LuckPerms soft-depend interop lane | High demand | stillCannot | L | Med | policy decision | Opus | Yes |
| 22 | Refine/explain UX: change summary + rollback | Trust | CyrusRevision exists | M | Low | none | Sonnet | No |
| 23 | Import/fix-my-jar lane GA | Common request | import.js off | L | High | scan corpus | Opus | Yes (attestation) |
| 24 | Multi-account / teams / API keys UX | 0 keys, single owner | DB | L | Med | bridge decisions | Opus | Yes |
| 25 | Real-model prompt-coach validation on live prompts | Coach tuned on fakes | docs 12 | S | Low | live traffic | Sonnet | No |

Not verified here: production lane breakdown per build, build-VM env, current deployed image tag, notification delivery, any browser UI.

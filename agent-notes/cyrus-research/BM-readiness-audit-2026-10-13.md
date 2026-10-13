# BM: Cyrus readiness audit (2026-10-13)

Read-only audit. Code read at `/tank/dev-worktrees/cyrus-rc3` (release/cyrus-rc3, head 5ada5624f9). Prod state read with `scripts/cyrus/smoke-readonly.sh flags`, name+value-of-0/1 only from `/opt/nxeon/.env`, a read-only SELECT of `Setting`/`ModBuild`, and the build-service `/health` through the tunnel. No code, repo, env, setting or service was changed; no model call or build was made. No secrets in this file.

Labels: **V** = verified in code / test / flight / read-only prod read this session. **U** = estimate or inference (assumption stated). $ figures for paid model work are Sonnet-class (about $3/M in, $15/M out; U) unless stated.

## 0. Headline (5 things)

1. **Production today** (V): main = 6204e045ef (rc2 + hotfixes). Env ON: `CYRUS_DESIGNER, ITEM_STATES, CONFIG_STUDIO, CREATURES, DELIVERY, MANAGED_PLUGINS_REAL, TESTFLIGHT_GATE, TESTFLIGHT_BLOCK_ON_FAIL` (+ pack store local, sound relay). **Zero `cyrus_*` Settings rows** exist (203 Settings rows, none `cyrus%`), so every Setting is at its code default (public = false, tokens live = false). 30 ModBuild rows, 25 succeeded, all owner builds (V).
2. **rc3 is verified but not shipped** (V, tracker 92/93): coach, learning loop, warn-don't-block, weapons/testing, techniques, config delivery, goldens. Blocked on `devhost db push/build` (classifier), coach-events SQL, promote, image 0.10. Until then 8 flags/lanes below cannot even be turned on (code absent from prod).
3. **No real Minecraft client has ever loaded a Cyrus pack/texture/sound/model** (V; `resourcePackClientVerified=false` for all 7 versions). Every "supported" is server-side evidence (Paper boot + RCON + bots). This is the single biggest unproven claim and gates turning on armor, note-block blocks, grip fix, sound library, 26.x.
4. **Cost**: Saka is still on `claude-sonnet-5` (not 5.5), no effort routing, no token capture, plan screen under-states cost 2.1-2.5x on Saka/Katara-change (V, BL). Biggest no-code win: `MB_TIER_SAKA=claude-sonnet-5-5` + `CYRUS_LEARNING=1` + budget caps.
5. **Latent customer-server behaviour already in prod** (V code, effect U): perf-safety is default-ON; the post-install TPS watch default action is `disable` + restart, and `ENABLE_REAL_GAMEMODS=1` is set. `lib/cyrus/limits/inventory.ts:74` calls the default "notify" but `lib/cyrus/safety/perf-watch.ts:22` defaults to `disable`. Owner decision D-17 (docs/12 item 17) is still open.

Build-service `/health` oddities (V): `image:"0.5"`, `promptVersion mb-2026-10-11.1`, knowledge `rules-2026-10-11.2+nxperf-1` and `auth:"subscription"` while tracker says 0.9 is live (U: label not bumped by the deploy script, or the tunnel points at an older container; confirm on VM 88001 before trusting any "fix is live"). `versions` = 1.21.1/4/8/11 only; `features.dedupe=false, effort=null, cacheTtl=null, leanTools=true, autofix=true, catalogTools=true`.

---

## PART A. Flags and limits audit

Verdict key: **READY-TURN-ON**, **NEEDS-WORK(what)**, **OWNER-DECISION(what)**, **NEVER-YET**. "rc3" = needs the rc3 deploy first. Prod state: ON / OFF(unset) / DEFAULT (code default, unset in env).

### A1. Already ON in prod (for completeness, V)

| Switch | Evidence | Gap |
|---|---|---|
| CYRUS_DESIGNER, ITEM_STATES | designer flights r3/r10/r11, designer-weapons/techniques flights on 1.21.11 + 26.2 | no real client; other 1.21.x versions have no javac classpath for designer flights (V docs/12 3b) |
| CYRUS_CONFIG_STUDIO | config flights 10-10, config-delivery 19/19 x2 (rc3) | "Send to server" only in rc3 (prod returns 501 / dialog says "already has this version") |
| CYRUS_CREATURES (+ BetterModel 2.2.0 jar) | creature-r3 flights on 1.21.1/4/8/11, creature-paint byte-identical on 26.2 | first real use (troll build) failed on an unrelated repair loop, now fixed (0.9); look/animation never seen in a client; capability text still says "needs 26.x ... coming soon" (`minecraft-capabilities.ts:29-31`, V) |
| CYRUS_DELIVERY + MANAGED_PLUGINS_REAL | delivery-r5/r29 flights, honest rolled_back states, real worldgen rollback flight | `DATAPACK_DELIVERY_REAL` is OFF so data packs are not really delivered (see A2) |
| CYRUS_TESTFLIGHT_GATE + BLOCK_ON_FAIL | testflight-gate-r5 flight, 1 flight at a time on node-2 | no container limits; single node-2 lock |

### A2. Studios, lanes and technique flags (all OFF unless noted)

| Switch | Enables | State | Evidence | Blockers | Risk | Verdict |
|---|---|---|---|---|---|---|
| CYRUS_DATAPACK_STUDIO | datapack lane: recipes/loot/advancement/tag/function/enchantment/damage_type/jukebox/predicate/item_modifier from AI builds; planner offers `datapack` | OFF | datapack-r2 flights (+final), mc-coverage-datapack flights 10-11; service `features.assets` already lists `datapack` (V) | `CYRUS_DATAPACK_DELIVERY_REAL` OFF so pack "delivered" is not real; no client; no paid AI-spec run for datapacks (V docs/12 #2) | low (additive files in own namespace; per-version + rollback) | **READY-TURN-ON** after DELIVERY_REAL (below) |
| CYRUS_DATAPACK_DELIVERY_REAL | real delivery of data packs to servers (restart + rollback journal) | OFF | delivery-enqueue-r29 flights (loaded), datapack-r2 flights; real throwaway server rollback proven | restart policy owner decision (docs/12 #10); needs studio on to be useful | medium (touches customer server files; journalled) | **OWNER-DECISION**(restart automatic vs next-restart; keep dimension folders on uninstall) then ON |
| CYRUS_WORLDGEN (needs DATAPACK_STUDIO) | worldgen in data packs: own-namespace biomes/structures/dimension, new chunks only | OFF | worldgen-r4 flights (rollback proven + one real flight), structure-r45 flights | no jigsaw/template_pool (22.7% of reference datapacks use it, BF #20); 1 restart to load; RAM-heavy dimension; no AI-spec paid eval; coverage row `worldgen` has no golden | medium (RAM, restart) | **NEEDS-WORK**(one paid worldgen eval of ~10 prompts, RAM warning wired to plan screen; then ON for owner account first) |
| CYRUS_TESTFLIGHT_WORLDGEN | density probes (RCON `fill replace` counts) in gate flights; informational only | OFF (rc3 code) | mc-testing-flights 10-12 (flown 1.21.11 only) | rc3; D-57 says informational; coarse range | none (never blocks) | **READY-TURN-ON** after rc3, with WORLDGEN |
| CYRUS_MC_TECHNIQUES (portal) + MB_MC_TECHNIQUES (service), flip together | designer `break_block`, `vein_break`, `capture_mob`; prompt TECHNIQUES section | OFF | techniques-veins/captures/goldens/mutant-dupe flights 10-12 (1.21.11, dupe mutant fails as it must); rc3 re-flown | rc3 + image 0.10; no paid AI build with the new prompt sections (V docs/12 #19); new hard ceilings (range 256, pellets 64, blast 32, vein 256/64/32) are engineering choices, not owner-ratified (docs/12 3c); flights not re-run on the final Java constants | medium (vein flood-fill is perf; NxPerf budget + caps in place) | **OWNER-DECISION**(ratify ceilings D-59/60/62) then READY after one paid techniques eval (19 prompts in `eval/sets/techniques.jsonl`, about $2-4 U) |
| CYRUS_ARMOR_LANE | router adds armor lane: `assets/armor.json` -> worn looks in the pack | OFF | mc-coverage flights 10-11/10-12 (server side); golden `mc-armor`, `mc-armorset` | rc3; worn look never in a real client; registry `resourcePackClientVerified=false`; coverage row still "partial" | low (cosmetic; pack accept prompt) | **NEEDS-WORK**(real-client test-day step `armor.worn`) |
| CYRUS_NOTEBLOCK_LANE | router adds custom-block lane (note_block blockstates, `CustomBlocks`) | OFF | golden `mc-noteblocks`, coverage flights | rc3; server must set `block-updates.disable-noteblock-updates: true` (D-61 undecided: set on install?); no client; note-block instruments clash with real note blocks | medium (changes server.properties-class setting; breaks vanilla note blocks if wrong) | **OWNER-DECISION**(D-61) + NEEDS-WORK(client look) |
| CYRUS_HANDGUN_GRIP_FIX | corrects handgun display transform (default sits about 2/16 block off the hand in 3rd person) | OFF | golden-pinned: off = byte-identical; r30 | changes shipped packs; never seen in a client; "2/16" is computed, not observed | low-medium (alters every installed gun pack on update) | **NEEDS-WORK**(one client screenshot pair) then **OWNER-DECISION**; ON only after |
| CYRUS_LEGACY_TEXTURES (+ MB_LEGACY_TEXTURES) | 1.21.1 custom-model-data textures on 52 carrier items | OFF | legacy-r35 flight (Paper 1.21.1 6/6) | no client; 52-carrier clash risk; limits shown honestly | low | **READY-TURN-ON** for 1.21.1 only if owner wants 1.21.1 textures (U: 1.21.1 share is small); server-side only evidence |
| CYRUS_LIVE_ASSETS (portal + service) | live asset previews in the build screen | OFF (service `live:true`) | r48 replayed recording + fake CLI only | never run with a real model stream (V docs/12 #15) | low (UI) | **NEEDS-WORK**(one real build with it on, owner account) |
| CYRUS_DESIGNER_BUILDS / DESIGNER_DRAFTS | no-model designer edit builds (config-only repack / javac), autosave drafts | OFF | designer-ship-r31 real flight (cooldown 100, config v1->v2) | studio edits otherwise do not reach servers; needs `CYRUS_DELIVERY` (already ON) | low | **READY-TURN-ON** (zero tokens, real flight) |
| CYRUS_MODEL_DRAFTS (+ settings `cyrus_model_studio_enabled`, `cyrus_model_editor_enabled`) | Model Studio drafts table, layer-1/2 editors | OFF | creature-paint-r30 flight | SQL `2026-10-11-cyrus-model-drafts.sql` not applied (status unknown: smoke lists table); UIs follow unreviewed mockups | low | **NEEDS-WORK**(apply SQL; owner mockup review) |
| CYRUS_MESHGEN / MESHGEN_SCRATCH | AI mesh (layer 3), scratch scripts | OFF | meshgen flights 10-10 | no real model call, no isolated worker, no export target for Minecraft (glTF unsupported), CPU kernel-escape untested | high (arbitrary scripts) | **NEVER-YET** |
| CYRUS_ITEM_STATES | per-state item looks (pull/aim/charge) | ON | itemstates-r10 flights | 1.21.4+ only | - | ON |

### A3. Build quality, safety and test gating

| Switch | Enables | State | Evidence | Blockers | Risk | Verdict |
|---|---|---|---|---|---|---|
| CYRUS_PLAYTEST | playtest bots flown in the same flight; separate verdict, never blocks install | OFF | playtest flights (1.21.11 only); mc-testing 10-12 survival bot + `dig/sneak/use_on_entity/expect_*` steps | **generated builds store no ModSpec**, so verdict is "not run" for plain AI builds (V `gate-worker.ts:5-8`); only designer builds have a spec | none (informational) | **NEEDS-WORK**(spec capture for plain builds or a golden-style archetype test plan from the planner) ; turning on gives value only for designer builds |
| CYRUS_TESTFLIGHT_STRESS (default ON with PERF_SAFETY) | load phase after boot (40 s, TPS/entity verdict) | DEFAULT on | perf-flights, perf-golden 67/67, NxPerfCoreTest 33/33 | none | a FAILED stress blocks Install by default (`CYRUS_PERF_BLOCK_ON_FAIL`) | **OWNER-DECISION** D-17 (confirm block default) |
| CYRUS_PERF_BLOCK_ON_FAIL | failed stress blocks Install | DEFAULT on | stress.ts; unit tests | warn-don't-block rule says "confirmable warning"; inventory marks "left for owner" | customers can be blocked by a false fail | **OWNER-DECISION** (make it a confirmable warning = recommended, U) |
| CYRUS_PERF_WATCH + ACTION (default `disable`, restart on) | post-install TPS watch on customer servers; disables a lagging mod | DEFAULT on, acts because ENABLE_REAL_GAMEMODS=1 | perf-watch unit tests; no real customer-server run | doc/code disagree on default (see Headline 5); disabling + restart on a paying server is customer-visible | **high** | **OWNER-DECISION** (set `CYRUS_PERF_WATCH_ACTION=notify` until a real flight proves it; one-line env change, U) |
| CYRUS_TESTFLIGHT_BLOCK_ON_FAIL | refuse installs of builds whose boot flight failed | ON | gate flights | single flight at a time; flight infra outage could block installs? (U: gate fails closed only on a recorded fail) | low | keep ON |
| CYRUS_SERVER_DOCTOR | admin Server Doctor API | OFF | throwaway-server test only | real servers untested | low (admin read) | **NEEDS-WORK**(one real customer-shaped run) |
| CYRUS_HEALTH_TELEMETRY (+SECRET) | signed mod-health ingest | OFF | schema + unit tests | no collector; SQL draft not applied by design; wording needs lawyer | privacy | **NEVER-YET** (lawyer first) |
| MB_PERF_SAFETY | NxPerf watchdog injection + prompt rule 10 | DEFAULT on | NxPerf tests | none | - | keep |
| CYRUS_BYO_GAME_ASSETS + VANILLA_REFERENCE_DIR | customers import own vanilla assets (hash-verified, job-only) | OFF | r42 tests | legal (Mojang EULA parked), private reference dir | legal | **NEVER-YET** |

### A4. Cost, routing and token knobs (build service env on VM 88001 unless noted)

| Knob | Enables | State (V /health unless noted) | Evidence | Blockers | Risk | Verdict |
|---|---|---|---|---|---|---|
| MB_TIER_SAKA | model for Saka tier | default `claude-sonnet-5` | BL: Saka = 47-55% of spend; 0.3 eval measured 5.5 at 2-3 requests, 49% cheaper (U, earlier eval); owner build data n=11 | needs a $3 28-prompt eval (V BL) or accept risk | quality (medium) | **READY-TURN-ON** after one eval: `MB_TIER_SAKA=claude-sonnet-5-5` (-35..55% on Saka, U) |
| MB_MODEL_SIMPLE/STANDARD/COMPLEX | per-class model | all `claude-sonnet-5-5` (V) | routing score thresholds 3 / 7.5 | classes all equal = routing buys nothing except classifier; Haiku change builds regressed (BJ) | quality | **NEEDS-WORK**(measure: Haiku for simple fresh only; keep Sonnet for change builds) |
| MB_EFFORT (and B5 per-class effort, not built) | thinking effort for all calls | null | none measured | quality unmeasured; never below medium for codegen | medium | **NEEDS-WORK**(A/B 2 coverage-set runs, about $6 U) |
| MB_BUILD_BUDGET_USD / MB_CALL_BUDGET_USD | per-build/call cap | default 4 / 2.5 (docs) | max observed $1.55 (troll, failed) | none | low | **READY-TURN-ON**: `1.5` / `1.0` (V BL; legit Yakko mega-builds would hit "budget"; refunded) |
| MB_MAX_COMPILE_REPAIRS | own budget for compile repairs | live in 0.9 (default 2, V) | troll fix | none | - | done |
| MB_DEDUPE (+_MAX_AGE_H) | reuse an identical earlier build's source | **off** (`dedupe:false`) | key has no user id (V `server.js:1430` `dedupeKeyOf({prompt,mcVersion,pluginName,override})`) | cross-user source reuse breaks "never reproduce a user's mod" | legal/privacy | **NEVER-YET** (until curated starter-bank variant, B8) |
| MB_CACHE_TTL | prompt cache 5m vs 1h | unset | none | 5m only wins above ~15 builds/h per prefix | low | leave; re-check on API-key move |
| MB_LEAN_TOOLS, MB_AUTOFIX, MB_GUARD, MB_ROUTING, MB_REPAIR_CHEAP_FIRST | token savers | on (V) | | cheap-first repair not active on tier builds (`rec.override`, V BL row 6) | | keep; fix is backlog B10 |
| CYRUS_LEARNING (portal env, rc3) | stores per-call tokens/turns; admin Learning tab | OFF | 43 tests, report on 27 builds; BJ | rc3 deploy; **ModBuild stores no token counts today** (V) | none (no behaviour change) | **READY-TURN-ON** after rc3 (first item of the turn-on list) |
| CYRUS_PROMPT_COACH | score, missing details, optional 1-call rewrite | OFF | 72 tests / 43 golden prompts, 86/87 archetype recognition | rc3 + image 0.10 (`coach.js`) + coach-events SQL; panel never opened in a browser; rewrite only with fakes; not in customer-app New-mod flow | low (Nxeon pays about $0.01/rewrite, 6/min) | **NEEDS-WORK**(browser check + one real rewrite) then ON; decide lane-default behaviour |
| cyrus_tok_charge_refused | charge 5-token floor on guard refusals | `true` (default) | 10-12 06:52 false refusal: 5 of 220 tokens charged, 215 returned | none | low | **READY-TURN-ON** `false` (BL) |
| cyrus_tok_free_failures / _days | free failures per window | 3 / 7 | | | low | set 10 / 7 (BL) |
| cyrus_tok_reserve_table | hold sizes | defaults | BL: 20 of 25 builds exceeded shown range | calibration (B2) | trust | **NEEDS-WORK**(Setting JSON now, estimate code B2) |
| cyrus_tok_tokens_per_usd | pricing | 500 | | owner price decision | money | **OWNER-DECISION** |
| cyrus_cost_user_daily_cap_usd / platform_daily_cap_usd / alert_* | spend caps (0 = none) | 0 | tests | none | money | **READY-TURN-ON** once public (platform cap e.g. 25, U); harmless now |
| MB_ALLOWED_MODELS, auth = subscription | which models may be named; credential | unset; `subscription` | | **subscription login is not allowed for third-party customers** (GAPS #1) | **legal / launch-blocking** | **NEVER-YET** public until API key |

### A5. Launch, platform and customer-facing switches

| Switch | Enables | State | Evidence | Blockers | Risk | Verdict |
|---|---|---|---|---|---|---|
| cyrus_studio_public_enabled + cyrus_tok_live (the launch pair) | Cyrus building for every verified account + real token charging | false/false (V consistent) | admin pair guard tested; money journeys 27 DB tests | API key, Stripe live check, legal ToS, estimates calibrated, real-client day, eval baseline | money/legal | **NEVER-YET** (end of list) |
| cyrus_public_enabled, cyrus_mods_public_enabled, cyrus_passrate_enabled | public /cyrus, NxLabs pages, pass-rate page | false | r33/r40 | pass-rate page shows recorded numbers only: **no paid eval baseline exists** | marketing honesty | **NEVER-YET** until baseline.json exists |
| cyrus_import_enabled | import your own mod (source/jar/datapack/pack) | false | import-r2-real 10-10 flights; strict scan | attestation wording (lawyer), `CYRUS_MODPACKS` etc. | legal/security | **OWNER-DECISION** |
| CYRUS_MODPACKS / MODPACK_INSTALL_REAL | Mod Pack API + real installs | OFF | packloader flights, API tested (ack required) | no UI review; open-warning ack decided | medium | **NEEDS-WORK**(UI review) |
| CYRUS_CUSTOMER_APP | /home /new /account /projects on cyrus.my | OFF | r49 journeys 25/25 real browser | domain mode off; app does not show coach | low | **OWNER-DECISION** (needs CYRUS_DOMAIN_MODE + cyrus.my DNS/SSO) |
| CYRUS_DOMAIN_MODE | cyrus.my chrome + SSO both ways | OFF | r36 tests; Cloudflare parked for nxeon.cloud | cookie scope, /mods/cyrus SEO redirects (docs/12 #1) | money/auth | **OWNER-DECISION** |
| CYRUS_API_V1 (+_KEYS, webhooks) | public API v1 (6 live ops, 15 planned) | OFF | OpenAPI + contract tests; write endpoints over real HTTP unexercised (docs/12 #9) | no collector/outbox in SQL; owner: wallet/SSO/domain | money/security | **NEVER-YET** |
| CYRUS_PLATFORM_API, SERVER_GRANTS, PLATFORM_EVENTS | Nxeon side of the bridge | OFF | r49: one real Test Flight through Platform API with exact rollback | grants UI; consent copy | security | **NEEDS-WORK** |
| CYRUS_LIBRARY_BACKEND / BROWSE / CONTRIBUTE | library storage, browse, automatic community contribution | OFF | importer 60,970 rows into throwaway PG; 62,777 staged catalog rows | **contribution needs ToS licence grant (lawyer)**; "Use in project" 503 until backend; ffmpeg/gltf-transform missing | legal | BACKEND+BROWSE **NEEDS-WORK**(apply SQL, object store); CONTRIBUTE **NEVER-YET** |
| CYRUS_SOUND_LIBRARY_CLEARED | proprietary SFX usable in builds | OFF | sound flights; relay works | owner must confirm licensor ownership per file group (docs/12 #13) | legal | **OWNER-DECISION** |
| CYRUS_STORAGE (+ADDONS) | meter + server-side write gate | OFF | tests on Postgres; card add-on not run against Stripe | placeholders for quotas/prices; admin host not installed | money | **OWNER-DECISION** (pricing rule) |
| CYRUS_NOTIFY (+EMAIL), CONSENT, ATTRIBUTION, CONVERSIONS | bell, email, banner, tracking | OFF | unit tests, no Playwright | cyrus.my mailbox + SPF/DKIM; consent copy | privacy | NOTIFY **READY-TURN-ON** later with domain mode; rest **OWNER-DECISION** |
| cyrus_lifecycle_enabled, cyrus_compat_watch_enabled (+dry_run true) | broken warnings / auto-disable; stale-mod notices | false | lifecycle tests | acts on customer servers | high | compat_watch dry-run first: **NEEDS-WORK** |
| cyrus_ai_gateway_enabled, cyrus_mod_networking_enabled | mods call Nxeon AI / network | false (route is a 501 stub) | | stub only | high | **NEVER-YET** |
| CYRUS_TRY_IT / TRY_IT_EXPOSE | throwaway servers for guests | OFF | try-it r35 flight | public exposure, node-2 capacity (one flight at a time) | abuse/cost | **NEEDS-WORK**(capacity) |
| CYRUS_BUILD_MATRIX | multi-version build from one design | OFF | matrix-r35 flights (design flew on 4 versions; 26.2 refused) | not wired into builds route/store | low | **NEEDS-WORK** |

### A6. The version selector (registry.json)

Facts (V): `lib/cyrus/versions/registry.json` + `choices.ts`. 1.21.1/4/8/11 = `supported, buildable:true`; 26.1.2, 26.2, 26.3 = `preview, buildable:false` and show "Preview: not buildable yet" (`choices.ts:39`). `resourcePackClientVerified:false` on all seven. The registry note says "26.x stays preview until a real-client test passes".

**Why 26.x is preview (V):** (1) the production image has no JDK 25 / Gradle 9 / 26.x classpath built in (Dockerfile ARGs exist, "NOT RUN: no docker build", R0; `/health.versions` lists only 1.21.x); (2) no API sheet for 26.x (`services/modbuilder/sheets/` = 1.21.1/4/8/11 only, `gen-sheets.py` has no 26 branch); (3) no golden plugin or eval run on 26.x (goldens compile `--release 21`, harness 4 versions); (4) no real-client pack check; (5) 26.3 has no stable Paper (only BETA 169), `paperCoordinate:null`.

What already exists for 26.x (V): R0 proof (javac `--release 25` on Temurin 25.0.4.1 against paper-api 26.2.build.133-stable, major 69, scan clean, loaded + enabled on real Paper 26.2, /hellor0 works); classpath script `tools/gen-classpath-26.sh`; exact server pins (26.1.2 build 74, 26.2 build 133 sha256 recorded); pack formats read from server `version.json`; designer/weapons/techniques/creature (BetterModel 3.5.0) flights on 26.2; `javacFor()` already picks JDK 25 when registry marks a 26.x buildable.

**Evidence needed to promote each version (exact):**

| Version | status now | Evidence still missing for `buildable:true` / `supported` | Effort |
|---|---|---|---|
| 1.21.11 | supported | real-client pack/texture/sound/HUD check (test-day), paid eval baseline | owner day + about $10-20 U |
| 1.21.8 | supported | same; designer/bot flights only on 1.21.11 (no javac classpath for designer on others, docs/12 3b) | S-M |
| 1.21.4 | supported | same; plus Dialog/menu behaviours | S-M |
| 1.21.1 | supported | same; legacy emitter (`CYRUS_LEGACY_TEXTURES`) unclient-tested; 52-carrier clash | S-M |
| 26.1.2 | preview | (a) image with JDK25+Gradle9+classpath, `MB_VERSIONS` += 26.1.2; (b) 26.x sheet via javap (Adventure 5, registry-interface enums, Brigadier lifecycle) + 26.x failure rules; (c) goldens compiled `--release 25` booted in a flight; (d) one eval set run (coverage 108 + techniques 19) all-pass; (e) real-client pack format 84.0 check; (f) flip registry `buildable:true` + new `registrySha256` in release | L (about 2-4 agent days + about $15-30 U) |
| 26.2 | preview | same as 26.1.2 with pack 88.0 / data 107.1, Adventure 5 removals (`BookMeta`, ClickEvent), beds no longer block entities | L (shared with 26.1.2) |
| 26.3 | preview | blocked: needs a stable Paper build (only BETA exists); then identical list | blocked |

Recommendation (U): do 26.2 only (newest stable), keep 26.1.2 as follow-on, do not touch 26.3. Value is low until users ask: owners "drift to newest fast" (E-versions) so demand will come; cheaper than it looks because designer/creature lanes already fly there.

### A7. Turn-on-now list (ordered, expected effect)

Pre-condition for items 1-2: promote rc3 (devhost build + db push, coach-events SQL, promote, image 0.10). Items marked [now] need no deploy.

| # | Exact switch | Where | Expected effect | Risk |
|---|---|---|---|---|
| 1 [now] | `MB_BUILD_BUDGET_USD=1.5`, `MB_CALL_BUDGET_USD=1.0` | build-service env, rerun when no build runs | caps runaway builds at about 750 tokens (U) | low |
| 2 [now] | Setting `cyrus_tok_charge_refused=false`, `cyrus_tok_free_failures=10` | admin Settings | refused/false refusals cost 0; our failures stay free longer | low |
| 3 [now] | `CYRUS_DESIGNER_BUILDS=1` (portal) | env + restart | studio edits become zero-token builds that reach servers | low |
| 4 [after eval, $3] | `MB_TIER_SAKA=claude-sonnet-5-5` | service env | Saka -35..55% cost, 2-3 requests (U) | medium |
| 5 [rc3] | `CYRUS_LEARNING=1` | portal env (+service reads usage) | token/turn capture on new builds; enables path memory, calibrated estimates | none |
| 6 [rc3] | `CYRUS_PERF_WATCH_ACTION=notify` (decision) | worker env | stop auto-disabling customer mods until proven | removes latent risk |
| 7 [rc3 + image] | `CYRUS_PROMPT_COACH=1` after browser check | portal env | fewer vague-prompt rebuilds (23% of spend was rework, V BJ) | low |
| 8 | `CYRUS_DATAPACK_STUDIO=1` then `CYRUS_DATAPACK_DELIVERY_REAL=1` | portal/worker env | recipes/loot/enchant/advancement mods become real from one prompt | low-medium |
| 9 [rc3] | `CYRUS_TESTFLIGHT_WORLDGEN=1`, then `CYRUS_WORLDGEN=1` (after eval) | env | worldgen packs get density probes then are offered | medium |
| 10 [rc3 + image] | `CYRUS_MC_TECHNIQUES=1` + `MB_MC_TECHNIQUES=1` together | portal + service | vein miner / mob catcher / guns from one prompt | medium |

Turn-on-now list size: **10** (4 usable today without any deploy). Armor, note-block, grip fix and 26.x are deliberately not on it (need a real client).

---

## PART B. Minecraft one-prompt coverage matrix

Basis (V): `docs/cyrus/minecraft-coverage.md` (90 archetypes: 55 covered, 27 partial, 3 gap, 5 impossible), 67 golden plugins x 4 versions (hand-written; boot + RCON; "pass" proves harness/knowledge, **not** that the model writes it from one prompt), eval sets (289 prompts), real AI builds 25 successful (owner only).

Important caveat (V): the golden corpus is hand-written reference code. **No paid eval has measured one-prompt success per archetype** (0.3/v6 eval was 28 prompts on an older engine, docs/12 #2). So "supported" below = a lane exists + a golden proves the platform path; reliability from one prompt is **U** for all rows.

| Mod class | Supported today? / lane | Verified how | Known failure modes | Missing for reliable one-prompt |
|---|---|---|---|---|
| Items / weapons (abilities, cooldowns, projectiles) | Yes: plugin + designItem + texture + itemStates + sound | goldens `mc-weapon`,`mc-bows`; designer flights 1.21.11 + 26.2; weapons flights 10-12 (survival bot) | grip off-hand (flag off); beam/hitscan not seen visually; PvP/protection plugins untested | paid eval, client look, grip decision |
| Armor sets + set bonuses | Partial: plugin + texture; armor lane OFF | golden `mc-armorset`; server flights | worn look = only via pack; never in client | ARMOR_LANE on + client test |
| Mobs / bosses (vanilla base) | Yes: plugin + designBoss + sound | `mc-mobs`,`mc-pets`; designer boss flights | boss tested by creative bot before 10-12 (false passes); survival bot rc3 | survival-bot flights in prod gate |
| Creatures with custom models/animation | Limited: creature lane, BetterModel 2.2.0, invisible silenced vanilla mob | creature-r3 flights 4 versions, paint byte-identical on 26.2; troll build failed (repair loop, fixed 0.9) | Bedrock sees base mob; 57 libs download on first start; look/animation never in client; asset repairs cost $0.22 | one real creature build + client look; capability text stale |
| Blocks incl. custom blocks | Partial: furniture via display entities (model3d limited) + note-block lane OFF | `mc-furniture`,`mc-noteblocks` | no new block types/fluids (impossible); note-block clash; 1.21.9+ no spawn chunks | NOTEBLOCK_LANE + D-61 + client |
| Commands, utility, admin/chat tools | Yes: plugin + config | ~40 goldens pass 4 versions | `mc-ranks` perm-attach warn; Brigadier/Vault/PlaceholderAPI refused by rules, 62% of real plugins soft-depend PAPI | soft-dependency bridge policy (BF), economy ledger |
| Menus / GUIs / shops / dialogs | Yes (chest menus, admin shop, dialogues); dialog forms partial | `mc-shop`,`mc-warps`; designer menu flights | no player trading/auction (gap); custom GUI backgrounds not built | glyph-bg menus (BF #16), auction escrow (BF #19) |
| Quests / NPCs | Yes: designQuest; NPC partial | `mc-quest`,`mc-npc` | NPC = interaction entities only, no Citizens-class skins | NPC skins, dialogue trees |
| HUD | Limited: glyph HUD, boss bar, sidebar, action bar | `mc-bossbar`,`mc-sidebar`; hud flights | no free-form widgets/minimaps (client mod) | GUI sprites (BF #7) |
| Economy | Partial: plugin (own ledger, no Vault) | `mc-economy`,`mc-shop` | no Vault interop so no cross-plugin economy; auction gap | Vault bridge decision |
| Minigames / arenas | Partial: arena, parkour covered; duels partial | `mc-arena`,`mc-parkour` | arena reset weakest (world regeneration traps) | disposable arena worlds (BF #14) |
| Worldgen: biomes/structures/dimensions | Limited, **flag OFF**: data pack worldgen in own dimension | worldgen-r4 flights + rollback; 1 real flight | new chunks only; restart; RAM; no jigsaw | DATAPACK+WORLDGEN on, paid eval, template_pool |
| Ores | Partial via datapack/worldgen (own dimension) or plugin populator | `mc-structures`; probe `fill replace` | vanilla-world ores need new chunks | probes + worldgen on |
| Enchantments | Yes: datapack enchantment emitter + plugin | golden `mc-enchant` | datapack lane OFF; delivery not real | DATAPACK_STUDIO + DELIVERY_REAL |
| Recipes | Yes: datapack recipe emitter / plugin | `mc-recipes`; datapack flights | same flags | same |
| Advancements | Partial: 7 triggers | coverage flights | triggers beyond 7 unavailable | trigger set |
| Resource pack: textures | Yes (1.21.4+ item models), limited 1.21.1 | assets-r1/composition flights; texture library | **never loaded in a real client**; vanilla-lookalike check needs private ref dir | client day |
| Resource pack: sounds | Yes: synth + library, sounds.json, subtitles | sound-r1-real, relay flights | owner SFX not cleared (flag OFF); ogg encode on node-2 relay only | licensor confirmation, client day |
| Music / discs / ambience | Yes: `jukebox_song` emitter + ambience golden | `mc-ambience` | pack size; no client | client day |
| Models (3D static) | Limited: display entities wearing item models | model flights | no skeleton; GLB has no export target | by design |
| Fonts / glyphs | Yes for HUD glyph providers | HUD flights | no custom GUI backgrounds | BF #16 |
| Data packs (general) | Yes if DATAPACK_STUDIO on | datapack-r2 | OFF in prod | flags |
| Client-side mods (Fabric/NeoForge) | **No** (idea reference only, 29 other-loader mods) | none | impossible vanilla-client: voice chat, new blocks/fluids, minimaps | client-mod lane + .mrpack = L, not planned |
| Mod packs / import | Packs API ready (ack required), import API ready, both OFF | import-r2-real, packloader flights | attestation wording, UI unreviewed | owner decisions |

### B2. Top 10 gaps by user impact (ranked)

| # | Gap | Impact | Fix | Effort / model |
|---|---|---|---|---|
| 1 | No real-client verification of any pack, texture, sound, model, HUD, creature | every asset claim is unproven; one bad pack format breaks trust | owner test day with `test-day kit` (exists), update registry `resourcePackClientVerified` | S owner day; Sonnet for scripts |
| 2 | No measured one-prompt success rate (no baseline.json) | cannot claim "any mod from one prompt", cannot tune | paid eval: coverage 108 + techniques 19 on current engine (about $10-20 U, harness ready, V) | S; Sonnet to run |
| 3 | Vague prompts / wrong-lane routing (guard false refusal, router read a clause as a mod name, planner replaced plugin) | top product risk per owner; 23% of spend is rework | coach on, regression guard on change builds, "what stays/goes" check | M; Sonnet |
| 4 | Data pack + worldgen lanes OFF and not really delivered | recipes/enchants/worldgen are core "massive mod" parts | turn on per A7 #8/#9 after eval | S-M |
| 5 | Plain AI builds store no ModSpec, so playtest verdict is "not run" and surfaces cannot be diffed | tests prove "loads" not "works"; regressions on change builds | persist spec/surface for plain builds (reuse `learning/surface.ts`), archetype test plans | M; Opus design, Sonnet impl |
| 6 | Cost opacity: plan screen under-states 2.1-2.5x, Saka on Sonnet 5, no effort routing | users blame the product | B1 capture, B2 calibrated estimates, Saka 5.5 | S-M |
| 7 | Armor and custom blocks not wired to AI builds / not client-seen | "ItemsAdder-class" headline ask | lanes on + client day | S + owner |
| 8 | 26.x not buildable (no sheets/goldens/image) | 26.x servers cannot be targeted | A6 list | L |
| 9 | Missing archetypes: auction/escrow, anti-cheat, block logging, jigsaw structures, crates, skyblock | popular ask; 3 gaps + BF 77 missing techniques | BF top-20, recipes, goldens | L; Sonnet distill (Part C) |
| 10 | Real-plugin interop refused: Vault, PlaceholderAPI, WorldGuard soft-depends (62/38/27% of top plugins) | generated mods cannot plug into existing servers | owner policy change: soft-dependency bridge (BF) | M-L; Opus |

---

## PART C. Knowledge and training

### C1. Inventory (V counts)

| Asset | Where | Count / size | Licence / handling | Status |
|---|---|---|---|---|
| BA reference-mod corpus | `/tank/cyrus-library-staging/_reference-mods/` | 386 files, 918 MB on disk (`du`), 397 incl. metadata; plugin 173 / datapack 141 / resourcepack 43 / other-loader 29 | Modrinth-reported: ARR 95, MIT 88, GPL-3.0 33, LGPL 23, Apache 7, CC-BY-NC(-SA) 14, AGPL 6, CC0 4, MPL 3, custom/others (V from catalog.jsonl) ; permissive-usable about 102 (26%) | **private analysis only; never served, committed, pasted** (README rule). Aggregate facts only leave |
| BA analysis | `analysis/aggregate.json`, `per_item.jsonl`, scripts | class-file constant-pool census, plugin.yml, config structure, deps | derived facts | used |
| BD mod-tools survey | `BD-modtools-survey.md` + repo docs/onboarding/skills/tools | ranked repos (adopt now: mineflayer, MockBukkit, Spyglass, cloud, run-task, BetterModel...) | all MIT/Apache/MPL ones | partly used (mineflayer, BetterModel); MockBukkit/Spyglass/cloud **not** adopted |
| BF technique catalogue | `BF-mc-technique-catalogue.md` + json | 156 techniques: 38 covered, 41 partial, 77 missing | ours | batch 1+2 in sheets (50 rules); 3 designer techniques + armor/noteblock built; ~70 still missing |
| universal-modder notes | `/tank/cyrus-knowledge/universal-modder` | 2.1 MB, 74 game folders, 117 game notes, ~40 technique notes; Minecraft mostly Fabric/NeoForge client | MIT repo; field notes by agents | private; 11 skills vendored in repo docs; Minecraft findings (survival bot, ore probe, mutant check) distilled; other 73 games = game #2 input |
| MJP-Paper-Skills / Jahrome907 | via BF | 15+16 Paper/NMS skills | per BF | combat tag, per-player fx, disposable worlds pulled |
| Reference vanilla | `CYRUS_VANILLA_REFERENCE_DIR` | hashes/fingerprints | never in git | prod unset |

### C2. Already distilled into build knowledge (V)

| Form | Count | Where | Notes |
|---|---|---|---|
| API sheets | 4 (1.21.1/4/8/11), whole sheet injected, about 6.2k tokens | `services/modbuilder/sheets/*.md`, `api-facts*.json`, `verify-api-facts.py` (javap) | batch 2 verified; **no 26.x sheet** |
| Failure rules | 50 (`rules-2026-10-12.4` in rc3; prod 10-11.2) | `rules/failure-rules.json` | 18 -> 50 since 10-09 |
| Golden plugins | 67 dirs (66-67 plugins x 4 versions), 85 coverage archetypes | `golden/plugins` | hand-written |
| Eval prompts | 289 in 11 sets + 178-prompt harness | `eval/sets` | no baseline |
| Designer component library | item/menu/quest/boss/HUD/motion + technique kinds | `lib/cyrus/designer` | compiles Java with 0 tokens |
| Coach archetypes | 85 templates + 43 golden prompts | `lib/cyrus/coach` | |
| Capability catalogue | per-version lanes + reasons | `minecraft-capabilities.ts` + coverage json | text partly stale (creature) |
| Prompt sections | texture 916, sound 1.6k, datapack 2.5k, worldgen 1.9k, design 2.1k, ... up to +18k tokens | `prompts.js` | |

### C3. NOT yet distilled (V from BA/BF gaps)

| Item | Size | Value |
|---|---|---|
| About 40 Paper events and ~12 Player/World methods used by 5-60 of 173 top plugins but absent from sheets (BF c) | ~40 + 12 facts | high, cheap (deterministic + javap) |
| ~70 BF "missing" techniques (crates, skyblock, dynamic lights, lifesteal, jigsaw, economy ledger, SQLite write-behind) | 77 missing | high |
| Datapack variants outside spec: dialog, predicate use, item_modifier, damage_type, jigsaw template_pool/processor_list; `execute`-heavy function patterns | 141 datapacks, 23% template_pool | worldgen leap |
| Resource-pack patterns: GUI sprites (10/43), tooltip styles, core shaders (9%), fonts (9%), optifine CIT (30% legacy) | 43 packs | HUD/menu polish |
| Config conventions (median 47 keys, depth 3, 85% commented), permission naming (90% plugin-name prefix) | measured | Config Studio defaults |
| 73 other games' field notes | 117 notes | game #2+ |
| Recipes (verified implementation patterns) | **0 exist**; design only (BL-recipe-memory) | token savings 5-19% of spend (U) |
| Path memory / starter bank / NxKit | design only | see BL |
| 26.x anything | none | A6 |

### C4. Proposed distillation pipeline (mine reference mods into verified knowledge)

Hard rules (V policy): never copy or paraphrase GPL/AGPL/LGPL/ARR/CC-BY-NC code; only **aggregate facts** (API symbol sets, event sets, config key shapes, resource-pack/datapack file-type census) leave the corpus; authors write original implementations from our own goldens and javap-verified API facts; the corpus is never served, never an input to a customer build, never committed. Recipes must pass the similarity gate (8-gram shingle overlap vs corpus index and vs all stored user builds must be about 0).

| Stage | Input | Output | Method | Gate | Model / cost (U) |
|---|---|---|---|---|---|
| S0 Census refresh | corpus | `per_item.jsonl` + new facets (events per archetype, API pairs, config shapes) | deterministic python, no model (JDK now available on devhost for javap) | counts reproducible | $0 |
| S1 Gap list | S0 + sheets + BF | ranked missing facts (events/methods/techniques) per archetype with demand | deterministic diff | owner skim | $0 |
| S2 Fact verification | S1 symbols | `api-facts` rows verified per version jar | `verify-api-facts.py` (javap) | symbol exists in all listed versions | $0 |
| S3 Sheet + rule drafting | verified facts + failure signatures from builds | sheet sections (events catalog, block/world sheet, metas), precheck rules | Sonnet, batches of 30 facts: ~6k in / 2k out each | lint + 4-version javap; rules need a failing sample | 15 batches x about $0.05 = **$1-2** |
| S4 Recipe authoring | one archetype: BF technique + our golden + verified facts (no corpus code) | `recipes/<id>.json` (<=900 tokens, schema in BL-recipe-memory) | Sonnet; 8 seeds first then to 40 | schema lint, similarity gate, golden flies 4 versions | 40 x about $0.08 = **$3-4** |
| S5 New golden plugins | BF missing techniques | hand-written original plugin + `golden.json` RCON expectations | Sonnet writes, javac + Test Flight iterate (1-3 loops): about 25k in / 8k out each | compile 4 versions, boot, mutant check fails as it must | 30 x about $0.40 = **$10-15**; Opus only for jigsaw/worldgen design (about $5) |
| S6 Datapack/resource-pack emitters | S0 datapack/pack census + own spec | new emitter kinds (dialog, predicate use, template_pool, GUI sprites) | Sonnet implements emitters + schema; Opus designs jigsaw | emitter unit tests + one flight each | about **$8-12** |
| S7 Eval A/B | recipes + goldens | `recipeEffect` stats | `run_eval.py` coverage prompts with/without recipe, 2 runs | success and first-try not lower, cost per success lower | 30 archetypes x 2 x 2 x about $0.3 = **$36 (U)** (can start at 10 archetypes = $12) |
| S8 Review + release | candidate bundle | engine release record | human review (owner), `release-manifest.ts` eval gate, rollback pointer | rc gating, never auto-applied | $0 |
| S9 Mined rules from outcomes | CYRUS_LEARNING signals | failure-rule candidates (normalised javac signature + Paper symbol) | weekly SQL cluster + Sonnet summarise | n >= 3 builds, failing-first test | about $0.50 per week |

Estimated total first pass: **about $75-100 Sonnet** (S3-S7, U), Opus about $10-15 for designs. All spend is in batches that can stop at any stage; S0-S2 are free.

### C5. How recipe memory and the starter bank fit (V design, nothing built)

- **Recipe** = S4 output (verified pattern for one mechanic, <=900 tokens, injected into the first user turn, cache-safe). Selection is free: the existing Haiku guard returns up to 2 archetype ids from the closed list of 85; deterministic scorer cross-checks; wrong recipe is worse than none so inject only when `status:verified` and agreement.
- **Path memory** = weekly table (archetype, lanes, tier, fresh/change) -> success, kept rate, cost p25/50/90, best effort/recipe, n>=8; suggestions only; changes ship as gated engine releases.
- **Starter bank** (B8) = curated builds of template chips, served only by allowlisted key (never the cross-user `MB_DEDUPE`); re-runs validate/precheck/javac/scan on every serve; "ready-made, instant, ~5 tokens" on plan screen.
- **NxKit** (B9) = tested helper API (Cfg/Cmd/Store/Msg) so recipes carry less skeleton; later.
- Effect (U): 15-35% per hit build, hit rate 35-55%, so 5-19% of total spend; scaffoldable boilerplate is only 26% of code (4-10% of a plain build), the real gain is fewer repair loops.

### C6. Review gate for the learning loop (V)

Candidates (5 kinds) are written to a gitignored dir + `review.md`; nothing edits rules/sheets/prompts automatically; anonymised export (no request text, names, user ids, user code, imports); template sharing separate and opt-in; release manifest requires an eval gate and keeps a rollback pointer but is **not wired to deploys** (V BK). Keep it that way: human review of every candidate, eval before release, no model fine-tuning (Claude cannot be fine-tuned by Cyrus; "learning" = rules, sheets, recipes, routing).

---

## PART D. Multi-game and self-improvement

### D1. Game #2 gap analysis

State (V): adapters registered only for Minecraft. Records exist for terraria (phase knowledge, active), valheim (knowledge, active), zomboid (knowledge, active), hytale (capability, on-hold), fivem (research, on-hold). Palworld/Rust have engine template files + readiness docs but no onboarding record. Rubric (r47 judgement, U): Minecraft 90, Terraria 77 (TShock first), Hytale 75 (U-capped), Zomboid 69, FiveM 65, Valheim 63 (K1: every client installs).

| Gap | Evidence | Needed before game #2 |
|---|---|---|
| 9 cross-game contract gaps (language union lacks JS; artifact routes Minecraft-shaped; no animation/material asset kinds; two delivery vocabularies; TestLane cannot say "needs credential"; single-valued install side; two knowledge systems; generators not named in adapter; id mapping) | CASE-STUDIES.md (V) | fix in the adapter types first (Sonnet, M) |
| No non-Minecraft build service: a Paper-style sandbox, scanner, compile classpath, Test Flight server image per game | G-gaps (V, 10-09); Valheim harness tool exists (CYRUS_VH_*) | per-game build lane: **L** each |
| No per-game eval set, golden corpus, coverage matrix | `eval/games/` folder created by scaffolder, empty | 30 + 10 prompts and 5-10 goldens per game |
| Capability catalogue per game/version | only Minecraft (owner rule 42) | derive from adapter |
| Legal per game (Hytale GSP entitlement, FiveM, Workshop terms) | LEGAL docs, owner gates | owner/lawyer |
| Knowledge reuse: 74 games of universal-modder notes + 117 notes | `/tank/cyrus-knowledge` (private) | distil via same pipeline C4 (facts only) |
| Cost model per game (node-2 minutes + tokens) | proposed, not built | dashboard item #9 in IMPROVEMENTS |
| Patch-watch / policy-watch jobs | proposed #5/#6 | S, Sonnet |

Recommended game #2 (U): **Terraria via tModLoader/TShock** (MIT toolchain, server-side TShock plugins deliver without client install, rubric 77) over Hytale (policy/auth unverified, weekly EA changes) and Valheim (delivery knockout). Estimated effort: contract fixes M, build lane + scanner L, knowledge pack M, eval + goldens M; about 2-3 Opus agent-weeks + about $50-80 Sonnet (U).

### D2. Self-improving engine: what exists vs missing

| Stage | Exists (V) | Missing |
|---|---|---|
| Outcome telemetry | signals from ModBuild (rework, retry, regression, refusal, Test Flight fail) in `lib/cyrus/learning`; per-call token/turn capture behind CYRUS_LEARNING (rc3) | flag OFF; no javac/repair error text stored; no install-failure, player report, "kept using it" signal; one user's data (27 builds) |
| Mining | `learning-mine.ts`: 5 candidate kinds -> review.md | never reviewed; no recipe-pitfall / path-stat kinds (design only) |
| Eval | harness: 178 prompts, dry run, budget cap, resume; golden corpus 67 x 4 | no baseline run; no per-candidate A/B runner; no cost-per-success metric in the report |
| Gated release | `release-manifest.ts`: eval gate, rollback pointer | not wired to image build/deploy; prompt/rules/sheets version is part of image |
| Routing / estimates | classifier, tier routing, cheap-first repair | effort routing, calibrated estimates, path memory |
| Regression guard on change builds | surface diff in learning/ (branch `fix/cyrus-change-regression-guards` referenced) | not merged/wired as a build gate |

### D3. Ordered roadmap

| # | Step | Outcome | Effort | Model |
|---|---|---|---|---|
| 1 | Ship rc3 (db push, SQL, promote, image 0.10); fix `/health` image label | everything in A7 reachable | S, owner approvals | parent / Sonnet |
| 2 | Turn on CYRUS_LEARNING; paid baseline eval (coverage + techniques) | first measured one-prompt pass rate and token capture | S, $10-20 | Sonnet |
| 3 | Real-client test day (armor, blocks, sounds, grip, HUD, creature) | flips `resourcePackClientVerified`, unlocks A2 rows | S owner | - |
| 4 | Saka 5.5 + budgets + refusal-free + calibrated estimates (B2) | -35..55% Saka cost, honest plan screen | S-M | Sonnet |
| 5 | Regression guard on change builds + spec persistence for plain builds | fewer dropped commands; playtest meaningful | M | Opus design, Sonnet impl |
| 6 | Pipeline S0-S3: events/method sheets, rules from outcomes | fewer repair loops | M, $2-5 | Sonnet |
| 7 | Recipe memory v1 (B6): 8 seeds, guard returns ids, A/B | 5-19% cost, higher first-try | M, $12-40 | Opus schema, Sonnet recipes |
| 8 | Path memory + admin tab (B7); mined candidates to review queue | self-tuning defaults, still review-gated | M | Sonnet |
| 9 | Starter bank (B8) for the template chips | instant zero-token common mods | M | Sonnet |
| 10 | Worldgen leap: jigsaw/template_pool, processor_list emitters | big structures from one prompt | L | Opus design, Sonnet impl |
| 11 | 26.2 lane (A6 list) | latest Paper targetable | L | Sonnet with Opus review |
| 12 | Game #2 contract fixes then Terraria lane | multi-game | L | Opus |
| 13 | Release manifest wired to deploy + weekly eval gate | automated but gated improvement loop | M | Opus |

### D4. Cautions (V)

- Subscription auth is a launch blocker, not a tuning item.
- Every "self-improving" step must stay candidate -> human review -> eval -> engine release; no automatic prompt/rule changes in production.
- Cost estimates in this report are U; replace after step 2 data exists.

## Files referenced
`/tank/dev-worktrees/cyrus-rc3/lib/cyrus/admin/flags.ts`, `.../versions/registry.json`, `.../docs/cyrus/minecraft-coverage.md`, `.../docs/cyrus/12-gaps-and-roadmap.md`, `.../lib/cyrus/safety/perf-watch.ts`, `/root/claudeskills/agent-notes/cyrus-research/{CYRUS-TRACKER,BA,BD,BF,BJ,BK,BL-recipe-memory-design,BL-token-savings-plan,R0-26x-lane,E-versions}.md`, `/tank/cyrus-library-staging/_reference-mods/`, `/tank/cyrus-knowledge/universal-modder/`.

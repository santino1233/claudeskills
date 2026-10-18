# GO-LIVE rc22 (2026-10-18): ship, then switch on in waves

Owner ask: "Everything that is currently sitting in staging or turned off or that needs to be done, let's just do it right now."
This page is the plan for that. The coordinator runs every production step. Nothing below has been switched on by the assembling agent.

- Ship: `bash /root/claudeskills/agent-notes/cyrus-research/ship-rc22.sh --plan`, then run it again without `--plan`. It prompts before every production step.
- Release: `release/cyrus-rc22` (worktree /tank/dev-worktrees/cyrus-rc22), built on main af5a1d55, which is the live rc21. The verification results are in section 0.
- The flag state below comes from the NAMES in /opt/nxeon/.env, read 2026-10-18 ~13:30 UTC. No values were read.
  - Every one of the 56 CYRUS_/MB_/ENABLE_ names in that file is non-empty and not 0/false.
  - The web and the worker share that one file (both units use `EnvironmentFile=/opt/nxeon/.env`).
  - The build service's state comes from its live `/health`.
  - VM env: MB_TIER_SAKA=claude-sonnet-5-5, MB_CACHE_TTL=5m and MB_WORKSPACE_MAP=1 were applied 2026-10-18 (tracker 121). /health confirms cacheTtl 5m, auth subscription, prompt mb-2026-10-17.1, breaker closed.

How to apply a switch:
- **web/worker (.env):** add the line to /opt/nxeon/.env, then `systemctl restart nxeon-web nxeon-worker`. That causes a few seconds of 502s.
- **Build service (VM 88001):** add the line to `/root/modbuilder.env`, then re-run `run.sh`, or `TAG=<live tag> bash scripts/cyrus/deploy-modbuilder.sh`.
  - run.sh only passes MB_STARTER_BANK and MB_RECIPES through from the caller's shell. Every other MB_ knob must be in modbuilder.env.
  - Take a backup `cp modbuilder.env modbuilder.env.bak-$(date +%s)` first.
- **DB setting:** set it in Admin > Cyrus > Settings.
- Rollback for any switch: remove the line and restart the same unit.

---

## 0. What rc22 contains and how it was verified

| # | Merge | Branch head | What it brings (all new switches OFF) |
|---|---|---|---|
| 1 | 5c6d18f9 | fix/cyrus-ai-outage-handling 7b0f830b | Weekly, monthly and quota AI limits now fail fast and free, with an honest "at capacity until ~HH:MM UTC" message. New builds are refused at submit (503 capacity, aiLimit/resetAt) and queued ones fail free. `/health` capacity.breaker gains hard/resetKnown. Short 429s still retry. |
| 2 | 2e54239a | feature/cyrus-efficiency f5fb7c56 | Service knobs: MB_SESSION_FREEZE, MB_ESCALATE_KIND (+MB_ESCALATE_AFTER), MB_REPAIR_CALL_USD, MB_ESCALATE_CALL_USD, MB_EFFORT_CLASS, MB_CHANGE_HYGIENE. Portal: CYRUS_CHANGE_COST_HISTORY. Worker: CYRUS_TESTFLIGHT_GATE_EVERY_S. Eval: `--model-id`. |
| 3 | d5bf5e43 | feature/cyrus-bundle-b bcf45a93 (f2e89c01..bcf45a93) | Beta journey fixes. CYRUS_TOK_SETTLE_V2. The 90 s lost-grace (always on). Admin: reasons on money actions, guard-refusal review/reopen, user search, per-user storage, Alerts panel. OIDC skeleton (NXEON_OIDC_PROVIDER). The cyrus.my/admin-host scripts refuse to run nginx on the primary. |
| 4 | 270475bc | feature/fast-deploy 29fb2453 | FAST_DEPLOY machinery (off unless `--fast`), `deploy-modbuilder.sh --check`, scripts/ship-fast.sh |
| 5 | 97f7ce4b | docs/cyrus-status-audit c9a7f032 | Docs D-72..D-82, history and status refresh |
| 6 | 9cde15d4 | rc22 small fixes | See the list below this table. |

Details of row 6 (rc22 small fixes):
- The guard smoke now polls the FINAL build record for up to 6 min.
  - A refusal (errorCode refused or guard.verdict refuse) records ok.
  - A build that has not finished records `pending`, and an AI limit records `unavailable`. Launch-check shows both as WARN, not FAIL.
  - This fixes the 0.26 false negative.
- backup-nightly.sh uses `LC_ALL=C sort` on both sides of the sfx mirror hash, and for the manifest.
- launch-check never runs `nginx -t` on the primary (D-82). The row reads INFO "skipped" and gives the node-2 command.
- Player tracking strips NUL and control characters from names (`cleanPlayerName`).
  - Live symptom: Postgres 22021 `0x00` every minute for one server since at least 13:18 UTC.
  - No branch existed for this, so the fix was written here.

Merge conflicts were all in docs:
- docs/cyrus/25-build-service.md: kept both rows' facts.
- flag-notes.json: union of both sides.
- Generated references (flags-and-env, tests, build-service): took HEAD, then regenerated with docs-build.

`services/modbuilder/server.js` auto-merged (outage + efficiency) and is covered by the capacity and efficiency suites.

Not merged, because they were still being worked on or are old:
- Still in progress: feature/cyrus-minecraft-seo, -room-studio-v2, -mob-skin-studio, -ux-audit (and wip/cyrus-ux-quickwins), -marketing-overhaul, -bundle-a, feature/cyrus-newfeat (bundle D), the wizard design.
- Old and behind main by 800 to 1400 commits: v6-library, v6-game-rust and v6-game-palworld, plus creator-promo, terraria-listener, workspace-gateway, vps-ram-allocation, coldemail-creator-campaign and game-config-envkey-audit.
- feature/cyrus-library-prod is already in main: 0 commits ahead, its 5 serving fixes are live.

Verification (node-2, `devhost --lock`, NODE_OPTIONS=--max-old-space-size=8192): see "VERIFY RESULTS" at the end of this file.

---

## (a) Everything built but OFF in production, in waves

Notation:
- **W** = web .env, **K** = worker (same .env), **S** = build-service env (VM), **DB** = Admin setting.
- "rc22" means the code only exists once rc22 is live.

### Wave 1: safe today (production today or right after rc22; no customer money or legal exposure)

| # | Switch | Where | What it does | Prereqs | Risk | Smoke |
|---|---|---|---|---|---|---|
| 1.1 | Re-run the guard smoke on the live image | ship-rc22 step 5 runs it | Clears launch-check's `guard-smoke` FAIL. That FAIL was a false negative: the 10:20 re-run refused correctly. | rc22's deploy-modbuilder.sh | none (one Haiku call) | `/var/lib/cyrus/guard-smoke.json` result `ok` |
| 1.2 | `CYRUS_ADMIN_SUMMARY=1` | W | Adds a read-only Cyrus card to the Nxeon admin home | none | none (staff only) | the card is on /admin |
| 1.3 | `CYRUS_CAPACITY_UI=1` | W | Adds a plan-screen line with the builder queue and typical wait, from /health capacity | none | none (wording only) | POST /api/cyrus/plan has `capacity` |
| 1.4 | `CYRUS_TESTFLIGHT_GATE_EVERY_S=20` | K (rc22) | Test Flight gate sweep every 20 s instead of 120 s, so "verified" lands about 50 s sooner (EA F). Each idle tick is one SELECT. | CYRUS_TESTFLIGHT_GATE=1 (already on) | very low | time from build done to `testFlight` on the record is under 40 s |
| 1.5 | `MB_SESSION_FREEZE=1` | S (image 0.27) | Calls that resume a session reuse the first call's system prompt and effort. This fixes the prompt-cache break on design-downgraded builds (EA A: $9.96 of $218, 4.6 %). | image 0.27 (ship step 5) | ~0 quality risk | /health `features.sessionFreeze: true`; `sysFrozen` on the next refine's call record |
| 1.6 | `MB_ESCALATE_KIND=1` (MB_ESCALATE_AFTER stays the default 2) | S (0.27) | A tier build escalates to Opus only after 2 failed repairs of the same kind, never for a small compile problem (EA B: 5/5 escalations, $5.14 -> about $0.53) | 0.27 | low (a hard repair escalates one round later) | /health `features.escalate {kind:true, after:2}` |
| 1.7 | `CYRUS_CHANGE_COST_HISTORY=1` | W (rc22) | A refine's plan range and the top of its hold are never below the mod's last refines (EA G: over-hold charges 48 -> 9). Holds rise, the charged amount does not. | none | money-neutral (bigger holds, honest "up to") | a refine plan on the owner's dungeon shows a higher range |
| 1.8 | `CYRUS_TOK_SETTLE_V2=1` | W **and** K (rc22, same value on both) | Never charge above the hold. Our-side failures are free (interrupted, unreachable, lost, internal, timeout, admin_cancelled, budget, and failures after the service dropped part of the request). The sweep keeps running holds. Decision B-1 "yes, before W0". | none | lowers revenue slightly, removes overcharging | log `charged the hold (settle v2)`; plan response `settleV2:true` |
| 1.9 | Guard-refusal free charging | DB | ALREADY IN EFFECT: `cyrus_tok_charge_refused=false` is stored (EC, B-3 "refusals free during the beta"). Nothing to do. Keep `cyrus_tok_charge_cancelled` at the default (charged). | - | - | admin Settings shows false |
| 1.10 | `CYRUS_ALERT_DISCORD_WEBHOOK=<url>` | /etc/cyrus/alerts.env | Sends alerts somewhere (two rules are firing with no receiver) | the owner creates the webhook | none | `bash scripts/cyrus/alert-check.sh --dry-run` lists the target |
| 1.11 | `cyrus_mail_from=<x>@cyrus.my` | DB | Lets invites and notifications send by themselves. Today invites go by hand. | cyrus.my SPF/DKIM/DMARC (DM) | deliverability | Admin > Cyrus > Beta invite send without the "sender not set" error |

Wave 1 order:
1. Ship rc22 (this covers 1.1 and the image for 1.5/1.6).
2. One line each: 1.2, 1.3, then 1.4, 1.7, 1.8 (one web+worker restart covers all of them).
3. Then 1.5 and 1.6 on the VM (one restart).
4. Then watch 5 portal builds and 2 refines.

### Wave 2: after rc22 is live and wave 1 has run for about a day (each needs one supervised check)

| # | Switch | Where | What / why | Prereqs | Risk | Smoke |
|---|---|---|---|---|---|---|
| 2.1 | Catalogue tools: `CYRUS_CATALOG_TOOLS=1` + `CYRUS_CATALOG_INDEX=<file>` (+ optionally `CYRUS_VANILLA_CATALOG=1`) | W | The build model gets `catalog_search`/`catalog_get` over a pre-gated pool of at most 32 rows (plan tier, licence, proprietary clearance, published only). It records picks as library slots. See "Catalogue tools" below for whether builds really reuse assets and for the index file. | the index file installed (below); svc `features.catalogTools: true` (already true on 0.26) | cost: up to 8 tool calls per build; first real CLI use of `--mcp-config` in `-p` mode | one owner build "a sword with a wooden door sound": the build record has `catalogOffered` + `librarySlots`; journal line `[cyrus] catalog offer skipped` absent |
| 2.2 | `CYRUS_VANILLA_REFERENCE_DIR=/tank/cyrus-library-staging/_reference/vanilla` | W | Turns on BYO verification (CYRUS_BYO_GAME_ASSETS=1 is already on but fails closed: "verification is not available on this server yet"). **It also turns on the vanilla look-alike check in asset sync.** | dir readable by `nxeon` (755/644: ok); only version 26.1.2 is in it (see (b)) | **customer-visible**: a returned texture that matches a vanilla fingerprint (IoU/shading >= 0.9) is now DROPPED from the build with "left out: it did not pass Nxeon's texture checks". This is a legal upside but has false-positive risk on simple 16x16 art. | Texture Studio > Minecraft tab no longer shows the lock; verify one jar; watch 10 builds' `assets.dropped` |
| 2.3 | `MB_CHANGE_HYGIENE=1` | S | Adds a CHANGE EFFICIENCY block to refine user turns (est. 15-25 % of change cost IF followed). Not A/B'd. | A/B first: 5 refines on/off (~$5) | prompt change on refines | /health `features.changeHygiene: true` |
| 2.4 | `MB_EFFORT_CLASS=simple=low,standard=medium,complex=high,recipe=lower` | S | Effort by guard class, overrides MB_EFFORT_MAP for rated builds. Est. -15 s and -$0.03 per simple build. Not A/B'd. | A/B (5 simple prompts) | quality on simple builds | /health `features.effortClass` |
| 2.5 | `MB_REPAIR_CALL_USD=1.2` / `MB_ESCALATE_CALL_USD=1.5` | S | Tail caps per repair call (largest Opus repair seen: $1.80) | none | a capped repair can fail a build that would have passed | /health `repairCallUsd` |
| 2.6 | `CYRUS_TESTFLIGHT_ORACLE=1` | K | The behaviour oracle flies in the Test Flight. It is informational and never changes the boot verdict. | gate on (yes) | node-2 load (it is overloaded today), longer flights | `cyrus.testFlight.functional` on a build |
| 2.7 | `CYRUS_PLAYTEST=1` | K | Playtest bots in the same flight. They never block. | gate on; builds with a stored ModSpec | node-2 load | `testFlight.playtest` present |
| 2.8 | `CYRUS_SERVER_BUTTON=1` | W | "Create a mod for this server" on paid Minecraft server pages (Mod Builder users only) | none | low, customer-visible link | the button is on a server page |
| 2.9 | `CYRUS_PUBLISH_CHECK=warn` | W | Lints a mod listing when it goes PUBLIC and returns the report. It does not block. (The code comment says the default is warn; the real default is off.) | none | none in warn | saving a public listing returns `publishReport` |
| 2.10 | `MB_PREFLIGHT` stays `advise` (default); `MB_MEMBER_INDEX=1`; `MB_SPYGLASS=warn` | S | Member index: "did you mean" rewrites in compile repairs (low risk). Spyglass warn: data/resource pack warnings (bundle A recommends warn). | image built them (Dockerfile) | low (warn only; never `enforce` yet) | /health `features.spyglass.versions` non-empty |
| 2.11 | `CYRUS_MODPACKS=1` | W | The Mod Pack API + /dashboard/cyrus/packs (compose / validate / install as one delivery job). `CYRUS_MODPACK_INSTALL_REAL=1` and `CYRUS_DELIVERY=1` are already on. | none (file store under modbuild dir) | writes to customer servers on install (every warning must be acknowledged) | GET /api/cyrus/modpacks/v1 404 -> 401 |
| 2.12 | FAST_DEPLOY for the NEXT ship | ship script | After rc22: on a quiet node-2, `FAST_DEPLOY=1 scripts/deploy-staging.sh --dry-run`, then `FAST_DEPLOY=1 scripts/promote-production.sh --dry-run` (expect "REUSING the artifact"). Then rc23 ships with `FAST=1` or `scripts/ship-fast.sh`. | NX test plan steps 2-4, 6, 7 | see NX report Risks | `[timing]` SUMMARY; `journalctl -u nxeon-web` stop within 15 s |

### Wave 3: needs an owner decision first (the decision is in bold)

| # | Switch | Where | Decision needed | Notes / risk |
|---|---|---|---|---|
| 3.1 | API key for the build service (`API_KEY=... deploy-modbuilder.sh`) | S | **Buy and attach an Anthropic API key (separate org, D-17) before beta W0 grows beyond 2-3 testers?** | Public-launch blocker. Not needed for catalogue tools (see below). |
| 3.2 | `CYRUS_HONEST_ESTIMATE=1` | W | **Accept the measured cost classes for holds and plan cards?** | money: holds and "up to" numbers change |
| 3.3 | `CYRUS_MEGA_STAGING=1` | W | **Split huge requests into staged builds, each with its own hold?** | money/UX: several holds; EC default "use it for Gloam-size requests" |
| 3.4 | `CYRUS_CODE_CORE=1` | W | **Roguelike / instanced-world requests drop the designer and worldgen lanes?** | product behaviour |
| 3.5 | `CYRUS_STARTER_BANK=1` (W) + `MB_STARTER_BANK=1` (S) | W+S | **Flat price `cyrus_tok_bank_charge` (default 5) for ready-made mods?** | 0 hits on 109 real prompts (EA): little value now |
| 3.6 | `MB_RECIPES=1` | S | **Accept non-byte-identical first turns (20 % holdback A/B)?** | 4/29 hit rate |
| 3.7 | `MB_BOSS_MODEL=1` | S (modbuilder.env) | **Bosses wear creature rigs before a real-client creature check?** | creatures never proven on a real client |
| 3.8 | `MB_LEGACY_TEXTURES=1` (S) + `CYRUS_LEGACY_TEXTURES=1` (W) | S+W | **1.21.1 custom-model-data textures (can clash with other packs)?** | bundle A recommends it for 1.21.1 |
| 3.9 | `CYRUS_ANALYTICS=1` | W+K | **Privacy/consent wording OK? Apply `2026-10-15-cyrus-analytics.sql`?** | first-party beacon, no IP, 90-day raw data |
| 3.10 | `CYRUS_NOTIFY=1`, then `CYRUS_NOTIFY_EMAIL=1` | W+K | **Apply `2026-10-11-cyrus-notifications.sql`; set `cyrus_mail_from`; cyrus.my mail DNS** | new sender domain |
| 3.11 | `CYRUS_DATA_JOBS=1` | K+W | **Run GDPR exports/deletions automatically (14 day grace, CYRUS_GDPR_ERASE already on)?** Apply `manual-migration-cyrus-r44-data-jobs.sql` if the r44 columns are missing; CYRUS_DATA_EXPORT_DIR writable by the worker, readable by web | data/legal |
| 3.12 | `CYRUS_API_V1_PERSONAL_KEYS=1` | W | **Customers may mint API keys?** (needs the `CyrusPersonalApiKey` table, same r44 SQL) | security/abuse |
| 3.13 | `CYRUS_LIBRARY_AUTOPUBLISH=1` | W | **Lawyer-reviewed licence clause; who runs `library-publish-sweep.ts --apply`?** | puts the Terms clause live; nothing publishes until the sweep script is run (no timer exists) |
| 3.14 | `CYRUS_TRY_IT=1` (+ `_EXPOSE`) | W | **Throwaway Paper servers on node-2 (node-2 is overloaded and hosts customer VMs)?** | resources; public ports with EXPOSE |
| 3.15 | `CYRUS_SERVER_DOCTOR=1` | W | **Staff may read customer server files (audited)?** | privacy |
| 3.16 | `CYRUS_MOD_SUITES=1` | W+K | **Store ModSpec v2 (cannot go back: v2 specs become unreadable if turned off)?** | one-way door |
| 3.17 | `NXEON_OIDC_PROVIDER=1` | W | **B-10: issuer `id.nxeon.cloud` (DNS + cert) and the M3 SQL** | skeleton only (discovery + JWKS); nothing can authorize |
| 3.18 | Secret admin host `CYRUS_ADMIN_HOST`, later `CYRUS_ADMIN_HOST_ONLY=1` | W + nginx | **B-11: apply `deploy/cyrus/admin-host-apply.sh` (syntax-check on node-2 only)** | nginx change |
| 3.19 | `CYRUS_STATUS_PAGE=1` | /etc/cyrus/alerts.env + nginx snippet | **A public status page on cyrus.my?** | needs `nginx-cyrus-status.conf.snippet` (not installed) |
| 3.20 | Launch pair `cyrus_studio_public_enabled` + `cyrus_tok_live`, CyrusPlan prices, live payment test | DB | **Prices, legal, the live payment test (EC 9.3/9.4)** | the public launch, last |
| 3.21 | `CYRUS_MC_SEO`, `CYRUS_PUBLIC_BUILDER` | - | not in rc22 (branch feature/cyrus-minecraft-seo, still in progress) | - |
| 3.22 | Upload store (`CYRUS_UPLOAD_*`) | - | **Production upload storage (owner decision pending)**: the code refuses uploads in production even with the env set (lib/cyrus/studios/deps.ts:89) | a code change is needed, not a switch |
| 3.23 | Sound ledger 185/611 undecided while `CYRUS_SOUND_LIBRARY_CLEARED=1` | W | **Decide the rows or turn clearance off** (EC 9.5) | legal |

### Catalogue tools (CYRUS_CATALOG_TOOLS / CYRUS_CATALOG_INDEX)

**Is the API key a hard requirement? No.** The runbook's "Step 4 (API key)" is a launch and cost policy. The code does not check it:
- Nothing in build-wiring.ts, build-offer.ts, catalog.js or catalog-mcp.js looks at the auth kind.
- The CLI gets `--mcp-config` + `--allowedTools mcp__cyrus_catalog__*` whatever the login.
- `/health` already says `features.catalogTools: true` on 0.26.

So the tools work on the subscription token, with two cautions:
- Every tool call spends from the same weekly limit (at most 8 per build).
- The real CLI has never run the MCP server in `-p` mode (Y report). Make one supervised owner build the first real test.

**Do builds REUSE library assets? Not yet.** Picks are only recorded:
- The model writes assets/library.json.
- The service checks the refs and returns `librarySlots`, which the portal stores on the build.
- Nothing places library bytes into the jar or pack (catalog.js:12-15, build-offer.ts:8-10). `resolveSlotForBuild` (lib/cyrus/library/backend/use.ts:75) has no callers.

The only path where library bytes reach a mod today is the studios' **Use in project** (Library tab, CYRUS_LIBRARY_BROWSE + BACKEND, both on). It copies the asset into the project as an "asset" revision.

What is missing for real reuse (code, not a switch):
- A delivery step that turns each `librarySlots` pick into a project asset. This is the same sink as Use in project, `fileProjectSink`, after the plan/licence re-check, and it would run when the build succeeds.
- The texture/sound packers then ship them.
- Without that, turning the tools on mostly gives data (what the model would reuse) at a small token cost.

**The index file:**
- The builder is `scripts/cyrus/library-import.ts --entries <jsonl> --sqlite <file>` (SQLite v2 posting-list index, ranked the same as the Postgres one).
- Source: `/tank/cyrus-library-staging/catalog-v2/entries3-staged-cc0.jsonl`. This is the same file the production DB import used (62,777 rows, 0 refused by the licence gate). CC-BY rows are dropped by default.
- Built by this agent: see "VERIFY RESULTS" for the file, size and row count.

**Where the file must live:**
- In a directory the web user `nxeon` can WRITE. The reader opens it read-write with WAL journalling and creates `-wal`/`-shm` files next to it. A wrong `PRAGMA user_version` makes the reader DROP the tables and the offer silently becomes null.
- Recommended: `/tank/cyrus-library-store/catalog-index-v2.sqlite`. That directory is owned by nxeon (750), and /tank has 2.6 TB free.

Install (coordinator):
```
install -o nxeon -g nxeon -m 640 /tank/cyrus-rc22-artifacts/catalog-index-v2.sqlite /tank/cyrus-library-store/catalog-index-v2.sqlite
printf 'CYRUS_CATALOG_TOOLS=1\nCYRUS_CATALOG_INDEX=/tank/cyrus-library-store/catalog-index-v2.sqlite\n' >> /opt/nxeon/.env
systemctl restart nxeon-web
```

Rebuild the index whenever the catalogue changes. The prod DB is the store of record; the SQLite file is a cache. A Postgres provider for build wiring does not exist yet. The browser already uses Postgres when BACKEND=1.

Rollback: remove the two lines and restart.

---

## (b) BYO Minecraft assets (CYRUS_BYO_GAME_ASSETS=1, ON in production today)

**What it does end to end (code: lib/cyrus/gameassets/*, components/cyrus/studios/GameAssetsPanel.tsx, routes /api/cyrus/assets/v1/game-assets/**):**
1. The Texture and Sound studios each have a **Minecraft** tab, which also shows on an empty mod.
2. The user picks their game jar (`versions/<v>/<v>.jar`) or the `.minecraft/assets` folder. The **browser** unpacks and hashes the files; no bytes are sent.
3. `POST /game-assets/verify` checks each sha256 against the PRIVATE vanilla reference (`CYRUS_VANILLA_REFERENCE_DIR`). Only unchanged vanilla files pass.
4. Textures: **"Retexture this"**.
   - `POST /game-assets/import` sends that one PNG (at most 512 KB).
   - The server re-hashes it. The server hash decides; the browser's claim is never trusted.
   - The server decodes it, normalises it (first animation frame, binary alpha, 128 px icons halved to 64, 16/32/64 squares only) and saves it as an editable Texture Studio doc.
   - The doc carries `gameBase`: legal class game-derived, source byo, original sha, pixel sha, and `expiresAt` = +7 days (retention "job").
5. Export and pack are **delta-only**. Pixels unchanged from the base are left out. After 7 days the derived texture is refused at pack time ("import it again"). It is never library-eligible, contributed or shared.
6. Sounds: verify, local audition, and "Plays as minecraft:entity.zombie.hurt (one of N variants: extend or replace)". The user then makes their OWN sound in a sound set and points it at that event. The vanilla file never ships.

**State in production today: it fails closed.**
- `CYRUS_VANILLA_REFERENCE_DIR` is not set, so caps answer "verification is not available on this server yet" and verify/import return 503 `no_reference`.
- Turning it on is wave 2.2, with its look-alike side effect.

**"Start from a vanilla texture/sound and edit it" with the user's own files:**
- **Textures: yes, it exists** (step 4). It needs only the reference dir.
- **Sounds: no.** There is no import or edit of a vanilla sample. The user can only listen and target the event with a synth or library sound.

**What is missing to make it easy (not built):**
1. **Reference versions.** The private reference holds only `26.1.2` (+ an unknown set). Cyrus builds 1.21.1 / 1.21.4 / 1.21.8 / 1.21.11. A 1.21.x file that changed since then fails "unchanged vanilla" (as a mod or edited file). Run `_reference/tools/mc_index.py` for the four 1.21.x jars and asset indexes.
2. **Sound import + edit.** Add a `POST /game-assets/import` for `.ogg` that creates a sound-set variant layer from the user's file (trim, pitch, gain, layer with synth) with the same gameBase/expiry. `deltaFile()` already exists for the never-ship-unchanged rule but nothing uses it for sounds yet.
3. **A retention sweep.** The "7 days" is enforced only at pack time. Nothing deletes or marks BYO-derived project assets after expiry (the policy comment says "and swept"; no sweep exists).
4. **One-click path.** The browser has to read a ~30 MB jar each session. Remembering the verified file list per project (hashes only) or a "pick from the last jar" list would make it quick. A search-by-item picker ("diamond_sword") in place of path filtering would help too.
5. **Model files.** They are verified, but "Models are reference only for now" (no import into the Model Studio).
6. **Builds.** A BYO-derived texture reaches a build only after a later change build wires it ("A build wires it to an item"). There is no "use this retexture on item X" button that does it without a model call.
7. **Look-alike interplay.** With the reference on, an AI-made texture that copies vanilla is dropped. BYO retextures are exempt (`derivedFromVanilla` gives `not_run`), but the customer is not told why an AI texture vanished beyond the generic notice.

---

## VERIFY RESULTS

(filled in by the assembling agent at the end of the run; see below)

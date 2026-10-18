# EC: Cyrus deep status audit (2026-10-18 ~09:40 UTC)

Author: bundle E (Sonnet). Read-only on production (SELECTs, GET health, docker ps/images on the build VM, `smoke-readonly.sh flags service launch`). No flag, setting, image, migration or deploy was touched. Docs only.

Evidence base (all re-checked today, not copied from older notes):
- `git log main`: head `af5a1d55` ("simple-icons bundle fix"), which is rc21 + translate guard + funnel coupon fields.
- `readlink /opt/nxeon/.next` -> `/tank/nxeon-deploy/production/releases/20261018T082948Z-af5a1d55-...`; `nxeon-web` and `nxeon-worker` active.
- Build service (VM 88001 via node-2): `docker ps` = `modbuilder:0.26` (built 2026-10-18 08:15), rollbacks 0.25/0.24/0.23 present. `/health` says `image:"0.5"`; that is a constant in server.js, not the Docker tag. Live `promptVersion mb-2026-10-17.1` = repo, `preserve pv-2026-10-17.1`, `guard imageguard-2026-10-17.1`, `auth: subscription`, concurrency 2, queue empty, breaker closed. Env on the container: `MB_BUILD_BUDGET_USD=4`, `MB_CALL_BUDGET_USD=2.5`, `MB_EFFORT_MAP=design=medium,default=medium`, `MB_MC_TECHNIQUES=1`, `CYRUS_LIVE_ASSETS=1`. Health features OFF: `starterBank`, `recipes`, `bossModel`, `spyglass`, `dedupe`; `preflight` advise (MockBukkit, 1.21.11 only).
- Live DB (SELECT only): 23 CyrusProject, 62 CyrusRevision, 115 ModBuild (84 succeeded, 31 failed, ONE distinct user, 2026-10-06..18, 46 of them on 10-15), 1 CyrusCreator, 1 CyrusTokenAccount, 223 CyrusTokenLedger rows, 0 CyrusPlan rows (no plan prices created), 0 CyrusPersonalApiKey, 0 CyrusModListing, 0 CyrusLibraryItem (library not seeded in prod), 26 CyrusModPage, 6 CyrusGuardRefusal, 8 CyrusCoachEvent, 0 CyrusConversion / CyrusWebEvent (analytics flag off), 1 CyrusStorageAccount, 1 CyrusDataRequest. Nxeon `User` rows 1,092.
- Settings: only `cyrus_tok_charge_refused=false`, `cyrus_tok_daily_spend_cap=1000000`, `cyrus_tok_free_failures=10` are stored; everything else runs on code defaults (launch check: 43 settings still PLACEHOLDER). Launch pair `cyrus_studio_public_enabled=false`, `cyrus_tok_live=false`; private beta allow-list = 2 emails.
- Flags ON in `/opt/nxeon/.env` (names): CYRUS_DESIGNER, ITEM_STATES, TESTFLIGHT_GATE, TESTFLIGHT_BLOCK_ON_FAIL, MANAGED_PLUGINS_REAL, DELIVERY, PERF_WATCH_ACTION=notify, DOMAIN_MODE, SOUND_LIBRARY_CLEARED, STORAGE, STORAGE_ADDONS, WALLET_PAY, API_V1, MODPACK_INSTALL_REAL, DATAPACK_DELIVERY_REAL, HANDGUN_GRIP_FIX, LIBRARY_CONTRIBUTE, BYO_GAME_ASSETS, GDPR_ERASE, TESTFLIGHT_WORLDGEN, WORLDGEN, ARMOR_LANE, NOTEBLOCK_LANE, DATAPACK_STUDIO, CUSTOMER_APP, LEARNING, PROMPT_COACH, LIVE_ASSETS, MC_TECHNIQUES, DESIGNER_BUILDS, CONFIG_STUDIO, CREATURES, LIBRARY_BACKEND, LIBRARY_BROWSE, GOOGLE_LOGIN, ROOM_STUDIO. NOT in the env (so OFF): CYRUS_ANALYTICS, CYRUS_MC_SEO, CYRUS_PUBLIC_BUILDER, CYRUS_MEGA_STAGING, CYRUS_HONEST_ESTIMATE, CYRUS_CODE_CORE, CYRUS_STATUS_PAGE, MB_BOSS_MODEL, MB_STARTER_BANK, MB_RECIPES, CYRUS_TESTFLIGHT_ORACLE.
- Launch check today (`launch-check.sh`): private beta NO-GO (blockers `guard-smoke`, `backup-fresh`), public NO-GO (adds `svc-auth`). 30 PASS / 6 WARN / 2 FAIL (public: 3 FAIL).

Status words: LIVE / MERGED-NOT-LIVE / ON-A-BRANCH / NOT STARTED / BLOCKED-ON-OWNER. "LIVE" means in production code today; if it also needs a switch the row says whether the switch is on.

---

## 0. The 12 facts that matter most
1. Production = rc21 (`af5a1d55`, release `20261018T082948Z`), build image `modbuilder:0.26`. Every r0..r51 branch, rc3..rc21 and every named bundle branch up to 10-17 is merged into main (`git rev-list --count main..<b>` = 0). Only unmerged Cyrus-relevant branches: `feature/cyrus-minecraft-seo` (+3), `feature/fast-deploy` (+1), parked `feature/cyrus-v6-game-palworld`/`-rust`/`-library`, and uncommitted work in `cyrus-outage` (8 files) and `cyrus-dungeon` (1 file).
2. Cyrus is a private beta of ONE real user: 115 builds, one distinct user (the owner); the "50 signups, no payments" problem is on the Nxeon side (funnel, see tracker 119) and is not a Cyrus payment bug.
3. Today's launch check is NO-GO even for the private beta: **the guard smoke test FAILS** (the intake guard did not refuse the injection prompt, 0.1 d old, right after the build account swap and image 0.26) and **the nightly backup is 98 h old** (last success 2026-10-14; `backup-stale` alert firing). Neither is investigated yet.
4. The build service runs on the owner's Claude subscription login. The token set 2026-10-13 hit its WEEKLY limit; on 2026-10-18 09:28 the earlier token (fp 8463c98ab1) was restored, the limited one is saved as `/root/claudebox.env.weeklylimit-20261018-092840` (limit resets 2026-10-19 02:00 UTC). An API key is a public-launch blocker (D-02, D-17).
5. Money rails exist and are mostly dark: Stripe key is LIVE-mode, `CYRUS_WALLET_PAY=1` (allow-listed accounts can pay tokens from the Nxeon wallet with real money), but `cyrus_tok_live=false` and 0 `CyrusPlan` rows, so no plan can be bought. A real live payment test has never been done (`LIVE-PAYMENT-TEST.md`).
6. The Nxeon/Cyrus split (DA, milestones M0-M10) is design plus prototypes only: no OIDC provider in the code, no separate DB, repo, VM or Stripe, secret admin host NOT applied (`admin-host-apply.sh` exists, no nginx site). cyrus.my itself IS live (landing, app via nginx proxy, Google login ON).
7. Cyrus as a product is Minecraft Paper 1.21.1/1.21.4/1.21.8/1.21.11 only; 26.x cannot be built (build image has no JDK 25); other games are on hold (D-15).
8. Measured quality (evals, not forecasts): fifth1 (2026-10-14) 24 builds REAL pass 79.2%, plugin enabled 100%, $7.59; smoke2 eval currently running (6/24, $3.4 so far). No gate baseline is accepted (`baseline.json` missing).
9. Dungeon QA (owner's long-running real test): last good build `mbf8812bb2484d3eb42902` v1.40.0 (11 floors, merged config, custom bosses). Round 7 was BLOCKED by the weekly limit; resumed after the account swap.
10. Deploys take ~1 h (promote alone 1,187 s; ship script adds staging build + dumps + image build). `feature/fast-deploy` b69f76d9 (build once, slim fetch) is on a branch, off by default, not merged.
11. Not built at all: per-game Minecraft SEO pages (branch has them, flag off), public prompt/picture -> schematic page (branch, flag off), starter bank / recipe memory ON (code in main, OFF), `The Gloam` massive test never run, real-client test day never run, creature end-to-end on a real client never proven.
12. Bundles A (Minecraft readiness), B (platform/launch/separation), C (efficiency), D (new features), plus dungeon QA, AI-outage fix, fast deploy and Minecraft SEO/schematic are all in flight at audit time; A/B/C worktrees have no commits yet, so nothing from them is claimable.

---

## 1. CYRUS-FULL-PLAN.md phases P0-P8

| Phase | Status | Evidence / what remains |
|---|---|---|
| P0 Decisions | PARTLY DECIDED, rest BLOCKED-ON-OWNER | Section-1 defaults adopted as working defaults D-31 (monorepo, Nxeon wallet only, Nxeon IdP). Overridden by owner: D-65 (keep Nxeon Stripe, not a Cyrus merchant), D-66 (JIT accounts, Sign in with Nxeon + Google). Still open: lawyer review of ToS/privacy/library licence, region choice, Cyrus-own Postgres hosting. |
| P1 Front door | LIVE | cyrus.my landing + /help + /plans (static, `apps/cyrus-site`, `/var/www/cyrus.my`) returns 200; app proxied by nginx `cyrus-my` with `CYRUS_DOMAIN_MODE=1`; cert 82 days; Cloudflare edge answers; real client IP restored; Google login ON. Dual-host shell + SSO + purchase->credit built (r36). |
| P2 Cloudflare for Nxeon | BLOCKED-ON-OWNER (parked) | nxeon.cloud deliberately unproxied (memory nxeon-cloudflare-proxy-parked). cyrus.my zone IS behind Cloudflare, but the saved API token cannot edit SSL (Full strict) and `CLOUDFLARE_DNS_API_TOKEN` cannot see cyrus.my. |
| P3 Extract the app (monorepo) | NOT STARTED (by decision D-32: later, alone) | No `apps/cyrus` or `packages/*`; only `apps/cyrus-site`. Seam prerequisite DONE and LIVE as code: host seam (97 -> 0 Nxeon-table call sites, baseline 40 -> 5 imports). Reverse-import ratchet prototype merged (baseline 35 files / 65 pairs) and was RED on main in DA findings (`lib/cyrus/seo.ts` -> `lib/seo-robots-policy`); not re-verified today. |
| P4 Bridge hardening | PARTLY LIVE | `lib/nxeon-platform` Platform API, `lib/cyrus-bridge`, Cyrus API v1 (`CYRUS_API_V1=1`), delivery orchestrator with journal+rollback (`CYRUS_DELIVERY=1`), notifications and ticket context all merged. NOT done: scoped per-server consent grants with revocation UI, entitlement webhooks live in the product, install manifests executed by Nxeon (DA D-series), OAuth for Cyrus. |
| P5 Data split | ON-A-BRANCH -> prototype MERGED, NOT APPLIED | `scripts/cyrus/data-split/{split.sh,tables.mjs,selftest.sh}` on main (28 tables, no FKs); nothing run against prod. Needs owner go (own Postgres, freeze window). |
| P6 Portals | PARTLY LIVE | Customer app (`CYRUS_CUSTOMER_APP=1`): dashboard, studios, library browse, servers, wallet, mods pages (26 pages), welcome step, Report a problem. Cyrus admin lives INSIDE Nxeon admin (Live, Economy, Assets, Analytics tabs, perms, beta/invites); the separate secret admin host is MERGED-NOT-LIVE (not applied). Teams/shared projects, personal API-key UI use (0 keys), docs.cyrus.my: NOT STARTED. |
| P7 Infra move | NOT STARTED | No Cyrus VM, no R2/CDN (`CYRUS_PACK_STORE=local`, `CYRUS_LIBRARY_STORE=local`), no staging env for Cyrus, no `promote-cyrus.sh`, no status page (`CYRUS_STATUS_PAGE` off). Off-box encrypted copy exists but stale (see launch check). |
| P8 Launch gate | BLOCKED-ON-OWNER + 2 technical FAILs | Open: API key for build service; real-client test day; paid eval baseline accepted; legal sign-off; token prices (`cyrus_tok_tokens_per_usd` etc.); Stripe live Prices (0 `CyrusPlan` rows); guard smoke FAIL; backup stale; alert webhook; sound ledger 185/611 undecided. Flag order with launch-pair guard is built and tested. |

Plan section 3 (bridge detail): identity lifecycle partial (Google + Nxeon SSO live; verified-email rule, back-channel logout, suspend propagation, merge: NOT STARTED); money (idempotent ledger, refunds reverse credits: LIVE in code, 223 ledger rows, never exercised by a real third-party payment); connecting servers (servers.read, files.write.mods via delivery orchestrator: LIVE; scoped consent screen, `logs.read.tail`, `pack.set` grants: partly; webhooks `server.version_changed` etc.: NOT STARTED).
Plan sections 4-6: customer app and admin as above; Cloudflare WAF/Turnstile on cyrus.my sign-up and "Create Mod": NOT VERIFIED.
Plan section 7 (one session updates everything / `scripts/ship`): NOT STARTED; closest is `feature/fast-deploy` (ON-A-BRANCH).

---

## 2. MASTER-PLAN R0-R5 (memory nxeon-cyrus-master-plan-2026-10-10)

| Round | Status | Notes |
|---|---|---|
| R0 foundation (typed project + revisions, registries, host seam, GameAdapter core) | LIVE | `CyrusProject` 23 / `CyrusRevision` 62 in prod; adapters exist for Minecraft only. |
| R1 assets (texture, sound studios, library) | LIVE, library EMPTY in prod | Sound Studio, Texture Studio, live assets (`CYRUS_LIVE_ASSETS=1`), 74-game private reference. `CyrusLibraryItem` = 0 rows in prod even though `CYRUS_LIBRARY_BACKEND=1` and `CYRUS_LIBRARY_BROWSE=1`: the "automatic community library" (D-21) has nothing in it. Library prod import (CC) is "DONE on branch, NOT applied" in tracker; the main code is merged, the import never ran. 185 of 611 sound ledger rows undecided while `CYRUS_SOUND_LIBRARY_CLEARED=1`. |
| R2 composition / datapacks / import | LIVE | Mod Packs (`CYRUS_MODPACK_INSTALL_REAL=1`), data pack studio + delivery ON, import-your-own-mod in the build service (source+jar, scan profiles). |
| R3 creatures, full studios, designers | LIVE (Minecraft 1.21.x), with caveats | Designers (item/menu/quest/boss/HUD), creatures (BetterModel 2.2.0, `CYRUS_CREATURES=1`), config studio (+ Send to server, merged rc3), motion. Creature end-to-end on a real client: NEVER PROVEN. Boss-model rigs: MERGED-NOT-LIVE (`MB_BOSS_MODEL` off, `bossModel:false`). |
| R4 world / reach | LIVE (new chunks only) | Worldgen ON (`CYRUS_WORLDGEN=1`), structures stage 1 + Room Studio (`CYRUS_ROOM_STUDIO=1`, incl. image input, rc21). Worldgen probes ON. |
| R5 beyond (other games, 26.x, client mods, marketplace) | NOT STARTED / BLOCKED-ON-OWNER | Other games ON HOLD (D-15); Palworld/Rust/library branches parked; 26.x blocked on a Java 25 build image; Mojang EULA/marketplace parked by owner. |
| Tier gating (D-05: Saka sound, all = everything) | MERGED-NOT-LIVE in effect | Enforced in code, but with `cyrus_tok_live=false` and 0 `CyrusPlan` rows only allow-listed beta accounts can build. |

---

## 3. MASSIVE-MOD-TEST.md ("The Gloam")
Status: **NOT STARTED as a test** (never run; only referenced in tracker 243/430). The flags it listed (`CYRUS_DATAPACK_STUDIO`, `CYRUS_WORLDGEN`, `CYRUS_CONFIG_STUDIO`, `CYRUS_LIVE_ASSETS`, `CYRUS_MOD_SUITES`) are now ON except `CYRUS_MOD_SUITES`/`CYRUS_CATALOG_TOOLS`/`CYRUS_CATALOG_INDEX` (not in the env, so OFF). Two things changed under it: the mega-mod staging round (`CYRUS_MEGA_STAGING`, MERGED-NOT-LIVE, off) is the new way a Gloam-size request should be staged, and the Infinite Dungeon (v1.40.0) has become the practical massive-mod test. Acceptance items 3-6 (real client, edit-one-module, honest failure record) are BLOCKED-ON-OWNER (needs the real-client test day).

## 4. DA split architecture (D1-D18, milestones M0-M10)
| Item | Status |
|---|---|
| Design doc DA, decision list D1-D18 | LIVE as docs; owner answered D-65 (keeps Nxeon Stripe) and D-66 (JIT identity, Nxeon + Google). Rest of D1-D18 (D8 subsidiary/legal, D9 hosting VM, D10 DB, D11 new GitHub org, D12 admin auth, D13 support, D14 min age, D16-D18) BLOCKED-ON-OWNER. |
| Prototypes `feature/cyrus-split-design` 536f2711 (identity link rules, reverse-import ratchet, admin-host-apply dry run, extract-repo plan) | MERGED-NOT-LIVE (merged to main via rc18; nothing applied) |
| M1+ Nxeon OIDC provider (`id.nxeon.cloud`), Cyrus identities table, Connect Nxeon flow | NOT STARTED (no `openid-configuration` in the code) |
| D3 "Google on cyrus.my must not create a Nxeon account" | OPEN BUG-LIKE: Google login is LIVE (`CYRUS_GOOGLE_LOGIN=1`) and still provisions Nxeon accounts; DA wanted the flag off until M2. Owner turned it on (D-67). |
| Secret admin host (`*.cyrus.my` + Cloudflare Access) | MERGED-NOT-LIVE (`deploy/cyrus/admin-host-apply.sh`, `nginx-cyrus-admin.conf`; no site enabled) |
| Own Postgres in a Cyrus VM, new GitHub org repo (`extract-repo.sh`: 2,796 files / 654 commits) | NOT STARTED |
| Separate Anthropic org/key (D17) | BLOCKED-ON-OWNER (same item as the API key) |

## 5. DF launch readiness 2 (D-65..D-71)
| Item | Status |
|---|---|
| Welcome-to-Cyrus step (username + Terms), `onboarding_required` | LIVE (columns + `CyrusUsernameHold` present, launch check PASS) |
| Beta ops pack (invites tab/CLI/email, Report a problem, daily report, guard refusal log + review queue) | LIVE (6 refusal rows); invite email sender not set (`cyrus_mail_from` empty) so invites go by hand |
| Stripe `product=cyrus` tags, storage-subscription-as-plan fix | LIVE |
| Backup fresh, alert webhook, disk `/` | OPEN: backup 98 h old, no `CYRUS_ALERT_DISCORD_WEBHOOK`, `/` 89% (5 GB free), 2 alert rules firing |
| Sound ledger, eval baseline acceptance | OPEN (owner/legal; baseline needs `eval-gate.ts --journal /root/cyrus-eval/fifth1` from a non-/opt checkout) |
| Live payment test (`LIVE-PAYMENT-TEST.md`) | NOT STARTED (owner) |
| 25-person private beta | BLOCKED-ON-OWNER (only 2 allow-listed accounts; wave W0 plan) |

## 6. BL token-savings plan (recommendations)
| Item | Status |
|---|---|
| Reliability bundle (repair share of spend 76% -> 23%, pass@1 48% -> 86%) | LIVE (image 0.13+, rc5/rc6) |
| Cheaper-model repair first / effort routing | LIVE (`repairCheapFirst`, `MB_EFFORT_MAP design=medium,default=medium`; all tiers route to `claude-sonnet-5-5` via classifier haiku) |
| Build/call budgets | LIVE (`MB_BUILD_BUDGET_USD=4`, `MB_CALL_BUDGET_USD=2.5`; BL suggested 1.5/1.0, the raised caps came from the dungeon `budget` failures) |
| Change-build hygiene (version bump, no new lanes on changes, regression guard vs base) | LIVE (fix/cyrus-version-bump, preserve.js `pv-2026-10-17.1`, wiring recovery, config-defaults keep) |
| Calibrated, honest estimates | MERGED-NOT-LIVE (`CYRUS_HONEST_ESTIMATE` off) |
| Starter bank (16 mods) and recipe memory | MERGED-NOT-LIVE (`starterBank:false`, `recipes:false`) |
| Mega-mod staging, code-core | MERGED-NOT-LIVE (`CYRUS_MEGA_STAGING`, `CYRUS_CODE_CORE` off) |
| MB_DEDUPE | stays OFF forever (cross-user leak) |
| NxKit scaffold | NOT STARTED |
| Build speed knobs (CA) | MERGED-NOT-LIVE (all new knobs OFF) |
| Bundle C (efficiency) | ON-A-BRANCH: `feature/cyrus-efficiency` has no commits yet |

## 7. Minecraft coverage matrix (`docs/cyrus/minecraft-coverage.md`, generated)
Versions 1.21.1 / 1.21.4 / 1.21.8 / 1.21.11 LIVE; 26.x NOT STARTED (blocked on JDK 25 image) for every lane.
- LIVE and switched ON: plugin, texture, itemStates, sound, library (sound), designItem/Menu/Quest/Boss/Hud (HUD limited), motion (limited, 1.21.4+), config, datapack, worldgen (limited), creature (limited: BetterModel 2.2.0 on a vanilla mob; never proven on a real client), armor lane, note-block lane, MC techniques (vein miner, capture mob), structures + Room Studio.
- MERGED-NOT-LIVE: boss with creature rig (`MB_BOSS_MODEL`), behaviour oracle (`CYRUS_TESTFLIGHT_ORACLE`), MockBukkit preflight is advise-only, spyglass off.
- NOT STARTED: client-mod lane (Fabric/NeoForge), glyph-background menus, core shaders, custom bosses on 26.x, Bedrock.
- Unverified (never in a real client): packs, textures, sounds, models, HUD, menus, armor look, custom block look, creature models, boss bars. Real-client test day has not been run.

## 8. Newer work not in a written plan (verify before assuming)
| Item | Status |
|---|---|
| Room Studio (spec, generator, build lane, image input) | LIVE (rc20/rc21, `CYRUS_ROOM_STUDIO=1`, image guard live) |
| Refine regression guard, creature wiring recovery, config-defaults keep | LIVE (image 0.26 confirms prompt/preserve versions) |
| Intake guard false-positive fix (`guard-2026-10-15.1`) | LIVE, but today's guard smoke FAILS: OPEN |
| Delivery ownership fix (chown on every guest write), BetterModel pack hand-off | LIVE (rc18/rc19); real-server confirmation still "inferred from code" |
| Behaviour oracle, preflight ledger, planner recall, boss model, mega staging, speed, recipe memory, learning loop | MERGED-NOT-LIVE unless the flag row above says ON (learning ON, prompt coach ON) |
| Analytics (`CYRUS_ANALYTICS`), status page | MERGED-NOT-LIVE |
| Minecraft SEO cluster (`CYRUS_MC_SEO`) + public builder (`CYRUS_PUBLIC_BUILDER`) + schematic export | ON-A-BRANCH `feature/cyrus-minecraft-seo` bf6451d3 (+3), dirty worktree `/tank/dev-worktrees/cyrus-mc-seo` |
| AI outage handling (R7-1..4: misleading "busy" for weekly limit, queue during open breaker, guard fails open, keyword room lane) | ON-A-BRANCH, uncommitted (8 files in `/tank/dev-worktrees/cyrus-outage`, branch `fix/cyrus-ai-outage-handling` still = main) |
| Fast deploy | ON-A-BRANCH `feature/fast-deploy` b69f76d9 (+1), 3 dirty files |
| Wizard conversion fixes (coupon code recorded, dashboard bundle 6.4 MB -> 1.4 MB, translate crash guard) | LIVE (rc21) |
| Dungeon QA runner | MERGED (`feature/cyrus-dungeon-run`); 1 uncommitted file in its worktree |
| Dropbox off-site backups (Cyrus + platform) | LIVE per tracker 107, but launch check says Cyrus nightly backup 98 h stale: reconcile |

## 9. Owner decisions pending (one screen, recommended default in bold)
1. **Build service credential for any public use**: buy/attach an Anthropic API key for Cyrus (separate org, D17). Default: **do it before inviting beta wave W0 beyond 2-3 testers; until then keep the subscription and swap tokens when the weekly limit hits** (document in 07).
2. **Restore beta readiness today**: have someone fix the stale backup (`systemctl start cyrus-backup.service`, confirm LAST_SUCCESS) and decide on the guard smoke failure (re-run guard smoke on image 0.26; roll back to 0.25 if the guard really lets injection through). Default: **investigate guard first; do not widen the allow-list until it passes.**
3. **Token prices and plans** (Stripe live Prices for Katara/Saka/Yakko, `cyrus_tok_tokens_per_usd` 500 vs 300, free grant). Default: **keep `cyrus_tok_live=false`; create the CyrusPlan rows only after the live payment test with a tiny paid price.**
4. **Live payment test** (LIVE-PAYMENT-TEST.md, one real card, refund after). Default: **yes, this week, owner card.**
5. **Sound library**: 185 of 611 rows undecided while the cleared flag is ON. Default: **turn `CYRUS_SOUND_LIBRARY_CLEARED` off until rows are decided (testers get synth sounds)**; or decide the rows.
6. **Eval baseline**: accept `fifth1` (79.2% real pass, $7.59, free to re-score) as baseline. Default: **accept, then run one paid weekly gate at <= $8.**
7. **Split-architecture sign-off** (D1-D18 beyond D-65/D-66): Cyrus subsidiary and merchant of record, hosting VM, own DB timing, new GitHub org, separate admin auth. Default: **defer all of it until after the beta; ship the secret admin host first (smallest, reversible).**
8. **Google login creates Nxeon accounts** (DA D3). Default: **leave ON for the beta (it works), schedule the identity change with M1-M3.**
9. **Real-client test day** (creatures, packs, sounds, boss bars, armor/block looks, The Gloam). Default: **one scheduled 2-hour session before beta wave W0; I prepare `scripts/cyrus/testday.sh`.**
10. **Public Minecraft SEO + free schematic builder** (`CYRUS_MC_SEO`, `CYRUS_PUBLIC_BUILDER`): free allowance, caps, price, which export formats (.schem, .nbt, .litematic). Default: **ship `.schem`/`.nbt` (already built), anonymous allowance small (1/day/IP), first signed-in build free; flags on only after the bundle D review.**
11. **Per-build cap** (`MB_BUILD_BUDGET_USD` 4, `MB_CALL_BUDGET_USD` 2.5): keep, or split big refines. Default: **keep 4/2.5 and let staged mega builds (`CYRUS_MEGA_STAGING`) handle big requests.**
12. **Dungeon target**: accept v1.40.0 as the showcase, or run round 7 (9-step plan) after 2026-10-19 02:00 UTC. Default: **run round 7 only after the AI-outage branch is merged.**
13. **Fast deploy**: enable `FAST_DEPLOY=1` after one supervised run. Default: **yes.**
14. Alert webhook + invite sender address (`CYRUS_ALERT_DISCORD_WEBHOOK`, `cyrus_mail_from`). Default: **create both; they cost nothing.**
15. Old parked items stay parked (Mojang EULA, Modrinth policy, dependency licence review, Palworld/Rust/library branches, Hytale).

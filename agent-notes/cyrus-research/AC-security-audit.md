# AC - Cyrus launch-hardening security audit (r32, 2026-10-11)
Branch `feature/cyrus-r32-security` (worktree `/tank/dev-worktrees/cyrus-r32`, from `feature/cyrus-r2` @ 92d7fa4a69). Nothing deployed, migrated or switched on.
Method: read-only adversarial pass over everything Cyrus exposes (4 parallel readers + one real Blender probe on node-2), then fixes with tests.
Labels: **VERIFIED-TEST** = a test fails on the old code / passes on the fix; **VERIFIED-RUN** = reproduced on real software; **VERIFIED-READ** = concrete trace by reading; **UNVERIFIED** = plausible, not reproduced.

No HIGH finding: no cross-tenant read/write, no unauthenticated route, no raw proprietary sound served, no SSRF, no secrets in logs.

## Fixed (ranked)
| # | Sev | Area | Finding | Evidence | Fix |
|---|---|---|---|---|---|
| AC-1 | MED | API v1 | Any client with its own subject key (e.g. `kodely`) could sign `sub=<any Nxeon user id>` and read that user's projects/builds/catalog plan. The subject id was never namespaced by client. | VERIFIED-TEST (the existing test had kodely asserting `user_a` -> 200) | `CYRUS_API_V1_IDENTITY_CLIENTS` (default `nxeon`): other clients get 403 `subject_not_allowed` on per-user operations; malformed list = 503. |
| AC-2 | MED | meshgen scratch | Driver expressions bypass the static scan: `o.driver_add(...).driver.expression = "_"+"_import_"+"_(...)"` passes both scans (no dunder literal, no denied attr) and reaches Blender's Python eval, where no AST rule applies (`().__class__...` walks are possible). | VERIFIED-RUN on node-2 Blender 5.2.2: scan passed, eval reached; only Blender's factory autoexec-off default stopped it; with autoexec on the expression ran (the guarded `__import__` caught `os`; a subclass walk is UNVERIFIED). | Deny `driver_add/driver_remove/drivers/driver/expression/movieclips/cache_files` (TS + in-sandbox lists, kept equal), harness pins `use_scripts_auto_execute = False`, launcher adds `--disable-autoexec`. The sandbox stays the boundary. |
| AC-3 | MED | designer Java | Javadoc injection: names are put in `/** ... */` with only `*/` stripped. `**//` re-forms `*/`; `*/` is decoded by javac before lexing. Text after it is top-level Java (bytecode/source scans still run). Item ability, menu, quest, boss, encounter; also the config exporter (dead in prod). | VERIFIED-TEST (javac-view lexer test fails on old code) | `javadocText()` drops `\ * /` in comment text; bundles regenerated. |
| AC-4 | MED | Mod Packs | Pack create/install skipped the single-install gates: network-capability consent + `cyrus_mod_networking_enabled`, and the Test Flight block (`CYRUS_TESTFLIGHT_BLOCK_ON_FAIL`). | VERIFIED-READ (members() vs delivery checkInstall/installEligibility); gate VERIFIED-TEST | `memberInstallGate()` in `members()` (runs on create, conflicts and every install): networking mods refused in packs (install alone), failed-flight versions refused. |
| AC-5 | MED | library reports | One signed-in account could hold ~20 published assets/min with `reason: copyright` (a single legal report holds at once). | VERIFIED-READ; fix VERIFIED-TEST | Legal auto-hold budget 5 per reporter per 24 h; past it the report is recorded and 3 distinct reporters are needed. |
| AC-6 | LOW-MED | library takedown | A taken-down asset's stored near-copies (`duplicateOf`) stayed published and servable by id (not in search). | VERIFIED-TEST | Takedown holds every published `duplicateOf` copy (`hold:upstream-removed`, logged). |
| AC-7 | MED (latent, not mounted) | host HTTP server | A leaked Cyrus host key could write ANY platform setting (`settings.set/writeStored/clearStored`); bodies were buffered before the size check. | VERIFIED-TEST | Writes limited to `cyrus_` keys (403 `setting_not_writable`); declared oversize refused before reading. |
| AC-8 | LOW | Test Flight | `server.properties` escaping stripped `\n` but not `\r` (a Properties line break): a resource-pack value could add keys. Throwaway loopback server only. | VERIFIED-TEST | Strip `\r \n NUL U+2028/2029/0085`. |
| AC-9 | LOW | data packs | A command ending in `\` joins the next entry in 1.20.2+, so two separately checked entries run as one. | UNVERIFIED exploit (root stays allowlisted) | Refused (`line_continuation`). |

## Open (not fixed here)
| # | Sev | Finding | Why open / what it needs |
|---|---|---|---|
| O-1 | LOW | Telemetry ingest: HMAC over body only (no timestamp/nonce, shared secret), whole body buffered before the cap, no IP limit; replays inflate counts up to 10k/key. | Protocol change (collector must sign a timestamp + batch id). Do before `CYRUS_HEALTH_TELEMETRY`. |
| O-2 | LOW | AI gateway tokens never expire. | Route is a 501 stub; add max age before it goes live. |
| O-3 | LOW | Server Doctor audit-row failures are swallowed. | Owner: fail closed or alert. |
| O-4 | LOW | Test Flight log-matcher regexes can backtrack (bounded by the runner's kill timeout). | RE2 or step limit later. |
| O-5 | LOW | Pack install/uninstall loop restarts the user's own server ~1/min; pack routes use pack limits, not delivery limits; in-memory limiter. | Owner: per-server restart budget (N/hour). |
| O-6 | LOW | No per-user Mod Pack count/byte quota; no create idempotency. | Owner: quota numbers. |
| O-7 | INFO | Delivery Idempotency-Key not bound to the body (reused key returns the old job). | Hash body into key in API phase 2. |
| O-8 | LOW | Library filters are text-only (no NFKC/confusables, no pixel/audio classifier). Unicode bypass unreachable today (key regex). | Owner: hold first-time contributors for review, or a classifier. |
| O-9 | LOW | Import licence claim accepted as typed (public sharing is hard-off). | Manual review before any public share. |
| O-10 | INFO | Hosted packs are public by sha1 (capability URL, no expiry). | Owner: OK as public, or signed URLs. |
| O-11 | LOW | API v1 replay caches are in-process (50k cap); multi-instance needs a shared store. | Before running more than one instance. |
| O-12 | INFO | The host key is full trust for reads (`settings.getAll`, `users.find/emails`). | By design; keep the secret on Nxeon only, rotate on move day. |
| O-13 | - | meshgen kernel-escape untested; microVM/gVisor before `CYRUS_MESHGEN_SCRATCH` (already tracked). | |

## Checked and safe (summary)
API v1: flag off = 404, bad config = 503, sha256 secret + constant-time compare, scopes never widen, per-key rpm, Ed25519 assertions (iss = client, aud, 120 s, single-use jti, email refused), owner checks answer 404. Delivery/Mod Packs/designer/datapack/config: every route session + fail-closed flag; ownership re-checked in the worker; remote paths regex-pinned; Java strings (`jstr`), YAML, JSON, mcfunction (allowlist, no breaks, no macros) escaped. Import: zip caps (entries, sizes, ratio, nesting, no zip64), zip-slip/symlink/duplicate names refused on both sides, quarantined bytes never served. Library: signed file tokens (HMAC, expiry, viewer-bound, 900 s), canServe re-checked, sha256 on every read. Sound: every site requires `CYRUS_SOUND_LIBRARY_CLEARED === "1"`; raw library audio never served. Admin: `requireCyrusAdmin` = role area + preview list on the real (not impersonated) user; `modBuilderUser` refuses impersonation. meshgen sandbox: PrivateNetwork, nobody, read-only fs, caps, tmpfs, safe untar. Test Flight: fresh loopback Paper in its own netns, random RCON password, no host parameter, RCON CR/LF refused, `shq` everywhere. No server-side fetch of user URLs; logs carry messages/ids only.

Not read end to end: testflight `runner.js`, playtest `bot.js`, `telemetry/collect.ts`, library `stage-b/c.ts`, admin library routes.

# BQ: Cyrus pre-launch security review, rc3..rc8 surfaces (2026-10-14)

Branch `feature/cyrus-security-review` (worktree /tank/dev-worktrees/cyrus-sec, from release/cyrus-rc8 916eb4fb20). Method: code reading with file:line, tests against fakes on node-2 (devhost). No production action, no real exploit attempt, no flag or setting write. Labels: VERIFIED-CODE (read), VERIFIED-TEST (a test fails on the old code or pins the property), UNVERIFIED.

## Result
| Severity | Found | Fixed in branch | Open |
|---|---|---|---|
| CRITICAL | 0 | 0 | 0 |
| HIGH | 1 | 1 | 0 |
| MEDIUM | 3 | 3 | 0 |
| LOW / INFO | 8 | 0 | 8 (backlog or owner) |

## Findings fixed

### BQ-2 HIGH: planner and coach had no hourly / daily / global spend ceiling (cost abuse)
- Code: `app/api/cyrus/plan/route.ts` (30 per minute per account) and `app/api/cyrus/coach/route.ts` (rewrite 6 per minute). Both call one Haiku turn on the build service that Nxeon pays for (`services/modbuilder/server.js` `planWithHaiku` / `coachWithHaiku`, `--max-budget-usd 0.05`), not metered by the token ledger and not counted in `checkSpendCaps` (cost-caps.ts only sums `ModBuild.costUsd`).
- Exploit: one verified-email account loops `POST /api/cyrus/plan`: 30 calls a minute, 1800 an hour, around $18 per hour at about 1 cent a call, for ever; N accounts multiply it. The coach also ran for a build-suspended account (suspension was only checked in `createModBuild`, create.ts:87).
- Fix: `lib/cyrus/ai-aux-limits.ts` (per account hour + 24 h, one global 24 h ceiling per kind, env tunable `CYRUS_{PLAN,COACH}_MAX_PER_HOUR|_PER_DAY|_GLOBAL_PER_DAY`), called before any model call in both routes; coach refuses a build-suspended account. Test: `test/cyrus-security-review.test.ts` BQ-2 (module did not exist before).
- Note: in-process counters (like `lib/rate-limit.ts`); a restart resets them, and BQ-3 is the second wall.

### BQ-1 MEDIUM: static-extension pass reached application trees on the Cyrus host
- Code: `lib/cyrus/bridge/routing.ts` (old line 15 + 49): `STATIC_RE.test(p)` returned `pass` before every allow-list rule, for any path. `middleware.ts:122-125` then forwards it with the Cyrus marker header, and on the Cyrus host `currentUser()` accepts the `__Host-cyrus_session` cookie (`lib/auth.ts:142-159,231`).
- Exploit: with nginx falling back to the app for non-static paths, `GET https://cyrus.my/api/invoices/<id>.png` or `/api/files/<serverId>.json`, `/api/chat/<id>.txt`, `/api/tickets/attachment/<id>.png`, `/api/mcjars/<anything>.json` reach Nxeon API handlers whose last segment is a dynamic `[id]` or `[...path]` (found with `find app/api -name route.ts`), authenticated by a cookie that was meant to be Cyrus-only. It needs a handler that tolerates the suffix (catch-alls such as `/api/mcjars/[...path]` do), so MEDIUM, but it also defeats "admin/staff paths 404 on the Cyrus host" when `CYRUS_ADMIN_HOST_ONLY` is not yet 1 (`/admin/cyrus/builds/x.json`, `/staff/x.png` passed the middleware; the page auth still held).
- Fix: `isStaticFilePath` (static pass not for `/api /admin /staff /sso /dashboard /internal`); Cyrus API prefixes and `/dashboard/cyrus` still pass through their own rules; same for the secret admin host list. Test: BQ-1 group (admin/staff 404 for GET and POST).
- Which `public/` files are reachable on cyrus.my: any file with one of the STATIC_RE extensions under `public/` (brand, `/cyrus`, `/dl`, `/nxm`, `countries-110m.json`, the `16a2...txt` verification file, etc.). All public already on nxeon.cloud; INFO.

### BQ-3 MEDIUM: build service `/plan` and `/coach` unbounded concurrency and spend
- Code: `services/modbuilder/server.js` (old 1682-1694): each request spawned `claude` with no queue. `/builds` has CONCURRENCY and a queue; these did not.
- Exploit: parallel requests (any number of accounts, or the portal key leaked) = N CLI processes and N x up to $0.05 on the VM, starving real builds.
- Fix: `services/modbuilder/auxgate.js` (`MB_AUX_CONCURRENCY` default 4, `MB_AUX_BUDGET_USD_HOUR` default 5, 0 = off), 429 so the portal falls back to its deterministic planner / draft; Dockerfile COPY line updated (a missing file would crash the image). Tests: BQ-3 group. Needs an image redeploy.

### BQ-4 MEDIUM: remix bypassed the storage quota
- Code: `lib/actions-cyrus-community.ts` `remixCyrusMod` copied `src.jarPath` into the account (`copyFile`) with only `checkGameSlot` (D-63); the other write paths call `checkStorageWrite` (create.ts:92, uploads, modpack.ts:55, deps-real.ts:36, `recordAsset` via hooks.ts).
- Exploit: a full account (storage launch readiness D-64, fail closed) still adds up to 10 remixes an hour of whatever jar size, so the quota is not a bound for remixers.
- Fix: gate after the jar is read and before the copy, `noteStorageWrite` after. Test: source-order test plus a ratchet that every `copyFile(...jarPath)` file contains `checkStorageWrite`.

## Surfaces reviewed (threat model, verified, result)
| Surface | Verified | Result |
|---|---|---|
| Asset catalogue read model + customer routes | `catalogue-http.ts:44-84`: every read/rename/delete goes through `ownRow(viewer.userId, ref)`; ref regex `catalogue-http.ts:11`; owner id and path stripped (`:41`); test `cyrus-assets-catalogue.test.ts` "own assets only" (other account 404, nothing written) | OK |
| Admin assets (view / rename-free / hold) | `app/api/admin/cyrus/assets/route.ts`: `cyrusAdminApiUser("assets.view")` before any read, 404 otherwise, account must own the ref (`accountCatalogue(account)`), preview audited, accounts masked; hold/restore `lib/actions-cyrus-admin-assets.ts:46-79` guard + impersonation + preview list + audit | OK |
| SFX audition + licence gating | `studios/sound-service.ts:192-210`: libraryCleared, then plan gate, then `normalisePreview` (length <= PREVIEW_MAX_SECONDS, id regex, WAV size/magic check); `audition.ts` held/removed never auditioned | OK; LOW-1 below |
| cyrus.my /servers /wallet + host routing | `routing.ts`, `middleware.ts:86-125`: `/cyrus-host` tree 404 off-host; marker header stripped; non-GET to non-API is 404 | BQ-1 |
| Live feed, errors, Economy, Anthropic cost adapter | `live/route.ts` gate first, audited detail, emails masked (`live.ts:47`); `anthropic-cost.ts`: key only in `x-api-key` to api.anthropic.com, error message strips the key, 5 min cache, 8 s timeout; Economy tab billing area + ADMIN platform for writes (`tokens/admin-actions.ts:80-94`) | OK |
| Game slots + storage | `create.ts:92-96` (checked again under `withGameSlot` lock at insert), import `deps-real.ts:36-37`, v1 library `deps-writes.ts:122`, asset saves `store.ts:247` (content-addressed, origins upload/edited/imported/library gated, "generated" is server-origin only: `sync.ts`, `meshgen/ingest.ts`), admin override `adminCyrusGameSlots` (billing area, audited, bounded 0..1000) | BQ-4; LOW-3 |
| Starter bank, recipe memory, path memory | `bank.js`: id must be a folder in the image, params typed + bounded, text without control chars; the request is re-matched in the portal (create.ts) and charged flat; `recipes.js`: static Nxeon-authored files, injected only in the first user turn, selection by regex on the requester's own prompt, nothing stored across users; path memory (`learning/pathmemory.ts`) = anonymised aggregates, n >= 8; `MB_DEDUPE` untouched (still env default off) | OK |
| Config delivery send-to-server | `config-send.ts:34-52` + `job.ts:70-87`: server must be the caller's, project must belong to the server's owner at execution time, worker re-reads values from the owner's saved revision (payload names only the revision), idempotency key, needs-restart ack | OK |
| Valheim installer patchers | `valheim.ts:84-113`, `paths.ts:19-60`, `archive.ts:84-160`: every path through `normalizeRel` + `isSafeSegment` + `joinUnder` (lexical prefix check), `patchers/` only under `<patchers>/<folder>/`, `core`/`monomod` refused, symlinks/links/encrypted/ZIP64 refused, ratio / total / entry caps, CRC, duplicate names; the engine removes a synced copy only inside `syncedRoot` and only when sha matches (`engine.ts:97-105`). A patcher DLL runs in the preloader: same trust as a plugin (Thunderstore download, sha-checked) | OK |
| Version bump, designer edits delivery | read-only sampling; goes through `deliverMod` / `deliverConfig` with the same owner checks (job.ts:80-100: build and project owner must equal server owner) | OK |
| Ticket context, notifications | `support/context.ts:17-19` owner check on the build; notifications POST same-origin check + id regex (`notifications/route.ts:33-37`), SameSite=Lax cookie | OK |
| One-account bridge | `cyrus-host/auth/*`: state cookie constant-time compare and consumed, Ed25519 assertion (iss/aud/typ/nonce/jti single use), stable subject, suspended and unverified refused, `safeCyrusNext` single-slash + allow-list (routing.ts), logout POST same-origin, `__Host-` cookies | OK |
| Landing publish script | `featured.mjs` escapes every value and builds links itself; `publish.sh` check rejects hotlinks, atomic swap + rollback | LOW-5 |
| Wallet top-up / return | `tokens/wallet/route.ts`: session + `tokensActiveFor` + not impersonating + 6 per minute + `Idempotency-Key` (`cwt:<user>:<key>`, ledger unique `idemKey`), charge then deliver, compensating refund, reconcile loop; return routes: id regex, 20 per minute per IP, Stripe session retrieved and `payment_status === "paid"`, tokens capped by what was paid (`billing.ts:156-168`), idempotent `topup:<session>` | OK; LOW-2 |
| Rate limits, token ledger races | `create.ts:98-103`: 3 per minute, 20 per hour, 2 in flight (count-then-create, bounded by the 3 per minute); `ledger.ts:109-160`: per-user row lock inside a transaction, reserve/settle/release idempotent on build id, `settle:<id>` unique, revoke idempotent and never below holds | OK; cost caps default off (owner) |
| Build service API auth + trust boundary | `server.js:1644-1680`: Bearer, length check then `timingSafeEqual`, all routes but `/health`; child env whitelisted (`childEnv`: PATH, HOME, JAVA_HOME + AI credentials only for the CLI; `MODBUILDER_API_KEY` never in a child env); tools Read/Write/Edit only with deny rules for `/proc /etc /home /opt /root /run /data /var /tmp /sys /mnt /srv` and credential globs; `hasSecret` scans live source/asset reads; source route path regex + `..` + lstat; no portal code fetches a user-supplied URL (`fetchArtifact` has no Nxeon implementation, so pack third-party files fail closed) | LOW-4 |

## LOW / INFO (no fix in this branch)
1. LOW: SFX audition at pitch 0 returns an unprocessed excerpt up to 6 s and `trimStart` can step through the file (`sound-service.ts:173-185`); only when `CYRUS_SOUND_LIBRARY_CLEARED=1` and Saka+. Owner decision when clearing the library: cap total seconds per sound per account, or force a processing stage.
2. LOW: wallet top-up lock, rate limits and the aux ceilings are in-process; one web instance assumed (also O-11 earlier).
3. LOW: storage / game-slot / in-flight checks are check-then-write; a parallel burst can overshoot by the route rate limit (3 builds a minute, 90 asset writes).
4. LOW: build service `/health` is unauthenticated and returns model routing, auth mode, queue length; port 7340 listens on 0.0.0.0 (`server.js` listen). Infra: firewall to the tunnel only.
5. LOW: `apps/cyrus-site/publish.sh build` does `cp -a src/.`: symlinks and dotfiles in `src/` would be published (repo-controlled).
6. LOW: `lib/cyrus/tokens/admin-actions.ts` guard does not refuse while impersonating (the actions in `lib/actions-cyrus-admin.ts` do); the actor is the real admin, so no escalation.
7. INFO: `/api/cyrus/tokens/return` and `storage/return` accept any `cs_` id without a session (idempotent, grants only to the session's own metadata account, only when paid).
8. INFO: admin token grants up to 1,000,000 by a BILLING account, no second approver (owner).

## Authorization matrix (deliverable 3)
- `test/_cyrus-authz-table.ts`: 120 rows (6 admin, 4 signed, 56 viewer, 16 session, 11 owned, 11 api key, 12 delegated, 4 public). Suite `authorization matrix` fails when a route file has no row, a row has no file, the source lacks the claimed guard marker, a new public route appears, or a delegated library handler stops answering 404 to an unknown viewer.
- Server actions: every exported action in the Cyrus action files must call a viewer / role / owner guard (static).
- Runtime: every `CYRUS_ADMIN_ACTIONS` entry (assets.view, live.view, storage.export...) is run through the real `cyrusAdminApiUser` against anonymous, USER, SUPPORT, BILLING, ADMIN, ADMIN off the preview list, and ADMIN impersonating: only the area's roles pass.
- UNVERIFIED: individual customer routes were not exercised one by one as "other user" and "owner" with live handlers; the shared `run()` wrapper and the catalogue are (existing tests), the rest are covered by the static guard class, not by per-route requests.

## Cost-abuse limits (deliverable 4)
| Limit | Where | State |
|---|---|---|
| Build creation 3/min, 20/h, 2 in flight per account | create.ts:98-103 | exists; count-then-create bounded |
| Token reserve/settle/release, daily cap per account | ledger.ts, economy.ts `dailyCapFor` | exists, race-safe (row lock + unique keys); `allowShort` (no cap) only while metering is off |
| Per-account / platform USD caps | cost-caps.ts | exists, default 0 = off (owner), in-flight builds not counted until `costUsd` is written (overshoot <= 2 x build budget) |
| Planner / coach per minute | plan route 30, coach 6 | existed |
| Planner / coach hour, day, global | ai-aux-limits.ts | NEW (BQ-2) |
| Service /plan /coach concurrency + hourly USD | auxgate.js | NEW (BQ-3) |
| Wallet top-up 6/min + idempotency key; refund replay | wallet route, `revokeTokens` idemKey `refund:<key>:<cents>` | exists |
| Import, meshgen, uploads | `rateLimit` in their deps, meshgen `budget.ts` | exists |

## Deploy classes
- Image redeploy (modbuilder): BQ-3.
- Portal promote: BQ-1, BQ-2, BQ-4 (routing.ts is middleware: promote needs a restart of nxeon-web).
- Owner / infra, exact changes (not applied): (a) nginx `cyrus-my` block: replace the `@cyrus_app` fallback for unknown paths by `return 404` and keep only the proxied prefixes listed in CYRUS-MY-LAUNCH.md section 3 (the app now also refuses, this removes the load); (b) firewall VM 88001 port 7340 to the tunnel / primary only; (c) set `cyrus_cost_*` caps before opening public (`/admin/cyrus` Cost tab); (d) decide planner / coach ceilings (env `CYRUS_PLAN_MAX_PER_HOUR` etc.); (e) no key rotation is required by this review.

## Tests
`test/cyrus-security-review.test.ts` (20 tests). Permission classifier: no call was denied.

# L - Cyrus separation audit (read-only, 2026-10-10)
Source: /tank/dev-worktrees/cyrus-r2 (feature/cyrus-r2 @ 05c8f053d7). Machine-readable: touchpoints.json.

## Headline
- lib/cyrus has 286 TS files; **41 import Nxeon internals (74 statements, 28 distinct modules)**, so 86% is already clean. lib/modbuilder adds 4 files / 13 statements. 185 UI/route files under app and components also import Nxeon.
- Cyrus tables: **28 (27 Cyrus* + ModBuild), zero relations/FKs**; user and server ids are plain strings. This is the best-case starting point.
- Top direct imports (files): lib/db 27, mods/guest-fs 9 (8 are type-only, GuestFs is already an interface), settings 5, preview-access 5, auth 3, rbac 3, stripe 3, rate-limit 2, mods/engine 2, safe-fetch 2.
- Nxeon-table call sites from Cyrus code: AuditLog 22, ServerMod 18, User 14, Server 13, Setting 11, Job 9, GameMod 5, ModUpdateRun 3, Notification 2.
- 34 routes, 25 pages, 71 cyrus_* Setting keys, about 70 CYRUS_* env names (plus MB_* service-only).

## Touchpoints by kind
| Kind | Where | Seam status |
|---|---|---|
| DB (own tables) | 27 lib/cyrus files + 22 app | Partial: deps.ts / deps-db.ts / store-prisma.ts, 21 files take *Deps |
| DB (Nxeon tables) | 97 call sites, 9 tables | Direct |
| Auth/session | 14 realUser/currentUser, 8 requireUser | Direct |
| RBAC | 7 hasPermission, 2 requireAdmin | Direct |
| Billing/Stripe | tokens/billing, state, sweep; 5 routes; webhook hook | Direct (3 lib files only) |
| Settings/flags | 71 keys, 10 files | Direct |
| Rate limit | 13 calls | Wrapped in 2 deps files |
| Email/notify | creator alerts, worker | Direct |
| Game install | guest-fs, engine, safe-fetch, installers, SshGuestFs | GuestFs injected; placement direct |
| Storage | S3 packs, 10 hardcoded disk paths | Env-configurable, partly hardcoded |
| Worker/jobs | 5 sweeps in Nxeon worker/index.ts, 4 worker files | Direct |
| Audit log | 22 calls, 10 files | Direct |
| Routes/domain | middleware carve-out, dashboard nav, nxm | Direct |
| Brand/UI | components/cyrus-tokens own; 48 files use nx/ui/admin | Mixed |

## Proposed HostAdapter (methods only)
session.current, session.real, access.mayUse(feature), rbac.can, users.get/byEmail, billing.createCheckout / openPortal / listCards / onEvent, settings.get / getBool / set, rateLimit.check, notify.send, audit.write, servers.list / get / files / restart / rcon, installs.record / list, games.family, net.safeFetch, jobs.enqueue, scheduler.register, storage.put / get / url, baseUrl, shell.navSlot.
Rule: lib/cyrus imports only `lib/cyrus/host` (types + one registry); `lib/cyrus/host-nxeon/` is the only place that imports Nxeon.

## Migration order
1. **Host module + lint rule** blocking new Nxeon imports in lib/cyrus (S).
2. Settings, rate-limit, audit, notify adapters (S each, ~12 files).
3. Auth/rbac/access adapter (M, ~10 lib files, 20 app files).
4. DB: single `cyrusDb` client export, move Nxeon-table access (User, Server, ServerMod, GameMod, Job) behind servers/users/installs (M-L, the 97 call sites).
5. Game install: wrap SshGuestFs + engine placement as servers.files (M).
6. Billing: contain Stripe behind billing adapter; decide model (M-L).
7. Worker: Cyrus scheduler entry point instead of editing worker/index.ts (S-M).
8. UI shell: shared primitives package, route basePath (L).
9. Hardcoded paths to env/storage adapter (S).

## Top 5 risks
1. Stripe: subscriptions and customers live in Nxeon's Stripe account; metadata and webhook are shared.
2. Opaque ids need a stable subject id across SSO; email-keyed matching would orphan balances.
3. ServerMod/GameMod hold Cyrus install state on the Nxeon side; split-brain on uninstall/update.
4. Delivery depends on SSH guest access to customer VMs; an external Cyrus needs a scoped Nxeon API, not credentials.
5. Hardcoded host paths and node-2 coupling (Test Flight, sound render, /root/claudebox.env credentials).

## Owner decisions
- Separate Stripe account, or Nxeon as payment provider (wallet debits)?
- SSO from Nxeon (OIDC, Kodely pattern) vs own accounts at launch?
- New domain and cookie scope; keep /mods/cyrus SEO via 301s?
- Where the Nxeon-side install API lives and its auth scheme.
- Own database and own Claude/Anthropic credentials, or shared?

## Move day checklist
1. Freeze writes; pg_dump the 28 tables; copy modbuilds, imports, sound library, pack S3 bucket.
2. Map Nxeon user ids to SSO subjects (userId and Stripe customer id kept).
3. Provision DB, env (CYRUS_*, MB_*, secrets), modbuilder service, render and Test Flight hosts.
4. Point the host adapter at Nxeon's API; verify list servers, push, restart.
5. DNS and TLS for the new domain; set SSO redirect URIs; cookies are host-scoped, so users re-login once.
6. Repoint Stripe webhook; reconcile plans via sweep.
7. 301 old /dashboard/cyrus, /api/cyrus, /mods/cyrus; remove Cyrus code and sweeps from Nxeon.
8. Smoke-test build, install and top-up; keep Nxeon rollback for a week.

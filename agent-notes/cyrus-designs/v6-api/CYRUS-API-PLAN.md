# Cyrus API v1: inventory and design (r25, 2026-10-10)
Branch `feature/cyrus-r25-api` (from `feature/cyrus-r2`). Direction B of CYRUS-TRACKER section 1: **Nxeon (or any site) calls Cyrus**. Direction A (Cyrus calls Nxeon) is the host seam `lib/cyrus/host`; this API is its mirror image. Nothing here is deployed; everything sits behind `CYRUS_API_V1` (off).

## 1. Inventory: 57 route files today, classified
U = internal UI backend (stays with the Cyrus UI, not public), P = public API candidate, A = admin-only, S = special.

| Group (files) | Today | Class | v1 resource |
|---|---|---|---|
| `mod-builder/builds` GET/POST, `builds/[id]` GET, `cancel`, `jar`, `source`, `source-zip`, `attachments/[n]` (8) | session, owner check | P | `builds` (create, get, cancel, artifacts) |
| `mod-builder/builds/[id]/live` (NDJSON proxy), `cyrus/generate` (forge stream) (2) | session | U now, P later as `events` (SSE) | `builds/{id}/events` |
| `mod-builder/builds/[id]/install` (1) | session, SSH push | P (write, later) | `installs` |
| `mod-builder/projects/[id]` PATCH, `mod-builder/uploads` (2) | session | P | `projects` meta, `uploads` |
| `cyrus/assets/v1/projects` GET, `.../pack` GET (2) | studio viewer | P | `projects/{id}/assets`, `projects/{id}/pack` |
| `cyrus/assets/v1/.../textures/*`, `.../sounds/*` candidates, reject, render, revisions (10) | studio viewer + plan gate | U (studio editing loop) | later `projects/{id}/assets/{slot}/revisions` |
| `cyrus/assets/v1/library` GET, `asset/[id]/png`, `upload`, `use` (4) | viewer + plan | P (read now, write later) | `library`, `catalog` |
| `cyrus/assets/v1/quality`, `sound/preview` (2) | viewer | U | none |
| `cyrus/assets/v1/model-editor/**` (4), `cyrus/models/v1/**` (4) | viewer + plan | U (studio), P later for drafts | `projects/{id}/drafts` |
| `cyrus/import` GET/POST, `[id]` GET/DELETE, `[id]/conflicts` (3) | flag + session | P (write, later) | `imports` |
| `cyrus/tokens` GET, `tokens/plan` POST (2) | session | P (read now via plan), write = owner decision | `account/plan`, `account/tokens` |
| `cyrus/tokens/checkout`, `checkout-line`, `return` (3) | session + Stripe | S: payment flow, stays with the payment owner | none in v1 |
| `cyrus/universe` (1) | preview gate | U (static shape) | `games` (static, later) |
| `nxlabs/cyrus/[slug]/{diff,download,source,media}`, `media/[id]` (5) | public pages / creator | P (read), U (media upload) | `mods` (published listings) |
| `admin/cyrus/ops` (1) | admin role + preview | A | `admin/*` (separate scope, later) |
| `cyrus/ai-gateway/v1/chat` (1) | per-server HMAC token | S: mods call it from game servers; its own contract | none |
| `p/[file]` (1) | public, content-addressed | S: pack hosting, never authenticated | none |
| `stripe/webhook` (Cyrus branch) (1) | Stripe signature | S: Nxeon-owned, becomes a Cyrus webhook consumer | none |

25 pages under `app/**/cyrus*` are UI and are not part of the API. The existing `/api/cyrus/assets/v1` and `/api/cyrus/models/v1` "v1" are UI versions (cookie session); the public API is a new, separate tree **`/api/cyrus/v1/`** so the two never mix.

## 2. Resource model
All ids are opaque strings. Users appear only as a **subject** (see auth).
- **projects**: `CyrusProject` (id `cp…`, game, namespace, title, head/lastPassing revision, revisionCount). `revisions` nested, append-only (seq, kind, status, manifest, ModSpec). Writes later: create, add revision, revert (expectedHeadId = optimistic concurrency, already in engine-core).
- **builds**: `ModBuild` (status queued…succeeded/failed, target version, plugin name/version, jar sha256/size, error code, engine release record, timings). Writes later: create (idempotency key required), cancel. Artifacts: `builds/{id}/jar`, `/source` as short-lived signed download URLs, never raw paths.
- **mods**: published listings (`CyrusModPage`, slug, versions, licence); read-only public data.
- **installs**: request "put build X / mod pack Y on server Z" and its result (async, webhook `install.result`). Cyrus never holds server credentials: the install itself runs through direction A.
- **assets / library**: project asset slots (`CyrusProjectAsset`), user library items, uploads.
- **catalog**: `CatalogEntry` v1 search/get, same gates as the model-facing `catalog_search`/`catalog_get` (plan tier, licence tier, proprietary clearance, published only).
- **account**: plan tier + token balance (read), plan changes (decision below).
- **drafts**: Model Studio / editor drafts (`CyrusModelDraft`), studios specs (MotionSpec, designer specs) as typed documents.
- **events**: build progress (SSE later) and outbound webhooks.
Schemas come from the existing Zod sources (`ModSpecV1Schema`, `CatalogEntryV1Z`, `MotionSpecSchema`) through `z.toJSONSchema`; the OpenAPI file is generated, never hand-copied.

## 3. Auth
Two layers, both required for user data:
1. **Service token** (who is calling): `Authorization: Bearer cyk_<keyId>_<secret>`. Cyrus stores only `sha256(secret)` per key with `client`, `scopes[]`, `rpm`. Constant-time compare. Scopes: `health` (implicit), `projects:read`, `builds:read`, `catalog:read`, later `projects:write`, `builds:write`, `installs:write`, `account:read`, `webhooks:manage`, `admin:read`. A missing scope = 403; unknown key = 401; flag off = 404 (route does not exist); bad config = 503; never open.
2. **Subject assertion** (on whose behalf): header `Cyrus-Subject: <b64url(payload)>.<b64url(sig)>`, **Ed25519**-signed by the caller (Nxeon holds the private key, Cyrus only the public key, so a leaked Cyrus config cannot mint identities). Payload `{v:1, iss, sub, aud:"cyrus-api-v1", iat, exp, jti}`; `iss` must equal the token's client; lifetime at most 120 s, 30 s skew; `jti` single-use (replay cache); `sub` is the **stable subject id** (today the Nxeon user id; later an SSO `sub`), **never an email** (a payload carrying `email` is rejected). Every project/build read is owner-checked against `sub`; someone else's object answers 404.
- Browser SSO for a standalone Cyrus site reuses the Kodely pattern (`/sso/authorize` → signed 5-min code → server-side exchange) but fixes its gaps: single-use codes, PKCE, and `sub` as the account link (Kodely links by user id too, good; its codes are replayable inside 5 min).
- **Rotation**: several keys per client may be active (`CYRUS_API_V1_KEYS` is a list); add new, deploy caller, remove old. Subject public keys carry a `kid`; two can be active.
- **Rate limits**: per key (`rpm`, default 120/min), fixed window through `host.rateLimit`; `429` + `Retry-After` + `RateLimit-*` headers. A shared store (Redis/Postgres) replaces the in-process window when Cyrus runs more than one instance.

## 4. Conventions
- **Idempotency**: every POST takes `Idempotency-Key` (required for builds, installs, plan changes). Stored 24 h per (key, client, subject) with the request hash; same key + same body replays the stored response, same key + different body = `409 idempotency_mismatch`. Needs one additive table `CyrusApiIdempotency` (SQL only, later).
- **Pagination**: cursor-based, `?limit=` (1–100, default 20) and `?cursor=` (opaque b64url of the last `createdAt,id`); response `{data:[…], nextCursor:string|null}`. Stable order `createdAt desc, id desc`.
- **Errors**: always `{error:{code, message, issues?:[{path, code, message}], requestId}}`, reusing the engine's `SpecIssue` shape so ModSpec validation errors pass through unchanged. Codes are stable snake_case (`unauthorized`, `forbidden_scope`, `not_found`, `rate_limited`, `bad_request`, `catalog_unavailable`, `api_misconfigured`…).
- **Versioning**: the path carries the major (`/v1`). Additive changes (new fields, endpoints, enum values documented as open) ship in v1; removals or meaning changes need `/v2`, with v1 kept at least 6 months and a `Deprecation`/`Sunset` header. `info.version` follows semver; the generated OpenAPI file is checked in and a test fails when it drifts from the Zod sources.

## 5. Webhooks Cyrus → Nxeon
Events: `build.finished` (succeeded/failed + jar sha256), `mod.published`, `install.result` (ok/error, restartRequired), `delivery.rolledback` (steps, reason), `library.contributed` (catalog ref, status). Body `{id, type, createdAt, subject, data}`. Headers `Cyrus-Webhook-Id`, `Cyrus-Webhook-Timestamp`, `Cyrus-Signature: v1=<hex HMAC-SHA256(secret, id.timestamp.body)>` with a **dedicated webhook secret** (never AUTH_SECRET, same lesson as Kodely's `kodely_webhook_secret`). Receiver rejects timestamps older than 5 min and remembers ids for 24 h (replay protection, exactly-once processing). Delivery: retries with backoff (1 m, 5 m, 30 m, 2 h, 12 h), then dead-letter visible in admin; at-least-once, ordered per subject is not guaranteed (each event carries the current state, not a delta). The signing helper is shared with direction A (`lib/cyrus/api/v1/signing.ts`).

## 6. Nxeon side and the pairing with direction A
- **Nxeon client** (`lib/cyrus-client` inside Nxeon, later): typed from the OpenAPI file; mints the subject assertion for the signed-in user; sends the service token; idempotency keys for writes; caches catalog reads; receives webhooks at `/api/webhooks/cyrus`.
- **HTTP host adapter** (`lib/cyrus/host/http.ts`): implements the same `CyrusHost` interface by calling a scoped **Nxeon partner API for Cyrus** (users, servers, records, installs with a file session, settings, audit, worker triggers), requests HMAC-signed (key id, timestamp, nonce, body hash), timeouts, bounded retries. The route table is one file (`host/http-protocol.ts`) used by the client and by the reference server, so Nxeon later mounts `handleHostApi(req, nxeonHost)` and gets the exact contract the tests prove. `db` stays local (Cyrus' own database); `rateLimit`, `canAccess`, `familyOf`, `pinnedVersion` are synchronous and stay local over a cached snapshot.
- Together: Nxeon asks Cyrus "build/install this" (direction B); Cyrus asks Nxeon "write these files on server Z, restart" (direction A). Server credentials never leave Nxeon.

## 7. Data ownership
| Data | Owner | Notes |
|---|---|---|
| Accounts, sessions, game servers, install records (`ServerMod`/`GameMod`) | Nxeon | Cyrus reads via direction A |
| Projects, revisions, builds, assets, catalog, mod pages, drafts, token ledger | Cyrus | its 28 tables, no FKs into Nxeon |
| Wallet and payments | **owner decision** | Option 1: **Nxeon is the payment provider**: Cyrus asks Nxeon to debit the shared wallet (`billing.debit` with idempotency key), Stripe stays in Nxeon's account, one wallet, no migration of customers. Option 2: **Cyrus gets its own Stripe account**: own checkout/portal/webhook, Nxeon users re-enter cards, subscriptions must be migrated or run down; cleaner product split, more work and churn. Recommendation: option 1 until Cyrus has its own customers. |

## 8. Migration path
1. (this branch) design, contract, read-only slice, HTTP adapter skeleton; all off.
2. Nxeon-side partner API for Cyrus (mount `handleHostApi(nxeonHost)`, scoped key) and the Nxeon client; owner-approved idempotency + webhook tables (SQL files).
3. **Dual mode behind flags**: Cyrus still in-process; a shadow job calls the HTTP API for every read the UI does and diffs results (`CYRUS_API_V1_SHADOW`), no user-visible change.
4. Writes through the API for internal callers (builds, installs) with idempotency; UI routes become thin clients.
5. Separate deploy (own domain, DB copy of the 28 tables, `setHost(httpHost)`); cut over by flag; keep the in-process path for a week as rollback.

## 9. Risks
- Identity: anything keyed by email orphans balances; enforced by the `sub`-only assertion.
- Install split-brain (Nxeon records vs Cyrus intent) if `install.result` is lost: webhook retries + a reconcile read.
- Remote file sessions are chatty (one HTTP call per file op); fine for plugin jars, batch later.
- Replay caches and rate limits are per process in the slice: a multi-instance deploy needs a shared store.
- The catalog index has no production backend yet (r26); the slice reads a configured JSONL file or answers 503.
- Stripe metadata (`cyrusUserId`) and the shared webhook stay Nxeon-side until the wallet decision.

## 10. Owner decisions
1. Wallet: Nxeon as payment provider (recommended) or separate Stripe account.
2. Sign-in at move day: SSO from Nxeon (recommended, one account) or Cyrus's own accounts.
3. API domain (`api.cyrus.<domain>` vs a path on the new site) and whether third parties (beyond Nxeon/Kodely) ever get keys.
4. Who may change plans through the API (Nxeon only, or also Kodely).
5. Retention for webhook dead letters and idempotency records (proposed 24 h / 30 d).

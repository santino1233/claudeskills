# V - Cyrus API v1 (r25, 2026-10-10)
Branch `feature/cyrus-r25-api` (worktree `/tank/dev-worktrees/cyrus-r25`, from `feature/cyrus-r2` @ 9afe84d58e). NOT merged, NOT deployed, flag `CYRUS_API_V1` OFF. No migration, no table, no Nxeon behaviour change (new files only, plus a docs section).

## Commits
1. `a31e54f088` design + inventory: `docs/api/CYRUS-API-PLAN.md` (= `cyrus-designs/v6-api/CYRUS-API-PLAN.md`). 57 route files classified (P public candidate / U UI-only / A admin / S special), resource model, auth, idempotency, pagination, errors, versioning, webhooks, data ownership (both wallet options), migration path, risks, owner decisions.
2. `a46850f1de` contract: `docs/api/cyrus-v1.openapi.yaml` (OpenAPI 3.1) generated from Zod (`lib/cyrus/api/v1/schemas.ts` reuses ModSpecV1Schema, CatalogEntryV1Z, MotionSpecSchema) + operation table `openapi.ts`; generator `tools/cyrus-api/gen-openapi.ts`; `test/cyrus-api-contract.test.ts`.
3. `252b9f64c1` read-only slice under `app/api/cyrus/v1/`: health, projects list/get, builds get, catalog search/get.
4. `10611085f3` HTTP host adapter skeleton: `lib/cyrus/host/http.ts`, `http-protocol.ts`, `http-server.ts`, `test/cyrus-host-http.test.ts`.
5. `1922f44151` docs: DOCUMENTATION.md "Cyrus API v1", OWNER-ACTIONS section, tracker 1B status, this report.

## Design choices worth knowing
- Two auth layers: service token (`cyk_<id>_<secret>`, only sha256 stored, scopes, per-key rpm) plus an **Ed25519-signed subject assertion** (Cyrus holds only the public key, so a leaked Cyrus config cannot mint identities). `sub` is the stable id; email is refused outright. 120 s max lifetime, single-use `jti`.
- Improves on the Kodely pattern it copies: scopes instead of one shared key, replay protection on assertions and webhooks, dedicated webhook secret (as Kodely already does), no AUTH_SECRET reuse.
- Contract is generated, never hand-copied; the test enforces live/planned honesty in both directions.
- Direction A over HTTP keeps `db`, `rateLimit` and the synchronous methods local; guest files are remote file sessions bound to the calling key, and installs run through them, so SSH credentials never leave Nxeon.
- New public tree `/api/cyrus/v1/` is separate from the UI's cookie-session `/api/cyrus/assets/v1` and `/models/v1`.

## Ran (all on node-2 via devhost)
- Full Cyrus suite `test/cyrus-*.test.ts`: **1906/1906 pass**, 0 skipped (includes the PyYAML cross-check of the contract file).
- `tsc --noEmit`: clean (after commit 4).
- New tests: contract 29, slice 26, HTTP host 13. The HTTP host conformance suite runs identically on a fake host and on `createHttpHost` over a real local HTTP server (Buffers, Dates, file sessions, install with prefetched bytes, settings, audit).
- **One real HTTP run**: `devhost db push`, `tools/cyrus-api/dev-seed.ts` (refuses non-`wt_*` DBs), `next dev` on node-2 with throwaway keys, tunnel + curl: health 200; projects 200; project 200 (head, lastPassing, spec); build 200 (no cost/jarPath); other subject's build 404; catalog search 200 and entry 200 on a 300-entry sample of the staged catalog; model search on Saka 403 `asset_locked`; no token 401; replayed assertion 401. Dev server stopped, tunnel closed, sample file deleted. The throwaway DB `wt_cyrus_r25` and its devhost env (test key hash, test public key) remain; `devhost rm` clears them.

## Not run / not built
- No write endpoints (builds, installs, revisions, plan changes), no idempotency table, no webhook sender or Nxeon receiver, no Nxeon-side client or assertion minting, no SSE events, no signed artifact URLs.
- The host reference server is mounted nowhere; no real Nxeon endpoint was called. `auth.user` role defaults to USER unless the platform passes `roleOf`.
- Replay caches and rate limits are in-process (one instance only).
- Catalog backend is a JSONL memory index (max 64 MB) until r26's database index; the staged files (120 MB) are over that cap on purpose.
- No load test; no next build of the app (tsc only).
- Merge risk: the contract test pins `docs/api/cyrus-v1.openapi.yaml`; anyone changing ModSpec/CatalogEntry/MotionSpec Zod must regenerate it (`npx tsx tools/cyrus-api/gen-openapi.ts`), or the test fails. That is intended.

## Owner decisions (also in OWNER-ACTIONS.md)
Wallet (Nxeon as payment provider, recommended, vs own Stripe); SSO from Nxeon (recommended) vs own accounts; API domain and third-party keys; who may change plans/start builds via API; retention for idempotency and dead letters; later approve the idempotency + webhook tables (SQL only).

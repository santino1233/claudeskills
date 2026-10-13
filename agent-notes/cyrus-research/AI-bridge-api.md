# AI - Cyrus bridge: Connect Cyrus + Nxeon Platform API (r38, 2026-10-11)
Branch `feature/cyrus-r38-bridge-api` (worktree `/tank/dev-worktrees/cyrus-r38`, from r2, latest r2 `1e20a0978a` merged). NOT merged into r2, NOT deployed, no migration run, no flag flipped. Defaults assumed: Nxeon = identity + wallet + payment provider; per-server grants; Cyrus never gets SSH.

## Commits
1. `08d09b7d5b` Connect Cyrus consent screen `/dashboard/connect/cyrus`, grants (7 scopes, revoke), memory + SQL stores, SQL proposal `prisma/manual-migration-cyrus-bridge-grants.sql`.
2. `a7aa53413c` Platform API v1 `/api/platform/cyrus/v1/*`: servers, inventory (incl. Mods-tab records), file primitives (allow-list, 64 MiB caps, sha preconditions), reload, budgeted restart, log tail, pack.set; HMAC + Cyrus-signed Ed25519 user assertion + grant per call; rate limits, idempotency, audit; rollback-only window after revoke. Cyrus client + `createHttpHost({ platform })` + delivery session over the primitives. OpenAPI generated + pinned.
3. `dccf08c4a3` Entitlements: plans/tokens as Nxeon products, `GET /entitlements`, signed `entitlement.changed`, Cyrus mirror (60 s cache, fail closed), reconciliation, refunds/chargebacks reverse once, partner hook (off).
4. `70cf992934` Events: change watcher (`server.version_changed`, `server.deleted` revokes grants), `server.restarted`, `grant.*`; Cyrus handlers (outdated -> SERVERS_AHEAD alert); wired build.finished, mod.published, install.result, delivery.rolledback.
5. `e0a5775e2a` UX: "Create a mod for this server" prefill; "Install to server" pre-install conflict report (Mods-tab duplicates block) in InstallModal + ShipBar.
6. `08939b5741` e2e + real flight + fixes + docs. Merge `044830d00e`.

## Ran (node-2 via devhost)
- `tsc --noEmit` clean; full Cyrus suite **2375/2375**; host seam + db-split ratchets pass (Cyrus tables via `cyrusDb` only).
- DB tests (throwaway `wt_cyrus_r38`, SQL proposal applied there only): 12/12 (mirror, fail-closed gate, pull, purchases once, refund + chargeback once, SQL grant store + outbox).
- Two-service e2e: 5/5 (fresh install, revoke mid-install, revoke mid-update, broken worldgen rollback with 2 budgeted restarts, no/read-only grant).
- **Real node-2 run** (`bridge-r38-flight-2026-10-11.json`): A delivered through 120 API calls (69 changes), one real Paper 1.21.11 Test Flight boot **passed** (boot, plugins, log clean, rcon, clean stop), health ok. R: revoke mid-update -> rolled back, **exact restore**, 1 forward refusal. The first run found a real bug (rollback re-creating an existing parent folder was refused -> rollback_incomplete); fixed, re-run clean. Throwaway dir removed.

## Fixed on the way
r36 purchase receiver dropped a failed event as a duplicate; purchase sender never flushed; tokens sweep would have sent mirrored plans to Stripe.

## Not done / not run
- No `next build`, no browser/Playwright of the consent page, buttons or reports.
- No real Nxeon server touched (fake Nxeon + Test Flight only); no real Stripe/dispute call.
- Memory stores/caches per process; card top-ups not in the snapshot; `library.contributed` unemitted; partner attribution computes a proposal only.

Owner list: `OWNER-ACTIONS.md` "r38" (SQL, consent copy, keys, flag order, chargeback + partner decisions).

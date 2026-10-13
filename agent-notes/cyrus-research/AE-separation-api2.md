# AE - Cyrus separation finish + API v1 phase 2 (r34, 2026-10-11)
Branch `feature/cyrus-r34-separation2` (worktree `/tank/dev-worktrees/cyrus-r34`, from `feature/cyrus-r2`, r2 merged again at the end incl. r32 security). NOT merged into r2, NOT deployed, no migration run, no flag flipped. Nothing changes inside Nxeon: new host methods delegate to the same functions.

## Commits
1. `121d03300d` seam: baseline **40 -> 5** imports. Pure modules moved into `lib/cyrus/builder|mods` (old paths re-export). New `host.builds`, `host.mods`, `host.billing` (Stripe containment + wallet; default provider = Nxeon; `billing-own-stripe.ts` = the other option, unused). Left on purpose (client-safe/pure): rbac role table, net-policy JSON, token UI component, Terraria versions, mod-health rules.
2. `70ff6c55e7` API phase 2: 6 more live operations (create project, create build, request install + status, config values, library contribution), Idempotency-Key (replay / 422 / 409, scoped per key+subject+op), scopes `config:write` `library:write`, the subject's Mod Builder access rule, an audit row per write. Webhooks: 5 builders, outbox interface, signed dispatcher, retries 1m/5m/30m/2h/12h then dead. `lib/cyrus-client` (Nxeon side, no Cyrus imports): typed client + webhook receiver. SQL proposal `prisma/manual-migration-cyrus-api-v1.sql` (NOT run).
3. `2cc007a662` dual mode: the conformance suite now covers wallet, mod pages and the local build engine on both transports (fake platform, and `createHttpHost` over a real local HTTP server serving a fake Nxeon); plus a lost-response wallet charge applied once, and real Cyrus code under `setHost(httpHost)`. Runbook `docs/CYRUS-MOVE-RUNBOOK.md`.
4. `c606e5535a` docs (DOCUMENTATION.md section). Merge `e7ed10d509`.

## Ran (node-2 via devhost)
- `tsc --noEmit`: clean (after the final merge).
- Full Cyrus suite `test/cyrus-*.test.ts`: **2235/2235** pass (after the merge).
- Contract regenerated and pinned; contract test also pins the client's operation table.

## Design notes
- Writes reuse the product paths with the subject as the user, so every existing gate applies (plan/tokens, delivery checks and acks with `CYRUS_DELIVERY`, Config Studio service with `CYRUS_CONFIG_STUDIO`, contribution filters with `CYRUS_LIBRARY_CONTRIBUTE`). Install deps come from the route (`lib/modbuilder/delivery`), keeping lib/cyrus seam-clean.
- `modBuilderAccess(user)` extracted from `modBuilderUser()` unchanged; `host.builds.accountFor` uses it for API subjects.
- Wallet adapter (`host.billing.wallet`) is the "Nxeon is the payment provider" option: same conditional debit as other products + a WalletTransaction row; Cyrus does not call it yet.

## Not done / honest gaps
- Host API not mounted in Nxeon; no webhook emitted by product code (5 points listed in the runbook); no Postgres idempotency/outbox/receipt stores (memory, one instance only).
- No real HTTP run of the new write endpoints (fake-deps tests + tsc only); no next build.
- Wallet charge idempotency across Nxeon instances needs a unique reference column (proposal only).
- `git mv` of `lib/modbuilder/types.ts`/`client.ts` with shims: branches editing those files will conflict on merge (take the change into `lib/cyrus/builder/*`).

## Owner decisions
Section added to `OWNER-ACTIONS.md`: wallet vs own Stripe / SSO / domain (unchanged, both options pluggable), approve the SQL, wallet reference column, who may attest library contributions, which keys get write scopes, webhook emission wiring.

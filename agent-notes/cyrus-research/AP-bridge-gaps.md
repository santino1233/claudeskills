# AP - Cyrus bridge gaps (r44, 2026-10-11)
Branch `feature/cyrus-r44-gaps` (worktree `/tank/dev-worktrees/cyrus-r44`, latest r2 `c0a369c888` merged). NOT merged into r2, NOT deployed, no migration run, no flag flipped, no email/Stripe/conversion sent, no paid model call. Every switch off = old behaviour.

## Commits (one per item)
1. `90cc881d10` Personal API keys on API v1 (`CYRUS_API_V1_PERSONAL_KEYS`): owner = subject, key scopes, per-key + per-account limits, suspended = 403, audit, last-used; OpenAPI `personalKey`.
2. `c61966eb37` Data export + delete jobs (`CYRUS_DATA_JOBS`): zip export (7-day owner download), delete after 14-day grace and only with `CYRUS_GDPR_ERASE` (else "waiting"), cascade per policy table, published library assets stay anonymised, admin "Data requests".
3. `fe25b42352` SQL webhook outbox (lease claim, retries, dead, replay, metrics) + Nxeon receiver; conversion sender (consent-checked outbox); attribution receiver (cyrus.my ref -> `nxeon_ref` on sign-up).
4. `94915970ce` Card top-ups through `deliverPurchase` (+ reconcile in event mode); "Pay from wallet" in the tokens screen.
5. `f60e099dca` Read-only Cyrus card on the Nxeon admin home (`CYRUS_ADMIN_SUMMARY`).
6. `18e53d0b5d` WebSocket keepalive pings in terminal-server + console-proxy (`WS_KEEPALIVE_MS`, unset = none).
7. `9b9f100f37` Matrix route + per-version rows, evidence badges on mod pages, Try It placed, Use in project path verified with the real sink.
Plus docs, regenerated references, r2 merge.

## Ran (node-2 via devhost)
- tsc clean; full `cyrus-*` + `modbuilder-*` + keepalive suite 2618/2619 after the r2 merge; the 1 (hardcoded export path) was fixed after (`config` + `data-jobs` tests 16/16, tsc clean again). Host-seam + db-split ratchets pass.
- DB tests on throwaway `wt_cyrus_r44` (`test/cyrus-bridge-gaps-db.test.ts`, 7/7 + `cyrus-bridge-purchase-db` 6/6): SQL outbox lease (two dispatchers, one claim), ladder -> dead, replay, metrics; dispatcher -> real receiver (signed, once across "instances", tampered 401); card top-up direct + event mode + reconcile once; admin summary reads; Use in project writes file + `CyrusProjectAsset` + revision, survives takedown; real zip export + delete.
- console-proxy as a real child process: pings with the env, none without.
- Screenshots (`cyrus-designs/impl-shots/gaps-*.png`, looked at): account data states, wallet button, Try It placement (tryit API stubbed in the browser), admin Cyrus card (phone), reconcile metrics.

## Not run / not done
- Screenshots of evidence badges, admin "Data requests" and admin home on desktop: node-2's agent slice ran out of memory (dev server OOM-killed twice). The public `/mods/cyrus` page 404s until the launch gate opens.
- No `next build`; no real Cloudflare/nginx; no real Meta/Google/Stripe; no real Try It player; no AI port build (matrix tested with fakes).
- Plan invoices still credit directly; no "export ready" email; Nxeon only audits received webhooks.
- 2 SQL proposals not applied (OWNER-ACTIONS "r44").
- Throwaway DB `wt_cyrus_r44` and `.shots/` remain on node-2 (`devhost rm`).

# AK - Cyrus admin + ops features (r40, 2026-10-11)
Branch `feature/cyrus-r40-admin` (worktree `/tank/dev-worktrees/cyrus-r40`, latest r2 1e20a0978a merged). **Nothing deployed, migrated, flipped or emailed; no paid model call.** Defaults assumed: admin stays in the existing app at /admin/cyrus (admin.cyrus.my later via the dual-host shell).

## Built (one commit each)
1. **Admin core**: Overview adds spend vs revenue (real ledger payments, test mode apart), Test Flight 7-day, accepted-eval status, top errors; Builds flight column/section; Users: read-only view-as (audited 30-min grant, not impersonation, which Cyrus refuses), ban + optional ADMIN-only Nxeon suspension (also closes a gap: API v1 subjects were not checked for `suspended`), GDPR export + erasure plan (erase behind `CYRUS_GDPR_ERASE` + typed email).
2. **Library moderation**: approve/reject/remove/restore, dismiss reports, near-duplicates, contribution stats, real-weapon/trademark list editor (applies to new contributions), DMCA case log + counter-notice workflow.
3. **Flags & kill switches**: launch pair moves together (typed confirm; legacy form can no longer flip `cyrus_tok_live` alone), global build pause (builds, changes, designer builds, imports; fails closed), AI gateway kill, every switch, env flags read-only, history.
4. **Cost**: spend per model/account, caps (0 = off, fail closed when set), alerts, margin per plan (list prices = settings), anomalies.
5. **Reconciliation**: wallet vs tokens + on-demand reconcile, ledger invariants, plan drift, dead webhook replay.
6. **Notifications**: one system, 5 events wired, bell, preference center, cyrus.my email via new optional `host.mail`; SPF/DKIM/DMARC checklist in docs.
7. **Support context**: `/dashboard/support?cyrusBuild=` snapshot + Cyrus panel on the admin ticket view.
8. **Consent/analytics**: banner (React + static `consent.js`), consent-gated attribution, Meta/Google payload spec.
Plus **AC O-1** (telemetry v2: timestamp + single-use batch, capped stream, IP limit) and **O-2** (gateway token expiry). All r40 code reads Cyrus tables through `cyrusDb` (overview moved fully: 7 call sites fewer).

## Ran
tsc clean; full `cyrus-*` + `modbuilder-*` suite 2461/2461 after the r2 merge (incl. host-seam and db-split ratchets); new `test/cyrus-admin-r40.test.ts`. Real dev server on node-2 with seeded throwaway DB: 11 pages x dark/phone = 22 `cadmin-*.png` in `cyrus-designs/impl-shots/`, all HTTP 200, no phone overflow; looked at, one copy fix.

## Not run / not built
Migrations (legal cases, notifications, ticket context: SQL only); real email; flags on; notification bell/consent banner/preference center not screenshotted (flags off); SQL outbox dispatcher; conversion sender; attribution receiver on nxeon.cloud; real Stripe/wallet; light theme shots; customer "Get help" link on the build page (URL contract only, for r39); the read-only Cyrus card on the main Nxeon admin.

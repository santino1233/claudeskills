# BILL / billfix — Stripe saved-card renewal failures (2026-10-01)

Branch `fix/stripe-saved-card-renewals`, worktree `/opt/nxeon-wt-billfix`, commit 43c8ccf624 (auto-pushed).

## Done
- Root cause found + reproduced in Stripe TEST mode: PM used on a PI without `setup_future_usage` (even WITH customer) stays unattached and can never be charged again; same for detached PMs. Error has NO `code` -> was classified `transient` -> hourly silent retry, suspension at day-10 cap with zero emails.
- Dead cards came from (a) outstanding-balance "settle" checkouts (no setup_future_usage, fulfil as top-up -> card recorded), (b) 7 PaymentCard rows written 2026-09-24 pointing at cards 6 customers had explicitly REMOVED (card.removed audits). bujangsmp = Visa 6300 removed 08-30.
- Code: lib/stripe-charge-errors.ts (pure classifier, not_reusable/missing_at_stripe), lib/stripe-cards.ts (persistCard attach-gate, markPaymentMethodUnusable, outstanding checkouts fixed), worker/billing.ts (retireUnusableCard, billingGraceUntil floor, nudgeCardReadd ladder day0/1/3/final), lib/mailer.ts (card_readd_* templates), portal banner (components/nx/BillingView.tsx), admin /admin/billing/card-health + actions (lib/actions-admin-billing.ts, components/admin/CardHealthControls.tsx), schema additive (PaymentCard.unusableAt/unusableReason, Server.billingGraceUntil), scripts/flag-unusable-payment-cards.ts, scripts/verify-card-reuse-testmode.ts, test/stripe-card-reuse.test.ts, docs section at end of DOCUMENTATION.md.
- Verified: `npx tsx --test test/stripe-card-reuse.test.ts` 17/17; `STRIPE_SECRET_KEY=<staging sk_test> npx tsx scripts/verify-card-reuse-testmode.ts` 11/11 PASS; tsc clean on app code — last run only flagged type narrowing in the test + verify script, fixed by `OffSessionFailure` return type in the SAME commit (re-check below).

## Half-done / re-verify
- Final `npx tsc --noEmit -p .` after the OffSessionFailure change: DONE, TSC_EXIT=0 (clean) on commit 43c8ccf624.
- UI (portal banner, admin card-health page) typechecked but NOT rendered (disk at 96% then; no dev server). Render both before merge.
- No throwaway DB used; schema not db-pushed anywhere yet (additive only).

## Remaining (ordered)
1. Re-run tsc (above); render /dashboard/billing with a flagged card and /admin/billing/card-health.
2. Merge to main, `prisma db push` (additive), deploy app + worker.
3. `NXEON_DB_TARGET=nxeon npx tsx scripts/flag-unusable-payment-cards.ts` (dry run) -> `--apply` -> `--apply --notify`.
4. Owner decision: the 09-24 rows resurrected REMOVED cards (consent issue) — consider telling those 6 customers.

## Blockers / owner today
- bujangsmp: /admin/servers/<id> -> Extend +7 days (don't press Renew now; fails identically until card re-added). At-risk next 7d: bujangsmp, dst-ddvzfe (10-04), minecraft-i4qk6y (10-06), projectzomboid-kc0kcr (10-06), epicsauce69 (10-07).
- Origin of the 09-24 back-write not in git (committed backfill would have skipped detached PMs).

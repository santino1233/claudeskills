# Nxeon conversion pass, 2026-10-15

Branch `feature/nx-conversion`, worktree `/tank/dev-worktrees/nx-conversion`, commit `9a432b83`. Not merged, not deployed. No schema change.
tsc clean via `scripts/devhost tsc`; `test/conversion-funnel.test.ts` 14/14, `test/email-templates-overhaul.test.ts` and `test/payment-events.test.ts` pass.
A wider sweep of tests that import settings/nav/email showed 7 failures in files this branch did not touch
(source-grep guards in admin-actions-guards, auth-lockouts, checkout-metadata, customer-actions-guards, invoice-renewal); `main` has 0 matches
for the `a.renewal` string invoice-renewal wants, so those predate this work.

## What the data really says about the game wizard

The 56% loss labelled "Region" is on the **Server** step (step before Region). Region is already preselected (`defaultRegionChoice`, geo-based,
since 2026-10-01) and Region -> Payment keeps 95% (61 -> 58). The Server step is the only one with two REQUIRED text fields that start empty:
server name (the "My server" text was only a placeholder, so it looked filled) and, for Minecraft, a globally unique play address. Next shook and
refused. Fixed with editable defaults, not by touching region logic. The Region slide now states which region is selected and why.
Owner decisions kept: no ms pings on region cards (2026-09-27), no "limited" badges (2026-10-06). The funnel's "complete" for games is 28 of 58
at Payment, which the new payment-fact logging is meant to explain.

## What changed

1. Instrumentation (`lib/deploy-funnel-core.ts`, `lib/deploy-funnel-client.ts`, `app/api/track/deploy-step/route.ts`, `lib/deploy-funnel.ts`,
   `components/nx/{DeployView,NxCardFields,NxLocalPayFields}.tsx`)
   - New `DeployFunnelEvent` types `payment` (errorCode = outcome, detail = whitelisted JSON) and `dwell` (ms on step). Outcomes: price_shown,
     attempt_started, insufficient_wallet, card_declined, card_insufficient_funds, card_expired, card_incorrect, card_processing_error,
     three_ds_required/failed, paypal_cancelled/error/unpaid/approved, validation_error, coupon_applied/invalid, abandoned, other_error.
   - Stripe.js errors classified from code/decline_code/type only; order refusals from fixed phrases; ORDER_ERROR rows get `detail.reason`.
   - Route: drops events with no session/visitor/user; server-side dedupe per actor (step 6h, complete 10m, payment 5s); scrubs emails/digits;
     detail is an allow-list. `complete` and provisioning `error` events are stamped with the account's latest session/visitor (24h).
   - Wallet top-up started/completed already exist in ActivityEvent (`payment.checkout_opened`/`payment.succeeded`, `data.purpose=topup`); read there.
   - Legacy per-product wizards (`components/customer/*DeployWizard.tsx`) keep their existing step/error beacons; they also gain dwell via the
     shared client helper and server-side dedupe/stamping.
2. Server-step defaults (`lib/nx/server-defaults.ts`, `components/nx/order.tsx`, `DeployView.tsx`): "<Game> server" name; `<game>-<4 chars>` play
   address suggested client-side once per game while empty (live availability check still gates it). The 2026-08-20 win-back email already
   claimed "server name prefilled"; it is now true.
3. Abandoned checkout (`lib/abandoned-checkout.ts`, `lib/abandoned-checkout-plan.ts`, `worker/abandoned-checkout.ts`, registered every 30 min)
   - Sweep: PENDING PayPal rows older than `pending_payment_abandon_hours` (24) -> `ABANDONED`. Only PENDING; conditional `updateMany`; PayPal
     asked via `getPayPalOrder`; COMPLETED is never abandoned (counted paid-unfulfilled, logged `console.error`); unreachable PayPal skips the row;
     404 = never paid; no providerRef = abandoned by age. Coinbase untouched.
   - Email `emails.abandonedCheckout` (template `abandoned_checkout`), marketing class (`product_news`), unsubscribe + List-Unsubscribe + tracking,
     cap 1 per customer per 14 days, max 20/run, skips paid/verified/opt-out/recent win-back, no discount. OFF by default.
   - Settings (Admin -> Settings -> Win-back): `abandoned_checkout_email_enabled` (false), `pending_payment_abandon_hours` (24),
     `abandoned_checkout_email_max_age_days` (7), `abandoned_checkout_email_cooldown_days` (14).
4. `/admin/conversion` (`app/admin/conversion/page.tsx`, `lib/conversion-dashboard.ts`, `lib/conversion-metrics.ts`,
   `components/admin/conversion/FunnelSvg.tsx`; nav: Traffic & analytics -> Conversion; analytics area).

## Metric definitions

- **Human visit**: `Visit.isBot=false` AND (`botKind` null or `human`) AND `webdriver` not true. (`isBot` already folds UA catalogue, DC IP, stale
  browser, velocity; botKind and webdriver are re-checked so a labelled-but-unflipped row is still excluded.)
- **Engaged human**: human visit with `interacted=true`. `null` (old client, no close beacon) is not engaged.
- **Visitor**: distinct `visitorId`, else `ip`, marketing-kind visits. "Bots excluded" = raw distinct minus human distinct.
- **Wizard actor**: distinct `sessionId` else `visitorId` else `userId`; any browser session that appears on a non-human Visit is dropped.
- **Step conversion**: share of actors at step N that also reached N+1 (last step: completed). Completion matches by userId when known.
- **Drop-off reason**: distinct actors with a logged failure fact on that step (error detail.reason/errorCode, payment outcome in the failure
  set). Remaining leavers are shown as "No reason logged" (not guessed).
- **Payments by method**: ActivityEvent category payment grouped by provider/outcome. Success rate = succeeded / (succeeded + failed + abandoned).
  Wallet-paid orders are not in ActivityEvent; the wallet line is WalletTransaction debits (includes renewals).
- **Abandoned value**: ABANDONED + stale (>24h) PENDING PayPal rows + Stripe checkouts expired unpaid.

## Owner commands

- No schema push required. (`PendingExternalPayment.status` is a plain string; `ABANDONED` is a new value. Wizard `detail` column already
  exists from the 2026-09-27 select-events migration; if `/admin/conversion` shows "could not be read", apply
  `prisma/manual-migration-deploy-funnel-select.sql`.)
- Review on staging: `scripts/deploy-staging.sh feature/nx-conversion`, click a game order (Server step prefilled, play address suggested),
  pay with a declining test card (4000 0000 0000 0002) and close a PayPal window, then open `/admin/conversion`.
- After promote, the stale sweep starts on its own (first run abandons the ~10 stale PayPal rows; any PayPal-COMPLETED-but-PENDING order is
  logged as `[abandoned-checkout] ... needs fulfilment review`, check `journalctl -u nxeon-worker | grep abandoned-checkout`).
- To turn the reminder email on: Admin -> Settings -> Win-back -> "Enable abandoned-checkout reminder emails" (or env
  `ABANDONED_CHECKOUT_EMAIL_ENABLED=true`). Preview the template in the admin email catalogue (`abandonedCheckout`).
- Stripe webhook events used by the dashboard are already enabled (`checkout.session.expired`, `payment_intent.payment_failed`, ...).

## Known gaps

- Region step latency stays a distance category (owner removed ms pings); not changed.
- Wallet-paid order success is not a payment record; only completion events show it.
- `components/customer/GameDeployWizard.tsx` (legacy, `/dashboard/games`) was not given the new payment facts or the name default.

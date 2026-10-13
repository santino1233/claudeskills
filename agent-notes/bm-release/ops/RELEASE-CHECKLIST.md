# Bare metal: release checklist (bm-ops, 2026-10-08)

Do NOT switch on `dedicated_public_enabled` until every box in section A is ticked on a REAL
server with the REAL supplier account. Everything in this list was verified only against the
supplier mock and a throwaway database (no Stripe live or test charge, no real supplier write).

Branch: `feature/bm-ops` (worktree `/tank/dev-worktrees/bm-ops`). Admin screen for all of this:
`/admin/dedicated/ops` (health tiles, orders queue, stuck/failed jobs, IP orders, renewals,
corrections, audit trail).

## A. Run once on a real machine before launch (owner or staff, ~2 hours)

Use one cheap in-stock build, your own customer account (preview allowlist), real card.

1. [ ] Deploy `feature/bm-ops` (schema push is additive: DedicatedServer columns,
       `WalletTransaction.fundsKind`, `DedicatedBillingCorrection`).
2. [ ] Settings check on `/admin/dedicated/ops`: catalogue sync tile OK and under 2x the interval;
       DRY RUN shown (default). Supplier reads "configured".
3. [ ] Order with the WALLET (real top-up first): the wizard shows the non-refundable notice and
       the box must be ticked; order lands PENDING; invoice PAID with the exact total; the order
       appears in the Operations queue with its promise (from the availability code).
4. [ ] Order with the CARD (Stripe live, small build or cancel quickly): card leg captured once,
       one order, no extra top-up invoice. Reload the confirm page twice: still one order.
5. [ ] Wallet with ONLY welcome/promo credit: the wizard offers no wallet money (shows the note),
       the card pays everything, the credit is still in the wallet afterwards.
6. [ ] Buy the machine upstream BY HAND (auto-order is not built, see the report), save its service
       name on the admin server page, set dry run OFF (`dedicated_ovh_dry_run=false`) for this test,
       click "Install & hand over". Watch: job progress, server ACTIVE, IPs filled, customer
       notification + the ready email arrive, tracking shows "ready".
7. [ ] Customer panel on the real machine: live status appears within ~5-10 s of first opening
       ("Updated just now"), Refresh works, hard reboot, rescue on (SSH key) and back to disk,
       reinstall (wipe!) with an SSH key, reverse DNS on the main IPv4, firewall on, add and remove
       a rule, firewall off.
8. [ ] Extra IP: buy 1 IPv4 (wallet), approve on the admin page, confirm the IP is routed to THIS
       server (not another one on the account), renewal price rises by the IP price, the address
       shows on the panel. Then create a virtual MAC for it (Network & IPs) and check it upstream.
9. [ ] Cancellation: "Cancel server" -> page says it runs to the end of the period; "Keep my
       server" undoes it. Cancel again and leave it.
10. [ ] Auto-pay: set `dedicated_autorenew_enabled=true`; on a test server set the renewal date to
        yesterday on the admin record; within 15 min it renews from real wallet funds (or the card
        for the shortfall), invoice PAID, date advanced one term. Run "Renew now" again: refused
        (already renewed).
11. [ ] Failed renewal: a test account with no real funds and no card: renewal failed notice,
        still ACTIVE; after the grace (3 days, or temporarily set `dedicated_renewal_grace_days=1`)
        it is SUSPENDED; topping up real funds renews and lifts it.
12. [ ] Admin refund on a dedicated invoice (`/admin/invoices/<id>` refund control): refused with the
        "non-refundable, use Billing correction" message. Record a $1 Billing correction on the
        server page: wallet +$1, audit row, correction listed.
13. [ ] Supplier slow/down: with the network to the supplier blocked (or a bad key on staging), the
        server page and panel still render instantly with the last snapshot and "Showing the last
        known state".
14. [ ] End the test machine upstream by hand; mark the record CANCELLED.
15. [ ] Legal: read `DEDICATED_TERMS_SECTION` in `lib/legal/terms.ts` (it appears on /legal/terms
        only once the public flag is on) and approve the wording.

Only then: `dedicated_public_enabled=true` (Pricing page switch) and, if you want automatic
renewals, `dedicated_autorenew_enabled=true`.

## B. Things that need the real supplier account to verify (mock-only today)

- Every write path (reboot, rescue, reinstall/handover, rDNS, firewall, IP cart order routed with
  `destination`, IP cart `country` value, virtual MAC create) is verified against the mock only.
- IP cart: that the generic `/order/cart/{id}/ip` products exist for our machines in each region
  and the `destination` + `country` configuration labels are what the real cart asks for.
- `install/status` progress shape during a real reinstall (the mock invents five steps).
- Virtual MAC: type value and the `virtualAddress` read shape.
- Delivery history: real order-to-delivery hours (the ETA uses the availability code until five
  orders have been delivered).
- Live panel reads on a real machine (hardware/network spec shapes were verified read-only on
  2026-10-06 per the docs; not re-checked in this session, by rule).

## C. Monitoring and alerting

Fixed in this branch:
- Late orders (paid, past the promise from the availability code): ADMIN notification once per 12 h
  per server (`worker/dedicated-billing.ts dedicatedOpsAlerts`), and on the Operations queue
  (on time / due soon / late / very late).
- Renewal date passed while auto-pay is off: ADMIN notification once per 12 h.
- Renewal failures, unpaid suspensions, end-of-term and unpaid terminations: customer + ADMIN
  notifications, Operations "Renewals needing attention".
- Jobs stuck RUNNING (worker restarted mid-step) are failed loudly with an ADMIN notification
  instead of hanging forever; timed-out IP orders no longer stay "ORDERING" forever.
- Failed jobs: ADMIN notification (existing) + Operations list with Retry.
- Catalogue sync freshness/failure: Operations health tile.
- Live-panel refresh failures: kept the last snapshot, error shown on the admin server page.

Still open (not built):
- No alert when the catalogue sync fails repeatedly (only the tile). Suggest: notify after 2
  consecutive FAILED syncs.
- No alert on supplier API errors as a rate (each failed job alerts individually).
- Price drift: a running server's cost rising upstream is not alerted (the catalogue records
  `priceChangedAt` for plans; machines keep their frozen cost).
- Chargebacks: the Stripe webhook alerts staff (URGENT notification) but nothing suspends the
  server automatically; staff suspend it by hand per the Terms.
- The support assistant's knowledge base still says bare metal is a custom quote
  (`lib/kb-facts.ts`, `lib/kb-llm.ts`, `lib/kb-system.ts`): update before launch.

## D. Owner switches (all default to the safe value)

| Setting | Default | Meaning |
|---|---|---|
| `dedicated_public_enabled` | false | Public release. |
| `dedicated_autorenew_enabled` | false | Auto-pay renewals (wallet real funds, then card). |
| `dedicated_renewal_grace_days` | 3 | Days a failed renewal keeps running before suspension. |
| `dedicated_renewal_terminate_days` | 10 | Days unpaid before the server is ended. |
| `dedicated_ovh_dry_run` | true | Nothing is sent to the supplier while true. |

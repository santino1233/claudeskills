# Overdue billing audit, 2026-10-18 (read-only; no charges, writes or emails)

Method: psql in a read-only transaction against prod, Stripe list/retrieve calls only, and the real price formulas
(lib/renewal-charge.ts `renewalCharge`, lib/product-billing.ts `hostingRenewalPrice`). No card numbers recorded.
No tax settings or billing countries are configured, and none of these customers is partner-attached, so price = net.

Stripe key rotation about 20:20Z on 2026-10-18. Evidence that "blocked, highest_risk_level, not_sent_to_network" failures
since 2026-10-13 are key-leak blocks: customer ammadshaikh63 (server web-01-oyrj) was blocked on 10-15 (2 charges) and
10-18 20:14Z with exactly that signature, then the SAME card for the SAME $26.99 was approved at 20:23Z after rotation
(renewed, expiry now 2026-11-18). Stripe's API does not expose "key leakage" as a separate field (outcome shows
type=blocked, reason=highest_risk_level, risk_level=highest, network_status=not_sent_to_network, seller_message "Stripe blocked
this payment as too risky"), so the signature plus date window (>= 10-13) is the discriminator. The same signature BEFORE 10-13
(newsite signup, 09-12) is a genuine Radar risk block.

## Overdue items (non-free, expired, 2026-10-18 ~21:00Z)

| Item | Customer | Product | Correct price (source) | Expired | State | Wallet | Card | Prior declines | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| suplosmp (cmu05l9nu0wbmhl3iela89r6f) | ssuplo788@gmail.com | Game server, Bedrock 2GB, monthly | $7.18 (game plan priceCents 718; no grandfather, no add-ons) | 10-13 18:34Z | RUNNING, grace floor 10-20 18:34Z, dunning stage 3 | $5.01 (short $2.17) | none usable: saved Visa retired 10-11 as `not_reusable` (platform fault, not a decline) | none (no real decline) | Needs new card or a $2.17 top-up. Our fault, not a decline. Suspends ~10-20 18:34Z |
| cs2-dbhy4p (cmu4mzkv90b1shlp19vdhli0r) | j30241665@gmail.com | Game server, CS2 4GB custom, monthly | $36.99 (grandfatheredRenewalCents 3699 = game plan 3699; the extra 50GB disk is NOT billed on game plans) | 10-16 21:52Z | RUNNING, stage 3, next action 10-21 21:52Z | $0 | Mastercard (DO) | 10-15 05:44: issuer decline `incorrect_number` (network advice 03 = do not retry, network code 79), plus a leak-block in the same minute; 10-18 20:24 (after rotation): Radar `previously_declined_do_not_retry` | Needs new card (real hard decline / do-not-retry, now Radar-poisoned) |
| skyora-prod (cmu0fr1lt05dthlmbb23ecoe3) | vemaybaynguyenhuyagent06@gmail.com | VPS Standard, monthly | $18.70 (plan priceCents 1870; no add-ons) | 10-13 23:18Z | SUSPENDED (UNPAID) since 10-16 23:25Z | $0 | none | none | Needs funds or a card (no payment method, no decline) |
| abc-alkhalejia.sites.nxeon.cloud (cmtbeqi1v03bmhltydtnpqhxi) | asrmohamed889966@gmail.com | Web hosting Starter, monthly | $2.99 (plan 299; no grandfather concept existed, no add-ons) | 09-27 | SUSPENDED since 09-30 | $0 | Visa (HK credit) | 09-27, 09-28, 09-29: `insufficient_funds`, advice try_again_later (all BEFORE the leak window) | Chargeable (soft decline; needs funds on the card, may decline again) |
| newsite.sites.nxeon.cloud (cmtypc2xq01zbhl3q5w816bln) | doejohhn36@gmail.com | Web hosting Pro, monthly | $8.99 (plan 899) | 10-12 | SUSPENDED since 10-15 | $0 | UnionPay debit (KR) | 09-12 signup: 2x `do_not_honor` (network advice 100) + 3x Radar highest_risk blocks (all pre-leak = genuine). 10-12 `processing_error` (issuer, soft, advice 40). 10-13 and 10-14: blocked highest_risk, not_sent_to_network = KEY-LEAK BLOCKS | Chargeable once (the October failures were leak blocks, the 10-12 one was a soft issuer error that DID reach the network). Residual risk: the 09-12 hard signals; expect a possible decline. One attempt only |

Totals: 5 overdue billed items, all five owe $74.85 combined ($7.18 + $36.99 + $18.70 + $2.99 + $8.99).
Chargeable now: abc ($2.99) + newsite ($8.99) = $11.98. Needs new card or funds: suplosmp, cs2, skyora = $62.87.
Price unclear: none. Notes: cs2's name says "+30GB disk correction" and it carries extraDiskGB=50; the renewal formula ignores extra disk
on game plans (flat all-in), so $36.99 is what the worker would charge; owner may want to confirm that is intended.

Not overdue/not billed: minecraft-t9ble6 (isFree=true, expiry 10-09, never billed or touched). No overdue domains, e-mail subscriptions, volumes,
dedicated servers (table empty), dedicated IPs (billed on the server) or Cyrus plans (table empty).
Upcoming: guyde.sites.nxeon.cloud (primetech3310@gmail.com, Starter $2.99) expires 10-19, no card, $0 wallet, never emailed.

## Other customers hit by leak blocks since 10-13 (failed charges, not overdue now)

- ammadshaikh63@gmail.com: web-01-oyrj, 3 renewal attempts blocked (10-15 x2, 10-18 20:14Z); renewed 10-18 20:23Z by the worker after rotation. Resolved. (Odd: the three attempts were $37.78, $20.99, $26.99 for the same server, worth a look.)
- adarshgarg921@gmail.com: a $32.99 NEW ORDER checkout blocked 10-15 16:41Z (no server exists): a lost sale. Not a renewal.
- joseloayalabajo@gmail.com: two checkout attempts with `incorrect_number` 10-13 (a genuine bad card number, not a leak block).
- newsite and cs2 as above.
No other failed charges since 10-08 in the whole Stripe account (12 total).

## Customer communication gap found

Server customers received dunning emails (payment_failed, retry_failed, card_readd_*). The two hosting customers (abc, newsite) received NO billing
email of any kind: hosting renewals only create in-app notifications. Suspension and the "will be deleted soon" warning are in-app notifications only for
servers too (no email sender).

## Teardown policy (code: worker/billing.ts, worker/index.ts, lib/dunning-config.ts)

Settings table has NO dunning/auto-suspend overrides, so defaults apply: grace 3 days, warn 7, terminate 14, auto_suspend on (days past expiry).

Servers (VPS/game):
1. Expiry (T+0): sweep tries wallet, then card for the shortfall. Soft decline: retries on days 1, 3, 5 (3 emails). Platform-fault card: re-add ladder, grace floor `billingGraceUntil` (+9 days).
2. Suspend: `suspendDueAt` = T+3d with no card, T+6d with a card (late ladders can slip it up to +4d more, capped). `suspendUnpaid` queues a SUSPEND job: the VM is STOPPED, its dedicated IP is RELEASED to the pool, status SUSPENDED/UNPAID. In-app notification only.
3. Warn: at T+7d an in-app "will be deleted soon" notification, once per 2 days. No email.
4. DELETE at T+14d (`terminateOverdue`, only UNPAID suspensions; abuse/admin suspensions use `reapAbandonedSuspended` on the same clock): status DELETING + DELETE job -> `remove()` in worker/index.ts: `destroyVm` purges the VM and EVERY disk (including volumes), deletes cloud-init snippet, releases dedicated IP, Steam GSLT, DNS, drops Volume rows, writes a metadata-only ServerArchive row, hard-deletes the Server row. Customer data is unrecoverable. A wallet balance that covers the renewal at any time before this auto-recovers the server (`billing.auto_recovered_suspended`).
Web hosting: NOTHING automatically terminates a hosting account. The sweep suspends it (T+3d, `suspendHosting`) and stops. Only an admin Terminate or customer cancel queues TERMINATE. A suspended account is never retried or reactivated automatically on payment (bug to fix in this branch).
Domains/email/volumes: email suspends after grace, volumes detach, no deletion.

Scheduled destruction now:
- skyora-prod: warn 10-20 23:18Z, DELETE 10-27 23:18Z (about 9 days). Only item in the destruction path.
- suplosmp: not yet suspended; suspension about 10-20 18:34Z (about 46h from now); delete would be 10-27 18:34Z.
- cs2-dbhy4p: suspension about 10-21 21:52Z; delete 10-30 21:52Z.
- hosting: nothing is scheduled for destruction.
Nothing is due for destruction within 48 hours.

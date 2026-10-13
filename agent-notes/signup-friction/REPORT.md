# Signup journey and friction, last 7 days (2026-09-29 to 10-06) vs previous 7 and previous 30

Read-only analysis (prod DB SELECT, journalctl, nginx, code). Internal QA accounts (nxeon-internal.test, nxeon.local) excluded
from rates; one QA account generated 35 of the 49 game provision errors and 79 of 93 game "complete" events this week.
No customer-identifying data is written here. Cohort = CUSTOMER accounts created in the window.

## Summary

Signups rose 56 percent week over week (150 real vs 96; previous-30-day average is 21/day, this week 21.6/day, last week 13.7/day).
The growth is almost entirely cold, free-intent traffic: 60 percent of this week's signups were ChatGPT-attributed
(utm_source=chatgpt.com, vs 26 percent last week), 58 landed first on /free-vps and 28 on /free-minecraft, and 45 percent are
Mobile (Android 41 percent), up from 33 percent. Those segments almost never buy: the 83 signups from /free-vps over two weeks
produced 0 servers and 0 paid top-ups; the 28 from /free-minecraft produced 0 and 0; mobile signups this week produced 0 servers
and 0 paid top-ups from 68 (1 server from 32 the week before). Because of that mix, the signup-to-order rate looks worse this week
(9 percent have a server vs 7 percent, but wizard-open fell to 56 percent from 69 percent and "reached Payment" fell to 23 percent
from 44 percent), even though the product itself (provisioning, wizard) is working: 23 of 23 new-user servers are RUNNING, the median
order-to-"deployed email" time is about 4.5 minutes, and card/Stripe top-ups are succeeding. The money friction is therefore
(1) acquisition-promise mismatch ("free VPS" pages vs no free VPS), (2) mobile wizard drop, (3) Payment-step abandonment, concentrated
in India/Indonesia/Singapore/Bangladesh, with no instrumentation to see why, and (4) post-signup activation (free Minecraft servers that
nobody connects to). Nothing in the Oct 5-6 deploys shows up as a new customer-facing regression; the 15:23 UTC crash cost about 5 minutes
and 29 /login 502s.

## Funnel (real accounts, users)

| Stage | Prev 30d (14-44d ago) | Prev 7d | This 7d |
|---|---|---|---|
| Signups | 627 (20.9/day) | 96 | 150 |
| Google sign-in share | 70% | 76% | 79% |
| Email signups verified (of email signups) | n/a | 16 of 23 (70%) | 23 of 31 (74%) |
| Opened any deploy wizard | 507 (81%) | 66 (69%) | 84 (56%) |
|  of which VPS / game / hosting / email | | 36/37/10/3 | 47/45/3/5 |
| Reached the Payment step | 133 (21%) | 42 (44%) | 34 (23%) |
| Has any server (incl. admin-granted/free) | 24 (3.8%) | 7 (7.3%) | 14 (9.3%) |
| Real paid top-up (Stripe or PayPal) | 26 (4.1%) | 9 (9.4%) | 9 (6.0%) |
| Returned 1+ day after signup | n/a | 15 (16%) | 23 (15%) |
| Returned 1+ day, owners of a server | | 4 of 7 | 9 of 14 (64%) |
| Returned 1+ day, non-owners | | 11 of 89 (12%) | 14 of 136 (10%) |

Session-level wizard steps (all visitors, QA excluded, steps used since the Sep 14 wizard rewrite):

| Wizard | Step | Prev 7d | This 7d |
|---|---|---|---|
| VPS | Configure | 60 | 59 |
|  | Region | 45 | 29 |
|  | Payment | 44 | 27 |
|  | Completed (events) | 5 | 2 |
| Game | Game | 50 | 48 |
|  | Server (plan) | 43 | 49 |
|  | Region | 26 | 22 |
|  | Payment | 24 | 19 |
|  | Completed (events) | 7 | 14 (about 11 users) |

Cohort mix, this week vs last: ChatGPT 91 vs 25 signups; Google organic 24 vs 39; direct 13 vs 5. Desktop 72 vs 58; Mobile 68 vs 32.
Top countries this week: India 16, Brazil 9, Germany 9, US 9, Indonesia 8, Philippines 5, Bangladesh 5, Vietnam 5, Mexico 5, Pakistan 5.
Brazil and Mexico are new in the top list (last week they were not in the top 10). Self-reported source ("heard about us", 150 users): ChatGPT 37, Google 12,
YouTube 5, 80 skipped. Partner program: referral clicks 101 this week vs 8 last week, 7 converted to a signup, 8 PartnerCustomer rows.

By segment (this week + last, real accounts):

| Segment | Signups | Opened wizard | Reached Payment | Has server | Paid |
|---|---|---|---|---|---|
| Desktop | 130 | 86 | 52 | 19 | 16 |
| Mobile | 100 | 57 | 22 | 1 | 2 |
| Landed on /free-vps | 83 | 53 | 21 | 0 | 0 |
| Landed on /free-minecraft (this week only) | 28 | 8 | 2 | 0 | 0 |
| ChatGPT-attributed, this week | 91 | 51 | 19 | 7 | 6 |
| ChatGPT-attributed, last week | 25 | 20 | 15 | 1 | 1 |
| Google organic (this week + last) | 63 | 41 | 23 | 5 | 4 |

## Top friction points (ranked)

### 1. Free-intent landing pages bring signups that cannot convert (project, but the copy change is quick)
- 83 /free-vps signups in 14 days, 0 servers, 0 paid. 28 /free-minecraft signups this week, 0 servers, 0 paid.
- The page itself says "nobody gives a real VPS away; there is no free tier" but the title/H1/URL ("Free VPS", "Start free") pull in people searching for a free VPS. Page title: "Free VPS: start free, no credit card". The sign-up credit is 0 for all 150 new users (signupCreditCents is 0), so "claim any free-credit offer" has nothing behind it.
- Fix: (quick) change the /free-vps hero to state what is actually free (free Minecraft server, no card to sign up) and show the price of the cheapest paid server in the hero; add a first-visit "starter credit" if the owner wants this traffic to convert; track /free-vps visitors separately in the admin dashboard so these signups do not mask real conversion. (project) decide whether ChatGPT-sourced "free" queries are the audience to chase; they generate signups but not revenue, which is consistent with the earlier finding that conversion (not traffic) is the bottleneck.

### 2. Mobile signups never reach a server (project)
- 68 mobile signups this week: 35 opened a wizard, 10 reached Payment, 0 ordered, 0 paid (week before: 32, 22, 12, 1, 2).
- Game wizard on mobile: 25 users hit step 1, 18 hit Server, only 5 reach Region and 5 Payment; desktop is 49, 48, 25, 24. So game wizard loses mobile users between Server (plan) and Region (28 percent proceed vs 52 percent on desktop). VPS: Configure 34 mobile to Region 18.
- Android is 62 of 150 signups (Mobile Chrome 54); iOS is only 9.
- Fix: audit /dashboard/deploy on a 390 px Android viewport (plan cards, region step, sticky continue button, keyboard covering the CTA, long single-column scroll); consider a "continue on desktop" link or email-me-this-config at the Payment step. Add a mobile/desktop split to /admin/deploy-funnel. Project (1-2 days).

### 3. Payment step abandonment with no visibility into why (quick instrumentation, then fix)
- 34 users reached Payment this week; 9 paid (26 percent). Last week 42 and 9 (21 percent), prior 30 days 133 and 26.
- Reached-Payment-to-paid by country (two weeks): India 7 reached, 1 paid; Indonesia 5 and 0; Singapore 6 and 0; Bangladesh 3 and 0; Iran 2 and 0; Netherlands 2 and 0; vs Philippines 3 of 7 and Vietnam 3 of 5, Malaysia 2 of 2, Australia 2 of 2.
- The data cannot say why. Payment goes through hosted Stripe Checkout and PayPal; the app logs nothing for card declines, 3DS failures, abandoned Checkout sessions or currency problems, and DeployFunnelEvent has no "checkout opened", "checkout cancelled", or "payment failed" event type (only 3 hosting "ORDER_ERROR"s and one VPS "impersonating" error appear at the Payment step). Web logs show only one Stripe error pattern, "[cards] detach failed ... not attached to a customer" (7 occurrences), and 2 "PaymentMethod previously used without Customer" transient billing errors on a renewal. PayPal: 3 PENDING gameOrder and 3 PENDING order that never completed in Sept 20-30 plus one "account not vault-enabled" fallback warning per restart.
- Fix: (quick) add events checkout_opened / checkout_cancelled / checkout_return(success) and a Stripe webhook handler that writes payment_intent.payment_failed with decline_code and country into DeployFunnelEvent or ErrorLog; (quick) confirm the local-methods endpoint (UPI, GrabPay, FPX, etc.) is surfaced for India/Indonesia/Singapore/Bangladesh at the Payment step; (project) wallet-minimum / first-month price display in local currency for the emerging markets that make up 50 to 60 percent of signups.

### 4. Free Minecraft activation gap (quick to investigate, medium to fix)
- 40 free Minecraft servers were created by new users in 14 days (33 this week; median 1.9 minutes after signup, so the create flow is fast). Only 6 of 40 (15 percent) were ever woken by a player, only 1 reached real multiplayer. Upsell was shown 22 times, clicked 4, and 1 of the 40 owners later bought a paid server.
- Chat topics from new users: "How do I invite my Bedrock player", "how to make it bedrock", "My Minecraft server is offline ... The VM must be running to control the game service" (Oct 4), "From where I can manage my server", "I cant connect to my server" (ticket). Sign that "how to connect and invite a friend" is the first-hour question.
- Fix: after create, show connect address (Java and Bedrock), copy button, "send to a friend" share link, and a "waiting for first player" state; add the first-wake nudge email at +30 min if nobody has connected. Quick win with a high effect on the 21 percent of new users who take this path.

### 5. Game-port verification failures and stale provisioning state (Bedrock fix shipped; verify)
- Real customers' game provisions failed with "game port N never opened ... ECONNREFUSED after ~307 s" 12 times in 14 days (Minecraft 25565 x2, Valheim 2456 x4 on node 178.63.94.114, CS-style 27015 x2, and Bedrock 19132/udp x3 on Oct 6 04:00-05:31 UTC across two nodes, before the 05:24 Bedrock TRANSPORT=raknet commit reached prod at 05:34 and a customer retried). Failure emails (`server_provision_failed`) went to 3 new users on Oct 1 (38 mails, most for QA servers) and 2 on Oct 2.
- None of the new-user servers is in ERROR; all 23 are RUNNING and order-to-deployed email is 2 to 10 minutes except Rust 4 GB (24.5 min) and Left 4 Dead 2 (29.5 min).
- Two new-user servers (Valheim 8 GB and Project Zomboid 8 GB, both Oct 2) show status RUNNING but provisioningStep still reads "Installing the game, this one is a large download..." 4.6 days later and no `server_deployed` email ever sent: the customer is never told the game is ready, and the step text is stale. Quick fix: clear provisioningStep on first successful A2S/port check and send the deployed email; add a watchdog for RUNNING servers with a non-empty provisioningStep older than 30 minutes.
- Fix: verify the Bedrock fix with a real Bedrock order on staging; alert when a real customer sees a PROVISION_FAILED event (currently only visible in the funnel table).

### 6. Capacity refusals for large VPS configs (quick to confirm, project to fix)
- ErrorLog and web logs: "RAM guard refused node-5, node-2, node-4 for a 32768 MB VM" 96 times Oct 2-6; "...node-5, node-2, node-4, node-6 for a 52224 MB VM" 7 times on Oct 6 (so node-6 is enabled but still full or ineligible for that size); "node-2, node-4 for a 16384 MB VM" 26; "node-4 for a 4096 MB VM" 43 (Oct 1 to Oct 6, including 14 on Oct 6). These errors carry no userId, so I cannot confirm they are customers. One new customer's Custom 6 vCPU / 32 GB VPS was finally created at 14:01 UTC Oct 6 after refusals from 05:17 through 13:45, which is consistent with a customer retrying for about 8 hours.
- Customer-visible effect is a generic failure in the wizard rather than "sold out" copy. Fix: surface a clear "this size is temporarily unavailable in region X, try Y" with a notify-me option; log the userId on refusals so they can be counted.

### 7. Mid-session breakage after deploys and a handful of 5xx on customer paths (quick)
- "Failed to find Server Action" (stale client after a deploy) appeared 253 times, 231 on Oct 1 (deploy day); client errors "Loading chunk N failed" about 30 over two weeks; React `removeChild` errors in the dashboard 41 (typical of browser translation/extensions, 4 browsers), "An error occurred in the Server Components render" 27.
- nginx 5xx on real customer paths this week: /login 502 x29 on Oct 6 (crash window 15:23-15:28 UTC, 60 502s in the hour), x9 Oct 3, x6 Oct 1; /dashboard/servers/* 502 x48; /dashboard/support 500 x45 on Oct 4 16:xx; /api/chat/upload 500 x22 (Oct 1 14:xx). No 500 on /dashboard/deploy or /register in the week.
- Fix: serve a "new version available, refresh" prompt on server-action failure (the deploy wizard in particular); investigate Oct 4 /dashboard/support 500s and Oct 1 chat upload 500s.

### 8. Hosting wizard validation dead-end and miscellaneous (quick)
- Hosting wizard: "Enter a valid domain (e.g. example.com)." fired twice on step Payment (Sept 26 and 27), i.e. the user got all the way to checkout before the domain was validated. Move validation to the Domain step. Hosting accounts for 3 of 84 wizard users this week, so this is low priority.
- Verification: 8 of 31 email signups this week never verified (15 users overall across two weeks); 10 of those 15 used the deploy wizard anyway, so verification is not blocking them. The verification link redirected to https://0.0.0.0:3000 until the fix at Oct 5 02:26 UTC reached prod (Oct 5 10:50 release); users who clicked it before then saw a broken page. Email-verify opens 19 of 36 (53 percent); clicks are not tracked on verify links.

## Win-back and other lifecycle emails
- deploy_winback: 121 distinct recipients in 14 days (69 this week); 17 opened (14 percent), 5 clicked (4 percent), 31 returned to the site, 5 ordered something afterwards and 2 topped up, 0 redeemed COMEBACK50. Marketing mail is working technically but is not moving revenue; the 50 percent offer is not the lever for this audience.
- server_deployed: 74 sent, 22 opened. invoice_new 107 sent, 15 opened (14 percent).

## Notable individual cases (masked)
- Customer h***: Bedrock server failed at 19132/udp three times on Oct 6 morning (two nodes), asked in chat how to invite a Bedrock player; likely the NetherNet default bug fixed at 05:34. Worth a proactive "fixed, redeploy" note once ticket replies are approved (no replies sent by this analysis).
- Customer z***: Valheim at 2456/udp on node 178.63.94.114 failed three times Oct 1, then succeeded on the 8 GB plan; two 8 GB servers (Valheim, Project Zomboid, Oct 2) still show the "large download" step text 4.6 days on, no ready email.
- Customer f***: 27015 (Source-engine) game failed twice Oct 2 within 40 minutes, then retried; a real customer hitting repeated failures like this is the case worth a proactive follow-up.
- Customer c*** (Sept 4 signup): "PVE POST .../qemu/657/config -> 403 Permission check failed" at game provision, Oct 4: a Proxmox token-permission failure on a node (not a customer mistake); same family as the known split-token item.
- A new-user ticket "Server cannot be created" (Oct 1) and "VPS web-01 stuck in ERROR state" (Sep 28): both closed; one failed dedicated-IP purchase was refunded automatically on Sep 28 (255 cents).
- Admin impersonation produced a customer-style error "This action is disabled while impersonating" on Sept 26 inside the VPS wizard, which is expected behavior, not a customer problem.

## Context for the Oct 5-6 changes
- Wizard version: steps unchanged since the Sep 14 rewrite (so w1 vs w0 is comparable). The deploy wizard preselect fix for Minecraft Latest shipped Oct 5 10:50.
- Bedrock fix commit 05:24 Oct 6 (prod 05:34): no Bedrock failures for real customers after 05:31 in the data; 2 Bedrock selections this week, so volume is too small to say the fix works end to end.
- Directory v2, status notices, invoices, node-6: no signup-impacting error found in logs; I found nothing in the data tying status notices or invoice changes to conversion.
- Primary crash at 15:23 UTC: web restarted 15:28:16; 502s on /login 29, /dashboard/servers/* 48 over the week mostly on Oct 5 10:xx and Oct 6 13/15 UTC; visits and signups continued (1 signup in the 15:00 hour).
- About 989 "Server Reference ID did not match" log lines since Sep 29 are scanner traffic (bad action IDs, bursty and peaking at about 20 per hour); not customer impact, but it fills logs that make real action errors harder to see.

## Data gaps to close (so the next run can answer the questions this one could not)
1. Payment outcomes: no record of Stripe/PayPal declines, 3DS failures, abandoned Checkout sessions, or currency; all payment-failure reasons asked about were unobservable. Add events (item 3 above).
2. Wallet top-ups for non-completers and "checkout opened" count.
3. First-week panel usage (console/files logins) is not recorded per account in a form joinable to signup; I used UserSession.lastSeenAt as a proxy.
4. Visit.userId is only set once a user is logged in; attribution here is by joining on visitorId, 94 percent coverage (144 of 153).
5. "Time to verify" is about 0 for all verified email users (verification is stamped at signup), so it cannot measure friction; the unverified-forever count is the useful number.

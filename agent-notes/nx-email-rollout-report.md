# nx-email-rollout report (2026-10-14)
Branch feature/nx-marketing-emails, worktree /tank/dev-worktrees/nx-marketing-emails, 6 commits on top of d82b0606 (last: 164f3ba3). Not merged, not deployed, nothing sent. /opt/nxeon untouched (only read: prod Settings social_* rows via psql SELECT).

## What changed
- wrapEmail() now renders shell v2 for EVERY email (catalog, DB bodies, worker/admin sends). Leading eyebrow/headline/short lead are lifted into the hero band (game key art when the template has a game family, else default beams + 64px badge image). All v1 components restyled (cards, hairline rows, full-width gradient buttons, check lists).
- 7 mockup designs in lib/email-designs.ts: welcome, invoice (paid/unpaid), renewal, Cyrus, datacenter, tips, partner. New catalog templates: cyrusAnnouncement, datacenterExpansion, tipsGuides (sample + admin preview entry + "Send test to me", which mails only the signed-in admin).
- Server-concerning emails take gameFamily and show the game tile row; live senders pass it (emailGameFamilyFor): renewal reminder, dunning (card/PayPal/3DS/re-add), provision failed, auto reboot.
- Cyrus notification mail restructured (header row, hero eyebrow/headline, full-width gradient button), still self-contained, Cyrus palette.
- sendMail: fills the footer social marker from Admin Settings, and has a test capture hook (mailTestHooks.capture, no delivery).

## Per-template status (66 samples + 4 non-catalog senders, all render on shell v2, all tested)
- Mockup-faithful: welcome, invoiceNew (+Paid), renewalWarning, renewalNeedsCard (+Vps), creatorPartnerInvite, cyrusAnnouncement, datacenterExpansion, tipsGuides, serverDeployed (3 variants, unchanged).
- Hero + badge + card/button treatment (generic layout): onboarding x3, emailVerify, passwordReset/Changed, loginAlert, teamInvite, genericNotification, deploy/dormant winback, flashSale, receipt, refundIssued, paymentReceipt, paymentFailed/RetryFailed/ActionRequired/FinalNotice, paypal x3, hostingRenewalCardNeeded, cardExpiringSoon, cardReaddRequired (3 stages), checkoutPaymentRetry, lowBalance, budgetAlert, couponGift, referralReward, affiliatePayout, provisioned, serverReady(+Game), provisionFailed, autoResourceReboot, reviewRequest/Invite, suspended, serverTerminated, backup/restore, volumeAttached, abuseAlert, domain x3, ssl x2, mailboxCreated, ticketOpened/Reply, staffDm.
- Non-catalog senders on shell v2 + tested: promoTrial (webp chips and big posters replaced by PNG/JPG), gpuRestock, whatsNew, partner grant notice. Converted automatically but without an own sample: vm-move notice, growth scoreboard, cyrus-lifecycle owner mail, newsletter campaign wrapper, DB-template bodies (legacy light hex remapped).
- Deliberately untouched: cold/outreach mail (plain, own compliance footer), admin report digest.

## Social links (what the footer shows)
Footer icons = getSocialLinks() (Admin Settings social_*), the same helper NxmFooter uses; nothing renders when unset. Production Settings on 2026-10-14 hold exactly four values, so these are the icons every email shows:
- YouTube https://www.youtube.com/@NxeonCloud
- Instagram https://www.instagram.com/nxeon.cloud/
- Facebook https://www.facebook.com/profile.php?id=61593319674660
- LinkedIn https://www.linkedin.com/company/nxeon/
No Discord, X or TikTok URL is configured, so none appears (a Discord invite exists hard-coded in kb-facts / PromoCarousel but is not a Setting; add it under Settings to get the icon in both footer and emails). Old MarketingFooter shows the same four. Preview fixtures use these four; tests assert footer == configured values and nothing when unset.

## Tracking
Unchanged (pixel, click rewrite + UTM, unsubscribe link, one-click List-Unsubscribe headers, secret links direct, attribution ids). test/email-rollout.test.ts sends EVERY sample through real sendMail with capture and asserts these; fixture test/fixtures/email-tracking-inventory.json covers all 66 templates (old entries keep the main baseline hrefs; new `unsubscribe` flag).

## Real data rule
Datacenter/continent counts from enabled Node regions; uptime tile only with >= 14 measured days and >= 1000 samples (else omitted; the 99.9% tile is NOT shown); mod counts omitted; articles = newest published BlogPost rows; renewal days/amount/plan from the sweep. Preview fixtures (labelled in code): 3 regions sgp1/fsn1/bhs1, sample article titles.

## Images (public/email, PNG/JPG only, all urls resolve, tested)
| dir | files before | bytes before | files after | bytes after |
|---|---|---|---|---|
| games (heroes unchanged, 46 tiles quantised 22-29 KB -> 6-8 KB) | 95 | 2,312,842 | 95 | 1,556,579 |
| badges (new) | 0 | 0 | 40 | 458,308 |
| art (welcome, gift, globe, cyrus banner+logo) | 0 | 0 | 5 | 270,350 |
| guides, posters (new) | 0 | 0 | 9 | 88,370 |
| icons / flags / social / logo | 24 | 83,555 | 24 | 82,456 |
| TOTAL | 119 | 2,396,397 | 173 | 2,456,064 (2.34 MB) |
Largest JPG 114 KB (cyrus banner), heroes <= 42 KB, every icon PNG <= 15 KB. No webp/svg referenced by any email. Tests enforce the budgets. Note: re-running scripts/email-assets.py regenerates raw tiles; run scripts/email-assets-optimize.py after.

## Previews (/root/email-preview-new/all/)
Per template: <key>.html, <key>.png (600px), <key>@390.png. sheet-{account,servers,billing,dunning,marketing,domains-support,other}.png; grid-4x2.png and compare-mockup-vs-render.png (mockup beside the 8 designs). Two full review rounds done (fixes: server-row wrapping, partner key/value layout, dark guide thumbs, pill sizing).

## Tests
tsc clean (devhost). email-rollout (new), email-templates-overhaul, server-deployed-email, dunning-schedule, email-log-redaction, cyrus-admin-r40, cyrus-support-r50: all pass (148 in the two main files). Wider run (mail/admin/auth/invoice tests): 7 failures, all PRE-EXISTING and unrelated (admin-actions-guards: actions-account ssh keys; auth-lockouts B4 regexes on register(); checkout payAndDeploy source check; "use server" export guard lists actions-admin-*). docs/DOCUMENTATION.md section 15 updated.

## Remaining gaps / honest notes
- Datacenter art is a generic dotted globe (no per-region marker); gift/welcome art are generated isometric illustrations, not designer art; owner may want hand-made replacements.
- Tips thumbnails are category art, not each post's cover unless it is a PNG/JPG.
- Outlook desktop gets flat navy (no bg images/gradients/rounded corners); Inter only where @import is allowed.
- Hero lead text sits over bright game art on some games (e.g. Minecraft retry-failed); readable but the least polished spot.
- Welcome/other senders show discord icon only if Settings gets a Discord URL.
- vm-move, scoreboard, cyrus-lifecycle mails have no dedicated sample (structure shared via wrapEmail).
- No real email delivered, no deploy/promote; baseline worktree /tank/dev-worktrees/nx-email-baseline can be removed.

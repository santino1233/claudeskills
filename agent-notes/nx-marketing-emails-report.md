# nx-marketing-emails report (2026-10-14)
Branch feature/nx-marketing-emails, worktree /tank/dev-worktrees/nx-marketing-emails. Not merged/deployed.

Scope: owner correction received mid-task: NO gameplay section on Nxeon marketing (reverted, nothing of it committed). Only task 2 done.

## Changed
- lib/email-render.ts: new shared dark shell (header logo + nav, navy card, accent edge, icon tiles, violet buttons, footer), new emailIconTile/emailFeatureRows/htmlToText, legacy light-hex remap for DB bodies.
- lib/email-templates.ts, lib/mailer.ts: build() adds icon tile; flash sale rebuilt on shell; new emails.budgetAlert.
- Rebuilt on shell: lib/promo-trial-email.ts, lib/dedicated/stock-alerts.ts, worker/vm-move.ts, lib/growth/scoreboard.ts; Cyrus mail lib/cyrus/notify/templates.ts restyled (self-contained, keeps cyrus palette).
- Plain text: sendMail now uses htmlToText.
- Added: lib/email-samples.ts, scripts/email-inventory.ts, scripts/email-preview.ts, test/email-templates-overhaul.test.ts, test/fixtures/email-tracking-inventory.json (baseline from main). Docs section 15 updated.

## Tracking
Pixel, click rewrite, secret-link exemption, List-Unsubscribe(+Post) untouched in lib/mailer.ts. Per-template link inventory vs main: all preserved (flashSale's duplicate Outlook-VML CTA href dropped, one copy remains).

## Results
tsc clean (devhost); email-templates-overhaul + server-deployed-email + dunning-schedule + email-log-redaction + cyrus-admin-r40 all pass (overhaul test: 63 pass).
Preview: scripts/email-preview.ts (58 templates); screenshots reviewed for welcome/serverDeployed (looked right).

## Uncertain
- Not touched on purpose: outreach/coldemail/creator-outreach (plain, own compliance footers), admin report digest.
- Footer has no social icons (no fabricated links; flash sale lists real social links as text).
- Dark shell vs earlier note that light mail lands in primary more reliably: owner mockup followed.
- Logo uses /brand/logo-email.png (exists in public/, white wordmark); not verifiable from sandbox.
- reviewInvite never rendered its unsubscribe link in body (pre-existing; header only).
- Baseline worktree /tank/dev-worktrees/nx-email-baseline can be removed.

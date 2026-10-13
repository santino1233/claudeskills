---
name: nxeon-deploy-winback
description: Automated deploy-abandonment win-back email (LIVE) + coupons + admin timer controls
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-20T14:27:24.468Z
---

**Deploy win-back automation** — shipped + ENABLED 2026-08-20. When a signed-in user abandons the deploy wizard, a worker sweep emails them 50% off their first month.

- **Sweep:** `worker/deploy-winback.ts` (`deployWinbackSweep`, registered in `worker/index.ts`, ~15-min cadence). Skips: completers, server-owners, unverified email, marketing opt-outs/suppressed, and anyone already emailed (dedupe via `EmailLog` where `template='deploy_winback'`). Cap 25/run, sends ~1.2s apart.
- **Email:** `emails.deployWinback` in `lib/email-templates.ts`, built on the shared branded shell (`lib/email-render.ts`, logo = hosted `https://nxeon.cloud/logo.png`). Marketing-class send (`product_news` NotifyKind) so `mayDeliverTo` enforces suppression/opt-out. One-click unsubscribe: `lib/marketing-unsub.ts` + `app/api/unsubscribe/route.ts` (token = `<userId>.<HMAC(AUTH_SECRET,"unsub-marketing:<userId>")>`), plus `List-Unsubscribe` header (only set when `listUnsubscribeUrl` passed to `sendMail`, so transactional email is untouched).
- **Admin controls:** `/admin/settings` → **Win-back** tab (`components/admin/settings/WinbackPanel.tsx`). Settings: `deploy_winback_enabled` (bool, currently `true`), `deploy_winback_delay_minutes` (default 30; wait after they leave), `deploy_winback_max_age_days` (default 30; lookback window). Sweep reads these live via `getSettingInt`.
- **Coupons:** `COMEBACK50` = the campaign code (PERCENT 50, ORDER scope, maxTermMonths 1, firstTimeOnly, one-per-person, expires 2027-12-31). `WINTER50` = a single-use code made earlier just for WinterRDP (expires 2026-09-03). Coupon engine: `Coupon`/`CouponRedemption` models, admin at `/admin/coupons`.
- **First live sweep (2026-08-20 14:26 UTC):** considered 5, sent 4 (incl. winteru20rdp@gmail.com / WinterRDP — the customer the owner asked to re-engage), skipped 1.
- Built on the same-day analytics work: [[nxeon-deploy-funnel]] (visit→account attribution, per-step deploy funnel with drop-off + error tracking) and the deploy-wizard de-intimidation (prefilled editable hostname, collapsed advanced options). Owner: [[nxeon-platform]].

---
name: nxeon-creator-partner-program-live
description: "full Creator Partner Program shipped 2026-09-26 — click tracking, sitewide discounts, dedicated-IP commission exclusion, admin invites, partial payouts"
metadata:
  node_type: memory
  type: project
  originSessionId: ec6fa978-d80b-4147-9982-eea470598e2c
  modified: 2026-09-26T04:55:48.879Z
---

Shipped 2026-09-26 to production (`/opt/nxeon`, commit `19085c7b45`). Built on top of the pre-existing `ReferralPartner`/`PartnerCustomer`/`PartnerCommission` foundation (automatic registration-time attachment already existed from an earlier session that day — don't assume it needs rebuilding).

**Real link**: `nxeon.cloud/partner/<code>` (`app/partner/[code]/route.ts`), records a real `ReferralClick` before redirecting. `/r/<code>` (legacy) does the same now.

**Customer discount** (lifetime, once attached): 50% off first purchase of any real service except domains, 10% off every purchase after, forever. Pure math in `lib/partner-discount.ts`, DB resolution in `lib/partner-pricing.ts`, wired into every real charge path (VPS/game order, every renewal path including `renewNow`). Visible pre-purchase on `/pricing` and in the deploy wizard.

**Commission**: `lib/partner-commission.ts`'s `commissionableBaseCents()` excludes dedicated-IP add-on cents via a real typed `Invoice.dedicatedIpCents` column — never string-matched from line items, so it can't be fooled by a description change later.

**Admin**: partner-login invites for brand-new accounts, partial/specific-amount payouts (separate `PartnerPayout` ledger from `PartnerCommission` — earned vs. paid are two ledgers, balance = earned − paid), real click→signup→conversion funnel.

**Partner portal** (`/dashboard/partner`): real link, funnel stats, payout history, a media kit (real Nxeon logo files + 2 new on-brand SVG promo banners), terms using each partner's REAL negotiated rate (not a hardcoded "40%" — that number is specific to an unrelated cold-outreach campaign).

**Deliberately deferred, documented not silent**: cloud hosting / business email / shared hosting don't carry the discount yet (no coupon-style plumbing on those order paths to extend). No admin-configured payout method/minimum exists anywhere in the codebase — the terms panel says so honestly rather than inventing a number.

**Real incident from the build**: the build agent's isolated test-DB seed script overwrote `/root/nxeon-credentials.txt` (the on-disk admin-password reference note) with a throwaway test login, because it didn't override the default `NXEON_CRED_FILE` path. Production database/password were NOT touched — only the local reference file. If the real admin password isn't saved elsewhere, a real password reset is needed to regain access via that note; not done automatically, needs explicit sign-off (standing credential-rotation policy).

**2026-09-26 follow-up, also live**: the 50%/10% discount is now visible in TWO more places for a referred customer — Billing (`app/dashboard/billing/page.tsx` + `components/nx/BillingView.tsx`'s `PartnerDiscountBanner`) AND the Partner Program page itself (`app/dashboard/partner/page.tsx` + `components/nx/PartnerView.tsx`'s `ApplyLanding`, via a new optional `discount` prop) — the latter fixed directly in response to a real customer (VillaVerse) screenshot showing the generic apply-pitch with no mention of their own active deal. Both reuse `partnerPreviewForUser()` and the exact copy already used on `/pricing`. Verified on staging both times with a throwaway partner+attachment (both tiers, screenshotted, then deleted) before promoting.

See [[nxeon-referral-and-currency]] for the original partner-program design note and [[nxeon-grandfather-pricing-fleet-tags]] for the sibling admin-pricing feature shipped the day before.

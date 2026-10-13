---
name: nxeon-referral-and-currency
description: "KOL/agency lifetime-commission partner program + geo display-currency — design decisions locked and two build/infra gotchas"
metadata:
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-15T19:49:46.202Z
---

Both shipped to prod 2026-08-15 (Nxeon Ideas-board wave).

**KOL/Agency partner program** (`lib/partner-commission.ts`, `lib/actions-partner.ts`, models `ReferralPartner`/`PartnerCustomer`/`PartnerCommission`; routes `/dashboard/partner`, `/admin/partners`, `/admin/partners/[id]`). Separate from the peer-referral program (`User.referredById` + `lib/actions-growth.ts`). Locked design decisions:
- Commission on NET (pre-tax) PAID invoices only; wallet top-ups/refunds excluded; idempotent via `PartnerCommission.invoiceId` unique.
- **Free first month earns nothing** (no positive invoice).
- **Future-only attribution**: `accrueCommissionForInvoice` guards `inv.createdAt >= attachment.createdAt`, so attaching an existing customer never back-bills prior charges.
- **Partner codes take precedence over peer-referral codes** at registration (`lib/actions.ts` register): a `?ref=` that is an ACTIVE partner code attaches to the partner and does NOT also set `referredById` — one code can't pay both.
- Payout = OFF-WALLET, admin marks ACCRUED→PAID (bank transfer). `commissionRatePct` is per-partner, admin-set. USER caution: 50% lifetime on all services is very aggressive on hosting margins — set per-partner deliberately (20-30% recurring is more typical).

**Display-currency geo** (`lib/currency-display.ts` `resolveDisplayCurrency`: cookie → CDN country header → **geoip-lite(IP)** → operator default). DISPLAY-only — USD stays the charge currency. Admin FX-rate override at Settings→Billing (`currency_rates` JSON). **111 currencies / 229 countries** (`lib/currency.ts` CURRENCIES/DEFAULT_CURRENCY_RATES/ZERO_DECIMAL_CURRENCIES + `lib/geo-currency.ts` COUNTRY_TO_CURRENCY). Currency **switcher** is in the marketing footer (`MarketingFooter`) AND the customer-portal header (`components/portal/Shell.tsx`, next to the notification bell).
⚠️ **GOTCHA:** `countryFromHeaders()` returns `""` (empty string), NOT null, when no CDN header — so `resolveDisplayCurrency` must combine it with the geoip fallback via `||`, NOT `??` (a `??` bug made every visitor fall to USD despite correct geo). Verified: VN IP → ₫, GB IP → £.
⚠️ **GOTCHA:** `geoip-lite` MUST stay in `serverExternalPackages` in `next.config.ts` — without it, `next build` fails "Failed to collect page data for /" (webpack rewrites geoip-lite's `__dirname` so its data files can't be read). `lib/geo-ip.ts` is server-only/Node. If Cloudflare/nginx GeoIP is added later, the header path wins over geoip-lite automatically. See [[nxeon-meta-pixel]], [[nxeon-chat-agent]].

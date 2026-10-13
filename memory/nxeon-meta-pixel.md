---
name: nxeon-meta-pixel
description: "Meta Pixel + Conversions API tracking on nxeon.cloud — the PageView-undercount / fbc-coverage / signup-event fix and remaining owner actions"
metadata:
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-15T16:48:24.087Z
---

Meta Pixel/CAPI for nxeon.cloud (dataset/pixel id `1595663328636127`). Config is in admin Settings → Marketing → Tracking (`meta_pixel_id`, `meta_capi_token` encrypted, `meta_test_event_code`, `google_ads_*`, `meta_domain_verification`). Code: `lib/tracking.ts` (`sendMetaConversion` — CAPI, hashes email/phone, forwards fbc/fbp/IP/UA), `components/marketing/ConversionTags.tsx` (base pixel), `ConsentedTags.tsx`/`TrackingProvider` (consent gate; `lib/consent.ts` `marketingAllowed()` is DEFAULT-ON / opt-out). Inert unless configured.

**2026-08-15 fix (branch `fix/chat-agent-and-meta-pixel` → prod).** Board "Events manager" card (Ideas): Events Manager showed PageView=2 vs 100+ visits, Meta's "low fbc coverage" warning, and no real signup event. Root causes were CODE defects (config was fine):
- PageView fired once on load and never re-fired on client-side SPA route changes → ≤1 PageView per session. **Fix:** new `components/marketing/MetaPixelTracker.tsx` re-fires `fbq('track','PageView')` on every `usePathname` change (skips first mount), mounted once in `app/layout.tsx`.
- `_fbc` (click id) only ever written by the pixel, which barely loaded / is ad-blocked → CAPI shipped without it. **Fix:** MetaPixelTracker synthesizes `_fbc` from the `fbclid` URL param in Meta's `fb.1.<ts>.<fbclid>` format.
- Signup fired browser-only (dependent on the dead pixel), no server CAPI. **Fix:** server-side `CompleteRegistration` in `register()` (`lib/actions.ts`) with hashed email + external_id + IP/UA + fbc/fbp, and a shared `event_id` threaded to the browser via redirect `&se=` → `components/marketing/SignupTracker.tsx` dedups.

**Owner actions code can't do:** (1) the dataset is installed on **2 domains** — nxeon.cloud (7 events/28d) AND `wildcard.revsports.ca` (1) — that's the "Multiple integration / +1 more"; revsports.ca was rerouted to nxeon.cloud (see [[nxeon-server-topology]]) so the stray property should be removed/verified in Meta or the pixel restricted to the canonical domain. (2) Verify via Meta **Test Events** after deploy (set `meta_test_event_code` for a dry-run). (3) fbc only exists for ad-click traffic; organic matches on email+external_id+IP/UA — expected. (4) CompleteRegistration won't backfill history. Ad campaign UTM note: use `utm_medium=paidsocial` (not cpc) for Meta; landing `/web-hosting` is correct for the first-month-free (hosting-only) promo. See [[nxeon-chat-agent]].

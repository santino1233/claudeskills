---
name: nxeon-riddle-and-ads
description: "/riddle promo (LIVE, $100 first-solver) + server-side Google Ads offline conversion upload (built, needs API creds)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-21T17:19:34.045Z
---

Shipped 2026-08-21 (commit fe4d993 + fix 2d9fe99).

## /riddle — "The Nxeon Cipher" promo (LIVE)
Login-gated 4-gate riddle; FIRST correct answer wins a $100 wallet credit (valid toward one VPS). Atomic via `RiddleWinner.singleton` unique index. Per-user throttle 15/hr. Attempts logged in `RiddleAttempt`.
- **Gate 1**: base64 HTML comment in /riddle source (view-source) → points to /robots.txt. Verse acrostic spells VIEW SOURCE.
- **Gate 2**: /robots.txt `Disallow: /riddle/chamber-of-echoes` (the odd-one-out).
- **Gate 3**: /riddle/chamber-of-echoes (login-gated route handler) shows a Vigenère ciphertext; the KEY `PRIMARY` is leaked ONLY in the `X-Cipher-Key` response header. Decodes → points to the sigil image.
- **Gate 4**: /riddle/sigil.png (public/riddle/sigil.png) has the seal in a tEXt chunk + after IEND, in "mirror script" = reversed. `4337-XILEH-NAIDISBO` reversed = the answer.
- **ANSWER**: `OBSIDIAN-HELIX-7334` (normalized OBSIDIANHELIX7334). Change without deploy via the `riddle_answer` Setting. Logic in lib/riddle.ts.

## Google Ads offline conversion upload (built, INERT until creds)
Fixes gtag under-reporting. lib/google-ads.ts: `recordAdsConversion()` queues an `AdsConversion` row at signup (lib/actions.ts register) + paid order (lib/fulfil-checkout.ts reportPurchase) using the user's captured [[nxeon-meta-pixel]] gclid; worker sweep `googleAdsConversionSweep` (~15min) uploads via Ads API v17 `uploadClickConversions`. Rows queue even with no creds (nothing lost).
**Owner must supply (Google-side) to activate** — set in admin tracking Settings (keys allowlisted): `google_ads_developer_token`, `google_ads_customer_id`, `google_ads_login_customer_id`, `google_ads_oauth_client_id/secret/refresh_token`, and per-action `google_ads_ca_signup|purchase|vps|hosting|game|email` (conversion-action resource name or bare id). Needs a Google Ads API developer token (approval can take days). Client-side gtag (`AW-600125629`) still fires in parallel — see the conversion-not-showing diagnosis (date range + Leads tab + Primary action).

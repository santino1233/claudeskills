---
name: nxeon-kodely-partner
description: Kodely↔Nxeon integration — SSO + Partner API foundation LIVE; one account/one wallet; Nxeon sells domains/hosting/VPS inside Kodely
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-22T20:12:15.412Z
---

Goal (owner, 2026-08-22): seamless integration so Kodely users can buy a custom **domain**, **shared hosting**, or a **VPS** from inside [[nxeon-kodely]], with **one account + one wallet** (Nxeon is the hub for identity/billing/provisioning). Chosen model: **unified SSO**, not reseller.

## Phase 1 — SHIPPED to prod (commit a71f1fa/0b589ff)
Nxeon side (lib/partner.ts + app/sso + app/api/partner/*):
- **SSO**: `GET nxeon.cloud/sso/authorize?client_id=kodely&redirect_uri=<https>&state=` → logs user into Nxeon (so shared session/wallet works), mints an HMAC(AUTH_SECRET)-signed 5-min code, 302s back. Kodely backend exchanges it: `POST /api/partner/sso/token` (X-Api-Key) → {userId,email,name,balanceCents}. Stateless codes; redirect_uri allowlisted (anti open-redirect).
- **Partner API** (all `X-Api-Key`): `/api/partner/wallet` (balance), `/api/partner/domains/check` (real name.com prices — registrar IS configured/live), `/api/partner/checkout` (returns a pre-filled Nxeon wizard URL for domain|vps|hosting so purchases reuse the existing money-path + provisioner, no reimpl).
- Outbound webhook helper `notifyPartner()` (HMAC-signed) — set `kodely_webhook_url` to receive status callbacks (emit points are Phase 2).

Settings (prod): `kodely_partner_api_key` = **the X-Api-Key** (SECRET_KEY, stored plaintext but stripped from browser; rotate via admin settings/DB); `kodely_sso_redirects` = `https://kodely.me,https://www.kodely.me,https://staging.kodely.me`. **Kodely app = kodely.me** (published sites on *.kodely.site).

Verified live: 401 w/o key, 404 w/ key+bad user, real domain prices, SSO 400 on bad client/redirect, 307→login when unauthed.

**Model confirmed 2026-08-22**: users log in with their EXISTING Nxeon account (or register a NEW one) via the SSO screen — NOT silent email-match account creation. Fixed a real bug found while wiring this: `/sso/authorize`'s not-logged-in bounce built its `next=` as an ABSOLUTE url (APP_URL-prefixed); `safeNext()` (lib/safe-next.ts) only accepts a relative same-site path (open-redirect guard) and was silently discarding it, so EVERY existing-customer link attempt fell through to /dashboard and never completed the round trip back to Kodely. Also `register()` ignored `next` entirely (hardcoded /dashboard?signup=1) and AuthForms' "Create account" link dropped `next` — so a brand-new user couldn't complete the link either. All three fixed in commit 81f16c0: relative self-URL, register() now honors next via safeNext (same pattern as login()), Create-account link carries next through. Verified live: unauth /sso/authorize now bounces to /login with a relative next= that passes safeNext.

## Phase 1.5 — order attribution + notify, SHIPPED (commit f0c4ad2)
Without this, wiring a webhook would have notified Kodely about EVERY Nxeon order, not just its own — needed a way to tag which orders came from Kodely first.
- `Server.partnerSource` / `Domain.partnerSource` (nullable, additive columns — applied to prod DB).
- `components/customer/PartnerSourceCapture.tsx` (mirrors the existing `ReferralCapture.tsx` pattern): reads `?ref=kodely` on ANY `/dashboard` page into a 24h cookie (`nx_partner_ref`), so the tag survives the deploy/domain wizard's redirects without threading a query param through every step. Mounted in `app/dashboard/layout.tsx`.
- `payAndDeploy` (lib/actions.ts): tags `OrderIntent.partnerSource` from the cookie; round-trips through Stripe metadata like `extraDiskGB`/`backupTier` already did; persisted onto the `Server` row at creation (lib/order.ts `tx.server.create`).
- `purchaseDomain` (lib/actions-domains.ts): reads the cookie directly (same-request wallet debit, no Stripe race) and tags the `Domain` row.
- Notify points, gated on `partnerSource === "kodely"`, best-effort: `worker/index.ts` on VPS RUNNING transition fires `notifyPartner("vps.provisioned", {userId,serverId,hostname,ipAddress})`; `purchaseDomain` on successful registration fires `notifyPartner("domain.registered", {userId,domain,expiresAt})`.
- `PARTNER_IDS` allowlist + `partnerSourceFromCookie()` helper live in `lib/partner.ts`.

## Phase 1.6 — fixed a broken checkout URL + completed hosting attribution (commit eaae5e7)
User asked "is everything ready for kodely" — checking honestly surfaced a real bug: `/api/partner/checkout`'s "hosting" product pointed at `/dashboard/order`, which is a dumb redirect to the VPS wizard regardless of query params (read the page, confirmed). A Kodely user choosing hosting would have landed in the VPS flow. Fixed to point at the REAL entry point `/dashboard/deploy?product=hosting` (confirmed against DeployHub.tsx's actual product-param handling, which accepts vps|hosting|game|email).
Also: hosting orders had ZERO attribution/webhook wiring (VPS + domains got this in 1.5, hosting was missed). Now mirrors the same pattern on BOTH legs: `HostingAccount.partnerSource` column; `placeHostingOrder` reads the cookie once, threads into the wallet path (`placeHostingOrderCore`→`orderHostingAccountFor`, persisted on create) AND the card path (`HostOrderCheckoutIntent.partnerSource`, round-trips via Stripe metadata, read back by `placeHostingCardOrder`); `worker/hosting.ts`'s new `notifyHostingPartner()` fires `hosting.provisioned` at BOTH ACTIVE-transition points (sandbox + real), gated on `partnerSource==="kodely"`. All 3 products (domain/vps/hosting) now have matching attribution+webhook wiring.
Verified live: checkout endpoint now returns the correct URL for both hosting and vps.

**Also caught + fixed the same day:** a genuine regression from Phase 1 — `lib/google-ads.ts`/`lib/partner.ts`/`lib/riddle.ts` had `import "server-only"`, which has no valid entry point outside a Next.js bundler. The WORKER runs as plain `tsx worker/index.ts` (not bundled), so its dynamic imports of these files were throwing "Cannot find module" on every tick — confirmed in worker logs, fixed by removing the import (no pre-existing lib/*.ts file in this codebase uses it, for exactly this reason).

## Phase 2 — TODO
- **Shared hosting** provisioning for the static Kodely export — BLOCKED on the [[nxeon-security-audit-2026-08-12]] RCE + shared-hosting security review (`ENABLE_SHARED_HOSTING` still off). Kodely sites are static, so shared hosting (or a lightweight static tier) is the natural fit — this gate is worth prioritizing.
- Kodely CLIENT side: add `/api/nxeon/callback` (code→token exchange), store nxeonUserId on the Kodely user, and "Publish → Domain/Hosting/VPS" UI that hits the checkout endpoint + listens for the `vps.provisioned`/`domain.registered` webhook. Integration kit already sent to the owner (paste-in guide, adapts auth/db imports). NOTE: the Kodely code on VM 110 (/opt/kodely) is STALE per owner and Kodely actually runs on their LOCALHOST — I cannot reach it to build/test the client side myself.

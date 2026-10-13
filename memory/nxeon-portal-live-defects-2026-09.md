---
name: nxeon-portal-live-defects-2026-09
description: "Live customer-affecting defects found by the Phase 1 read-only audit on 2026-09-03, none fixed yet"
metadata: 
  node_type: memory
  type: project
  originSessionId: 1716c7ee-ae35-4cf5-b557-9059709e07c4
  modified: 2026-09-03T18:10:32.691Z
---

The Phase 1 redesign audit ([[nxeon-portal-redesign-phase1]]) surfaced correctness bugs, not design
opinions. **Nothing was changed** — Phase 1 was read-only. These are independent of the redesign and
can each be fixed on their own.

High:
- **Game customers cannot renew, auto-renew, cancel, delete, snapshot, reinstall or reach networking.**
  The game branch of `app/dashboard/servers/[id]/page.tsx` returns (~line 1008) before the standard
  `ServerTabs` render. It also strands the working world-archive backup feature, and the worker still
  emails customers telling them to download backups from a "Manage → Worlds" tab that does not exist.
- **~20 email templates have no production sender** — incl. server_suspended, server_terminated,
  password_changed, login_alert, low_balance, referral_reward. All classified CRITICAL in the notify
  policy, yet they reach the customer only as an in-app bell entry.
- **Team roles grant no authorization.** Ownership checks consult only `userId`; no loader consults
  `Membership`; `Membership.areas` is dead. Four roles are offered that confer nothing.

Medium:
- Shared hosting is fully sellable but `worker/hosting.ts` keeps the provisioner inert unless
  `ENABLE_SHARED_HOSTING=1` — an order would sit PENDING forever.
- `text-slate-500` used 694x fails AA (~4.0:1) on navy; it is baked into `.section-label`, every
  `.table-shell` header and every input placeholder. `text-slate-600` (81x) fails even AA-large.
- Two inert checkout controls: the cardholder-name input is never passed to `confirm()`, and the
  save-card checkbox renders checked AND disabled.
- `?paid=1` / `?pending=1` are written by 6 redirect sites and read by none → silent dead ends for
  paid-but-unfulfilled orders and every PayPal/Coinbase return.
- VPS add-ons copy says "you can add or remove these later" — untrue for docker and the malware
  scanner (cloud-init one-shots with no post-provision API).
- Shared hosting sends no email and no notification when an account goes ACTIVE.

Low: zero-byte `caddy.svg` is in the live `HAS_LOGO` allow-list and renders broken;
`logos/games/bedrock.png` is the Java Minecraft wordmark; a single registrar error hides three cards
on the domain page; the game Mod Store fabricates ratings/installs/screenshots/reviews from `hash(slug)`.

**How to apply:** raise these with the owner before touching them — several are on live prod, and
credential/infra changes need sign-off ([[nxeon-live-credential-rotation-policy]]).

---
name: nxeon-hosting-wizard
description: "shared-hosting needs a proper checkout wizard like VPS (spec) + the \"auto-deploy no checkout\" diagnosis"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-12T14:06:42.705Z
---

**Shared-hosting order flow needs a proper wizard + checkout (user-reported 2026-08-12).**

**Diagnosis of "clicked Create account, it auto-deployed without checkout":** NOT a mischarge. `orderHostingAccount` (lib/actions-hosting.ts:83) debits the WALLET only (no Stripe checkout path). First-month-free is HOSTING-ONLY, so a MONTHLY plan's first month = $0 (`promoCharge` $0 for a 1-month term) → $0 wallet debit passes even at $0 balance (line 144) → provisions instantly. Working-as-coded, but two real problems:
1. **No payment method captured** → month-2 renewal (worker/product-renewals.ts) has nothing to charge → dunning → suspend. Free signups silently lapse.
2. **No wizard/review/checkout** — hosting is just a domain field + "Create account", unlike VPS's full DeployWizard → payAndDeploy → Stripe checkout.

**Domain requirement:** currently HARD-REQUIRED (lib/actions-hosting.ts:94 "Enter a domain."). Should be OPTIONAL — start on a free temp `username.nxeon.cloud` subdomain, connect/register a real domain later. Removes checkout friction.

**BUILD: a HostingDeployWizard mirroring the VPS DeployWizard:**
- Plan select + term (Monthly/Annual — hosting terms only, no multi-year) with the pricing/term ladder styling.
- **Optional domain** (temp subdomain fallback; or register-in-flow).
- **One-click app installs** (WordPress etc. — reuse the existing HostingTask app-install catalog).
- **Storage-increase upsell** + **backup upsell** (like VPS extra-disk/backup add-ons; hosting equivalents — diskQuota upgrade, backup tier).
- **Review step** + **real checkout that CAPTURES a card** even when month 1 is $0 (so renewals work) — route through Stripe like payAndDeploy, or capture a payment method / require wallet top-up.
- Keep displayed===charged; first-month-free hosting-only; money-AUDIT before promote (like the billing bundle).

**Quick safe win (if not doing the full wizard):** make domain optional + add a "first month free, then $X/mo — add a payment method for renewals" step so nobody silently lapses at month 2.

**GAME-SERVER SETUP is ALSO weak (user 2026-08-12)** — the game deploy/order flow (components/customer/GameDeploy.tsx + lib/actions-gameplans.ts) needs the same wizard treatment: game select → plan → term → server settings/mods/slots → app/modpack options → review → real checkout with card capture. Same money-path discipline. Do alongside the hosting wizard.

**GAME LOGOS (in progress, feature/game-logos):** wiring a shared `GameLogo` component so real per-game logos render across marketing (game-servers, GameLandingPage, PricingExplorer tabs) + customer (GameDeploy), replacing the 🎮 emoji. Convention: owner drops official logos at `public/logos/games/<family>.svg` (families: minecraft, valheim, rust, palworld, cs2, terraria — terraria missing). Owner is sourcing the logos. Some assets already existed at public/logos/<family> but were unused.

Both wizards are MONEY-PATH builds — do fresh with full budget, careful, audited. See [[nxeon-shared-hosting]], [[nxeon-readiness-audit-2026-08-12]] (also flagged failed-provision refund + wire renewal emails), [[nxeon-resume-point]].

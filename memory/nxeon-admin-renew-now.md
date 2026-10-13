---
name: nxeon-admin-renew-now
description: "admin-only \"Renew now\" with real wallet-then-card fallback, LIVE 2026-09-25 on /admin/servers/[id]"
metadata:
  node_type: memory
  type: project
  originSessionId: ec6fa978-d80b-4147-9982-eea470598e2c
  modified: 2026-09-25T14:14:46.477Z
---

Built and shipped 2026-09-25 in response to a real gap the owner found: no admin UI existed to force a specific customer's renewal, and — audited the same day — exactly ONE renewal in all of production history had ever actually completed via the wallet→card fallback (a $2.99 hosting addon on an internal test account, 2026-09-13). Zero VPS/game-server plan renewals had ever been proven to work through that path for a real paying customer, despite [[nxeon-grandfather-pricing-fleet-tags]] and many customers having real saved cards.

**Where it lives**: `/admin/servers/[id]` → Admin actions → "Renew now" button. Shows a real wallet/card-split preview (from `renewalQuote`) before a confirm dialog, then calls `adminRenewServerNow(serverId)` (`lib/actions.ts`).

**Money mechanics**: `renewServerImmediately` (`worker/billing.ts`, exported) reuses the exact same primitives the automatic sweep (`billingSweep`/`renewDueServer`, runs every 10 min inside `nxeon-worker`) already trusts — `walletSplit`, `hasChargeableCard`, `attemptCardRenewal`, `commitRenewal` — not a third copy of the arithmetic. Deliberately NOT `renewDueServer` itself: that function no-ops for any server with `autoRenew` off, and returns nothing a UI could show. Same double-charge protection as the sweep (CAS on `expiresAt` inside `commitRenewal`, Stripe idempotency key + unique index on `WalletTransaction.stripePaymentIntentId`).

**Real verification before shipping**: 9/9 scenarios run against an isolated throwaway Postgres DB + real Stripe TEST mode, including a genuine captured PaymentIntent (`pi_3UJZeGHxcLe3GonT02rNkova`) — the first VPS/game-server-shaped proof this path actually works — plus a real decline and a concurrent-double-call race test (exactly one winner).

**Important limit discovered this session**: Claude Code's own tool permissions hard-block any script that directly executes a real-money transaction ("Real-World Transactions" classifier) — this is why the fix had to be a real admin-clickable UI button rather than something run from a script/session directly, and why verifying pslgaming's (wizzy.zelda@gmail.com) renewal specifically still needs the owner to click the button themselves.

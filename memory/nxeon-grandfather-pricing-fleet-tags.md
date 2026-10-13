---
name: nxeon-grandfather-pricing-fleet-tags
description: admin-settable grandfathered renewal price + real add-on-aware fleet pricing/lifecycle tags — LIVE in prod 2026-09-25
metadata:
  node_type: memory
  type: project
  originSessionId: ec6fa978-d80b-4147-9982-eea470598e2c
  modified: 2026-09-25T12:05:35.122Z
---

Shipped 2026-09-25 to production (`/opt/nxeon`, commit `c58a8754`). Built in response to two real customer cases the owner flagged: `terraria-i2ydef` (animeboygo2@gmail.com, informally grandfathered after a price increase, no price recorded anywhere) and `darkeden-guard-sg` (jsj8013@gmail.com, pays an extra disk-space fee the admin fleet list didn't show).

**Mechanism:** reused the existing `Server.grandfatheredRenewalCents` field (shipped 2026-09-17 as an auto-freeze-on-sale/resize mechanism) rather than adding a second "locked price" field — it was already the one override point inside `renewalCharge`. Admin sets/clears it from `/admin/servers/[id]` (`adminSetGrandfatheredPrice`/`adminClearGrandfatheredPrice` in `lib/actions.ts`), audit-logged.

**Real bug found+fixed in the same pass:** `renewNow` (manual "Renew now", `lib/actions.ts`) built a fresh object that silently dropped `grandfatheredRenewalCents` — unlike every other real caller of `renewalCharge`/`renewalQuote`, which passes the raw `Server` row through. **26 live servers** had a grandfathered rate diverging from their live plan price at the time; any of them clicking "Renew now" themselves would have been overcharged. Has its own permanent regression test now.

**Fleet list (`/admin/servers`):** price column now goes through `lib/admin-fleet.ts`'s `serverFleetPriceCents` (add-on- and override-aware) instead of a bare plan-price read. New `serverFleetTags`: Grandfathered / per-add-on tags / Renewing soon (5-day window, matches the page's existing banner) / Overdue / Deleting soon (replaces Overdue, not shown alongside — reuses `worker/billing.ts`'s real dunning/grace-period math via the new `lib/dunning-config.ts`, not reinvented).

**Verification:** typecheck clean, 16 new tests / zero regressions, full prod build, real read-only prod query confirmed `darkeden-guard-sg` computes to $27.49/mo ($24.99 grandfathered base + $2.50/25GB) matching the owner's own description exactly.

**Still open:** the owner has NOT yet said what `terraria-i2ydef`'s actual grandfathered price should be — the admin UI to set it now exists, this is just waiting on the owner to pick the number.

See [[nxeon-portal-live-defects-2026-09]] for the broader admin-panel defect list this was part of.

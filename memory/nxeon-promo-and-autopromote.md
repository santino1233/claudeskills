---
name: nxeon-promo-and-autopromote
description: "first-month-free is HOSTING-ONLY, and an unidentified auto-promoter shipped unreviewed work to prod"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-11T19:49:20.884Z
---

Two things from the 2026-08-11 board-completion push:

**1. The first-month-free promo is SHARED-HOSTING ONLY.** Owner corrected this mid-session ("$0 for vps hosting... not vps... I wanting this for shared web hosting"). A free month of a $2.99–$8.99 hosting plan is a cheap acquisition offer; a free month of a $6.49–$32.99 VPS is real exposure. Enforced in code by `lib/promo-redemption.ts` `FIRST_MONTH_FREE_SERVICES = ["HOSTING"]` + `firstMonthFreeAppliesTo(service)`, gated in all 4 order flows' `promoEnabled`. VPS/Email/Game always bill full. Marketing surfaces (PromoBar, PricingGrid, ProductPricing, /pricing hub, business-email) show the promo on hosting only. To extend to another product, add its `PromoServiceType` to that one array. See [[nxeon-marketing-design]].

**2. An auto-promoter shipped UNREVIEWED integration work to prod — and it is NOT the nxeon-improve agent.** Even with `nxeon-improve` inactive, `main` in /opt/nxeon was fast-forwarded to an unreviewed integration commit and prod was rebuilt+restarted (18:28 UTC), briefly putting first-month-free live on VPS. Reflog showed `main@{0}: merge origin/integration/promo-email: Fast-forward`. No cron/timer/git-hook does this (checked). Suspect a second Claude session or an external CI. **Before pushing any branch, assume it may auto-ship to prod.** Work on branches, validate on staging, and don't leave money-unsafe code on any branch that could be promoted. Ask the owner to identify/kill this mechanism. Related: [[nxeon-improve-agent]], [[nxeon-build-isolation]].

**Prod DB writes + prod-tree git ops are classifier-blocked for me** (psql Setting writes, `git merge` on prod main, `prisma db push`) — the OWNER runs promotes. Board-table writes via `npx tsx` (prisma) are NOT blocked.

---
name: nxeon-marketing-redesign-2026-09
description: "New marketing website overhaul (started 2026-09-27) — package location, audit files, hard constraints, identity-first plan"
metadata:
  node_type: memory
  type: project
  originSessionId: ec6fa978-d80b-4147-9982-eea470598e2c
  modified: 2026-09-27T01:50:23.114Z
---

Full overhaul of the public Nxeon marketing site using a static design package another session produced (31 finished HTML pages + Python generators + Aurora UI library). Source: board card "New Marketing Website v1" (card id cmuj55mvu0u6ihlxr1ihcpzk3), extracted to `/root/nxeon-marketing-v1/src/New Marketing Website v1/nxeon-website-handoff/`.

Audit (done in Sonnet 5 subagents, 2026-09-27) lives in `/root/nxeon-marketing-v1/audit/` — 01 new-site inventory, 02 current live marketing, 03 portal assets, 04 backend wiring gaps, 05-MASTER-AUDIT (side-by-side keep/discard/add/change).

**Hard constraints (owner):** never change the customer portal (copy/fork assets only — the newwebsitev4 self-scoped-class + forked MarketingGlobe pattern is the precedent); never deploy the new marketing site to production until it's 100% ready.

**Plan:** finalize the visual identity first (tokens, type, buttons, motion, which live/portal assets carry over), THEN design the remaining pages on the new design, then build/wire backend, staging-verify, launch gate.

Key gap facts: live site has ~117 static routes + ~750 programmatic [slug] pages, 64,714 mods, 346 blog posts — new package covers 31 pages/templates each instantiated once. Deploy CTAs must keep the `lib/deploy-intent.ts` DEPLOY_PARAM contract. Live has 4 legal pages to port; refund/cookie/DPA need owner/legal input. Only 2 real regions exist (not the 7 in new copy).

**Identity board (round 1 done 2026-09-27):** https://claude.ai/artifact/VyQrtsfAv4nQdy4Z7btn1N (picks in its db collection `picks`, snapshot in /root/nxeon-identity-board/picks-v1/). Chosen: Aurora palette + Geist type; live .btn-deploy (+rocket icon), portal .btn and spinning-rim primary; new nav + live footer (reorganised); new hero + renders; Aurora icons; new game/pricing/matrix/blog/NxLabs templates (all live templates removed). Owner used "Keep" to mean "use it" for live/portal items too. Owner notes also asked to bring Aurora icons + the new animated NX loader INTO the portal — APPROVED by owner 2026-09-27 as rare, deliberate portal exceptions (portal loader = the new site's animated NX + loading bar + an arc orbiting the NX). HARD RULE for this: marketing and portal CSS stay in SEPARATE stylesheets/scopes so neither can replace the other by accident. Aurora UI kit = the component library (not a page). Round 2 (75 more candidates) also DONE 2026-09-27 — full 124 picks snapshotted in /root/nxeon-identity-board/picks-v2/picks/. Round 2 kept: all new Compare-page pieces (departure board/boarding pass, flight rules, disclosures, table, calculator), new mega+mobile nav, new plan cards + portal plan picker, new contact form/FAQ/Aurora inputs, new maps + portal globe, new catalogue cards + portal picker/mods/services, all 9 new homepage sections, animated NX logo + static logo, portal screens as marketing visuals. Removed every live section. To design new: public server directory, 404, cookie banner, Aurora seg/chips/toasts. Final CTA = live CTA content over new homepage art. Open questions to owner: particle background (kept in r1 note, removed in r2) and two nav buttons (read as Deploy for signed-out / Open dashboard for signed-in). HARD RULE (owner, 2026-09-27): the new homepage hero stays EXACTLY as designed, including its own WebGL globe — never swap in the portal globe there (portal globe is only for region-picking sections). Owner decided 2026-09-27: KEEP the 7-regions claim as-is (their call; deploy wizard only offers 2). Particles: only on game pages. Nav: 'Deploy a server' signed-out / 'Open dashboard' signed-in. Review badges (Google/Trustpilot/HostAdvice): carry the ReviewBadges COMPONENT everywhere it appears live, but NEVER its DEMO_BADGES fallback — as of 2026-09-27 there are 0 real reviews and no review URLs, so live shows fabricated 4.9/312 etc.; badges must render nothing until real reviews exist (live fix logged as a separate task). Next: identity spec → living component library in an isolated noindex staging-only area → page design.

Related: [[nxeon-model-split-preference]], [[nxeon-marketing-design]], [[nxeon-redesign-generic-drift]]

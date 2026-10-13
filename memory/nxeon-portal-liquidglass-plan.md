---
name: nxeon-portal-liquidglass-plan
description: "Candidate portal redesign 'Liquid Glass, neon-lit' (2026-09-04) — deploy wizard collapsed 7 screens to 3, navy/violet neon; saved as a plan at /root/nxeon-portal-liquidglass-plan/, NOT approved and NOT built into the app"
metadata:
  type: project
---

A candidate direction for the Nxeon customer portal, drafted 2026-09-04 and saved at the
owner's request as a **potential plan — not approved, not implemented**. Nothing on the
running system was touched; `/opt/nxeon` was read read-only.

Canvas (9 artboards): https://claude.ai/code/artifact/dda16c03-ba99-4187-b959-ce7a4d4c0cd8
Durable copy: `/root/nxeon-portal-liquidglass-plan/` — `PLAN.md` (the full write-up,
including the open questions for the owner), `artboards/` (the nine `.dc.html` sources +
`canvas.json` — edit these and re-seed with the `design` skill), `build/` (`_kit.css`,
`_hdr.frag`, the `*.tpl` templates, generated globe/sparkline geometry).

**The proposal in one line:** collapse the deploy wizard from
`Hub -> Plan -> Location -> Install -> Add-ons -> Access -> Review -> Pay` down to
**Choose -> Set it up -> Pay**, by turning Location / hostname / SSH / disk / malware
scanning / backup retention from steps into defaults you can override.

Material: brand navy + violet pushed into neon — ink `#04050E`, violet `#7D5CFF`
(primary), cyan `#35DFF5` (value), magenta `#FF4FD0` (game), blue `#4A7DFF`. Manrope +
DM Mono, deliberately not Geist. No image assets at all — every icon, glyph, flag, the
globe and the isometric panel are hand-written SVG.

**Why:** this is the owner's own brief (liquid glass / iOS 26, buyer psychology, pay and
deploy as fast as possible, fresh assets), built on top of the two references they
supplied. It is a much further-developed take on direction "02 Liquid Glass" from
[[nxeon-direction-mockups]], now leaning navy/violet/neon rather than the mint-and-amber
first pass they rejected.

**How to apply:** do not build from a description — start from `artboards/` plus
`PLAN.md`. Phase 1's standing rules still bind: backend never changes, and Phase 2
implementation happens only in the sandbox, never the live tree (see
[[nxeon-portal-redesign-phase1]], [[nxeon-build-isolation]]). Before any of this reaches
customers, read PLAN.md's honesty ledger — chiefly that Nxeon runs ONE region (SGP1), so
the region picker marks the other seven "Soon" rather than inventing latency, and that
the add-on rates and dashboard account figures in the mockup are sample data.

Related: [[nxeon-marketing-design]], [[nxeon-brand-gradient]], [[nxeon-47-seconds-tagline]],
[[nxeon-redesign-generic-drift]], [[nxeon-portal-live-defects-2026-09]].

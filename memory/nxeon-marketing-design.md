---
name: nxeon-marketing-design
description: Hard-won constraints for Nxeon marketing/homepage design — the real theme and what the user keeps rejecting
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-02T18:08:59.190Z
---

The user rejected FIVE homepage-overhaul attempts (v2–v6 previews). Root causes, finally diagnosed:

1. **Off-theme palettes.** I invented bespoke looks (charcoal+amber, blueprint-navy, etc.). The REAL Nxeon theme is fixed in [[nxeon-platform]] `app/globals.css`: deep **navy** ground (`--color-navy-950 #060a14`), **violet brand** (`--color-brand-500 #6f47f5`, 400 `#8a70fb`), **blue/cyan accents** (`--color-accent-blue #3b82f6`, `--color-accent-cyan #22d3ee`), glass cards, violet glow. Use `grad-text` (blue→violet), `.card`, `.btn-primary`, `.eyebrow`, `hero-aura`, `tone-panel/deep/light`, `.rail`. Cyan is the in-theme "live/active" pop — NEVER amber (amber only as a semantic warning).
2. **Templated/boring layout.** Every version was the same skeleton: dark bg + a canvas particle animation + centered eyebrow → stacked sections → stat strip → product grid → pricing → CTA. That IS the "AI slop" they said they don't want. They want bolder, asymmetric, editorial composition.

**Why:** the marketing site must feel like it belongs to the actual product (the app/dashboard are navy+violet+glass), and must not look AI-generated.

**How to apply:** build marketing pages ON the existing brand tokens and component primitives, not a new palette. Live homepage is `app/page.tsx`. Honesty guardrails: "24/7" = monitoring not human support; keep stats honest (NEVER copy the rocket prototype's invented "50K servers / 12 locations"); AI-build shows the approve gate; migration shows handled-vs-flagged.

**2026-08-02 VIDEO BRIEF (board "Website Overhaul" card, 4:51 narrated screen-rec — the authoritative direction).** The user compared THREE sources and wants them combined into a NEW preview version (built `/v8`): (1) a rocket.new AI prototype "Deploy anywhere. Instantly." (dark violet, terminal deploy card, stat bar, compatible-stack, product tabs, 3-tier pricing, "47s away" CTA), (2) the current Nxeon site, (3) `/v5`. LIKES/keep: nav hover-underline; the glowing background dots (AmbientField); font color gradients (grad-text); compatible-stack as an auto-sliding carousel (LogoMarquee); products with per-product colors; the pricing chart; **"Your server is 47 seconds away."** (his favourite — speed is the #1 buying trigger); the migration animation (MigrationScreens — "explains it perfectly"); the Matrix multi-console; the screen animations generally + **show MORE screens** (business email=MailInbox, domains=DnsManager, AI builder=ClaudeChat/ClaudeBuilder, dashboards); existing dropdown nav + icons. DISLIKES/fix: rocket's buttons (keep Nxeon btn-primary); the "Built for performance" cards (messy/dead-space — redo cleaner); the fake globe (looked bad — use a real map = NetworkMap, NOT a globe). Card also wants: unique (not AI slop), buying-psychology focus, **5-star reviews** on the page, preview before replacing live. Reusable screen components live in `components/marketing/showcase/` (MailInbox, DnsManager, ClaudeChat, MigrationScreens, ServerDashboard, GameControlPanel, VolumesPanel) + DeployCard (hero terminal), MatrixTerminal, NetworkMap. To read board video attachments: ffmpeg (installed) contact sheets + faster-whisper (installed, `base.en`) for transcript. Earlier previews `/v6` (Command Deck) and `/v7` (globe+configurator) were superseded by this brief.

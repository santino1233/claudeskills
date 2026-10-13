---
name: nxeon-project
description: "Nxeon is Nick's own game-server hosting platform/company, separate from the Kodely YouTube series -- brand kit and promo-video pipeline location"
metadata:
  node_type: memory
  type: project
  originSessionId: df20b19b-4205-4221-86d3-7d64f9d542a8
  modified: 2026-09-26T13:15:37.566Z
---

Nxeon (nxeon.cloud) is Nick's own product: a game-server hosting platform (deploy wizard, game catalogue, region/ping picker, one-click mod installs, dashboard/console). This is a **separate venture from Kodely** (the AI website builder featured in the "Vibe Coding" YouTube series) -- don't conflate the two. Nxeon was previously referenced only in passing in the Kodely video (as something whose admin URL had to be privacy-blurred), but is a real product with its own content-creator/affiliate program.
**Why:** two different local video projects now exist under the same working directory; mixing up brand/style between them would be a visible error (Nxeon's own promo materials must use Nxeon's brand, not the Vibe Coding series' retrowave look).

Nxeon brand kit (confirmed by Nick directly, from the live homepage): background `#05060d`, brand purple gradient `#3b82f6` (blue) -> `#8a70fb` (light purple) -> `#6f47f5` (dark purple), accent cyan `#22d3ee`, mint/success `#11c88e`, white. Fonts: **Geist** (display/body) and **Geist Mono**, both free on Google Fonts (site loads them via `next/font/google`). A magenta `#e5197e` shows up in some UI contexts but Nick flagged it as an unconfirmed placeholder, not finalized brand -- leave it out of anything official until he confirms it.
**How to apply:** use this palette/type for any Nxeon-branded asset (promo videos, graphics, decks) without re-asking, but don't use the magenta unless he confirms it's now official.

Promotional video work for Nxeon itself (not the Vibe Coding series) lives in `nxeon-promo/` at the project root, with its own `edit/` pipeline mirroring the Kodely project's structure (scripts/, animations/, graphics/, a self-hosted `edit/remotion/` project). First deliverable: a 30s-cap 16:9 promo for Nxeon's content-creator program, cut from a raw screen recording of the dashboard/deploy flow, combining video-use-style ffmpeg cutting, HyperFrames text overlays, and Remotion-rendered full-frame graphic cards (game/mod poster grids, discount card, support card, outro CTA).
**Why:** explicit ask to build this here rather than handing off to another session, and to use HyperFrames + Remotion + video-use + baz.studio together.
**How to apply:** when Nick asks for more Nxeon marketing/promo content, start from `nxeon-promo/edit/` rather than the Kodely template, and reuse the Remotion scene files under `nxeon-promo/edit/remotion/src/scenes/` rather than rebuilding them.

See also [[video_editing_pipeline_setup]] (the Kodely/Vibe-Coding pipeline -- distinct project) and [[video_editing_style_prefs]] (style preferences that still apply across both).

---
name: nxeon-game-servers-batch
description: "2026-08-23 batch — game wizard auto-advance fix, capitalization fix (13/19 games were unlabeled slugs), 31 new hero/poster images, new per-game hero backdrop, 10 \"move from X\" migration pages"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-23T08:49:58.695Z
---

Shipped commit 0eda47b, live + staging synced.

**Game deploy wizard**: `pickGame()` in components/customer/GameDeployWizard.tsx now auto-advances to the Plan step on click (was: just highlighted the card, needed a separate Next click).

**Capitalization bug (real, found while investigating)**: app/dashboard/deploy/page.tsx and app/dashboard/games/page.tsx each kept their OWN copy-pasted `GAME_META` with only 6/19 games (minecraft/valheim/rust/palworld/cs2/terraria) — the other 13 (ark, satisfactory, projectzomboid, sdtd, vrising, enshrouded, factorio, gmod, conan, unturned, theforest, sonsoftheforest, bedrock) silently fell back to their raw lowercase slug with zero formatting. The marketing /game-servers page's own GAME_META was already fully correct — just never reused. Fix: added `GAME_DISPLAY` (all 19, correct names) to the already-plain lib/games.ts (documented safe for server components); both broken pages now import it instead of their own list. Left components/marketing/GameLogo.tsx's `GAME_VISUAL` (client-only, has extra brand-gradient colors) untouched — separate, still-correct duplicate, lower priority to consolidate.

**Game art**: owner uploaded games.zip (31 files: hero+poster pairs for most, hero-only for minecraft/valheim/rust/palworld/cs2/terraria) → extracted into public/games/art/<slug>_hero|poster.jpg. Several source photos were 2-2.8MB — installed imagemagick (apt) and resized+recompressed everything (hero max 1920×1080, poster max 800×1200, q82) → all under 550KB. Converted the 2 PNG sources (bedrock poster, terraria hero) to JPEG for pipeline consistency. New assets that didn't exist before: minecraft_hero.jpg, bedrock_hero.jpg, bedrock_poster.jpg (Bedrock had zero dedicated art). `ART_SLUG` in GameCoverCarousel.tsx gained bedrock; minecraft deliberately NOT added to the poster map (no poster provided, already resolves via the existing /logos/games/covers/minecraft.jpg fallback).

**NEW: HeroBackdrop** (components/marketing/showcase/GameCoverCarousel.tsx) — every game already had a `_hero.jpg` on disk but NOTHING in the app rendered them until now. Self-contained backdrop inside the carousel: swaps to the currently-CENTERED game's hero art (blurred, dimmed, `HERO_SLUG` map), fades in on selection change via a plain opacity transition (no new global CSS). Lives on /game-servers.

**10 new "move from X" migration pages** (different search intent than the existing vps-vs-X comparison family — migration-story-first, not table-first): app/(marketing)/migrate-from-{a2hosting,bluehost,cloudways,digitalocean,godaddy,hostgator,hostinger,ionos,kamatera,namecheap}/page.tsx, all thin data files into new components/marketing/MigrateFromPageLayout.tsx. Leads with the REAL 4-step SSH-scan-and-move mechanism (from app/(marketing)/migrate/page.tsx — root SSH + local-socket DB dump, so no source DB password needed, verified against worker/migrate-real.ts's own doc comments), honest per-provider "why people leave" bullets (structural/category claims only — shared-hosting heritage, upsell tiers, panel-vs-root-access — nothing fabricated about a named competitor), live DB-fed Nxeon pricing (never hardcoded). Each vps-vs-X page got a small cross-link to its migrate-from-X sibling. All 10 added to app/sitemap.ts.

Built via one background Agent (migration pages, ~500K tokens) running in parallel with direct work (wizard/capitalization/images) — verified the agent's output myself before shipping (read the actual diffs, cross-checked all 10 provider names/slugs for copy-paste drift, verified the FAQ's specific DB-dump technical claim against worker/migrate-real.ts's real code, ran a full `npm run build` in the worktree before merging).

**Follow-up (same day, commit 2753c64): posters in the wizard + hero on the SEO pages.** User first said "no hero image here" (was looking at /minecraft-server-hosting, a THIRD surface — the 20 `/<game>-server-hosting` SEO landing pages, distinct from both the wizard and the /game-servers carousel), then walked back to "don't need posters/hero either," then reversed again to "want both." Final, shipped:
- **lib/games.ts** gained `GAME_ART_SLUG` (poster+hero slug per family) — consolidated OUT of GameCoverCarousel.tsx's local copy, the single shared source for all 3 consumers now (was about to repeat the exact capitalization-bug drift pattern by adding a 2nd/3rd local copy).
- **components/customer/GameCoverTile.tsx** (deploy wizard's game-picker cards, `/dashboard/deploy?product=game`): now checks `/games/art/<slug>_poster.jpg` FIRST — it never checked the bundled poster art before, only an owner cover-drop-in convention that was mostly empty (hence the plain wordmark-on-gradient tiles the user saw).
- **components/marketing/GameHero.tsx** (shared hero on all 20 `/<game>-server-hosting` pages, e.g. /minecraft-server-hosting, /rust-server-hosting): real per-game hero photo added as a dimmed/blurred background layer behind the existing themed particle-canvas animation (kept the particles — additive, not a replacement). Verified all 18 real game pages' `family` prop matches `GameFamily` keys exactly.

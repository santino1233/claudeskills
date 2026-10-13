---
name: nxeon-brand-asset-library
description: "the owner's own premium PNG art (rank badges, N mark, server stack, globes, light ribbon) is in /opt/nxeon/board-uploads — find it by alpha-transparency scan, don't scrape stock"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 2aa2dcca-a502-4055-9d89-9bae0c754838
  modified: 2026-09-06T13:16:01.191Z
---

When Nxeon design work needs premium imagery, look in `/opt/nxeon/board-uploads/board/*/`
BEFORE scraping stock. The owner uploads brand art there and it is already licensed
to them, on-palette, and transparent — strictly better than anything free stock
gives, and it needs no "replace before production" caveat.

The uploads are mostly screenshots, so find the art by transparency: PNGs in
RGBA mode whose alpha histogram is >18% near-zero are cut-outs, not screenshots.
That one filter found the whole set in a single pass (~18 hits out of thousands).

What is in there (2026-09-06): the glowing N mark, an isometric neon server
stack, a neon database, two globes (full sphere + Earth's limb with arcs), the
brand light-ribbon wave, a gamepad, a 5-up service-icon strip, a 7-badge rank
pack (Bronze->Apex), and grids of UI/app-logo marks. Extracted into
`/opt/nxeon-v2/public/nx/art/` and `public/nx/ranks/` with a README recording
provenance; `tools/badges.py` re-slices the rank pack.

**Slicing an icon sheet, both mistakes I made:** columns are NOT evenly spaced
(the badges widen Bronze->Apex) — detect them from alpha column-sums. And a
square crop centred on a wide badge reaches down into its label pill — crop
tight to the body first, then pad to square.

For backdrop plates where no owner asset fits, NASA image releases are public
domain (17 U.S.C. §105) and safe for production; gradient-map their luminance
onto the Nexion ramp to fix the palette (real auroras are green, nebulae are
orange). Recipe in `/opt/nxeon-v2/tools/plates.py`. Unsplash comps under
`public/nx/placeholder/` are NOT cleared — those still need replacing.

Related: [[nxeon-v2-design-fork]], [[nxeon-project-board]], [[nxeon-marketing-design]].

**2026-10-07 Bare Metal tier renders (owner-supplied):** 1-, 3- and 5-unit NX server stacks = the size hierarchy for bare metal (small build → 1 unit, mid → 3, large → 5). Sliced onto ONE shared 711px canvas, bottom-aligned, so equal display boxes keep their true relative scale: /root/agent-notes/bm-concepts/assets/tier-{1,2,3}.webp (+ owner-tiers-original.webp); also in the design worktree at public/nx/art/bm/. Not in /opt/nxeon yet.

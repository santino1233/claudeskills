# Cyrus v4 — matching the owner's concept (2026-10-07)

Concept: `owner-concept.png` (1774x887). Owner rejected v3 (graphite/lime): "not in sync with Nxeon at all".
v4 rebuilds the look to the concept while keeping every real feature.

Harness: throwaway DB `nxeon_agt_cyrus` + mock build service, `next dev -p 3149`, all inside one
`flock /root/.nxeon-build.lock` session (`session.sh`, holds dev + mock, killed by PID/PGID on `.stop`).
`node shot.mjs <name> <path>` with VIEWS=concept (1774x887, the concept's own size, sandbox banner
hidden), desktop 1440, wide 1920, mobile 390. Side-by-sides: `python3 compare.py ours.png compare/<x>.png`.

## Build (before round 1)
- Shell: `/dashboard/cyrus` is immersive (the portal rail/header/phone tabs step aside; Cyrus draws
  the concept's Nxeon sidebar + top bar itself, links go to the real portal pages).
- Web engine rewritten (`web/tree.ts` + pure `web/tree-layout.ts`): Cyrus core -> game -> category
  -> mod; canvas for space/aurora/threads/beads/travelling light, DOM for nodes (real buttons).
- Registry games (Minecraft live; ARK, The Isle, Palworld, Rust, Valheim soon), deterministic
  category classifier (`lib/cyrus/categories.ts`), templates + "New … mod" chips fill empty branches.
- Inspector: Share / more / Deploy Mod, tabs Code / Explain / Versions / Files / Notes, file switcher,
  mod card (chips, description or live build stages, Open Project / Download / NxLabs (soon)),
  Related Files.
- Composer: Chat / Generate / Debug / Refactor / Docs (all real builds), attach, screenshot
  (getDisplayMedia), voice, Katara / Saka / Yakko, send.
- Icon set: Lucide-geometry line icons with neon gradient strokes + glow, original game emblems,
  isometric mod cubes, Nxeon X as the Cyrus mark.

## Round 1 (r1/, compare/r1-home.png) — first build vs the concept
Close in structure on the first pass (sidebar, top bar, core, games, categories, inspector, composer).
Differences -> fixes:
- Mod pills too narrow, names truncated ("Lucky mob..", "Simple Econo..") -> width estimate raised and
  every column uses one width (the concept's columns are even); pills 26 px tall, 32 px rows.
- Threads thinner and dimmer than the concept's neon -> wider glow pass, brighter core line.
- A huge empty rectangle at the bottom: the v3 web-control rule kept `right:18px` while v4 set
  `left`, so the box stretched across the stage -> fixed.
- Sidebar: "Palworld Mods" wrapped because of a "Soon" tag; the concept has none -> soon games are
  dimmed with a tooltip instead. Mod-card actions wrapped -> one row like the concept.

## Round 2 (r2/, compare/r2-home.png, r2-core-zoom.png)
- Concept threads wander in S-curves with many bright beads; ours were near-straight with 2-3 beads
  -> S-bend on core->game and game->category threads, one bead per ~40 px (2-7), brighter beads.
- Coming-soon branches were dimmed to 42%, the concept draws them at full strength -> 82%.
- Our canvas had a violet wash in the middle; the concept is near-black around the core with the
  nebula at the edges -> centre blob and core pool cut, ground darkened.
- Emblems sat small in their discs, the concept's fill the disc -> discs 76-78 px, emblem 1.5x,
  brighter double-glow ring; leaves 34 px with coloured icons; core ring 4 px with a double bloom.

## Round 3 (r3/) — light, live build, phone
- Crash: bead generator read `arr.length` from Array.from's map callback (undefined) -> fixed.
- Hydration warning: node coordinates (Math.cos on server vs client) and useId gradient ids
  differed -> coordinates rounded, emblem gradient ids are per game (identical defs are harmless).
- Light: white Nxeon lockup vanished on the white sidebar -> inverted+hue-rotated in light only;
  the active nav item's white text on a pale tint failed contrast -> dark violet text.
- Live build: stage track, "Weaving the code", elapsed, last events and the streaming file with the
  "Cyrus is writing" tag all read well; Deploy Mod disabled until ready.
- Phone: the web scaled to 0.45 (unreadable) -> phones keep >= 0.62 and pan sideways (touch pan-x on
  the canvas, page scroll vertical); top bar overflowed -> compact.

## Round 4 (r4/) — every tab and overlay
- Explain, Versions (map + list + compare), Files (folders relative to the plugin package), search
  palette, model picker, Generate mode with version chip and estimate: all working.
- Phone: composer note overlapped the code behind the sticky composer -> fade backdrop; zoom
  controls moved to the right edge.
- Search: typing right after Ctrl K was lost -> autofocus on mount.

## Round 5 (r5/) — 1440 / 1920 / concept size
- At 1440 the 400 px inspector clipped the mod card (title "Simple...", NxLabs button cut) -> chips
  wrap under the title, actions wrap in a narrow inspector (container query).
- Zoom controls sat under the composer at the bottom-left -> top-left under the top bar.
- Failure verdict inside the mod card lost its styles with the v2 caption -> restyled (alert panel,
  Try again / Edit and retry). Polish: nodes and threads grow outward on load (core -> games ->
  categories -> mods, opacity/blur only; static under reduced motion).

Best set: `best/` (1-4 are concept|ours pairs at the concept's size).

## v4b — owner feedback: keep the real portal chrome, much more vibrant (r6-r12)
- Chrome: reverted the Shell.tsx/globals.css immersive switch; the real portal sidebar and top bar
  are back and Cyrus fills the content area. Cyrus's copy of the sidebar/top bar is gone; Projects +
  Cyrus Pro moved INTO Cyrus as a top-left switcher (Minecraft Mods ▾ → per-game projects, Custom
  Project, Cyrus Pro card) with Find (P) and New (N) buttons. Cyrus no longer binds Ctrl K (the
  portal's palette owns it).
- Eyedropped the concept: branches #3ce4dd teal, #cd4aff / #e080ff magenta-violet, #b81afa violet,
  #2ed8ec cyan, core ring #0770fe electric blue -> #571af9 violet, ARK #143beb, The Isle #0c73fd;
  ground #031231 / #030833 navy (blue, not violet). Category and game hues re-set to these.
- r6 (compare/r6-core.png): additive bloom (18 px halo, 8 px glow, 3.4 px body, 1.8 px line, white
  core) — vibrant but too thick, and our ground was violet-washed (#27234d near the core vs the
  concept's #100d3d / #020820).
- r7-r8: thinner, crisper strokes; nebula pushed to the corners, centre blob and per-node halos cut;
  ground #020719; core ring 3 px with a white inner rim and a violet/blue double bloom.
- r9-r10: beads were invisible (2 px white core) -> one bead per ~32 px with a solid white centre and
  a coloured halo; travelling light 18 px.
- r11: faint plotting grid behind the web (the concept's graph-paper depth), stronger core bloom.
- r12: inside the portal frame the web shrank -> the upper-left mod column sits beside its category
  instead of above it (shorter web, bigger scale); mod columns start clear of the category label
  ("Gameplay" was overlapped); web controls moved to the stage's top-right.
Best set for this pass: `best-v4b/`.

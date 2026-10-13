---
name: nxeon-game-servers-mobile-fixes
description: "2026-08-23 — fixed mobile carousel completely invisible (CSS blowout bug), softened desktop hero backdrop, added mobile footer accordion. All 3 verified with Playwright against real builds, not guessed."
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-23T13:36:29.873Z
---

Shipped commit 3836ccc, live + staging synced. Used a headless-browser (Playwright, already in node_modules) to get REAL evidence instead of guessing from screenshots — this mattered: the user's "duplicate logo in the footer" turned out to be a Playwright element-screenshot stitching artifact (sticky header re-pinning during scroll-and-stitch capture), not a real bug — verified via direct DOM query (exactly 1 `<footer>`, 1 real `logo.png` image on the whole page) before wasting time chasing it.

**Mobile carousel was completely blank (real bug, root-caused precisely):** the carousel's own viewport had `clientWidth=4256px` on a 390px mobile screen — the sum of all 19 cards' natural widths. Classic flex/grid `min-width:auto` blowout: a grid item with no explicit min-width grows to fit its content instead of respecting `overflow-hidden`. The carousel's position MATH (translateX etc.) was already correct — it was centering against a phantom 4256px box instead of the real 390px one, pushing every card thousands of pixels off-screen. Fix: `min-w-0` on the grid item wrapper (app/(marketing)/game-servers/page.tsx) AND on GameCoverCarousel's own outer wrapper (defense in depth — it's reused elsewhere). This also fixed a secondary symptom: the H1 text was overflowing horizontally on mobile too — same root cause pulling the whole grid wider than viewport.

**Desktop "looks embedded on top of the page":** the HeroBackdrop added last session (see [[nxeon-game-servers-batch]]) had `overflow-hidden rounded-[28px]` — a hard-edged box, exactly what reads as a floating panel. Replaced with a `mask-image: radial-gradient(...)` that fades the photo to nothing well before any edge (no boundary for the eye), bled beyond the carousel's own box via negative insets so it feathers into the surrounding hero as ambient atmosphere instead of a background-for-the-widget.

**Mobile footer "needs fixing":** not broken rendering — ~40 links across 6 categories rendered as one uninterrupted wall of text on mobile, no hierarchy. Desktop grid (sm+) completely unchanged; mobile now gets the same 6 categories as native `<details>` accordions, collapsed by default. Zero JS (native HTML disclosure), can't hydration-mismatch.

**Process note:** built locally (`npm run build` + `npm start` on a scratch port in the worktree, never the live prod tree), then used Playwright to verify all 3 fixes with real DOM measurements + screenshots (collapsed/expanded footer states, carousel clientWidth before/after, desktop backdrop screenshot) BEFORE merging/deploying — caught that my first fix attempt's numbers were real, not assumed. Same Playwright check re-run against the LIVE site post-deploy to confirm (358px live, matching local).

See [[nxeon-game-servers-batch]] for the hero/poster art + capitalization work this builds on.

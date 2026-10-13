---
name: nexion-ui-sandbox
description: The coded Nexion sandbox at /opt/nexion-ui — where it runs, its hidden URL, and the measure-don't-eyeball rule that keeps it matching the reference screens
metadata:
  type: project
---

The Nexion design brought into working code, isolated from the running platform.

- Code: `/opt/nexion-ui` (Next.js 15 / React 19 / Tailwind 4), systemd unit
  `nexion-ui-web` on **port 3020**
- Hidden public URL: `https://nexion.q4w8zt3ky6vn2sm.nxeon.cloud`
  (nginx site `nexion-ui`, `X-Robots-Tag: noindex`, robots deny)
- Screenshot harness: `node .shots/shot.mjs <url> <out> [w] [h]`, `FULL=0` for
  viewport-only. `.shots/measure.mjs` reads element widths out of the live DOM.
  Both import playwright by absolute path from `/opt/nxeon/node_modules`.
- `/opt/nxeon-sandbox` belongs to a DIFFERENT session — stay out of it.

**The owner's constraint:** the sandbox takes the Nxeon codebase only for
context on placements and functions. No original Nxeon styling or assets.

**Measure the reference, never eyeball it.** Every time I judged a value by
looking, I was off by multiples and the owner had to correct it:

- Card bodies: I made them ~5x too light. Reference is +6 blue over the ground.
- Corner radius: I used 17-20px; reference measures 8-9px.
- Density: I assumed "smaller cards, tighter padding". Reference is
  content-rich cards on a ~4px gutter — packed close, not shrunk.
- Backdrops: my aurora ran 4-6x too bright. Sampled across ref-02's hero band
  the reference sits between `rgb(3,7,18)` and `rgb(11,22,76)` — a glow, not a
  wash. `magick ref.png -format "%[pixel:p{X,Y}]" info:` settles these in
  seconds; do that before changing a single value.

**Structural things the reference does that are easy to miss:**
- On `/deploy` the nav sidebar is REPLACED by the wizard steps + promo card, so
  the game grid gets the whole column and runs six across. Step state therefore
  lives in `components/wizard.tsx` (context above both Shell and the page).
- Backdrops are per route: `AuroraBg` everywhere, `GlobeBg` on `/deploy`. Two
  aurora layers stacked (canvas + a static SVG in the hero) read as a wash —
  there must only ever be one.
- A `fixed` backdrop at `-z-10` sits BEHIND the body background and vanishes.
  Backdrop `z-0`, content `z-10`, sidebar `z-20`, topbar `z-30`.
- Icons come from a sprite sheet, so `text-*` colour classes do nothing. The
  flame mark is baked crimson; the reference's is blue —
  `filter: hue-rotate(240deg)` is the only lever.

**The accent palette is deliberately OFF full saturation (2026-09-05).** The
owner asked for the neon toned down system-wide. Every accent token was pulled
in ~14-24 points of saturation with the hue held exact — cyan `#00d9ff`→`#14c5e4`,
blue `#1f7bff`→`#2f7eef`, violet `#9333ff`→`#8c3ae9`, magenta `#f21cff`→`#d623e1`,
mint `#00e39a`→`#11c88e`, amber `#ffb020`→`#efa828`, rose `#ff3b6b`→`#ef426c`.
Coloured halos were cut roughly 40-55% and the triple-halo on `.card-on` reduced
to one. Do NOT "restore" these to pure neon.

Lesson: reducing the glow shadows alone moved the frame by under 1% — the page
is ~90% near-black, so halos are a small pixel share. The lever that actually
changed how loud it reads was ACCENT SATURATION. Measure it the right way:
mean saturation over only the coloured pixels (S>25%, L>12%), which went
70.4% → 65.9% with 10.6% fewer pixels reading as saturated at all.

**Two different globes, do not confuse them.**
- `public/globe-arc.png` — the flat lit-limb arc, used ONLY as the page backdrop
  in `GlobeBg`. Alpha feathered to zero on all sides; never re-cut it with
  `-transparent white`, which punches a hole through the flare's white core.
- `components/RegionGlobe.tsx` + `public/globe-geo.json` — the region selector's
  sphere. The owner rejected the old WebGL one from the design canvas as neon
  clipart, so this is a from-scratch Canvas 2D orthographic globe. Armed only
  when the region step is reached (every deck slide stays mounted).

**How the globe geometry works (2026-09-05) — the traps, in order:**
1. `isles` in the canvas source `_g3d.json` is a POINT LIST of specks, not
   polylines. Drawing it as rings produces a mesh of chords across the sphere.
   That one mistake caused every artifact I chased for an hour.
2. A land ring crossing the horizon cannot be drawn by breaking the path
   (fill() closes each visible run into triangular wedges) nor by clamping
   hidden points to the rim (chords across the face). Correct closure along the
   limb is a nest of winding cases. SOLUTION: pre-cut the land into 30° tiles at
   build time so no polygon straddles far enough to matter, then clamp. The
   coastline is a SEPARATE stroke pass, simply broken at the horizon.
3. Precompute each point's unit vector at load, so a frame is multiply-adds with
   no trigonometry — that is what makes ~15k points at 30fps free.
4. The canvas element must be much larger than the disc (R = size * 0.29) or the
   additive bloom is clipped and the bounding box shows as a hard rectangle.
   A `destination-out` radial at the edge guarantees it.
5. Colour goes on the LIMB and the NETWORK (additive `lighter`), not the face.
   Blended normally over near-black navy, cyan and magenta just grey out.

**Liquid glass card system (2026-09-05).** `.lgc` / `.lgc-in` / `.lgp` /
`.lgchip` / `.lgcta` / `.lgeyebrow` in globals.css, built to the owner's concept
render. Lit gradient rim (cyan→blue→violet→magenta) with an outer bloom, a
second hairline 4px inside it, artwork filling the frame, and a frosted sheet
over the lower half with a grab handle on its top edge.

The load-bearing detail: `backdrop-filter` only blurs what is BEHIND an element,
and behind this card is flat #000a1c. The artwork must live INSIDE the card with
the sheet floating over it, or the glass blurs nothing. Each slide carries a
`tint` sampled from its own art driving the eyebrow colour and a radial wash, so
the sheet reads as lit by the picture. `components/PromoCarousel.tsx` rotates six
of them on the dashboard rail; art in `public/promo/*.webp`.

**Portal rebuild phases (2026-09-05).** A full inventory of the live portal is
in the session; the headline findings that drive the redesign:
- `app/dashboard/servers/[id]/page.tsx` is 1376 lines and is SECRETLY TWO PAGES —
  `if (isGameServer) return <GameServerPanel/>` at line 1015. VPS and game share
  a route but render different shells, so a game server has no Metrics or
  Networking tab and a VPS has no Players tab, by branch not by design.
- There are SIX copy-pasted tab implementations, all using `history.replaceState`
  instead of routing, so browser-back never moves between tabs.
- 58 routes, 24 nav entries, 17 orphans (`/dashboard/nxcloud` has zero inbound
  links anywhere). Tools exist twice (32 files), invoices twice, game servers in
  two lists, Free MC in two places.
- Billing is a 944-line single scroll whose own comment claims invoices are a tab
  there; they never were.

The sandbox answer: ONE detail shell (`components/ServerShell.tsx` +
`lib/server-nav.ts`), tabs as REAL routes under `app/servers/[id]/*`, and the
product type choosing the row set. Phases: 1 compute (done), 2 game+hosting
(done), 3 billing (done), 4 network/identity, 5 support/account, 6 Matrix.

**Real assets in `public/`** (knocked out of the board attachments with
`magick … -fuzz 8% -transparent white`): `globe-arc.png`, `controller.png`, and
18 game covers under `games/<slug>.webp`. The covers decide the catalogue —
`GAMES` in `lib/fixtures.ts` was rewritten to the 18 titles that actually have
art (dropping FiveM, TF2, DayZ, SCUM).

See [[nexion-design-canvas]], [[nxeon-build-isolation]],
[[nxeon-pkill-nextstart-incident]], [[nxeon-redesign-generic-drift]].

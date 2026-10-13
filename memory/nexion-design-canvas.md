---
name: nexion-design-canvas
description: The Nexion visual system canvas for the Nxeon portal — artifact URL, working dir, build scripts, and the rules that keep it from breaking
metadata:
  type: project
---

From-scratch recreation of the **Nexion** visual system for the Nxeon customer
portal, built as a Claude Design canvas (contract pin `0.1.31`).

- Artifact: https://claude.ai/code/artifact/42dfe22c-a7e3-4464-9f62-8cf58aeb7914
- Working files: `<session scratchpad>/nx/` — **the scratchpad gets wiped between
  sessions.** Recover with the design skill's helper:
  `Artifact action:"read"` the URL (it saves the full page to a local file), then
  `node "<design skill dir>/seed-canvas.mjs" --extract <that file> --to <fresh dir>`.
  That returns every artboard, both sprites and canvas.json — but NOT the Python
  builders, which have to be rewritten. The built `.dc.html` files carry all the
  inlined JS (globe3d, preloader, loaders, aurora), so animation work can be done
  by editing the artboard directly.
- References: `scratchpad/nexion-refs/ref-01..21.jpg`; board attachments under
  `/opt/nxeon/board-uploads/board/<cardid>/`

Builders: `b16.py` (deploy wizard), `b_dash.py`, `b_srv.py`, `b_pages.py`,
`b_sheets.py` (Foundation + Icons), `b_states.py`, `b_preloader.py`, `b_lab.py`.
Libraries: `_nx.css` (the ONLY place shared CSS belongs), `_ui.py`, `_icons.py`,
`_shell.py` / `_shell16.py`. Animations: `aurora.js` (live), `aurora2.js`
(backup, AuroraLab), `globe3d.js` (WebGL), `preloader.js`.

**Standing constraints from the owner:** never touch the running system at
`/opt/nxeon`; do not recycle any existing Nxeon asset — everything is drawn
fresh; be candid about what the design does and does not yet cover.

**Rules learned the hard way — apply before every publish:**
- Shared CSS goes in `_nx.css`, never a page-local block. A page-local copy is
  how the icon sprite silently vanished from two artboards.
- `preview.mjs` must run each artboard's OWN script and call its real
  `componentDidMount`. When it re-implemented canvas mounting itself, a globe
  that only ever worked in the harness shipped broken twice.
- Run `diag2.mjs` (page errors + canvas paint + overflow) on every artboard
  before publishing, and sync `canvas.json` sizes from each file's `$preview`.
- Any `%%` surviving into a built `.dc.html` is a double-escape bug; `_depct()`
  wraps every write in `b16.py`.

See [[nxeon-platform]], [[nxeon-marketing-design]], [[nxeon-brand-gradient]],
[[nxeon-redesign-generic-drift]].

**Owner's globe notes (2026-09-04):** wanted the city-to-city network routes with
travelling pulse points, and the sphere reading round rather than flat. Fixed by
keying the cyan/magenta sweep to the LIMB only (it was washing magenta across half
the continents), adding a key light for roundness, lowering the arc lift so routes
cross the face, and giving each route a steady lit line with a packet running
along it instead of fading the whole arc in and out.

**Loaders:** the owner prefers the sleek single-mark loaders (Loaders artboard,
nine variants on the N — assemble/spin/collapse/sweep/scatter/draw/trail/flip/pulse)
over the elaborate ring-and-particle Preloader, which is kept for comparison.

**Scope as of 2026-09-04: 52 artboards**, laid out in labelled rows — deploy
wizard (7), system sheets (6), core app (10), hosting panel (8), domains & mail
(6), money path (5), account (6), auth (4). The owner asked for all four
remaining batches in one go and they are all in.

**Recovered tooling** (the Python builders were lost with the scratchpad):
`_shell.py` lifts the helmet CSS, sidebar, topbar and logic class straight out of
`Dashboard.dc.html`; `_ui.py`'s two sprite maps (129 icons, 65 app marks) were
recovered by parsing the Icons artboard, which renders every mark beside its
label. Never redraw this chrome from memory — extract it.

**`collide.py` runs before every build.** A page-local CSS class that also exists
in the base sheet does not error, it silently loses the cascade: `.caret` became
a blinking terminal cursor, `.trow` inherited a 56px min-height that squashed a
table rail, `.term` and `.danger` likewise. Related trap: a rule like
`.dbsel span { flex: 1 }` also matches the sprite `<span>` and stretches a 15px
icon across five cells of the sheet — scope those to a class.

**Premium variants (2026-09-04, 56 artboards).** The owner said the design did not
feel as premium as the reference screens, naming the cards. A pixel comparison
against the 21 originals — still recoverable from
`/opt/nxeon/board-uploads/board/cmtmlv9k20p0nhl777grhs52y/` (21 PNGs, 1536x1024) —
found I had it BACKWARDS:

- Reference card bodies are only **+6 blue over the page ground**, FLAT, near-black;
  the **rim is the brightest thing on the card**. My cards were raised mid-navy
  slabs about 5x too light, which is what flattened every page.
- Rims must be **zero-red blue** (`#002049`, `#00173b`, `#001a3e`); mine were
  `rgba(72,148,255,…)` — periwinkle, with red in it.
- Corner radius: reference measures ~8-9px. Mine were 17-20px, roughly 2x.
- Nested surfaces step **down** toward the page, never up.
- The light source belongs on the page ground, behind the cards — that is what
  justifies a lit rim.
- Never put a gradient inside a numeral; numbers go in the proportional sans.
- Hero bands are ~half artwork, bleeding off the top-right under a mask.

New modules: `_iso.py` (isometric SVG hero assets — server stack, wire globe,
shield, envelope, db stack, network plane, each with gradient faces, neon edge
light, floor glow and a fading reflection) and `_prem.py` (the premium card/hero
recipe). Variants: ServersPremium, PlansPremium, DashboardPremium, RegionPremium.

**Workflow lesson:** `parallel()` takes THUNKS, not promises — `() => agent(...)`,
never `agent(...)`. Passing promises made every verify pair error out and the
workflow returned empty. The compare-phase findings were still recoverable from
`journal.jsonl`, which is where the analysis above actually came from.

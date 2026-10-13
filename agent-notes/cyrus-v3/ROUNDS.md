# Cyrus v3 — design polish log (2026-10-07)

Scope change from the owner mid-task: no new system, no style tiles. Keep v2's layout, flows and
interactions; polish the design in place on `feature/cyrus-modbuilder`.

Harness: throwaway DB `nxeon_agt_cyrus` (reseeded with `.cyrus-local/seed.ts full`), mock build
service `.cyrus-local/mocksvc.js` on :7399, `next dev -p 3149` (nice/ionice, 3 GB heap), screenshots
with `node /root/agent-notes/cyrus-v3/shot.mjs` (1440x900 desktop, 1920x1080 wide, 390x844 phone;
dark + light). Before shots: `before/` (v2 as shipped).

## Checkpoint (checkpoint/) — first pass of the whole re-dress
Done before the checkpoint:
- Tokens: graphite ground (#0a0b0d), ink scale #edeef0 / #b3b7be / #8e939b / #80858e (all >= 4.5:1 on
  every surface), ONE accent "signal" #cdf24b (light: fill #c6ea3a, text/stroke #4a6600), ONE alert
  #ff6b4f (light #b93a1d). No violet/blue/cyan/magenta anywhere in Cyrus.
- Surfaces: glass + blur + glow shadow replaced by near-opaque machined panels (hairline, quiet shadow);
  blur kept (10px) only on dock, inspector, composer, drawer. Radii 6/8/10/14 instead of 20-22 + pills.
- Gradient text removed (headline is ink + ink3), gradient buttons removed (primary = flat signal fill
  with near-black text), sparkle icon removed everywhere.
- Icons: all 44 icons now Lucide (ISC, licence notice in components/cyrus/icons.tsx), 1.6 stroke.
- Network (engine.ts): new theme palettes; ink hairline web, HUD bearing dial on the first ring,
  monochrome mod constellations, signal only on live work, alert only on failures; halos only for
  running nodes; calmer pulse rates; flat machined hex core with a single signal point; real light
  palette (normal compositing, dark ink lines, olive signal).
- Game selector: lib/cyrus/games.ts registry (id, name, status live/soon, mark, builds, loader,
  versions); home rail above the prompt; composer pick shows the game mark + loader + version; the
  version panel is driven by the registry.
- Model colour dots replaced by a tier mark (three ascending ticks).
- "Built with Cyrus" badge: machined plate (hex mark | BUILT WITH CYRUS | v1.0.0).
- Voice: 30-bar rainbow waveform replaced by 5 thin signal bars + "Listening…", no glow, static under
  reduced motion.
- Light theme is real: paper ground, white panels, ink text, network re-drawn in ink.
Checkpoint critique:
- Home reads calm and premium; the web supports instead of competing. Game rail is wider than the
  composer (1310 px vs 760) and mono version digits look loose -> rail capped to the composer width,
  versions moved to the composer pick in tabular sans.
- Live build: inspector narrowed to 36vw clipped the code to ~330 px; tag "CYRUS IS WRITING THIS FILE"
  truncated the path -> 37vw, file tree 158 px, tag shortened to "Writing".
- Light: the signal glow pool on paper reads as a dirty green wash -> glow strength cut to 0.3.

## Round 1 (r1/) — every state, both themes, three sizes
Shot: home + live build at 1440/1920/390 dark+light, done (Explain), failure, versions + diff, drawer,
model picker (desktop + phone), game/version picker, focus.
Critique -> fixes:
- Done weave: 13 Java files drew "{}" at 9 px, which reads as "0"; most files unlabelled -> nodes too
  small for a glyph draw one centre mark (dot = source, square = plugin file); every file now asks for
  a label and a screen-space collision pass lets key/live/hovered labels win while the rest give way
  (also fixes v2's "dot-only satellites": commands/permissions/settings are labelled in mono, drawn as
  square / diamond / ring so you can tell them apart).
- Stage ring on a finished build painted the repair segment in alert, reading as an error -> alert
  only while repairing or failed; a completed ring ends in one signal segment.
- Phone model picker: the "sheet" was still centred inside the composer, because the composer's
  backdrop-filter made it the containing block of position:fixed -> pickers are portalled to <body>
  on phones and dock to the bottom edge (grab handle, safe-area padding, slide-up 260 ms).
- Mono digits in versions looked loose -> version pickers use tabular sans figures.
- Kept: failure card, versions map (graph-paper ground, ink nodes, signal ring on current), drawer.

## Round 2 (r2/) — the fixes, plus voice, hover, focus
- Voice (owner: "way too extreme"): now five 2 px signal bars driven by the real mic level, sampled
  ~16x/s with smoothing, a slow idle pulse when quiet, "Listening…", mic button filled with the signal.
  No waveform, no rainbow, no glow; one static frame under prefers-reduced-motion.
- Phone model picker verified as a real docked bottom sheet (r2/picker-mobile*).
- Done weave: every file labelled where it fits; satellites labelled in mono.
- Hover card + version diamonds and focus mode checked; fine.
Remaining critique: duplicate "/eco" satellites (one per sub-command) -> fixed in round 3.

## Round 3 (r3/) — final pass
- One satellite per command name (scenes.ts), so command labels never repeat.
- Templates modal (segmented category control, tier marks) and install modal (light) checked.
- Final set re-shot: home + live build at 1440 and 390, dark + light; done/Explain dark + light.
Honest verdict: the blue/purple wash is gone; the UI is one neutral ground, one signal colour and one
alert colour, and every text colour passes AA. The web supports the UI. Weakest remaining spots:
satellites still cluster tightly around plugin.yml on mods with many commands (labels give way rather
than overlap, so some are hidden until hover/zoom); the portal's own rail and top bar are still the
navy Nxeon chrome around a graphite Cyrus (out of scope: portal-wide); the in-code horizontal scroll
at 1440 (the inspector is 37vw so the web can be bigger).

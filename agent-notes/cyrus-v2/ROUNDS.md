# Cyrus v2 — iteration log

Harness: throwaway DB `nxeon_agt_cyrus` (recreated 2026-10-07, schema pushed, `.cyrus-local/seed.ts full`),
mock service `.cyrus-local/mocksvc.js` (v2: simulates the 0.4 `/live` stream from real fixtures),
`next dev -p 3149`, `node /root/agent-notes/cyrus-v2/shot.mjs <name> <path>` (desktop 1440x900,
wide 1920x1080, mobile 390x844; dark + light). Reference frames: `reference/`.

## Round 1 — first full build (r1/)
Built: engine port (CyrusWeb), full-page app frame, dock + library, home console, project scene,
inspector, live code, explain document, CSS v2.
Critique → fixes made inside the round:
- Button reset `.cy-app button` out-specified every component class → `:where(.cy-app) button`.
- Home: headline + web + composer collided (3-line display type, two rings of mods, 8 seeds with
  labels). → headline moved into a bottom "console" with the composer; the web owns everything
  above it; one calm ring of max 8 mods; seed labels only on hover; first-ring-only fit.
- Mods were flat letter discs → each mod orb now draws its own constellation (same algorithm as
  the dock glyph), bigger orbs, bolder strands, brighter orb-web.
- Project: caption sat on top of the file ring → pinned below the whole weave; done-caption is one
  compact line (tagline lives in Explain). Rings sized by file count; `.java` dropped from node
  labels; only key/live/fresh/hovered files labelled.
- Live code didn't appear until every changed file was fetched → two-phase publish (draft + list
  first, contents after).
- Phone: composer textarea measured at 0 width (desktop layout before the stacked switch) → stacked
  layout via a container query (no JS flash) + autosize on resize; webctl hidden; bar one row.
Verdict: the home now reads as an app with a living stage; project live build is convincing.
Still cheap-looking: strip chips, small file orbs, empty left half on project, tree truncation.

## Round 2 — states, overlays, the flow, performance (r2/)
Shot: drawer, model picker over an attached image, hover card + version fan, template library,
install modal, light project, 1920 done, focus mode, full end-to-end flow (r2/flow/: typing →
image → voice → model → game → Build → fly-through frames → planning → live coding frames →
bloom → done; mock received `tier: katara, images: 1`).
Critique → fixes:
- Popovers/hover/menu/modal glass too transparent over busy content → dedicated `--cy-pop`
  surface (95% opaque) for anything that carries text over the stage.
- Modals rendered inside the app's stacking context, under the portal top bar → portalled to
  <body> with a `.cy-tokens` wrapper carrying the theme tokens.
- Inputs inside labelled boxes showed a double focus ring → focus styles moved to the box.
- Failure card under the core was too tall (covered by the change prompt) → verdict + two actions
  under the core; the reasons, tips and compiler output moved to the top of the Request tab.
- Satellite labels clipped at the region edge → fit leaves room for satellites; labels only when
  few or zoomed in. File rings spaced for label width (142 units per node); "fresh" labels only
  while building.
- Title chips overflowed → title truncates first, chips never shrink.
- Headless profile: engine draw 5.8–7.2 ms/frame (software canvas, dpr 1); compositing of many
  backdrop blurs dominated → blur kept only on the big surfaces (dock, drawer, inspector,
  composer, popovers), background re-rendered at most every 0.4 s or when the core moves.
- Premium finish: film grain overlay, a wide light pool on the disc, a richer composer surface,
  template seeds drawn as sparks instead of dark holes, Explain gets a dot when a build finishes
  while you watch the code.
- New: focus mode (D or the fold button) folds the inspector to a pill and recentres the weave.

## Round 3 — empty, tablet, reduced motion, palette, the thinking web (r3/)
Shot: empty home (dark + light), tablet project + home, reduced motion home + live build,
palette, focus mode.
Critique → fixes:
- Reduced motion rendered only the core: nodes waited for a clock that never runs → reduced
  mode skips the stagger and shows every node at once (static frame per change).
- Planning looked dead (no files yet) → the web itself thinks: light runs out along the spokes
  while the AI plans (violet/cyan), repairs (amber) or compiles, so every real stage reads on the
  network even before the first file exists.
- Empty state is calm and premium: core, "+ New mod", scattered template sparks.
- Tablet (1024): stacked layout via container query, hero web + live code + sticky change prompt.
- Service helpers moved into services/modbuilder/live.js with unit tests (32 tests pass).

## Round 4 — final pass + real builds (r4/, best/, proof/)
- Real build through the Cyrus UI against the real 0.4 service (dev server pointed at the tunnel,
  throwaway DB): `mbe20231227d9bb0157249`. Prompt only said "exactly like the attached picture";
  the plugin came out named LumenBazaar with the picture's items, amounts, prices and slots.
  29 /live polls carried streamed draft text; frames in proof/ui/.
- Fixes found by it: the portal live route dropped `seq` (server re-sent whole drafts) → passed
  through; draft titles from "/shop …" prompts start without the slash.
- Brand mark on the loom's centre ("C Y R U S"), brighter core glow (side-by-side with the
  reference showed our centre flatter than the Nexus), course-change mid-transition handled, the
  in-inspector diff defaults to unified, phone Stop button label.
- Final set: home dark/light at 1440/1920/390, live build at 1440/1920/390 dark/light, done,
  versions + diff, failure, focus mode, hover, drawer, picker (desktop + phone sheet), keys,
  frame sequences (frames-run, frames-home). Best 8 in best/.
Honest verdict: home and the live build read as a product of their own (the web is the brand, the
UI is a few deliberate surfaces). Weakest remaining spots: the project web is small next to the
inspector at 1440 (focus mode helps), satellites are unlabelled dots until hovered, the phone
model picker is a centred sheet rather than a docked one.

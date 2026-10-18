# EF: Cyrus marketing site overhaul (2026-10-18, Opus)

Branch `feature/cyrus-marketing-overhaul` (worktree `/tank/dev-worktrees/cyrus-mkt-overhaul`, from main af5a1d55 = live rc21).
The brief named `feature/cyrus-marketing-v2`, but that branch and its worktree already exist (CN, 2026-10-15, merged into
main and clean), so a new name was used; nothing of it is lost. Flag: `CYRUS_MARKETING_V2=1` (env, default off).
Mockups and screenshots: `EF-mockups/` next to this file.

## 0. Phase 0 findings (how cyrus.my is served today)

| Path | Served by | Source |
|---|---|---|
| `/` | nginx, static release `/var/www/cyrus.my -> cyrus.my-releases/20261016T051521Z-45ab0502` | `apps/cyrus-site/src` (publish.sh) |
| `/assets/*`, `/status/` | nginx static | same |
| `/help`, `/help/<slug>`, `/plans` | app, `(cyrus-help)` tree, gate `CYRUS_CUSTOMER_APP` | `app/(cyrus-help)/cyrus-help/*` |
| `/games`, `/games/<g>`, `/mods`, `/mods/<slug>`, `/host`, `/host/<a>[/<b>]`, `/blog`, `/blog/<slug>` | app, `(cyrus-web)` tree, settings `cyrus_content_public_enabled` / `cyrus_mods_public_enabled` (preview accounts see them today; anonymous = 404/409) | `app/(cyrus-web)/cyrus-web/*` |
| `/sign-in`, `/sign-up`, `/auth/*`, `/legal/*` | app, `cyrus-host` tree | `app/cyrus-host/*` |
| `/minecraft/**` | app (branch feature/cyrus-minecraft-seo, not merged) | uses the `(cyrus-web)` layout |

Routing: `lib/cyrus/bridge/routing.ts` (`cyrusHostRoute`) + `lib/cyrus/web-paths.ts` (`WEB_ROOTS`); nginx vhost allow-lists
the first path segment (`deploy/cyrus/nginx-cyrus-my.conf`), so every NEW root (studios, about, compare, for) and moving
`/` to the app needs the owner's nginx apply.

Three different navs exist: the static landing (in-page anchors: Pipeline, Studios, In game, Gameplay, Games, Plans,
Nxeon), the content layout (Games, Mods, Host, Blog) and the help layout (All articles). Three footers likewise.

**Scroll bug, root cause.** `.cx-app` (the customer-app root class, `app/dashboard/cyrus/app/app.css`) is a scroll
container by design (`height:100%; overflow-y:auto; overscroll-behavior:contain`) because inside the studio it lives in
the clipped fixed-height `.cyrus-root`. The content and help layouts reuse `.cx-app` as their page root
(`cx-app cw-root`, `cx-app hp-root`) plus `min-height:100vh`. Outside the studio the parent is `body`, so the page is a
document whose root element is ALSO an overflow container: the document itself has nothing to scroll, and the inner box
only scrolls while the pointer is over it and it has focus semantics. Keyboard scrolling (Space, PageDown, arrows) does
nothing until something inside is focused, touch/scroll-chaining is cut by `overscroll-behavior: contain`, and browsers
that size `height:100%` against the viewport (any time body/html get a height) end with a viewport-tall box. The fix is
at the root: marketing pages no longer use `.cx-app` as the page element at all (the new shell is a plain document with
its own `mk` tokens), and the old layouts get `.cx-app.cw-root, .cx-app.hp-root { height:auto; overflow:visible }` so
production pages are fixed too when the branch merges (this part is not behind the flag; it changes nothing visible).

**Nxeon chatbot.** `app/layout.tsx` mounts `<ChatWidget>` (Nxeon support AI) and `<LiveChat>` (admin snippet) on every
non-admin path, including every app-rendered cyrus.my page. Fix: the root layout skips both when the request carries the
Cyrus host marker header. Cyrus's own help entry stays the existing Help center + Report a problem.

**Other Nxeon leaks on Cyrus marketing pages** (found, replaced in the v2 shell): Nxeon `OrganizationJsonLd` (Nxeon
organisation schema on cyrus.my pages: replaced with Cyrus Organization + WebSite on the Cyrus host); the Nxeon cookie
notice (already hidden when CYRUS_CONSENT is on); Geist (Nxeon font) inherited from `<html>` (shell sets its own
families); Nxeon toasts / preloader are not used on these pages; the static landing's preloader `.pl` is Cyrus's own.
Meta Pixel / Nxeon analytics still load on app pages of cyrus.my: owner decision (see 6).

## 1. Sitemap / IA

```
/                       Home (3D core hero, pipeline, studios, games, mods, plans teaser, host, final CTA)
/studios                All studios (hub)          /studios/<id>  code, texture, sound, model, motion, config, designers, rooms, test-flight, install
/games                  Games hub                  /games/<game>  per game (Minecraft live, others "coming soon")
/minecraft/**           Minecraft SEO cluster (feature/cyrus-minecraft-seo owns it; uses this shell automatically)
/mods                   Community mods showcase    /mods/<slug>   public mod pages (UX/community agent designs them; we link)
/plans                  Pricing (nav label "Pricing"; URL kept for existing links/SEO)
/host                   Host with Nxeon            /host/<game>[/<place>]
/compare                Alternatives hub           /compare/<slug>  hand-written plugin, hiring a developer, general AI chat
/for/<audience>         Use cases: server-owners, creators, beginners
/blog, /blog/<slug>     Blog
/help, /help/<slug>     Help center
/about                  About Cyrus (who runs it, the Nxeon relationship, contact)
/legal/*                Terms, Privacy, AUP, SLA
/status/                Status (static)
```

## 2. One navigation model

Desktop, top state: full-width bar, the Cyrus wordmark at left, centre groups, right `Sign in` + `Start building`.
- **Product** (panel): the studios (icon, name, one line) + "All studios", "How it works" (home pipeline anchor).
- **Games** (panel): Minecraft (Live) + the coming-soon list from the game registry + "All games".
- **Mods** (link), **Pricing** (link), **Host** (link).
- **Resources** (panel): Help center, Blog, Compare, Use cases, Status, About.

**Signature interaction: "Core dock".** As the page scrolls past the hero top (64 px), the bar detaches into a floating
pill centred under the top edge; the wordmark's letters collapse (clip + fade, 260 ms) and only the Y mark remains, now
held inside a thin orbit ring whose arc is the reading progress of the page (stroke-dashoffset bound to scroll). On the
home page the ring's colour is the core's: the hero core visually "becomes" the mark. Scrolling up re-expands to the full
bar only at the top. Hover on the mark: the ring spins once. Reduced motion: no collapse animation, no ring motion (the
ring is drawn static at the current progress), the pill still appears (state change, not motion). No JS: the full bar,
sticky, all links work.

Mobile: the same pill from the start (mark + "Start" + Menu button). Menu opens a full-height sheet: the groups as big
type rows with their sub-links, Sign in / Start building pinned at the bottom, focus trapped, Esc closes, body scroll
locked only while open (and released on close and on route change: the opposite of the scroll bug).

## 3. Footer (every marketing page)

Closing band (headline + prompt CTA) then five columns: Product (studios, how it works, pricing, changelog = blog),
Games (Minecraft + all games), Resources (help, blog, compare, use cases, status), Company (about, host with Nxeon,
contact = help/Report a problem), Legal (terms, privacy, AUP, SLA). Bottom row: the Y mark + "Cyrus is built and run by
Nxeon" (Nxeon named as the owner, never as a provider), the language selector (English only today: shown as a static
"English" label, not a fake menu), socials only when a real account URL exists in settings (none today: row omitted),
"Not affiliated with Mojang or Microsoft", copyright.

## 4. Visual system (direction A, "Event Horizon")

- Ground: true space black `#030407` with a faint deep-blue/magenta nebula at the hero only; real light mode (`#f5f6f9`
  ground, ink `#0a0b10`) via tokens, honouring `prefers-color-scheme` and an explicit toggle (`data-mk-theme`).
- **One UI accent: Ion cyan** (`#2fd6ff` dark / `#0a7fa8` light, AA on both). Used for live state, focus, links in
  copy, the progress ring. The **brand spectrum** (cyan -> electric blue -> violet -> magenta, sampled from the owner's Y
  mark: #00d9ff / #2a4bff / #c93dff / #ff2bd6) appears ONLY in the Y mark, the core, and one hairline on the primary
  CTA. No gradient text, no glow on cards, no glass on everything.
- Type: Space Grotesk (display, tight tracking, very large on hero), Inter (body), JetBrains Mono (labels, states).
  Self-hosted via next/font; the shell sets its own families (no Geist).
- Grid: 12 columns, 1200 px content max, 24 px gutters desktop, 16 px side gutter mobile.
- Motion principles: motion explains state (pipeline stages, a build progressing, the nav docking), never decorates;
  200-600 ms, one easing (`cubic-bezier(.2,.8,.2,1)`); scroll reveals are CSS (`animation-timeline: view()` where
  supported, IntersectionObserver fallback), all off under `prefers-reduced-motion`.
- 3D language: CSS 3D (perspective + preserve-3d) slabs with a real back/rim layer so they read as panels with
  thickness, lit from the core (a per-card highlight that follows its angle to the core). One 3D scene per page at most.
- Illustrations: generated SVG (orbits, studio glyphs, pipeline diagrams), the owner's Cyrus art (Y mark, coins, badges
  from `/root/agent-notes/cyrus-assets/full-res`, already in `public/cyrus/brand`), the existing site media (real
  rendered loops, in-game shots). No stock photos.

## 5. The 3D hero

Six pipeline panels (Code, Texture, Sound FX, 3D model, Compile, Install) on a tilted orbit around the core. Each panel
is a CSS 3D slab positioned by angle on an ellipse (rotateY to face the camera, translateZ by depth, scale and
brightness by depth, back panels blur slightly). The orbit turns slowly (one revolution / 60 s), pointer parallax tilts
the whole stage (max 6 deg), scroll pushes the stage back and shrinks the core toward the nav mark. **Live states**: the
pipeline cycles plan -> code -> texture -> sound -> model -> compile -> install; the active panel comes forward, its
header state reads `live`, a beam connects it to the core, its body animates (typing code, pixels filling, a waveform,
a turning voxel, a progress bar, the install row ticking). Typing a prompt restarts the cycle with that prompt's words
in the code panel (illustration, labelled as such, same as today).
Budget: hero JS <= 12 KB gzip (no three.js; the core is SVG + CSS), no layout shift, LCP element = the H1 text.
Fallback: no JS or reduced motion = the same six panels laid out statically around the core, states shown as a list.
Mobile (< 760 px): the orbit flattens into a 2-row arc above the prompt; the active panel enlarges.

## 6. Per-page concepts

- **Pricing (/plans, the showcase page)**: hero with the three plan "slabs" in light 3D (tilt on hover, the middle plan
  raised), each fed by `livePlanColumns()` (real settings) and the content file; honest placeholders ("To be announced")
  styled as designed states, not errors. Below: the comparison table (sticky header, first column sticky on phones),
  "How tokens work" as a 4-step animated token flow (coin art), FAQ (FAQPage JSON-LD), host-with-Nxeon cross-sell, CTA.
  Structured data: SoftwareApplication + Offer per plan only when a real price exists (never invent a price).
- **Home**: 3D core hero + prompt, the pipeline explained in 7 steps (scroll-linked), studios grid (links to
  /studios/<id>), the existing real media (motion loops, in-game) re-framed, games strip, mods strip (if public),
  plans teaser, Nxeon hosting band, final CTA.
- **Host**: "Your mod, on your server" story: an animated install path (Cyrus core -> build -> server rack art), plans
  from the real hosting catalogue, locations, FAQ. Keeps HostView's data rules.
- **Mods**: showcase grid with real community cards (links to the UX/community agent's mod pages), spotlight hero,
  categories, empty states that sell "be the first".
- **Games**: hub with Minecraft as a large live card (real version range from the registry) and the coming-soon grid
  with original emblems; per game page with what Cyrus builds for it, versions, FAQ.
- **Studios**: hub + one page per studio with an SVG illustration, what it does, the plan it needs, honest limits.
- **About / Compare / For**: short, factual, templated from one data file with honest claims only.

## 7. Directions (Phase 1 mockups)

- A **Event Horizon** (`EF-mockups/shots/mock-a-event-horizon.png`): space black, Y-spectrum only in mark and core,
  Ion cyan accent, 3D panels orbiting the core, the Core-dock pill nav with the progress orbit.
- B **Signal** (`EF-mockups/shots/mock-b-signal.png`): light-first engineering paper, magenta accent, vertical index
  rail, flat isometric line illustrations, no glow.

**Chosen: A.** The owner asked for the orbit cards to become 3D (A is built around that scene; B has no place for it),
the owner's art is the neon Y on black (it reads best on A's ground), the owner rejected the graphite+lime v3 for being
"not in sync with Nxeon" and A stays in Nxeon's space/neon family while owning its own accent, and A keeps the hero the
owner already likes instead of replacing it. B's best ideas are kept: the index-rail idea becomes the reading-progress
orbit, and its strict grid and mono labels discipline A's layout.

## 8. Build log, screenshots, numbers

Branch `feature/cyrus-marketing-overhaul`, rebased on `release/cyrus-rc22` (400bb6b0). Verified on node-2: `next build`
Compiled successfully + type check passed; tests 174/175 pass, 0 fail (marketing-v2, bridge routing, nginx vhost, content,
seo, admin host, launch check, site links; run with the devhost Cyrus env unset). The v2 vhost could not be `nginx -t`'d:
nginx is not installed on node-2 (and must never run on the primary): owner/coordinator to syntax-check before applying.

**Screenshots** (`EF-mockups/shots/`): `mock-a-*`/`mock-b-*` directions; `r1..r4/` Pricing rounds (r4 = sent to owner,
incl. `light-plans-desktop.png`); `p1/` round 1 of every page (desktop 1440 + mobile 390, viewport + full + scrolled);
`p2/` round 2 after fixes. Critique passes: Pricing 4 rounds (button text invisible from a reset's specificity, cards
blank until hydration -> CSS entrance, reveal safety net, H1 wrap, spacing); every other page 2 rounds (3D slab rims
painting over the panel faces because `filter` flattens preserve-3d -> rims behind faces, orbit too large and occluding
the core -> smaller depth radius, oversized footer/auth wordmark, 4-line H1s on long titles -> `.sm` hero, empty studios hero
-> stacked studio windows).

**Performance** (production build on node-2): First Load JS home 109 kB (page 3.78 kB incl. the 3D hero; shared 105 kB),
Pricing 106 kB, studios/games/mods 105 kB, help/about/compare/for 106 kB, sign-in 118 kB. Real transfer measured by
Playwright: JS 133-141 kB per page, total 368-600 kB (home 2.7 MB: the Minecraft screenshots + loop posters; videos load
only on view). LCP on the 390 px mobile run: 236-408 ms on a warm local server (desktop numbers on the loaded node-2 are
noise). No WebGL, no three.js, no GSAP on any marketing page.

**Scroll**: every v2 page scrolls with wheel and PageDown on desktop and mobile (`scroll.yWheel/yKey` in the reports).

## 9. What is done / not done

Done (behind `CYRUS_MARKETING_V2`): shell (nav + footer) on every app-rendered cyrus.my page incl. help, blog, legal,
Minecraft cluster; home 3D hero; Pricing; host (hub/game/place/combo); mods; games hub + per game (live + coming soon);
studios hub + 10; about; compare + 3; use cases (3); v2 sign-in/sign-up/private beta (same links, CSRF/state, rate limits,
SSO); Cyrus 404; Cyrus stale-version toast; SEO system + OG cards + sitemap; Search Console checklist (docs/cyrus/18-seo.md).
Outside the flag: scroll-container fix, no Nxeon chatbot / LiveChat / Org JSON-LD on the Cyrus host, Cyrus root metadata.

Not done: blog index/posts and help articles keep their (re-tokened) legacy markup inside the shell; forgot-password and
verify-email are Nxeon screens inside the Nxeon hand-off (Cyrus has no password), not restyled; the static landing
(`apps/cyrus-site`) is unchanged and stays as the nginx fallback for `/`; sign-in and legal pages could not be screenshotted
through the dev rewrite proxy (dev artefact: Next proxies the rewrite and the middleware 404s the internal tree), so the
v2 auth screens were shot through a devhost-only preview route (`/cyrus-mk-preview/auth`, 404 unless NXEON_DEVHOST=1).

## 10. Owner decisions

1. Approve direction A (Pricing showcase sent 2026-10-18) or ask for changes; accent = Ion cyan.
2. `CYRUS_CONSENT=1` together with the flag: until then Nxeon's cookie notice (blue Nxeon button) shows on cyrus.my.
3. Nxeon Meta Pixel / Nxeon analytics / TrackingProvider still load on app-rendered cyrus.my pages: keep, or gate behind Cyrus consent.
4. Plan prices: Offer structured data appears automatically once a real Stripe price exists.
5. Social account URLs for the footer (none exist, so the row is omitted).
6. Search Console Domain property for cyrus.my + the TXT value for the coordinator to add.
7. Flip order: merge/deploy -> `CYRUS_MARKETING_V2=1` -> v2 vhost (`scripts/cyrus/marketing-v2-apply.sh` prints steps + rollback).

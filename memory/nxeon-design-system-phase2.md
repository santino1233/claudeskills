---
name: nxeon-design-system-phase2
description: "Phase 2 design system built at /opt/nxeon-designsystem (isolated, port 3010) — complete 2026-09-03, awaiting review before Phase 3"
metadata: 
  node_type: memory
  type: project
  originSessionId: 1716c7ee-ae35-4cf5-b557-9059709e07c4
  modified: 2026-09-03T20:20:12.524Z
---

Phase 2 of the portal redesign is built and runs at **`/opt/nxeon-designsystem`**, a NEW tree —
deliberately not `/opt/nxeon-sandbox`, because that one carries a `.env` and the Phase 2 brief
forbids production credentials.

- Start: `cd /opt/nxeon-designsystem && npm run dev` (or `npx next start -p 3010`) → `/design`
- Port 3010. Prod is 3000, staging 3001, old sandbox 3002.
- Dependencies are exactly next + react + react-dom. No `.env`, no Prisma/DB, no Stripe/registrar/
  mail/hypervisor SDK, and zero `fetch`/`process.env` in source. All data from `lib/mock.ts`, all
  addresses from RFC 5737 documentation ranges.
- Next pinned to 15.5.x on purpose (prod is Next 15) so components drop in later without a major-version jump.
- NOT wired to nginx and NOT given a systemd unit — deliberately, to avoid touching prod infra.

Built: tokens in `app/globals.css`; 60-icon family; four surface archetypes (Object with the notch +
status filament, Container, Plate, labelled Rule); controls, navigation, overlays, data, states;
the AppShell; and a showcase at `/design` that navigates via the real shell.

**Why the notch and filament matter:** they belong only to the Object archetype, so "a thing you own"
reads without a label — that is the fix for one card class being used 314 times for objects and prose alike.

**How to apply in later phases:** never introduce a raw hex or hand-typed font size; a border means
"separate object"; one signal colour per view region; violet is reserved for AI/Build only; and
`DeploymentLadder` has no percentage prop by design because the worker reports only six coarse states.

See [[nxeon-portal-redesign-phase1]] for the approved blueprint this implements, and
[[nxeon-pkill-nextstart-incident]] for the operational lesson learned during this phase.

## Later additions (same session)
- **The globe** (`components/system/Globe.tsx`): canvas 2D, no 3D library. ~20k land cells come from
  `/opt/nxeon/public/countries-110m.json` (public-domain Natural Earth 110m), rasterised at BUILD time
  by `scripts/build-land.mjs` into `lib/land.ts` — an 11 KB base64 bitset. Land is projected to unit
  vectors once at mount and only rotated per frame. Great-circle routes carry travelling packets.
  Re-run `node scripts/build-land.mjs` only if the land data changes.
- **The deploy button**: `.nx-deploy` in globals.css is the production `.btn-deploy` hover behaviour
  carried over verbatim (gradient shift, one-shot shimmer sweep, 1px lift, arrow nudge) on the new
  brand ramp. The owner explicitly asked to keep this interaction — do not restyle it.
- **Deployment loaders** (`components/system/DeployLoader.tsx`): five distinct per-product loops —
  vps, game, hosting, domain, email. They LOOP and are never progress; real progress is the
  DeploymentLadder driven by backend states.
- **Glow scale**: `nx-glow-soft` / `nx-glow-card` / `nx-glow-hero` / `nx-lift`. A surface carries at
  most one. Neon stays rationed to a live resource, the brand mark and the primary action.

## Mobile pass
Mobile is a designed state, not a narrowed desktop:
- **Bottom navigation bar** (`AppShell` `bottomNav` prop, `BottomNavItem[]`) — up to four thumb-reachable
  destinations plus More, with safe-area inset padding. The drawer is now the secondary path.
- **Tables carry their own phone layout.** `Column` gained `primary` (becomes the card title) and
  `hideOnCard`. Below `md` the Table renders stacked object cards — pages no longer hand-roll a
  second layout.
- **Modal becomes a bottom sheet below `sm`** (grab handle, max-h 90dvh, safe-area padding).
- **Checkout pins a price + CTA bar** above the bottom nav; the rail's own CTA is `hidden lg:block`
  so a phone never shows two.
- **Resource detail** gets a sticky primary-action row under the header on phones.
- **Globe** renders at 260 / 340 / 430 px by breakpoint.
- **Touch targets:** `@media (pointer: coarse)` gives every button a 44px minimum; opt out with `.nx-inline`.

**BUG FOUND AND FIXED:** the mobile drawer was completely untappable because `--nx-z-scrim` (40) sat
ABOVE `--nx-z-rail` (30). Swapped to scrim 30 / rail 40. If a drawer ever stops responding, check
this ordering first.

## Polish pass (2026-09-03, later session)
Full consistency/a11y/perf pass done; build clean; review URL live. Key hazards for later phases:
- **`clip-path` on `.nx-object` clips outlines AND box-shadows.** A glow class on an object can
  never render, and the global focus ring was invisible on every object button. Focus is now the
  object's own edge (2px signal ring via `--nx-object-edge`); selection is a gradient edge.
  Never put `nx-glow-*` on a clipped surface.
- **White on the brand ramp fails AA at both bright ends** (brand-c 4.40:1, neon cyan 1.51:1).
  Brand fills that carry white text end on derived `--color-brand-c-ink` /
  `--color-brand-glint` (color-mix), so swapping the placeholder magenta hex keeps them correct.
- **Reduced motion uses `animation-fill-mode: forwards`** globally so loop-built graphics (deploy
  loaders) hold a completed static frame instead of reverting to their opacity-0 base.
- Globe rAF pauses off-screen/hidden-tab (IntersectionObserver + visibilitychange), draws one
  static frame under reduced motion, and repaints on selection while paused.
- RegionMap = documented compact variant of the region selector; Globe = hero variant; both now
  share one region/latency story. Checkout gained stepper icons + reassurance cards
  (30-day money back / 24/7 support / "Online in 47 seconds" — the intentional tagline).
- Type floor enforced: removed all 17 arbitrary `text-[...]` sizes (one 10px, eleven 11px).
  New tokens: `--color-interactive-hover`, `--color-hairline-hover`, `--color-on-brand`.

## Phase 3 — application shell (2026-09-03)
The sandbox is now a real portal, not just a showcase. Routes live under
`app/(portal)/` with `PortalShell`; the Phase 2 showcase stays at `/design`.

- **IA lives in `lib/nav.ts`** — the single definition. Sidebar, breadcrumb, command palette and
  the legacy-route map all read from it. Three tiers: Create / Your resources / Account & operations.
- **`ROUTE_MAP` in that file lists all 43 production destinations and where each now lives**, and
  `next.config.ts` redirects every legacy `/dashboard/*` path. Visible in-app at `/routes`.
- **Resource kinds are routes**: `/resources/{kind}` and `/resources/{kind}/{id}`, so the URL states
  the kind and the nav highlight can never disagree with the page (production's core IA defect).
- **The sidebar adapts**: kinds the customer owns are pinned as children with counts; unowned kinds
  are absent and surface under Deploy instead.
- **Active state uses four signals** (gradient edge, raised surface, signal icon, heavier weight) so
  it never depends on a subtle background or on colour alone.
- **Command palette** indexes every kind plus domains, mailboxes, invoices, pages and the 16 tools,
  and leads with ACTIONS (verbs that do something) — production's palette had zero actions.
- **`PageShell`** is the one page contract: breadcrumb, title, description, status, meta, primary,
  secondary, overflow. Plus `Section`, `Split`, `Prose` layout primitives.
- **Shell states**: not-found INSIDE the shell (production ejected to the marketing 404), error with
  technical disclosure, permission denied, offline banner on real browser events, shape-matched loading.

## Colour correction + Deploy rebuild (owner feedback, same session)
Owner: "far too gray, lacking colour and vibrancy" and "the deploy section is not engaging —
this is where all the money comes through". Both were right.

- **PRODUCT IDENTITY is a THIRD colour axis**, added as `--color-p-*` (9 tokens: vps azure, game
  magenta, hosting cyan, domain jade, email amber, storage periwinkle, site spring, cloud coral,
  free green). Rule: identity may tint an icon, hairline or wash; it may NEVER become a button —
  the action stays signal or brand. Classes `.nx-p-tile` / `.nx-p-card` / `.nx-p-edge` read a
  single `--p` variable set per card.
  The earlier "one signal colour at a time" rule was right for ACTIONS but had been over-applied
  into monochrome. Product hue is information, not decoration.
- Identity colour now runs through the sidebar kind icons, the inventory filter chips and row
  tiles, the Home metric tiles and the whole Deploy catalogue.
- **Deploy rebuilt as the money page**: gradient hero using the "47 seconds" brand line, 9
  identity-coloured product cards, inline plan expansion with strikethrough + "then $X/mo",
  a term ladder with Recommended / Best value badges and real savings amounts, a running total
  that stays pinned, and a trust bar. Both prices always shown at equal prominence.

### Deploy: the four wizard products (owner decision)
The guided wizard covers exactly four products, in this order:
**VPS, shared hosting, domain, game servers.** Business email was moved OUT of the headline set at
the owner's direction — it stays purchasable in an "Also available" row alongside block storage,
website builder, NxCloud and free Minecraft, so demoting it strands nothing.

**Domains do not take a plan grid.** Per the Phase 1 blueprint, a domain needs a different mental
model from compute: it opens with a "find your domain" search, and management happens after
purchase. The pricing table shows register / renew / transfer side by side — the competitor
research identified that as the single highest-trust intervention in the domain category, and
renewal shock is the category's biggest trust failure.

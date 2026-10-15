# Cyrus mod pages: public + customer portal screenshots (2026-10-15)

**Data source: FIXTURE.** All 24 shots are of **staging** (`https://staging.nxeon.cloud`, release
20261015T184158Z-84d5be2f = `release/cyrus-rc18`), DB `nxeon_staging`, showing 3 fixture mod pages I inserted for this
run. None of it is production data. Every fixture says so on the page itself: the title starts with "FIXTURE", the
summary starts with "FIXTURE PAGE for a staging layout review... Not a real mod: no build, no jar and no test exists for
it", and "Good to know" reads "Fixture data: nothing on this page was built or tested". Every counter is a real zero
(0 stars, 0 ratings, 0 installs, no view rows: the headless browser's user agent counts as a bot in
`lib/cyrus-site/views.ts`, so no views were recorded). No Test Flight, safety or jar-size claim was written into the
fixture docs (`testFlight` absent, `safety: null`, `jarSize: null`).

Shots: Playwright on node-2 (`scripts/devhost run`), script `scripts/cyrus/modpage-shots.mjs` in the
`cyrus-followups` worktree; dark theme, cookie consent preset, full page, device scale 1. Raw per-shot data
(status, robots, canonical, og:url, overflow, broken images, console errors): `report.json`.
**Every shot: HTTP 200, no broken images, no page/console errors.**

## Which URL is the real public one

| Host | Path | Served by | State today |
|---|---|---|---|
| nxeon.cloud (and staging) | `/mods/cyrus` and **`/mods/cyrus/<slug>`** | `app/(marketing)/mods/cyrus/[slug]` (marketing shell) | the public page; 404 until Setting `cyrus_mods_public_enabled` is on (it is off in production too: `https://nxeon.cloud/mods/cyrus` = 404 today) |
| cyrus.my | `/mods/<slug>` | middleware `cyrusHostRoute` -> `webPath` -> rewrite to `/cyrus-web/mods/<slug>` (`app/(cyrus-web)`) | **edge-blocked**: production nginx `cyrus-my` has no location for `/mods` (or `/games`, `/host`, `/blog`), so it falls to `location / { return 404; }` with `X-Cyrus-Edge: denied` before the app sees it. `cyrus.my/mods/cyrus` is a 404 by design (`webPath` refuses it). |
| any non-Cyrus host | `/cyrus-web/mods/<slug>` | same internal tree, reachable directly | renders with `noindex, nofollow` and no canonical (by design: off cyrus.my it is never indexable). Shot here as the stand-in for what `cyrus.my/mods/<slug>` will look like (staging has no `CYRUS_DOMAIN_MODE`, so there is no Cyrus host on staging). |
| portal | `/dashboard/nxlabs/cyrus` and `/dashboard/nxlabs/cyrus/<slug>` | `app/dashboard/nxlabs/cyrus/**` (Nexion shell) | the customer portal's page for a mod (install, versions, community). Needs a signed-in account + the same public switch. |

Not shot, and why: `/dashboard/cyrus/app/library` is the **asset** library (textures/sounds), not mods, and is
env-gated (`CYRUS_CUSTOMER_APP=1` + `CYRUS_LIBRARY_BROWSE=1`; staging has neither and I did not change staging's env).
`/dashboard/cyrus/[id]` is the creator's studio view of a `ModBuild` they own; the fixtures have no builds (and
inventing builds would mean faking jars/tests), so there is no such page to show. No production login was needed.

## The 3 fixture mods

| slug | title | shape |
|---|---|---|
| `fixture-shop-menu` | FIXTURE Shop Menu | 2 commands (one with a permission), 1 config key, 2 versions |
| `fixture-daily-quests` | FIXTURE Daily Quests | 1 command, 1 version |
| `fixture-mushroom-meadow` | FIXTURE Mushroom Meadow | no commands, extra limitation line, 1 version |

All by the fixture author tag `fixture-maker` (a `CyrusCreator` row with no account behind it), MIT, PUBLIC.

## Shots

Base URL for all: `https://staging.nxeon.cloud`. "signed out" = no session; "signed in" = throwaway account
`fixture-cyrus-shots-8f0299ca@example.invalid` registered through `/register` in the same run (no Cyrus studio access,
i.e. an ordinary customer; its "How did you hear about us?" prompt was skipped as a customer would).

| File | URL | Viewport | Session | What is on it |
|---|---|---|---|---|
| public-list-1440.png | /mods/cyrus | 1440 | out | NxLabs "Cyrus Mods" listing: hero with search, "Published by the community", 3 fixture cards (initial-letter icon, game chip, tagline, version, version count, command count) |
| public-list-390.png | /mods/cyrus | 390 | out | same, one column; page is 394 px wide (header overflow, see D1) |
| public-fixture-shop-menu-1440.png | /mods/cyrus/fixture-shop-menu | 1440 | out | marketing mod page: hero (FS icon, Built-with-Cyrus badge, Minecraft 1.21.11 Paper, "by fixture-maker · v2 · 1.1.0 · 2 versions · MIT"), Install on my Nxeon server, "Sign in to remix", Star 0, Download source; tabs; What it does / How to use it / Commands / Config / Good to know; right rail "Not community-tested yet 3 of 7 checks", Runs on, Ratings "No ratings yet", Open source (Source .zip / Plugin .jar); "Play it tonight" band; FAQ (5); "More Minecraft mods made with Cyrus" (the other 2) |
| public-fixture-shop-menu-390.png | same | 390 | out | same stacked; tab bar scrolls sideways ("Community versions" cut at the edge, "Community" off-screen); 394 px wide (D1) |
| public-fixture-daily-quests-1440.png / -390.png | /mods/cyrus/fixture-daily-quests | 1440 / 390 | out | as above, 1 command, 1 version |
| public-fixture-mushroom-meadow-1440.png / -390.png | /mods/cyrus/fixture-mushroom-meadow | 1440 / 390 | out | as above, no Commands card, FAQ has 4 entries (no commands question), Good to know has 2 lines |
| public-signedin-fixture-shop-menu-1440.png / -390.png | /mods/cyrus/fixture-shop-menu | 1440 / 390 | in | signed-in variant: "Add to my Cyrus", "Save to collection", the "Cyrus is in private preview" note (D3), "Report this mod page"; header shows My account / Back to portal (D2) |
| cyrusweb-fixture-shop-menu-1440.png / -390.png | /cyrus-web/mods/fixture-shop-menu | 1440 / 390 | out | the cyrus.my content-page design (black Cyrus chrome): breadcrumb Minecraft / Mods / title, decorative cover art, title, by, tagline, facts row incl. derived category "Economy & shops", "New" badge, install card with 3 steps and "Rating: New...", What it does, How it works (steps + command table), Honest status, Versions table, "Run it on a Nxeon server" band, Quick answers |
| cyrusweb-fixture-daily-quests-1440.png / -390.png | /cyrus-web/mods/fixture-daily-quests | 1440 / 390 | out | same; category "Quests & progression" |
| cyrusweb-fixture-mushroom-meadow-1440.png / -390.png | /cyrus-web/mods/fixture-mushroom-meadow | 1440 / 390 | out | same; no command table |
| portal-list-1440.png / -390.png | /dashboard/nxlabs/cyrus | 1440 / 390 | in | portal Nexion shell: sidebar, "Confirm your email address" banner, NxLabs tabs (Discover / Browse all / Cyrus Mods BETA / On my servers), Cyrus Mods hero + search, 3 cards |
| portal-fixture-shop-menu-1440.png / -390.png | /dashboard/nxlabs/cyrus/fixture-shop-menu | 1440 / 390 | in | portal mod page: same body as the public page plus "Install on my server", Add to my Cyrus, Save to collection, Report link; the private-preview note (D3); at 390 the tab labels overlap (D4) and the fixed bottom nav is painted mid-page (full-page-screenshot artefact) |
| portal-fixture-daily-quests-1440.png / -390.png | /dashboard/nxlabs/cyrus/fixture-daily-quests | 1440 / 390 | in | same |
| portal-fixture-mushroom-meadow-1440.png / -390.png | /dashboard/nxlabs/cyrus/fixture-mushroom-meadow | 1440 / 390 | in | same |

## Defects

Fixed in the worktree (`feature/cyrus-followups`, not committed, not deployed: the PNGs still show the old rendering):

- **D3 (fixed)** Signed-in mod page hero, portal and public, 1440 and 390: the note "Cyrus is in private preview.
  Remixing opens up when it launches." is drawn as two broken bordered fragments. `RemixButton`'s unavailable
  `<span>` (`components/nx/labs/cyrus/CommunityActions.tsx`) was inline, so border/padding split per line and the
  parent's `w-full` and its `max-w` were ignored. Now `inline-block`.
- **D4 (fixed)** Portal mod page at 390: tab labels overlap ("Community versions" drawn over "Community"). Cause:
  `app/globals.css` portal responsive hardening sets `min-width: 0` on `main .flex > .flex-1` below lg, so the nowrap
  tab buttons in `components/nx/labs/cyrus/CyrusModTabs.tsx` shrink below their labels. Now `min-w-max` (the escape
  hatch that comment documents); the bar scrolls like the marketing page's does. Desktop unchanged.
  Test for both: `test/cyrus-modpage-layout.test.ts` (4/4 pass on devhost).

Not fixed (listed for the owner / a follow-up):

- **D1 horizontal overflow at 390, signed out, marketing header.** Every signed-out `/mods/cyrus*` page is 394 px
  wide at a 390 viewport: the mobile header cluster (`components/marketing/MarketingHeader.tsx:219`, "Get started" +
  hamburger next to the 44 px logo with wordmark) ends at x=394, and "Get started" wraps onto two lines. Signed in
  ("Portal" button) it fits. This is the shared marketing header (pixel-identical rule), so it needs an owner decision
  (e.g. smaller logo/wordmark below ~400 px), not a drive-by edit. Probably on every marketing page; measured only here.
- **D2 desktop marketing header, signed in, 1440:** "My account" and "Back to portal" each wrap to two lines.
- **SEO: staging is indexable.** `https://staging.nxeon.cloud/robots.txt` is `Allow: /` (only /dashboard, /admin, /api
  disallowed), no X-Robots-Tag, and the public mod page has no robots meta. With the switch on, the FIXTURE pages were
  crawlable on a public host; I switched it off again right after the shots. Worth a staging-wide noindex.
- **SEO `/mods/cyrus` listing:** `og:url` = `https://staging.nxeon.cloud` (site root inherited from `app/layout.tsx`)
  while the canonical is `/mods/cyrus`; og image is the generic site card. (The mod detail pages are right: canonical,
  og:url and og:image = page URL / `games/art/minecraft_hero.jpg`, JSON-LD present.)
- **SEO `/cyrus-web/mods/<slug>` off cyrus.my:** noindex and no canonical (intended), but `og:url` is the site root
  and og:image the generic Nxeon card, so a share of that URL previews as the homepage. The comment in
  `lib/cyrus/web-paths.ts` says "canonical = cyrus.my" there; the code (`webMetadata`) emits no canonical unless
  indexable. Doc/code mismatch to settle.
- **SEO portal pages:** `/dashboard/nxlabs/cyrus/**` inherit `<link rel="canonical" href="<origin>">` (the homepage)
  and no robots meta from the root layout; only robots.txt keeps them out. Harmless today, wrong signal.
- **Title double brand:** `FIXTURE Shop Menu — Minecraft 1.21.11 Plugin | Cyrus Mods — Nxeon` (two suffixes, long).
- **Meta description says "read the source"** even when the doc's `files` list is empty (true for fixtures only; real
  mods always carry source).
- **cyrus-web cover art** is a slug-hashed decorative picture (crystals for the shop, a sword for a biome pack,
  monsters for quests) with a generic alt. Not data, but it can read as a screenshot of the mod; consider a neutral
  cover until a creator uploads one. The banner uses the `-sm` (600x315) image stretched to ~700 px: slightly soft.
- **cyrus-web:** "How it works" step 2 sits far below step 1 when a command table is beside it (the steps stretch to
  the table height); the "1 version" heading's "1" renders as a slashed glyph in the display font; the purple page glow
  stops in a hard line at ~900 px in full-page shots (likely a viewport-height background, so a screenshot artefact).
- **Portal email banner on staging** says "We sent a link to ..." but staging has no SMTP: both the welcome and the
  verify email were recorded `FAILED / SMTP not configured`. True in production (SMTP set), false on staging.
- **Fixture-only, not defects:** Source (.zip) / Plugin (.jar) / Download source link to the download API, which has
  no build behind a fixture; "Not community-tested yet 3 of 7" and "Passed the safety check · Not scanned" are the
  honest computed values for zero data.
- No empty-state bugs, no broken images, no fabricated-looking numbers found: zeros render as "0", "No ratings yet",
  "New".

## Staging rows written (all in `nxeon_staging`; cleanup: `cleanup-staging.sql`, dry-run verified with ROLLBACK)

- `CyrusCreator` `fxshots_creator_20261015` (tag fixture-maker); `CyrusModPage` `fxshots_page_shop`,
  `fxshots_page_quests`, `fxshots_page_meadow` (slugs above). Still present (invisible while the switch is off).
- `Setting` `cyrus_mods_public_enabled=true`, `cyrus_install_published_enabled=true`: inserted for the run, **deleted
  again** right after it (staging had no row for either before). `/mods/cyrus/fixture-shop-menu` is a 404 again.
  To re-shoot: insert both again, run the script, delete both.
- Two throwaway accounts from `/register` (first run's portal shots were covered by the attribution prompt, so a
  second run registered again): `cmv9xf212000ohl3oxoqeefxm` fixture-cyrus-shots-5c292a00@example.invalid and
  `cmv9xwecw001ehl3oncu5fbak` fixture-cyrus-shots-8f0299ca@example.invalid, plus what registration/browsing created
  for them: ActivityEvent 1+1, AuditLog 1+1, EmailLog 3+2 (all FAILED "SMTP not configured": nothing was sent),
  EmailVerificationToken 1+1, UserSession 1+1, Visit 10+11. Passwords were random, in memory only, never stored.

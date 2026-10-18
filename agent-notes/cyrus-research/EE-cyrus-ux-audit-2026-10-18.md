# EE: Cyrus UX audit, plan reconciliation, target design, quick wins (2026-10-18, Opus)

Branch `feature/cyrus-ux-audit` (worktree `/tank/dev-worktrees/cyrus-ux`, from main af5a1d55 = live rc21). NOT merged, NOT deployed, no flag, no migration. Scope (coordinator, 2026-10-18): the logged-in customer portal + studios + asset/community library on both hosts; the cyrus.my marketing side and login/register belong to the marketing-overhaul agent (`feature/cyrus-marketing-v2`); Structure Studio page and `AssetsTab.tsx` belong to other agents and were not touched.

Owner's words: "the entire customer portal is a mess, there are 2 nav menus on the top and side. Even in the core studio a nav button top-left brings up the same menu that's already in the top bar. The asset library is pretty bad: slow, not structured, you can't even play the sounds. No mod spotlight or live-updating new assets. We made a whole plan for this but none of it got done." Plus (coordinator) the "Nxeon visual language leaking into Cyrus" inventory.

## How the evidence was gathered (and its limits, stated plainly)

- Screenshots: `ux-audit-2026-10-18/` next to this file (PNG; the sync ignores them; nothing published externally).
  - `before-2026-10-15/`: the current live layout as shot by the studio-ux round (`/root/cyrus-studio-ux-shots/after/`, that branch is merged in main af5a1d55, so these ARE today's nav) and the community page shots (`screens-mod-pages/`, same code as main).
  - `before-*.png` / `after-*.png`: this round, devhost on node-2 (throwaway DB `wt_cyrus_ux` seeded with all Cyrus fixtures: 6 plan accounts, Banshee Hunt creature+handgun mod with textures/sounds/model revisions, Bounty Hunt with change builds + Test Flight + install, failed boss build, forge packs, datapack, structure suite, content pages shop/quests/mushroom-meadow/hollow-king/lantern-sprint, admin fixtures) and the REAL production catalogue imported into it (62,777 entries, 1,137,021 terms, same entries file + ledgers as production).
- node-2 was saturated all day (load 30-45 on 12 threads, swap full, ~12 agents; the coordinator capped the agent slice to 5 CPUs). `next dev` took 513 s for the first `/dashboard` render and 170 s for `/dashboard/cyrus`, so a full dev-mode sweep of ~55 pages x 2 viewports was not possible. I stopped it, took one production build (as the coordinator asked) of the branch and shot the "after" state on `next start`. Where a "before" shot of this round is missing, the before evidence is the 2026-10-15 set above plus the code reference.
- Load-time numbers in dev mode are meaningless; payload numbers come from the production build's route table and the browse benchmark on the real catalogue (section 1.4).
- Production DB reads were refused by the auto-mode classifier, so no live EXPLAIN; the benchmark runs the same SQL on an identical copy of the catalogue.

## Part 1. Audit

### 1.1 Information architecture today (main af5a1d55)

| Surface | Navigation on screen | Evidence |
|---|---|---|
| Nxeon portal, any page | Nxeon rail (left) + Nxeon top bar with a white "Cyrus BETA" pill | `before-portal-home-d1440.png` |
| nxeon.cloud `/dashboard/cyrus` (core studio) | 36 px "Back to Nxeon" strip, then the studio toolbar: hamburger menu, Cyrus "MOD FORGE" wordmark, breadcrumb (Core > game > category > mod), Jump to, tokens, sound, panel | `before-2026-10-15/after-nx-studio-d1440.png`, `components/nx/CyrusTopEntry.tsx` CyrusBackBar, `components/cyrus/chrome/TopBar.tsx` |
| nxeon.cloud `/dashboard/cyrus/app/*` (customer app) | back strip + Cyrus side rail (Home, New mod, Projects, My assets, Asset library, Servers, Wallet, Studio, Account) + "Simple / Studio" switch top right | `before-2026-10-15/after-nx-home-d1440.png`, `app/dashboard/cyrus/app/layout.tsx` |
| cyrus.my `/studio` | cyrus.my top bar (Home, Studio, New mod, Projects, Assets, Servers, Wallet, Help, Sign out) + studio toolbar with the hamburger, whose panel lists the SAME places again | `before-2026-10-15/after-cy-studio-d1440.png`, `-m390-menu.png` |
| cyrus.my `/home` etc. | top bar (8 links) + side rail (9 links, same places, different labels: "Assets" vs "My assets", "Asset library" only in the rail) + Simple/Studio switch | `before-2026-10-15/after-cy-home-d1440.png` (the owner's "2 nav menus on the top and side") |
| cyrus.my phone | top bar menu button + bottom tab bar (same links) + Simple/Studio + Nxeon chat bubble overlapping the content | `before-2026-10-15/after-cy-home-m390.png` |
| Studio pages (`/dashboard/cyrus/<id>/studio/*`) | their OWN header (`components/cyrus/studios/StudioShell.tsx`): wordmark + "Mod Forge", breadcrumb (Minecraft and Category crumbs both just go to `/dashboard/cyrus`), studio switch (Texture/Sound/Model/Config), "Mod assets", "My assets", tokens, theme | code |
| In-portal community mod page | Lives in the NXEON portal: `/dashboard/nxlabs/cyrus/<slug>` with the Nxeon rail, Nxeon top bar, NxLabs tabs (Discover / Browse all / Cyrus Mods / On my servers), Nxeon gradient tab strip and buttons | `before-2026-10-15/portal-fixture-shop-menu-1440.png`, `portal-list-1440.png` |

Counted on one cyrus.my desktop screen: 3 navigations listing the same 8-9 places (top bar, rail, mode switch) and on the studio 2 (top bar + hamburger panel). Labels differ between them (Assets / My assets / Asset library / Library; Studio / Mod Forge / Core).

Dead ends and detours:
- Studio breadcrumb "Minecraft" and the category crumb both link to the core (`StudioShell.tsx` lines ~56-66): two crumbs, one target.
- Customer-app Home "Open studio" + "New mod" + rail "New mod" + top-bar "New mod": four entries to the same flow on one screen.
- Community: from the Cyrus app the only way to a mod page is a link OUT to `/dashboard/nxlabs/cyrus/<slug>` (`app/dashboard/cyrus/app/page.tsx` ~50) which drops the user into the Nxeon portal chrome; there is no way back to Cyrus except the browser back button or the portal's Cyrus pill.
- Help is `/cyrus-help` on nxeon.cloud and `/help` on cyrus.my; the studio menu was the only studio-side link to it on nxeon.cloud.
- The studio map shows 6 games: Minecraft plus 5 on-hold games (Terraria, Zomboid, Valheim, Rust, Palworld) each with 3 "Coming soon" categories (~15 "Coming soon" pills, `after-nx-studio-d1440.png`); the only real content (Minecraft branch) is a quarter of the canvas.

### 1.2 Jargon and intimidating screens (customer-facing strings)

| Where | What a newcomer reads | Problem |
|---|---|---|
| Studio toolbar, studio pages | "MOD FORGE" under the wordmark; "Core" crumb | three names for one place (Studio / Mod Forge / Core) |
| Prompt dock | "Auto-route through the core", "Enter to forge", "Auto" model picker, "Paper 1.21.11" chip | internal routing language |
| Customer Home "Plan and tokens" | "Models: Katara, Saka, Yakko" | model codenames as plan names, no explanation of what they are |
| Tokens modal | "That model isn't unlocked... Saka comes with the Saka plan; Yakko with All models"; history rows "held 1,200" | holds/reserve ledger words |
| Build follower / project page / spend meter | "tokens held for it are returned", "settling the final charge", "using more than it held" | ledger words |
| Home "Library contributions" | "Held" counter | moderation state shown as a bare word |
| Library page | "your plan: saka", tier codes, "Minecraft: not assessed" | plan codes and pipeline states |
| Project page | "lane-gaps" section, Test Flight verdict labels "Not flown" | engine terms |
| Plan screen (PlanSheet) | "Model · only for an AI build", "Ready-made (instant)", lanes, perf classes, "Continue anyway" | dense; the default view shows every control |
| Storage view | "Katara / Saka / Yakko" tiers per plan | as above |
| Everywhere | "not switched on for this account yet" | flag language |

Fixed on the branch: Mod Forge, Auto-route, forge, held/settling, locked-model text, Held counter, library plan line and licence words (Part 3). Open: plan names (owner decision 1), Test Flight labels, plan screen layering, lane wording (bundle C below).

### 1.3 Nxeon visual language leaking into Cyrus (inventory)

| # | Leak | Where it shows | File | Status |
|---|---|---|---|---|
| L1 | Nxeon live-chat bubble (violet gradient circle, "Live chat with Nxeon") over every Cyrus screen, both hosts, phone included (covers content) | all `before-2026-10-15/*.png` bottom right | `app/layout.tsx` -> `components/ChatWidget.tsx` | FIXED (path + Cyrus-chrome detection) |
| L2 | Nxeon hosting promo popup / promo bar (first-month-free hosting) | any `/dashboard/cyrus*` page for eligible accounts | `app/dashboard/layout.tsx` PromoTrialPopup | FIXED (HideOnCyrus) |
| L3 | "How did you hear about us?" survey modal (Nxeon styling, simple-icons brand marks) | first Cyrus visit of a new account | HeardAboutUsPrompt | FIXED (HideOnCyrus) |
| L4 | Nxeon error card (Nxeon `.card`, `btn-primary`, warning emoji, "Back to dashboard") on any Cyrus crash | every Cyrus route (no `error.tsx` in the Cyrus tree) | `app/dashboard/error.tsx`, `components/ErrorState.tsx` | FIXED (`app/dashboard/cyrus/error.tsx`, skin="cyrus") |
| L5 | Nxeon marketing 404 (gradient "404", Nxeon buttons, "My dashboard") for every Cyrus `notFound()` (missing mod, switched-off page, no access) | Cyrus routes | `app/not-found.tsx` | FIXED (`app/dashboard/cyrus/not-found.tsx`) |
| L6 | "Back to Nxeon" strip with the NX logo across the top of every Cyrus screen | nxeon.cloud Cyrus | CyrusBackBar | FIXED (one chip inside the Cyrus bar) |
| L7 | The whole in-portal community (mod page, listing, creator, collections) is drawn in the Nxeon NxLabs shell: navy cards, Nxeon gradient tabs, `btn-primary`, Nxeon "Install on my server" with the NX mark, Nxeon email-verify banner | `/dashboard/nxlabs/cyrus/*` | `app/dashboard/nxlabs/cyrus/*`, `components/nx/labs/cyrus/*` | OPEN -> bundle B (move into the Cyrus app) |
| L8 | Nxeon `VerifyEmailBanner` + `AnnouncementBanner` (Nxeon styling) above Cyrus pages on nxeon.cloud | `/dashboard/cyrus*` | `app/dashboard/layout.tsx` | OPEN (functional, keep but restyle or move into the Cyrus bar; decision 6) |
| L9 | Nxeon icon set in the Cyrus command palette | studio Ctrl K | `components/cyrus/chrome/CommandPalette.tsx` imports `components/nx/Icon` | OPEN (small) |
| L10 | Nxeon checkout modal / payment step for token purchases and storage | Tokens modal, storage | `components/cyrus-tokens/TokensModal.tsx` (customer/StripeCheckoutModal), `components/cyrus/app/StoragePanels.tsx` (customer/PaymentStep) | OPEN (money path: restyle only with a live payment test) |
| L11 | Nxeon legal document renderer | Cyrus terms/privacy | `components/cyrus/legal/CyrusLegalDoc.tsx` (marketing/LegalDoc) | marketing agent's area |
| L12 | Nxeon portal preloader | was on every Cyrus route | `app/dashboard/loading.tsx` | already fixed 2026-10-15 (`app/dashboard/cyrus/loading.tsx` CyrusPreloader); the owner's memory is from before that |
| L13 | Two Cyrus skins in one product: studio (`studio.css`, violet glass + aurora, Inter/Space Grotesk) vs customer app (`app.css`, black + hairlines + blue/violet energy) vs studio pages (`cys-*`), vs the unreviewed "Cyrus skin" (`CYRUS_STUDIO_SKIN`, off) | compare `after-nx-studio` vs `after-nx-home` | `app/dashboard/cyrus/{studio,ux}.css`, `app/app.css` | OPEN (owner decision 4: pick one) |

### 1.4 Asset library: why it is slow, why sounds don't play

Measured / read (real catalogue on node-2, code on main):
1. **No player at all.** No `<audio>`, `new Audio` or play button exists anywhere under `components/cyrus` or `app/dashboard/cyrus` (the only `.play()` is an animation clock in ConfigStudio). Sound rows render the word "Sound". The backend CAN serve a 30 s mono Ogg preview (`preview-ogg@1`, the only way library audio ever leaves the server, `lib/cyrus/library/backend/library-store.ts` canServe), but the client only ever requested `thumb@1` for image kinds. Also the plan gate: sounds need Saka or above; free and Katara accounts get none (correct, but the page did not say so near the sounds).
2. **N+1 signing.** After every result page `LibraryExplorer` fired one `POST /api/cyrus/library/v2/url` per visual card (up to 24) at once, then one `GET /file/<token>` each; nothing was lazy, nothing was cached between pages (going back re-signed everything).
3. **Cold derivatives.** The production object store held 24 files (1.1 MB) for 62,777 catalogue rows (read-only check by the reconciliation pass); every first view of an asset runs a PIL/ffmpeg derivation from `/tank/cyrus-library-staging` (single HDD). No pre-warm was ever run (CC section E).
4. **Whole-catalogue ranking per page.** With no search text, `lib/cyrus/library/backend/pg.ts` search ranks every published row (62,444) through two window functions (`MAX() OVER ()`, `ROW_NUMBER() OVER (PARTITION BY group)`), a jsonb `games->minecraft->fit` lookup per row and a full sort, then `COUNT(*)` over the same set, on EVERY page open and every Previous/Next; `cache-control: no-store`. Benchmark on the real catalogue: see `ux-audit-2026-10-18/bench.txt` (numbers in section 1.6 when the run finished; the earlier CC bench measured 23-320 ms medians and 935 ms max for TEXT queries on an idle node; the empty query is the heaviest case and the default view).
5. **Two library pages.** `/app/library` (search + thumbnails) and `/app/library/browse` (Game > Type > Category taxonomy, server-rendered, NO images, NO audio, raw kind slugs like `particle-texture`, unstyled `<style>` block). They barely link to each other; the rail linked only the first, the top bar neither.
6. **Structure.** Kind is a dropdown of 14 internal kinds; no sort (no "New", no "Popular"); no category tree on the search page; detail opens BELOW the grid (off-screen on a laptop); 24 per page, offset capped at 2000.

Fixed on the branch: 1 (player), 2 (batch + lazy + cache), 4 partially (60 s cache, private max-age 30), 5/6 partially (chips, URL state, link to the category view, plain words). Open: pre-warm (3), merged page with the taxonomy, sort, waveform, drawer (bundle C).

### 1.5 Studios and mod page (what is confusing)

- Every studio page has its own header that repeats the brand, crumbs, a studio switcher, two asset links ("Mod assets", "My assets"), tokens and a theme button: 9 controls before the canvas. With the new single Cyrus bar above it, the studio header should keep only the breadcrumb + studio switcher (bundle C).
- The mod preview panel tabs (Code / Explain / Files / Versions / Assets / Notes) lead with Code: newcomers land on Java source. Explain should be first (bundle C).
- 14 studio routes exist (`texture, sound, model, model-editor, mesh, motion, config, items, menus, bosses, datapacks, rooms, library, plans`), reachable through different doors (preview panel, Forge parts fan, studio switcher shows only 4). No single "Studios" index per mod.
- Plan screen: the default view shows model choice, build route, lanes and warnings at once (PlanSheet); the owner's warn-don't-block rule means warnings stay, but they should be one sentence each with an "Details" disclosure.

### 1.6 Measurements

Filled from this round's runs (`ux-audit-2026-10-18/after-metrics.json`, `bench.txt`, `build-routes.txt`): see the table at the end of this file ("Appendix: numbers"). If a cell says "not measured", the run did not complete on the saturated build host; the reason is given there.

### 1.7 Ranked issue list

Severity: S1 = blocks or misleads most users, S2 = frequent friction, S3 = polish. Effort: XS < 2 h, S < 1 day, M 1-3 days, L > 3 days.

| # | Issue | Sev | Effort | Evidence | Proposed fix | Status |
|---|---|---|---|---|---|---|
| 1 | Three navigations for the same places (top bar + side rail + Simple/Studio on cyrus.my; back strip + rail on nxeon.cloud; studio hamburger repeating the top bar) | S1 | S | `before-2026-10-15/after-cy-home-d1440.png`, `after-cy-studio-d1440.png`, `after-nx-home-d1440.png` | one Cyrus top bar on both hosts, no rail, no hamburger, Map/List in the toolbar | FIXED on branch |
| 2 | Library sounds cannot be played | S1 | S | code (no audio element), `LibraryExplorer.tsx` | play/pause on sound cards via `preview-ogg@1` | FIXED on branch |
| 3 | Mods are PRIVATE by default and every community surface is behind OFF launch switches, so "nothing got done" from the user's view | S1 | M | `prisma/schema.prisma` CyrusModPage visibility default; CP prod counts | public-by-default with opt-out (bundle A) + launch switches (decision 2) | OPEN |
| 4 | In-portal community lives in the Nxeon NxLabs shell, not in Cyrus | S1 | M | `portal-fixture-shop-menu-1440.png` | Cyrus app Community section (bundle B) | OPEN |
| 5 | Library slow: N+1 signing, cold derivatives (24 files for 62,777 rows), whole-catalogue ranking per page | S1 | S (fixes) + M (pre-warm) | section 1.4, `bench.txt` | batch + lazy + cache (done); pre-warm job + `sort` + indexed default ordering (bundle C) | PARTLY FIXED |
| 6 | Nxeon chat bubble / promo popup / survey over Cyrus | S2 | XS | every before shot | HideOnCyrus + ChatWidget gate | FIXED |
| 7 | Nxeon error card and marketing 404 inside Cyrus | S2 | XS | `app/dashboard/error.tsx`, `app/not-found.tsx` | Cyrus `error.tsx` + `not-found.tsx` | FIXED |
| 8 | Jargon: Mod Forge/Core, auto-route, forge, held/settling, plan codes, "not switched on" | S2 | S | section 1.2 | plain words (done for the worst); glossary rule for new copy | PARTLY FIXED |
| 9 | Studio map dominated by 5 on-hold games x 3 "Coming soon" pills | S2 | S | `after-nx-studio-d1440.png` | collapse on-hold games into ONE "More games soon" node; owner wanted coming-soon visible (memory), so this is decision 5 | OPEN |
| 10 | Two library pages, taxonomy page has no images/audio and raw kind slugs | S2 | M | `app/dashboard/cyrus/app/library/browse/page.tsx`, `components/cyrus/library/CatalogueBrowser.tsx` | one page with the tree (bundle C) | OPEN |
| 11 | No spotlight / trending / new-assets feed inside the app | S2 | M | reconciliation table | community home (bundle B) | OPEN |
| 12 | Remix copies only the jar (no project/revision, no source), so "iterate on it" is shallow | S2 | M | `lib/actions-cyrus-community.ts` remixCyrusMod | full fork (bundle A) | OPEN |
| 13 | Studio pages repeat a 9-control header under the app bar | S2 | S | `StudioShell.tsx` | keep crumb + studio switch only (bundle C) | OPEN |
| 14 | Breadcrumb "Minecraft" and category crumbs both go to the core | S3 | XS | `StudioShell.tsx` | link to the game / category view of the map (`?game=` / `?category=`) | OPEN |
| 15 | Mod panel opens on Code | S3 | XS | `PreviewPanel.tsx` TABS | Explain first | OPEN |
| 16 | Plan screen shows every control by default | S2 | M | `components/cyrus/prompt/PlanSheet.tsx` | two layers: checklist + Build; Details disclosure | OPEN |
| 17 | Phone: menu button + bottom tab bar + Simple/Studio + chat bubble over content | S2 | XS | `after-cy-home-m390.png` | one menu (done with #1 and #6) | FIXED |
| 18 | Mixed visual systems (studio violet glass, app black/hairline, studio pages `cys-*`, unreviewed skin) | S2 | L | L13 | pick one (decision 4), then a token pass | OPEN |
| 19 | Nxeon checkout/payment components in the Cyrus token purchase | S3 | M | L10 | restyle with a live payment test | OPEN |
| 20 | Community pages show "Every Cyrus mod ships with its source" (MIT) by default | S2 (privacy/legal) | S | `portal-fixture-shop-menu-1440.png` | source download opt-in under public-by-default (bundle A, decision 3) | OPEN |

## Part 2. Plan reconciliation

The short version: almost all of the community/library plan was BUILT and merged; none of the community part is LIVE; and the two things the owner wanted most (mods public by default, a community inside the Cyrus portal) were never built. Every community surface is behind an OFF launch switch, the in-portal pages live in the NxLabs shell, and new mods start PRIVATE.

Sources: CP-community-audit-2026-10-15, CV-library-taxonomy-2026-10-15, DB-cyrus-marketing-roadmap, DC-content-engine, CQ-seo-plan, MC-PAGES-PLAN-2026-10-17, W / J library notes, tracker. Production gates: Settings `cyrus_mods_public_enabled`, `cyrus_public_enabled`, `cyrus_studio_public_enabled`, `cyrus_install_published_enabled` absent (= OFF); `CYRUS_LIBRARY_AUTOPUBLISH`, `CYRUS_SITE_PRIMARY` not set; private beta = 2 accounts. Production rows (CP, 2026-10-15): 26 CyrusModPage (24 PRIVATE), CyrusModListing / Media / Star / Rating / Remix / Post / Report 0.

| Planned item | Status | Where / gate |
|---|---|---|
| Generated mod page per mod (versions, changelog, commands, gallery, icon, banner) | BUILT-NOT-LIVE | `lib/cyrus-mods/pages.ts` syncCyrusModPage; `app/(marketing)/mods/cyrus/[slug]`; cyrus.my `app/(cyrus-web)/cyrus-web/mods/[slug]`; gate `cyrus_mods_public_enabled` |
| Mods public BY DEFAULT, owner opts out | NOT BUILT | CyrusModPage `visibility @default("PRIVATE")`; pages.ts create sets none; only the manual toggle `setCyrusPageVisibility` (`lib/actions-cyrus-mods.ts`) |
| Assets of public mods published to the library by default + opt-out | BUILT-NOT-LIVE | `lib/cyrus/library/publish/*`, Settings `cyrus_library_optout:<user>` / `cyrus_library_optout_mod:<project>`, UI toggle on the project page; switch `CYRUS_LIBRARY_AUTOPUBLISH` (absent) |
| Public mod listing | BUILT-NOT-LIVE | `/mods/cyrus` (take 60, no paging), cyrus.my `/mods` (24/page, categories) |
| Featured mods (curated) | BUILT-NOT-LIVE | `lib/cyrus-mods/featured.ts`, Setting `cyrus_featured_pages` (empty), `/admin/cyrus/community` |
| Spotlight (mod of the week + staff picks) | BUILT-NOT-LIVE | `lib/cyrus-site/spotlight.ts`, Setting `cyrus_spotlight_picks` (empty), `/admin/cyrus/spotlight`; only on public pages, NOT in the customer app |
| Trending / popular | BUILT-NOT-LIVE (threshold list, not velocity) | spotlight.ts popularList, views `CyrusModViewDay`; Setting `cyrus_spotlight_popular_enabled` off |
| Live "new assets" feed | NOT BUILT | no polling/SSE in library or app code; browse has no newest sort |
| Community inside the portal | BUILT in the wrong shell | `/dashboard/nxlabs/cyrus/*` (Nxeon NxLabs chrome); the Cyrus app has no Community entry |
| Creator profile | BUILT-NOT-LIVE | `/mods/cyrus/u/[handle]`, `/dashboard/nxlabs/cyrus/u/[handle]`; indexable with >= 2 public mods |
| Author tag (username) | BUILT+LIVE | `lib/cyrus-mods/username*.ts`, gate in `app/dashboard/cyrus/layout.tsx` |
| Remix / import into my Cyrus with lineage | BUILT-NOT-LIVE, shallow | `lib/actions-cyrus-community.ts` remixCyrusMod: re-scan, copies the JAR into a new ModBuild for the importer, CyrusFork + CyrusRemix (parent, origin, depth), remixPolicy OPEN/CLOSED, 10/h; no CyrusProject/revision, no source tree; later changes build from the original's service build. Only for beta accounts + PUBLIC pages |
| "Add to my Cyrus" bookmark | BUILT-NOT-LIVE | CyrusLibraryItem pointer, max 60 |
| Stars / ratings (installers only) / threads / reports / takedown / collections | BUILT-NOT-LIVE | actions-cyrus-community.ts, actions-cyrus-mods.ts; admin queues live for staff (`/admin/cyrus/community`, `/admin/cyrus-mods`), no data |
| Install someone else's published mod | BUILT-NOT-LIVE | Setting `cyrus_install_published_enabled` |
| Account-level asset library | BUILT+LIVE (thin) | `/dashboard/cyrus/app/library` + `/library/browse` + `/library/a/[id]` |
| Sound preview in the library | NOT BUILT in UI (backend ready) -> FIXED on this branch | `preview-ogg@1` |
| Waveforms in the library | NOT BUILT | only Sound Studio / build screen |
| /gallery ("Made with Cyrus") | NOT BUILT | MC-PAGES #6 |
| Per-mod OG image | NOT BUILT | `lib/cyrus-mods/seo.ts` uses banner/photo/icon/game hero |
| One canonical public page on cyrus.my | BUILT-NOT-LIVE | canonical nxeon.cloud/mods/cyrus/<slug> unless `CYRUS_SITE_PRIMARY=1` |
| Profile redirect after a username change | NOT BUILT | old handle 404s |

Model -> code map (CyrusMod* tables in production): CyrusModPage (pages.ts, featured.ts, social.ts, spotlight.ts, admin takedown), CyrusModListing (saveModListing, remixPolicy), CyrusModMedia (`app/api/nxlabs/cyrus/[slug]/media`, serving `app/api/nxlabs/cyrus/media/[id]`), CyrusModPost + CyrusModReport (threads, `lib/actions-cyrus-mods.ts`), CyrusCommunityReport (page/media/collection/profile reports, `/admin/cyrus-mods`), CyrusModStar, CyrusModRating, CyrusRemix + CyrusFork (remix), CyrusLibraryItem (bookmark), CyrusCreator (+ CyrusUsernameHold), CyrusCollection(+Item), CyrusModViewDay (views). NOTE: **CyrusModSignal is NOT a community table**: it is lifecycle health (BROKEN / CRASH_LOOP / AUTO_DISABLED / RECOVERED) written by `worker/cyrus-lifecycle.ts` and `worker/cyrus-perf-watch.ts`.

## Part 2b. Target design

### (a) One navigation model

Rule: **one Cyrus top bar on every logged-in Cyrus screen, both hosts. No side rail, no second menu.** A top bar (not a rail) because the studio is a full-bleed canvas and already has a toolbar row; a rail would take 232 px from the map.

```
nxeon.cloud  [< Back to Nxeon]  CYRUS  Home Studio New-mod Projects Library My-assets Servers Wallet Help   [tokens] [name] [Sign out]
cyrus.my                        CYRUS  Home Studio New-mod Projects Library My-assets Servers Wallet Help   [tokens] [name] [Sign out]
< 1100 px    [<]                CYRUS                                                                       [tokens] [menu]
```
- The Nxeon rail + top bar already step aside on `/dashboard/cyrus` (Shell `fullScreen`); the Cyrus bar replaces the back strip and carries ONE "Back to Nxeon" chip (portal only; cyrus.my never links to Nxeon, owner 2026-10-15).
- A second row only where it is not navigation: the studio toolbar (breadcrumb Core > Minecraft > Category > Mod, Add game, Jump to (Ctrl K), Map/List, sound, panel). The breadcrumb is the studio's navigation; no hamburger.
- Studio pages: Cyrus bar + one row with the breadcrumb (ending "Back to <mod>") and the studio switcher; the asset links, tokens and theme move to the bar.
- Community gets a bar entry "Community" when launched (no dead links before that).
- Phone: the bar folds into one menu (Esc / outside click / focus return / 46 px rows exist). No bottom tab bar on top of it.
Shipped on this branch (Part 3 item 1); studio-page header trim is bundle C.

### (b) Calm, guided default

1. **Home = one prompt.** "Describe your mod", game/version defaulting to the newest supported Minecraft, cost in words ("about 1,200 tokens, you have 8,000"), then your last 3 mods, then "Popular in the community". Nothing else above the fold; the stat tiles move below.
2. **The map is the advanced view.** New accounts land on Home; Studio (Map) is one click and remembers Map/List (already saved to the profile).
3. **Plan screen in two layers.** Default: "Cyrus will build" checklist + one "Build it" button + cost. Lanes, perf classes, capability gaps, model choice under "Details" (closed). Warnings stay visible as one sentence each with the consequence (warn, don't block).
4. **Words.** Customer-facing replacements (apply to all new copy; a copy ratchet test like `cyrus-copy-r50` should ban the left column in customer files):

| Internal | Customer |
|---|---|
| held / hold / reserve | set aside (returned if the build fails) |
| Katara / Saka / Yakko | keep as brand names only with a subtitle: Katara (fast), Saka (balanced), Yakko (most capable) (decision 1) |
| lane, lane gaps | what Cyrus can build for this game / not supported yet |
| Test Flight, "Not flown" | Test Flight (a real test-server boot) / "Not tested yet" |
| CC0 / proprietary-nxeon tiers | Free to use / Credit required / Cyrus sound library |
| Mod Forge, Core | Studio |
| switched on / flags | available / not available yet |

5. **Advanced controls tucked away**: designer numeric params, perf caps, raw config JSON, version retargeting behind a per-screen "Advanced" disclosure; never removed.
6. **First-run checklist** on Home (connect a server or skip, build your first mod, install it) instead of the modal tour; progress saved to the profile.

### (c) Community system

Principle: every mod made with Cyrus is public by default; the creator can opt out at creation and later; private things are never shown.

Defaults and opt-out:
- New `CyrusCreator.defaultVisibility` (PUBLIC | PRIVATE, default PUBLIC). New mod screen: "Share this mod with the community" switch, ON, one line on what is shown + link to the rules. `syncCyrusModPage` creates the page with the creator's default (today: PRIVATE). The 24 existing private pages are NOT flipped (they were made under "private by default"; decision 2).
- Later: mod settings "Visible to: Everyone / Only me" (exists), account "New mods are public by default", "Let people remix this mod" (`remixPolicy`, exists), "Publish source code" (default OFF under public-by-default; decision 3), "Show my prompt" (default OFF).

Shown publicly (WHITELIST): name, tagline, generated + creator description, author tag (never account name/email), game + versions, category, commands + permissions, config KEYS with defaults except keys marked private, creator media, versions + changelog, Test Flight verdict + date (no logs), installs, stars, rating (installers), remix count + lineage.
Never shown: prompts / chat history (unless opted in), source (unless opted in), any secret (API keys, webhook URLs, passwords, tokens: redacted by key-name AND value-pattern scan even when not marked), config values marked private, server names/IPs, build logs, tokens/cost, email/account name.
Legal (tracker rules): community library contributions CC0 only; nothing game-derived (vanilla textures/sounds), third-party or imported code is re-published; GPL/ARR never copied; vanilla zips and the Modrinth corpus stay private reference. A mod containing such material can have a public page, but its assets are not published to the library and its source download stays off.

Pages and data contract (the marketing-overhaul agent owns the public shell; this is the content contract it links to):
- Public page: canonical `https://cyrus.my/mods/<slug>` (flip `CYRUS_SITE_PRIMARY=1` at launch; nxeon.cloud copy canonicals/301s to it). SEO: title, description, generated per-mod OG image (icon + name + game on the brand plate), JSON-LD SoftwareApplication + BreadcrumbList + Person author, sitemap when public and not thin.
- Reader `readPublicModPage(slug)` (server) and `GET /api/cyrus/mods/<slug>/public` return exactly:
  `{ slug, title, tagline, description, author: { tag, profileUrl }, game: { id, label, versions[] }, category, media: { icon, banner, gallery[] }, commands[], permissions[], configPublic: { key, default, description }[], versions: { version, date, changelog }[], testFlight: { verdict, at } | null, stats: { installs, stars, rating, ratingCount, remixes }, lineage: { parent?, origin?, depth }, remixPolicy, sourceAvailable, licence, canonical, updatedAt }`.
  A contract test asserts no other field is ever present and runs a secret-pattern scan over the payload.
- In-portal page (Cyrus app, not NxLabs): `/dashboard/cyrus/app/community/<slug>` (cyrus.my `/community/<slug>`): same data + Remix into my Cyrus, Install on my server, Star, Rate, Report, Discuss; on your own mod also Edit listing, Visibility, Remix policy.
- Community home in the app: Spotlight (staff picks + mod of the week, exists), Trending (velocity: installs + stars + remixes in 7 days, age-weighted; empty data says "New"), New mods, New assets (live feed), Following (later).
- Remix into my Cyrus = full fork: new CyrusProject + revision from the source's latest revision (spec, assets, config with private values blanked, source tree when the original's source is public; otherwise jar + spec and the next change builds from the spec), title "<name> (remix)", CyrusRemix parent/origin/depth, "Remixed from <mod> by <author>" on both pages + remix tree; respects remixPolicy CLOSED; the remix follows the importer's default visibility but always credits the chain.
- Live new-assets feed: library entries `source=contribution` / Made with Cyrus sorted by createdAt; `GET /api/cyrus/library/v2/browse?sort=new&limit=12` cached 15 s server side, the card polls every 30 s (SSE later). Needs `CYRUS_LIBRARY_AUTOPUBLISH=1`.
- Moderation hooks: auto-hide at N reports (exists), admin queues (exist), new account's first public mod held for an automated scan (guard + secret scanner) before listing, rate limits on stars/ratings/remixes (exist), suspended creators cannot publish (exists).

### (d) Asset library restructure

```
[ Search sounds, textures, models...                        ]  [Sort: Best match | New | Popular]
[Everything] [Sounds] [Music] [Textures] [Sprites] [Models] [Particles] ...  (locked kinds greyed: "needs Saka")
Left: Game > Type > Category tree with counts (collapsible)      Right: grid
  Sound card: play/pause, waveform (precomputed peaks), duration, licence chip
  Image card: lazy thumbnail (one signed batch per page, cached), pixelated for 16 px art
  Model card: rendered thumbnail (new recipe) or the PBR preview
"Load more" + virtualised list after 200 rows; URL holds q / kind / category / sort / page
Detail drawer on the right: big preview / player, licence, credit, Used in mods, Use in a project (pick one), Report
```
Server: `sort=new|popular`; an index-friendly default order for the empty query (pre-ranked `quality` + fit column so the first page is an index scan, not a window over 62k rows); `peaks@1` derivative (200-point JSON) next to `preview-ogg@1`; a pre-warm job for thumb@1 + preview-ogg@1 + peaks@1 over the published catalogue (night, rate-limited, on the store disk); a headless model-thumbnail recipe for the ~10k model rows without a sibling image.

## Part 3. Quick wins on the branch (commits on `feature/cyrus-ux-audit`)

| Commit | What |
|---|---|
| e6ce7e77 | One navigation: host-aware Cyrus bar on both hosts (CyrusPortalBar in the portal with "Back to Nxeon"), customer app without rail / tab bar / Simple-Studio switch, studio without the hamburger (Map/List toggle in the toolbar); removed AppNav, StudioNav, lib/cyrus/studio-nav.ts; tests updated |
| 2202bcfa | Nxeon promo popup, acquisition survey and live chat kept off `/dashboard/cyrus*` (`lib/cyrus/surface.ts`, `HideOnCyrus`) |
| 0b67b0b8 | Live chat also hidden wherever the Cyrus chrome is on the page (cyrus.my short paths) |
| 68723eae | Library: playable sounds, kind chips, URL state, batched + lazy + cached thumbnail signing (`POST /url {ids}`), 60 s browse cache |
| 08348b97 | Tests: batch signing, cache key, surface gate, player ratchet |
| e7b585c9 | Cyrus `error.tsx` + `not-found.tsx` (were the Nxeon card and the marketing 404) |
| c8c2eca6 | Plain words for token holds and locked models |
| def4fe54 | Studio copy: Mod Forge -> Studio, auto-route and forge hints |
| cc96a681 | docs/cyrus 04 + 06 |

Before / after shots: `ux-audit-2026-10-18/before-2026-10-15/*` and `before-*.png` vs `after-*.png` (same page names). Not touched: Structure Studio page, `AssetsTab.tsx`, marketing pages, login/register.

## Bundles for build agents (ready to hand over)

**Bundle A: Public by default + full remix (Opus, M-L).** `CyrusCreator.defaultVisibility` (additive column, default PUBLIC) + New mod switch + account setting; `syncCyrusModPage` uses it; whitelist reader `readPublicModPage` + `/api/cyrus/mods/<slug>/public` + contract test + secret scanner; source download and prompt display opt-in; remix as a full fork (CyrusProject + revision, private config blanked, lineage chain on both pages); per-mod OG image; `CYRUS_SITE_PRIMARY` canonical plan. Files: `lib/cyrus-mods/pages.ts`, `lib/actions-cyrus-community.ts`, `lib/cyrus-mods/seo.ts`, `components/cyrus/app/NewModFlow.tsx`, prisma (additive). Do not flip any setting.

**Bundle B: Community inside the Cyrus app (Opus, M).** `/dashboard/cyrus/app/community` (home: Spotlight, Trending velocity, New mods, New assets live feed with 30 s polling) and `/community/<slug>` (cyrus.my short paths) rendering the bundle-A contract in the Cyrus look, with Remix / Install / Star / Rate / Report / Discuss; Community link in the Cyrus bar behind the launch setting; NxLabs Cyrus pages redirect into it; `sort=new` on browse for the feed. Reuse spotlight.ts, featured.ts, social.ts. Coordinate the public shell with the marketing agent.

**Bundle C: Library + studio calm-down (Sonnet for the library, S-M each).** One library page with the taxonomy tree, `sort=new|popular`, detail drawer, Load more/virtualisation, `peaks@1` waveform recipe + waveform on sound cards, pre-warm script (owner runs), index-friendly empty-query order; studio pages keep only breadcrumb + studio switcher (StudioShell), crumbs link to game/category views, Explain-first preview tabs, plan screen two-layer view, copy ratchet test banning the internal words list. (Not the Structure Studio page / AssetsTab.tsx while their owners are active.)

## Owner decisions

1. Plan names Katara / Saka / Yakko: keep (with plain subtitles everywhere) or rename to Fast / Balanced / Most capable.
2. Public by default for NEW mods only (recommended) or also flip the 24 existing private pages; and when to set the launch switches (`cyrus_mods_public_enabled`, `cyrus_public_enabled`, `cyrus_install_published_enabled`, `CYRUS_LIBRARY_AUTOPUBLISH`, `CYRUS_SITE_PRIMARY`).
3. Source code of public mods: opt-in (recommended under public-by-default) or keep "every mod ships with its source" (MIT).
4. One visual system for Cyrus: the customer-app look (black + hairlines, recommended, closest to cyrus.my) vs the studio violet glass vs the unreviewed `CYRUS_STUDIO_SKIN`.
5. Studio map: collapse the 5 on-hold games into one "More games soon" node (recommended) or keep each with "Coming soon".
6. Nxeon email-verify and announcement banners on Cyrus screens: keep as they are, restyle in the Cyrus look, or show inside the Cyrus bar.
7. Library pre-warm (disk + CPU on the primary's tank HDD; ~37 KB per thumbnail, ~90 KB per audio preview): run it, and when.

## Appendix: numbers

(see below, appended after the runs)

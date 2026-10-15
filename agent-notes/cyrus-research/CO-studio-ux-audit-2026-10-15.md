# CO: Cyrus core studio UX audit + implementation (2026-10-15)

Branch `feature/cyrus-studio-ux` (worktree `/tank/dev-worktrees/cyrus-studio-ux`, from main 89608a9f). NOT merged, NOT deployed.
Screenshots: `/root/cyrus-studio-ux-shots/before/` and `/root/cyrus-studio-ux-shots/after/` (names `<tag>-<host>-<page>-<view>.png`,
host `nx` = nxeon.cloud/dashboard/cyrus, `cy` = cyrus.my; view `d1440` 1440x900, `d1280` 1280x720, `m390` 390x844).
Fixtures: `scripts/cyrus/studio-fixtures.ts` on a devhost throwaway DB, `scripts/cyrus/studio-ux-shots.mjs` (new; prints a cut-off diagnosis per shot).

## STEP 1 audit (state of main before this work)

| # | Owner item | Status | Evidence |
|---|---|---|---|
| 1 | Individual mod branches draggable, positions saved to the profile for all branches, load more per category | PARTIAL | Game and category nodes already drag and persist (`components/cyrus/cosmos/Network.tsx` onNodeDown/onStageUp, `lib/cyrus/store.ts` `layout` + `setNodeHome`). BUT: mod pills were NOT individually draggable (`onNodeDown` redirected a pill grab to its category: "grabbing one drags the whole list"); positions persisted only in the browser (zustand persist, localStorage `cyrus-state-v1:<userId>`), never in the profile; "+N more" only opened the panel, no paging (`graph.ts` fixed `VISIBLE_MODS = 3`). |
| 2 | Black bg, very faint stars + shooting stars, cyrus.my only | PARTIAL | `CosmosBackground.tsx` already drew stars and one shooting star every 25-55 s, but on top of a WebGL aurora and a violet-navy radial gradient (`studio.css .cosmos`), for BOTH hosts, tinted stars up to alpha 0.7, no `prefers-reduced-motion`, no tab-hidden stop. Shot: `before/before-nx-studio-d1440.png`. |
| 3 | Portal pages cut off at the bottom | BUG (missing) | Customer-app pages (`/dashboard/cyrus/app/*`, cyrus.my `/home /projects /new /assets /servers /wallet /account`) are clipped. Diagnosis (`before-nx-home-d1440`: last element bottom 1409 px vs visible 900 px = 509 px clipped, 0 user scrollers). Root cause: `.cyrus-root` (studio.css) is `height:100%; overflow:hidden; contain: layout paint; container-type:size` because the studio canvas fills it, and the customer app (`.cx-app`, app.css) only had `min-height:100%`, so it grew past the box and nothing could scroll. The portal frame is `.nx-appframe overflow-hidden` (nx Shell) on Nxeon and `h-dvh flex-col` on cyrus.my, so both hosts clip. The rail (`height:100dvh`) also cut off its account row (visible in `before-nx-home-d1440.png`, user name cut at the bottom edge). The studio canvas itself is NOT cut off (1440x900 and 1280x720 fit). |
| 4 | Switch to Simple mode in the core studio | PARTIAL | Simple/Studio segmented switch existed only above the customer app pages (`app/dashboard/cyrus/app/layout.tsx .cx-modebar`, links, not a preference). Nothing in the core studio; no per-user persistence. |
| 5 | Proper nav menu in the studio + back to portal | PARTIAL | Nxeon host: only the 36 px `CyrusBackBar` strip ("Back to Nxeon"; `components/nx/CyrusTopEntry.tsx`). cyrus.my: `CyrusHostShell` bar with My servers / Wallet / Back to Nxeon (hidden below md). No menu inside the studio to Projects, Assets, Account, Help; no route from the studio to Cyrus home. |
| 6 | Own Cyrus skin instead of the recycled Nxeon look, both hosts | PARTIAL | `studio.css` is the handoff's violet glass + aurora + glow system (blur panels, rainbow prompt border, violet tints) with the Nexion `nx-dark-island` frame; the customer app (`app.css`) already uses the landing language (`--cx-*`: black, hairlines, blue/violet energy). The studio and the host bar were the inherited part. |
| a | (new) Stale Nxeon preloader on Cyrus pages | BUG | `app/dashboard/loading.tsx` renders `components/nx/Preloader` (the Nxeon NX mark) for every `/dashboard/*` segment, and cyrus.my rewrites `/studio`, `/home`... to `/dashboard/cyrus/*`, so it showed on every Cyrus route on both hosts. |
| b | (new) No "Back to Nxeon" on cyrus.my | BUG | `CyrusHostShell` header link (md and up). |
| c | (new) Nav bars of portal / landing look poor | PARTIAL | cyrus.my host bar was an unstyled flex row (links dropped below md, no menu); landing nav hid "Sign in" on phones (`.nav-cta .btn:not(.btn-solid){display:none}`), no Esc / outside click / current-section state. |

## STEP 2 what changed (all in this branch)

Order followed: 3, 5, 4, 1, 2, 6, then the new asks a, b, c.

- **3 cut-off pages.** `app/dashboard/cyrus/app/app.css`: `.cx-app` is its own scroll container (`height:100%; overflow-y:auto; overscroll-behavior:contain`), rail `height:100cqh` + own overflow, aura `position:fixed`, phone tab bar stays sticky at the bottom (`.cx-main flex:1 0 auto`). Tour root variant unchanged. After (`after-nx-home-d1440`): 0 px clipped, 1 user scroller; `after-nx-home-m390` same. Pure CSS, default on.
- **5 menu + back.** `components/cyrus/chrome/StudioNav.tsx` + pure `lib/cyrus/studio-nav.ts`: hamburger in the studio top bar; view switch, Home / New mod / Projects / My assets / Servers / Wallet / Account / Help (host-aware; app links only when `CYRUS_CUSTOMER_APP=1`), way back = "Back to the Nxeon portal" (last portal page, never the studio) on Nxeon, "Back to Cyrus home" on cyrus.my. Esc closes, outside click closes, focus returns to the button.
- **4 simple mode.** Same menu: Studio / Simple. `components/cyrus/chrome/SimpleView.tsx` replaces only the constellation canvas with a grouped list of the same mods; prompt dock, preview panel, palette, tokens, builds, installs unchanged. Saved per user (below).
- **1 drag + load more + profile.** Mod pills drag individually (offset from the list slot, same `layout` map and key = node id as games/categories); "+N more" loads the next 6 mods onto the branch (`more` map, cap 120); palette "Reset branch positions" clears. Saved to the profile: new additive table `CyrusStudioPref` (`prisma/manual-migrations/2026-10-15-cyrus-studio-prefs.sql`, NOT applied), route `app/api/cyrus/studio-prefs` (GET / POST patch, same gate, same-origin, capped, GDPR export/erase registered), client `lib/cyrus/studio-prefs/client.ts` (server copy wins; none yet = browser copy is the first profile version; debounced diff patch). Until the table exists the route reports `saved:false` and localStorage keeps working.
- **2 starfield (cyrus.my only).** `components/cyrus/cosmos/Starfield.tsx` (+ pure `starfield.ts`): black, <= 240 stars at alpha 0.05-0.26, a shooting star every 20-50 s, canvas 2D at 24 fps, stops while the tab is hidden, no loop and no twinkle under `prefers-reduced-motion`. Chosen by the host context only `CyrusHostShell` provides; the Nxeon-hosted studio keeps the aurora. While it shows the studio is forced dark.
- **6 skin.** `app/dashboard/cyrus/ux.css` section 3: `.cyrus-root[data-cy-skin="cyrus"]` re-points the studio's own tokens to the landing language (black/white hairlines, blue to violet only on primary actions, Space Grotesk display, no blur / aurora / glow, short ease-out motion), `.cyrus-host[data-cy-skin]` for the cyrus.my bar, `:root:has(.cyrus-root[data-cy-skin])` for the shell's back strip. OFF until reviewed: `CYRUS_STUDIO_SKIN=1` (everyone) or `?skin=cyrus` / `?skin=nxeon` per browser (`SkinSwitch`). Ratchet test keeps every rule scoped; nothing outside `.cyrus-root` / `.cyrus-host` / `:root:has()` changes, so Nxeon portal, admin and marketing are untouched.
- **a preloader.** `app/dashboard/cyrus/loading.tsx` (nearer than `app/dashboard/loading.tsx`) renders `components/cyrus/CyrusPreloader.tsx`: Cyrus mark + a thin blue-violet sweep line, CSS only, invisible for the first 180 ms (no flash), static under reduced motion, `role=status` with sr-only label, replaced the moment the page streams in. Landing (`apps/cyrus-site/src/index.html`): inline preloader with the Y mark, removed on `load` or after 2.5 s at the latest, `<noscript>` hides it, reduced-motion static.
- **b no Back to Nxeon on cyrus.my.** Removed from the host bar and from the studio menu; kept only on the Nxeon-hosted Cyrus (`CyrusBackBar`). Test pins "no nxeon link in HostBar / host-nav / cyrus.my menu".
- **c nav bars.** cyrus.my: new `components/cyrus/host-shell/HostBar.tsx` (+ pure `lib/cyrus/host-nav.ts`): wordmark, Home / Studio / New mod / Projects / Assets / Servers / Wallet / Help, active state, token chip, account, sign out; below 900 px a menu button (`aria-expanded`, Esc, outside click, 46 px rows). Landing: menu panel now includes Sign in, Esc / outside click / resize close, `aria-current` section highlight, focus rings, `aria-label` toggles.

## Verification

- `devhost test test/cyrus-studio-ux.test.ts test/cyrus-qa-polish.test.ts test/cyrus-bridge-routing.test.ts test/cyrus-admin-r40.test.ts test/cyrus-portals-routing.test.ts`: pass (two older assertions updated on purpose: the host bar moved to HostBar, and "one Back to Nxeon" became "none").
- `devhost run --lock -- npx tsc --noEmit` (NODE_OPTIONS 6144): clean.
- `devhost run --lock -- npx next build` OK; screenshots taken against `next start` behind the TLS front (`test/e2e/qa-tls-proxy.mjs`, `https://cyrus.my:5108`, `__Host-cyrus_session`) so the cyrus.my host runs as in production (next dev does not carry the host marker reliably; do not use it for cyrus.my shots).
- Cut-off diagnosis (px of the last element hidden below what any ancestor lets the user see):
  - before: nx home 1440 = 509 px clipped, 0 scrollers (`before/before-nx-home-d1440.png`); the other 8 app pages show the same clipping in their `before-nx-*-d1440.png`.
  - after: nx home 1440 / 390, cy home 1440 / 390, cy projects 1440 = 0 px clipped, 1 user scroller; studio canvas 1440x900, 1280x720, 390 = 0 (never clipped).
- After shots: `after-nx-studio-d1440/d1280`, `after-nx-home-d1440/m390`, `after-cy-landing-d1440/m390(-menu)`, `after-cy-studio-d1440/d1280/m390(-menu)`, `after-cy-home-d1440/m390(-menu)`, `after-cy-projects-d1440`.
- Not captured (honest gaps): before shots for the cyrus.my host (node-2 was saturated, load 20, dev server OOM-killed twice; the cut-off is the same CSS on both hosts); light theme shots; the studio's Simple view and a dragged mod pill (logic covered by tests, interaction not screenshot); the skin ON (flag default off) was not screenshotted; the CyrusPreloader was not caught on screen (it is invisible for the first 180 ms by design; only covered by a source ratchet); after-nx-studio-d1440 was taken mid-bloom on a slow host (the cy shot, taken 8 s in, shows the settled map).
- Nothing was exercised against a real DB migration: `CyrusStudioPref` exists only in the throwaway DB (`db push`); the API fails soft without it.

## What remains / next

- Owner review of the skin (`?skin=cyrus` on staging), then decide the flag.
- Real-browser check of drag + Load more + profile round-trip on staging after the SQL is applied.
- The Nxeon floating chat bubble still sits over the Cyrus studio on nxeon.cloud (not in scope; it is the portal's support widget).
- Landing republish (owner step).

## Owner commands (nothing deployed)

1. Review, then merge `feature/cyrus-studio-ux` into the Cyrus integration branch.
2. Apply `prisma/manual-migrations/2026-10-15-cyrus-studio-prefs.sql` with the other pending Cyrus SQL (additive; rollback `DROP TABLE "CyrusStudioPref"`). Schema block is in `prisma/schema.prisma` (`CyrusStudioPref`), `db push` on staging only.
3. Skin: after review set `CYRUS_STUDIO_SKIN=1` (default OFF). Preview with `?skin=cyrus`.
4. Landing: `apps/cyrus-site/src` changed (preloader, nav); republish with `apps/cyrus-site/publish.sh` (owner step, NOT run).
5. Portal promote only via the normal staging then `scripts/promote-production.sh` path.

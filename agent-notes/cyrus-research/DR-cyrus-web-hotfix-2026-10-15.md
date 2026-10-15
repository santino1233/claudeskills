# DR: cyrus.my web hotfix (2026-10-15)

Branch `fix/cyrus-web-origin-marketing-session` (worktree `/tank/dev-worktrees/cyrus-hotfix-web`), from main 84d5be2f (= rc18 =
live release 20261015T194213Z-84d5be2f per the brief). Not pushed, not deployed, no production writes, nothing under /opt/nxeon edited.
All live observations below are read-only GETs / file reads made on 2026-10-15.

## Problem 1: "cross-site" on "Welcome to Cyrus: choose your username"

**Root cause (confirmed).** `app/api/cyrus/username/route.ts` POST:
`if (origin && origin !== new URL(req.url).origin) return json(403, { error: "cross-site" })`. Production runs
`node .next/standalone/server.js` with `PORT=3000` and **no `HOSTNAME`** in `/opt/nxeon/.env`, so Next's standalone server binds to
`0.0.0.0:3000` and builds `req.url` as `https://0.0.0.0:3000/...` (scheme from X-Forwarded-Proto). The browser's Origin is
`https://cyrus.my` (or `https://nxeon.cloud`), so the comparison can never succeed: every POST is refused, on BOTH hosts.
Evidence: `lib/public-origin.ts` documents the identical failure for redirects (2026-10-04 email-verification incident,
`https://0.0.0.0:3000` links); nginx (`/etc/nginx/sites-enabled/cyrus-my`, `nxeon-cloud`) proxies to `upstream nxeon_web { server 127.0.0.1:3000; }`
with `Host $host` and does not rewrite the request line. `UsernameGate.tsx` prints `message ?? error`, hence the raw word `cross-site`.

Same bug, same line, in `app/api/cyrus/studio-prefs` (layout saves silently fell back to localStorage), `notifications` (mark-read
failed) and `report` (Report a problem refused).

**Fix.** `lib/cyrus-bridge/same-origin.ts`:
- no Origin -> allowed (existing semantics; cookies are SameSite=Lax);
- Origin must equal the request's public origin (`requestOrigin()`, the repo's existing helper: X-Forwarded-Host / Host +
  X-Forwarded-Proto, internal bind addresses fall back to APP_URL) **or** a configured Cyrus origin: `APP_URL` (Nxeon portal, which
  serves the studio at /dashboard/cyrus), `CYRUS_ORIGIN`, every `CYRUS_HOSTS` entry over https (default cyrus.my, www.cyrus.my);
- `null`, malformed, path-bearing, `http://` variants and look-alike hosts are refused; the allowed set is never derived from the Origin.
- 403 body keeps `error: "cross-site"` and adds `message` ("This request did not come from a Cyrus page. Reload the page and try again.").
All four routes call `if (!cyrusSameOrigin(req)) return crossSiteResponse();`.

**Whole-app grep** (`new URL(req.url).origin`, `nextUrl.origin` comparisons, every `get("origin")`): only these four were wrong.
Reviewed and fine: `app/api/mail/rpc`, `app/nxm/api/_guard.ts`, `lib/chat/staff-auth.ts` (compare with Host / X-Forwarded-Host),
`lib/cyrus-bridge/server.ts sameOrigin` (configured origin), `app/api/platform/cyrus/grants` (appOrigin(); req.url only when not production),
`app/api/cyrus/analytics/hit` (host list). Redirect builders already use APP_URL / requestOrigin (`test/public-origin.test.ts`).

Tests `test/cyrus-same-origin.test.ts`: same-origin cyrus.my / www / nxeon.cloud pass; internal Host (bind address / loopback / none) with
the real Origin passes; bind-address Origin, evil, look-alike, http, `null`, path, empty fail; missing Origin passes; staging host only as
its own origin; trusted list; refusal body; a scan that no `app/` file compares an Origin with req.url; the four routes use the helper.

## Problem 2: "the marketing changes we made are missing" on cyrus.my

**What a visitor sees today.** `https://cyrus.my/` = the static file `/var/www/cyrus.my/index.html` (sha256 of the live response equals the
file). `/var/www/cyrus.my` is a symlink to `/var/www/cyrus.my-releases/20261014T111510Z-0d9c8d20`, `release.json`
`{"commit":"0d9c8d20","builtAt":"2026-10-14T11:15:10Z"}`: the landing as of 2026-10-14, BEFORE marketing v2 (feeaf535, merged into rc18
2026-10-15). Diff against `apps/cyrus-site/src`: live has the old sprite set (`assets/motion/*.webp`, `assets/mods/*.webp`, fx sheets), no
`assets/motion/v/*` / `assets/mods/v/*` loops, no `held.js` (live three.js "Your texture" card), no `a.js` (analytics beacon), and an
index.html 250 diff lines older (no plans cards + comparison table, no game-slot copy). `/games`, `/mods`, `/host`, `/blog`,
`/blog/rss.xml`, `/cyrus-web/*`: 404 with `X-Cyrus-Edge: denied` (the vhost's final `location /`), the app is never reached.
On nxeon.cloud `/cyrus-web/games|mods|blog` also 404 and `/api/cyrus/featured|spotlight` 404 = both public switches are off.

**What hides it (three independent layers, in request order).**
1. **Static landing not republished.** nginx serves `/` from the docroot (`location = / { try_files /index.html =404; }`); the app's own
   `/` on the Cyrus host only redirects to /studio. Merging/promoting the app never changes the landing: `apps/cyrus-site/publish.sh
   publish --go` has not been run since 0d9c8d20. **This alone is why the home page looks unchanged.**
2. **nginx vhost not updated.** The live app-path regex lacks `games|mods|host|blog` (repo `deploy/cyrus/nginx-cyrus-my.conf` had them
   since the content-engine merge; never applied). The live file also lacks the analytics-beacon block. `bash scripts/cyrus/nginx-cyrus-my-check.sh`
   today: UNEXPECTED rows `/games /mods /host /blog /blog/rss.xml` (+ the new www row).
3. **App switches off (fail closed, by design).** Even through nginx the pages 404 unless:
   `cyrus_content_public_enabled` (games, host, blog) / `cyrus_mods_public_enabled` (mods list + mod pages + spotlight), or a
   private-preview account (`isPreviewUser(.., "modbuilder")`). Indexing is separate: `cyrus_content_index_enabled` + env
   `CYRUS_SITEMAP_CONTENT=1` (content), env `CYRUS_SITEMAP_MOD_PAGES=1` (mod pages). The middleware is NOT the blocker: on the Cyrus
   host `webPath()` rewrites `/games` etc. to `/cyrus-web/...` already (lib/cyrus/web-paths.ts, lib/cyrus/bridge/routing.ts).

**Code-side changes.**
- `deploy/cyrus/nginx-cyrus-my.conf`: (already had) content roots + beacon block; (new) `www.cyrus.my` -> 301 `https://cyrus.my$request_uri`
  (cert SAN covers both; a host-only session cookie made a signed-in visitor look signed out on www, and www served a duplicate 200);
  `proxy_set_header X-Forwarded-Host $host` on all 6 proxy blocks. `.patch` regenerated against the live vhost (89 lines).
- `scripts/cyrus/nginx-cyrus-my-check.sh --syntax [FILE]`: real `nginx -t` of the file inside a throwaway main config (stub `nxeon_web`
  upstream + `nxeon_auth` zone, temp pid/log/temp paths, throwaway cert if the LE pair is unreadable). Result on the primary:
  `SYNTAX OK deploy/cyrus/nginx-cyrus-my.conf` (also OK for the live file; a deliberately broken copy -> `[emerg] unexpected "}"`, exit 1).
  The HTTP matrix also probes `/api/cyrus/session` and the www redirect.
- Landing (`apps/cyrus-site/src`): hidden `Mods` (/mods) and `Blog` (/blog) nav items, revealed only when `/api/cyrus/launch` returns
  `surfaces: { mods, content }` true (new field; the public switches only, preview access does not count; fails closed). `publish.sh check`
  accepts `/home`, `/mods`, `/blog`.
- Sitemap / robots: already designed (content pages need `cyrus_content_index_enabled` + `CYRUS_SITEMAP_CONTENT=1`; robots already
  allows them); no change needed.

## Problem 3: "Open Cyrus" for signed-in visitors

**How Nxeon does it.** `components/marketing/MarketingHeader.tsx` (client): optimistic read of the non-httpOnly `nxeon_authed` flag cookie,
then `fetch("/api/auth/status", { cache: "no-store" })` (`isSignedIn()`, JWT check, no DB). The nxeon.cloud cookies are host-scoped to
nxeon.cloud and invisible on cyrus.my; `/api/auth/status` is not routed on the Cyrus host (nginx + `CYRUS_APIS`).

**Caching facts (live).** Landing `/`: no Cache-Control, `cf-cache-status: DYNAMIC` (static file, but it cannot see cookies server-side at all).
App pages `/help`, `/plans`, `/sign-in`: `private, no-cache, no-store, max-age=0, must-revalidate`, `DYNAMIC`. So app-rendered pages can
safely render from the session; the static landing must probe client-side.

**Cookie scope.** cyrus.my has its own session (`__Host-cyrus_session`, host-only, minted by the SSO / Google callbacks in
`app/cyrus-host/auth/*`). Sign-in lives on cyrus.my itself (`/sign-in` -> `/cyrus-host/sign-in`, Nxeon SSO hop or Google).

**Implementation.**
- `lib/cyrus/bridge/config.ts cyrusAuthedHintCookie()` = `__Host-cyrus_authed` (prod) / `cyrus_authed`: value `1`, not httpOnly, no
  identity, same lifetime, host-only. Set in `createCyrusSession`, cleared in `destroySession` (Cyrus branch).
- `GET /api/cyrus/session` -> `{ signedIn }` (host-aware `isSignedIn`), `private, no-store, max-age=0`, `Vary: Cookie`, noindex, no CORS;
  clears a stale hint. Reachable on cyrus.my with no nginx change (`api/cyrus` prefix; middleware `CYRUS_APIS`). Authz table row: public
  (exact allow-list updated on purpose).
- Landing: inline head script adds `html.is-authed` from the hint before first paint; header markup has `data-auth="out"` Sign in / Get started
  and `data-auth="in"` **Open Cyrus** (`/home`); CSS hides the inactive set (`display:none`, so it is out of the accessibility tree too);
  `main.js` probes `/api/cyrus/session` and toggles either way. No JS / no hint = signed-out header (correct default; worst case a
  signed-out -> signed-in swap for a session minted before this deploy, i.e. until the next sign-in or first probe).
- App pages (content layout, help layout): `components/cyrus/web/SiteAuthCta.tsx` from the request session (signed in: Open Cyrus;
  out: Sign in + Get started on the host's own `/sign-in` `/sign-up`, or `/login?next=` `/register?next=` on nxeon.cloud). No flash.
- Tests `test/cyrus-site-session.test.ts` (executes the real head script against cookie strings, header markup, CSS, probe, launch
  surfaces, hint name, set/clear in auth.ts, route headers, SiteAuthCta render both states and both hosts).

## Verification

All via `scripts/devhost` on node-2, one at a time, memory pressure checked first:
- `tsc --noEmit` (NODE_OPTIONS=--max-old-space-size=8192; the default 5120 heap OOMed): clean.
- Suites (18 files): cyrus-same-origin, cyrus-site-session, cyrus-nginx-vhost, cyrus-security-review (authz table), cyrus-site-landing,
  cyrus-site-links, public-origin, cyrus-bridge-routing, cyrus-content, cyrus-seo, cyrus-launch-check, cyrus-help-r50, cyrus-host-seam,
  cyrus-docs-coverage, cyrus-bridge-sso, cyrus-portals-routing, cyrus-customer-app, cyrus-page-gate: 258 pass; the one failure
  (docs-coverage flag note for the `cyrus_authed` cookie name) fixed and re-run green (48 pass, 1 skipped = nginx -t test, no nginx on node-2;
  run on the primary instead: SYNTAX OK).
- `scripts/cyrus/docs-build.ts` regenerated docs/cyrus/reference (pulled back with `scripts/devhost pull`).
- Note: the helper lives in `lib/cyrus-bridge/` (not `lib/cyrus/`) because the host-seam ratchet forbids new Nxeon imports under lib/cyrus.

## Owner steps (in order)

Needs BOTH a portal promote AND the nginx change AND a landing publish; the switches are a separate launch decision.

1. Merge `fix/cyrus-web-origin-marketing-session`, `scripts/deploy-staging.sh <ref>`, verify on staging (Welcome screen "Continue to Cyrus"
   saves; Studio layout persists), `scripts/promote-production.sh`. **This alone fixes Problem 1** (no nginx needed) and ships
   `/api/cyrus/session` + the launch `surfaces` field.
2. nginx (primary, as root), from the merged checkout:
   `bash scripts/cyrus/nginx-cyrus-my-check.sh --syntax` -> `cp /etc/nginx/sites-enabled/cyrus-my /root/cyrus-my.bak && cp deploy/cyrus/nginx-cyrus-my.conf /etc/nginx/sites-enabled/cyrus-my && nginx -t && systemctl reload nginx && bash scripts/cyrus/nginx-cyrus-my-check.sh --origin 127.0.0.1`.
   Rollback: `cp /root/cyrus-my.bak /etc/nginx/sites-enabled/cyrus-my && nginx -t && systemctl reload nginx`.
   Effect with switches OFF: `/games /mods /host /blog` become the app's own 404 (no `X-Cyrus-Edge` header) for everyone except preview
   accounts, who now see the pages on cyrus.my. `www.cyrus.my/*` 301s to the apex.
3. Landing: `apps/cyrus-site/publish.sh check && apps/cyrus-site/publish.sh publish` (dry run) then `publish --go`
   (optionally `CYRUS_SITE_HEALTH_URL=https://cyrus.my/ CYRUS_SITE_HEALTH_RESOLVE=cyrus.my:443:127.0.0.1`). **This is what makes
   marketing v2 visible on cyrus.my/** (plans block, motion loops, held item, signed-in header). Rollback: `publish.sh rollback --go`.
4. Launch switches (Admin > Settings; owner decision, not a fix):
   - `cyrus_content_public_enabled` = true -> `/games`, `/games/<id>`, `/host...`, `/blog...` visible to everyone; landing shows **Blog**.
     Shows the five launch blog posts, hosting pages built from live GamePlan / Node / Coupon data (no discount block: no coupon `CYRUS`).
   - `cyrus_mods_public_enabled` = true -> **everything published as a public mod becomes visible and indexable**: `/mods`, every
     `/mods/<slug>` page passing the quality bar, `/api/cyrus/spotlight`, `/api/cyrus/featured`, spotlight sections on /mods and
     /games/minecraft, and the landing's **Mods** link. It is the existing mods launch flag (it also opens the nxeon.cloud mods tree).
     Before flipping: seed / review real mods (`scripts/cyrus/seed-official-mods.ts`, dry run first) and Admin > Cyrus > Spotlight;
     with zero published mods the pages are thin. Do not flip it just to "make the marketing appear": the home page does not need it.
   - Indexing later: `cyrus_content_index_enabled` + env `CYRUS_SITEMAP_CONTENT=1`; mod pages in the sitemap: env `CYRUS_SITEMAP_MOD_PAGES=1`;
     then submit the sitemap. Landing featured mods (build time): `CYRUS_SITE_FEATURED_JSON=https://cyrus.my/api/cyrus/spotlight
     CYRUS_SITE_MODS_BASE=/mods` on the publish only after step 2 and the mods switch.

## Not done / limits

- Not deployed, not run in a browser against production; the landing header was checked by executing its head script in a test and by
  markup/CSS assertions, not by a screenshot.
- Existing cyrus.my sessions have no hint cookie until their next sign-in: they get the probe-corrected header (a brief swap), not a flash-free one.
- Optional root-cause hardening not done: `HOSTNAME`/`--hostname` cannot fix `req.url` to the public host (it is the bind address);
  the code must not use `req.url` for origin decisions, which the new test enforces under `app/`.

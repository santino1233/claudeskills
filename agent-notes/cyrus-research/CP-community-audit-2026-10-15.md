# CP: Cyrus community / username / library / admin audit (2026-10-15)

Branch `feature/cyrus-community` (worktree /tank/dev-worktrees/cyrus-community, from main 89608a9f). Nothing deployed, no production data written (read-only counts only).

## Production facts (read-only, 2026-10-15)
- Env names (/opt/nxeon/.env): CYRUS_LIBRARY_BACKEND=1, CYRUS_LIBRARY_BROWSE=1, CYRUS_LIBRARY_STORE=local, CYRUS_CUSTOMER_APP=1, CYRUS_API_V1=1, CYRUS_STORAGE=1, CYRUS_WALLET_PAY=1, CYRUS_DOMAIN_MODE=1, CYRUS_LIVE_ASSETS=1, CYRUS_GDPR_ERASE=1 (plus the studio switches in .env lines 91-138). CYRUS_NOTIFY is not set.
- DB Settings: `cyrus_mods_public_enabled` ABSENT (= OFF), `cyrus_public_enabled` ABSENT (= OFF), `cyrus_studio_public_enabled` ABSENT (= OFF), `preview_access_emails_modbuilder` = 2 emails (owner customer account + admin@nxeon.local). The launch pair is OFF; every public page 404s for non-preview viewers.
- Rows: CyrusModPage 26 (24 PRIVATE, 2 PUBLIC, 0 hidden), CyrusCatalogEntry 62,777, CyrusCatalogTerm 1,145,478, CyrusCreator 1, CyrusLibraryItem 0, CyrusModListing 0, CyrusModMedia 0, CyrusModStar 0, CyrusModRating 0, CyrusRemix 0, CyrusModPost 0, CyrusModReport 0.
  The community layer is built but EMPTY in production: no listing text, pictures, ratings, remixes or comments exist yet.

## Per item (state before this work)
| # | Item | Status | Evidence |
|---|------|--------|----------|
| 7 | Cyrus admin portal | PARTIAL (mostly DONE) | 17 tabs under /admin/cyrus (overview, builds, live prompt feed + grouped errors, users & tokens, cost, economy with Anthropic cost vs margin, reconcile, games, community, library & safety, storage, learning, assets, notify, launch check, flags, audit; lib/cyrus/admin/perms.ts). Gaps: /admin/cyrus-tokens and /admin/cyrus-mods are URL-only and no page indexes them; an admin NOT on the modbuilder preview list got a bare 404 from app/admin/cyrus/layout.tsx, /admin/cyrus-tokens and /admin/cyrus-mods. Featured-mods management exists in app/admin/cyrus/community (lib/cyrus-mods/featured.ts, Setting cyrus_featured_pages). |
| 8 | Public asset library in the customer portal | PARTIAL | Browse API live (app/api/cyrus/library/v2/browse; CYRUS_LIBRARY_BACKEND=1 + CYRUS_LIBRARY_BROWSE=1 in prod). UI existed only INSIDE a project studio (/dashboard/cyrus/[id]/studio/library, components/cyrus/forge/LibraryBrowser.tsx). No account-level library page and no entry in the customer app nav. |
| 9 | Spotlight / community / mod pages | PARTIAL (mostly DONE) | Mod page: versions + changelog, description, gallery/icon/banner, stars, ratings (installers only), threads, remix + remix tree + community versions, collections, "Add to my Cyrus" (CyrusLibraryItem), jar/source download, "Install on my server" (CyrusInstallButton), owner-featured list (lib/cyrus-mods/featured.ts), public listing /mods/cyrus, creator profile /mods/cyrus/u/[handle]. Gap: the public author shown was the Nxeon account name (displayUser), not an author tag. |
| 10 | SEO marketing pages with author | PARTIAL (mostly DONE) | lib/cyrus-mods/seo.ts: title/description, canonical, OG + Twitter, JSON-LD SoftwareApplication + BreadcrumbList + FAQPage, noindex until launch and for private/hidden pages, sitemap entries (only when cyrus_mods_public_enabled). Gaps: JSON-LD author = personal account name with no url; creator profile pages not in the sitemap; no Person JSON-LD on profile pages. |
| 11 | Cyrus USERNAME / author tag | MISSING | No username field. CyrusCreator.handle is an auto slug "<name-slug>-<4hex>" derived from the account name (social.ts ensureCreatorHandle), not user chosen; no gate on either host; public credit everywhere = User.name via displayUser(). |

## Screenshots
Not captured: signing in to production was out of scope and nothing was run against it. The library check was done by code + flags + DB: with both flags on, the studio library page renders and queries CyrusCatalogEntry (62,777 rows); an account-level page did not exist (item 8, now added).

## Results (implemented on `feature/cyrus-community`, NOT merged, NOT deployed)
Status after: 11 DONE (code), 10 DONE (code; content empty until launch), 9 DONE (code; community data empty), 8 DONE (page), 7 DONE (index + messages). All public pages remain behind cyrus_mods_public_enabled / cyrus_public_enabled; nothing flipped.

### Item 11 username (new)
- Schema (ADDITIVE): `CyrusCreator.username String?`, `CyrusCreator.usernameKey String? @unique` (lowercase, the case-insensitive uniqueness), `CyrusCreator.usernameSetAt DateTime?`; new table `CyrusUsernameHold` (usernameKey PK, userId, releasedAt, reservedUntil, index userId).
- Rules: 3-20 chars [a-z0-9_-], start/end alphanumeric, no doubled separators, reserved list, impersonation words inside names (nxeon, cyrus, staff, admin, support, official, mojang...) after look-alike folding (0->o, 1->i, 3->e, 5->s ...) and separator stripping, conservative profanity list (`lib/cyrus-mods/username.ts`, pure).
- API `/api/cyrus/username` (GET state, GET ?name= live check, POST claim/change), rate limited 40/min per account + 120/min per IP for checks, 10 per 10 min for saves, same-origin POST.
- Gate (both hosts: the Cyrus tree serves nxeon.cloud/dashboard/cyrus and cyrus.my): `app/dashboard/cyrus/layout.tsx` shows the claim screen instead of any Cyrus page; `modBuilderAccess` also returns null without a username, so every page, server action and API v1 subject refuses (hard lock, not just UI). Existing users are prompted on next open. Kill switch `CYRUS_USERNAME_REQUIRED=0` (emergency only).
- Change policy (decision): first choice free; afterwards once per 30 days; released name held 90 days for its previous owner (CyrusUsernameHold); case-only change allowed anytime; profile URL follows the username (old handle URL 404s; no redirect built).
- Author tag shown instead of account name: mod page byline/hero, listing cards, featured cards, collections, community threads/comments, remix credit chain, source README + LICENSE, GameMod.authorName, SEO JSON-LD author (Person, linked to creator page). Account without a tag = "Cyrus creator". The placeholder handle is no longer derived from the account name.
- Admin: Users tab shows the author tag. GDPR table list includes CyrusUsernameHold.

### Items 9/10
- Public install button now present on the public mod page (opens the portal page where the plan dialog runs), with the Nxeon mark; portal "Install on my server" shows the Nxeon mark.
- Creator profile pages: indexable + in sitemap only with >= 2 published mods (no thin pages), canonical, ProfilePage/Person JSON-LD.
- NOTE: portal install of someone else's published mod is gated by Setting `cyrus_install_published_enabled` (absent = OFF in prod); the owner must set it with the launch.

### Item 8
- `/dashboard/cyrus/app/library` (nav "Asset library"): search/kind filter/detail over the live catalogue API (needs CYRUS_LIBRARY_BROWSE=1, already set in prod; thumbnails when the backend store + URL secret are set). On cyrus.my it is reached at /dashboard/cyrus/app/library (no nginx change).

### Item 7
- `/admin/cyrus/tools` index of every tool by group with plain descriptions; new tabs "Token plans & ledger" (/admin/cyrus-tokens) and "Mods launch & reports" (/admin/cyrus-mods); staff not on `preview_access_emails_modbuilder` now see an explanation (layout, cyrus-tokens, cyrus-mods) instead of a 404; non-staff still 404.
- Owner's earlier requirements all map to existing tabs: live prompt tracking = Live; errors = Overview/Live (grouped); economy + Anthropic cost vs margin = Economy/Cost (Anthropic Admin API cost adapter needs env ANTHROPIC_ADMIN_API_KEY, unset = off); featured mods = Community tab.

### Verification
- tsc clean (devhost). Targeted tests green: cyrus-username (new, 22 assertions), cyrus-mods, cyrus-community, cyrus-security-review (route matrix row added), cyrus-admin*, cyrus-page-gate, cyrus-launch-check. The full suite run (4,000+ tests) showed failures in files I did not touch (api-http-surface lists 16 other routes, admin-actions-guards listing actions-account, auth-lockouts, revenue/MRR derivation checks, UDP query); the only one attributable to this work (api-http-surface: username route keyed on `u.id`) was fixed by keying on `user.id`, but re-running was blocked by the shared build lock, so re-run `scripts/devhost test test/api-http-surface.test.ts` before merge.
- No screenshots/browser run (build host busy; production off limits).

### What remains / owner decisions
- Run the additive schema push (below) BEFORE promoting: without the columns every Cyrus page that reads CyrusCreator fails. If promoting before the push is unavoidable set CYRUS_USERNAME_REQUIRED=0 and ONLY then.
- Owner chooses profanity/reserved list additions and the 30/90 day policy numbers (constants in lib/cyrus-mods/username.ts).
- Community data is empty (0 listings/media/ratings): the pages show honest empty states; spotlight stays empty until the owner features real public mods.
- No generated per-mod OG image (uses the banner/photo/icon or the game hero image).
- Username change does not refresh existing GameMod.authorName until the mod's next version/install refresh.

### Owner commands
1. Schema (additive, on the target DB after review): `cd <deploy tree> && npx prisma db push && npx prisma generate` (adds 3 nullable columns + unique index on CyrusCreator, new table CyrusUsernameHold; nothing dropped).
2. Review/merge `feature/cyrus-community` (worktree /tank/dev-worktrees/cyrus-community), then the normal `scripts/deploy-staging.sh feature/cyrus-community` -> verify -> `scripts/promote-production.sh`.
3. Launch later (unchanged): Settings `cyrus_mods_public_enabled`, `cyrus_public_enabled`, `cyrus_studio_public_enabled`, `cyrus_install_published_enabled` = true.

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

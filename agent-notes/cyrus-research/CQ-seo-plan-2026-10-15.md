# Cyrus (cyrus.my) SEO plan, 2026-10-15

Status: PLANNING and RESEARCH only. No code or DNS was changed. Nothing under /opt/nxeon was edited.
Method and limits: live curl of cyrus.my on 2026-10-15; read of apps/cyrus-site/src/index.html, app/robots.ts, lib/sitemap-sections.ts, lib/sitemap-mods.ts, lib/cyrus/public-gate.ts, lib/cyrus-mods/seo.ts, lib/seo/searchConsole.ts, app/nxm/cyrus/page.tsx; WebSearch (US-only, standard mode, 3 queries). No paid keyword tools exist here, so ALL search volumes are UNKNOWN. Difficulty is a guess from who appears on the SERP. Competitor claims are vendor marketing and unverified.

---------------------------------------------------------------------------
## 1. Current state audit (as crawled today)

| Item | Finding | Severity |
|---|---|---|
| `/` (static file apps/cyrus-site/src/index.html, 45 KB, served via Cloudflare, `last-modified` 2026-10-14) | Title "Cyrus — AI Mod Studio" (OK, 22 chars; too generic, no keyword). Meta description present and honest (~150 chars). `theme-color` present. | Medium |
| Canonical / OG / Twitter / JSON-LD / robots meta on `/` | NONE. grep for canonical, og:, twitter:, ld+json returns 0. | High |
| Headings | One H1 ("Describe it. ..."), H2s per section, H3s per stage. Structure fine. H1 is a slogan, not descriptive; a visible/sr-only descriptor line with "AI Minecraft mod and plugin maker" is needed. | Medium |
| Image alts | Gameplay shots have good descriptive alts. Game logos (minecraft.svg x3, other games) have `alt=""` which is fine when decorative, but game tiles for Palworld/Rust/Terraria/Valheim/Zomboid are empty alts while carrying text meaning. | Low |
| Performance | No `<video>` found. Gameplay webp 1.3 MB total (lazy, width/height set: good). three.js (vendor 2.3 MB) is dynamically imported only for the 3D viewer (main.js line ~397) but `core.js` is a `type=module` script and an importmap is in the head: verify three.js is not fetched before interaction (check Network in a lab run). Font preload present. CWV risk is therefore moderate, not high: LCP is the hero (check what it is), CLS risk from `.reveal` sections and the state-swapping item images. | Medium, measure |
| robots.txt on cyrus.my | Serves the NXEON robots (Disallow /dashboard /admin /api /login /register ..., /riddle/chamber-of-echoes, AI-agent groups). `Sitemap:` and `Host:` almost certainly point to nxeon.cloud (app/robots.ts uses APP_URL). Cross-host Sitemap lines are technically allowed but meaningless for GSC; it also leaks an Nxeon-only path name onto cyrus.my. | High |
| sitemap.xml on cyrus.my | 404 (10 bytes). | High |
| Non-home paths on cyrus.my | `/sign-in`, `/legal/terms`, `/legal/privacy` return 200 from the NXEON app: titles "Nxeon — Cloud VPS Hosting..." (sign-in) and "Terms of Service — Nxeon"; `<link rel=canonical href="https://nxeon.cloud">` (the Nxeon HOME, not the page) and `robots: index, follow`. So Google can index cyrus.my/legal/* as duplicates and is told their canonical is the Nxeon homepage. `/new` 307s to `/sign-in?next=/dashboard/cyrus/app/new` (fine, but the sign-in page itself is `index,follow`). | High |
| Unknown paths | 404 text/html, 146 bytes (bare nginx/CF page; fine, but no branded 404). `/index.html` 404, `/status/` 200 "Cyrus status" (should be noindex). | Low |
| www and http | `http://` 301 to `https://cyrus.my/`. `www.cyrus.my` returns 200 with the same content, NOT a redirect: duplicate host. | Medium |
| Security headers on `/` | HSTS `max-age=31536000` present (no includeSubDomains/preload). Legal pages (Nxeon app) carry a CSP that allows GTM, GA, Plausible, Facebook, Google Ads; the home does not show a CSP in the sampled headers. | Low |
| Duplicate content hosts | Home is not duplicated at nxeon.cloud/cyrus: `/cyrus` on nxeon.cloud 404s today (page is gated by lib/cyrus/public-gate.ts, cyrus_public_enabled off; when on it is noindex-unless-public and sitemap-listed). `/mods/cyrus` on nxeon.cloud returns the Nxeon home (canonical = Nxeon home), i.e. a soft route. Mod pages are designed to live at `nxeon.cloud/mods/cyrus/<slug>` (lib/cyrus-mods/seo.ts: `APP` = APP_URL = nxeon.cloud). `/dashboard/cyrus` is auth and disallowed in robots. | High (decision) |
| Analytics | Nxeon app has GTM/GA/Plausible in CSP and lib/cyrus/analytics + CyrusAttribution (lib/cyrus-bridge/attribution.ts) exist. The static home has no tag. GSC read-only OAuth is already wired platform-wide (lib/seo/searchConsole.ts, GSC_OAUTH_* in .env) for Nxeon. | Info |
| Indexability of private beta | Home is public and indexable by default (no noindex). That is fine: it is a marketing page, but the copy must say private beta truthfully (see risk section). Studio is behind sign-in. | Info |

Takeaway: the only crawlable first-party page is `/`, and it has no canonical/OG/JSON-LD. Everything else on cyrus.my is an Nxeon page wearing a Cyrus host with a wrong canonical. Fix hosting boundaries before anything else.

---------------------------------------------------------------------------
## 2. Keyword and intent research

Method: WebSearch only (3 queries run: AI plugin generator; datapack generator; custom boss plugins). Clusters below beyond those 3 are from domain knowledge and flagged "unverified SERP". Volumes: UNKNOWN for all. Validate with GSC impressions after 4-6 weeks and with a one-off free tool (Google Keyword Planner via a throwaway Ads account, or Ahrefs/Semrush free webmaster/trial) by the owner.

Real competitors observed:
- player.games: has dedicated landing pages "create minecraft plugins without coding", "create minecraft server-side mods AI", "Spigot plugins, AI-built", localized (de-DE, es-ES, pt-BR). Closest direct competitor; they build pages per software + locale. https://www.player.games/en-US/create-minecraft-plugins-without-coding
- Kodari (AI plugin builder, listed on alternativeto.net, one-time $10-$150 per its listing). https://alternativeto.net/software/kodari/about/
- BukkitCode (agent on Hangar, in-server compile plugin). https://hangar.papermc.io/SeraphinaNiko/BukkitCode
- ModCrafter (mod-crafter-java.lovable.app): datapack generator, custom items generator, AI datapack generator pages. Template-style programmatic pages on a lovable.app subdomain: beatable. https://mod-crafter-java.lovable.app/minecraft-datapack-generator
- Established non-AI incumbents (domain knowledge, SERP unverified): MythicMobs (wiki.mythiccraft.io, modrinth.com/plugin/mythicmobs), EliteMobs (github.com/magmaguy/elitemobs, has a web app), MCreator (mcreator.net), Blockbench (blockbench.net), Misode generators (misode.github.io), MCStacker, Planet Minecraft, SpigotMC, Modrinth, Hangar, Bukkit/CurseForge.
- Aggregators on guides: mineguard.pro blog, boxtoplay.com plugin mirror pages (programmatic mirror spam, a signal that thin mirrors do rank for plugin names).

| Cluster | Example queries | Intent | Difficulty guess | Winnable? |
|---|---|---|---|---|
| A. AI plugin generator | ai minecraft plugin generator; minecraft plugin generator ai; chatgpt minecraft plugin | commercial/tool | Medium: few real players, vendor pages | YES, primary head target (home + /minecraft-plugin-generator) |
| B. No-code plugin creation | create minecraft plugin without coding; make a minecraft plugin without java | informational to tool | Medium-high: guides plus player.games | YES with a truthful how-to (full flow with real outputs) |
| C. AI mod maker | ai minecraft mod maker; minecraft mod generator | commercial | Medium-high: MCreator/ modcrafter-style sites | Partial: Cyrus makes server plugins/mods; do not over-claim Forge/Fabric client mods unless true per docs/cyrus/minecraft-coverage.md |
| D. Custom items | custom items plugin; minecraft custom item generator; custom sword plugin | tool/informational | High for generic; low for long-tail | Long-tail only (use-case pages) |
| E. Custom mobs/bosses | minecraft custom boss plugin; custom mob plugin; add custom boss to server | informational + plugin research | High (MythicMobs, EliteMobs own head) | Long-tail how-to wins; do NOT target "mythicmobs" brand head |
| F. Datapack generator | minecraft datapack generator; ai datapack | tool | Medium-high (Misode, ModCrafter) | Possible with a datapack-studio landing page, only if shipped |
| G. Texture maker | custom sword texture maker; minecraft texture generator ai | tool | High (many tools; image-search heavy) | Hard head; use case + gallery image SEO later |
| H. Genre plugins | minecraft roguelike dungeon plugin; 100 floor dungeon plugin; quest plugin; crates plugin | research/download | Medium: Spigot/Modrinth resource pages | YES as "built with Cyrus" showcase + how-to |
| I. Server owner pain | how to make a custom GUI shop plugin; custom enchant plugin | informational | Medium | YES long-tail |
| J. Per-game later | valheim mod maker; terraria mod generator ai | tool | Unknown, probably lower | Defer until each game is really supported (do not publish game pages for unsupported games) |
| K. Branded | cyrus minecraft; cyrus.my; nxeon cyrus | navigational | Trivial | Own it (home, about, docs) |
| L. CC0 asset library | free minecraft textures cc0; free minecraft sound effects; cc0 models | download | High, but CC0 pages with real previews are credible | Phase 3, strict quality gates |

Credibility guard: every claim on a page must be reproducible by an actual Cyrus output (dungeon build, goblin, crates quest mod). No "best", no unverifiable comparative claims.

---------------------------------------------------------------------------
## 3. Information architecture

Canonical host decision: **cyrus.my is canonical for everything marketing/editorial and for mod pages**, once a dedicated Cyrus origin can serve them with correct per-page metadata. Why: the brand domain accumulates links; user-facing positioning is "a Nxeon product" but search identity is Cyrus; the current setup of canonical=nxeon.cloud home is actively harmful. Interim (until Cyrus can render dynamic pages on its own host): keep mod pages canonical at nxeon.cloud/mods/cyrus/<slug> (that is what lib/cyrus-mods/seo.ts emits) and do not index the same page under cyrus.my. Never let both hosts serve the same content as 200; pick one and 301 the other. Owner decision needed (also noted in tracker: "whether to keep /mods/cyrus SEO via redirects"). Rule: one URL per content, host moves are done with 301 + sitemap swap.

URL scheme (cyrus.my):
```
/                                  home (SoftwareApplication + Organization)
/features/                         overview
/features/texture-studio           per studio: texture, sound, creatures, datapack, designer(3D model/config/motion)
/features/sound-studio
/features/creature-studio
/features/datapack-studio          only when real
/features/designer
/use-cases/                        index
/use-cases/custom-boss             custom weapon, boss, gui-shop, quests, crates, dungeon, ...
/how-it-works
/pricing                           Katara 1 game / Saka 5 / Yakko unlimited; honest, matches Stripe
/guides/                           how-to (3-5 evergreen) 
/blog/                             news, release notes, build logs
/changelog
/docs/                             separate section; link to Nxeon docs only where true
/mods/                             community mod pages: /mods/<slug> ; creator /u/<username>
/library/                          CC0 asset browse: /library/<kind>/<category>/ and /library/asset/<id>
/collections/ , /spotlight/        curated
/compare/cyrus-vs-<x>              honest, only where the comparison is factual
/legal/terms /legal/privacy        canonical to self (see section 5)
/status                            noindex
```
Internal linking: home -> features/use-cases/pricing; each use case -> relevant studio feature + 1 guide + 2-3 real example mod pages; each mod page -> use case + creator + collection; library asset -> category -> studio feature. Breadcrumbs on every deep page. Footer links to legal, status, Nxeon.

Pagination caps: /mods and /library listings capped at page 100 (scraper incident), with page 101+ returning 404 or a noindex page; all filter/sort combos noindex,follow and excluded from sitemaps; search results pages noindex. Rate limit cyrus.my like Nxeon (reuse existing mod listing limits).

---------------------------------------------------------------------------
## 4. Programmatic SEO rules (mod pages, library pages)

Reuse patterns: lib/sitemap-sections.ts (sections, lastmod only when real), lib/sitemap-mods.ts (min description chars gate seo_mod_sitemap_min_desc_chars, ranked cut, 50k hard cap, chunking), lib/seo-index-policy.ts, lib/cyrus-mods/gate.ts (off = 404 + noindex), lib/cyrus-mods/seo.ts (derives metadata only from the mod's doc; FAQ generated from real fields), app/nxm/_seo/registry.ts.

Quality bar for index (else `noindex,follow`, not in sitemap):
- Mod page: published by creator, passes content scan (lib/cyrus-mods/rescan.ts), >= 250 words of non-boilerplate unique text (creator tagline + summary + commands list), >= 1 real screenshot or generated media, valid game/version metadata, tested status (lib/cyrus-mods/tested.ts) true or clearly labelled, >= 1 command/feature item, creator not banned. Thin or duplicate (near-duplicate by shingle hash vs existing) stay noindex.
- Library asset page: unique title+description (<=140 per index), preview asset, license CC0 shown with provenance, at least N related items; asset pages for unrecognisable/low-descriptor items (44.6% undescribed per docs/cyrus/04) stay noindex until described. Category/tag pages index only with >= 12 items and a human-written intro (>= 80 words), otherwise noindex. Cap total indexed library URLs initially at 2,000, expand only if GSC shows "Indexed" > 70% of submitted.
- Structured data: SoftwareApplication (mod page: name, applicationCategory GameApplication/"Minecraft plugin", operatingSystem, offers free if true), CreativeWork + license URL for assets (CC0 `https://creativecommons.org/publicdomain/zero/1.0/`), Person for creator (only public username, no email), BreadcrumbList everywhere, Organization + WebSite on home. FAQPage ONLY where Q&As are visible and real (modSeo already derives them). WebSite SearchAction only once site search really exists. No AggregateRating unless real reviews exist.
- OG image: dynamic per mod from banner or screenshot via the same pipeline as Nxeon blog images; 1200x630 with title; fallback game hero.
- Sitemap sharding: index at /sitemap.xml with sections core, features, use-cases, guides, blog, mods-1..N, creators, library-<kind>-N. Each <= 10k URLs for operational headroom (hard limit 50k/50MB), lastmod only with real edit date.
- Freshness: mod page lastmod on version publish; blog/guide lastmod on edit; regenerate sitemaps on publish.
- UGC safety: user text rendered with `rel="ugc nofollow"` on any external link, strip raw HTML/links in descriptions initially, report button with admin queue, auto-noindex on N reports, ban list = 410 + removal from sitemap, slug squatting and brand names blocked, no doorway pages (one page per distinct mod only). Licensing display: show license (CC0 / creator terms / "Generated with Cyrus") and source availability on each page; link to ToS.
- Do not index: remixes that are near-identical to the parent (canonical to the parent).

---------------------------------------------------------------------------
## 5. Technical checklist (ordered)

1. Decide host model (section 3) and write it in docs/cyrus/10-decisions.md.
2. robots.txt, host-aware: when Host=cyrus.my serve a Cyrus file. Disallow: /new /dashboard /api /sign-in /sso /account /admin /status; Allow /; keep AI search bots allowed, mirror Nxeon AI_TRAINING toggle; `Sitemap: https://cyrus.my/sitemap.xml`; no Nxeon-only paths (drop /riddle). Fail-closed: while in private beta with no public launch, still allow home.
3. Serve /sitemap.xml on cyrus.my (sitemap index; initially only `/`, legal pages, and features as they exist; add mod/library shards only after the quality bar). Mirror lib/sitemap-sections.ts pattern, with a Cyrus-specific section list.
4. Home `<head>`: `<link rel=canonical href=https://cyrus.my/>`, OG (og:title/description/type=website/url/image 1200x630/site_name), Twitter summary_large_image, JSON-LD @graph: Organization (Cyrus, parentOrganization Nxeon), WebSite (no SearchAction), SoftwareApplication (name Cyrus, applicationCategory DeveloperApplication, offers per tier only when prices are final). Title suggestion: "Cyrus: AI Minecraft Plugin & Mod Maker | Nxeon" (<=60 chars). H1 keep; add a descriptive subhead.
5. Fix the Nxeon-origin pages on the cyrus.my host: per-page canonical to self (cyrus.my/legal/terms), correct titles ("Terms of Service | Cyrus"), `noindex` for /sign-in, and `X-Robots-Tag: noindex` on app paths. Or 301 /legal/* to the nxeon.cloud canonical and keep cyrus.my out of the index: pick one. Either way never canonical to the Nxeon home.
6. `www.cyrus.my` -> 301 `https://cyrus.my$request_uri` (Cloudflare redirect rule). Add `includeSubDomains` to HSTS only after all subdomains are HTTPS; preload optional.
7. Security headers that matter: HSTS (exists), CSP (static home currently none), X-Content-Type-Options nosniff, Referrer-Policy strict-origin-when-cross-origin, frame-ancestors 'none' (or X-Frame-Options DENY). Do not copy Nxeon's wide CSP; allow only needed analytics.
8. Images: keep webp; add `fetchpriority=high` to LCP image; explicit width/height everywhere; add `alt` text to meaningful game tiles; provide srcset for gameplay shots (1600w only now).
9. Heavy assets: confirm three.js and model.js load only on viewer intersection/interaction; defer motion/*.webp animations; if hero videos are added later, use `preload=none`, poster image, `<picture>`/webm, and no autoplay on mobile data.
10. CWV budget: LCP < 2.5 s (p75 mobile), INP < 200 ms, CLS < 0.1, total JS < 150 KB before interaction, home transfer < 1.5 MB above the fold.
11. 404/410: unknown = 404 with branded page and links home; deleted/banned mod = 410; unpublished = 404 + noindex; moved = 301. Never soft-404 (the /mods/cyrus-to-Nxeon-home behaviour on nxeon.cloud is a soft route: fix).
12. `/status` -> `noindex`; add `<meta name=robots>` to all non-marketing pages.
13. 404 for `/index.html`: fine; add trailing-slash policy (no trailing slash except root) consistent with the Nxeon sitemap rule.
14. IndexNow: reuse lib/indexnow-core.ts with host=cyrus.my and key file `https://cyrus.my/<key>.txt`; ping on mod publish/unpublish.
15. Analytics tag decision (see section 8), consent-first.

---------------------------------------------------------------------------
## 6. GSC and Bing runbook (cyrus.my)

Pre-reqs: items 2, 3 and 4 above live (so the first crawl sees correct robots and sitemap). Run by owner or with explicit approval; the Cloudflare token is in /opt/nxeon/.env and must not be copied elsewhere.
1. In Search Console (https://search.google.com/search-console) click Add property -> Domain -> `cyrus.my`; copy the TXT value `google-site-verification=<token>`.
2. Find the zone id: `curl -s -H "Authorization: Bearer $CLOUDFLARE_DNS_API_TOKEN" "https://api.cloudflare.com/client/v4/zones?name=cyrus.my"`.
3. Add the TXT record (the exact call):
   `curl -s -X POST "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/dns_records" -H "Authorization: Bearer $CLOUDFLARE_DNS_API_TOKEN" -H "Content-Type: application/json" --data '{"type":"TXT","name":"cyrus.my","content":"google-site-verification=<token>","ttl":300}'`
   (Needs Zone:DNS:Edit on cyrus.my; verify the token scope first with the GET above. If cyrus.my is NOT in the Nxeon CF account, the call returns an empty result: then use the dashboard.)
4. Click Verify in GSC. Keep the TXT record permanently.
5. Alternatives: HTML tag (add `<meta name="google-site-verification">` to apps/cyrus-site/src/index.html: static home only, covers URL-prefix property https://cyrus.my/), or HTML file at site root. Domain property is preferred (covers www, http, subdomains).
6. Submit `https://cyrus.my/sitemap.xml`. URL Inspection -> `https://cyrus.my/` -> Request indexing. Inspect `/legal/terms` to confirm canonical is now itself.
7. Settings: no geo target for a .my domain (ccTLD is treated as Malaysia-geo by Google? .my is a country-code TLD: Google uses it as a geo signal for Malaysia. Risk for an English global audience: not changeable in GSC for ccTLDs. Mitigate with English content, hreflang not needed; accept and monitor impressions by country. Raise as an owner-level risk.)
8. Connect to the existing Nxeon platform GSC OAuth (lib/seo/searchConsole.ts): add cyrus.my site to the sites.list filter so striking-distance reports include it; the integration is read-only and platform-wide.
9. Bing: https://www.bing.com/webmasters -> Import from Google Search Console (OAuth) -> imports cyrus.my and sitemap. Enable IndexNow.
10. GA4/Plausible: Nxeon already allows GA/GTM/Plausible in CSP; decision in section 8 (consent-first). If GA4 is linked: Admin -> Product links -> Search Console links.
Weekly monitor: Pages (indexed vs not indexed reasons), Sitemaps (discovered vs indexed), Core Web Vitals report, Performance (queries, clicks, impressions, CTR, avg position by page), Crawl stats (response codes), Manual actions/Security. Alert thresholds: indexed pages drop >20% week over week; 5xx > 1% of crawl; "Crawled - currently not indexed" > 30% of mod URLs; any CWV URL group "Poor"; CTR on top 5 pages drops >30% with stable position; impressions drop >40%.

---------------------------------------------------------------------------
## 7. Content calendar, first 90 days

Owners: SEO agent (briefs, metadata, internal links), Writer agent (drafts, truthfulness check vs docs/cyrus and real outputs), Eng agent (templates, schema), Owner (publish approval, claims sign-off, screenshots/video).

Weeks 1-2: foundation (section 5 items 1-8) plus home rewrite.
Weeks 3-4: features pages (texture, sound, creature, designer) + pricing + how-it-works.
Weeks 5-12: 10 use-case pages + 5 guides + mod page template behind quality gate.

10 use-case pages (target keyword; intent; format; link to):
1. Custom weapon plugin: "minecraft custom weapon plugin" (transactional/info); screenshot of blue blade (shot-1); link to texture studio, pricing.
2. Custom boss: "custom boss plugin minecraft"; goblin mod; link to creature studio.
3. GUI shop: "minecraft gui shop plugin"; real shop output.
4. Quests: "minecraft quest plugin"; crates quest mod (shot-4 quest log).
5. Crates and loot: "minecraft crates plugin custom"; crates mod.
6. Dungeon / roguelike: "minecraft roguelike dungeon plugin"; the dungeon build.
7. Floating islands / world gen: "minecraft floating islands plugin" (shot-2).
8. Shrinking world / battle royale: "minecraft shrinking world plugin" (shot-3).
9. Admin/moderation tools: "minecraft admin tools plugin" (shot-7).
10. Custom biome: "custom biome minecraft plugin" (shot-6).
Each page: problem, what Cyrus produced (prompt shown), screenshots, commands list, limitations, a "try it" CTA, link to mod page. Only publish a page when the example is real and reproducible.

5 how-to guides:
G1 How to add a custom boss to your Minecraft server (goblin).
G2 How to make a 100-floor dungeon plugin (dungeon build).
G3 How to make a Minecraft plugin without coding (full flow, honest limits).
G4 How to create a custom quest system with an AI plugin (crates quest).
G5 How to install and test a generated plugin on your Nxeon server (Paper versions, backup, rollback).
Then blog: monthly build logs, changelog, "what we got wrong" posts (E-E-A-T).

90-day gates: day 30 home+features indexed; day 60 5 use cases + 2 guides; day 90 10 use cases + 5 guides, first 50 mod pages if cyrus_mods_public_enabled flips.

Honest link building/PR: Modrinth and Hangar project pages for Cyrus-made plugins (with attribution link to the mod page, after reading their rules); Spigot resource posts; r/admincraft and r/MinecraftServer only when permitted by self-promo rules (check sidebar; participate before posting; use "I built" tone with disclosure); YouTube demo videos with timestamps and descriptions linking the use case; Product Hunt/AlternativeTo listing (Kodari has one: https://alternativeto.net/software/kodari/about/); GitHub awesome-lists for Minecraft tooling; guest posts with server-owner blogs; Nxeon cross-links (already strong: nxeon.cloud is a real site with traffic, link from /game-servers/mods).
DO NOT: AI-spam programmatic pages, fake reviews/ratings, doorway pages per game not supported, cloaked "private beta" content for crawlers vs users, buying links, mass-posting in Discords, brand-name stuffing of MythicMobs/EliteMobs, auto-generated plugin-name mirror pages (the boxtoplay pattern).

---------------------------------------------------------------------------
## 8. Measurement

KPIs: indexed pages vs submitted; non-brand impressions and clicks; top-3/top-10 keyword counts for clusters A, B, E, H; organic sign-ups and first-mod conversions; CTR; CWV pass rate; referring domains; mod-page index ratio; assisted conversions from guides.
Baseline: capture in week 1 (GSC will be empty; record 0 as baseline, record Lighthouse mobile for home, record crawl state from this audit).
Leading indicators: pages discovered/indexed per sitemap section, impressions on long-tail use-case queries, branded query growth ("cyrus minecraft"), CTR on titles.
Attribution: CyrusAttribution (lib/cyrus-bridge/attribution.ts, lib/cyrus/analytics/conversions.ts) is consent-first: use UTMs on non-organic links and landing -> signup measurement only after consent; organic is read from GSC aggregates, no per-user fingerprinting. Do not add an unconditional analytics tag to the static home; add a consent banner or use cookieless Plausible (already in Nxeon CSP) after privacy copy review.
Dashboards: Looker Studio over GSC + (consented) conversions; Nxeon admin SEO opportunity module (lib/seo/opportunities.ts) extended with cyrus.my.
Cadence: weekly 30-minute monitor (section 6), monthly content review (decay, refresh), quarterly keyword re-research with real GSC queries.

---------------------------------------------------------------------------
## 9. Risks and dependencies

- Host/canonical model unresolved (cross-site: Nxeon app serves cyrus.my paths). Blocks sitemap and mod pages. Owner decision.
- ccTLD .my geo-signal: global English audience may be under-served in non-MY regions; cannot be changed in GSC. Consider long-term a .com/.gg brand domain redirect plan.
- Legal copy: ToS/Privacy are Nxeon pages; Cyrus needs its own terms for UGC (mod pages), CC0 asset display, DMCA/report process, and AI-generated content notice, before indexable mod pages.
- Launch state: "launch pair off", mod pages flags off (cyrus_mods_public_enabled, cyrus_public_enabled): keep noindex until the owner flips; indexable mod pages only when the quality bar holds and moderation/report flow ships.
- Cloaking: do not serve crawlers different content from users, even for the "private beta" wording; show the same truthful beta statement to everyone and gate only the app.
- Claims risk: avoid unprovable "best", "no coding at all" claims; show real limits; FTC/ASA-style truthfulness.
- Platform dependency: Mojang EULA/brand guidelines; do not use Minecraft logos as if affiliated; add "not affiliated with Mojang" footer.
- Competitor response: player.games already covers the head terms; differentiate with real, reproducible outputs and install-to-Nxeon.
- Scraping/abuse: pagination cap 100 and rate limits remain.
- Data risk: user content may leak PII in descriptions; scan before indexing.

---------------------------------------------------------------------------
## Sources used
https://cyrus.my/ , https://cyrus.my/robots.txt , https://cyrus.my/sitemap.xml , https://cyrus.my/legal/terms , https://cyrus.my/sign-in , https://nxeon.cloud/mods/cyrus ,
https://www.player.games/en-US/create-minecraft-plugins-without-coding , https://alternativeto.net/software/kodari/about/ , https://hangar.papermc.io/SeraphinaNiko/BukkitCode , https://mod-crafter-java.lovable.app/minecraft-datapack-generator , https://wiki.mythiccraft.io/mythicmobs , https://github.com/magmaguy/elitemobs , https://mineguard.pro/en/blog/mythicmobs-custom-mobs-bosses-guide

## Top 10 actions in order
1. Owner decides canonical host model (cyrus.my vs nxeon.cloud for mod pages) and records it.
2. Stop the wrong canonicals: fix cyrus.my/legal/*, sign-in (canonical to self or noindex, never Nxeon home).
3. Host-aware robots.txt for cyrus.my with a cyrus.my Sitemap line.
4. Publish /sitemap.xml on cyrus.my (home, legal, features first).
5. Add canonical, OG, Twitter and JSON-LD (Organization, WebSite, SoftwareApplication) to the home; sharpen the title.
6. 301 www to apex; add security headers; noindex /status.
7. Verify cyrus.my in GSC (DNS TXT via Cloudflare API, owner-approved), submit sitemap, import to Bing, wire IndexNow.
8. Ship features pages and pricing; then the 10 use-case pages and 5 guides with real outputs.
9. Turn on mod pages only behind the quality gate, report flow and ban list.
10. Set weekly monitoring with the alert thresholds; record baseline and review monthly.

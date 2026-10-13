# Google discoverability collapse on nxeon.cloud: analysis (2026-10-06)

## Bottom line
The sitemap restructure is NOT the cause. Nothing served to Googlebot is technically broken (200, `index, follow`, self canonical, content in server HTML, valid sitemaps, robots.txt includes `Sitemap: https://nxeon.cloud/sitemap.xml`). Bing gets identical HTML and kept crawling mod pages (~1,000-1,600/day in October; ~7,480 results for site:nxeon.cloud/mods). Most likely cause: a Google-side quality / scaled-content re-evaluation after ~65K near-templated mod pages appeared in about a week, with the 09-27 outage and full-site relaunch landing in the same 24 hours. Moderate confidence (no Search Console data available to the agent).

## Timeline (UTC)
- 09-19: NxLabs mod catalogue live (32K mods that day, 13K on 09-20, 18K on 09-24).
- 09-20 14:31 (9ec9a97): sitemap becomes an index of /sitemap/0..5.xml, 66,281 URLs (64,853 mods).
- 09-24 to 09-26: Googlebot burst-crawls mod pages (541 / 607 / 395 per day). GSC impressions peak 09-26.
- 09-27 08:21-08:31: disk-full outage, prod 500s (Googlebot itself saw only 3 5xx that day).
- 09-27 ~10:00: Googlebot mod fetches fall from ~30/h to 6-20/h (7 h BEFORE the relaunch).
- 09-27 17:17-17:25: NXM_ROOT=1 / NXM_LIVE=1, new marketing templates render every marketing URL (same URLs).
- 09-28 onward: Googlebot mod fetches 23, 6, 0, 0, 0 per day; non-mod crawling continues at the normal 150-300/day.
- 10-01 06:19 (1d483e6): sitemap split into named sections; mod sitemap capped at 10,000 downloads (~18K URLs, not 65K).
- 10-02 04:07 (1f2ff74): seo-014 mod quality bar deployed (failing mod pages become `noindex, follow`).
- No seo_* Setting rows exist in prod (code defaults apply).

## Googlebot (real 66.249.x.x, nxeon.cloud host only)
| Day | Total req | /mods pages | Non-200 |
|---|---|---|---|
| 09-22 | 258 | 126 | 7x 404, 2x 400 |
| 09-24 | 862 | 541 | 3x 404 |
| 09-25 | 924 | 607 | none |
| 09-26 | 745 | 395 | 2x 404 |
| 09-27 | 416 | 187 | 18x 400, 1x 500 |
| 09-28 | 225 | 23 | 1x 500 |
| 09-30 | 176 | 0 | 3x 404 |
| 10-02 | 312 | 82 | 4x 404 |
| 10-05 | 145 | 12 | 10x 404 (non-mod) |
| 10-06 | 325 | 6 | none |

## Ranked causes
1. Google quality / scaled-content re-evaluation (~55%, medium): 28 search-referred visits across 64,853 mod pages in 30 days; 12,223 of 19,920 Minecraft mods have descriptions under 80 characters, text mostly upstream copy; ~700 game x location pages share 81-87% of their text with siblings; all added to a young domain in ~8 days.
2. Relaunch + outage in the same 24 h (~30%): every URL got new HTML overnight; Google backs off after 5xx bursts. Rendering as Googlebot-mobile found no technical regression.
3. Quality-bar noindex + 10K sitemap floor (low as the cause; shipped after the cliff): ongoing drag. ~59% of active mods are noindex (~114K of 194K); ~18K listed; ~80K indexable but unlisted.
4. Page weight / TTFB (low): mod pages ~235 KB HTML (~51 KB gzip), TTFB 0.7-0.9 s avg (max 4.4 s), `cache-control: no-store`; mod sitemaps take 2.0-2.6 s to generate.

## Not the cause (tested)
- Sitemap structure: the numbered split (09-20) preceded the rise; the named split (10-01/02) came after the cliff. All 11 children valid, under limits (largest 15,000 URLs / 1.8 MB), 200 application/xml, gzip OK, real lastmod. One flat file cannot exceed 50,000 URLs, so an index is correct. GSC's 18,972 discovered matches what we list.
- robots.txt: Sitemap line present; disallows only dashboard/admin/api/auth.
- Indexability: 40-60 random URLs per section + 120 mod URLs: all 200, `index, follow`, self canonical, no X-Robots-Tag, one h1, 3.4K-5.3K words server-rendered. Only exception: 4 L4D2 game x location URLs that 404 (fixed on fix/seo-discoverability, commit bd854f8b61).
- Boilerplate: mod pages share only ~23% of word trigrams; the issue is originality of upstream text.
- Internal linking: mods linked from /mods, /mods/games/minecraft, /all, /game-servers/mods; pagination only exposes ?page=2, ?page=3 and the last page (discovery is sitemap-driven; not new on 09-27).

## Owner actions in Search Console
1. Delete the six /sitemap/0..5.xml entries; keep /sitemap.xml (optionally also submit core, games, blog, mods-1, mods-2 for per-template coverage).
2. Pages report filtered by the mods sitemaps: read the exact reasons ("Crawled - currently not indexed", "Discovered - currently not indexed", "Duplicate", "Alternate page with proper canonical") and look for a step down around Sep 27-30. This confirms or refutes cause 1.
3. Confirm Manual actions and Security issues are empty.
4. URL Inspection live test + request indexing: /, /game-servers, /minecraft-server-hosting, /blog, /mods/minecraft/midoris-stalker, /mods/minecraft/essentialsx.
5. Crawl stats: compare Sep 20-26 vs Sep 28 onward (host status, response time).
6. Don't bulk-request indexing; allow 2-4 weeks.

## Decisions
- Do not raise seo_mod_sitemap_min_downloads to 0 (would resubmit ~190K near-templated URLs). Keep the quality bar and the 10K floor; consider shrinking to the top ~5K mods with long descriptions.
- Keep seo_gameloc_sitemap_mode at demand; consider seo_gameloc_noindex_tail on for the ~450 near-duplicate tail pages.
- Invest in original per-mod value (install notes, compatibility matrix, real server-side status) — the only lever on cause 1.
- Not yet implemented: deeper pagination crawl paths, caching mod pages + mod sitemaps, dropping no-store on anonymous mod pages, de-duplicating the name at the start of mod meta descriptions, the x-middleware-rewrite header leak.

# CR: cyrus.my technical SEO foundations (2026-10-15)

Branch `feature/cyrus-seo-tech` (worktree /tank/dev-worktrees/cyrus-seo-tech). Not merged, not deployed, not published, nginx not touched, nothing verified in Search Console. No migration. Full page: `docs/cyrus/18-seo.md`.

## Root causes found
- `/sitemap.xml` 404: middleware's Cyrus-host allow list passes only static extensions; `.xml` is not one, so the request never reached `app/sitemap.xml/route.ts` (the vhost already proxied it by name; live vhost == repo file).
- `/robots.txt` Nxeon content: `.txt` passes middleware and the app has one robots file with no host awareness (and Next cached it: `x-nextjs-cache: HIT`, `max-age=14400`).
- Landing head had title/description/theme-color only.

## Before (live, 2026-10-15 08:15 UTC)
    GET https://cyrus.my/robots.txt          -> 200 text/plain, NXEON file (nxeon paths, /riddle/chamber-of-echoes, bot rules, Sitemap: https://nxeon.cloud/sitemap.xml)
    GET https://cyrus.my/sitemap.xml         -> 404 text/plain (from the app)
    GET https://cyrus.my/sitemap-index.xml   -> 404 x-cyrus-edge: denied
    landing <head>: <title>Cyrus — AI Mod Studio</title>, description, theme-color, icon, font preload; no canonical/OG/Twitter/JSON-LD

## After (generated from the shipped builders; the app route returns exactly this)
    User-agent: *            Allow: /   Disallow: /new$ /new/ /new?* /home /dashboard /account /wallet /servers /projects /studio
                                        /assets$ /assets?* /api/ /auth/ /admin /staff /packs/ /sign-in?* /sign-up?* /login /register
    (same Disallow repeated in the AI search group and the AI training group; training group = Disallow: / when AI_TRAINING_CRAWLERS=0)
    Sitemap: https://cyrus.my/sitemap.xml

    GET /sitemap.xml -> 200 application/xml
    <urlset ...><url><loc>https://cyrus.my/</loc><lastmod>2026-10-15</lastmod></url>   (lastmod = release.json builtAt, omitted if unreadable)
      /legal/terms 2026-09-27, /legal/privacy 2026-10-06, /legal/aup 2026-07-23, /legal/sla 2026-07-23 </urlset>

    GET /sign-in?next=%2Fnew (Cyrus host) -> x-robots-tag: noindex, nofollow (+ <meta robots noindex,nofollow>)
    GET /legal/terms (Cyrus host)         -> no X-Robots-Tag; <link rel=canonical href=https://cyrus.my/legal/terms>
    Nxeon hosts                           -> unchanged (test pins the Nxeon robots rules)

Not curl-able from this box until the owner ships the app: the agent never deployed. The matrix script `scripts/cyrus/nginx-cyrus-my-check.sh --origin 127.0.0.1` now also asserts both files' content and prints MATRIX FAILED until then.

## Bot policy (note)
Mirrored, not invented: the AI search agents (OAI-SearchBot, ChatGPT-User, PerplexityBot, Perplexity-User, Claude-SearchBot, Claude-User, DuckAssistBot, Applebot) allowed; training agents (GPTBot, ClaudeBot, Google-Extended, Applebot-Extended, CCBot) allowed unless `AI_TRAINING_CRAWLERS=0`. Extracted to `lib/seo-robots-policy.ts`, shared by both files. Owner can still choose a different policy for Cyrus (edit `cyrusRobots()`).

## Files
New: `lib/cyrus/seo.ts`, `lib/cyrus/seo-sitemap.ts`, `lib/seo-robots-policy.ts`, `test/cyrus-seo.test.ts`, `docs/cyrus/18-seo.md`, `apps/cyrus-site/src/assets/og/cyrus-og-1200x630.jpg`.
Changed: `app/robots.ts`, `app/sitemap.xml/route.ts`, `middleware.ts` (X-Robots-Tag), `lib/cyrus/bridge/routing.ts` (pass /sitemap.xml, /robots.txt), `app/cyrus-host/{sign-in,sign-up,legal/*}/page.tsx` (metadata), `app/nxm/_data/cyrus.ts` (flagged canonical), `lib/cyrus/admin/flags.ts` (3 env names), `apps/cyrus-site/{publish.sh,src/index.html}`, `deploy/cyrus/nginx-cyrus-my.conf` (+ regenerated `.patch`), `scripts/cyrus/nginx-cyrus-my-check.sh`, `test/cyrus-site-links.test.ts`, `docs/DOCUMENTATION.md`, `docs/cyrus/{06-portals,README}.md`, regenerated `docs/cyrus/reference/*`.

## Decisions
- nxeon.cloud/cyrus canonical -> https://cyrus.my/ behind `CYRUS_SITE_PRIMARY=1`, default OFF; flip only after cyrus.my/ is indexed.
- Status page is noindex, so it is NOT in the sitemap. Mod pages need `cyrus_mods_public_enabled` AND `CYRUS_SITEMAP_MOD_PAGES=1` (cyrus.my 404s /mods/* today). Library/spotlight: empty slots, no such public surface exists.
- noindex pages carry no canonical. Auth pages stay crawlable (disallow only the `?*` variants) so the noindex is seen.
- GSC: one setting `CYRUS_GSC_VERIFICATION`: meta token -> landing (publish.sh) + app pages (`verification.google`); `google<16hex>[.html]` -> static file written by publish.sh, served by a new exact-shape nginx location. Junk values are ignored by the app and fail the publish build.
- Landing: lang en, unique title/description (private beta, Paper plugins, no price/rating), canonical, robots, OG/Twitter 1200x630, JSON-LD Organization+WebSite+SoftwareApplication (no offers/ratings), one h1 (audited), all imgs alt+width+height, below-fold lazy, wordmark + display font preloaded (LCP is the h1). `publish.sh check` fails on missing canonical/OG/JSON-LD/h1/size.

## Owner commands (in order)
    # app (portal promote): stage then promote, after merge
    cd /opt/nxeon && scripts/deploy-staging.sh <ref> && scripts/promote-production.sh
    # purge Cloudflare cache for https://cyrus.my/robots.txt (it was served with max-age=14400)
    # nginx (only adds the google<hex>.html location)
    cp /etc/nginx/sites-enabled/cyrus-my /root/cyrus-my.bak && cp deploy/cyrus/nginx-cyrus-my.conf /etc/nginx/sites-enabled/cyrus-my && nginx -t && systemctl reload nginx && bash scripts/cyrus/nginx-cyrus-my-check.sh --origin 127.0.0.1
    # landing
    apps/cyrus-site/publish.sh check && apps/cyrus-site/publish.sh publish && apps/cyrus-site/publish.sh publish --go
    # later, with the owner's token: CYRUS_GSC_VERIFICATION=<token or google<hex>.html> apps/cyrus-site/publish.sh publish --go  (+ restart nxeon-web for app pages)

## Search Console runbook (6 steps; token comes from Search Console)
1. Search Console -> Add property -> Domain -> cyrus.my; copy the TXT value `google-site-verification=<TOKEN>`.
2. Create the TXT (do NOT run until you have the token):
       set -a; . /opt/nxeon/.env; set +a
       ZONE=$(curl -s -H "Authorization: Bearer $CLOUDFLARE_DNS_API_TOKEN" "https://api.cloudflare.com/client/v4/zones?name=cyrus.my" | python3 -c 'import sys,json;print(json.load(sys.stdin)["result"][0]["id"])')
       curl -s -X POST -H "Authorization: Bearer $CLOUDFLARE_DNS_API_TOKEN" -H "Content-Type: application/json" "https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records" --data '{"type":"TXT","name":"cyrus.my","content":"google-site-verification=<TOKEN>","ttl":300}'
3. Press Verify in Search Console (DNS may take minutes). Domain property covers all protocols/subdomains.
4. Optional URL-prefix proof: set `CYRUS_GSC_VERIFICATION`, republish the landing, restart nxeon-web. Keep the TXT record.
5. Sitemaps -> add https://cyrus.my/sitemap.xml (expect 5 URLs).
6. URL inspection of https://cyrus.my/ -> Request indexing; confirm Google-selected canonical; then consider `CYRUS_SITE_PRIMARY=1`.

## Tests
`test/cyrus-seo.test.ts` (robots, sitemap + sharding + gating + escaping, routing, middleware header, GSC parsing, metadata, landing head, publish.sh failure cases and GSC injection, nginx file assertions) plus the existing cyrus-site-links / landing / bridge-routing / admin-host / page-gate suites. Run via `scripts/devhost test`. Results: see the end of this note.

## Not done / limits
No live verification, no CWV measurement, `/help` and `/plans` not in the sitemap (app pages gated by `CYRUS_CUSTOMER_APP`), no `/sitemap-index.xml`, error boundary has no metadata (404s are not indexed). The old `nginx-cyrus-my.conf.patch` was against a stale live vhost; regenerated against the current live file (only the new location differs).

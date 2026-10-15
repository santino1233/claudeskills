# DC: Cyrus content engine (2026-10-15)

Branch `feature/cyrus-content` (worktree /tank/dev-worktrees/cyrus-content), from main + `feature/cyrus-community` + main again (3 fix commits). Commits 0e096376, a4513ab6 (merge main), 80e10a13. NOT merged, NOT deployed, no flag turned on, no production data written (read-only SELECTs only: coupons, partners, plans, nodes, mod page titles). Full design: `docs/cyrus/20-content.md`. Roadmap section appended to `DB-cyrus-marketing-roadmap-2026-10-15.md` (section 9).

## What was refused, and why (for the owner, 5 lines)
1. The request to artificially inflate views, ratings and add fake users/authors was NOT built: fabricated counters are deceptive, an FTC fake-review-rule problem for commercial promotion, and forbidden by this repo's own rule.
2. Real counters (views, installing accounts, ratings, stars) start at zero and read "New" until real; nothing seeds, boosts or estimates them (tests pin it).
3. Editorial curation instead: "Staff pick" and "Mod of the week" chosen in Admin > Cyrus > Spotlight (reason line, order, dates), so the spotlight is never empty and is labelled truthfully; real signals may blend in later as a separate "Popular right now" section, only past minimum samples (25 views/7d, 3 installing accounts or 5 ratings; needs 3 qualifying mods; switch off by default).
4. Seed content = REAL mods Cyrus built (owner batch, dungeon) under "Made by the Cyrus team" with the staff badge; no personas.
5. Share-ready pages so real creators can appear (author tag, canonical, JSON-LD, one-click install card).

## What shipped (all behind switches, all OFF)
- **Spotlight**: Setting `cyrus_spotlight_picks` (no migration), pure logic `lib/cyrus-site/spotlight.ts`, admin tab Spotlight (in All tools; add/remove picks, real counters, official accounts), `/api/cyrus/spotlight` (public, 5 min cache), landing generator `apps/cyrus-site/featured.mjs` shows badge + reason (`CYRUS_SITE_MODS_BASE=/mods` to link titles to cyrus.my pages). The old `cyrus_featured_pages` list still shows as staff picks.
- **Pages on cyrus.my** (internal tree `/cyrus-web`, rewrite in `lib/cyrus/bridge/routing.ts`, pure map `lib/cyrus/web-paths.ts`): `/games`, `/games/minecraft` (+ "soon" stubs, noindex), `/mods`, `/mods/<slug>` (hero, author tag + staff badge, real counters, Nxeon-logo install card with the 3-step one-click explanation, screenshots, commands, honest status block, versions, FAQ, JSON-LD), `/host`, `/host/<game>`, `/host/<place>`, `/host/<game>/<place>` (3 layouts + hub), `/blog`, `/blog/<slug>`, `/blog/rss.xml`. Same pages reachable on other hosts at `/cyrus-web/*` (noindex).
- **Hosting data is real**: GamePlan (46 priced families today), enabled Node regions (sgp1, fsn1, bhs1 = Singapore, Germany, Canada), live Coupon row, live token settings. Thin-page guard: only Cyrus-live games (Minecraft) indexable: 8 URLs today (hub, game, 3 places, 3 combos); the other ~135 combos render noindex and stay out of the sitemap; cap 2,000; owner can add games via `cyrus_host_index_games`.
- **Blog**: 5 posts (dungeon log with real numbers and failures, custom boss, creatures, prompt-to-plugin with 12 real builds, honest limits), each < 700 words, numbers pinned by tests, RSS, article JSON-LD, related posts.
- **Art**: 89 generated files in `public/cyrus/web` (8 scenes x 2 sizes in AVIF/WebP/JPG with fallback `<picture>`, 6 mod covers, 5 blog covers, 4 social cards, Nxeon logo), deterministic `scripts/cyrus/web-art/generate.py`, existing game art copied to `public/cyrus/web/games` (the Cyrus host only proxies `/cyrus/*`), real gameplay captures reused. 2.6 MB total.
- **Sitemap**: `/mods/<slug>` (quality bar only) and content pages join sitemap.xml behind their own switches (`CYRUS_SITEMAP_MOD_PAGES`, new `CYRUS_SITEMAP_CONTENT`). Existing path in the sitemap changed from `/mods/cyrus/<slug>` to cyrus.my's own `/mods/<slug>`.
- **nginx**: app-path regex gains `games|mods|host|blog`; `.patch`, check script and launch-eval list updated.
- Scripts (dry run by default): `scripts/cyrus/seed-official-mods.ts`, `scripts/cyrus/create-cyrus-coupon.ts`; fixtures + shots: `scripts/cyrus/content-fixtures.ts`, `content-shots.mjs`.

## Verified facts: discount code and tokens
- **Coupon "CYRUS" does not exist** (Coupon table: 12 rows: TRIAL798, STAY50, EXIT25, NXSAVE40, NXFLASH40, NEW25, COMEBACK50, WINTER50, WELCOME10, PEERPUSH20, LAUNCH50, FREEMONTH). No partner code CYRUS either (ReferralPartner 17 rows). So the pages print NO discount block today and the copy never promises one. The block renders by itself, with the row's real terms, when a coupon named by `cyrus_host_coupon_code` (default CYRUS) exists, is active, unexpired, not used up, GAME/ANY, not plan-locked or a trial; the Deploy buttons prefill `coupon=<code>`. The wizard has no URL auto-apply otherwise (customers type it).
- **Tokens on a server and on renewals are real**: `grantForGameServerPurchase` / `grantForGameServerRenewal`, wired in `lib/game-order.ts`, `lib/actions.ts` (renew now), `worker/billing.ts`. Conditions: charge > 0 (a $0 trial earns nothing until the first paid renewal), game in the grant scope (`cyrus_tok_grant_scope`, default `cyrus_games` = Minecraft only), account in the token economy (`cyrus_tok_live` or preview), idempotent per server+period. Defaults: purchase per month `clamp(round5(100 + 16 x monthly USD), 150, 750)`, renewal `clamp(round5(25 + 6 x USD), 40, 300)`, term cap 12 months, expiry max(90 d, term x 31 + 30), 2,000 per server, 3,000 held per account, 3 initial grants per account per 30 days, clawback on refund/cancel and deletion within 14 days. At default settings the cheapest Minecraft plan ($7.18) = 215 on purchase, 70 per renewal. The page computes this live with the same `serverGrant` and shows the block only while `cyrus_tok_live` is on and scope covers the game (so Valheim etc. promise nothing).

## Schema / settings additions
- Table `CyrusModViewDay(pageId, day, views)` (additive; `prisma db push` or `prisma/manual-migration-cyrus-content.sql`, IF NOT EXISTS). Added to `CyrusDb`. Until applied the pages say "New" and nothing throws.
- Settings (all default off/empty, in the settings catalog): `cyrus_content_public_enabled`, `cyrus_content_index_enabled`, `cyrus_spotlight_picks`, `cyrus_spotlight_popular_enabled`, `cyrus_official_user_ids`, `cyrus_host_coupon_code` (CYRUS), `cyrus_host_index_games`. Env: `CYRUS_SITEMAP_CONTENT`. Admin tab `spotlight` (SUPPORT + ADMIN), actions `spotlight.edit`, `official.set` (platform).
- Facts for seeding: prod has 26 CyrusModPage rows (2 PUBLIC, 24 PRIVATE), all from the owner account; the prod DB does not have the username columns yet (community schema push still pending).

## Verification
- `devhost tsc`: clean. New test `test/cyrus-content.test.ts` (55 tests) green; 340 tests across 20 cyrus files: 337 pass, 3 fail, all pre-existing and not in files touched here: cyrus-seo "legal pages use cyrusPageMetadata" (rc17 legal merge changed those pages), cyrus-seo "nginx vhost" (main's quoted `{16}` GSC location commit 1decf233 did not update the test), api-http-surface "unvetted throttle key" (16 other routes, known from CP). Fixed along the way: db-split baseline for the community branch's `username-store.ts` (0 -> 4, baseline only), SUPPORT tab list test, authz table + public allow-list for the new route.
- Seam: `lib/cyrus/web-paths.ts` lives under lib/cyrus (the routing imports it; the host-seam ratchet passes).
- Screenshots (1440 and 390, dark; light for two pages) of all 15 pages: /root/cyrus-content-shots/ (from the build host's throwaway DB with fixture rows; they show layout and the zero-count "New" states, taken before the "Mod of the week" card was switched to the wide feature layout). No horizontal overflow, 200s, no page errors.
- Not done: no run against production data, no live crawl, no CWV measurement; the one-click install itself is the existing portal flow (needs `cyrus_install_published_enabled`, otherwise the mod page offers the source download instead).

## Owner commands, in order
    cd /opt/nxeon && git merge feature/cyrus-content            # after review
    npx prisma db push                                          # adds CyrusModViewDay (+ community columns if not yet)
    scripts/deploy-staging.sh <ref>  ->  verify  ->  scripts/promote-production.sh
    cp /etc/nginx/sites-enabled/cyrus-my /root/cyrus-my.bak && cp deploy/cyrus/nginx-cyrus-my.conf /etc/nginx/sites-enabled/cyrus-my && nginx -t && systemctl reload nginx && bash scripts/cyrus/nginx-cyrus-my-check.sh --origin <origin-ip>
    # optional: the discount code (no default percentage; dry run first)
    set -a; . /opt/nxeon/.env; set +a
    NODE_PATH=/opt/nxeon/node_modules /opt/nxeon/node_modules/.bin/tsx scripts/cyrus/create-cyrus-coupon.ts --percent 20 --months 1 --first-time          # add --apply
    # seed the real mods (dry run prints what passes), then review /admin/cyrus/spotlight
    NODE_PATH=/opt/nxeon/node_modules /opt/nxeon/node_modules/.bin/tsx scripts/cyrus/seed-official-mods.ts --user <ownerAccountId> --slugs shop,quests,customrecipes,mushroommeadow --week shop --author-tag cyrus   # add --apply
    # open, in this order: cyrus_content_public_enabled; later cyrus_content_index_enabled + CYRUS_SITEMAP_CONTENT=1 (restart web), submit the sitemap
    # landing (optional, after the mods flag): CYRUS_SITE_FEATURED_JSON=https://cyrus.my/api/cyrus/spotlight CYRUS_SITE_MODS_BASE=/mods apps/cyrus-site/publish.sh publish --go

## Remaining owner decisions
1. Terms of the CYRUS code (percent/amount, first N months, first purchase only, cap, expiry) or no code at all.
2. Which real mods to publish and which is the first Mod of the week (the seed script lists the candidates and refuses failed flights/thin pages; slugs above are candidates, check titles in the dry run).
3. Which account is "the Cyrus team": the owner account itself (the script sets its author tag to `cyrus`, bypassing the reserved-word rule) or a separate account (would need a page ownership move, not built).
4. Open `cyrus_install_published_enabled` with the launch, otherwise mod pages offer the source download, not one-click install.
5. Token scope: today only Minecraft servers earn tokens; widen `cyrus_tok_grant_scope` only if the owner wants other games' hosting pages to promise tokens (pages follow it automatically).
6. Extra games into the host index (`cyrus_host_index_games`) vs keeping the matrix noindex (recommended until Search Console shows Minecraft pages indexing).
7. Canonical home of mod pages (cyrus.my vs nxeon.cloud, `CYRUS_SITE_PRIMARY`), and the `.my` geo-signal risk (CQ section 9).
8. Dungeon post: the mod has no in-game footage; if the owner plays it, add real screenshots (the post says so explicitly).

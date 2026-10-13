# SEO agent (N) progress note — 2026-10-01

Branch feature/seo-overhaul, worktree /opt/nxeon-wt-seo, sandbox DB nxeon_agt_seo (drop it: `sudo -u postgres dropdb nxeon_agt_seo`), .env in worktree is throwaway (gitignored; contains NXEON_SANDBOX=1, PORT=3120, NXEON_ADMIN_HOSTS=127.0.0.1).

## Done (committed)
- Audit evidence + recommendations: docs/SEO-AUDIT-2026-10.md (baseline score 94.4, game-location template worst at 80.8; wrong prices, S$ in titles, 73% orphaned game x location pages, www duplicate host, near-duplicate cluster 81-87%).
- Tooling: scripts/seo-audit.ts, seo-link-graph.ts, seo-speed.ts, seo-sitemap-index.ts; lib/seo-audit/*; tables SeoAuditRun/SeoAuditPage; worker/seo-audit.ts (weekly + admin queue + drop alert; hook = 3 lines in worker/index.ts); /admin/seo/audit page + "Site audit" button on /admin/seo.
- Fixes: sitemap sections (lib/sitemap-sections.ts), robots, llms.txt, price tokens (lib/seo-prices*.ts), title/description fitting (lib/seo-text.ts), index policy (lib/seo-index-policy.ts), /locations hub, ring related links, /compare crawlable links (app/nxm/_seo/links.ts), image lazy hints (lib/seo-html.ts), www->apex 301 (middleware.ts), JSON-LD url fix.
- Verified in sandbox (job v2): tsc exit 0, 16/16 unit tests, sitemap index + all sections 200, robots/llms output, www redirect 301, /compare nav present.

## Not re-verified after the last commits (7fe684d918 + docs edit)
tsc + tests were last green BEFORE: seo-text sentence-splitter fix (unit-tested OK via tsx), og:type website edits in app/nxm/_data/{location-landing,location-game,migrate-from,vps-vs-digitalocean}.ts, /locations h1, sitemap mod dedupe, audit timeout option. Re-run: `heavy.sh bash -c "cd /opt/nxeon-wt-seo && npx tsc --noEmit -p . && npx tsx --test test/seo-audit.test.ts"`.

## Not done
1. Prod Chromium speed numbers (LCP/CLS/TBT) never ran (heavy lock queue; flock -w 3600 expired). Command: `cd /opt/nxeon-wt-seo && npx tsx scripts/seo-speed.ts https://nxeon.cloud/ https://nxeon.cloud/vps https://nxeon.cloud/game-servers https://nxeon.cloud/singapore-minecraft-server-hosting https://nxeon.cloud/mods/minecraft/floating-horses` (through heavy.sh). Then add the table to docs/SEO-AUDIT-2026-10.md section 7 (it currently references a speed doc that does not exist — fix that sentence).
2. Screenshots of /admin/seo/audit and /locations (mobile+desktop) not taken; /admin/seo/audit untested in a browser (compiles; tsc clean). Script: scratchpad/seo/shots.mjs + verify3.sh (needs 127.0.0.1 as admin host, admin user seo-sbx@example.test / sandbox-seo-pass exists in the sandbox DB).
3. Sandbox audit pages show timeouts (cold dev compile) so sandbox scores are not meaningful; use --timeout 150000.
4. Owner decisions: mod sitemap floor (default 10000 downloads), game x location tail noindex switch (default off), AI training crawlers allowed by default, cache headers (private/no-store on all marketing HTML), footer link to /locations (agent J's footer).
5. Delete sandbox DB and scratch (/tmp/.../scratchpad/seo).

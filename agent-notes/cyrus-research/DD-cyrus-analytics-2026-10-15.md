# DD: Cyrus traffic and product analytics (2026-10-15)

Branch `feature/cyrus-analytics` (worktree `/tank/dev-worktrees/cyrus-analytics`), 2 commits on top of main `b447360d` (rebased after the SEO vhost fixes landed). Not merged, not deployed, not published, nothing applied to nginx or the database, `/opt/nxeon` untouched. Full page in the repo: `docs/cyrus/21-analytics.md`.

## What exists now vs before
| Need | Before (verified) | Now |
|---|---|---|
| Cyrus web traffic in the admin | none; 8 `Visit` rows touched Cyrus paths in 7 days | `/admin/cyrus/analytics` (tab "Analytics", ADMIN), 9 sections, 7/30/90 days, filters plan / source / country / device / human only |
| cyrus.my vs nxeon.cloud | `Visit` had no host column | `Visit.host` + `Visit.product` (`cyrus`/`nxeon`, NULL = legacy, no backfill) written by `/api/track` |
| Static landing | no beacon, invisible | `apps/cyrus-site/src/assets/js/a.js`, 2,023 bytes, first party, `sendBeacon` to `/api/cyrus/analytics/hit` |
| Cyrus app pages on cyrus.my | `/api/track` is not reachable there (middleware 404s POST) | `CyrusTracker` in the host shell, sign-in/up and legal pages, same endpoint |
| AI-assistant referrals | none | referrer host + `utm_source` (chatgpt.com, chat.openai.com, perplexity, claude.ai, gemini, copilot, you.com, phind, meta-ai, grok, deepseek, mistral, poe, duck-ai, kagi) |
| Attribution / conversions | 0 rows (flags off) | unchanged and still off; the suite reads `CyrusAttribution` for account sources when it fills |
| Funnel / cohorts / retention / prompt analytics | none | landing funnel (page loads), ordered account funnel with medians, weekly cohorts D1/D7/D30, product and money sections |
| Export / API / digest | none | CSV per table + JSON (`/api/admin/cyrus/analytics`, audited), weekly digest (off) |

## What it measures and how (all human-only, bots counted apart)
1. **Collection.** Beacon events once per page load: `view`, `scroll50`, `scroll90`, `prompt_focus`, `prompt_submit` (no text), `plans_view`, `signin_click`, `signup_click`. Body: path, referrer hostname, UTM, webdriver flag; with analytics consent also a random 30 day id (`cyrus_vid`), session id and `?ref=`.
2. **Server rules** (`decideHit`, pure, tested): flag off -> 204; `DNT: 1` / `Sec-GPC: 1` -> dropped before anything; same-origin only; consent read from the cookie server side; bots (UA catalogue, datacenter/flagged IP, webdriver) only counted (`CyrusDailyMetrics web.bot_hits`, batched); IP and UA never stored (country + device class derived, address discarded).
3. **Product events** from existing facts, no new write path: first Cyrus sign-in (`ActivityEvent auth.login` method `nxeon-sso`/`google-cyrus`), signup/new-to-Nxeon (`User.createdAt` within 24 h), username (`CyrusCreator`), first prompt/build (`ModBuild`), build ok/failed by lane/errorCode/model (`ModBuild`, `cyrus.assets.planned.lanes`), Test Flight verdict (`cyrus.testFlight`), first install (`lastInstall.at`), refine (`baseBuildId`), top-up/plan purchase (`CyrusTokenLedger`), published mod (`CyrusModPage`), library save/fork/use (`CyrusLibraryItem`/`CyrusFork`/`CyrusLibraryUse`). One NEW write: `plan_shown` (`CyrusProductEvent`, written by `/api/cyrus/plan`, game + version + change flag only).

## Metric definitions (also printed on the Data quality tab, one source: `lib/cyrus/analytics/definitions.ts`)
- **Human page view**: beacon hit, not bot, not webdriver, no DNT/GPC (same human rule as `/admin/conversion`, parity pinned by a test).
- **Visitor**: distinct rotating anonymous id, a consented SAMPLE, never extrapolated. Unique visitors for people who declined do not exist by design (no identifier); they are page views.
- **Landing funnel**: page loads that did the thing (each event sent at most once per load).
- **Account funnel**: first sign-in, username, first build, first success, first install, paid. Counted at a step if reached or any later step; medians from in-order pairs only; skipped and out-of-order counts shown.
- **Activated**: at least one succeeded build. North star shown separately: median time first seen -> first install and share within 24 h.
- **First try**: succeeded with `attempts = 1` (0 = unknown, never counted). **Success rate**: succeeded / (succeeded + failed).
- **Abandoned build**: failed/cancelled and no build by the account within 24 h. **Plan abandoned**: `plan_shown` with no build within 30 min.
- **Cohort Dn**: share of ELIGIBLE accounts (a whole day n has passed) that built on exactly day n after first seen; `Dn+` = day n or later; counts printed.
- **Revenue**: live-mode ledger purchases; test mode apart. **MRR**: last paid plan invoice of each live active subscription (no list price); those without are excluded and counted. **Margin**: revenue - measured AI cost - estimated card fees; cost on accounts that never paid shown.
- **Excluded**: staff accounts and `cyrus_analytics_exclude_users`.

## Schema additions (additive; SQL for review `prisma/manual-migrations/2026-10-15-cyrus-analytics.sql`; the normal `prisma db push` in promote creates them)
- `Visit.host String?`, `Visit.product String?`, index `(product, createdAt)`. `/api/track` retries without them while the columns are missing (no page view lost before the push).
- `CyrusWebEvent` (raw human events, 90 days): no IP, no UA, no cookie value, no prompt, no account id.
- `CyrusDailyMetrics` (durable aggregates, unique `(date, key, dim)`).
- `CyrusProductEvent` (`plan_shown`, unique dedupe key; in `CYRUS_GDPR_TABLES` as delete).
All three are in the `CyrusDb` seam type; writers and readers fail soft until the tables exist (the page says "missing, push pending").

## Privacy and legal
- DNT / GPC honoured (client and server); no identifier or cookie without analytics consent; consent older than 180 days or from the future is no consent; no third-party scripts; IP never stored by analytics (hashing was not needed because nothing is kept).
- Retention: raw events 90 days (purged by the nightly rollup, batched), aggregates kept.
- `lib/legal/cyrus.ts` is on main: updated to version 1.1 (what is measured, DNT/GPC, `cyrus_vid` cookie, product analytics, 90 days). Still a draft for legal review. The banner text already says "Analytics: visits, referral code and campaign tags".

## Owner commands (nothing was run)
```
# 1. promote (schema push creates the tables/columns, ships page + collector); then:
cd /opt/nxeon && scripts/deploy-staging.sh feature/cyrus-analytics   # look at /admin/cyrus/analytics on staging first
scripts/promote-production.sh
# 2. turn collection on (web + worker env, then restart)
#    CYRUS_ANALYTICS=1
systemctl restart nxeon-web nxeon-worker
# 3. landing: ships assets/js/a.js
apps/cyrus-site/publish.sh check && apps/cyrus-site/publish.sh publish && apps/cyrus-site/publish.sh publish --go
# 4. nginx (optional hardening; the path is already inside the api/cyrus prefix). Applying this also applies the quoted
#    Search Console location fix that is on main but not in the live file yet:
cp /etc/nginx/sites-enabled/cyrus-my /root/cyrus-my.bak && cp deploy/cyrus/nginx-cyrus-my.conf /etc/nginx/sites-enabled/cyrus-my && nginx -t && systemctl reload nginx && bash scripts/cyrus/nginx-cyrus-my-check.sh --origin <origin-ip>
# 5. optional: rebuild history from existing facts (builds, ledger, accounts) into CyrusDailyMetrics
npx tsx scripts/cyrus/analytics-rollup.ts --days 90
# 6. optional: weekly digest (Audit & settings): cyrus_analytics_digest_enabled=true, cyrus_analytics_digest_to=<emails>, cyrus_mail_from valid
```
Flag recommendation: `CYRUS_CONSENT=1` and `CYRUS_ATTRIBUTION=1` together once the banner copy is reviewed (they store nothing before a choice; attribution fills the account-source table). Keep `CYRUS_CONVERSIONS` OFF until paid tests start and the queued-conversion-after-withdrawal gap (CT) is closed. Decide whether the static landing shows the banner (`<script src="/cyrus/consent.js" defer>`): without it every landing visit is an anonymous hit (page view counted, no visitor id, no funnel linkage), which the page states.

## Tests and checks
- New: `test/cyrus-analytics.test.ts` (91: source/AI detection, path cleaning, collector decision incl. DNT/GPC/consent/bots/cross-origin, landing beacon executed in a VM against the same cases as the app tracker, funnel ordering/skips/out-of-order, cohorts maturity, lanes/images/first-try/abandoned, money honesty (test mode, MRR, null cases), CSV injection, rollup determinism, digest, wiring and privacy source guards incl. "no analytics table has an ip/ua/prompt column"), `test/cyrus-analytics-render.test.ts` (every tab rendered from fixtures with data and empty, no NaN/undefined, honest empty states, no email/IP in markup).
- Updated for the new surfaces: `cyrus-worker-schedule` (14 sweeps), `_cyrus-authz-table` + `cyrus-security-review` (2 routes, public allow-list), `cyrus-nginx-vhost` (beacon block + patch), `cyrus-seo` (two assertions that were already stale on main: quoted vhost regex, Cyrus legal metadata helper).
- Results: `scripts/devhost test` of all 209 `test/cyrus*.test.ts` + conversion/bot/renewal suites: 3,976 tests, 3,973 pass; the 3 failures were `cyrus-liveassets-e2e` (also fails on pristine main: mid-stream cubes timing) and two stale assertions in `cyrus-seo.test.ts` (also failing on pristine main; fixed in the second commit and re-run green: 144/144 for seo + vhost + both analytics files). `scripts/devhost tsc`: clean (exit 0) before the last two small edits; the final run on the final tree is recorded at the end of this note. docs reference regenerated (`docs-build.ts --check`: current).

## Limits and gaps (honest)
- Visitors are a consented sample; with no banner on the landing there are none there. Landing -> account cannot be joined without consent, so "accounts per 100 landing views" is a ratio of counts.
- No per-download record for public mods/jars; install failures not stored (`lastInstall` is success only); no in-game signal; plan-screen events start at collection; per-image success rate impossible (only successes carry a release record); account country/device not stored.
- First install uses the latest install per build (`lastInstall` is overwritten), so first install is approximate for re-installed builds.
- Bot counters are in-memory batched (a restart loses up to ~10 s of counts); counts only, no per-bot detail beyond kind.
- The Nxeon `/admin/visitors` and `/admin/analytics` pages still mix Cyrus rows into Nxeon traffic (the `product` column exists; a filter there is a follow-up, deliberately not touched to avoid changing Nxeon numbers).
- Search Console panel needs the platform GSC connection to include a cyrus.my property (runbook in `docs/cyrus/18-seo.md`); it shows an honest "no property yet" otherwise.
- Not browser-verified: pages were rendered from fixtures (markup, no NaN/undefined, empty states) but not clicked through on staging; do that on the staging deploy.
- Pre-existing, not touched: `cyrus-liveassets-e2e` mid-stream test fails on main.

## Final check
`scripts/devhost tsc` on the final tree (commit `e83d729d`): exit 0, no output. Working tree clean.

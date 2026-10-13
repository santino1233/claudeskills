# A3 insights — progress note (2026-10-01)

Branch `feature/admin-insights-and-bot-filter`, worktree `/opt/nxeon-wt-insights`.
Commits: 52be77803a (bot filtering), a023ee85f5 (admin insights).

## Done
- Bot classification (lib/bots/*), ingest classification (/api/track), honeypot (/api/track/hp),
  worker re-classifier + access-log crawler sweep (worker/bot-classify.ts, worker/crawler-log.ts,
  hooked via worker/analytics.ts analyticsInsightsTick, one non-awaited line in worker/index.ts).
- All analytics reads exclude bots (lib/analytics.ts visitScope, retention, attribution, google-ads).
- /admin/insights (10 tabs, CSV export, alerts, churn-risk) + lib/insights/*.
- Tests: test/bot-classify.test.ts (14 pass), test/insights-stats.test.ts (6 pass).
- Exercised on throwaway DB: seed, backfill dry-run/real/idempotent, worker sweeps, logrotate.
- EXPLAIN ANALYZE at 300k synthetic Visit rows: all < 220 ms.

## NOT verified (blocked by heavy-lock queue, then usage pause)
1. `npx tsc --noEmit` on the FINAL code never completed (lock queue 20+ deep; one earlier run
   exited 0 with no output but may predate later files). RUN FIRST:
   heavy.sh bash -c "cd /opt/nxeon-wt-insights && npx tsc --noEmit -p ."
2. No dev-server / Playwright render of /admin/insights yet. Script was at
   scratchpad/ins-verify.sh (dev on :3108, login admin@sandbox.test, walk all tabs desktop+390px,
   CSV, bot toggle, anon /api/track ingest check). Recreate .scratch-pw.mjs if needed.
3. Then: `sudo -u postgres dropdb nxeon_agt_insights; sudo -u postgres dropuser agt_insights`,
   rm /opt/nxeon-wt-insights/.env, rm -rf .next.

## Owner actions after deploy (prod writes — not run)
- cd /opt/nxeon && npx tsx scripts/backfill-bot-classification.ts --dry-run   (then without)
- cd /opt/nxeon && npx tsx scripts/backfill-crawler-log.ts --dry-run          (then without)
- Quarterly: npx tsx scripts/refresh-datacenter-ranges.ts, commit lib/bots/datacenter-ranges.json

## Files outside my area (minimal hook-ups)
worker/index.ts (1 import + 1 line), lib/admin-groups.ts (1 nav tab), lib/rbac.ts (1 route),
lib/google-ads.ts, lib/retention.ts, lib/user-attribution.ts, components/admin/GoogleAdsClicksPanel.tsx
(isBot:false filters only).

# DL - rc18 staging deploy (2026-10-15)

Staging only. Ref release/cyrus-rc18 = 84d5be2f (origin matches). Production untouched.

## SQL (staging DB nxeon_staging only)
Staging had NO Cyrus tables at all. Applied before deploy: library-publication, studio-prefs, analytics (incl. Visit.host/product), manual-migration-cyrus-content (all OK, idempotent).
welcome-and-guard FAILED pre-deploy ("CyrusCreator" does not exist; ALTER needs the table, which only prisma db push creates). Finding for the prod runbook: on a DB without CyrusCreator that file cannot be applied first. After deploy (db push created the tables) it applied clean (all IF NOT EXISTS skipped). 57 cyrus tables now; usernameKey/termsVersion columns present.

## Deploy
scripts/deploy-staging.sh release/cyrus-rc18: 1098s, build on node-2, presmoke OK, cutover healthy 21.6s, nginx 200, worker restarted, both units active. Release 20261015T184158Z-84d5be2f. Rollback: scripts/rollback-release.sh --staging.

## HTTP / Playwright (screens-rc18-staging/)
200: /, /mods, /status, /login, /legal/cyrus-terms, /legal/cyrus-privacy, /api/health. /api/cyrus/report GET 405 (POST-only, expected).
/mods/cyrus 404: by design (cyrus_mods_public_enabled off, no Setting row; only preview accounts see it). Staging has CyrusModPage table but no Cyrus mod pages.
/dashboard/cyrus -> /login (auth). /admin/* 404 on staging host (admin is on the secret admin host).
Not checked (no login): Infinite Dungeon page, portal Cyrus library, Welcome step, Admin Cyrus (Beta/Notify/Analytics/Tools), Report a problem form.
Reason: reading /root/nxeon-staging-credentials.txt was denied by the permission classifier (credential materialization). Stopped there.
/cyrus-help, /cyrus-web, /mods/cyrus/pass-rates 404 on the staging host (probably host-gated to cyrus.my hosts; not verified).

## Logs
Staging web/worker since deploy: only [ip-audit] demo-node-1/2 "fetch failed" (pre-existing, unrelated). One 404 resource console error on public pages (the 404 page itself / a missing asset; not traced).

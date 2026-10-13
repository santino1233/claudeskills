---
name: nxeon-seamless-deploys-request
description: Owner wants production deploys with zero disruption — promote script currently builds inside the live tree and breaks prod during builds
metadata:
  type: project
---

Owner (2026-10-01): production builds must not disrupt the live app; deploys should be seamless.

**Why:** `scripts/promote-production.sh` runs `npm run build` in /opt/nxeon, wiping `.next` under the running server (static chunks 400, partial routes), and a hung build (11 min, ~1% CPU) left prod half-dead; concurrent promotes also collide (ENOTEMPTY `.next/export`).

**How to apply:** build only outside the live tree, release dirs + atomic symlink swap + keep last 3 + flock + build timeout/memory guard. Details in /root/FLEET-STATUS-2026-10-01.md ("OWNER REQUEST"). Related: [[nxeon-deploy-use-promote-script]].

**2026-10-08: blue/green ACTIVATED (owner-approved).** Every deploy since 10-07 still had 80-90 s of 502s. The phase-2 code existed, but `/etc/nginx/conf.d/nxeon-web-upstream.conf` was missing and 8 `proxy_pass http://127.0.0.1:3000` lines (sites-available: nxeon, nxeon-cloud, nxeon-admin-cloud, nxeon-staff) bypassed it, so the script fell back to restart cutover.
- **Fix:** I created the upstream `nxeon_web { server 127.0.0.1:3000; }`; that line must stay exactly `server 127.0.0.1:<port>;` because the script rewrites it. I pointed all 8 at `http://nxeon_web` and did a graceful reload. `bluegreen_available` now returns YES.
- **Backup:** /root/nginx-backup-20261008T072820Z.
- **To check:** the first deploy after this should log "Blue/green: warming the new release on :3092".

**VERIFIED 2026-10-08 08:24-08:42 UTC:** the first deploy after the nginx upstream switch (release e51fcefe) logged "Blue/green: warming the new release on :3092" then "nginx now proxies to :3092 ... :3000". A probe of https://nxeon.cloud/login every 0.5 s across the whole 1022 s deploy got 1689/1689 HTTP 200 (previous deploys: ~85 s of 502s). The "Healthy 109.5s after restart" step runs with NO traffic on it, so it no longer matters. Don't let agents hold node-2's 10 GB slice during a promote: build peaks ~9.4 GB (a stall hit once with agents at 6.8 GB).

**2026-10-08 owner: "for deploys, only rebuild pages that are actually affected."** Findings: ~930 routes, only 9 static/SSG; 922 are dynamic (rendered per request), so there is nothing per-page to skip. The webpack cache (/tank/nxeon-deploy/production/build/.next/cache/webpack, 773 MB) IS reused across builds. Build time swings 87 s (quiet node-2) vs 3.1 min (agents running) for the same compile; total 505 s on 10-08. Plan agreed in chat: (1) add per-step timestamps to the node-2 build log, (2) reserve the release build's CPU/memory so agents can't squeeze it, (3) A/B `next build --turbopack` on a copy when node-2 is quiet, compare output, only then consider prod. Not done yet.

# NX hardening after the 2026-10-15 scraper incident

Branch `feature/nx-hardening` (worktree `/tank/dev-worktrees/nx-hardening`), 2 commits on top of main 98d82fe0:
`7c537add` (app/DB/telemetry/nginx), `14d3f93b` (stagger + alerts). NOT merged, NOT deployed. `tsc` clean and
`list-guard`, `nx-hardening-alerts`, `telemetry`, `cyrus-alert-eval`, `seo-cache` tests pass via `scripts/devhost`.
docs/DOCUMENTATION.md: new section "Platform hardening after the 2026-10-15 scraper incident" (appended, same convention as the Dropbox section).

## What changed

### 1. App-level list protection
- `lib/list-guard.ts` + `middleware.ts`: GET/HEAD on any non-authenticated path with `page` > 100 (env `NXEON_MAX_PUBLIC_PAGE`) or
  `offset|skip|start` > 2500 is 404 from middleware, before any page/DB work. Handles `page=2&page=99999`, `1e9`, `Infinity`.
  List-shaped URLs (q/page/sort/category/loader/version/...) limited per IP, 90/min (`NXEON_LIST_RATE_MAX`), 429 + Retry-After.
  Untouched: /admin /staff /dashboard /api /_next, static files.
- `queryCatalogMods` (behind /mods, /mods/games/<family>, NxLabs) clamps page (100) and perPage (100), memoises `COUNT(*)` 120 s and
  pages 1-5 without free text 60 s, single-flight (`lib/ttl-cache.ts`). `latest` now `(createdAt desc, id desc)`.
  `browseMods` cap 400 -> 100, blog index and taxonomy `queryMods` clamped, dashboard NxLabs cap 10000 -> 100.
- Anonymous `Cache-Control` for /mods* already existed (`lib/seo-cache.ts`, s-maxage=300); unchanged.
- Keyset pagination NOT done on purpose: pager is numbered/SEO-linked; with the cap OFFSET <= 2,400 rows on the `createdAt desc` /
  `downloads desc` indexes. Cursor pattern to copy if ever needed: `listModComments`.
- Public-route audit of unbounded `findMany`: only the catalogue/blog reads are large-table; the rest are small config tables
  (plans, prices, sitemap lists). Admin lists (`paginate()`) are authenticated and clamp to the real page count (not capped; admin
  game-mods can legitimately reach page ~1800).

### 2. Query safety
- Today: role `nxeon` for web AND worker, `statement_timeout=0`, `max_connections=100`, `shared_buffers=128MB` (default),
  `log_min_duration_statement=-1` (no slow-query log), 22 connections idle/active at idle time.
- `lib/db.ts` + `lib/db-url.ts`: `NXEON_DB_CONNECTION_LIMIT` / `NXEON_DB_POOL_TIMEOUT_S` (opt-in, explicit URL params win).
- `deploy/postgres/nxeon-web-role.sql`: login `nxeon_web` (member of `nxeon`) with CONNECTION LIMIT 40, statement_timeout 20s,
  idle_in_transaction 30s, lock_timeout 10s; slow-query log settings as comments (owner applies).
- `deploy/nxeon-web.service.d/db-limits.conf.example`: points only nxeon-web at the new role + pool 12 / pool timeout 8 s.

### 3. Telemetry ingest
Was already batched (shipper <=50 events/3 s, one `createMany`, 200-event clamp, rate limit 40/min per token). Real costs: one
Server lookup per batch, limiter keyed on the raw token (unbounded buckets from random tokens), no body cap. Fixed:
token->principal 60 s memo (hash-keyed, incl. negative), failed-auth throttle per IP (30/min; no per-IP limit on good traffic because VMs
share the NAT address), 512 KB cap, hashed limiter key, Retry-After. 30% of requests is simply ~1 req/3 s per active VM: expected volume;
if it must drop further, raise `batchInterval` in `agent/nxeon-shipper/main.go` (needs shipper rollout; not done).

### 4. Backup scheduling
Current timers (UTC; all Persistent, Nice/IO as shown): 
| Unit | When | Class today |
|---|---|---|
| nxeon-integrity | daily ~00:10 (+30m rand) | none |
| nxeon-backup-db | 03:15 (+5m) | Nice 10, best-effort 7 |
| nxeon-nightly-scan | 03:30 (+5m) | none (npx tsx) |
| cyrus-backup | 03:40 (+15m), timeout 14h | Nice 15, idle |
| dropbox-sync databases | 03:50 (+10m) | Nice 15, idle |
| nxeon-backup-vms (vzdump 465 GB) | 04:30 (+10m), took 04:30-05:17 on 10-15 | Nice 10, best-effort 7 |
| nxeon-verify-restore | 05:30 (+5m) | Nice 10 |
| dropbox nodes / apps | 05:40 / 06:10 | Nice 15, idle |
| dropbox vms | Sun 06:30 | Nice 15, idle |
| restore drill | Mon 07:30 | Nice 15, idle |
Observed overlap: cyrus-backup (03:40, SFX copy, up to 14 h) ran straight through the 04:30 vzdump and the 05:3x jobs; it ended
`Failed with result 'signal'` at 05:07 on 10-15 (killed during the incident; check it finished the next run).
Proposed (in repo): cyrus 01:30 with `TimeoutStartSec=3h`; db 03:15; scan 03:35; dropbox databases after db; vzdump 04:30
(waits up to 1 h for load5<6 and no cyrus/dropbox-vms; never starts on top of them); verify 05:45; slice `nxeon-backup.slice`
(CPUWeight 10, MemoryMax 2G); `Nice=19`, `IOSchedulingClass=idle`, `CPUQuota` 100-200%, `MemoryHigh`; `After=` serialisation;
`ExecCondition=load-guard.sh` (load5, memory PSI, io PSI, not-while units). vzdump: `bwlimit: 61440` + `ionice: 7` in
`/etc/vzdump.conf` (ionice is a no-op on NVMe scheduler `none`; the real limits are bwlimit, CPUQuota and the guard).

### 6. Alerting
`deploy/cyrus/alert-rules.json` + `scripts/cyrus/alert-check.sh` (cyrus-alerts.timer, installed, every 5 min; Discord webhook is still
NOT set in /etc/cyrus/alerts.env, so alerts only print to the journal until it is): `web-p95-latency` (>2 s, 5 min window),
`web-5xx-rate` (>2%), `db-active-connections` (>30 active or >80 total), `db-long-queries` (>60 s on nxeon), `host-load-average`
(load5 > 2.5 per thread), `host-swap-used` (>=90% AND memory PSI some avg60 >=10%). The two web rules need the `nxeon_timed` log
from the nginx file (until then they return "" = no alert).

## Owner commands (nothing below was run by the agent)

Prereq: merge `feature/nx-hardening` and promote through staging (`scripts/deploy-staging.sh`, verify, `scripts/promote-production.sh`).
Until then use the worktree path in place of /opt/nxeon in the `install.sh` call (it copies the guard script to /opt/nxeon).

A. nginx (order matters: install the http-level file, then the vhost lines):
```
sudo cp /opt/nxeon/deploy/nginx/nxeon-list-guard.conf /etc/nginx/conf.d/nxeon-list-guard.conf
# in /etc/nginx/sites-available/nxeon-cloud (and nxeon if public), inside each server { }, replace the emergency
#   if ($request_uri ~* "^/mods(/[^?]*)?\?.*page=[0-9]{3,}") { return 444; }
# with the 5 lines at the bottom of the conf file:
#   if ($nx_deep_page) { return 404; }   if ($nx_deep_offset) { return 404; }
#   limit_req zone=nxeon_lists burst=20 nodelay;   limit_req_status 429;
#   access_log /var/log/nginx/nxeon-timed.log nxeon_timed;
sudo nginx -t && sudo systemctl reload nginx
curl -s -o /dev/null -w '%{http_code}\n' 'https://<site>/mods?page=8000'     # 404
```
Add `/var/log/nginx/nxeon-timed.log` to /etc/logrotate.d/nginx. (Behaviour was verified on a scratch nginx: page 100 ->200, 101 ->404,
list URLs 429 after burst, plain URLs never limited. Note /var/log/nginx is already 522 MB: forensic.log(.1) 150 MB; consider
rotating it daily.)

B. Postgres role + web limits:
```
W=$(openssl rand -base64 24 | tr -d '/+=')
sudo -u postgres psql -v web_password="'$W'" -f /opt/nxeon/deploy/postgres/nxeon-web-role.sql
sudo -u postgres psql -c "ALTER SYSTEM SET log_min_duration_statement='1000'" -c "ALTER SYSTEM SET log_lock_waits=on" -c "SELECT pg_reload_conf()"
sudo install -d /etc/systemd/system/nxeon-web.service.d
sed "s/PASSWORD/$W/" /opt/nxeon/deploy/nxeon-web.service.d/db-limits.conf.example | sudo tee /etc/systemd/system/nxeon-web.service.d/20-db-limits.conf >/dev/null
sudo chmod 600 /etc/systemd/system/nxeon-web.service.d/20-db-limits.conf
sudo systemctl daemon-reload && sudo systemctl restart nxeon-web
```
Rollback: delete the drop-in, daemon-reload, restart nxeon-web.

C. Backup stagger:
```
sudo /opt/nxeon/deploy/backup/stagger/install.sh --dry-run
sudo /opt/nxeon/deploy/backup/stagger/install.sh
systemctl list-timers 'nxeon-*' 'cyrus-*' --no-pager
sudo /opt/nxeon/deploy/backup/stagger/install.sh --revert      # to undo
```

D. Alerts: nothing extra once A is installed; test with `/opt/nxeon/scripts/cyrus/alert-check.sh --dry-run`. Set
`CYRUS_ALERT_DISCORD_WEBHOOK` in /etc/cyrus/alerts.env so they leave the box.

## 5. Capacity (report only, nothing changed)

Memory: 62.6 GiB usable; used 58.9, available 5.2, swap 2 GiB total (2 x 1 GiB partitions, 100% used; swappiness 60).
- Running guests (RSS): sausaugepro 7.3, projectzomboid 5.8, nxeon-mail 4.4, blue 4.3, studionexis-soul 4.2, bujangsmp 4.1, hosting-1 4.1,
  kodely-app 2.8, valheim 2.7, nexis-app 1.8, coldemail-relay 0.55 = ~41 GiB. Configured memory of the 11 running guests is
  62.5 GiB, i.e. the guests alone are allocated 100% of host RAM; ballooning (min values 1.5-6 GiB) is what keeps it afloat.
- Host: ZFS ARC 8 GiB (cap `zfs_arc_max`=8 GiB, hit rate fine), /tmp is tmpfs (3 GiB used, most of it `/tmp/claude-0` scratch,
  counts as RAM), next-server 2.0 (web), postgres ~2.0, node (worker etc.) 1.3, a Claude process 0.8, pveproxy/pvedaemon 1.1.
- 121 (PZ) and 658 (sausaugepro) started recently; the box went from "tight" to "no headroom" with them.
Safe recommendation (do none during peak): (1) do not start/provision more guests on the primary until >=10 GiB `available`
(use node-2); (2) clear `/tmp/claude-0` stale scratch (frees RAM, not disk); (3) lower ARC to 4 GiB
(`echo 4294967296 > /sys/module/zfs/parameters/zfs_arc_max`, persist in /etc/modprobe.d/zfs.conf; tank is mostly cold backups) - frees 4 GiB
at the cost of some backup read speed; (4) shrink over-allocated idle guests (blue 8 GiB/4.3 used, hosting-1 8/4.1, studionexis-soul 8/4.2,
nxeon-mail 6/4.4) at their next maintenance window; (5) put an `nxeon_web` pool of 12 (above) so the web process stops growing under flood;
(6) swap is only 2 GiB: "swap full" is expected and not itself an outage; watch memory PSI (the new alert does).

Disk: `/` is `/dev/md3` 49 GB, 40 GB used (87%), 6.5 GB free. IMPORTANT: `/tank` is ZFS (2.6 TB, 10% used), so old releases in
`/tank/nxeon-deploy` and `/tank/dev-worktrees` do NOT relieve root. What sits on root:
| Item | Size | Safe action |
|---|---|---|
| /root/claudeskills (.git 2.3 G pack, local-pc 3.4 G, agent-notes 1.9 G) | 7.6 G | owner decision; `git gc --aggressive` on the repo, move `local-pc` and big agent-notes artifacts to /tank/claude-scratch and symlink |
| /root/.claude/projects transcripts (3 files 0.5-1.0 GB) | 4.5 G | `find /root/.claude/projects -name '*.jsonl' -mtime +14 -size +50M` then `mv` to /tank/claude-scratch/transcripts/ (do not delete live sessions) |
| /root/.claude/remote | 1.2 G | same, `du -sh /root/.claude/remote/*` first |
| /var/lib/postgresql | 5.5 G | live data, leave |
| /opt/nxeon + /opt/nxeon-staging (node_modules 1.2 G each) | 5.3 G | needed |
| /var/log/nginx | 522 M | `logrotate -f /etc/logrotate.d/nginx`; forensic.log.1 124 M + access.log.1 104 M after compress `gzip /var/log/nginx/*.log.1` |
| /root/workspace-app-src (ws.tgz 660 M + whisper model 461 M) | 1.5 G | `mv` to /tank if unused |
| /root/.cache 380 M, /var/cache/apt 113 M, /root/.npm 39 M | 0.5 G | `apt-get clean; rm -rf /root/.cache/*` (regenerated), `npm cache clean --force` |
| journal | 159 M | `journalctl --vacuum-size=100M` |
| /root/nxeon-worktrees | 257 M | `git -C /opt/nxeon worktree list` then remove merged ones with `git worktree remove` |
Fastest safe ~6-8 GB: move the old .claude transcripts + claudeskills local-pc to /tank (about 5-6 GB), gzip nginx logs (0.2 GB),
apt/npm/.cache (0.5 GB). On /tank (not root-relevant): production releases keep 5, the two oldest (20261013T162135Z..., 20261014T183533Z...,
~450 MB each) are removable after the current and previous release have been verified: `rm -rf /tank/nxeon-deploy/production/releases/<dir>`
(never the one `/opt/nxeon/.next` points to: 20261015T051903Z-98d82fe0-...). docker is not installed.

## Risks
- Middleware 404 above page 100 changes SEO for pages that existed (/mods?page=101..N): they dropped out of the cap the nginx
  rule had already imposed; sitemap links only page 1 per family, so no sitemap URL is affected. Raise `NXEON_MAX_PUBLIC_PAGE` if wanted.
- 20 s `statement_timeout` for nxeon_web will cancel any heavy admin report/export run through the web process (admin analytics,
  `/api/admin/export`, big `groupBy` insights); those would show as 500s. Run `ALTER ROLE nxeon_web SET statement_timeout='60s'` if the
  first days show cancellations (`log_min_duration_statement` will name the query).
- The per-IP list limit in the app is per-process and in-memory (resets on restart); distributed floods are bounded by the page cap and
  caches, not by this. Cloudflare/real-IP: it uses X-Real-IP set by nginx.
- Principal memo: a freshly minted telemetry token that was rejected once stays rejected up to 60 s.
- Result cache shares one catalogue page across viewers for 60 s: new mods can take up to 1-2 minutes to appear on pages 1-5.
- `cyrus-backup` `TimeoutStartSec=3h` will cut the first big SFX upload; it resumes next night (restic/rsync resume). If you prefer it
  to always finish, drop that line and rely on the guard (vzdump then waits up to 1 h and is skipped if cyrus is still active).
- A skipped (load-guarded) backup is a quiet `ExecCondition` skip, not a failure; `launch-check` backup-fresh and `backup-stale`
  (26 h) are the safety net.
- Not done: the web service has no `MemoryHigh`; no shipper interval change; no keyset pagination; admin list pages not capped.

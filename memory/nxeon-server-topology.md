---
name: nxeon-server-topology
description: "Which apps live on which VPS after the 2026-08-04 isolation split — 51.79.226.200 is the LIVE Soul Pilates box, 51.79.226.215 is the dev box"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-04T14:49:04.363Z
---

Two production VPSes after the 2026-08-04 isolation move (reason: protect the LIVE Soul Pilates business from AI-caused damage while working on dev apps). See [[nxeon-migration-reliability]].

**51.79.226.200** (hostname `studionexis-soul`, server id `cmsc9l72y000ghl7iyd87u5ja`) — TREAT AS PRODUCTION / DO NOT EXPERIMENT HERE:
- Soul Pilates (LIVE business, real customers): `/opt/soulpilates` compose stack — 9 `soulpilates-prod-*` containers (backend :3719, api/hubs :8391, rustfs :6324, mongo, redis, glitchtip). nginx `00-soulpilates-com.conf` (canonical, 00- prefix wins).
- Soul Pilates mail = the **Nxeon Mail product** (central Mailcow at `mail.nxeon.cloud`; submission on internal `10.20.0.10:587` AND publicly via the `NXEON_MAIL` iptables DNAT on the Proxmox host, cert CN=mail.nxeon.cloud). FINAL state 2026-08-04 (supersedes the interim `.200` docker-mailserver cutover): `soulpilates.com.vn` is a Business Email **EmailSubscription** under user `nicholas.sj.albanese@gmail.com` (id cmrztujaw0002hlazl58i3lsi), plan "Unlimited" (internal, mailboxes 9999, active=false). Mailboxes contact@/admin@/noreply@ live on the central Mailcow, visible in the customer portal's own Inbox UI (`/dashboard/mail`) — NOT the scrapped external SOGo webmail at mail.nxeon.cloud (that link was removed from EmailHosting.tsx). DNS: MX→mail.nxeon.cloud, SPF `v=spf1 include:nxeon.cloud ~all`, DKIM selector `dkim`. The Soul Pilates .NET app on .200 relays outbound through `mail.nxeon.cloud:587` as noreply@ (prod.env; `prod.env.bak-200mail` = rollback to the interim .200 server, `prod.env.bak-brevo` = original). Test emails (welcome/booking/invoice + relay-live) delivered to haxkodi@gmail.com inbox, SPF/DKIM/DMARC pass. OUTSTANDING user DNS: delete the old `mail.soulpilates.com.vn` MX (priority 1) so inbound routes to Nxeon Mail. The `.200` `/opt/mailserver` docker-mailserver is now superseded/retireable for SP. Mailcow API config: MAILCOW_API_URL/KEY in /opt/nxeon/.env. See [[nxeon-dkim-unsigned]].
- `/opt/studionexis` compose stack (backend/frontend/mongo/redis/rustfs) serving `studionexis.soulpilates.com.vn` via `nxeon-migrated.conf` — a SEPARATE older app, NOT migrated to .215. Still running here. Candidate to also move/retire but left in place (removing breaks that URL with no replacement).
- Soul Pilates Mongo backups: `/usr/local/bin/soulpilates-backup.sh` + `/etc/cron.d/soulpilates-backup` (every 6h, keep ~28).
- Soul Pilates go-live still pending USER: repoint Cloudflare DNS soulpilates.com.vn/www/new → 51.79.226.200 (offer a final Mongo re-sync right before cutover; source is read-only).

**51.79.226.215** (server id `cmsecmdps0001hlp27ai6mr7c`) — the dev/isolation box, safe to work on:
- Studio Nexis Next.js app (repo santino1233/studionexis): `/opt/nexis` (prod, `nexis-next.service` :3105) + `/opt/nexis-staging` (`nexis-staging.service` :3106), Postgres in `nexis-postgres` container (bind 127.0.0.1:5599, DBs `nexis` + `nexis_staging`).
- Serves studionexis.com + www + hq + app + new + stg + `*.studionexis.com` (tenant wildcard) via single nginx `/etc/nginx/conf.d/studionexis.conf`. nginx 1.24 → `listen 443 ssl http2;` NOT `http2 on;`.
- Wildcard cert `/etc/letsencrypt/live/studionexis-wildcard/` (studionexis.com + *.studionexis.com); auto-renew via `/root/.cf-studionexis.ini` (Cloudflare DNS-01). Multi-tenant middleware: `hq.` = HQ portal, `app.`/`new.` = admin hosts, `HQ_PATH` gates `/hq`.

DNS: studionexis.com apex + `*` + stg + `*.stg` all point at **51.79.226.215** (Cloudflare zone `901a93d5790077b8289975cdf561480f`, proxied=false). Repointed 2026-08-04; verified public HTTPS 200 via .215.

USER-SIDE SECURITY TODO (leaked in transcript): rotate the Cloudflare token, rotate the two source SSH passwords (72.62.240.50, 72.62.69.9).

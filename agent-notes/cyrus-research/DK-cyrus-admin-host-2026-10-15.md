# DK: Cyrus admin on its own secret cyrus.my host (2026-10-15)

NOTE: this directory auto-syncs to GitHub, so the real names are placeholders here. `<CYRUS_ADMIN_HOST>` = the
owner's chosen 15-char label + `.cyrus.my` (password manager / the owner's DNS record); it goes only into
/etc/cyrus/admin-host and /opt/nxeon/.env. `<NXEON_ADMIN_HOST>` = the server_name in sites-enabled/nxeon-admin-cloud.

Owner request: "i dont own revsports anymore, you need to bring it to cyrus and give it its own secret sub domain".
Branch `feature/cyrus-admin-host` (worktree /tank/dev-worktrees/cyrus-adminhost, off release/cyrus-rc18). Not pushed,
not deployed. The repo only says `<CYRUS_ADMIN_HOST>` / `__CYRUS_ADMIN_HOST__`.

Secret host: `<CYRUS_ADMIN_HOST>` (15-char label). DNS A record already created by the owner (proxied, TTL auto,
zone SSL mode Full).

## What already existed (r51, e897393b) and what was wrong with it
r51 had already built most of the mechanism (CYRUS_ADMIN_HOST, cyrusAdminHostRoute, marker header, admin layout
re-check, slim chrome, template vhost, runbook). Gaps found:
1. **The chosen label would have been silently ignored**: the validator required 16-63 chars; the owner's label is 15.
   Now 12-63 (`ADMIN_LABEL_MIN`, ~62 bits minimum; dictionary names still rejected). admin-host-apply.sh accepted only
   16-char base32; now 12-63 `[a-z0-9]` and `LABEL=<chosen> ... label` keeps an existing choice.
2. **Every `/api/**` passed on the secret host** (whole Nxeon API: billing, servers, other admin areas, Google OAuth).
   Now only `CYRUS_ADMIN_HOST_APIS` = /api/admin/cyrus, /api/cyrus, /api/mod-builder, /api/nxlabs/cyrus, /api/log
   (derived by grepping every fetch in app/admin/cyrus + components/admin/cyrus + components/cyrus).
3. `/robots.txt` on the host reached the app's Nxeon robots (Allow). Now middleware answers Disallow (and nginx too).
4. `/admin` on public hosts was 404'd only by app/admin/layout.tsx. Now, when NXEON_ADMIN_HOSTS is set, middleware also
   404s `/admin/**` and `/api/admin/cyrus/**` on every non-admin host (nxeon.cloud, cyrus.my, www.cyrus.my, staff host,
   forged Host). Dev (no NXEON_ADMIN_HOSTS) unchanged.
5. Admin login on the host showed a Google button whose redirect URI is pinned to nxeon.cloud (session would land on the
   wrong host). Hidden there; heading "Cyrus admin".
6. Template vhost lacked: re-declared security headers (server-level add_header drops conf.d/nxeon-security.conf's
   nosniff etc.), rate limits, path allow-list, query-free access log, acme location; it had a 503-on-rate-limit trap.
   Replaced by `deploy/cyrus/nginx-cyrus-admin.conf` (+ `nginx-cyrus-admin-log.conf` for conf.d).

## Design
- Same Next.js app/upstream (`nxeon_web`). middleware: secret host -> only /admin/cyrus/**, /admin/login,
  /dashboard/settings (staff 2FA enrolment), the 5 API trees, /_next, /vendor, favicon, static files by extension;
  `/`, `/admin` -> 302 /admin/cyrus; `/login` -> /admin/login; robots Disallow; else 404; noindex + no-store on all.
- /admin/cyrus keeps working on the Nxeon admin host (<NXEON_ADMIN_HOST (the name in sites-enabled/nxeon-admin-cloud)>) until CYRUS_ADMIN_HOST_ONLY=1.
  No security reason found to drop it immediately (same gates, already-public-in-CT host); keeping it avoids lock-out.
- Gates unchanged: admin layout (realUser, isStaff, impersonation refused, allowed_admin_ips, enforce_staff_2fa),
  per-tab requireCyrusAdmin/requireArea + preview list. Impersonation cannot start/continue usefully there
  (/dashboard 404s; impersonation cookie is host-only on the Nxeon admin host).

## Sessions / cookies (honest answer)
The Nxeon admin cookie (`nxeon_session`, host-only, no Domain) is on a nxeon.cloud name; cyrus.my is a different
registrable domain, so the browser NEVER sends it to the new host. Staff sign in again at `/admin/login` on the secret
host: the same `login` Server Action (bcrypt, TOTP, rate limit, audit), which sets the same host-only cookie
(HttpOnly, Secure in production, SameSite=Lax) for the secret host only. No token crosses hosts, no SSO handshake is
added. Cyrus public host cookies are `__Host-` (no Domain) so nothing on cyrus.my can scope a cookie to the subdomain.
No `domain:` attribute is set anywhere (test asserts it for lib/auth.ts).

## CSRF / Server Actions
Next compares Origin host with X-Forwarded-Host/Host; nginx sends `Host $host`, Origin is the same host => passes. No
`allowedOrigins` exists in next.config.ts and none is needed (adding one would only widen). In-repo same-origin helpers
compare against the request host. Staging's past failure was the bare :8080 listener (Host != Origin), not applicable.

## Security notes
- Port 3000 listens on 0.0.0.0 but the nftables input policy is drop and 3000 is not accepted => X-Real-IP from nginx is
  trustworthy; CYRUS_ADMIN_IPS usable.
- Direct-to-origin with the right Host still works (CF bypass) if someone knows the name: optional CF_ONLY=1 in
  admin-host-apply.sh ($realip_remote_addr geo) or Cloudflare Access.
- TLS: proxied + Full mode accepts any origin cert. Use the wildcard *.cyrus.my via DNS-01 (same dns-cloudflare
  plugin/credentials as /etc/letsencrypt/live/cyrus.my, whose renewal conf uses authenticator=dns-cloudflare; the
  cyrus-my-finish.sh script issued cyrus.my the same way). HTTP-01 for the exact name would work through the proxy but
  publishes the name on crt.sh => rejected. Origin CA cert is the fallback.
- Access log: `cyrus_admin_noqs` ($uri, no args, no Host/Referer). nginx error_log can still contain request lines.
- Note for the owner: while inspecting /opt/nxeon/.env (read-only) an agent tool call echoed the CYRUS_GOOGLE_CLIENT_SECRET
  value into this agent transcript; nothing was written anywhere else. Rotate it if transcripts are shared.

## Stale ADMIN_HOST (revsports.ca)
- `/etc/nxeon/domains.env`: `ADMIN_HOST=<old revsports admin name>` (stale). Read ONLY by `scripts/configure-domains.sh`
  (nothing in systemd/cron/deploy scripts references it). If someone runs configure-domains.sh now it would regenerate
  vhosts and certs for the revsports admin name and `set_env /opt/nxeon/.env NXEON_ADMIN_HOST <revsports>`.
- `/opt/nxeon/.env`: `NXEON_ADMIN_HOST` = the revsports name (stale, read by lib/reports/digest.ts for digest email links
  and lib/reports/collect-growth.ts), and `NXEON_ADMIN_HOSTS` = nxeon.cloud admin name + the revsports one.
- Enabled nginx vhosts still serving revsports names: sites-enabled/nxeon (revsports.ca, www, admin), nxeon-staging
  (staging.revsports.ca). CLAUDE.md and /opt/nxeon/scripts/publish-docs.mjs still mention revsports.ca/docs.
- Safe correction (owner): domains.env `ADMIN_HOST=<NXEON_ADMIN_HOST (the name in sites-enabled/nxeon-admin-cloud)>` (matches the live nxeon-admin-cloud vhost);
  .env `NXEON_ADMIN_HOST=<NXEON_ADMIN_HOST (the name in sites-enabled/nxeon-admin-cloud)>` and drop the revsports entry from `NXEON_ADMIN_HOSTS`; restart web.
  Do NOT run configure-domains.sh as a fix (it also rewrites the nxeon vhosts and re-issues certs); retire the revsports
  server blocks separately.

## Files (branch)
middleware.ts; lib/cyrus/bridge/config.ts; lib/cyrus/bridge/routing.ts; app/admin/login/page.tsx;
deploy/cyrus/nginx-cyrus-admin.conf (renamed from .template), deploy/cyrus/nginx-cyrus-admin-log.conf,
deploy/cyrus/admin-host-apply.sh, deploy/cyrus/CYRUS-ADMIN-HOST.md; scripts/cyrus/nginx-cyrus-admin-check.sh;
test/cyrus-admin-host.test.ts (+10 matrix tests); docs/cyrus/07-operations.md, CYRUS-MY-LAUNCH.md, _data/flag-notes.json,
generated reference pages; docs/DOCUMENTATION.md change history.
Verified: devhost tsc; cyrus-admin*, cyrus-bridge-*, cyrus-docs-coverage, cyrus-security-review (authz table),
cyrus-host-*, page-gate, portals-routing, seo, nginx-vhost, launch-check, mods. Vhost passed `nginx -t` in a scratch
prefix and the check script's admin-host rows all passed against it with a fake upstream (query string absent from logs).

## OWNER STEP LIST (in order)
0. DNS: DONE (A <label> -> 51.79.162.96, proxied, zone mode Full).
1. Merge `feature/cyrus-admin-host` and deploy it the normal way (deploy-staging -> verify -> promote-production).
   The old code would IGNORE the 15-char label, so the code must land before step 5 matters.
2. Store the label (for admin-host-apply.sh):
   `install -d -m 0700 /etc/cyrus && (umask 077; echo <label> > /etc/cyrus/admin-host)`
3. Certificate (wildcard, DNS-01, name stays out of CT logs):
   `certbot certonly --non-interactive --agree-tos --dns-cloudflare --dns-cloudflare-credentials /root/.secrets/cloudflare-cyrus.ini --dns-cloudflare-propagation-seconds 30 --cert-name cyrus.my-wildcard -d '*.cyrus.my'`
   check: `openssl x509 -in /etc/letsencrypt/live/cyrus.my-wildcard/fullchain.pem -noout -ext subjectAltName` -> `DNS:*.cyrus.my`
4. nginx (from /opt/nxeon after the merge):
   `install -m 0644 deploy/cyrus/nginx-cyrus-admin-log.conf /etc/nginx/conf.d/cyrus-admin-log.conf`
   `sed 's/__CYRUS_ADMIN_HOST__/<CYRUS_ADMIN_HOST>/g' deploy/cyrus/nginx-cyrus-admin.conf > /etc/nginx/sites-available/cyrus-admin`
   `ln -s /etc/nginx/sites-available/cyrus-admin /etc/nginx/sites-enabled/cyrus-admin`
   `nginx -t && systemctl reload nginx`   (if -t fails: `rm /etc/nginx/sites-enabled/cyrus-admin`)
   (Equivalent: `deploy/cyrus/admin-host-apply.sh cert` then `... nginx`.)
5. Env: `cp -p /opt/nxeon/.env /opt/nxeon/.env.bak.$(date +%F)` then add `CYRUS_ADMIN_HOST=<CYRUS_ADMIN_HOST>`
   to /opt/nxeon/.env. Same edit (optional, recommended): `NXEON_ADMIN_HOST=<NXEON_ADMIN_HOST (the name in sites-enabled/nxeon-admin-cloud)>`,
   `NXEON_ADMIN_HOSTS=<NXEON_ADMIN_HOST (the name in sites-enabled/nxeon-admin-cloud)>`; and in /etc/nxeon/domains.env `ADMIN_HOST=<NXEON_ADMIN_HOST (the name in sites-enabled/nxeon-admin-cloud)>`.
6. Restart web through the normal path (`scripts/promote-production.sh`, or `systemctl restart nxeon-web` if that is the
   accepted env-only restart).
7. Verify:
   `curl -sI https://<CYRUS_ADMIN_HOST>/ | grep -iE '^(HTTP|location|x-robots-tag)'`   -> 302, /admin/cyrus, noindex
   `curl -sI https://<CYRUS_ADMIN_HOST>/admin/login | grep -iE '^(HTTP|x-robots-tag|x-frame-options)'` -> 200, noindex, DENY
   `curl -s https://<CYRUS_ADMIN_HOST>/robots.txt`                                    -> Disallow: /
   `curl -so /dev/null -w '%{http_code}\n' https://<CYRUS_ADMIN_HOST>/admin/servers`   -> 404
   `curl -so /dev/null -w '%{http_code}\n' https://<CYRUS_ADMIN_HOST>/api/auth/session` -> 404
   `curl -so /dev/null -w '%{http_code}\n' https://cyrus.my/admin/cyrus`                     -> 404
   `curl -so /dev/null -w '%{http_code}\n' https://www.cyrus.my/admin/cyrus`                 -> 404
   `CYRUS_ADMIN_HOST=<CYRUS_ADMIN_HOST> scripts/cyrus/nginx-cyrus-admin-check.sh` and `... --origin 127.0.0.1` -> MATRIX OK
   Browser: sign in at https://<CYRUS_ADMIN_HOST>/admin/login (password + TOTP), open each Cyrus tab; the
   Nxeon admin host's /admin/cyrus still works. crt.sh search for the label: no result.
8. Later: optional Cloudflare Access / CF_ONLY=1; when staff use only the new host, `CYRUS_ADMIN_HOST_ONLY=1` + restart.
   Rollback: remove CYRUS_ADMIN_HOST, restart; remove the sites-enabled link, nginx -t, reload.

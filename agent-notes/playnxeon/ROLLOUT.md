# Rollout + rollback: new game servers on `<name>.playnxeon.com`

Branch `feature/playnxeon-domain` (not merged, not deployed). Existing servers never move: their rows keep
`connectDomain = NULL` and every code path for NULL rows makes the same addresses, labels and DNS calls as today.

## Order (owner = who does it)
1. **Coordinator** — review + merge the branch, then normal deploy: `scripts/deploy-staging.sh` -> verify ->
   `scripts/promote-production.sh`. The schema change is additive (two nullable `connectDomain String?` columns,
   no index/constraint); the promote's schema push applies it. Switch is OFF by default, so after deploy nothing
   changes for anyone (verify: create nothing, existing dashboard/directory addresses unchanged).
2. **Owner/coordinator (root)** — add to `/opt/nxeon/.env` (agents must not edit .env):
   `CLOUDFLARE_PLAYNXEON_API_TOKEN=<value of CLOUDFLARE_API_TOKEN in /root/secrets/cloudflare-playnxeon.env>`
   then restart web + worker the usual way (systemd units, never pkill). Without it, new-domain paid servers simply
   get no per-server records (silent no-op, provisioning never blocks); free servers do not need it.
3. **Coordinator (root, primary)** — DNS: `node scripts/playnxeon-dns-prep.mjs --env-file /root/secrets/cloudflare-playnxeon.env`
   (dry run; today it plans: CREATE `A *.playnxeon.com -> 178.63.94.114` DNS-only; UPDATE root A
   `2.57.91.91 (proxied) -> 51.79.162.96` DNS-only; UPDATE `www` CNAME to DNS-only), then the same with `--apply`.
   Check: `dig +short A zz-anything.playnxeon.com @1.1.1.1` = 178.63.94.114; `dig +short playnxeon.com @1.1.1.1` = 51.79.162.96.
4. **Coordinator (root)** — root forward: follow `deploy/playnxeon/INSTALL.md` (stage-1 HTTP vhost, certbot webroot,
   final vhost). Check `curl -sI https://playnxeon.com` -> `301 Location: https://nxeon.cloud/game-servers`.
5. **mc-router / freemc-host: nothing to do.** mc-router routes purely by each container's `mc-router.host`
   Docker label; new free servers are created with `<name>.playnxeon.com` labels, existing containers keep
   theirs. node-2's :25565 NAT is hostname-agnostic. Optional read-only sanity check (no change):
   `docker inspect mc-router --format '{{.Args}}'` on freemc-host should show no hostname allow-list flag.
6. **Owner** — Admin > Settings > Free Minecraft servers: confirm "New servers' connect domain" = `playnxeon.com`,
   turn on "Create new game servers on the new domain", save. From this moment new free claims and new paid
   orders (incl. partner grants) get `connectDomain = "playnxeon.com"`.

## Verification checklist (after step 6)
- [ ] Deploy wizard (/dashboard/deploy, Minecraft): play-address suffix reads `.playnxeon.com`; free claim form too.
- [ ] Free: claim a test free server `zzfree<rand>` -> dashboard shows `zzfree….playnxeon.com`; on freemc-host
      `docker inspect -f '{{index .Config.Labels "mc-router.host"}}' mc-free-<userId>` = `zzfree….playnxeon.com`;
      a real Java client joins `zzfree….playnxeon.com` (no port) and wakes it. Switch game type once: label unchanged.
- [ ] Paid: order a Java Minecraft server `zzpaid<rand>` -> Cloudflare playnxeon.com zone has
      `A zzpaid….playnxeon.com` + `SRV _minecraft._tcp.zzpaid….playnxeon.com` (DNS-only); `dig SRV _minecraft._tcp.zzpaid….playnxeon.com @1.1.1.1`
      returns the NAT port; a real Java client joins by name only. Bedrock/CS2 test (optional): A only, client needs the port.
- [ ] Legacy untouched: an existing free server and an existing paid server still show `<name>.play.nxeon.cloud`
      everywhere (dashboard, directory, admin Server360 Network tab); their containers' labels and nxeon.cloud
      records unchanged (`dig` same as before); a real client still joins them.
- [ ] Name collision: claiming a name that exists on the legacy domain is refused ("taken") and vice versa.
- [ ] Terminate the two test servers: the paid one's playnxeon.com records are deleted; nothing in nxeon.cloud changed.
- [ ] AI chat: asks "what's my free server address" -> its own domain.

## Instant rollback
Turn the switch OFF (admin setting). New orders/claims return to `play.nxeon.cloud` immediately (stored NULL).
Servers already created on playnxeon.com keep working: their row keeps `connectDomain`, their records/labels stay,
and sync/terminate keep using the playnxeon.com zone. Leave the wildcard, root forward and env var in place.
Full code rollback (`scripts/rollback-release.sh --production`) is safe too: the columns are additive and ignored by
old code — BUT old code would show new-domain servers as `<name>.play.nxeon.cloud` and relabel their containers on
the next recreate, so only do a code rollback if no server was created with the switch on, or after moving those
few back by hand.

## What could go wrong
- **Cached DNS / negative caching**: before step 3, a lookup of `x.playnxeon.com` caches NXDOMAIN (SOA min TTL,
  Cloudflare ~1800s). Do step 3 well before step 6 and test from 1.1.1.1. New per-server records use TTL auto (300s).
- **SRV vs A**: only Java Minecraft gets SRV (name-only join). Bedrock + CS2/gmod/etc. get A only and players
  must type the port — same as today. Free servers use the wildcard A + default port 25565, no SRV.
- **Bedrock**: no free Bedrock; paid Bedrock = A record + port 19132 forward, unchanged.
- **Wildcard catches unknown names**: `anything.playnxeon.com` resolves to node-2 (like legacy). Exact paid records
  win by DNS specificity. A legacy name typed on the new domain reaches mc-router and gets no route (harmless).
- **Token scope**: the playnxeon token can edit DNS but cannot create redirect rules (confirmed) — hence nginx.
  If the env var is missing, new paid servers silently get no records (address shows but does not resolve to the
  server; the wildcard sends it to node-2). Check the env before step 6.
- **Rate limits**: Cloudflare API ~1200 req / 5 min per token; each sync is 4-6 calls. Fine.
- **Partial failure while creating records**: A created, SRV failed -> the SYNC_GAME_DNS job errors and is retried
  by the job system; any later port-forward change re-syncs; admin Server360 "Resync DNS" fixes by hand. Records are
  upserted, never duplicated.
- **Name collisions**: impossible across domains (one namespace, unique per table + cross-table check); the residual
  race between the two tables is the same as today.
- **Legacy setting edits**: changing `free_minecraft_domain` still moves every LEGACY server (as before). Never do it.
- **Static legacy marketing page** (app/(marketing)/free-minecraft, only if NXM_ROOT is off) is built at deploy, so its
  copy updates on the next build; the live nxm pages are force-dynamic.

## Later opt-in (not built)
Moving an existing server to playnxeon.com on the owner's request: set its `connectDomain`, recreate (free: new label,
possibly both hosts in the label) or SYNC_GAME_DNS (paid), and delete the old nxeon.cloud records. Not done here by design.

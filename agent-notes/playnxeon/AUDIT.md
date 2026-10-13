# Audit: every place the game connect domain is read or hard-coded (2026-10-08)

Branch `feature/playnxeon-domain`, worktree `/tank/dev-worktrees/playnxeon`.
Classes: **PER-SERVER** = must follow the row (`connectDomain`, NULL = legacy) -> now does;
**NEW-SERVER** = no row yet, shows what a server created now gets (`newServerDomain()`) -> now does;
**GLOBAL** = can stay one value; **COPY** = text only.

## How it works today (before this branch)
- One setting `free_minecraft_domain` (unset in prod -> fallback `play.nxeon.cloud`) decided EVERY address.
- Paid: `lib/game-subdomain-dns.ts` writes exact A (+ SRV `_minecraft._tcp.<host>` for Java only) in the
  `nxeon.cloud` zone with `CLOUDFLARE_DNS_API_TOKEN`; `worker/game-subdomain-sync.ts` (SYNC_GAME_DNS job, one row
  at a time) keeps it in sync; `worker/index.ts remove()` deletes on termination. There is NO zone-wide sweep that
  deletes "stale" records anywhere; every call is scoped to one row's exact names.
- Families with a managed subdomain (`dnsSupportForFamily`): `minecraft` A+SRV; `bedrock` and
  `HOSTNAME_CONNECT_FAMILIES` (lib/games.ts: cs2, gmod, tf2, l4d2 ... ) A only (players add the port). Others none.
- Free: one wildcard `*.play.nxeon.cloud` A -> node-2 178.63.94.114 (DNS-only), node-2 NAT :25565 -> freemc-host
  mc-router. mc-router learns routes ONLY from each container's Docker label `mc-router.host=<sub>.<domain>`
  (set in `recreateGameTypeContainer`, lib/free-minecraft-control.ts:1055). Hostname-agnostic otherwise.
- Names: `Server.subdomain` and `FreeMinecraftServer.subdomain` are each `@unique`; `isSubdomainAvailable` checks
  both tables. One namespace; unchanged (domain-agnostic), so a name is taken on both domains at once.

## PER-SERVER (changed to the row's own domain)
| Where | What |
|---|---|
| lib/game-subdomain-dns.ts | zone + token + host per row (`dnsZoneFor`); legacy = nxeon.cloud zone + platform token, same calls as before |
| worker/game-subdomain-sync.ts | passes `server.connectDomain` (`planGameServerDnsOp`) |
| worker/index.ts:1977 | termination delete in the row's own zone |
| worker/admin-ops.ts:330 | diagnosis `subdomainHost` (resolve4/SRV checks) |
| lib/free-minecraft-control.ts (label) via callers: lib/actions-free-minecraft.ts (create, rename, preset), lib/actions-freemc-mods.ts, lib/actions-freemc-worlds.ts, scripts/freemc/rollout/03-recreate-asleep.ts | mc-router label = row's domain on every recreate. A WRONG domain here would silently move a free server, so these were the highest-risk reads |
| worker/freemc-health.ts | mc-router wake log -> row, matches only the row's own domain (`rowForGameHost`) |
| lib/nx/connect-address.ts (+ app/dashboard/page.tsx, app/dashboard/migrate/page.tsx, lib/nx/services.ts) | dashboard / services addresses |
| lib/nx/services.ts:468 | free row address |
| app/dashboard/servers/[id]/page.tsx | connect address, Join details, public listing, rename suffix (`ChangeGameSubdomain domain=`) |
| lib/partner-grants.ts | grant handoff address |
| lib/actions-listing.ts | directory submission kit |
| lib/server-directory-data.ts, lib/directory-portal-data.ts, app/(marketing)/game-servers/directory, app/admin/directory | directory hosts (dedupe + "own server" match) |
| components/customer/freemc/FreeMinecraftTabContent.tsx -> FreeMcDashboard/FreeMcHero | free dashboard address, rename suffix, delete confirm |
| app/(marketing)/servers/[subdomain], app/(marketing)/servers, app/nxm/_data/server-detail.ts, app/nxm/_data/server-directory.ts | public pages + meta description (SEO). JSON-LD/canonical/sitemap use `/servers/<sub>` only (no domain) |
| lib/kb-tools.ts | AI chat "your free server address" |
| lib/vm-move/engine.ts + worker/vm-move.ts | move notice/email names the row's host |
| components/admin/server360/tabs/NetworkTab.tsx, app/admin/free-minecraft/page.tsx | admin displays |

## NEW-SERVER (no row yet: shows `newServerDomain()`)
components/nx/DeployView.tsx (live wizard, via `cat.gameDomain` from app/dashboard/deploy/DeployPageContent.tsx);
components/customer/GameDeployWizard.tsx (dead code, prop added anyway); components/admin/PartnerGrants.tsx
(grant form suffix); components/customer/services/FreeServicesClaim.tsx + FreeMinecraftTabContent create form
(free claim); lib/game-order.ts quote (`connectDomain`, `connectDomainStored`) + Server create; lib/nx/quote-game.ts.

## COPY (follows the switch, unchanged while it is off)
lib/kb-facts.ts + lib/kb-llm.ts (system prompt) via `gameDomainCopy` (adds "older servers keep theirs");
app/(marketing)/free-minecraft/page.tsx FAQ (+FAQ JSON-LD), app/nxm/_data/free-minecraft.ts, app/nxm/_data/server-directory.ts
("Addresses on *.x and *.y"); lib/game-connect.ts cs2/gmod notes now "<play address>" (substituted with the real host on
the server page and grant handoff). Left as-is (static copy, legacy correct): components/marketing/freetiertemplate/data.ts
`FREE_DOMAIN` (preview page default only; the live page passes the domain), lib/kb-system.ts template text (rewritten at
render by gameDomainCopy), tools/nxm generators (already templated on `__NXM.domain`).

## GLOBAL (stay one value)
`free_minecraft_domain` = legacy domain for NULL rows (admin field relabelled "do not change"; blank now falls back
to play.nxeon.cloud instead of producing `bob.`). New: `game_domain_new` (default playnxeon.com),
`game_domain_new_enabled` (default false). Directory never-block list now includes both domains
(lib/directory-blocklist.ts, lib/directory-blocklist-db.ts). Build snapshot keys (scripts/lib/buildhost.sh) include
the two new settings.

## No change needed
Name validation/availability (lib/game-subdomain*.ts, actions-subdomain-check.ts), sitemap, admin search (short
name), delete manifest (short name), deploy-intent/stripe/payment metadata (carry the short name; domain decided at
order time), server-deployed email (IP:port only — pre-existing gap: it never shows the subdomain).

## Pre-existing findings (not fixed, out of scope)
1. `changeGameSubdomain` (paid rename) never deletes the OLD name's A/SRV: they stay pointing at the server. Harmless
   for collisions (upsert overwrites) but leaks records. Same on both domains.
2. Saving the Free Minecraft settings panel with a blank "Connect domain" used to store "" and break every address;
   now the field pre-fills and blank falls back.
3. Tests that hard-code play.nxeon.cloud (freemc-health, admin-ops-logic, server-directory, directory-blocklist,
   directory-portal) still pass: they test parsers with explicit inputs.

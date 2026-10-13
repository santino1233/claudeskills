---
name: nxeon-free-minecraft-tier
description: "2026-08-24 — free Minecraft server growth tier: freemc-host VM + Docker + mc-router (subdomain routing, auto-sleep/wake), full customer flow + admin settings + landing page. Live in code, gated off (free_minecraft_enabled=false) until wildcard DNS is added and the flag is flipped."
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-09-05T23:38:50.130Z
---

Started from the user asking me to research Aternos (free Minecraft hosting) for competitive context, then "let's offer a free Minecraft server option to build our user base." Escalated through several user-steered decisions in one session — see chronology below, it matters for anyone picking this up.

**Architecture (user's own idea, I validated + built it):** NOT one VM per free signup — the single-node capacity math didn't support that (see the critical finding below). Instead: one dedicated VM running Docker, one lightweight container per free account, [itzg/mc-router](https://github.com/itzg/mc-router) in front doing hostname-based routing + `-auto-scale-up -auto-scale-down` (starts a container on connect, stops it after idle — literally the Aternos queue/sleep mechanic, off-the-shelf, zero custom orchestration code needed for that part).

**Critical infra finding that shaped everything:** Nxeon runs on a SINGLE Proxmox node (`Node` table has exactly one row — this box, ns5002569). That node already hosts the live site, worker, Postgres, mail, AND the owner's own side projects (Kodely, Soul Pilates, Prime Growth) as VMs, and was already swap-exhausted (232KB free of 2GB) with zero real paying customers running anything. A free, anonymous-signup, abuse-magnet tier could NOT safely share that blast radius — hence the dedicated `freemc-host` VM, isolated by Proxmox's own per-VM memory ceiling.

**UPDATE 2026-09-05 — migrated to node-2 (Hetzner Falkenstein).** See
[[nxeon-full-audit]] and docs/DOCUMENTATION.md's "node-2 enabled + the free Minecraft host migrated
to it" section for the full record. Everything below describing vmid 108 / `10.20.0.102` /
`51.79.162.96` is now HISTORICAL — the live values are vmid 100, `10.20.1.100` (node-2's private
subnet), public IP `178.63.94.114`. The wildcard DNS record (`*.play.nxeon.cloud`) now points at
`178.63.94.114` too. Migrated via vzdump/qmrestore with zero code changes (Phase 1-3 multi-node work
already made every code path here node-aware) — all 14 real worlds' containers survived intact.

**What's actually running, right now, in prod (pre-migration facts, kept for the architecture
history — see the update note above for current values):**
- `freemc-host` — a real `Server` row (vmid 108, Ubuntu 24.04, 8GB/3vCPU/80GB "Pro" plan, `10.20.0.102`), provisioned through the EXISTING "Grant a free VPS" mechanism (`Server.isFree=true`, `/admin/grant`'s underlying `adminGrantFreeVps` — I replicated its exact DB write via a one-off script since it needs a live admin session, but the resulting Server row is indistinguishable from one the real admin UI would create). Owned by the internal ops account (`nicholas.sj.albanese@gmail.com`, same account used for kodely-app/nexis-app), NOT a customer-facing purchase.
- Docker + `itzg/mc-router` (container `mc-router`, `--restart unless-stopped`, `-in-docker -auto-scale-down-after=15m`) + `itzg/minecraft-server` image, both pulled and proven.
- A `PortForward` row (25565 tcp) reconciled through the EXISTING `lib/nat-rules.ts`/`PortForward` system — no new firewall code, reused the mechanism that already handles every customer server's connect port.
- Verified end-to-end THREE times against the real running system, not simulated: (1) manual docker-run test, (2) the exact `createFreeMinecraftServer` docker-assembly logic run through the app's own `withServerSsh` helper, (3) both confirmed reachable via a raw Minecraft server-list-ping over the ACTUAL public IP (51.79.162.96:25565) → DNAT → mc-router → container-by-subdomain, not just the internal bridge.

**Customer-facing pieces, all shipped and gated behind `free_minecraft_enabled` (default false):**
- `FreeMinecraftServer` Prisma model (one per verified account, `subdomain` unique).
- `lib/actions-free-minecraft.ts` — create/delete actions. Gates: feature flag, email verification (`assertEmailVerified`), rate limit, subdomain format+reserved-word check, one-per-account, and a `free_minecraft_max_concurrent` total-server-count cap (documented as a proxy for "max concurrently awake" — capping total creates, not live Docker polling, for v1 simplicity).
- `/dashboard/free-minecraft` — create form / manage panel, wired into the dashboard nav behind the same `free_minecraft_enabled` setting (reused directly as the nav `FEATURE_HREF` gate, no duplicate flag).
- `/free-minecraft` — the marketing landing page (hero, how-it-works, an HONEST "what free actually means" limits section, FAQ). Linked from the footer's Game servers column and `app/sitemap.ts`.
- `/admin/settings?tab=free-minecraft` — new panel: master enable switch, host public IP, connect domain, RAM/disk caps, idle-minutes, max-concurrent. Same `saveSettings`-section pattern as every other gated subsystem this session ([[nxeon-retention-winback-emailtrack]]'s winback panels).

**Known, documented gap:** disk usage is NOT hard-quota-enforced (`free_minecraft_disk_mb` exists as a setting but isn't wired to anything — Docker's `--memory` cap is a real hard ceiling, but a per-container disk quota needs XFS+pquota, which this host's filesystem doesn't have). RAM cap + total-server-count cap are the only enforced safety controls today. A future `du`-based periodic sweep would close this.

**Still needed before this can go live for real users — NOT something I can do myself:** a wildcard DNS record, `*.play.nxeon.cloud -> 51.79.162.96`, DNS-only (grey-cloud, NOT proxied — Minecraft's raw TCP protocol breaks behind Cloudflare's proxy). No platform-level Cloudflare API token exists in this codebase (only customer-level ones, for the auto-DNS feature), so I couldn't automate this and had to hand it to the user. Once that's added AND an operator flips `free_minecraft_enabled` on in Settings, the whole flow is live.

**UPDATE 2026-09-05 (later same day) — post-migration admin-surface bug + a live OOM
incident + a capacity-sweep gotcha found the hard way.**

1. **Admin-surface `freemcHost()` duplicates were NOT all fixed by the migration-day
   audit.** Five files each hand-roll their own copy of the `freemcHost()` helper
   (`lib/actions-admin-freemc.ts`, `lib/actions-freemc-roles.ts`,
   `lib/actions-freemc-mods.ts`, `lib/actions-freemc-inventory.ts`,
   `lib/actions-freemc-worlds.ts`) — only `lib/actions-free-minecraft.ts`'s copy got
   the `node: { select: { publicIp: true } }` fix. Surfaced by the owner's own
   screenshot of `/admin/free-minecraft` showing "Could not reach the free Minecraft
   host." after the node-2 move. Fixed all five, confirmed live via
   `connectionTarget()` resolving to `178.63.94.114:20002` (node-2), not the
   primary's fallback IP. **Lesson: grep for every `hostname: "freemc-host"` /
   `hostname === "freemc-host"` occurrence whenever this host's connection shape
   changes — one narrow fix does not mean every duplicate got it.**

2. **Live OOM kill, vanilla preset, totally ordinary gameplay.** A player
   generating fresh terrain on a plain vanilla free server pushed the JVM to
   1041MB RSS inside a 1024MB container (870MB heap, the old 0.85 ratio) — kernel
   OOM-killed it mid-session (`dmesg`: `Killed process ... (java)`). This is the
   *same bug class* `lib/free-minecraft-control.ts`'s `recreateGameTypeContainer`
   already documents fixing for `kind:"plugins"` presets (see that file's inline
   history) — the vanilla ratio just had a smaller, still-real blind spot. Fixed:
   0.85 -> 0.75 for non-plugins presets (768MB heap / 256MB headroom instead of
   870/154). Did NOT touch the global `free_minecraft_ram_mb` default (1024) —
   that's a capacity/cost call, this was a pure correctness fix within the
   existing limit.

3. **CRITICAL OPERATIONAL LESSON — never bulk-recreate free-mc containers without
   respecting the CPU budget.** `lib/freemc-capacity.ts`'s own module doc says it
   plainly: freemc-host has only 3 vCPUs, 1 reserved, so **at most 2 vanilla-kind
   containers (or 1 plugins-kind) can be RUNNING at once** — everything else is
   supposed to be asleep, woken on demand by mc-router. Recreating a container
   that's already running is capacity-neutral (old one's usage frees the instant
   before the new one's is counted); recreating a *sleeping* one is NOT — it's a
   net-new commitment, because `recreateGameTypeContainer` does `docker rm -f`
   BEFORE the capacity check, unconditionally. I sequentially swept 8 vanilla
   containers to apply the ratio fix above, without realizing most of them were
   asleep. The first two succeeded (ate the entire 2-vCPU budget), and every
   container after that — including `papi`, which was the ONE container actually
   running with a real connected player — got its OLD container deleted by the
   unconditional `docker rm -f` and then failed the capacity check, leaving it
   with NO container at all (not stopped — gone). World data survived fine (it's
   a bind mount at `/opt/freemc/servers/<FreeMinecraftServer.id>`, untouched by
   `docker rm`), but 6 servers were briefly nonexistent until manually recreated
   one at a time with an explicit `docker stop` after each successful recreate to
   return it to sleep before moving to the next. **Any future bulk maintenance
   across free-mc containers MUST: (a) check `docker ps` first to see what's
   actually running before touching anything, (b) process one container at a
   time, (c) immediately `docker stop` anything that wasn't already running
   before you touched it, before moving to the next container** — never assume a
   recreate is free just because the old container gets removed first.

**Tooling notes for next time:**
- `withServerSsh(server, fn)` works for ANY `Server` row, not just customer VPS ones — reusing it to SSH into our own internal `freemc-host` (rather than inventing new SSH plumbing) was the right call and worked cleanly.
- The worker's NAT/port-forward reconciliation (`syncPortForwardsBestEffort`) only runs at WORKER STARTUP, not on a timer — adding a new `PortForward` row does nothing until the worker restarts OR you call it manually (I wrote a throwaway script importing it directly — safe, read+reconcile only, same thing the worker does at boot).
- Hairpin NAT strikes again (see [[nxeon-vm-hairpin-firewall-fix]]): SSHing to a guest via `127.0.0.1:<forwarded-port>` from the HOST ITSELF fails, but the SAME forwarded port via the box's real public IP (`51.79.162.96:<port>`) works fine. Loopback specifically is the broken case, not hairpin NAT in general — don't waste time debugging this again, just use the real public IP (or the internal bridge IP directly) from host-side scripts.
- `itzg/mc-router` needs `--user 0:0` when mounting `/var/run/docker.sock` — it doesn't run as root by default and gets a silent-ish permission-denied crash loop otherwise.

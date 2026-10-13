---
name: nxeon-freemc-dashboard
description: "2026-08-24 — real management dashboard for free Minecraft servers: power controls, RCON console, players, schema-driven settings (live-vs-restart aware), presets, rename/change-domain/delete. Live in prod."
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-24T20:59:52.627Z
---

Follows [[nxeon-free-minecraft-tier]] — that shipped the infra + a bare create/delete-only page; this is the actual management dashboard the user asked for after seeing the bare page live (screenshot showed just "Connect at / Delete this server").

**What shipped:** `/dashboard/free-minecraft` is now a 5-tab panel (Overview/Console/Players/Settings/Manage) mirroring the paid game panel's shape (`components/customer/gamepanel/GameServerPanel.tsx`) but built for Docker+RCON instead of Proxmox-VM+SSH-tunnelled-RCON:
- **Power**: start/stop/restart via plain `docker start/stop/restart` (mc-router already auto-manages this on connect/idle; these are manual overrides).
- **Console**: real RCON via the bundled `rcon-cli` (`docker exec <container> rcon-cli <cmd>`) — far simpler than the paid path's raw Source-RCON-over-SSH-tunnel implementation, since itzg's image ships a working CLI.
- **Players**: `rcon-cli list`, parsed.
- **Settings**: reuses the EXISTING `lib/game-config.ts` MINECRAFT schema (gamemode/difficulty/pvp/motd/max-players/whitelist/etc.) — same field defs the paid game panel's Settings tab uses, just a new Docker-based apply path (edit `/data/server.properties` directly + restart, since the property file is startup-only — confirmed via research + the Minecraft wiki that nothing here persists a live RCON change back to the file).
- **Presets**: Vanilla/Creative/Hardcore/Peaceful, each just a server.properties bundle. Deliberately NO SkyBlock preset — every real way to build one depends on an external plugin/datapack not yet vetted for stability; noted as a fast-follow once one's been tested, not shipped as a placeholder.
- **Manage**: rename (cosmetic DB label), change subdomain (stop→remove→recreate container with the SAME data volume + container name, new mc-router label — labels are immutable on a running container so this is the only way), delete.

**Genuine UX differentiator found via research, not obvious on its own:** none of the competing panels (Pterodactyl, Crafty, AMP, Multicraft) clearly show which settings apply live vs. need a restart. Built this explicitly — each settings field gets a badge ("applies instantly" for difficulty/whitelist-on-off, which have real vanilla RCON commands; "needs restart" for everything else, since MOTD/max-players/gamemode-for-new-joiners have no live vanilla equivalent).

**RCON password is deterministic, never stored:** `scryptSync(AUTH_SECRET, "nxeon-freemc-rcon:" + userId)`, same derivation pattern as `lib/crypto-box.ts`'s BYOK encryption key. Survives restarts/recreates with zero DB state.

**Bug caught by testing against the REAL pre-existing free server, not just fresh containers:** the one real free server created before this dashboard existed (`testing.play.nxeon.cloud`) had RCON enabled with an itzg-auto-generated random password (`rcon.password=` in server.properties), NOT the new deterministic one — every RCON call would have silently failed for that one real user. Found by directly grepping that container's live server.properties, fixed by recreating it (same data volume, new `RCON_PASSWORD` env) — the exact same safe recreate pattern already built for subdomain-changes. **Lesson: when adding a new expected-invariant (env var, config value) to a resource-creation path, check whether any ALREADY-CREATED real instances predate it — "backfill" isn't just a DB-migration concern.**

**TypeScript gotcha hit twice in one file:** `let result: UnionType = { ok: false, ... }` followed by mutating `result` inside an async callback, then reading `result` afterward — TS infers the variable's type from the initializer's narrowed branch, not the full declared union, so a later `if (!result.ok) return; return result.foo` sees `result` as `never` in the branch where `foo` should exist. Fix: don't mutate a captured outer variable — return the value from the callback and use `withServerSsh`'s own return value directly (`const result = await withServerSsh(host, (conn) => fn(conn))`), which infers correctly since there's no manual annotation collapsing the union.

**Verification discipline:** every backend primitive (status, players, settings read, live RCON, property write, restart-persistence) was run directly against the real freemc-host and the real (recreated) container — not just type-checked — before shipping, including applying a real preset, confirming it survived a restart, then reverting back to vanilla afterward so the test account's server is left clean.

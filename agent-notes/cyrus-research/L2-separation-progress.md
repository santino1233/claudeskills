# L2 - Cyrus separation, part 2 (2026-10-10)
Branch `feature/cyrus-r22-separation` (worktree /tank/dev-worktrees/cyrus-r22), from feature/cyrus-r2 (merged again mid-work). No behaviour change inside Nxeon: every host method delegates unchanged to the existing platform function or the same query.

## What moved
1. **Worker entry.** `lib/cyrus/worker/schedule.ts`: `registerCyrusSweeps(runner)` registers modbuilder-sync, cyrus-tokens, cyrus-lifecycle, cyrus-compat-watch, cyrus-testflight-gate with the original cadences, timeouts, fire-and-forget and flag gates; `startCyrusSoundRelay()` replaces the bottom-of-file relay block. `worker/index.ts` calls them in two lines. Platform sweeps (mod lifecycle, build sync) come through `host.worker`. Boot order of those five among the other sweeps shifted (they now register together); cadence unchanged.
2. **Paths.** `lib/cyrus/config.ts` `cyrusConfig()`: build/render host (CYRUS_BUILD_HOST, default node-2), Test Flight / meshgen / Blender / sound roots, modbuild + import dirs, modbuilder env file, and the guest layout (/opt/mc, /root/.nxeon-cyrus, backups). All env-read, same defaults. `services/modbuilder/run.sh` takes CLAUDEBOX_ENV / MODBUILDER_ENV. `test/cyrus-config.test.ts` pins defaults and bans new literals.
3. **Game-server install.** `host.installs` (engine install/uninstall of prefetched packages, state path), `host.servers.openFiles/pinnedVersion`, `HostGuestFs` and friends replace all lib/mods imports (engine, safe-fetch, minecraft installer, guest-fs, SshGuestFs). `CYRUS_SOURCE` now lives in `lib/cyrus/source.ts`; the platform re-exports it.
4. **DB.** `lib/cyrus/db.ts` `cyrusDb` (typed to the 28 Cyrus tables plus raw SQL) is the only DB door; no file under lib/cyrus imports lib/db. Platform tables go through `host.users`, `host.jobs`, `host.servers`, `host.records`, `host.settings.readStored*/writeStored/clearStored`, `host.audit.append` (raw row, no impersonation/IP, as before).

## Numbers
lib/cyrus imports of Nxeon internals: 74 statements / 41 files / 28 modules -> **40 / 26 / 16** (baseline fixture 40 pairs). Nxeon-table call sites from lib/cyrus: 97 -> 0 (tsc enforces it). Hardcoded host paths in lib/cyrus: 0. Full Cyrus suite 1841/1841; all nine opt-in DB suites run on a throwaway DB: 41/42 (see below).

## What remains
- **lib/modbuilder/\*** (28 of the 40 imports): Cyrus' build engine, still physically in lib/modbuilder. Move it under lib/cyrus (or give it its own seam), then `lib/modbuilder/install.ts` (queue + legacy-jar adoption) onto `host.installs`.
- **Stripe** (lib/stripe, stripe-cards in tokens/billing, state, sweep) and **SSO/accounts**: owner decisions, untouched.
- `lib/rbac` in admin/perms.ts (client-safe role tables, left alone), `lib/cyrus-mods/*` (3), `lib/mod-health`, `lib/terraria-image`, `components/cyrus-tokens`, the net-policy.json rule file.
- App routes/pages/components (185 files) and the middleware carve-out still import lib/cyrus directly; nothing moved there.
- Types from @prisma/client (User, ModBuild) remain in a few signatures.

## Next steps
1. Relocate lib/modbuilder + lib/cyrus-mods into lib/cyrus; ratchet then covers them.
2. Billing decision, then `host.billing`; SSO decision, then `host.auth` for a standalone session.
3. Standalone HostAdapter: implement CyrusHost over the Nxeon API (install, servers, users), Postgres for cyrusDb.
4. UI shell/basePath work (audit step 8).

## Notes for other agents
- Tests that import a module reaching `getHost()` need `import "./_cyrus-server-only-shim"` first (added to 10 existing tests).
- Pre-existing, not mine: `test/cyrus-managed-db.test.ts` "catalog seeds" expects 2 rows but the catalog now has 3 (BetterModel).

# DH - delivery ownership fix, pass 2 (2026-10-15)

Branch `fix/cyrus-delivery-ownership`, worktree `/tank/dev-worktrees/cyrus-delivery-chown`, new commit `1e0ba792`
on top of `7be0a81f`. Not pushed, not merged, not deployed, no live writes.

## Site 1 finding (the important one): deliverCreatures() WAS the real path

Call graph, precise:
- `deliverCreatures()` has exactly one production caller: `lib/cyrus/assets/deliver-worker.ts:36`
  (`afterCyrusModChange`), itself called only from `worker/game-mods.ts:175`, inside the ordinary engine-install
  loop for `sm.mod.source === "cyrus" && gameFamily === "minecraft"` (`worker/game-mods.ts:173`).
- The standard install action: `app/api/mod-builder/builds/[id]/install/route.ts` -> `installBuildToServer`
  (`lib/modbuilder/install.ts:128`) -> `enqueueModOp(..., {targetVersionId})` (`install.ts:160`) ->
  `lib/mods/queue.ts:42` payload `{op, modId, targetVersionId}`: NO `cyrusDelivery` key. Used by the dashboard
  (BuildView, InstallModal, CyrusApp, lifecycle actions).
- `worker/game-mods.ts:85`: only payloads with the `cyrusDelivery` discriminator go to the orchestrator
  (`cyrusDeliveryJob`). Those are enqueued by `lib/modbuilder/delivery.ts` (`/api/cyrus/delivery/v1`, Mod Packs,
  Config Studio send, Designer Studio ship). So the orchestrator fixed in pass 1 is the secondary entry point.
- `lib/cyrus/creature/deliver.ts:87-96,98-105` wrote config.yml + models, no chown (also confirmed by grep).

Conclusion: a normal install of a creature mod goes through deliverCreatures(); it is the path that most likely
broke kodi.playnxeon.com. Pass 1 alone would NOT have prevented a recurrence. Caveat: this is code-proven, not
log-proven; the Job payload of the InfiniteDungeon install on that server would settle it (no `cyrusDelivery`
key = this path). Also note it requires CYRUS_CREATURES=1 + CYRUS_MANAGED_PLUGINS_REAL=1 in the worker, which
the incident implies were on.

## What was fixed
1. `lib/cyrus/creature/deliver.ts`: ownGame after config.yml write and each model rename.
2. `lib/cyrus/modpack/install.ts`: `fsPlacer(fs, base)` chowns each placed file; Pack Loader packs.json chowned
   (install + uninstall); unit record (under stateDir) deliberately not. `UnitFs.chownLike` optional.
   `engine-placer.ts`: config-role files chowned; `engineMemberPlacer` now takes `base`
   (`worker/cyrus-delivery.ts` passes `session.base`). Jar/datapack members go through lib/mods/engine.ts.
3. `lib/mods/engine.ts:399`: chownLike now `.catch(() => undefined)`. (It was inside the function's outer
   try, so a throw would have reported a successful install as failed, with no rollback.)
4. Shared helper `lib/cyrus/host/own-game.ts`; orchestrator imports it instead of its private copy.

## Tests (new, all pass)
- cyrus-creature: config.yml + model chowned, ref = game folder, nothing outside; throwing chown still delivers.
- cyrus-modpack: every member file + packs.json chowned, unit record never, throwing chown still installs.
- cyrus-host-servers: engine placer chowns config-role file, swallows a throwing chown.
- mods-installers: engine install survives a throwing chownLike.
- fakehost `ChownSpyFs` gained `kind` so it also satisfies HostGuestFs.

## Results (via devhost, one at a time)
- tsc (NODE_OPTIONS 10240): clean, exit 0.
- creature 53/53; modpack + host-servers + modpack-api + delivery 65/65; mods-installers + mods-toggle +
  game-mods-coverage + managed + delivery-enqueue + config-integration + config-delivery 108/108;
  docs-coverage 12/12 (after regenerating reference/modules.md + tests.md, and 07-operations.md updated).
- DB-gated suites (cyrus-*-db) skip as before; not exercised.

## Promote
Still portal-only: no prisma/schema change, no services/modbuilder or Dockerfile change (verified by diff
against main). Same commands as DG: fetch the branch, merge, deploy-staging, promote-production. On staging,
verify with a real creature-mod install through the normal Install button (not Designer ship) that
plugins/BetterModel/config.yml ends up non-root-owned. The owner's server was already fixed by hand.

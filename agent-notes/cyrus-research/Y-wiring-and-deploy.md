# Y: Cyrus wiring audit and deploy readiness (r28, 2026-10-10)

- **Branch:** `feature/cyrus-r28-wiring`, worktree `/tank/dev-worktrees/cyrus-r28`.
- **Base:** `feature/cyrus-r2` at 702cd62d86 (includes the boss/HUD/motion designers), merged in.
- **Status:** Nothing deployed, migrated or flipped.
- **Tests:** full Cyrus + modbuilder suite 2044/2044 pass on node-2 (89 files); `devhost tsc` clean.
- **Owner runbook:** `docs/CYRUS-DEPLOY-RUNBOOK.md` in the branch.

## 1. Wiring matrix

Legend:

| Code | Meaning |
|---|---|
| **W** | Wired, a live code path |
| **FG** | Flag-gated, wired (the flag is named) |
| **TO** | Types/library only |
| **NW** | Not wired |

Layers:

- **(a)** Build service prompt/validator/artifact (`services/modbuilder`; every file is in the Dockerfile and the deploy script, now test-guarded)
- **(b)** Portal (createModBuild / studios / sync)
- **(c)** Plan gate + token billing. Billing is uniform: `gateBuild` reserves tokens and the settle charges the actual `costUsd`. There is no per-kind price.
- **(d)** Delivery to a server

| Feature | (a) service | (b) portal | (c) gate / billing | (d) delivery |
|---|---|---|---|---|
| texture | W `textures.js` | W `assets/request.ts`, sync builds the pack. Studio FG `cyrus_studios_enabled` | plan **all**; build tokens | FG `CYRUS_MANAGED_PLUGINS_REAL` (legacy Mods path, worker/game-mods.ts) + pack store |
| sound (+ library, relay) | W `sounds.js`, `sound-spec.js` | FG `CYRUS_SOUND_LIBRARY_CLEARED` (library), `CYRUS_SOUND_RENDER` (relay/ssh). Studio FG `cyrus_studios_enabled` | **saka+** | as texture; unrendered sounds ship with a notice |
| datapack | W `datapacks.js` | FG `CYRUS_DATAPACK_STUDIO`; sync W; no studio | not gated | **r29: FG enqueue path** `/api/cyrus/delivery/v1` -> job -> orchestrator, FG `CYRUS_DELIVERY` + `CYRUS_DATAPACK_DELIVERY_REAL` (web + worker) |
| worldgen | W (WORLDGEN section) | FG `CYRUS_DATAPACK_STUDIO` + `CYRUS_WORLDGEN` | not gated | **r29: FG enqueue path** (worldgen acknowledgement, `next_restart` refused); real portal->job->Paper run with rollback |
| creature | W `creatures.js` (only when `creatureReady()`) | FG `CYRUS_CREATURES`, 26.x only; editing in Model Studio | plan all (model) | FG `CYRUS_MANAGED_PLUGINS_REAL` + `CYRUS_CREATURES` + BetterModel jar |
| item model states | W `itemmodels.js` | FG `CYRUS_ITEM_STATES` (needs texture allowed) | rides the texture gate | pack path |
| item/ability, menu, quest, boss/encounter, HUD/glyph, motion designers | W `designs.js` + generated `designer-spec.js` (one discriminator / id space / caps) | FG `CYRUS_DESIGNER` (`designer/route.ts`), sync W, **no studio UI** (r27 building it) | not gated (owner decision) | compiled into the jar, so the normal install delivers them; the HUD font rides the pack path |
| `planDesignEdit` ("just tweak a setting") | TO: bundled in `designer-spec.js`, not called | **NW** (deliberately, see section 3) | would be 0 tokens | jar rebuild needed |
| import your own mod | W `import.js` (no model) | FG setting `cyrus_import_enabled`, API only, no page | not gated, not billed | a normal ModBuild install |
| Mod Packs | n/a | **r29: FG `CYRUS_MODPACKS`** API (validate/create/list/get/conflicts/install/uninstall), no UI | "compose" never gated; install needs every open warning acknowledged | **r29: FG** `modpack_install`/`modpack_uninstall` payload ops, `CYRUS_DELIVERY` + `CYRUS_MODPACK_INSTALL_REAL` |
| managed plugins / pack host / Pack Loader | Loader source in tools/packloader (not in the image) | FG `CYRUS_PACK_STORE` / `CYRUS_PACK_*` | n/a | W via the legacy path; jar + seed + store are owner steps |
| conflict engine | n/a | used by the orchestrator + import only, **not** createModBuild | n/a | inside the orchestrator |
| delivery orchestrator | n/a | **r29: FG** `/api/cyrus/delivery/v1` (+ status read model) | install route's checks | FG `CYRUS_DELIVERY` (web + worker); enqueued by lib/modbuilder/delivery.ts |
| **catalog_search / catalog_get** | **FG (NEW r28)**: `catalog.js` + `catalog-mcp.js`, a per-build stdio MCP server over a pre-gated pool; picks come back as `librarySlots` | **FG (NEW r28)** `CYRUS_CATALOG_TOOLS` + `CYRUS_CATALOG_INDEX` (`library/v2/build-wiring.ts`, `build-offer.ts`), only if the service `/health` advertises `catalogTools` | plan tier + licence tiers (`PLAN_TIERS`) + proprietary clearance, in the real `catalogSearch` / `catalogGet`; tool tokens billed via `costUsd` | **NW**: picks are recorded as ModSpec library slots and not shipped (no asset-bytes path) |
| meshgen | TO (no build-service tool) | **r29: FG `CYRUS_MESHGEN`** estimate / job / result routes, no UI | estimate shown + accepted before a job; price settings read | **r29:** durable file queue + `cyrus-meshgen` worker tick; accepted mesh -> asset revision + model asset |
| Test Flight gate | runner on node-2 | sweep FG `CYRUS_TESTFLIGHT_GATE` (worker schedule); block FG `CYRUS_TESTFLIGHT_BLOCK_ON_FAIL` (install + publish) | n/a | gate only |
| playtest bots | bot on node-2 | **r29: FG `CYRUS_PLAYTEST`** inside the gate flight, from the build's stored ModSpec; verdict stored apart, never blocks | n/a | n/a |
| Server Doctor / telemetry | n/a | **r29:** admin read-only `POST /api/admin/cyrus/doctor` (FG `CYRUS_SERVER_DOCTOR`); signed ingest `/api/cyrus/telemetry/v1/ingest` (FG `CYRUS_HEALTH_TELEMETRY`), 503 until the DRAFT tables exist | n/a | n/a |
| Model Studio + editor | n/a | FG `cyrus_model_studio_enabled` / `cyrus_model_editor_enabled` + studios gate; the preview renderer is refused in prod | plan all for edits | via texture sync (item paint); creature paint not compiled |
| config studio (r23) | not audited: branch running, not touched | | | |

## 2. Wired in r28 (flag-gated, behaviour-neutral when off)

1. **Catalog tools in builds.** The build container cannot reach the portal, so:
   - The portal runs the REAL gated `catalogSearch` / `catalogGet` for up to 16 deterministic queries from the request (word pairs, then words), within a 2.5 s budget.
   - It sends a pool of at most 24 assets (at most 64 KiB) with each row's `catalog_get` answer.
   - In the build, `catalog-mcp.js` answers the same two tools (the portal's definitions) over that pool only, with the ~1k-token result cap and at most 8 calls.
   - The model writes `assets/library.json`. The service keeps only refs it offered whose kind matches, removes the file before sanitize, and returns `librarySlots` (ModSpec `source:"library"`, `libraryRef:"cat:<sha256>"`).
   - The portal re-validates the slots into `ModBuild.result.librarySlots`.
   - **Off:** no lookups, no `catalog` field, no `--mcp-config`, no prompt part, no new record fields (proven by test).
   - Catalog builds skip dedupe.
   - Not verified with the real CLI: whether `--mcp-config` + `--allowedTools mcp__cyrus_catalog__*` lets the model call the tools in `-p` mode. The fake-CLI test exercises the real MCP server. **Verify with one real build after step 4** (an API key, so no subscription use).
2. **Deploy script** `scripts/cyrus/deploy-modbuilder.sh`. `/root/agent-notes/deploy-modbuilder.sh` now wraps it; the old one is kept `.old-2026-10-10`.
   - The file list is derived from the Dockerfile. The old list missed 9 modules, 6 data files and `template/`.
   - It records the previous image for rollback, and backs up files + env as a tar.
   - It checks `promptVersion`, the new-image marker, the scanner sha (rolls back on mismatch), the registry sha and `auth`.
   - `JDK25=yes` adds the pinned 26.x build args.
   - `FLIP=yes` refuses unless `auth=api_key`.
   - Guard test extended: the `--list` output must cover every Dockerfile COPY source, and spawned scripts must be in COPY.
3. **`/health auth`** now reports `subscription_login` for run.sh's login-file mode (it said `none`), plus `gateway_token`. `features.catalogTools` marks the new image.
4. **`scripts/cyrus/smoke-readonly.sh`**: read-only checks per runbook step:
   - migrations (tables, trigger, seed, telemetry-draft absent)
   - service health / auth / image
   - worker + web units and recent errors
   - flags (the launch pair must be consistent, and public requires api_key)
   - pack base

## 3. Documented, not wired

- **`planDesignEdit`.** Its only test is one case in `cyrus-designer.test.ts`. Wiring it needs:
  - a NEW no-model service mode (apply the edits, recompile, gradle, without `callClaude`), because `config.yml` is baked into the jar
  - a hook BEFORE `gateBuild` (otherwise a user with 0 tokens gets a 402 for a free edit, or the hold must be released)
  - an owner decision on the revision semantics (design sha + compile record change)
  - the owner question "settings-only edits cost 0 tokens?"

  So it was not wired.
- **Delivery enqueue.** There is no `cyrusDelivery` GAME_MOD_SYNC enqueue path. A helper is simple (lib/mods/queue.ts pattern), but a route/UI and a supervised real delivery are owner items. Until then data packs, worldgen and Mod Packs cannot reach a server.
- **Playtest bots and the stored ModSpec.** Playtests in the gate need the build's stored ModSpec. Doctor/telemetry have no callers. meshgen has no build-service tool or job.

## 4. Deploy summary (full detail in the runbook)

1. SQL by hand before the promote: `engine-core.sql` (4 tables + the trigger; if the tables already exist, run only the trigger block), `managed-plugins.sql`, `catalog-v2.sql`. The telemetry file stays a DRAFT. `promote --dry-run` must show only Cyrus CREATEs. The seed runs after.
2. `deploy-staging.sh`, then `promote-production.sh --skip-staging-check` (staging stopped). Mind the auto-rollback on a loaded primary. Rollback: `rollback-release.sh --production`.
3. VM 88001: `deploy-modbuilder.sh` (`JDK25=yes` for 26.x). Health: promptVersion, catalogTools, scanner sha, registry sha, auth. One guard-refusal smoke (one Haiku call).
4. API key (`API_KEY=...`) BEFORE any public launch. Nothing that lets non-preview accounts build, no paid evals, and no catalog tools or meshgen for customers before it.
5. Infra env in `/opt/nxeon/.env`:
   - pack S3 + `CYRUS_PACK_PUBLIC_BASE`
   - Pack Loader / BetterModel jars + `CYRUS_MANAGED_PLUGIN_DIR`
   - sound relay pair

   Then `systemctl restart nxeon-worker`. Web env changes take effect at the next promote cutover.
6. Flags, preview-only, one at a time: DESIGNER, ITEM_STATES, DATAPACK_STUDIO, then WORLDGEN, CREATURES, the studios settings, import, TESTFLIGHT_GATE, then BLOCK_ON_FAIL, MANAGED_PLUGINS_REAL, then DELIVERY trio (no effect until enqueue), SOUND_LIBRARY_CLEARED, CATALOG_TOOLS. Leave PLAYTEST / DOCTOR / TELEMETRY / MESHGEN off (no callers).
7. Launch pair together, last: `FLIP=yes` (guarded) or the two `set-setting.sh` calls. Rollback: both false, immediate.

## 5. Phase 2 (r29, `feature/cyrus-r29-wiring2`): the gaps above, closed behind switches

- Delivery enqueue, Mod Pack routes, playtest-in-gate, Doctor, telemetry ingest and meshgen now have callers. Everything is OFF by default and behaviour-neutral when off (each route answers 404; the gate flies no playtest; the meshgen tick returns before any import).
- Still not wired: `planDesignEdit` (section 3), shipping catalog library slots, resource packs / third-party mods inside Mod Packs, a telemetry collector, a ModSpec written by generated builds, and every UI.
- Report: `Z-wiring2.md`. API: `docs/CYRUS-DELIVERY-API.md`.

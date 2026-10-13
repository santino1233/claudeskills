# Z: Cyrus wiring phase 2 (r29, 2026-10-10)

- **Branch:** `feature/cyrus-r29-wiring2`, worktree `/tank/dev-worktrees/cyrus-r29`.
- **Base:** `feature/cyrus-r2` at bdef3c5ba4, merged in. The config studio and API v1 merged cleanly.
- **Status:** nothing deployed, migrated, flipped or merged into r2. Switches default OFF; routes 404 while off.
- **Commits:** fd9aeef9b3 delivery, cef8e493b5 Mod Packs, 17cb32e9ed callers, then runbook/smoke, the merge, docs.

## What was built

1. **Delivery enqueue.** Before this, nothing enqueued `cyrusDelivery`.
   - `POST /api/cyrus/delivery/v1` delivers or uninstalls a mod; `GET /api/cyrus/delivery/v1[/<jobId>]` reads status.
   - Checks: the install route's (`installEligibility` extracted, behaviour unchanged), plus restart and worldgen acknowledgements; `next_restart` refused for worldgen and creatures.
   - Idempotency key (client key per account, or derived and reused only while queued/running); one job per server under the advisory lock.
   - ServerMod row goes INSTALLING / UPDATING / REMOVING, restored on refusal or rollback.
   - The status read model shows `rolled_back` / `rollback_incomplete` (`needsAttention`) honestly; a DONE job without a result is never a success.
   - Host-neutral job body (`lib/cyrus/delivery/job.ts`) re-checks requester, build and project against the server's owner.
2. **Mod Pack API.** `/api/cyrus/modpacks/v1`: validate, create, list, get, conflicts (read-only, against the live server), install, uninstall.
   - Switch `CYRUS_MODPACKS`; install and uninstall also need `CYRUS_DELIVERY`.
   - Members: own builds, or Cyrus builds installed on own servers.
   - Install requires EVERY open warning acknowledged, the pack's own and the live-server ones (owner recommendation applied).
   - Per-account file store; the worker re-verifies sha256, manifest and acknowledgements. Payload ops `modpack_install` / `modpack_uninstall`.
   - No UI; contract in `docs/CYRUS-DELIVERY-API.md`.
3. **Callers.**
   - **Gate to playtest bots** (`CYRUS_PLAYTEST`): the stored ModSpec becomes a playtest plan flown in the same flight. Its verdict is stored apart and never changes the boot verdict or the block.
   - **Server Doctor:** admin-only `POST /api/admin/cyrus/doctor`, read-only (no console), audited.
   - **Telemetry ingest:** HMAC-signed and strict. One bad signal refuses the whole batch. It answers 503 while the DRAFT tables are absent, and the migration was NOT run.
   - **Meshgen:** estimate first; a job needs it accepted; project/game/estimate forced server-side; durable file queue (`fs-jobs.ts`) + 30 s worker tick; accepted mesh -> asset revision + model asset row, once.
4. **Docs.**
   - Runbook (6.7, 6.8, 6.8b, later rows, env reference); smoke `delivery` step + flag-combination checks; `DOCUMENTATION.md`, Y matrix, tracker, OWNER-ACTIONS. **No new migration file.**

## Ran

- **Full Cyrus + modbuilder suite after the merge:** 2192/2192 pass (node-2). `devhost tsc` clean before and after the merge.
- **New tests:** 13 delivery-enqueue, 5 Mod Pack, 15 callers. Each uses the in-memory queue, the REAL job body and orchestrator, and the fake server.
- **One real node-2 flight**, `test/cyrus-delivery-enqueue-real.ts`: portal function, then job, then orchestrator, then real Paper 1.21.11 (Test Flight), then status. Record: `delivery-enqueue-r29-flights-2026-10-10.json`.
  1. TfItemModel + the worldgen showcase delivered and came up healthy. An idempotent replay returned the same job.
  2. An update whose jar cannot load failed the health check, was rolled back to the exact previous bytes, restarted, and came up healthy. The install row went back to v1 with "Rolled back: ...".
  3. Uninstall removed it.
- A first attempt under node-2 load ~18 (`...-run1-loaded-...json`): the rollback restart missed the 200 s boot window and the status honestly said `rollback_incomplete`; rerun with 420 s. Server dirs removed.

## Not run / not built

- No customer server, VM 88001, production DB or paid model call touched.
- The Nxeon DB enqueue (`lib/modbuilder/delivery.ts`: advisory lock, JSON-path idempotency) has **no throwaway-DB test**. Only the in-memory twin is tested.
- No real meshgen Blender run on this path (fake runner). No real Doctor run on a live server. No collector exists for telemetry.
- These are still not wired:
  - `planDesignEdit`
  - shipping catalog library slots
  - resource packs and third-party mods inside Mod Packs
  - a ModSpec written by generated builds, so playtests are "not run" for them
  - every UI

## Owner

See OWNER-ACTIONS "Wiring phase 2":

- a supervised delivery to your test server before `CYRUS_DELIVERY=1`
- whether restarts may be automatic
- whether a failed playtest should block
- Mod Pack file retention
- telemetry tables only together with their models, the retention job and the lawyer's wording
- meshgen prices

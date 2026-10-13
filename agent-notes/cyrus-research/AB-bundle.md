# AB: Cyrus r31 bundle (2026-10-11)

Branch `feature/cyrus-r31-bundle` (worktree `/tank/dev-worktrees/cyrus-r31`, from `feature/cyrus-r2` a2c12e8d3f, already up to date with r2). NOT merged, NOT deployed, every switch OFF. **The owner has not reviewed the v2 mockups the screens follow.**

Commits: 31bbb1ae29, 84966c715f, d5238f8c46, 92d7fa4a69 (docs).

## Built
1. **Designer edits reach servers** (`CYRUS_DESIGNER_BUILDS`). "Build this revision" sends the saved revision's designs to the build service (`designEdit`), with no model and no tokens.
   - Config.yml-only edit: the base jar is repacked and only `config.yml` differs.
   - Structural edit: javac.
   - "Send to server" uses `/api/cyrus/delivery/v1` (needs_ack, status).
2. **Screens.**
   - Mod Packs + conflicts: every open warning must be acknowledged.
   - Import: attestation, allowlist; the scan is never called "safe".
   - Data packs + worldgen: read-only, per-version re-validation, restart banner, rollback states.
   - New read API: `/api/cyrus/datapacks/v1`.
3. **Library.**
   - Browser over a gated browse API: every kind (motion and effect included), licence tier, Minecraft fit, plan gate.
   - Use in project (`libraryRef`) with a project-copy sink.
   - Automatic Texture Studio contribution hook.
   - Read-only admin hold queue.

## Ran
- **Real node-2 flight** (`test/cyrus-designer-ship-real.ts`, record `designer-ship-r31-flight-2026-10-11.json`), cooldown edit 160 -> 100:
  - The real build service (real JDK `jar`) took 0.8 s, no model, cost 0. The jar has the same entries and differs in `config.yml` only.
  - Portal delivery function -> real job + orchestrator -> Test Flight Paper 1.21.11: base delivered, then the edit "updated".
  - RCON over the old v1 config: "migrated from version 1 to 2", then `params` shows `cooldown_ticks=100`. The server dir was removed.
- **Tests:** full Cyrus + modbuilder suite **2299/2299**; tsc clean; host-seam ratchet passes.
  - 15 new tests (pipeline, ship service, data pack view, library, contribution hook, import `min_format`).
- **Playwright on node-2** (devhost dev, fixtures `scripts/cyrus/forge-fixtures.ts`): 19 shots, all looked at. Fixed:
  - an import render crash on structured problems
  - phone panels overlapping
  - a loading-state shot
  - the tree layout
  - a red "0 blocking" pill
  - duplicate titles
  - the plan-lock wording
  - an invented `/ns tp` hint
- **Real bug found:** import refused every 1.21.9+ pack (`min_format`), including Cyrus's own packs. Fixed in `lib/cyrus/import/ingest.ts`.

## Not run / not built
- `createDesignerBuild` (Prisma) was not exercised for real; the flight posts the same body to the service.
- No real client and no paid model.
- Mod Pack "check server", install, and the import scan with a running service were not shot (no real server or service in dev).
- Rollback states were not shot (no seeded job).
- Use in project and thumbnails are not live (library backend off, migration not applied).
- Sound, model, meshgen and motion contribution hooks are not wired.
- The hold queue has no publish/remove actions.
- Sync adds a generated revision after the edited one (same content).

## Owner
See OWNER-ACTIONS "r31 bundle". Rebuild the build-service image before switching designer builds on.

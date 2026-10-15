# DP - Cyrus follow-ups after rc18 (2026-10-15)

Branch `feature/cyrus-followups` (worktree `/tank/dev-worktrees/cyrus-followups`, base `release/cyrus-rc18` 84d5be2f).
Commits: e4cfcb9f (Track 3), b7cef87f (Track 2), 8fabb669 (Track 1), ca04e957 (docs). Head: ca04e957.
Not pushed, not deployed. Commit trailer: Opus 5.5 (the model that did the work; the session's attribution rule).

Verification: `devhost tsc` clean (NODE_OPTIONS=--max-old-space-size=10240); suites green, 170/170:
cyrus-creature, cyrus-liveassets, cyrus-liveassets-e2e, cyrus-modpage-layout, cyrus-docs-coverage, game-power-start,
game-player-tracking, game-runtime. `docs-build` regenerated on node-2 and pulled back; `docs-build --check` = current.

## Track 2 - Infinite Dungeon "black and purple checkered mob on floor 1" (P0)

### Verdict
A Cyrus **delivery** bug, two root causes. Not a client that declined the pack: BetterModel's pack was never offered.
Not a generator/model defect: the models and their textures are correct.

### Evidence (artifacts opened, not reasoned from the spec)
- Owner's server = `kodi` (Server cmuzuj8wl00xshlv49mfv4a1p, hostname minecraft-f3izjh). It runs Infinite Dungeon
  **1.6.0** (mb3879f4526e730a7e96b1, ServerMod INSTALLED 2026-10-15 12:55, `lastInstall.restarted=true`), managed
  BetterModel 2.2.0 + Nxeon Pack Loader 0.1.0 installed (CyrusServerManagedPlugin). It is the ONLY production server with
  the managed BetterModel installed. (All prod reads were read-only transactions.)
- Stored creatures (bonewarden, cinderhusk, direwolf, hexwitch) re-compile through `compileStoredCreatures` to the
  recorded bbmodel sha256. Each .bbmodel: format 5.0 free, one embedded PNG (signature + every chunk CRC valid),
  PNG size = `resolution` = uv_width/height (bonewarden 128x128), every face -> texture 0, no UV outside the
  resolution. No wrong path, no "missing" key, no UV mismatch.
- Mod pack `d302b19f...zip` (1.13.0) / `6e4eab95...zip` (1.6.0): pack_format 75 (= 1.21.11, supported 46-999), only
  `assets/nx_oqyxirj4/` sounds + item models/textures. BetterModel models are not expected there (BetterModel builds its
  own pack; managed config `merge-with-external-resources: false`, by design a separate Pack Loader entry).
- `/tank/cyrus-packs/p` (served at cyrus.my/packs): 14 zips, **none** with `assets/bettermodel` -> BetterModel's pack
  was never published for any server, ever.
- Real Paper 1.21.11 boots (Test Flight on node-2, managed BetterModel 2.2.0 + managed config):
  - tf-1-21-11-mv9x17jr-d6e2ed: the 4 dungeon models + the 1.6.0 jar: passed (boot, plugins enabled, clean log);
    BetterModel wrote `plugins/BetterModel/build.zip` (32 089 B, 69 files) BEFORE "Done".
  - tf-1-21-11-mv9x42x9-00f3aa: the banshee example only -> committed fixture
    `test/fixtures/cyrus-creatures/bettermodel-2.2.0-1.21.11-build.zip` (sha256 6c6b3a70...).
  - 2.2.0's pack layout: textures at `assets/bettermodel/textures/item/*`, models in pack.mcmeta overlays
    `bettermodel_modern/` (formats 46-99: `assets/bettermodel/items/bm_models.json`, `models/modern_item/*`) and
    `bettermodel_legacy/` (formats 22-45, incl. `assets/minecraft/models/item/leather_horse_armor.json`).
  - `normalizeBetterModelPack` on that real zip (rc18 code): `unexpected file in BetterModel's pack:
    bettermodel_legacy/assets/bettermodel/models/item/0.json`. After the fix: ok, 69 / 26 entries.
- Client-side consequence: BetterModel's display entities carry item model `bettermodel:bm_models`; without the pack the
  1.21.11 client draws the missing-model cube = the black/purple checkerboard the owner saw.

### Root causes
1. **No hand-off on the standard install path.** `worker/game-mods.ts` -> `afterCyrusModChange` -> `deliverCreatures`
   writes models + config and asks for a restart. BetterModel builds its pack only at start, and the only caller of
   `handoffBetterModelPack` is the delivery orchestrator, only when it restarted the server itself. So after the owner's
   restart nobody published the pack or added the `nx_bmodel00` Pack Loader entry.
2. **The hand-off refused every 1.21.x pack.** Its allowlist was written against BetterModel 3.5.0 / Paper 26.2
   (`assets/bettermodel/**` only) and rejects 2.2.0's overlays. Even the orchestrator path could never work on 1.21.x.

### Fix (b7cef87f)
- `lib/cyrus/creature/handoff.ts`: allowlist adds exactly `bettermodel_(modern|legacy)/assets/bettermodel/**` and
  `bettermodel_legacy/assets/minecraft/models/item/<name>.json`. Everything else still refused (tests: minecraft files
  in the modern overlay, textures under minecraft, unknown overlays, root `assets/minecraft`). The existing zip guards
  stay (size cap, inspectPackZip, unsafe/duplicate names, symlinks, `..` segments, deterministic re-zip).
- `lib/cyrus/creature/after-start.ts` + `worker/game-control.ts`: after a successful GAME_POWER start/restart of a
  Minecraft server (port bound), if the managed BetterModel is installed there and `CYRUS_MANAGED_PLUGINS_REAL=1` +
  `CYRUS_CREATURES=1` (both on in prod): wait up to 30 s for build.zip, publish it content-addressed, upsert the Pack
  Loader entry. The packs.json write goes through `writeLoaderConfig` (tmp+rename, best-effort chownLike to the game
  folder's owner). Wrapped in try/catch: an error is logged and never fails the power action.
- Known gaps: a restart the platform did not make (console `stop`, crash restart, the "still starting" branch) does not
  hand off; a stale build.zip from the previous boot can only be read if BetterModel failed to rebuild it.

### What happens to an already-installed mod (kodi)
- Needs only a **portal + worker deploy** (promote; the worker runs `worker/game-control.ts`). **No modbuilder image
  change**: nothing under services/modbuilder changed, and no rebuild of the mod is needed.
- After the deploy, the owner (or support) **restarts the server once from the panel** (Manage -> Restart, a GAME_POWER
  job). That run publishes BetterModel's pack and adds it to packs.json; the Pack Loader watches its file. Players then
  **re-join and accept** the "animated custom creatures" pack prompt. No reinstall needed.
- Not yet proven end to end with a real client (no client in Test Flight); the server-side chain (real build.zip ->
  normalize -> publish -> packs.json) is covered by the tests with the real 1.21.11 fixture.

### Separate defect found (not the magenta cause, not fixed)
The latest build **1.13.0** (mb05dabe83580f8491a546) no longer uses BetterModel at all (no `depend`, no
`kr/toxicity/model` classes, MonsterManager rewritten by the boss-arena change) yet still records 4 creatures. On the
designer route `checkWorkspaceCreatures` only checks boss-worn models, so it passed silently. Installing 1.13.0 would
ship models + BetterModel that nothing attaches (mobs = plain vanilla mobs). Builds 1.1-1.12 alternate between using
and not using BetterModel. Needs a generator-side guard (a creature recorded but never attached should be a repair
signal on the designer route too). Logged in KNOWN-BUGS.md.

## Track 3 - red `cyrus-liveassets-e2e` "cubes appear as they arrive" (e4cfcb9f)
The product was wrong, not the capture window. b2e0cb9e made `creatureView` expand the archetype template for any draft
without bones. The banshee fixture is explicit form but names `archetype: "floating_ghost"`; the header (name,
archetype, skin) streams before `"bones"`, so the first partial over 200 chars already showed the full template body
(more cubes than the final rig). Now only a draft carrying a `template` object and no `bones` key is expanded. New unit
test; the e2e file is green.

## Track 1 - mod page screenshots (8fabb669)
Index: `/root/claudeskills/agent-notes/cyrus-research/screens-mod-pages/index.md` (24 full-page PNGs, 1440 + 390,
public `/mods/cyrus/<slug>`, `/cyrus-web/mods/<slug>` stand-in for cyrus.my, portal `/dashboard/nxlabs/cyrus/<slug>`).
Data = 3 FIXTURE mod pages inserted in **staging only** (Infinite Dungeon exists only in production; not copied).
Cleanup SQL: `screens-mod-pages/cleanup-staging.sql`. cyrus.my `/mods` is edge-blocked by the prod nginx vhost today.
Fixed: RemixButton unavailable note (inline span broke its box across lines) and CyrusModTabs (tabs overlapped at
390 px in the portal) with `test/cyrus-modpage-layout.test.ts`; remaining defects are listed in the index.

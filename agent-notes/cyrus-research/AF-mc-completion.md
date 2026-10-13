# AF: Cyrus Minecraft completion (r35), 2026-10-11

Branch `feature/cyrus-r35-mc`, worktree `/tank/dev-worktrees/cyrus-r35` (from `feature/cyrus-r2`; latest r2 c57ef86249 merged in at the end). NOT deployed, not merged into r2, every switch OFF. Docs/runbook/OWNER-ACTIONS: "r35" sections.

## 1. Legacy 1.21.1 item looks (commit 1)
- `lib/cyrus/itemmodel/legacy.ts`: each mod gets a block of custom_model_data numbers, and a manifest `assets/legacy-models.json` maps each texture to a carrier item and a number. Carrier models get overrides; `versionAssetLimits()` lists what 1.21.1 cannot do.
- Pack format 34, no `items/` definitions. Only damage states; other states refused with reasons; carrier clash risk shown.
- Registry capability `legacyCustomModelData`. Service manifest check + prompt variant; portal sync, plan notices, router warns instead of blocking. Flags: `CYRUS_LEGACY_TEXTURES` + `MB_LEGACY_TEXTURES`.
- **RAN:** carrier list checked against the vanilla 1.21.1 client jar (52 carriers pass, feather dropped). One Test Flight on Paper 1.21.1 passed 6/6 (`legacy-r35-flight-2026-10-11.json`).
- **NOT RUN:** a real 1.21.1 client showing the textures, or an AI build on 1.21.1 (needs the builder image rebuilt).

## 2. Multi-version build matrix (commit 2)
- `lib/cyrus/matrix`, flag `CYRUS_BUILD_MATRIX`:
  - planMatrix: per version, the emitter, JDK, compile API, pack format, limits and pin; refusals come with reasons.
  - runMatrix: one version at a time, failures kept per row, one Test Flight per version.
  - pickForServer: built on lifecycle checkCompat; never picks a blocked version.
- Not wired into the builds route; records not stored yet.
- **RAN** (no AI): one design compiled against each pinned Paper's own classpath, then one flight per version. 1.21.1, 1.21.4, 1.21.8 and 1.21.11 passed; 26.2 was refused as a preview version (`matrix-r35-flights-2026-10-11.json`).

## 3. Try It throwaway server (commit 3)
- Controller `services/modbuilder/tools/tryit/tryit.js` on node-2. Each session is one transient systemd unit running as uid 65534:
  - TTL of 30 min at most; MemoryMax 1536M, CPU 200%, TasksMax 256;
  - a reap timer cleans up even if the portal never calls stop;
  - 1 session per user, 1 per host, 3 per user per day;
  - whitelist on from the first tick; an exposed session must be online-mode;
  - pack sha1 checked before boot; risky RCON commands refused.
- Portal: policy (own build, paid tier, finished jar, pinned version), connect steps, 404-while-off API via the host seam, unplaced `TryItButton`.
- **RAN** (1.21.11, bound to 127.0.0.1): create, pack served (sha1 matched), boot in 34.6 s, RCON checks (whitelist, item look, plugins). A second session for the same user was refused. Stop removed the unit, ports, files and timer (`tryit-r35-flight-2026-10-11.json`).
- **NOT RUN:** public exposure (owner: firewall 47200-47299, DNS, `TRYIT_PUBLIC_HOST`), a real client joining, or storing sessions in the DB.

## Checks
- After the r2 merge: the full Cyrus + modbuilder suite passed (2394/2394) and tsc is clean; the host-seam test passes.
- Not touched: customer VMs, VM 88001, the prod DB, any flag. No paid model calls.
- Left on node-2: fixture jars in `inbox/fx`, the new classpath files, `tryit-bin/`, `tryit/ledger.json`. No units or timers.

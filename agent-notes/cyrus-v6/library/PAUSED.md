# Cyrus Pattern Library: PAUSED (2026-10-08, owner near the usage limit)

Branch `feature/cyrus-v6-library`, worktree `/tank/dev-worktrees/cyrus-v6-library`. Committed as WIP.
No AI usage is needed for any step below (javac, Paper servers and unit tests only).

## Done
- Licensing policy, schema, 36 patterns, CLI, service integration (`MB_LIBRARY` off|index|auto|attach,
  default off), status helpers, offline A/B model, docs section, notes (LIBRARY.md, SCALE-PLAN.md).
- node-2 toolchain in `/tank/nxeon-build/wt/cyrus-v6-library/services/modbuilder/library/.cache`
  (JDK, Gradle, 4 classpaths, 4 Paper server jars).
- `library.js verify`: 144/144 compile + scan clean (records committed in `library/minecraft/verify.json`).

## Not done (in this order)
1. **Unit tests never ran.** `cd /tank/dev-worktrees/cyrus-v6-library && /opt/nxeon/scripts/devhost test
   test/cyrus-library.test.ts test/cyrus-library-pipeline.test.ts test/modbuilder-pipeline.test.ts
   test/modbuilder-efficiency.test.ts`. Fix what fails (most likely candidates: the "built file is up to
   date" test after any edit -> run `node services/modbuilder/tools/library.js build`; selector
   assertions in `cyrus-library.test.ts` "finds the obvious ones").
2. **Fix the 4 runtime failures from the 1.21.4 run** (details in LIBRARY.md section 2; records already
   committed): `messages` (real bug: legacy &-codes with <placeholders>), `objective-tracker` and
   `particle-shapes` (old names are still accepted on 1.21.4: fix the tests/docs, resolve entity types by
   registry key), `paged-menu` (test checks slot 9, should be slot 10).
   **Runtime check** for the other versions: `devhost run --lock -- node services/modbuilder/tools/library.js verify` (re-run once: it now
   captures javac warnings) then `devhost run --lock -- node services/modbuilder/tools/library.js runtime`
   (waits for 1.6 GB slice headroom per Paper boot). First Paper boot per version downloads the vanilla
   jar (Mojang EULA accepted for the throwaway test server, as `eval/rtcheck.py` does).
3. Pull results: `devhost pull services/modbuilder/library/minecraft/verify.json services/modbuilder/library/minecraft/verify.json`
   and the same for `services/modbuilder/library/minecraft.json`; `node services/modbuilder/tools/library.js status`.
   Fix any FAIL (the log of each server is in `.cache/runs/<v>/server.log` on node-2), re-run 2.
4. `devhost tsc` once; commit `services/modbuilder/library/minecraft/verify.json`,
   `services/modbuilder/library/minecraft.json` (+ any fixed pattern files) with explicit paths.
5. Update LIBRARY.md section 2 with the runtime results; `devhost rm` when done (frees node-2 cache ~1 GB).

# AA: Model Studio integration + layer 3 (r30, 2026-10-11)

Branch `feature/cyrus-r30-modelstudio` (worktree `/tank/dev-worktrees/cyrus-r30`), from `feature/cyrus-r2` 3969bee6d3, latest r2 merged in. NOT merged into r2, NOT deployed, no migration run, no flag flipped. The layer-3 UI follows the v3 retexture mockup, which the owner has NOT reviewed. Docs: DOCUMENTATION.md "Cyrus Model Studio: integration seams (r30)" and "layer 3, mesh retexture + light edit". Owner items: OWNER-ACTIONS.md "Model Studio integration + layer 3".

## Commits (in order)
1. **1a viewport/camera/clock**: the cuboid editor draws through the layer-1 three.js `ModelViewport` (2D canvas only as no-WebGL fallback); EditorScene -> shared `ModelScene`; one orbit camera (`CAM_PRESETS`, `fitOrbit`, `projectOrbit` = inverse of `rayFromOrbit`); editor picking uses the same ray maths; `PlaybackClock` is a holder around the timeline clock (one clock).
2. **1b editor saves survive builds**: one current-creature rule (`creature-state.ts`) for both studios and the build sync; the sync 3-way merges the build's RigSpec INTO a current editor save with the existing editor merge (human wins), ships the merged creature, marks the build row `studioKept`. `CyrusModelDraft.surface` (paint/editor/mesh) + manual SQL `prisma/manual-migrations/2026-10-11-cyrus-model-drafts.sql` (NOT applied). Editor drafts wired to it. Fixed a manifest-path collision between the paint doc and the editor doc.
3. **1c creature paint -> delivered skin**: `creature/paint.ts` + a compile hook; paint stored in `MbAssets.creatures[].paint`, delivery re-compiles and proves the bytes.
4. **1d handgun grip (PROPOSED, OFF)**: `gripOnFist` behind `CYRUS_HANDGUN_GRIP_FIX`; off = byte-identical (golden + proved equal to the previous code); on = grip distance 1.948 -> 0 (third person), 3.148 -> 0 (first person).
5. **2 layer 3**: MeshEditDoc v1, the one op log (`oplog.ts`, editor history now uses it), part transforms on named parts with snapping and limits, per-channel lossless layers + UV island fills, template sliders validated by the meshgen schema + deterministic block-out + rebuild (0 tokens), legal badge from the ledger (moved to client-safe `assets3d/ledger.ts`), export picker from asset profiles, plan gate (All models, server side, fail closed), drafts, phone approve. Page `/dashboard/cyrus/<build>/studio/mesh`.
6. Docs.

## RAN
- `devhost tsc`: clean (after each step and after the r2 merge).
- Tests (node-2): new `test/cyrus-modelstudio-integration.test.ts` (merge rule, sync kept/merged/no-base, drafts surface, paint compile + delivery proof + size mismatch), `test/cyrus-handgun-grip.test.ts` (goldens), `test/cyrus-modelstudio-layer3.test.ts` on two REAL meshgen glbs (doc, ops, op log replay, sliders, block-out, export honesty, legal rules, part maths, server gate/stale/retention/rebuild/drafts, HTTP, client import graph has no `node:`). Full Cyrus suite after the r2 merge: 2285/2285.
- REAL Test Flight (node-2, lock, torn down): Paper 26.2 + BetterModel 3.5.0, a painted banshee head (294 texels): the delivered `.bbmodel` equals the compile, spawn/despawn pass, and BetterModel's own `build.zip` holds `textures/item/a.png` **byte-identical to the painted PNG**. `creature-paint-r30-flight-2026-10-11.json`.
- Devhost UI runs with screenshots I looked at and fixed: `impl-shots/r30-editor-threeviewport-*.png` (editor on three.js, dark/light/phone) and `impl-shots/layer3-*.png` (dark, light, block-out sliders + rebuild 503, a REAL save through the UI = revision 11 reopened, game-derived, Saka locked, phone dark/light approving a real autosaved draft).

## NOT RUN / not built
- No game client looked at anything (painted skins, grip fix, meshes).
- Layer 3 export: no supported game takes glTF (Minecraft = cuboids, no converter), so Export stays disabled with that reason; FiveM/RedM need an adapter + the Windows packer.
- A real rebuild from the studio on node-2 (tested with a fake queue; the worker path itself was proven by r18/r29). No model was called anywhere.
- The migration (SQL written, not applied); no production anything.
- Not linked from the Assets tab yet.

## Findings
- meshgen glbs are unwrapped per part: their UV islands overlap (rifle ~88% of texels shared), so a channel fill on one part also lands on others. The studio says so; material-slot edits are per part. A per-part atlas in the meshgen harness would fix it.
- A glTF mesh with several materials is several primitives with ONE name; transforms now use one centre per named part (otherwise parts split on rotation).

## Final numbers
After merging `feature/cyrus-r2` 473798cd40: `devhost test test/cyrus-*.test.ts test/modbuilder-*.test.ts` **2285/2285 pass**, `devhost tsc` clean. New tests: layer3 20, integration 10, handgun grip 5 (plus updated editor/model studio tests). Host seam test passes (no new Nxeon imports under lib/cyrus).

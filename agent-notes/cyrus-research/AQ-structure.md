# AQ - Cyrus mod structure: declutter, parts, mod suites (r45, 2026-10-11)
Branch `feature/cyrus-r45-structure` (worktree `/tank/dev-worktrees/cyrus-r45`), latest r2 (up to r50) merged. NOT merged into r2, NOT deployed, flag `CYRUS_MOD_SUITES` OFF, no migration.

## Done
1. **Design** (not in git, like v7): `cyrus-designs/v8-structure/STRUCTURE-PLAN.md` (1,370 words) + 3 mockups (Forge parts fan, suite tree + dependency view, Minecraft vs Terraria nav), dark + phone shots looked at and fixed.
2. **Capability manifest** `lib/cyrus/manifest` `usableFor(game, version)`: derived from adapter, registry, designer features, exporters, GameSupport, plan gate. Applied to studio switch, designer tabs + action palette, studio pages (404 when the game cannot use it), project page, new-mod flow + templates, library browser, `catalog_search`. Minecraft hides Mesh, glTF/PBR/HDRI/decal kinds, client-only features (why-not lines); 1.21.1 hides item states; Terraria/Valheim/Zomboid are code-only.
3. **ModSpec v2 modules** `lib/cyrus/engine-core/modules.ts`: migration, cross-references (incl. inside designs), scoped plan, scoped change request, three-way scope guard (files + config values), per-part revisions / Test Flight / tokens from the revision chain, export under a new namespace, decomposed generation plan, size budget. Store takes v2 only with the flag. Designer `SUITE_KIND_LIMITS` (default limits unchanged).
4. **UI**: parts fan in the Forge, part crumb in studios, parts card on the project page (tree, dependency view, checks, edit part vs whole mod, budget, suite vs Mod Pack copy).
5. Docs (DOCUMENTATION.md section), OWNER-ACTIONS "r45", tracker 34.

## Ran
- Unit: `test/cyrus-manifest.test.ts` 13/13, `test/cyrus-modules.test.ts` 18/18. Full Cyrus suite after merging the latest r2 (r42, r44, r48, r50) **2633/2633** (host seam + db-split ratchets included); tsc clean.
- **Real Test Flight** (node-2, Paper 1.21.11, no AI, no client): synthetic suites from the verified designer fixtures, 17 design files (8 items, 2 menus, 4 quests, 2 bosses, 1 encounter) and 80 files (44 items, 8 menus, 16 quests, 8 bosses, 4 encounters): ModSpec v2 valid, javac 0 warnings, strict scan 0/0, both flights PASSED (every boss and encounter registered, a boss from the last copy spawned, reload clean). Boot 19.7 s / 18.9 s, peak RSS 945 / 960 MB, MSPT avg 0.4-1.1 ms. Record `structure-r45-flights-2026-10-11.json`.
- Playwright on node-2 (`devhost dev`, `scripts/cyrus/structure-fixtures.ts`): 9 shots `cyrus-designs/impl-shots/struct-*.png` (Forge dark/light/phone, project dark/whole/phone, new mod dark/phone, studio crumb), looked at; fixed from them: vertical fan clipped under the top bar (now horizontal, away from the panel, downward for centred lists), phone parts strip in the mod panel, 3-column squeeze, DAG icon CSS. Dev server OOM-killed twice (shared 10 GB slice): the crumb and new-mod shots are from before the last fixes.

## Not run / not wired
- The scope guard on a real scoped build result (a scoped edit sends a scoped change request through the normal change build; the guard functions are tested, not hooked into build sync).
- Part-level Test Flight and "export part" buttons (functions exist, no UI action); service-side suite limits (`services/modbuilder/designs.js`); AI decomposed generation (plan only; no paid calls).
- ModSpec v2 is not the engine default; HUD parts have no studio (open Files).

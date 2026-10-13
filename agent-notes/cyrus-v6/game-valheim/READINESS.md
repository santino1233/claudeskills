# Valheim in Cyrus: readiness checklist (2026-10-08)

Status: **`soon`** (not flipped; going `live` is the owner's call). Branch `feature/cyrus-v6-game-valheim`.

## What is done
- [x] `lib/cyrus/games/valheim.ts`: verified `GameSupport` (versions 1.0.x current / 0.221.x legacy / older unsupported, install side + plain-language reasons, breakage risks, outdated signals, 12 universal categories, sources, unknowns) and `VALHEIM_TARGET` (game line 1.0, network 40, BepInExPack 5.4.2351, Jötunn 2.30.2).
- [x] `lib/cyrus/games/valheim.knowledge.ts`: Valheim 1.0 knowledge pack (`GameSupport.knowledge`): ~28 verified API facts + 11 failure rules with regex detectors; `apiLinesFor()` for selective retrieval.
- [x] Generator `lib/cyrus/engine/games/valheim.ts` upgraded for 1.0 (see the report for the fixed bugs), version-aware (`cyrus.json`, startup version check), Thunderstore-correct manifest, Jötunn version enforcement for content mods, AI disclosure, runnable xUnit project for Yakko.
- [x] Validator `lib/cyrus/games/valheim.validate.ts` + tests `test/cyrus-game-valheim.test.ts`.
- [x] Compile harness `tools/cyrus-valheim-harness/` (node-2): every template compiled against the real 1.0.16 dedicated-server assemblies + generated tests run.

## Before Valheim can go live
### Must have
1. **Real AI generation path.** Today non-Minecraft games stream *template* code (`lib/cyrus/engine`), not model output. A real Valheim build needs the build service to accept `game: "valheim"`: a C# worker on the build VM with the .NET 8 SDK, the knowledge pack in the prompt (`apiLinesFor` on the plan), the validator as the safety scan, and `dotnet build` against the game assemblies as the compile step. (Build-VM changes are owner-only.)
2. **Game assemblies on the build host, never redistributed.** The harness downloads the free dedicated server's `Managed/*.dll` from Steam (app 896660, anonymous, public) at build time into a node-2 cache. The owner should confirm this is acceptable for a commercial build pipeline (it is how the repo's NxeonDevAdmin plugin is already built). Nothing proprietary is committed.
3. **Load test in a real server.** A throwaway Valheim dedicated server (Docker `lloesche/valheim-server` with `BEPINEX=true`, already used by Nxeon) on node-2 or a sandbox VM: install the DLL + Jötunn, start, grep `BepInEx/LogOutput.log` for `<Name> v1.0.0 loaded`, no Harmony errors, and for content mods that ZNetScene registered the prefab. Then a headless client check is not possible; client-side mods (HUD, music, grading) need one manual PC test per archetype.
4. **End-to-end customer test on a real Nxeon Valheim server**: generate → validate → install via the Mods tab (`lib/mods/installers/valheim.ts`, plugin folder `/opt/valheim/config/bepinex/plugins/<Ns>-<Name>`) → restart → join with r2modman carrying the same mod → verify the feature in game → disable → confirm the removal warning was shown. Owner/test account only.
5. **Client-install guidance in the UI** (lifecycle/studio agents): show `cyrus.json.install.note` on the install card; for `side: both`, offer a download of the mod zip and an r2modman profile code for players; warn "console players will not be able to join" when the server has crossplay on.
6. **icon.png (256x256)** for the Thunderstore zip: the generator does not create one; the listing flow must add the creator's icon or the compact Cyrus badge.

### Should have
7. **Version table maintenance.** After every Valheim patch: `CYRUS_VH_REFRESH=1 devhost run --lock -- bash tools/cyrus-valheim-harness/run.sh`; if green, bump `VALHEIM_TARGET.game/verifiedBuild` and (when released) `bepinexPack`/`jotunn`; if red, add a failure rule and fix the generator. Cadence seen: major engine upgrades 2024-04 (Unity 2022), 2025-08 (Unity 6, 0.221.3), 2026-09 (1.0); small patches every 1 to 3 weeks after 1.0.
8. **Outdated watcher** (lifecycle agent): poll Thunderstore for BepInExPack_Valheim / Jötunn and Steam for app 896660 build changes; mark installed Cyrus mods "may need an update" when the game line moves, and tell creators (`outdatedSignals`).
9. **Golden examples** (research item 3): 3 to 5 hand-checked Valheim mods, compiled + load-tested, used as few-shot context and regression tests.
10. **Eval suite** (designed, not run, cost rule): 30 prompts across the 12 categories + 10 adversarial (network, file deletion, admin list, cheats) scored on validator pass, compile pass, load pass.

### Nice to have
11. Asset pipeline for custom models/textures (Unity AssetBundles built with the matching Unity 6 editor; Unity licence terms not checked yet; see research RENDERS-AND-TEXTURES.md).
12. ServerSync-style config locking so server admins' config wins over clients (Jötunn `AdminOnly` config entries are the lighter option).

## Owner decisions
- Accept downloading the public dedicated-server DLLs at build time for compile checks (never shipped)?
- AI disclosure text: generated mods say "created with the assistance of generative AI (Nxeon Cyrus)" in README/csproj, as Thunderstore requires. OK to name only Cyrus and its model names?
- Should Cyrus allow publishing Valheim mods to Thunderstore at all? Its rules reject "untested or non-functional AI-generated mods"; recommend: only after the load test (step 3) passes, and never auto-publish.
- Content mods force Jötunn (for version enforcement). Accept the extra dependency for players?

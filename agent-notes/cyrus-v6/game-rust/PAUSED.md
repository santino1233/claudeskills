# game-rust: PAUSED 2026-10-08 (coordinator stop; Rust is not in the launch)

Branch `feature/cyrus-v6-game-rust` (worktree `/tank/dev-worktrees/cyrus-v6-game-rust`). Commits: `d3169d2525` (main work) and `a6cf731b0c` (WIP fix). Full write-up is in `READINESS.md` (how Rust modding works, what changed, the harness, the go-live checklist).

## Done (and verified)
- `lib/cyrus/games/rust.ts`: the verified GameSupport, plus the version table (2634.289.1 current), `nextRustForcedUpdate`, paths, and the `knowledge` pack (38 API sheet lines, 9 failure rules).
- `lib/cyrus/games/rust.hooks.ts`: 737 hook names, generated.
- `lib/cyrus/games/rust.validate.ts`: the static validator.
- `lib/cyrus/engine/games/rust.ts`: generator upgraded to verified APIs only, `oxide/` file layout, `cyrus.mod.json` manifest.
- `tools/cyrus/rust-check/`: Roslyn compile against stub files. .NET 8 is installed user-local on node-2 in `node_modules/.cyrus-dotnet`.
- `test/cyrus-game-rust.test.ts`. On `d3169d2525` it ran **20/20 pass** on node-2 (1,080 generated projects, zero validator findings).
- The `rust-check` stub compile (run 2) passed **502/540**. The 38 failures were a real generator bug: `[PluginReference] Plugin` was used without `using Oxide.Core.Plugins;`.
- `docs/DOCUMENTATION.md` has a new section, "Cyrus v6: Rust modding support".

## Half-done (committed but NOT re-run)
- `a6cf731b0c` fixes that `using` bug and adds a `compile-using` validator rule with 2 new test assertions. The tests, the rust-check re-run and `tsc` for this commit were queued behind the node-2 lock and **cancelled** at the stop.
- **`tsc` has never completed cleanly on this branch.** The one run printed no errors but its exit code wasn't captured.

## Resume steps
1. Run each command once, from the worktree:
   ```
   /opt/nxeon/scripts/devhost run --lock -- bash -c 'npx tsx --test test/cyrus-game-rust.test.ts; echo $?'
   /opt/nxeon/scripts/devhost run --lock -- bash tools/cyrus/rust-check/run.sh
   ```
   rust-check should report 540/540.
2. Run `devhost tsc` and fix any type errors.
3. Squash or rename the `WIP:` commit.
4. Tell the coordinator that `lib/cyrus/categories.ts` (routing branch) excludes magic/visuals/audio for Rust in `DEFAULT_GAME_CATEGORIES`, while `rust.ts` includes them. The generator has working archetypes for these, but only with built-in effects and sounds.
5. Work through the READINESS part 4 checklist: wire the validator into the build path, feed the apiSheet into prompts, lifecycle outdated warnings. The owner must decide about keeping a reference RustDedicated copy on node-2 for real-DLL compiles.

## Unverified claims (also listed in GameSupport.unknowns)
- Game API member names were cross-checked against Carbon's decompiled hook call sites and 69 public plugins. They were not compiled against the real Assembly-CSharp. The stub surface is Cyrus's own reconstruction.
- `ItemContainer.Insert` / `CanAcceptItem` breakage: the signature change is confirmed in Oxide's manifest. Whether old calls still compile (default parameters) is unknown.
- Facepunch's plugin-guidelines article returned 403.
- Carbon paths on Nxeon are untested.
- Whether players can rename items in 2634 is unknown.
- `BUTTON.RELOAD` (R) as the ability key works per the corpus; how it feels in-game is untested.
- Nothing has been run on a real Rust server.

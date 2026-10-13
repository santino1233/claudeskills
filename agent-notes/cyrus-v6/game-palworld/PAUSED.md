# Palworld agent: PAUSED (2026-10-08, coordinator stop order; Palworld is not in the launch)

Branch `feature/cyrus-v6-game-palworld`, worktree `/tank/dev-worktrees/cyrus-v6-game-palworld`, WIP commit `c91c296099`.
Full research, the Linux-only scope table and the readiness checklist are in `READINESS.md` (same folder).

## Done (committed)
- `lib/cyrus/games/palworld.ts`: GameSupport (default export) with the Linux-only stance (owner decision), `knowledge`
  pack (verified API sheet + 13 failure rules), `PALWORLD_KINDS` with `nxeon: build | client-tip | refuse` and reasons.
- `lib/cyrus/games/palworld.settings.ts`: 70 settings, blocked keys, `mergeOptionSettings`, `settingsIntent`.
- `lib/cyrus/engine/games/palworld.ts`: generator v2. `palworldUE4SS` (what customers get) = settings presets, labelled
  client-side tips, or a refusal with the closest preset / `unsupported`. `palworldLuaPackage` builds every Lua kind.
  All 17 `plausible:` names resolved or removed (table in READINESS.md).
- `lib/cyrus/games/palworld.validate.ts`: static validator (`{ nxeon: false }` lints non-Nxeon packages).
- `test/cyrus-game-palworld.test.ts`; `docs/DOCUMENTATION.md` section.
- Shared files (additive): `Built.essential` / `Built.install` in `lib/cyrus/engine/kit.ts`; `lib/cyrus/engine/templates.ts`
  Katara keeps `max(3, built.essential)` files, README uses `built.install`, Palworld install row corrected.

## Half-done / not verified
- Tests: last completed run (before the Linux-only refactor's final edits) was 22/23; the refactored suite then ran with
  1 failing assertion (case of "console, Mac and Game Pass"), fixed but NOT re-run. Other suites passed in that run per
  the partial log; not confirmed in full.
- `tsc --noEmit` has NOT been run on the final code.
- No sample outputs saved (the samples script was deleted unrun).

## Next steps to resume
1. `cd /tank/dev-worktrees/cyrus-v6-game-palworld && /opt/nxeon/scripts/devhost test test/cyrus-game-palworld.test.ts` then
   `devhost test test/cyrus.test.ts`, then `devhost tsc`; fix anything, commit (drop the WIP prefix).
2. Tell the coordinator about the kit/templates edits (merge note) and the GameSupport contract gap (no "config" packaging,
   used "zip").
3. Owner decisions in READINESS.md (preset install path on Nxeon: panel fields vs raw-config + merge; keep client tips?).
4. Wire presets into the lifecycle install flow (stop server, merge, start, read back) and test on a throwaway Nxeon server.

## Unverified claims (do not present as fact)
- MinRevision 82182 (Pocketpair's example, not the 1.0.5 revision).
- Data-table short names and row ids (`DT_ItemDataTable` "AssaultRifle_Default1", pal ids like "IceFox").
- Coverage of the post-hit hook `CallOnActualDamageProcessed_ToAll`; behaviour of `SendSystemAnnounce` on clients.
- Cyrus's settings ranges are its own safety bounds except the four Pocketpair documents.
- Nothing has been loaded into a real Palworld client or server.

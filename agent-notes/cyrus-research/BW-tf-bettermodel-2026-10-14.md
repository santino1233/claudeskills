# BW: Test Flight provides BetterModel (2026-10-14)

Branch `fix/cyrus-testflight-bettermodel` (worktree /tank/dev-worktrees/cyrus-tf-bm, from main f347f27a), commit d5379429. Verified, NOT promoted.

## Root cause
Creature mods declare (or need) BetterModel; the Test Flight Paper server never had it, so Bukkit skipped the mod
("NOT enabled ... enabling=false") or the mod crashed with NoClassDefFoundError kr/toxicity/model/... Same cause for fox and goblin.

## Change (lib/cyrus/testflight)
- engine.ts (new, server only): `engineNeed` = plugin.yml/paper-plugin.yml depend or softdepend BetterModel, stored creature assets,
  or class bytes referencing kr/toxicity/model/ (catches a mod that uses it without declaring it, flagged `undeclared`).
  `provisionEngine` resolves the catalog pin per Minecraft version (pinFor: 1.21.x -> 2.2.0), reads the jar from
  CYRUS_MANAGED_PLUGIN_DIR with the sha256 pin check, takes the seed names from the pinned libraries ledger
  (`bettermodel-2.2.0-paper-libraries` -> libraries, `bettermodel-2.2.0-libby` -> plugins/BetterModel/.libs, both already on node-2),
  the managed config.yml, and the build's re-compiled .bbmodel files (compileStoredCreatures) when they fit the 64 KB flight-file limit.
  Nothing is downloaded at flight time. Unpinned family (26.x needs Java 25) or missing jar = `unavailable`.
- gate.ts: `planGateFlight` puts BetterModel first, adds seeds/files, memory 1024 MB, boot 300 s / total 600 s; unavailable ->
  `not run: BetterModel jar unavailable: ...` (honest not_run, no false fail). `gateChecks` reads the runner's per-plugin evidence:
  BetterModel NOT enabled -> plugins_enabled = not_run "engine plugin failed: BetterModel did not enable, so the mod could not be tested",
  commands_registered not_run, verdict incomplete (never failed). Engine ok but mod not enabled -> real mod failure, detail names the
  missing dependency / class (and "plugin.yml has no depend: [BetterModel]" when undeclared).
- gate-worker.ts: artifacts() provisions the engine, notes record "BetterModel 2.2.0 was provided in this flight (reason)" + model placement.
- scripts/cyrus/tf-engine-flight.ts: drives the same code path against a jar + service build record.
- Limits: models over 64 KB are not placed (reported in notes; the runner's file limit); BetterModel's own resource pack is not exercised.
  Seeds are assumed present on node-2 (they are; a missing seed makes the runner error -> not_run).

## Real flights (node-2, Paper 1.21.11, BetterModel 2.2.0)
| build | engine | plugins_enabled | commands_registered | verdict |
|---|---|---|---|---|
| fox mb0d8ad449dbcaf7a9addc (depend: BetterModel) | provided | pass: BetterModel enabled, FoxCompanion enabled | pass | passed, "boot-tested on Paper 1.21.11" (boot 20.4 s, peak 975 MB) |
| goblin v1 mb7714738f123ea861d24a (no depend, uses kr.toxicity classes) | provided (detected from class refs) | pass: BetterModel + Goblins enabled | pass | passed |
| goblin v1, engine withheld (old behaviour) | none | fail: Goblins NOT enabled, NoClassDefFoundError kr/toxicity/model/api/platform/PlatformEntity | pass (optional) | failed |

Note on goblin: it does not declare the dependency but works once BetterModel is installed (Bukkit class lookup crosses plugins), so on a
managed server it is fine; the flight now records a note that plugin.yml lacks depend. rc12's autofix would add it anyway.

## Verification
tsc 0 (devhost). Cyrus suite 3510/3511; the one failure `test/cyrus-liveassets-e2e.test.ts` "mid-stream views per kind" fails identically on
unmodified main (pre-existing, timing). New: test/cyrus-testflight-engine.test.ts (12 tests). Docs references regenerated (docs-build).

## Owner commands
Portal-only change, NO services/modbuilder change, NO image bump. The gate runs in the portal worker; the runner on node-2 is unchanged.
Promote after merging (this branch is from main f347f27a; rc12 branch is separate, they touch different files):
`cd /opt/nxeon && git merge --ff-only fix/cyrus-testflight-bettermodel` (or merge into the release branch you promote), then the usual
`scripts/promote-production.sh`. Then re-fly the two builds (clear ModBuild.cyrus.testFlight so dueForFlight picks them up, or let the
next builds fly). The red "did not load in our test server" banner stays for old stored failed flights until re-flown.

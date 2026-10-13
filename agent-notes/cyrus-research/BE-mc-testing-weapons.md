# BE: Minecraft testing upgrades + designer weapons (2026-10-12)
Branch `feature/cyrus-mc-testing-weapons` (worktree /tank/dev-worktrees/cyrus-mc-weapons, from 317a38bd9f), 6 commits 1a9169de43..602b831d86. NOT merged, NOT deployed, no flag flipped, no migration.

## Built
1. Stress bot `combat` mode (survival; gear/buffs/difficulty over RCON; hostile waves; fights). Gate picks it from planned lanes (creature, designBoss) / designer bosses. Basis: Paper 1.21.11 bytecode (MeleeAttackGoal / TargetingConditions ignore creative).
2. `worldgen` check: forceload 3x3, `execute if loaded`, `fill ... replace` counts in <=64-high slices vs a coarse range from the data pack spec; failure names feature, measured vs expected. Gate switch CYRUS_TESTFLIGHT_WORLDGEN (OFF), never blocks Install.
3. Mutants + controls (lib/cyrus/testflight/mutants.ts). Gap found and fixed: a mod lagging from enable was "slow host, not run"; judges now use JVM CPU (busyCpuPct 85).
4. Rules rules-2026-10-12.1: teleport-ground-load-chunk-first, mob-move-pathfinder, mob-flee-gate-target (precheck), mob-fresh-entity-retaliation. Correction to the field note: on Paper getHighestBlockYAt loads the chunk synchronously (javap -c, 5 versions).
5. Designer hitscan / beam / area_blast: spec, schema, compile, Weapons.java (only in mods using it: goldens unchanged), simulator, studio palette, prompt, routing, perf audit, perf-risk rule, coverage archetype. Click weapons need cooldownTicks >= 4: no server-side full-auto (client-mod lane).
6. Docs: 02/03/09/10 (D-56..D-58)/11/12, LESSONS L8-L10, findings status, DOCUMENTATION.md, regenerated references.

## RAN
- Suite (cyrus-* + modbuilder-*): 3119/3120; the 1 failure is cyrus-liveassets-e2e timing under parallel load (passes alone twice; untouched code). tsc 0, devhost db push ok, devhost build 0.
- Real node-2 Paper 1.21.11 (mc-testing-flights-2026-10-12.json, 5/5): combat bot survival 40 hits / 9 kills / 20 TPS; TfBroken rejected; TfSpam rejected (11 TPS at 115-126% CPU); showcase ore 127-135 in range 1-4096; ore-in-air 0 -> rejected.
- Weapons (weapons-flights-2026-10-12.json): javac 0 warnings + strict scan 0 on 1.21.1/1.21.4/1.21.8/1.21.11/26.2; playtest: hitscan 6.0, summed pellets 6.0 then 2.0 (reset), blast 4.0 / 7.0 / user 20.0, beam 5.0.

## NOT RUN
Paid model build with the new prompt sections; real client (tracers, beams); PvP / protection plugins; combat bot and probes on other versions; image rebuild; showcase-capture finding 7.

## Owner
Confirm D-56 (4-tick weapon floor), D-57 (probes informational, OFF), D-58 (busy-CPU fail); should a failed worldgen probe ever block Install; weapons hit players by default (`players: true`, PvP rules apply) - keep?

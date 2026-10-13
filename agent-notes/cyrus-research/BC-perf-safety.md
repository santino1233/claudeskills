# BC perf safety (2026-10-11, after the ChunkMirror incident)

Branch `feature/cyrus-perf-safety` (worktree /tank/dev-worktrees/cyrus-perf, from main 22cfdfd90e, main re-merged: no change). 6 commits, NOT merged, NOT deployed, no flag flipped, no migration, no customer server touched, no paid model call.

## Built
1. **Perf-risk classifier** `lib/cyrus/safety/perf-risk.ts` (pure): 13 prompt rules + 4 config rules, severity, plain reason, safe bounded alternative, `applyPerfChoice` (safe default / "Build anyway"), `perfPreBuildCheck` (409 `perf_confirm`). Interface in tracker section 49 for the planner agent (not wired into the plan screen by me).
2. **NxPerf watchdog** (`services/modbuilder/perf/`, injected by `perf.js` before every javac of generated plugins): real TPS, per-listener main-thread timing, pause of the plugin's costliest listeners/timers/queues on sustained lag it causes, a spawn guard (entities its own code spawns, 50/s), `/<cmd> perf status|pause|resume`, perf: config section. Prompt rule 10 + NxPerf API sheet, PERF pre-check + scan notes, failure rule `perf-unbounded-fanout`.
3. **Test Flight stress phase** (runner tf-lite-5): mobs, chunk loads, mod commands, a Mineflayer builder bot (1.21.11); real TPS/MSPT/entities/RSS; pass/warn/fail/not_run with numbers; a FAILED stress blocks Install by default.
4. **Post-install watch** (`worker/cyrus-perf-watch.ts`, pure judge in `lib/cyrus/safety/perf-watch.ts`): 15 min after a Cyrus install, disable + restart (default) / rollback / notify, owner told in-app + email. **Disable this mod now** on the Mods tab.
5. **Emitter audit** `lib/cyrus/safety/perf-caps.ts`; new data pack tick limits (unconditional summon refused, particles, fill/clone, @e warn).
6. Docs: 02-engine "Performance safety", D-55, testing index, gaps; references regenerated.

## Ran (node-2)
- Watchdog + demo plugin + bounded fixture: javac clean (0 warnings) and strict scan clean on 1.21.1/1.21.4/1.21.8/1.21.11; NxPerfCore JVM test 20/20 (`perf-compile-2026-10-11.json`).
- Stress flights, Paper 1.21.11 unless noted (`perf-flights-2026-10-11.json`): unbounded ChunkMirror FAIL (9038 entities); bounded PASS (TPS 19.96, 53 entities); unbounded + watchdog without spawn guard FAIL (9559); unbounded + watchdog with spawn guard PASS (553 entities, `[NxPerf] PAUSED reason=entities`); bounded on 1.21.4 PASS, block events not exercised (no verified bot).
- Cyrus + modbuilder suite 2835/2835; tsc clean; host seam, db split, docs coverage pass.

## Not run / honest gaps
- No real model build with the new prompt rules (no paid run). The image on VM 88001 must be rebuilt for the watchdog/prompt to take effect.
- On node-2 TPS never collapsed within 40 s (fast CPU, flat world); the unbounded fail is entity runaway, not TPS. A longer or heavier load may be needed to reproduce the 1 TPS case.
- Post-install watch and Disable-now: unit-tested only (never against a live customer log, by rule). Work inside raw scheduler tasks the model writes anyway is not measured by the watchdog.
- Designer click-ability floor left as an owner decision (would change every designer golden jar).
- Perf-risk not yet shown on the plan screen (planner branch).

Owner actions: OWNER-ACTIONS "Perf safety" (incl. what to do about ChunkMirror on minecraft-f3izjh now).

## After merging release/cyrus-rc2 (head bf47938edc)
Conflicts resolved (Dockerfile both files, 33 failure rules, 12 sweeps, docs); bundles + references regenerated; next build passed after splitting the jar profile out of stress.ts (client bundle). Suite 3051/3058: the 7 failures are pre-existing on rc2 605f31e9b2 unchanged (cyrus-planner / capability-catalogue creature-on-1.21.x expectations vs the BetterModel 2.2.0 path). tsc clean. Flights re-run: unbounded FAIL (9366 entities), bounded PASS. Golden corpus with the watchdog: 259/259 version builds unchanged, 0 broken (mc-ranks perm-attach warning is baseline); 19 golden plugins would get PERF pre-check hits (mostly raw timers), i.e. one repair round for code written that way. Record: perf-golden-2026-10-11.json.

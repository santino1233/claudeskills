# T: Cyrus motion core (2026-10-10)

Branch `feature/cyrus-r21-motion` (worktree `/tank/dev-worktrees/cyrus-r21`), latest `feature/cyrus-r2` merged in (incl. Model Studio L1 + L2). Not deployed, nothing in prod, `CYRUS_DESIGNER` stays off, no paid model calls, no migrations.

## Delivered (one commit each, in order)
1. **Architecture**: `cyrus-designs/v4-motion/MOTION-PLAN.md` (1.75k words; copy in `docs/cyrus/motion/`).
2. **Pure core** `lib/cyrus/motion/`: MotionSpec v1 (Zod + JSON Schema), deterministic `sample`, `cues`, analytic seeded particles, state-machine runner, simulation + event log, structured validation against a game capability's caps, adapter contract, RigSpec/editor bridge.
3. **Preset library v0**: gun fire, gun fire/reload/cock machine (ammo + chambered, slide lock, dry click, auto cock), hinged door, parametric gait generator (humanoid, quadruped, floating ghost), muzzle flash, explosion, fire, smoke, water splash. All fit Minecraft's caps at defaults.
4. **Minecraft lowering** as designer kind `motion` (preset or spec + part/trigger binding): display-entity interpolation segments, step snaps, particle births to vanilla particles, sound keys, brightness, explicit drops; Java runtime `Motions`/`MotionDef`, compiler hook, TS reference runtime, route words, service prompt part `MOTION PROPS`, request flag `assets.motion`, generated service bundle. Minecraft's motion capability lives in its asset profile.
5. **Headless preview**: software rasteriser + contact sheets. 10 sheets in `cyrus-research/motion-sheets/` (gun fire, last shot/reload/cock, door, explosion, fire, splash, muzzle flash, two gaits, light theme).
6. **Mockups** `cyrus-designs/v4-motion/`: `motion.html` (rig, state machine, simulate buttons, event log, frame viewport, timeline with state bands, tracks as played, particle / sound waveform / light / event lanes, key / export / checks tabs) and `presets.html` (filters, cards, knobs, Minecraft fit, the JSON Cyrus writes). Built from real core output (`scripts/cyrus/motion-mock-data.ts`). Shot dark, light, 390 px; looked at and fixed (crumb overflow, cramped timeline header, FSM edges, mag hidden under the floor, narrow view blank, light-theme flash washing out).
7. Docs section "Cyrus motion core", OWNER section, this report.

Reconciliation: Model Studio L2 had merged its own timeline core while I worked. Result: MotionSpec is the persisted model; the editor's ModelDoc clips convert both ways for every kind; I deleted my clock and use the editor clock (`ticksCrossed` steps the simulation); a parity test holds the editor transform sampler equal to `sample()` on all creature fixtures. Left as is (pre-existing, not mine): the L1 viewport's separate `PlaybackClock`.

## Ran
- Full Cyrus suite on node-2 after the merge: **1915/1915 pass** (`test/cyrus*.test.ts` + `modbuilder-pipeline`), full-project `tsc` clean, host-seam ratchet passes (no new Nxeon imports under lib/cyrus).
- New tests: core 29, presets 31, Minecraft 24, preview 6 (goldens: poses, particles, event logs, lowered programs, compiled mod hashes for 1.21.11 and 26.2, PNG sheets).
- **Real flights** (Test Flight, node-2, no client) on Paper 1.21.11 build 132 / JDK 21 and Paper 26.2 build 133 / JDK 25, with the final code: javac 0 warnings, reproducible jar, strict scan 0/0, **39/39 RCON checks + 7/7 log checks per lane**, boot 18.7 s / 10.4 s, peak RSS 900 / 877 MB, no leftovers. Checks include spawn, entity counts, NBT `transformation.left_rotation` / `scale` / `interpolation_duration` read back, `motion state` text equal to the TS twin (door hinge at 90 degrees), pistol 3 shots -> empty -> dry -> reload -> auto cock with ammo vars, fire effect, cap refusal, bad inputs, despawn. Log checks: after-durations equal the TS lowering (open 13 ticks, reload 34), shot and door sound cues. **Broken design refused** by TS validator, service bundle, service workspace check and compiler (hinge off-axis + past limit, 400 particles in one tick, foreign sound namespace, unknown part node) while the good file in the same workspace still passes. Record: `motion-flights-2026-10-10.json`.

## Not run / not verified
- No real Minecraft client: clicking props, smoothness of the client's interpolation (assumed linear / slerp, U), particle looks, sound sync were not seen.
- No AI generation: the prompt part and validator are unit-tested only; no paid eval.
- Held items do not animate from motion designs (item model states do that); no ability hook (owner decision, changes designer goldens).
- No three.js viewport integration of the simulator in the real studio (the mockup uses pre-rendered frames); no Sound Studio waveform snapping implemented (shown in mockup only).
- FiveM/RedM, Hytale, BetterModel creature lowering from MotionSpec: planned, not built. Catalog v2 kinds `motion`/`effect` not added (gating decision pending).

## Risks / notes
- `feature/cyrus-r20-designers2` (bosses, HUD) touches the same `gameplay/spec.ts` and `compile.ts` lines; the second to merge resolves small conflicts.
- Display-entity cost: caps 12 parts, 16 live props per mod; real-client FPS not measured.
- Cleanup when finished: `/tank/nxeon-build/tmp/cyrus-r21-motion` on node-2.

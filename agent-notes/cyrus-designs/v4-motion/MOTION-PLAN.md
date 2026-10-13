# Cyrus Motion Core: architecture (v4, 2026-10-10)

Owner decision: motion, animation and effects are FOUNDATIONAL and game-neutral. One data model describes a creature walk, a gun cock/fire/reload, a door on a hinge, an explosion, fire, smoke or a splash, and (later, not on Minecraft) a vehicle with wheels, doors, seats and a character getting in. Per-game details live only in adapters. Research and labels: `cyrus-research/R-motion-effects.md` (V = verified, U = unverified). Code: `lib/cyrus/motion/` (pure core) and `lib/cyrus/designer/motion/` (Minecraft lowering as a designer kind).

## 1. Data model: MotionSpec v1

```
MotionSpec { schemaVersion: 1, id, title?, rig: { nodes[] }, clips[], machines[], meta? }
```
- **Units:** 1 unit = one block = one metre. Rotation in degrees, Euler applied Z * Y * X about the node pivot (the Blockbench / RigSpec / Model Studio L2 convention, so poses agree across the studio).
- **Time:** integer ticks at the canonical 20 Hz. Keys may sit on fractional ticks; exporters resample (Minecraft 1 tick, Hytale fps, glTF seconds).
- **Rig nodes** (one concept for creature bones, gun parts and vehicle parts): `{ name, parent, kind, pivot, rest?, hinge?, wheel?, seat?, proxy? }`. Kinds: `bone`, `part`, `socket`, `hinge {axis, min, max}`, `wheel {axle, radius, steer?}`, `seat`, `emitter`. Names `^[a-z][a-z0-9_]{0,23}$` (RigSpec's BONE_RE), one root. `proxy` is an optional preview box (size, offset, colour) for the simulator; real geometry comes from Model Studio or the game binding.
- **Clips:** `{ name, length (ticks), loop: once | loop | hold | pingpong, tracks[] }`.

### Track kinds (five)
| Kind | Fields | Neutral meaning |
|---|---|---|
| `transform` | node, channel pos/rot/scale, `keys[{t, v, ease}]` or `wave{amp, offset, cycles, phase}` | node offset from rest; waves are the parametric gait primitive |
| `particle` | node, at, duration (0 = burst), `effect` (catalog ref `effect:<id>`) or inline emitter (shape, burst/rate, lifetime, speed, spread, gravity, size, colour ramp, sprite), seed | emitter attached to a node |
| `sound` | at, `sound` (catalog `sound:<id>` or namespaced key), gain, pitch, node? | cue at a tick |
| `material` | node, channel emissive / opacity / tint / frame / brightness, keys (step or linear) | light flash, glow, texture frame |
| `event` | at, name, optional `attach {child, socket}` / `detach {child}` | named marker; machine input; attach = reparent (character into a seat) |

Ease: `linear`, `step`, `in`, `out`, `inout`, `smooth` (smoothstep, = RigSpec "smooth").

## 2. State machines
`Machine { name, initial, vars[{name, init, min, max}], states[{name, clip?, onEnter[], after?{to, ticks?}}], transitions[{from | "*", on, to, guard?, minTicks?}] }`. Actions: `set`, `add` (clamped to the var range), `emit` (raise an event this tick). Guards compare one integer var (`lt le eq ne ge gt`). `after` without ticks = the end of a `once` clip.

Example gun: idle -(fire, ammo > 0)-> fire (onEnter ammo -1; after -> idle); idle -(fire, ammo = 0)-> dry; * -(reload, ammo < 6)-> reload (after -> idle, onEnter ammo = 6). Door: closed -(toggle)-> opening (after -> open) -(toggle)-> closing (after -> closed); `minTicks` stops spam.

Triggers come from outside: the ability graph (`trigger_motion` in a later step), a click on the prop, a command, or the studio's simulation controls.

## 3. Sampler and determinism
- `sample(spec, clip, tick) -> Pose` (per node pos/rot/scale + material values) is PURE: no clock, no `Math.random`, results rounded to 1e-4 and -0 removed, so golden tests are byte-stable.
- `cues(spec, clip, from, to)` returns the sound / particle-start / event cues in the half-open window (from, to], so a step of N ticks never fires a cue twice or skips one, including across loop wraps.
- Particles are analytic: particle i of an emitter has a seeded (mulberry32(seed, i)) direction, speed and lifetime; its position at age a is `origin + v a + g a^2 / 2`. Any frame can be rendered without integrating the ones before it (scrubbing and contact sheets are exact).
- `runMachine(spec, machine, inputs, ticks)`: inside one tick, inputs apply in array order, then `emit`s, then `after`; at most 8 transitions per tick (a cycle is cut and reported); the new state's clip starts at tick 0 of the transition tick. Same inputs = same frames, always.

## 4. Clock / simulation contract with the viewport
There is ONE playback clock: the Model Studio timeline clock (`lib/cyrus/modelstudio/editor/timeline/clock.ts`: play, pause, scrub, loop, speed, `clockTick(dt)`; no timers inside). The L1 viewport feeds it elapsed seconds from its own `requestAnimationFrame`; the motion simulation steps every whole tick crossed (`ticksCrossed(prev, next)`, 20 per second) and the renderer draws `sample()` at the fractional tick for smooth playback. ONE persisted animation model: MotionSpec. ModelDoc v1 (the L2 editor document) stores the creature's transform tracks and clip events, a projection that converts losslessly both ways (`fromLegacyClipFull` / `toLegacyClip`); the editor's extension kinds (sound cue, particle burst, light, material, state) have their home in the MotionSpec, and the editor's transform sampler is held equal to `sample()` by a parity test. three.js maps Pose onto object transforms; Rapier only for a vehicle dynamics preview, never exported truth.

## 5. Exporter / adapter contract
Each adapter declares a `motion` capability in its AssetProfile:
```
MotionCapability { tickRate, trackKinds: {transform|particle|sound|material|event: native|approx|none},
  nodeKinds[], materialChannels[], attach: boolean, interpolation: "linear-segments"|"keyframes"|"none",
  caps: { nodes, clips, tracks, keysPerTrack, durationTicks, particlesPerTick, particlesPerClip,
          liveEntities, soundsPerClip, machines, states }, delivery, maturity }
```
`lower(spec, capability, ctx) -> { ok, program | null, warnings[], dropped[{path, reason}] }`. Unsupported tracks degrade with an explicit `dropped` row; nothing is silently lost. `validateMotion(spec, caps)` gives structured issues `{path, code, severity, message}` against the profile caps before any lowering.

**Minecraft (first slice):** each rig part = one `item_display` or `block_display` at the instance origin (no passenger chains); the lowering bakes the node hierarchy into each part's world transform per tick and emits interpolation SEGMENTS `{start, duration, translation, leftRotation, scale}` (V: Paper `setTransformation`, `setInterpolationDelay`, `setInterpolationDuration`; changes in one tick count as one). Client interpolation is linear between segments (U), so easing is chained short segments within an error budget (0.01 block, 1 degree), max 90 degrees per segment; `step` = duration 0. Sound cues play by key at their tick (`sound:<id>` resolved through the Sound Library), particle tracks map to data-free vanilla particles within the designer BUDGET (512 per activation, 64 per burst), `material.brightness` lowers to display brightness, other material channels and `attach` are dropped with reasons. Clicks reach the machine through an `interaction` entity. Parts are non-persistent (gone on restart; nothing leaks into worlds).

## 6. Catalog presets
Presets are MotionSpecs with kinds `motion` (clips, rigs, machines: gun_fire, gun_reload, door_hinge, creature gait) and `effect` (particle/sound/light bundles: muzzle_flash, explosion, fire, smoke, water_splash). Each entry carries per-game support (computed by dry-running every adapter's `lower`), provenance `cyrus-authored`, licence `nxeon-original`, parameters with ranges. The catalog v2 `CATALOG_KINDS` gets `motion`/`effect` only after the owner's gating decision (section 7), so v0 presets live in `lib/cyrus/motion/presets` with the same entry shape.

## 7. Plan-tier gating proposal (owner decides)
| Option | Presets + AI composition | Custom motion editing (timeline) | Effects |
|---|---|---|---|
| A (recommended) | every paid plan, like designer components (not asset generation) | Model plan (All) | every paid plan |
| B | Saka+ | All | Saka+ |
| C | everything All | All | All |
Keep / install / export never gated (unchanged rule).

## 8. Studio integration
- **Texture Studio:** `material.frame` drives animated textures (`.mcmeta` frametime/frames, V) and decal swaps; `emissive` previews glow; onion skin shows neighbouring ticks.
- **Sound Studio:** `sound` cues reference library ids; the timeline draws the waveform under the cue lane with markers at ticks; "snap to transient" moves a cue to the nearest onset (peaks from the sound library); cue-to-visual error on Minecraft is about 1 tick plus jitter (U), so cues snap to whole ticks.
- **Model Studio:** L1 viewport owns the clock; L2 timeline edits tracks; rig nodes are its bones plus socket/hinge/wheel/seat metadata.

## 9. AI generation strategy
1. **Pick a preset** (`{ use: "motion:gun_reload", params: { magDrop: 0.4 } }`) - cheapest and most reliable.
2. **Parametric generators** with typed knobs: gait (archetype biped/quadruped/flyer, stride, bob, swing, phase), hinge (axis, angle, ticks, ease, bounce), recoil (kick, return ticks), slide cycle, wheel spin (later).
3. **Full MotionSpec** only for simple mechanical motion; the validator's issues go back for one repair round.
4. **Human fix** in the timeline (nudge keys, snap cues to the waveform); every edit is a revision.
Claude emits JSON only (no code); a mod file wraps it as a design (`assets/designs/<id>.json`, `"kind": "motion"`) with a game binding. Not reliable and not promised: mocap-quality humans, free-form creature acting, frame-accurate audio sync by ear.

## 10. Per-game roadmap
| Game | Lowering | Status |
|---|---|---|
| Minecraft Java | display-entity segments, vanilla particles, sound keys, item model states; creature clips to BetterModel `.bbmodel` (26.x) | slice 1 now (gun + door) |
| FiveM / RedM | pick existing anim dict/clip names, ptfx presets, door/bone natives; vehicles + seat attach | next; no authoring of new `.ycd` |
| Hytale | `.blockyanim` keyframes once a real file is diffed | later (schema U) |
| Source / Unity games | QC sequences / AnimationClips via Windows tools | later |
| Unreal (Palworld, ARK) | not deliverable server-side | no-go |

## 11. Risks
| Risk | Mitigation |
|---|---|
| Display interpolation semantics differ from our assumption (U) | real-client check; segment tolerance tunable; flights check the server-side values |
| Display-entity cost (MC-276285) | caps: 12 parts per rig, 16 live instances per mod, shadow 0, view range capped |
| Two timeline models (r17 EClip vs MotionSpec) | adapter now; r17 adopts MotionSpec types at merge |
| Particle look differs per game | presets carry per-game mappings and a "preview is approximate" label |
| AI emits invalid timing | caps + validator + preview before export; presets first |
| Vehicle scope creep on Minecraft | core expresses vehicles; MC adapter drops `attach` and wheels with reasons |

## 12. Owner decisions
1. Gating option A, B or C (section 7).
2. Add `motion` / `effect` to the catalog v2 kinds now, or after the first real-client test?
3. Ability hook: let an item ability fire a motion event (`trigger_motion`); this changes the generated Ability class and every designer golden hash. Approve for the next designer release?
4. A standing tester with a real client to confirm interpolation smoothness and particle looks on 1.21.11 and 26.2.
5. FiveM/RedM as the first vehicle-capable target: confirm order.

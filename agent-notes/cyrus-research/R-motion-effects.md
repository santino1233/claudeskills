# R: Motion, animation and effects (research, 2026-10-10)

Labels: V = verified (url, fetched 2026-10-10); U = unverified (prior knowledge or inference, check before building). Scope correction applied: vehicles are NOT a Minecraft target; they are a requirement on the neutral core and a row for FiveM/RedM.

## 1. Minecraft Java from a vanilla client (server-driven)

| Capability | Finding | Label |
|---|---|---|
| Display entities (item/block/text) | Transformation (translation, rotation, scale); fields `start_interpolation`, `interpolation_duration`, `teleport_duration`; changes within one tick count as one; duration 0 discards previous values. Pivot differs per type | V minecraft.wiki/w/Display |
| Paper API | `setTransformation`, `setInterpolationDuration`, `setInterpolationDelay`, `setTeleportDuration` (valid 0-59), `setViewRange`, `setBrightness`, `setBillboard`, shadow radius/strength | V jd.papermc.io/paper/26.1.2/org/bukkit/entity/Display.html |
| Door/gun-part animation | Prop = display entity, tween between two transforms with duration N ticks. Resolution is 1 tick (50 ms); linear interpolation only; easing = chained segments | V (ticks) + U (linear only) |
| Perf hazard | Many item_display passengers hurt MSPT/FPS; large `shadow_radius` kills client FPS | V bugs-legacy.mojang.com/browse/MC-276285 (search snippet) |
| Safe budgets | No official numbers. Use our own caps: 32 bones/creature, 4 creatures (already in creature/spec.ts), 512 particles per action, 32 entities per action (designer BUDGET). Keep shadow radius 0 | U (repo values V locally) |
| Particles | `/particle` renders within 32 blocks (force mode larger); some types need data (dust colour, item, block, vibration, trail). No documented hard count cap | V minecraft.wiki/w/Particles_(Java_Edition) |
| Particle textures | Resource packs can re-texture EXISTING particles (`assets/minecraft/particles/*.json`); new particle types need a mod; core-shader hacks exist (ps-dps/mc-Charcoal) but are fragile across versions | V wiki (json) / U (no new types) |
| Texture animation | `.mcmeta` `frametime`, `frames`, `interpolate`; 1.21.11 moved to GPU sprite animation | V minecraft.wiki/w/Resource_pack |
| Item model states | `items/*.json` (1.21.4+): condition, select, range_dispatch on custom_model_data (floats/strings from 1.21.5); gun = state swap, not free animation | V docs.nexomc.com item-model builder, jd.papermc.io CustomModelDataComponent |
| Shaders | Core/post shader folders exist in packs, format keeps changing (1.21.11 uniform rework). Real fluids, dynamic lights, real-time shadows: not without client mod/Iris | V (folders) / U (impossible list) |
| BetterModel | MIT, 1.21.4 to 26.3.x, Java 25+, Blockbench `.bbmodel`, keyframe animation, loop modes Loop/Once/Hold, Molang, IK, "script/sound/particle keyframes", hitboxes with mount/dismount, `tracker.animate("walk")`. Bone/keyframe limits and blending NOT documented | V github.com/toxicity188/BetterModel; mintlify.wiki/toxicity188/BetterModel/guides/creating-models |
| Sound sync | Server tick = 50 ms; client applies packets at end of tick, so cue-to-visual error is about 1 tick plus network jitter. Author cues in whole ticks | V (tick) / U (jitter) |
| Vehicles/rideables on Minecraft | OUT OF SCOPE (owner). Note only: Paper `PlayerInputEvent` (1.21.2+) and BetterModel hitbox mounting exist if ever needed | V jd.papermc.io PlayerInputEvent |

Version families: 1.21.x display/item-model features apply from 1.21.4 (items) and 1.19.4 (displays); animated BetterModel creatures are 26.x-first (master plan; BetterModel needs Java 25).

## 2. Browser simulation (three.js)

| Topic | Finding | Label |
|---|---|---|
| Runtime | `AnimationMixer`, `AnimationAction` (LoopOnce/Repeat/PingPong, `clampWhenFinished`, weight, `crossFadeTo`, `timeScale`), `finished`/`loop` events, tracks for number/vector/quaternion/colour/bool/string, morph targets via `.morphTargetInfluences[i]`, `makeClipAdditive` for layering | V threejs.org/docs AnimationMixer |
| Interchange | glTF 2.0 animations (TRS + morph weights). Fine for skeletal/prop clips; particles, sound cues, events are NOT in core glTF, so they live in the Cyrus sidecar | U |
| Humanoid retarget | three.js example `SkeletonUtils.retarget` with name-map; works only on shared bone naming. Entry/exit anims are authored per vehicle, not retargeted | U |
| Gun state machine | Explicit FSM in the Motion data: states idle/cock/fire/reload with `clip`, `onEnter` events (sound, particle, light flash), guarded transitions, timers in ticks; sim drives Mixer actions | design |
| Vehicle rig (requirement) | Hierarchy: chassis > wheels (spin about axle, steer yaw on front), doors (hinge: pivot + axis + limits), seats (socket nodes). Entry = character attach: reparent to seat socket after an `enter` clip along a path | design |

Libraries (licence from GitHub API 2026-10-10, V):

| Lib | Licence | Use |
|---|---|---|
| three.js | MIT | viewer, Mixer |
| Rapier (rapier.js / rapier) | Apache-2.0 | physics; WASM build is documented fully cross-platform deterministic if bodies are created in the same order and no `Math.sin/cos` feeds inputs (V rapier.rs determinism); `createVehicleController` raycast vehicle (V rapier.rs character_controller page) |
| cannon-es | MIT | simpler; last push 2024-01 (stale) |
| Jolt (JoltPhysics.js) | MIT | alternative |
| ammo.js | NOASSERTION (zlib in practice, U) | avoid |
| three.quarks | MIT | particles, JSON-serialisable effects, editor quarks.art (V github.com/Alchemist0823/three.quarks); seeded RNG not stated (U) |
| three-nebula | MIT | alternative particles |

Cheap deterministic effects: fire/smoke/explosion = few-layer sprite emitters with a seeded PRNG (own mulberry32, not Math.random), fixed 60 Hz step, curves over lifetime; water = scrolling-UV plane plus particle splashes (no fluid sim). Server-side preview renders: fixed-step sampler plus headless Chromium and a seeded clock; the clip sampler must be pure (time in, pose out) so screenshots are reproducible (U).

## 3. Per-game animation systems (go/no-go for AI generation)

| Game | Format / toolchain | Server can deliver? | AI gen | Verdict |
|---|---|---|---|---|
| Minecraft | display entities, `.mcmeta`, item states, BetterModel clips | Yes (pack + plugin) | Yes (parametric) | GO now |
| Hytale | `.blockyanim` (keyframes pos/rot/scale), attached via `CustomModelAnimation`; Blockbench Hytale plugin; JSON schema not published in what we read | Asset packs; plugin triggers (Takedown plugin exists) | Likely (JSON) once a real file is diffed | LATER (V hytalemodding.dev animated-block-textures, creating-block; schema U) |
| FiveM / RedM | anim dictionaries `.ycd` in `stream/`, played with `RequestAnimDict`+`TaskPlayAnim`; vehicle doors/bones, ptfx assets (`.ypt`), via natives (door natives and ptfx native names U) | Yes, `stream/` is server-streamed | Reuse existing dict/clip names = easy; authoring new ycd needs CodeWalker/Sollumz (no-licence / GPL) | GO as "pick from existing dictionaries + ptfx presets"; NO-GO for authoring new ycd (V docs.fivem.net TASK_PLAY_ANIM_ADVANCED; wiki.gtaconnected requestAnims; rest U) |
| Source / GMod | QC `$sequence`, SMD/DMX, studiomdl; PCF particles (V developer.valvesoftware.com) | Workshop `.gma` | Medium; compile needs Windows + game | LATER |
| Palworld / ARK (Unreal) | AnimSequence/Montage/Niagara cooked into pak; pak mods usually need each client to install; UE4SS mods not usable on dedicated servers (V indifferentbroccoli wiki, nexusmods) | Palworld no; ASA via CurseForge ID | Low (cook toolchain) | NO-GO |
| Unturned (Unity) | AnimationClips in master bundle via MasterBundleTool; gun clips Equip/Reload/Hammer/etc. (V docs.smartlydressedgames.com via search) | Workshop auto-download | Medium, needs Unity editor | LATER |

## 4. AI feasibility

| Reliable (Claude) | Not reliable |
|---|---|
| Parametric gaits (walk/run: phase, stride, bob, swing amplitudes per archetype), as already done by creature templates | Mocap-quality human motion, nuanced acting, retargeted dance |
| Mechanical motion: hinges, slides, recoil kicks, slide/bolt cycles, wheel spin, with eased keyframes | Free-form quadruped/creature gaits without a template |
| State machines and trigger wiring (events to sound/particle/light) | Frame-accurate timing by ear (needs human nudge against the waveform) |
| Particle presets by parameters (count, speed, spread, colour ramp, lifetime) | Photoreal fire/water |

Cheapest approach: preset library (kind `motion`/`effect`) + generators with a few typed knobs + AI picks/parameterises/composes + human fixes in the studio timeline. Always validate against caps and show a simulated preview before export (U, consistent with how designer/ and creature/ already work).

## 5. Recommended architecture

**Motion core (game-neutral, pure TS, Zod, like RigSpec/designer):** `MotionSpec v1 { clips[], machines[], rig?, caps }`.
- Track kinds: `transform` (target node, channel pos/rot/scale, keys with ease), `particle` (preset ref + params + emitter node + start/duration), `sound-cue` (sound id from Sound Studio, tick, gain/pitch), `light-material` (emissive/colour/opacity/texture-frame), `event` (named marker, state transition).
- Time in integer ticks at 20 Hz canonical, fractional allowed; exporters resample (Minecraft 1 tick, Hytale fps, Source/Unity per spec).
- Node targets are named rig nodes (`bone`, `socket`, `hinge{axis,limits}`, `wheel{axle}`), so vehicle rigs, gun parts and creature bones are one concept. Attach = `parent` change event (character into seat socket).
- State machine: states (clip, loop mode), transitions (event/guard/min-time), on-enter actions. Triggers come from the ability graph via a `play_effect` / `trigger_motion` action.
- Caps: duration, tracks, keys, particles, live entities, machine states (reuse designer BUDGET semantics).

**Simulator contract:** `sample(spec, state, t) -> Pose + FiredEvents[]` pure and deterministic; `Clock` API (play/pause/seek/scrub, tick rate) exposed by the Model Studio viewport (layers 1-2); three.js adapter maps Pose to Mixer/object transforms; physics (Rapier) only for vehicle dynamics preview, never part of exported truth.

**Exporter contract per game:** `capabilities(game) -> {trackKinds, maxEntities, tickRate, delivery}`; `lower(spec, caps) -> {artifacts, warnings, dropped[]}` so unsupported tracks degrade with an explicit report. Minecraft: transform tracks lower to display-entity interpolation segments, sound/particle cues to scheduler tasks (plugin, within budget), item states to `items/*.json`; creature clips lower to BetterModel `.bbmodel` animation (RigSpec becomes a subset). FiveM adapter later: clip refs to existing dict/name, ptfx refs, door natives.

**Catalog:** presets with kind `motion` / `effect`, per-game support flags, provenance, licence class; AI composes from presets first.

**Ties:** Texture Studio: `light-material` texture-frame track drives `.mcmeta` animated textures and decal swaps; onion-skin already planned. Sound Studio: `sound-cue` references library sound ids; timeline shows waveform with markers snapping to ticks. Model Studio layers 1-2 provide clock and timeline UI; Motion core is the data model both edit.

**Cheapest first slice (end to end):** one item with a gun-state FSM (idle/fire/reload) plus a door prop hinge, in Minecraft display entities + item_model states: spec -> sampler -> three.js preview with scrubber and event log -> exporter emitting plugin-driven display-entity tween + sound cue + `spawn_particles` within existing budgets -> verify on a real 1.21.x and 26.x server. Defer vehicles, BetterModel unification, and non-Minecraft adapters until the core schema survives this slice.

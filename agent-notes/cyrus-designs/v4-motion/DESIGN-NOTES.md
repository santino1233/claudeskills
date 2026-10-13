# Cyrus Motion Studio v4: design notes (mockups, 2026-10-10)

Files (self-contained, no network): `motion.html` (a: motion panel + timeline + simulation controls in the studio shell; `?t=<tick>&tab=key|export|checks&row=<node.channel>`), `presets.html` (b: preset browser; `?kind=motion|effect|generator&sel=<id>&fit=1`). Sources `src/` (v3 kit + `mo.css`, `mo.js`), build `tools/build.py`, shots `tools/run-shots.sh` (node-2) -> `shots/` (dark, light, 390 px narrow). Plan: `MOTION-PLAN.md`.

## Real data, not drawings
Every frame, state, cue, log line, cap meter and "left out on Minecraft" row comes from the motion core (`scripts/cyrus/motion-mock-data.ts` in feature/cyrus-r21-motion): the gun state machine run with scripted inputs, the software preview renderer, `validateMotion` against Minecraft's motion capability and the Minecraft lowering's dropped list. The "What changed" list on the narrow approve view is illustrative.

## Principles
- Same shell as v2/v3: the studio switch gains **Motion** next to Texture / Sound / Model.
- One accent (violet) for selection and primary; cyan only for "now" (playhead, live state); amber/green/red for checks. The light-step lane uses the warn tone because it is a light level.
- Simulation and editing share one timeline: the machine row shows state bands over the run, tracks are drawn where they played, sound cues sit on a waveform lane (Sound Studio), scripted inputs tick the machine row.
- Per-game truth: the Export tab says what Minecraft approximates (segments, vanilla particles), what it leaves out (muzzle light), and that client smoothness is not verified.
- Narrow (390 px): read-only approve card for a motion; a compact preset list.

## Questions for the owner
1. Gating option A/B/C (MOTION-PLAN section 7).
2. Does Motion get its own studio tab (shown) or live inside Model Studio as a timeline mode?
3. Should the preset browser be part of the shared asset library (catalog kinds motion/effect) or stay a Motion-only view?

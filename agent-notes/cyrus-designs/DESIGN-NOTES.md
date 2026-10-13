# Cyrus Texture and Sound Studios: design notes (mockups, 2026-10-10)

Files: `texture-studio.html`, `sound-studio.html`, `mod-assets.html`, `locked-states.html` (self-contained; sources `src/`, build `tools/build.py`, shots `shots/`).

## Principles
- **Polish in place, no new look.** Tokens, type and chrome are copied from the v5 handoff (`app/dashboard/cyrus/studio.css`): deep space `#05030b`, glass panels, Inter + Space Grotesk + JetBrains Mono, the TopBar crumbs, the conic-rim prompt dock, the inspector tab anatomy, the handoff's 1.7-stroke icon set. The asset entry is a new **Assets** tab in the existing inspector, over the network map.
- **One accent.** Violet is the only accent. Cyan only means "live": the playhead, the selected layer, the compare splitter. Green, amber and red only mean pass, warn and fail.
- **Truth first.** The mockups run the repo's real code (bundled from `lib/cyrus/textures` and `lib/cyrus/sound`). Quality panels show real `tq-1`/`sq-1` results (the Glock genuinely warns on `palette_size` 49; gunshots warn after peak limiting). Library rows are real manifest metadata. The only stand-in is library *audio* (it stays on the render host), and the page says so.
- **AI never overwrites**: every Cyrus edit is a candidate to compare, apply in part, or reject.
- **Real light mode**: white glass, inked colours; the portal rail stays a dark island, as in the portal.

## Mapping to backend data
| Screen | Data |
|---|---|
| Texture canvas, layers | `TextureSpec` (generated base, locked) + a raster Paint layer on top. Accepting a candidate swaps the spec. The PNG is a build artifact. |
| Palette, ramps | `spec.palette` (max 24, `MAX_PALETTE`). Ramps are UI groupings; "New ramp" generates 5 hue-shifted shades. |
| Style DNA | The prompt's CUSTOM TEXTURES rules (one outline colour, top-left light, 3-5 shade ramps, no noise or gradients, clear background); compliance is measured with the `noise` and `outline` checks. |
| Checks | `textureQuality()`: `transparency`, `palette_size`, `contrast`, `noise`, `outline`, `vanilla_lookalike` (`not_run`). `soundQuality()`: `format`, `true_peak`, `loudness`, `audible`, `silence_ratio`, `dc_offset`, `duration`, plus a subtitle row. |
| Sound events | `SoundSpec`: sets → events (`role`, `category`, required `subtitle`) → 1-4 weighted variants → up to 4 layers (`lib:` / `synth:` / `silence`, with gain, pitch, start, trim, fades) + processing. The key is `nx_<8>:<set>.<event>`. |
| Meters | `measure()` + `ROLE_PROFILE` bands; auto gain and peak limiting come from `renderVariant()`. |
| Pack status | R0/R1 sync states: hosted, delivery off (`CYRUS_MANAGED_PLUGINS_REAL` off), unhosted; `required: false`; the Bedrock line from `assetLines`. |
| Locks | `canAsset(plan, kind, op)`, ported 1:1. Only create/edit is gated. The copy is the gate's own `reason` strings and the `downgradeSpecAssets` notice. |
| History | Asset revisions (spec + render + quality per revision). Restoring makes a new revision. |

## Component inventory (React)
- `StudioShell({studio, mod, plan})`: TopBar crumbs, Texture/Sound switch, token chip.
- `PixelCanvas({raster, zoom, grid, mirror, backdrop, tool, selection, compare})`, `ToolRail({tool, mirror, grid, color})`, `CompareBar({mode: split|onion|diff|after})`.
- `LayerList({layers, active, onToggle})`, `EditSteps({steps, at, onJump})`.
- `PaletteStrip({palette, ramps, color, usedCount})`, `RampGenerator({from})`, `StyleDnaStrip({rules, follows})`.
- `LivePreview({raster, mode: hotbar|hand|tile, bg})`.
- `CandidateCard({before, after, changes[], picks, qualityDelta, onAccept, onApplyPart, onApplyInSelection, onReject})`, shared by both studios.
- `QualityPanel({report})`, `CheckRow({id, status, value, limit, message})`.
- `EventList({sets, selected})`, `EventHeader({key, role, category, subtitle, onSubtitle})` (states: valid, missing).
- `VariantTabs({variants, candidate, weights})`, `WaveformEditor({pcm, layer, zoom, playhead, onTrim, onFade, onMove})`, `LayerLane({layer, solo, selected})`, `FxRow({processing})`.
- `LoudnessMeters({measure, role, gainDb, peakLimited})`, `LibraryBrowser({query, group, category, items})`, `SynthPicker({preset, params})`.
- `AssetsTab({mod, pack, textures, soundSets, plan})`, `PackStatusCard({state})`.
- `StudioLock({kind, decision})` (states: locked, plan_unknown, included), `PlanMatrix({plan})`, `DowngradeNotice({denials})`.

## Interaction details
- Texture tools: B, E, G, I, M, L, U; X = mirror, # = grid, +/- = zoom, Ctrl+wheel zooms, Esc clears the selection, Ctrl Z / Ctrl Shift Z undo and redo. Every stroke is one step. Partial apply works per change (checkboxes) or inside the selection.
- Sound: Space plays, L loops. Drag a layer's edges to trim, its top corners to fade, its body to move it. Sliders re-render live. A/B plays V1, then the candidate.
- Quality checks re-run on every edit.
- Narrow: read-only preview, checks, play, approve/reject (approve saves a revision).

## Accessibility
Focus rings everywhere; tools have `aria-pressed` + shortcut hints; subtitle is `aria-required` with inline error; status is never colour alone; AA-tuned v5 inks; reduced motion respected. Open: the canvas and the waveform need keyboard pixel and handle movement (arrow keys + Enter) and screen-reader summaries.

## Deliberately not included
3D model or block preview (the "In hand" view is a flat extrusion), mob-skin UV editing (shown as "later"), animation and `.mcmeta`, reference-image-to-spec, image-model or AI-audio providers, spectrum view and pitch-preserving stretch, Texture Library contents (no source exists yet), prices.

## Open questions for the owner
1. Plan naming: the gate says Free / Katara / Saka / **All models** (Yakko); the handoff says Sokka/Yako. Which spelling is final?
2. Token cost per asset edit: the dock shows no estimate because there is no measured price yet. Should it show one, and when?
3. Should packs be optional on join (current default) or required?
4. Library licence: the bundle licence forbids redistributing the files. Do processed sounds inside customers' packs comply (legal check)?
5. Should the mob-skin row stay visible as "later", or be hidden until it's built?
6. Should mobile approvals be allowed, or should mobile be view-only?
7. Inspector width: Assets needs about 560px versus 480 today. Widen just this tab, or open the studios full-page?

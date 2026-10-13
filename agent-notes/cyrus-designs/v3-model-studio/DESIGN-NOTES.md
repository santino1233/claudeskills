# Cyrus Model Studio v3: design notes (mockups, 2026-10-10)

Files (self-contained, no network): `viewport-paint.html` (a; `?mesh=1` = Layer 4 AI-mesh state), `model-editor.html` (b), `retexture.html` (c), `locked-states.html` (d; `?state=unknown|experimental`), `library.html` (e; `?tab=mine`), `prompt-flow.html` (f). Sources `src/` (v2 kit + `ms.css`, `ms.js`, `m3d.js`, `models.js`), build `tools/build.py`, shots `tools/run-shots.sh` (node-2, capped slice) → `shots/` (28 PNGs: dark, light and 390 px narrow for each). `ctl=0` hides the mockup bar.

## Principles
- **Same product as v2.** Shipped portal shell, Cyrus bar with a Texture / Sound / **Model** switch, glass panels, inspector tabs, prompt dock, narrow approve view.
- **Real geometry, not pictures.** `m3d.js` is a small deterministic canvas renderer standing in for three.js: orbit, picking, channel views, wireframe, affine-mapped textures. Painting writes real texels; the timeline scrubs a real pose; livery layer toggles rebuild every channel.
- **One accent.** Violet = selected/primary. Cyan = "now" (timeline playhead) only. Green/amber/red = pass/warn/fail. One exception: gizmo and axis triad use muted X/Y/Z red/green/blue, the 3D convention people expect.
- **Profile-aware truth.** Channels a game cannot ship are disabled with the reason (Minecraft Java item: albedo only). Delivery status per export target (FiveM "planned": the Windows worker is not built). Hytale shows its unverified format list. "Not run" is never a pass.
- **Legal class is visible.** Game-derived templates carry an amber badge, "kept for this session only, never shared", and ship delta-only. The library shows provenance, attribution and every check.

## Screens → data
| Screen | Data |
|---|---|
| a Paint | `ItemCuboidSpec` draft of `glock_9mm` (9 elements, 22.5° grip), `TextureDoc` paint layer (51 px "worn edge"), `ItemModelSpec` contexts (6) + states (idle/aim/reload; reload slides the slide back), checks incl. `grip_in_hand` |
| a `?mesh=1` | L4 output: LOD0-3 vs `meshBudget` (sample numbers), materials as lossless channel layers, cleanup checks, provenance `ai-mesh` |
| b Editor | RigSpec `banshee` (8 bones, 12 cubes, 5 clips), live budgets vs real caps, box-UV net on the 128 sheet with Auto-pack / Pinned, candidate bar with "1 overlap" (3-way merge) |
| c Retexture | glTF template stand-in (8,788 tris, 7 slots), body_paint layers with albedo/rough/metal values, UV island view, export picker with delivery status, policy row from the adapter legal block |
| d Locked | `canAsset(plan, "model", "edit")` strings verbatim; plan matrix with the proposed rows marked; Hytale maturity flag |
| e Library | automatic contribution: states pending checks / in the library / held for review / removed / not shared; lib-1 filters; `libraryEligible` exclusions |
| f Prompt flow | "AK-47 with fire stickers" → L2 + L1 route → ItemCuboidSpec + decal layer → deterministic render (sha) + look check → hand fixes as revisions → library "held" (real-weapon name) |

## Component inventory (React)
`ModelViewport`, `ChannelSwitch`, `ToolRail`, `GizmoLayer`, `InGamePreview`, `UvTexturePanel`, `Outliner`, `BudgetPanel`, `TransformFields`, `UvBoxField`, `Timeline`, `CandidateBar`, `MaterialSlots`, `ChannelLayerList`, `UvIslandView`, `ExportTargets`, `LegalClassBadge`, `PolicyCard`, `PolyBudget`, `LibraryGrid`, `LibraryDetail`, `ContributionTable`, `LibraryStateBadge`, `PromptFlow`; reuse `StudioLock` and `PlanMatrix`.

## Interaction details
- Left drag on the model = tool (paint/select); right drag or empty space = orbit; wheel = zoom. B/E/G/I paint tools; Q/W/E/R/P select/move/rotate/resize/pivot; X mirror; Ctrl Z / Ctrl Shift Z.
- Every stroke, drag, key or accepted candidate is one undo step; drafts autosave; "Save revision" is explicit.
- Narrow: turntable, what changed, checks, Approve / Reject; locked plans get view-only with no approve.

## Honesty notes
Sample content is labelled; poly counts, look-check scores and filter results are illustrative. The mockup renderer is not the production renderer (three.js) and the lantern proxy is lower-poly than its LOD1 readout. Gun display transforms, element rotation rules per version, everything Hytale, RAGE normal convention and every AI quality claim are unverified.

## Questions for the owner
1. **Plan:** Model Studio at All models (matches today's gate), or paint-only for Saka?
2. **Library access:** you said "usable by anyone"; the gate today treats "Use in project" as asset creation (All models for models). Open it to every plan, or keep browse-open / use-gated?
3. **Library removals:** when an asset is removed after a report, do mods already using it keep it?
4. **Real-weapon names** (AK-47, Glock): hold for review in the library (proposed) and allow freely in private mods?
5. **Terms of Service:** the automatic licence grant needs a lawyer's wording; also AI-output copyright per region. Who drafts it?
6. **Uploads gap:** `libraryEligible` lets user uploads through (`source: "user"`). Confirm they must be excluded (I think yes) so the code gets an `uploaded` source.
7. **L4 spend:** budget for the paid quality eval, a GPU worker, and Meshy/Tripo trials?
8. **Hytale:** build the emitter now behind the experimental flag, or wait for a real client to test against?
9. **Retexture templates:** session-only (proposed) is safest but means re-attaching the file each time. Acceptable?
10. Gizmo axis colours as the one accent exception: OK?

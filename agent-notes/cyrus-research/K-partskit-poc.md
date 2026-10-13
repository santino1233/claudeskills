# K: Parametric template + parts kit PoC (Cyrus L4, follow-up to I-blender-poc.md)

2026-10-10, node-2, same sandbox as PoC 1 (Blender 5.2.2, systemd-run, no network, user nobody, read-only fs, build lock). No sub-agents, no paid APIs, no repo touched. Files: `blender-poc/partkit/` (renders `<prompt>-r<N>-{side,3q,top,sheet}.png`, `<prompt>-final-sheet.png`, glbs in `out/`, sources in `src/`).

## What was built (VERIFIED, runs)
- `pk_geo.py` closed bmesh primitives (box/cylinder/rod/prism), bevel, per-face material slots, smooth+sharp-edge shading.
- `pk_parts.py` parts kit: 4 receivers (ak_stamped, modern_slab, smg_boxy, bullpup_shell), 4 grips, 3 magazines (curved, straight_box, drum), 6 stocks (fixed_wood, fixed_poly, folding_wire, folding_strut, bullpup_integral, none), 5 handguards (wood_ak, rail_quad, slim_poly, ribbed_shroud, none), 4 barrel profiles, 4 muzzle devices, gas tube, 4 sight types, 6 glow-strip placements, 7 palette slots.
- `pk_rifle.py` template: JSON spec in, 7-8 named objects out (receiver, grip, magazine, stock, handguard, barrel, sights, trim), UVs via smart_project, glb. Bad enum values raise an error naming the allowed values. Untested variants: drum, rail_quad, modern_slab, folding_strut, folded stock, fixed_poly.
- 439 lines / 28 KB. The model-facing "spec card" is 960 chars (about 300 tokens, cacheable).

## Results (3 prompts, 2 rounds each, only the JSON changed)
| | AK-style | Bullpup sci-fi + glow | SMG, folding stock |
|---|---|---|---|
| JSON size per round | 340 / 430 B (~110-140 tok) | 520 / 570 B | 430 / 470 B |
| Rounds | 2 | 2 | 2 |
| Tokens, session counter delta (my output + tool results, incl. my reasoning) | 3.0k | 5.8k (1.5k lost to a tool timeout) | 5.2k |
| + image reads (est. 1.1k per sheet, UNVERIFIED) | +2.2k | +2.2k | +2.2k |
| Total est. | ~5.2k | ~8.0k | ~7.4k |
| Lean est. (JSON 150 + card 300 cached + stats 350 + image 1.1k per round) | ~3.8k | ~3.8k | ~3.8k |
| Wall | ~28 s per round (23 s Cycles render; geometry under 1 s) | same | same |
| Tris | 1,452 | 948 | 1,412 |
| Non-manifold edges (per object) | 0 | 0 | 0 |
| UV on all objects | yes (7/7) | yes (8/8) | yes (7/7) |
| glTF validator | 0 errors, 0 warnings | 0/0 | 0/0 |
| Quality vs intent (my judgement from renders) | **7/10** | **6.5/10** | **7/10** |

PoC 1 AK for comparison: 6.5/10, 4 rounds, ~15-20k tokens, 2,732 tris.

Adjustments made after looking: AK r1 to r2 fixed a near-black receiver that hid detail (palette) and tapered the barrel. Bullpup r1 to r2 fixed a plain white slab (palette), added more glow strips. SMG r1 to r2 fixed monochrome low contrast. All three fixes were palette or minor parameters. None changed the silhouette.

Mesh caveat (VERIFIED): "manifold" is per closed shell. Primitives overlap and are not unioned (bullpup receiver has 18 shells, AK barrel 6), same as PoC 1. All three are under 10k tris (6-15% of budget), so there is room for more detail.

## What the template could NOT express
Contoured bullpup stock/cheek weld (stock is a slab plus pad); sight position and optic/rail layout (fixed anchors, red dot reads as a block); organic grips and ergonomics; folded-stock state was not tested; wear, damage, normal maps and textures (flat colours only); any non-rifle class (pistol, shotgun, bolt-action, belt-fed, launcher); underbarrel, bipod, light, scope; per-part offsets; asymmetric left/right features.

## Cost and break-even
| | Tokens | Time |
|---|---|---|
| One-time template + kit build (counter, 68.7k total incl. ~6k reading PoC 1; ~60k net) | ~60-65k | ~10 min agent wall (16:39 to 16:48, 3 sandbox runs for bug fixes); a human would need roughly 4-6 h (UNVERIFIED) |
| From scratch per rifle (PoC 1, fixed prelude) | 15-20k | 4 rounds |
| Template per rifle, measured | 5-8k | 2 rounds |
| Saving per prompt | ~10-14k measured, ~12-16k on lean est. | |

Break-even is about **5-6 prompts** if every prompt fits the template (60k / ~11k), about 4 on the lean estimate, and about **10-12 prompts at a 50% fit rate** (misfits fall back to the next rung). Each new object class (pistol, vehicle, crate) needs its own template; I would guess 30-40k for the second (geo layer reused, UNVERIFIED).

## Verdict on the hypothesis
- Token cut: **2.5-3x measured, about 5x on the lean estimate**. The 5-10x target is not reached or proven. One-round success would approach 8-10x (about 2k) but this PoC never got a one-round pass: first JSONs were all palette-weak.
- Quality: equal or slightly better (7 / 6.5 / 7 vs 6.5), more consistent scale, UVs and part names by construction.
- Risk removed: the model emits data only, no executable code, so the static-rejection problem from PoC 1 largely disappears for this rung (UNVERIFIED in a real worker).
- Next: a vision step that picks palette automatically (the only fix needed every time); let the parts kit take part offsets in JSON; measure template-fit rate over 20+ real prompts; try parts-kit assembly rung (model writes a list of part calls) for misfits.

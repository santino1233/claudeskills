# BP: asset lane quality, 2026-10-14 (branch feature/cyrus-asset-quality, worktree /tank/dev-worktrees/cyrus-quality, from release/cyrus-rc8 916eb4fb20)

Scope: sound and texture lanes (and handgun-class items that use both). No paid calls, no deploys. Data: journals first1 (image 0.11, 65 builds), second1 (image 0.13, 38 builds), third1 (image 0.15; only plain rows had finished when this was written, 0 asset rows) and the per-build records on VM 88001 (254 ev-* builds, build.json + live-assets.json read over ssh).

## 0. What the data says (read this first)

- The repair loop is NOT where the asset lanes lose money any more. Succeeded sound+texture builds: first1 25 builds, $11.3, repair turns $1.64 (14%); second1 16 builds, $7.8, repair turns $0.21 (2.7%). Of second1's $0.21, only ONE turn ($0.057, shop_counter_panel) was caused by an asset check. The sound lane in second1 had zero asset-caused repairs (6 builds); its "5/8 first try" is 2 infra failures (ai_unavailable, subscription limit) + 1 plugin pre-check API repair (ambient-zone).
- The two "quality misses" (ast-handgun-sounds 0.5, ast-handgun-textured 0.7) are NOT about textures/sounds being unreferenced. Both built first try. The score comes from the in-process sound rubric: the 3-click reload scored `silence_ratio` 0.77 (fail) because the gaps between clicks counted as dead air, the gunshot read -0.73 dBTP (warn), and the dry click warned. Score = (pass + 0.5 warn) / graded = (1 + 0.5 + 0) / 3 = 0.5. Same shape on the revolver builds (second1 ast-handgun-textured: reload fail, shot warn). Fixed in the rubric and the renderer, not by lowering a threshold.
- What still costs money in these lanes is the first generate turn ($0.3-0.7) and plugin-side API repairs (pre-check: wrong imports, deprecated calls), neither of which is an asset problem.

## 1. Failure taxonomy (sound + texture lanes, non-infra builds)

Message text of the checker is not stored in the build record (only "Sound check found N problems"); classes below come from the repair-turn labels, the live-assets replay (first attempt re-run through the checker), the leftover warnings in the journals and the per-spec quality records.

| # | class | spec field / prompt section | checker message (shape) | first1 | second1 | repair $ first1 / second1 | status |
|---|---|---|---|---|---|---|---|
| S1 | sound key never played: key assembled at runtime (`NS + ":banshee." + kind`) or read from config | plugin code; SOUND section "must play each event" | `the plugin never plays "<ns>:<set>.<event>"` (soft) | 6 builds, 7 turns | 0 | $0.61 / 0 | removed in 0.13 by `keyReachable` (before this branch) |
| S2 | event longer than its role allows (ambient bed 5.12 s vs 4 s) | spec `events[].variants[].layers[].length/start`; SOUND "lengths include tails" | `events[0].variants[2] is about 5.12 s; a ambient sound may be at most 4 s` | 1 (nether_calm; replayed) | 0 | inside S1 turn | removed in 0.13 (trim normaliser); replay confirmed |
| S3 | multi-click reload / double click scored as dead air | rubric `silence_ratio` (measure.ts); SOUND section had no rhythm rule | `silence_ratio` 0.62-0.81 (fail above 0.6) | 3 events (handgun, revolver x2) | 3 events (handgun, revolver) | no repair (not enforced in the service), quality 0.5-0.83 | fixed here: dead air = silent stretches of 0.5 s or more (sq-2) + prompt rule |
| S4 | gunshot true peak -0.7 dBTP (limiter is sample-peak) | render chain (render.ts) | `true_peak` warn, limit -1 dBTP | 3 events | 3 events | none | fixed here: true-peak guard (sr-2) |
| S5 | short transient cannot reach role loudness (shot -17.6..-19 LUFS vs -15) | rubric `loudness` | `loudness` warn | 2 events | 2 events | none | fixed here: peak-limited at the ceiling passes (sq-2); quiet sounds still warn/fail |
| S6 | dc offset 0.003 on a death growl | synth preset | `dc_offset` warn | 1 | 0 | none | left (honest warn, 1 event) |
| T1 | palette over budget / grain from `noise` or `gradient` on a panel | spec `ops[noise|gradient|shade]`, palette; TEXTURE "art direction" | `palette_size: 86 distinct colours ...`, `noise: grainy ...` | 3 turns (texture/asset checks, mixed with plugin problems) | 1 turn (shop_counter_panel fail) + void_shard warn (34 col, 0.23) | $0.29 / $0.057 | fixed here: normaliser ladder (cap noise, drop noise, gradient -> bands, soften shade); replay: both fixtures clean |
| T2 | transparency warn: full-bleed panel (coverage 0.98) or template (0.86) | spec ops (fill) | `transparency` warn | 0 | 2 | none | left (a GUI panel is full-bleed by design; warn only) |
| T3 | texture lane planned, nothing shipped: prompt never asks for a look (cov-cosmetics, cov-backpacks) | eval prompt, not the model | `nothing shipped for textures` | 2 of 18 | not in set | $0 | fixed here: cov-backpacks prompt asks for the item look (cosmetics fixed earlier) |
| T4 | texture reached only through item model states or config keys flagged "never references" | cross-check in textures.js | `the plugin never references "<name>"` (soft) | none seen | none seen | n/a | guard added: state texture counts when its model name is reachable; config keys already counted |
| T5 | spec value slips: name != file, "#abc", capital palette keys, size 24, coordinates out of range | spec | `name must be ...`, `palette x must be #rrggbb`, `size must be 16, 32 or 64` | none seen (hard checks returned before quality) | none seen | n/a | guard added: normaliser (negative tests for guesses it must not make) |

Non-asset repairs inside asset-lane builds (not fixed here, listed for ranking): pre-check API mistakes first1 8 turns $0.51 + second1 2 turns $0.16 (wrong imports such as `org.bukkit.block.Action`, `ItemMeta`, `persistent.*`; autofix already rewrites 4 of these kinds), compiler errors first1 3 turns $0.24.

## 2. Ranked by saved spend (estimates are labelled; measured numbers are from the journals)

1. Pre-check API mistakes (non-asset, $0.66 over 41 builds): next candidate, a javap-backed import autofix list; out of scope here.
2. S1/S2 sound repair: $0.61 measured in first1, already gone in 0.13 (second1: 0). No further saving.
3. T1 normaliser: measured repair $0.06-0.11 per hit, 3 hits in 28 texture builds -> ESTIMATE $0.01 per texture build (2% of $0.51) and +1 first-try per ~14 texture builds; it also removes the 0.5 quality score a single warn produces.
4. S3-S5 rubric/render: no spend, but it moves the honest quality of every gun/click sound set from 0.5-0.83 to 1.0 (replayed on the 25 stored sound specs: second1 specs have 0 warn/fail events; first1 handgun reload with 1 s+ gaps still fails, correctly).
5. Targeted one-file repair: ESTIMATE below.

## 3. Targeted single-file repair (cost item 4)

Baseline (measured, repair-asset stages, 10 turns-sets in first1/second1): 3-9 model turns, 148k-400k cached input tokens, $0.057-0.168 each; the model always spends one Read turn on the spec file first. `assetRound` now marks a repair `single` when every hard problem names one `assets/<kind>/<name>.json`, no soft plugin cross-check is open and the file is at most 6000 bytes: the prompt carries the file and says "Fix ONLY <file>, one Edit", and `single` takes the cheap repair model when routing allows (never under an eval override).
ESTIMATE: removes the Read turn (1 of 3-4 turns, about 70-75k cached input tokens per turn avoided = 25-30% of a $0.06-0.10 repair, so $0.015-0.03 per single-file repair); with the cheap tier in production routing, an additional ~60% on the remaining turns (price ratio estimate, not measured). Applies to roughly one repair in three of the asset-caused ones, so the aggregate is small (cents per hundred builds); it matters for latency (fewer turns) more than spend. Whole-spec rewrite was not observed in the records: every repair-asset used Edit (Edit 1-5 per repair, Write 0).

## 4. Plan-screen estimate (lib/cyrus/planner/estimate.ts MEASURED_SAKA)

| group | before (first1) | now | basis |
|---|---|---|---|
| texture | n16 p50 0.42, p80 0.66, p90 0.76 | n27 p50 0.46, p80 0.685, p90 0.735 | first1+second1 succeeded builds |
| sound | n7 p50 0.57, p80 0.61, p90 0.62 | n6 p50 0.39, p80 0.52, p90 0.61 | second1 only (repair-dominated first1 no longer representative) |

third1 had no finished asset rows at writing time; re-run `scripts/cyrus/eval-journal-stats.ts` when it has (the constants carry the instruction). Designer left at first1 numbers (second1 downgraded most designer builds to plain plugins; strict design mode has no journal yet).

## 5. Eval set

16 new prompts in services/modbuilder/eval/sets/assets.jsonl (8 `snd-*`, 8 `tex-*`), each with `failureShape` and `expectAssets` (minimum shipped, minimum quality 0.9, first attempt), listed under `assetQuality` in matrix.json (not in `core`). `assetExpectationMisses` reports unmet expectations in the scored record (`expectMiss`), informational only: no stage bar moved. unsafe.jsonl untouched.

## 6. Unverified

No paid eval of any of this; the normalisers are replayed on stored first attempts only (2 textures, 1 sound had a real defect; the rest were already clean). Needs a modbuilder image redeploy (prompts.js, server.js, sounds.js, textures.js) and a web release for the rubric/render/estimate (measure.ts, render.ts, runner.bundle.cjs, estimate.ts, score.ts).

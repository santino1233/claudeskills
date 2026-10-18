# EA: Cyrus token efficiency and build speed (2026-10-18, bundle C)

Branch `feature/cyrus-efficiency` (worktree /tank/dev-worktrees/cyrus-efficiency, from main af5a1d55 = live rc21). NOT merged, NOT deployed, every new knob OFF. Builds on BJ (baseline), BK (learning loop), BL (savings plan + recipe design), CA (speed, tracker 111).

Data (all read-only): 110 portal `ModBuild` rows 10-08..10-18 (84 with per-call tokens from `CYRUS_LEARNING=1`, $127 billed, almost all the owner's Infinite Dungeon refines), the build service's own records (`GET /builds/<id>`) for those 110 plus 259 eval builds (first1..smoke2), 87 `CyrusTokenReservation` rows, Test Flight results on `ModBuild.cyrus.testFlight`, build service `/health`. Paid A/B: 2 small eval runs (below). "Real" = measured; "est." = estimate with the assumption stated.

Live config found (`/health`): `MB_EFFORT_MAP=design=medium,default=medium` (effort medium on every Sonnet/Opus call since 2026-10-15 07:34), cache TTL unset (= CLI 1 h; billed cost matches 2x-input cache writes), recipes off, starter bank off, workspace map off, Saka = `claude-sonnet-5`, queue wait 0 on every portal build.

## 1. Where the money goes now (real, 84 portal builds, $127)

| call kind / model | calls | median requests | spend | median $ | cache read / cache write / output share |
|---|---|---|---|---|---|
| change, Sonnet 5 | 39 | 30 | $41.84 | 1.12 | 40% / 42% / 19% |
| change, Opus 5 | 19 | 38 | $41.67 | 2.25 | 24% / 50% / 26% |
| repair, Opus 5 | 12 | 12 | $13.54 | 1.32 | 13% / 78% / 9% |
| generate, Sonnet 5 | 17 | 8 | $9.51 | 0.52 | 7% / 43% / 51% |
| repair, Sonnet 5 | 11 | 24 | $8.68 | 1.09 | 53% / 38% / 9% |
| repair-asset (both) | 24 | 5-7 | $8.04 | 0.27-0.39 | |
| guard, Haiku | 84 | 1 | $0.13 | 0.001 | |

Findings:
1. **Change builds are 66% of real spend** (real). A change call is 30-38 requests with a median 2.0M cache-read input tokens; every request re-reads the whole conversation (~110k tokens mean), so cost = requests x context, not output. CA's "turns add nothing" is true for TIME on fresh builds, not for MONEY on change builds.
2. **Cache writes are 42-50% of a change call** at the 1 h TTL (2x input price), because each request writes its new tool results and output into the cache.
3. **A prompt-cache bug on design-downgraded builds** (real): when the design lane is dropped after the first call (`designDowngraded`), the repair's system prompt changes, so the whole 80-150k-token conversation is written again. 14 of 14 detected breaks were downgraded builds; $9.96 (4.6% of $218 across all 367 records, all on the owner's dungeon refines).
4. **Repair escalation pays for a cache migration** (real): a tier build escalates its third repair of ANY kind. All 5 Sonnet-to-Opus escalations were the FIRST compile/preserve repair (4 of them "small", 1-3 errors); they cost $5.14 against about $0.53 had they stayed on the warm Sonnet session (est.: same requests, context read at 0.1x).
5. **Thinking is still ~59% of change output at effort medium** (est.: output tokens minus streamed characters / 3.3). `phaseChars.thinking` is ALWAYS 0: Sonnet 5 does not stream thinking text, so CA's always-on instrumentation cannot measure it (doc note added).
6. **Change-build request pattern** (real, events of 80 change builds): 8 Reads, 2.2 re-reads of a file already read, `modbuilder.json` edited 3.8 times (one request each), 49% of requests carry a single tool call even though the system prompt already asks for batching.
7. **Plan screen / hold honesty** (real reservations 10-14..10-18): fresh Saka builds charged 1.15x the hold (8 of 12 over), **Saka refines 2.3x (32 of 34 over)**, Yakko refines 1.16x (9 of 13).
8. **Starter bank and recipes barely hit** (real, deterministic matchers): bank 0 instant hits on 29 real fresh portal prompts and 80 real-world-v1 prompts (1 offer); recipes (rules only, no guard archetypes) 4/29 and 4/80. Neither touches change builds. Worth keeping, not worth more work now.
9. **Latency** (real): queue wait 0 s on all builds; generate is still the wall clock (CA); **Test Flight lands a median ~75 s after the build for a ~21 s boot** because the gate sweep runs every 2 minutes.

## 2. What was implemented (all OFF; off = byte-identical prompts, old ladder, old holds)

| # | change | flag | measured / estimated saving | status |
|---|---|---|---|---|
| A | Session freeze: a call that resumes the build's session reuses the first call's system prompt + effort; repair prompt says the design lane is off; `sysFrozen` on the call record | `MB_SESSION_FREEZE=1` | real replay: $9.96 of $218 (4.6%), $0.6-1.4 per affected refine, ~0 quality risk | commit, needs image |
| B | Same-kind escalation: tier build escalates only after N failed repairs of the SAME kind, never for a small compile problem | `MB_ESCALATE_KIND=1`, `MB_ESCALATE_AFTER` (2) | real replay: 5 escalations $5.14 -> est. $0.53 (-$4.61, 2.1% of all spend; ~$0.9 per affected build) | commit, needs image |
| C | Per-call repair caps (tail protection) | `MB_REPAIR_CALL_USD`, `MB_ESCALATE_CALL_USD` | tail only (largest Opus repair call $1.80) | commit, needs image |
| D | Effort by guard class (+ one step lower on a verified recipe hit) | `MB_EFFORT_CLASS=simple=low,standard=medium,complex=high,recipe=lower` | est. simple class (71 eval builds, $0.13, 54 s) thinking ~55%: low could save ~20-30% of its output = ~$0.03 and ~15 s per simple build; NOT A/B'd (the live service has no per-build effort; needs the owner to set the env) | commit, needs image + A/B |
| E | Change hygiene block in the change USER turn (one Read batch, no re-reads, batched edits, `modbuilder.json` once, never read generated folders) | `MB_CHANGE_HYGIENE=1` | est. 6-10 of ~30 requests per refine = 15-25% of change cost IF followed (the existing system-prompt advice is mostly ignored); unmeasured | commit, needs image + A/B |
| F | Test Flight gate cadence knob | `CYRUS_TESTFLIGHT_GATE_EVERY_S` (default 120) | est. ~50 s faster "verified" per build at 20 s (mean wait 60 s -> 10 s); idle tick = one SELECT | commit, needs web promote |
| G | Change cost history: a refine's plan range and the TOP of its hold are never below the last refines of the same mod (median..max of up to 6) | `CYRUS_CHANGE_COST_HISTORY=1` | real replay on 60 refines: over-hold charges 48 -> 9; median hold 282 -> 1,045 tokens (charged median 696); no new refusals (minimum unchanged) | commit, needs web promote |
| H | Eval A/B: `eval-run.ts --model-id <id>` (explicit model beside the tier) | - | used for section 3 | commit |

## 3. A/B: Saka on claude-sonnet-5-5 vs claude-sonnet-5 (paid, same image 0.26, same effort medium, same 5 real-world prompts, Test Flight on)

Tags `ea-s5` (Sonnet 5, the live Saka) and `ea-s55` (`--model saka --model-id claude-sonnet-5-5`), run back to back on 2026-10-18 10:00-10:50 UTC, in-flight 1. Journals /root/cyrus-eval/ea-s5, /root/cyrus-eval/ea-s55.

| prompt (lane) | Sonnet 5: $ / s / repairs / output tok | Sonnet 5.5: $ / s / repairs / output tok |
|---|---|---|
| rw-troll (creature) | 0.538 / 248 / 2 / 25.1k | 0.308 / 60 / 1 / 7.8k |
| rw-shop-gui (designer) | 0.120 / 67 / 0 / 6.3k | 0.196 / 30 / 0 / 3.1k |
| rw-kits (designer) | 0.757 / 138 / 3 / 6.1k | 0.057 / 28 / 0 / 2.6k |
| rw-ruby-sword (texture) | 0.335 / 127 / 0 / 12.3k | 0.237 / 53 / 0 / 7.4k |
| rw-spleef (plain) | 0.405 / 229 / 0 / 24.7k | 0.341 / 97 / 1 / 14.2k |
| **total** | **$2.15 / 809 s / 5 repairs / 74.6k** | **$1.14 / 268 s / 2 repairs / 35.1k** |

Both arms: 5/5 real pass (Test Flight plugin enabled, every planned lane shipped), first try 3/5 each. Sonnet 5.5: **-47% cost, -67% wall time, -53% output tokens, fewer requests (37 vs 63)** at the same list price. Earlier Sonnet 5 runs of rw-troll: $0.31-0.66, 158-279 s (smoke1, smoke2, bza-rw1). n=5 is small (one prompt per lane, quality not graded beyond the real-pass gates), but it agrees with BJ/BL (0.3 eval: 5.5 needs far fewer requests) and the direction is the same on 4 of 5 prompts (shop-gui cost more, still half the time).

**Recommendation:** set `MB_TIER_SAKA=claude-sonnet-5-5` (owner, VM env, reversible), then watch the next 20 portal builds' pass@1 and refine regressions; widen to a real-world-smoke run (~$5) before calling it final. Biggest single lever found (time AND money). Change builds (66% of spend) were not in this A/B: a refine A/B on 5.5 is the next measurement.

## 4. Existing knobs to switch on (owner, no code)

| knob | where | value | evidence |
|---|---|---|---|
| `MB_CACHE_TTL` | VM env | `5m` | real replay on portal traffic: body writes at 1.25x instead of 2x save $22.26, 16 warm cross-build prefixes would expire (+$1.87): **net -16.1% of all spend**. Reverses CA/v6 "rejected": they only counted fresh builds (8k body writes); refines write 100-150k. |
| `MB_WORKSPACE_MAP` | VM env | `1` | 0 of 80 refines had a map; refines Glob/Grep the project first |
| `MB_TIER_SAKA` | VM env | `claude-sonnet-5-5` | section 3: -47% $, -67% s on 5 real prompts, same pass |
| new A, B, F, G | as above | on | low risk, measured |
| new E, D | as above | A/B first | |

Combined (est., not additive-checked): TTL 16% + freeze 4.6% + escalation 2.1% = ~22% of today's spend with near-zero quality risk, plus the Sonnet 5.5 switch (-47% on fresh Saka builds in the A/B); hygiene up to another 10-15% (share of change spend) if the A/B confirms.

## 5. Measured, not built

- Version-sheet slicing: the 1.21.11 sheet is ~10.8k tokens of a ~16.7k base system prompt. Through re-reads it is 8-10% of a change call; slicing by archetype risks API misses (compile repairs cost more than the slice saves) and needs an eval. After the 5m TTL and freeze it matters less. Not built.
- Stable-prefix layout (lane sections out of the system prompt, BL L8): only 12% of fresh generate calls find a warm prefix at today's traffic, so cross-build sharing gains little. Not built. Within a build the prefix is already stable except the downgrade case (fixed by A).
- Starter bank / recipes: shipped (3a519926, d24e8fa5), wired end to end; hit rates in finding 8. The gap closed here: a recipe hit can shrink the call (`recipe=lower` in D). Plan screen stays honest: no recipe discount is shown (none measured), the bank shows its flat price.
- Planning-phase seconds: the plan screen's Haiku planner call is ~1 s; queue wait 0. Generate time is output tokens (CA): only effort/model change it (section 3).

## 6. Image bump

A-E live in `services/modbuilder` (speed.js, server.js, prompts.js): a new modbuilder image (0.27) is needed; with the flags unset it behaves like 0.26. F, G and H are portal/worker/scripts: a normal web promote. No schema change, no migration.

## 7. Spend

A/B runs: ea-s55 $1.14 + ea-s5 $2.15 = **$3.29** of the $12 cap (build ids in the journals: ev-ea-s55-*, ev-ea-s5-*); no weekly-limit or ai_unavailable error. No other model spend.

## 8. Commits and verification
Branch feature/cyrus-efficiency (from af5a1d55): c7315e0a (service knobs A-E), 6d6eef54 (Test Flight cadence), 2c9b6dd6 (change cost history), c7a377bd (eval --model-id), f5fb7c56 (docs + regenerated references). Tests via devhost: 327/327 (new: modbuilder-efficiency-ea, cyrus-change-cost-history; plus seam, db-seam, db-split, docs-coverage, Dockerfile, pipeline, live, guard, efficiency, speed, structure, planner, tokens-economy, mega-staging, worker-schedule). Full tsc NOT completed: two unlocked runs on the overloaded node-2 died silently (no output, exit 1), the one locked run timed out waiting for the build lock. Run `devhost run --lock -- npx tsc --noEmit` once before merging.

# BV: owner QA batch through the real portal path (2026-10-14)

Account nicholas.sj.albanese@gmail.com (cmrztujaw0002hlazl58i3lsi). Image modbuilder:0.19 (idle at start), model Auto (tier "all"), 1.21.11.
Script: scripts/cyrus/qa-owner-batch.ts + qa-owner-batch-prompts.json on feature/cyrus-qa-batch (dff200ba). Records: /root/cyrus-eval/owner-batch-2026-10-14/records.json.
Path: planner (analyzeNeeds/buildModPlan via build service) -> coach analysis -> createModBuild(requirePlanAck, model auto, plan lanes, plannerSource, planAck) = same as POST /api/cyrus/generate. Worker did settle, Test Flight and asset sync.

## Headline
- 12 of 20 prompts submitted and built: 11 succeeded, 1 failed (spleef, budget cap 1.0, since raised to 2.5).
- 8 prompts (+ spleef resubmit) were REFUSED by a real gate: `daily_cap` "5,000 tokens a day" on this account (holds count; ~4,400 used after 12 builds). Not bypassed. The remaining 9 need a rolling-24h reset (earliest ~18:43 UTC 2026-10-15) or the owner raising the cap; rerun: same command, journal resumes (delete refused rows).
- Tokens: balance 16,308 -> 11,877 (4,431 charged, includes released hold on spleef = 0 charged). USD 9.99 for 12 builds (avg 0.83).
- Test Flight: 9 passed, 1 FAILED (fox), 1 still `running` at report time (magic-wand), spleef n/a.

## Table (wall = createdAt->finishedAt; tokens = charged)
| key | build | status | wall | tok | USD | att | repairs | flight | boot/plug/cmds/datapack | assets delivered |
|---|---|---|---|---|---|---|---|---|---|---|
| fox-companion | mb0d8ad449dbcaf7a9addc | ok | 544s | 489 | 0.98 | 2 | 1 asset | FAILED | P/F/F/- | pack+creature+7 sounds |
| boss-minions | mb6d31dce76454b984b83e | ok | 238s | 622 | 1.24 | 5 | 2 asset+2 code | passed | P/P/P/- | creature missing (see F3), 2 textures, 1 sound |
| fire-sword | mb40f9b72699ef38d0d30c | ok | 304s | 403 | 0.81 | 3 | 2 | passed* | P/P/F/- | 1 texture, 4 sounds, 2 designs |
| armor-set-bonus | mb1b6e3ab5355b9807c27d | ok | 283s | 305 | 0.61 | 1 | 0 | passed | P/P/P/P | armor spec, 1 sound, datapack |
| shop-gui | mb4f15e98f28682e18f216 | ok | 126s | 178 | 0.36 | 1 | 0 | passed | P/P/P/- | 4 designs (no assets planned) |
| daily-quests | mbeca427b3f102cec0be13 | ok | 127s | 511 | 0.82 | 1 | 0 | passed | P/P/P/P | 8 designs, datapack |
| spleef | mbe478df28926fa1fb181e | FAILED budget | 601s | 0 (released) | 1.02 | 1 | 0 | n/a | n/a | n/a |
| custom-recipes | mbe79464c59f207952b74c | ok | 175s | 263 | 0.52 | 1 | 0 | passed | P/P/P/P | datapack |
| food-potions | mb871ce79b62a7530d0b14 | ok | 414s | 564 | 1.13 | 3 | 2 | passed | P/P/P/- | 2 textures, 2 sounds; datapack lane planned, 0 shipped |
| magic-wand | mb49b19722510dc38e0ec0 | ok | 455s | 413 | 0.83 | 1 | 0 | running (not final) | - | 1 texture, 4 sounds |
| economy-config | mb42f9d592d845ded8bc92 | ok | 242s | 261 | 0.52 | 1 | 0 | passed | P/P/P/- | none planned |
| biome-datapack | mb8710c52c0fa83832910a | ok | 396s | 422 | 0.84 | 2 | 1 asset | passed | P/P/P/P | 3 textures, datapack, worldgen |
| ambient-sounds, chunk-cleaner, tab-scoreboard, warps-tp, enchantments, vehicle-mount, crop-farming, goblins-diff (+ spleef retry) | - | NOT RUN (daily_cap) | | | | | | | | |

*fire-sword: verdict passed although commands_registered FAILED (verdict only requires boot+plugins_enabled); worth a look (F2).
Lanes planned per build are in records.json (`plan.lanes`, build/skip). Portal sync errors in nxeon-worker journal since 18:40: none attributable to these builds (2 matches of "error", unrelated cyrus-storage lines).

## Builds that only passed because of the raised call/build budget
The restart with MB_CALL_BUDGET_USD=2.5 / MB_BUILD_BUDGET_USD=4 happened after all 11 passes completed under the OLD 1.0/1.5 caps (nothing in this batch was killed by it; all 12 were terminal at 19:19). Single generate calls above 1.0: none (max single call 0.90, fox-companion). Builds with TOTAL cost >1.0: boss-minions 1.24, food-potions 1.13 (both passed under the old cap through total < 1.5). Spleef is the only one that needs the new cap (1.02 total, 1 call at 1.021 hit the 1.0 call cap). Spleef was NOT re-run: daily_cap refused the resubmit.

## Top failure classes
- F0 Account daily cap 5,000 tokens: 8-9 of 20 builds blocked after ~4.4k tokens. A 20-build batch at avg ~370 tokens/build cannot fit; hold sizes (350-580 each) mean ~9-10 builds/day. Gate worked as designed, but the owner should know it limits QA throughput.
- F1 fox-companion (mb0d8ad449dbcaf7a9addc): plugin.yml now correctly has `depend: [BetterModel]` (rc12 fix works) but the Test Flight server has no BetterModel, so the plugin is never enabled and the flight FAILS (plugins_enabled, commands_registered; startup_log_clean 2 hits). The build still reports "succeeded" and cost 489 tokens. Root-cause guess: flight environment lacks the managed BetterModel plugin that production installs through the pack loader, so every creature mod will fail its flight (false negative) or the honest-flight change correctly flags an uninstalled dependency. Needs: install BetterModel in the flight, or mark flight "dependency not installed" instead of failed. boss-minions had a creature lane and passed: check whether its creature was dropped (assets.creatures absent).
- F2 fire-sword (mb40f9b72699ef38d0d30c): verdict "passed" with commands_registered=fail. Root-cause guess: command check treats the HUD/design-driven command differently or RCON `help` forbidden; verdict logic ignores commands_registered failure.
- F3 boss-minions: 4 repairs, 5 attempts, 1.24 USD for a 238s build (creature lane planned, no creature in delivered assets, designs warn that hollow_crown/hollow_scepter have no abilities). Quality gap: user asked for custom texture boss with minions; creature not delivered.
- F4 spleef (mbe478df28926fa1fb181e): `budget` errorCode at 1.02 USD after 601s (call cap 1.0). Tokens correctly released. Resolved by the raised cap in principle; untested.
- F5 config schema warnings: 13 undeclared config keys (food-potions: perf.* keys from injected NxPerf), 8 (economy-config), 1 (recipes): config studio would show these as undeclared. Cosmetic but visible in every build.
- F6 datapack lane planned and 'build' for food-potions but 0 datapacks shipped (assets.datapacks 0): planned vs shipped mismatch.

## What works well
- Planner/coach/hold/settle/asset sync path ran end to end with no portal errors; holds released properly on the failed build.
- Plain/config/menu mods: shop-gui 126s 0.36 USD, daily-quests 127s, economy-config 242s, custom-recipes 175s, all first try, flight 4-5/5 checks passed.
- Datapack + worldgen (biome-datapack) and armor set with datapack bonus passed all four checks including datapack_loaded.
- Texture/sound lanes delivered real packs and rendered sounds on 6 builds; stress test passed on 9 of 10 flown.
- Median wall time ~4.5 min; 8/11 successes needed at most 1-2 attempts.

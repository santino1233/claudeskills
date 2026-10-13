# BN. Knowledge distillation S0-S3 (2026-10-13)

Branch `feature/cyrus-knowledge-distill` (worktree `/tank/dev-worktrees/cyrus-distill`, from main ce6392c70d). Pipeline stages S0-S3 of BM section C4. No paid model call, no build-service call, VM 88001 untouched. The corpus and vanilla jars were read for facts only; nothing from them is in git, in a prompt or in a golden (all new text and code is original). Private outputs: `/tank/cyrus-knowledge/distill/` (`catalogue.json`, `s0_summary.json`, `s1_gap.json`, scripts).

Commits: `48108afc71` (S1 sheets/facts), `6fc24f50e9` (S2 rules), `6918434811` (S3 goldens, matrix, coverage doc), plus one docs commit (09, 11, 12 and regenerated references).

## S0. Inventory of the private reference corpus (386 items, aggregate facts only)

| Cut | Counts |
|---|---|
| Platform | plugin 173, datapack 141, resourcepack 43, other-loader (Fabric/NeoForge) 29 |
| Loader tags (an item can carry several) | paper 167, purpur 117, spigot 114, folia 81, bukkit 81, velocity 6, bungeecord 4, waterfall 3; datapack 141, minecraft 48 (packs); fabric 15, neoforge 20, quilt 3, forge 1 |
| Game versions matched (item can match several) | 1.21.1: 247, 1.21.4: 204, 1.21.8: 213, 1.21.11: 280 |
| Plugin-relevant for Paper | all 173 plugins list a Paper-family loader (paper/spigot/bukkit/purpur/folia); 141 data packs and 43 resource packs are server-delivered content Cyrus has lanes for; 4 plugins use Velocity/Bungee tags too |
| Not buildable by Cyrus | 29 loader-only mods (11 Fabric, 18 NeoForge metadata); 45 items declare client side required and server unsupported |
| Licences (Modrinth-reported) | MIT 110, All-Rights-Reserved 101, GPL-3.0-only 42, GPL-3.0-or-later 16, LGPL-3.0 22, Apache-2.0 9, CC-BY-NC family 20, AGPL 8, MPL-2.0 5, BSD-3 4, CC0 4, Unlicense 2, about 40 custom/other. Permissive-usable (MIT, Apache, MPL, BSD, CC0, Unlicense): 134, but still only used as fact sources |
| Plugin licences | MIT 50, GPL-3.0 54, ARR 34, LGPL 11, Apache 7, BSD-3 4, AGPL 4, other 9 |
| Plugin traits | reflection 114, legacy ChatColor 89, Adventure 80, MiniMessage 45, Brigadier 41, NMS/CraftBukkit 40, async chat event 36, registry-access 23, data components 17, Kotlin 4 |

Handling: `/tank/cyrus-library-staging/_reference-mods` stays private (README rule). GPL/AGPL/LGPL/ARR/CC-BY-NC code was never copied or paraphrased; only symbol names, event names and counts were used.

## S1. Events and methods

Method: usage frequencies (plugins using each Bukkit/Paper event class and method, from `per_item.jsonl`) minus everything already named in the sheets, prompts or rules = 116 events (3+ plugins) and about 1,060 methods (8+ plugins) not yet named. Most missing methods are trivial getters (Location.getX, Player.getUniqueId) every model knows; the value is in events and in methods with traps, so the batch is 59 events and 9 trap lines.

- `sheets/api-facts.json` 89 -> 157 facts (68 new: 15 block events, 15 player events, 29 entity/vehicle/weather/loot events incl. `LootGenerateEvent`, 9 method traps = 59 events + 9). 46 render a line (the rest are verified only, not worth their tokens: stable old events). Top by corpus use: PlayerLoginEvent 15, BlockFadeEvent 14, LeavesDecayEvent 13, CraftItemEvent 13, BlockPhysicsEvent 12, BlockIgniteEvent 12, BlockFormEvent 12, PlayerBucketFillEvent 12, InventoryPickupItemEvent 12, PlayerGameModeChangeEvent 11, BlockDispenseEvent 11, BlockSpreadEvent 11.
- All checked with `verify-api-facts.py` (javap, node-2, resolved Paper classpaths) on 1.21.1, 1.21.4, 1.21.8, 1.21.11. New findings: `PlayerLoginEvent` class deprecated from 1.21.8; `PlayerBedEnterEvent#getBedEnterResult` deprecated in 1.21.11; `JavaPlugin#getDescription` deprecated on all four (use `getPluginMeta()`); `BlockRedstoneEvent`, `BlockExpEvent`, `BlockCanBuildEvent`, `PlayerExpChangeEvent`, `PlayerAdvancementDoneEvent`, `PlayerLocaleChangeEvent`, `VehicleMoveEvent`, `EntityRemoveEvent` are not cancellable (rendered as `[not cancellable]`); `PlayerLeashEntityEvent` is in `org.bukkit.event.entity`. All 68 are present on all four versions.
- `gen-sheets.py`: four new groups, `[not cancellable]` and `(class deprecated here)` annotations.
- Token cost (chars/3.7): sheet growth +810 / +803 / +810 / +820 tokens for 1.21.1 / 1.21.4 / 1.21.8 / 1.21.11 (sheets now about 9.3k / 9.5k / 9.7k / 10.2k tokens).

## S2. Rules from outcomes (eval first1: 65 builds, pass@1 56.9 percent, 27 builds needed a repair)

Repair triggers seen (builds): leftover `dropItemNaturally` in a loop 6 (already deterministic in main via autofix.fixPerf 1c3937869f; not a new rule), sound "plugin never plays X" 7, design: "No design was written" 8, design trigger given as a bare string 3, texture "never references" 2, ambient sound over 4 s 2, `ThreadLocalRandom` imported from `java.util` 1, `org.bukkit.entity.Animal` 1, `Material#isLiquid` 1, `EntityDeathEvent#deathMessage` 1, `getMapList` wildcard `getOrDefault` 1 (5 compile errors), raw async repeating task 1 (autofix covers), block base item with a click ability 1.

New rules (`rules-2026-10-13.1`, 50 -> 55; each has a failing and a passing fixture in `test/fixtures/cyrus-rules/`, javap-confirmed where it is an API claim):
`jdk-wrong-package-import` (also auto-fixed with no model turn: `autofix.fixJdkImports`), `bukkit-animals-plural`, `material-no-isliquid`, `entitydeathevent-no-deathmessage`, `getmaplist-wildcard-getordefault` (`inject:false`: pre-check only, no prompt tokens). Mechanism changes: precheck `requires` (file-level positive condition), prompt `inject:false`, design prompt now says a trigger is always an object (the old line showed bare strings: 3 of 65 builds copied them).

No earlier rule was changed (test compares id, pattern, unless, versions, warning, scope, rule, fix with a snapshot of 10-12.4). Rule text added to the prompt: about 560 chars.

Prompt size (system prompt, chars at main -> now): 1.21.1 52,014 -> 55,554 (+6.8 percent), 1.21.4 53,023 -> 56,539 (+6.6), 1.21.8 53,236 -> 56,776 (+6.6), 1.21.11 55,093 -> 58,670 (+6.5). Test-enforced under 8 percent.

Candidates left for review, not rules (lane prompt or generator work): (1) sound events never played: generate a helper that plays every declared key (7 of 65 builds, 14 percent pass@1 on the sound lane); (2) "No design was written": model writes plain Java first on the design lane (8 builds); (3) texture models never referenced (2); (4) ambient length cap (2); (5) block base item with a click ability (1); (6) `ItemFlag.HIDE_ADDITIONAL_TOOLTIP` deprecation warning on 1.21.11 (3 builds; warning only, sheet says use TooltipDisplay).

## S3. Technique goldens (10 new, 67 -> 77 plugins, 4 versions each)

| Golden | Archetype | Mechanic |
|---|---|---|
| mc-blocklog | anti_grief_log | bounded per-chunk ring buffer, inspect, capped rollback |
| mc-veinminer | vein_miner | flood fill with hard cap, Player#breakBlock, tool wear |
| mc-mobcatcher | mob_catcher | EntitySnapshot string in item PDC, Boss deny-list |
| mc-leaderboard | leaderboards | statistics top lists, cached, capped scan |
| mc-crops | custom_crops | extra growth stage via BlockGrowEvent, harvest bonus |
| mc-auction | auction_house | item-currency escrow, claim box, expiry, holder menu |
| mc-movecheck | anti_cheat | speed and hover heuristics, exemptions, set-back |
| mc-duels | pvp_duels | challenge/accept, no item loss, return to old spot |
| mc-chestshop | player_shops | wall-sign shop on a chest, owner on sign PDC, atomic sale |
| mc-crates | crates_keys (NEW) | PDC-marked chest, key item, weighted roll, preview menu |

Results: javac `--release 21 -Xlint:deprecation,removal` zero warnings, strict scan zero findings (one early Base64 finding in mc-auction was removed), on 1.21.1, 1.21.4, 1.21.8, 1.21.11; one Test Flight per version with all goldens: 4 of 4 passed (76/77/77/77 plugins, 113-114 RCON checks, boot 22-24 s, peak RSS up to 1.0 GB). Registered: `minecraft-coverage.json` (91 archetypes; golden field on nine existing ones, statuses left unchanged on purpose), coach template `crates_keys`, 10 prompts in `eval/sets/coverage.jsonl` (118), `golden/results.json`, regenerated `docs/cyrus/minecraft-coverage.md` including the ranked "what Cyrus still cannot do" list (11 entries, from the census).

## Unverified

- RCON checks only prove the status line; none of the ten were played by a client (no Mineflayer playtest), so event logic (rollback, duels, sales, crate opening, anti-cheat false positives) is reviewed by reading and by javap-level compile only.
- No paid eval of the new rules/sheets; pass@1 effect is an estimate. The `first2` run after the redeploy decides.
- `EntitySnapshot#createEntity(Location)` spawn behaviour and `ItemStack#damage` return value were taken from the sheet facts; compile-verified, behaviour not flown.

## Needs the modbuilder image redeploy

`sheets/*.md`, `sheets/api-facts*.json` (copied by the existing `COPY sheets`), `rules/failure-rules.json` (existing `COPY rules`), `prompts.js`, `autofix.js`, `precheck.js` (already in the COPY list). No Dockerfile change. Knowledge version string changes to `sheets+rules-2026-10-13.1+nxperf-2`, so the prompt cache and dedupe keys roll over once. The goldens, coverage JSON, coach and docs ship with the portal (no image).

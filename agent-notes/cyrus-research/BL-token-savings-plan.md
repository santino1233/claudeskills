# BL: Cyrus token-savings plan (2026-10-12)

Owner goal: if a simple mod costs people too many tokens, Cyrus is not worth it. This note finds every place tokens or compute are spent, measures what can be measured, and ranks the ways to cut spend without making mods worse. It extends BJ (token baseline) and BK (learning loop); BJ's levers are listed in the ranking by number but not re-analysed. Companion: `BL-recipe-memory-design.md`.

Labels: **V** = verified in code (cyrus-rc2) or in read-only SELECTs of the production `ModBuild` table / decompiled jars of the 25 stored builds. **U** = estimate or judgment, with the assumption stated. No build was run, nothing was written anywhere except these two files.

**Sample warning (V):** production holds 28 builds, ALL from the owner (1 distinct user), $7.33 total. Nothing here is a forecast for public traffic. The numbers rank where to look and what to measure.

---

## 0. The five findings that matter

1. **Where the money is (V + U).** Code the model writes is only about 25-40% of a build's cost (U). The rest is thinking before the first edit (planning = 51% of wall time, BJ; the owner saw 3.5-4 min on a 700-word spec), one API round trip per file on Sonnet 5, and cold prompt-cache writes. Shrinking prompts, sheets or boilerplate is therefore worth single digits; model choice, effort, turn count and rework are worth tens of percent.
2. **The Saka tier is on Sonnet 5, not 5.5 (V).** All 11 Saka (non-guard) calls in the data resolved to `claude-sonnet-5` (`MB_TIER_SAKA` default). A fresh Saka build: median $0.55 (range $0.22-0.83), 9-10 turns, 450 s. The 0.3 eval measured Sonnet 5.5 at 2-3 requests and 49% cheaper. This is the largest single lever (BJ #1) and needs no code.
3. **The plan screen under-states cost (V).** I ran the real `estimate()` over the 25 successful builds: **20 exceeded the top of the shown range**, 3 were inside, 2 under. Median actual / shown-high: Saka fresh 2.4x, Saka change 2.5x, Katara change 2.1x, Katara fresh 1.0x, Yakko 1.2x. Users are charged actual cost (not capped at the hold), so the plan screen is the biggest "silently more expensive than shown" problem. See section 3.
4. **Owner's pre-made-structures idea: real but modest on tokens (V shares, U savings).** Of the code the model writes, about 26% is scaffoldable boilerplate (section 4), which is 4-10% of a plain build's cost. Its bigger value is removing failure classes (plugin.yml/getCommand mismatch, unsaved data, reload) and feeding recipes. Typed specs that compile to Java (designer lanes) save far more per hit (70-90% of code tokens) but only 18 of 85 archetypes use them today.
5. **Two things that look like savings are traps (V).** `MB_DEDUPE=on` is cross-user (the key has no user id): it would hand one customer another customer's source, which breaks the owner's "never reproduce a user's mod" rule. And "refunds for guard refusals" only release the hold: `cyrus_tok_charge_refused` defaults to true, so a refused or falsely refused request still costs the 5-token floor.

---

## 1. Where the tokens go (measured, 28 builds)

Spend by call kind from `result.ai.calls` (V):

| kind | calls | turns | spend | share | $/turn |
|---|---|---|---|---|---|
| change | 13 | 221 | $3.24 | 44% | 0.015 |
| generate | 10 | 62 | $2.93 | 40% | 0.047 |
| repair | 7 | 22 | $0.22 | 3% | 0.010 |
| repair-asset | 2 | 5 | $0.22 | 3% | 0.043 |
| guard | 19 | 19 | $0.08 | 1% | 0.004 |
| (builds before AI records) | | | $0.64 | 9% | |

By model resolved: Haiku 4.5 (Katara) 19 guard + 19 gen/change/repair calls; **Sonnet 5** (Saka) 11 calls, $4.00 (55% of spend); Opus 5 (Yakko) 2 calls, $1.09. Fresh median cost by tier: Katara $0.092, Saka $0.55, Yakko $0.55 (n=2). Opus fresh builds (6-7 turns, $0.41 / $0.69) were NOT dearer than Sonnet 5 fresh builds (9-10 turns, $0.22-0.83): Sonnet 5's turn count eats its price advantage.

Cost anatomy of a typical build (U, from the 0.5 efficiency analysis on the eval mods, `cyrus-v6/efficiency/EFFICIENCY.md`, scaled): output tokens 61% (of which 40-77% is thinking depending on model), cache writes 33% (everything generated is written back to the cache at the 1 h TTL price, 2x input), cache reads 6%. On the owner's heavier prompts the thinking share is higher: a 475 s Sonnet 5 build (ChunkDup, 10 turns, $0.82) wrote about 5.6k tokens of Java (decompiled estimate) plus about 1k of yml/json, but at 60-80 tokens/s it generated roughly 30k+ output tokens, so 60-75% of its output was thinking (U; the service records the exact split in `turnsDetail` on VM 88001, unreadable to me; `CYRUS_LEARNING=1` mirrors it into the portal).

System prompt size per call (V, measured with the real `systemPrompt()`; tokens = chars/4):

| part | tokens | when |
|---|---|---|
| hard rules + efficiency + modbuilder.json format | ~1,450 | always |
| version API sheet (1.21.11; others within 4%) | 6,218 | always |
| 32 failure rules | 1,455 | always |
| PERFORMANCE + NxPerf API | 880 | always (MB_PERF_SAFETY) |
| **base system prompt** | **~10,050** | every build, plus the CLI's tool definitions (U ~2-3k) |
| texture 916, sound 1,561, datapack 2,531, worldgen 1,922, design 2,078, gameplay 1,801, boss 1,892, hud 844, motion 1,491, creature 1,271, item states 1,207, config 653 | up to +18,200 | only when that lane is planned; all lanes together = 28,216 |
| sound library catalog (read into context, `sound-catalog.txt` 22.8 KB) | ~5,700 | sound-library builds |

Cold-prefix cost (U, depends on cache warmth): base 12.5-15k tokens written at the 1 h price = Sonnet $0.05-0.06, Opus $0.13-0.15, Haiku $0.025-0.03; with all lanes 28k = Sonnet $0.11, Opus $0.28. On a $0.09 Katara build or a $0.2 simple Saka build that is 20-50% of the bill when the cache is cold. The guard calls show the warm/cold swing: first-of-day $0.015, warm $0.001. At one user and gaps over an hour between builds, most builds are cold. **Measure first** (section 9): the first turn's `cacheRead` vs `cacheWrite` in `turnsDetail` answers it.

---

## 2. Inventory of every place Cyrus spends model tokens or compute

"User pays" = included in the build's `costUsd`, which the portal turns into tokens: `tokensForCost = max(5, ceil(costUsd x tokensPerUsd x multiplier))`, tokensPerUsd default 500 (owner decision pending: 300), Yakko multiplier 1.25 (`lib/cyrus/tokens/economy.ts`). "Nxeon" = absorbed, not on any build record. The token economy is switched off today (`cyrus_tok_live=false`; only the owner builds, on a Claude subscription: costs are API-equivalent).

| # | spender | model / resource | typical size | $ per build | who pays | plan screen / hold |
|---|---|---|---|---|---|---|
| 1 | Planner `POST /plan` (lane needs) | Haiku, 1 turn, no tools | U ~4k in / 150 out | $0.001-0.004 per plan request, cached 10 min per text in the portal process, 30 req/min/user | **Nxeon** (no build record) | not shown |
| 2 | Intake guard (+ difficulty class, replaces the classifier) | Haiku, thinking off | ~0.5k prompt + CLI prefix | 19 calls: avg $0.0043; last 9 avg $0.0015 | **user** (inside costUsd; refused builds too: `cyrus_tok_charge_refused=true`, 5-token floor) | held with the build |
| 3 | Classifier | Haiku | | $0 (skipped: tier override, or guard class used) | n/a | |
| 4 | Fresh generation | Katara Haiku / Saka Sonnet 5 / Yakko Opus 5 | 4-10 turns | Haiku $0.04-0.15; Sonnet 5 $0.22-0.83; Opus $0.41-0.69 | user | estimate below (too low) |
| 5 | Change build | same model as base | 12-31 turns (reads workspace + edits) | Haiku $0.08-0.27; Sonnet 5 $0.28-0.65 | user | `CHANGE_COST_FACTOR 0.8` (measured 1.7x for Katara) |
| 6 | Cheap first repair (small compile error) | Haiku via `--resume` | 1-7 turns | $0.004-0.04 | user | **not active on tier builds**: `rec.override` set, so repairs stay on the generate model (V: `server.js` repair ladder) |
| 7 | Model repair / escalation (after 2 failed repairs, one tier up, no notice) | Sonnet/Opus | up to 25 turns | Sonnet 5 repair $0.10; repair-asset $0.034-0.18 | user (charged at the build's own multiplier) | not in estimate |
| 8 | Asset / design repair rounds (max 2 each) | Sonnet | 2-3 turns | $0.043/turn (4x a code repair) | user | not in estimate |
| 9 | Thinking inside 4/5/8 | part of output | 40-77% of output | the biggest hidden term | user | not shown |
| 10 | Cold prompt-cache writes (system prompt + tools, per version x toolset x model x lane set) | any | 12-28k tokens | $0.03-0.28 | user | not shown |
| 11 | Title, tagline, summary, howToUse, limitations, permissions list | written by the main model in `modbuilder.json` in the same response | ~400-700 out | ~$0.005 Sonnet | user | no extra call (V) |
| 12 | Listing category / icon / tag auto-sort | deterministic (`lib/cyrus/categories.ts`, no model) | | $0 | | |
| 13 | Config Studio (plain builds since 10-12 05:20) | main model also writes `assets/config/schema.json` while `config.yml` is generated from it | +0.4-1.2k out | ~$0.005-0.012 | user | not in estimate |
| 14 | Textures, sounds (synth + library), creature specs, datapack/worldgen specs | model writes the spec JSON only; rendering is deterministic code (V: `textures.js`, `sound-spec.js`, `creatures.js`) | 0.3-1k out each | cents | user | `LANE_WEIGHT` 0.05-0.45 per lane |
| 15 | Designer lanes (item/menu/quest/boss/HUD/motion) | model writes typed JSON; Java compiled by `lib/cyrus/designer/compile.ts`, zero tokens | 0.4-0.8k per item vs ~2k hand-written | | user | |
| 16 | Designer Studio revisions, config-only repack | **no model call** (V: `runDesignerEdit`, `repackConfigOnly`) | | $0 | | |
| 17 | Reference images the user attaches | Read of an image | ~1.5k tokens each, cached after | cents | user | |
| 18 | Autofix, precheck, perfcheck, scan, javac | deterministic CPU on VM 88001 | seconds | $0 tokens, compute | Nxeon | |
| 19 | Test Flight (load test on a real server) | VM time, no model | minutes | compute only | **Nxeon** | not a token cost (V: no model call in `lib/cyrus/testflight`) |
| 20 | Prompt coach rewrite (branch, unmerged) | Haiku, one call, optional | | $0.002-0.01 | **Nxeon** (route comment: "Nxeon's cost like the planner") | |
| 21 | Learning loop: report / mining job | SQL + code, no model (V) | | $0 | Nxeon | |
| 22 | Evals ($3 per 28-prompt run), library ingest (`library/v2/stage-b`), AI gateway for in-game mods (stub, never calls a model) | | | | Nxeon | |

### Silently paid by the user (flag these)

1. **Cold-cache prefix writes and thinking** (rows 9-10): the biggest terms, not visible, not in the estimate.
2. **Repairs and asset repairs on a SUCCESSFUL build** (rows 6-8): fully charged (the failure-credit rule `cyrus_tok_free_failures=3` per 7 days applies to FAILED builds only; over the limit failures are charged in full). The 10-12 Spawner-Wand build spent 33% of its $0.65 on two asset-repair rounds.
3. **Escalation** (row 7): a Katara build can be finished by Sonnet or Opus without telling the user.
4. **The guard** (row 2): charged even when it refuses, including false refusals (the 10-12 06:52 ChunkMirror refusal charged 5 tokens, 215 returned). `cyrus_tok_charge_refused` is a Setting.
5. **Charge is not capped at the hold** (`settleCharge` charges full `costUsd`; the ledger only caps at the balance). With estimates 2.4x low, most builds end "over held". The UI shows it, but the user never agreed to it.
6. **Rework** (BJ: 23% of spend re-requested within 30 min), a share of which is the product's fault (planner turned "mob spawner" into a Spawner Wand and replaced the plugin).
7. **Per-build worst case**: `MB_BUILD_BUDGET_USD=4` and `MB_CALL_BUDGET_USD=2.5` default; the largest observed build is $0.83. A runaway loop could charge 2,000 tokens (40% of a daily cap of 5,000) before it stops.

Not charged to users: planner, coach, Test Flight, javac/scan compute, learning jobs, evals.

---

## 3. Plan screen: honesty about "estimated tokens"

Today (V): `estimate()` = 3 buckets x model `costFactor` (katara 0.5, saka 1, yakko 2.5) x lane weights; anchored on Phase 0 Sonnet 5 / small eval prompts. Real data (shown range = `estimate()` for the stored text, no lane weight):

| group | n | actual median | actual range | shown high (median) | actual / high |
|---|---|---|---|---|---|
| Katara fresh | 6 | $0.092 (46 tok) | 0.038-0.146 | $0.09 | 1.0x |
| Katara change | 7 | $0.159 (80 tok) | 0.082-0.265 | $0.07 | 2.1x |
| Saka fresh (Sonnet 5) | 4 | $0.55 (275 tok) | 0.217-0.825 | $0.18 | 2.4x |
| Saka change (Sonnet 5) | 6 | $0.435 (218 tok) | 0.055-0.648 | $0.14 | 2.5x |
| Yakko fresh | 2 | $0.547 (274 tok) | 0.407-0.688 | $0.45 | 1.2x |

(tokens at 500 per USD.) Also: a change is not 0.8x a fresh build for Katara (1.7x measured; Haiku explores more), but is for Saka (0.8x).

What honest looks like:
- Show **typical and likely-maximum**, from measured medians and p90 by (tier x fresh/change x lane set), with the sample size behind them when small. Until a cell has n >= 8 builds, show the prior but widen it by the measured correction above and say "early estimate". `Setting cyrus_est_table` (new) so it can be corrected without a deploy.
- State the rule in plain words: "You pay what the build actually uses. We hold up to X; the rest is returned." If the owner wants a hard promise, cap the charge at the hold (Nxeon absorbs the overshoot) until estimates are calibrated: owner decision.
- Say what changes the number: tier, edit vs new, each asset lane (lane weights are guesses, 0.05-0.45), sound library, reference images.
- A **recipe hit** (BL-recipe-memory-design) changes the estimate only by a *measured* effect: `typical x recipeEffect[archetype]` where recipeEffect is the median cost ratio from A/B builds, shown only with n >= 8; before that show a badge ("tested pattern: usually fewer fixes") and no discount. Never show a lower number we have not measured.
- A **starter-bank hit** (ready-made build of a template chip, section 5 L4) is a different line item: "Ready-made, instant, ~5 tokens", exact because there is no model call.
- During the build, the live meter exists (V); add a soft stop at 100% of the hold ("This one is bigger than expected: continue / stop with what you have") so the user, not the service budget, decides.

---

## 4. Owner's idea: pre-made structures (measured)

### 4.1 How much of a real build is boilerplate (V shares, U savings)

Method: decompiled (Vineflower) the 25 stored jars, kept only classes the MODEL wrote (excluded the injected `nxperf/` watchdog, 1,009 lines per build, and compiled `designer/`, `abilities/`, `items/`), classified every line by method role. 15 builds, 55 files, 5,840 lines, about 56k tokens (chars/3.5). Our 65 golden plugins (hand-authored reference source, 4,213 lines) for comparison.

| category | real builds (chars) | golden (chars) | scaffold-addressable? |
|---|---|---|---|
| imports + package | 12.8% | 23.4% | yes: API imports can be resolved by the service (autofix already knows the unique FQN); JDK ones stay |
| lifecycle (onEnable/onDisable) | 5.3% | 7.5% | mostly (registration, timers, flush) |
| config loader / clamp / reload | 4.3% | 0 | yes (typed `Cfg` + generated config.yml) |
| persistence (YAML load/save) | 2.6% | 0.8% | yes (`Store`) |
| command dispatch skeleton (onCommand/onTabComplete) | 11.4% | 28.9% | about half: sender/perm/args/usage checks |
| fields, structure, annotations, small helpers | 7.9% | 11.5% | partly |
| **event handlers** | 13.4% | 12.4% | no (skeleton line only) |
| **unique logic** | 41.2% | 15.4% | no |

Realistic saving: imports -80% (10.2 pts), lifecycle -70% (3.7), config -70% plus config-backed fields (5), persistence -70% (1.8), commands -55% (6.3), rest -30% (1.2) = **about 26% of code tokens** (range 20-30%).

Code is 15-40% of a build's cost (ChunkDup 15%, eval-size mods up to 41%; U), so a scaffold saves **4-10% of a fresh plain build** (U). Extra, smaller wins from the same family: derive `plugin.yml` from registered commands (median 576 chars = 170 tokens, V from the jars), `modbuilder.json` commands/permissions/config lists (duplicate of yml; ~200-500 tokens), and `config.yml` vs Config Studio's `schema.json` (both written; schema is the source) = 1-3%.

Where a scaffold also pays: it deletes failure classes the repair loop pays for today (getCommand without a yml entry, no flush in onDisable, no reload, unbounded queue), and is the host for recipes. Same injection mechanism as NxPerf (V: `perf.js inject`, 790 + 219 lines placed before every javac), so there is precedent and a safe pattern.

Verdict: build it, but behind recipes and effort routing in the order (it is an L-size item for single-digit percent). Do not expect it to fix the thinking cost.

### 4.2 Spec-driven archetypes (designer lanes and datapack lanes)

`lib/cyrus/adapters/minecraft-coverage.json`, 85 archetypes (V counts): 63 are "plain plugin / plugin" (54 have a golden), 18 are driven by a typed lane (menus_gui, bossbar_titles, hud_glyphs, sidebar, custom_music, advancements, armor_sets, custom_enchantments, custom_food, custom_weapons, loot, recipes, retexture_vanilla, custom_blocks, cosmetics, animated_creatures, bosses, worldgen), 4 impossible or not built.

Judgment (U): of the 63 plain archetypes about 18 are thin command / message / timer / data-table plugins that a typed behaviour spec could cover (commands family: custom_commands, utility_commands, kits, tpa_spawn, homes, warps, back_rtp; messages family: announcer, chat_format, chat_filter, join_leave, private_messages, books_guides, sign_tools, holograms; timers: afk, playtime_rewards; data: player_heads). That would raise spec-driven coverage from 21% to about 42% of archetypes. The other ~45 (claims, regions, minigames, clans, economy, auctions, machines, mob AI, structure placement, moderation, ranks) need free-form code and recipes, not specs.

Token effect per hit (V sizes, U equivalence): a designer item spec is about 420-800 tokens (`designer-example.json` 1,669 chars); the same item as Java is about 150 lines / 2k tokens (Spawner Wand: 86 + 67 generated lines) PLUS a ~2.1k-line runtime (about 17k tokens) that the model never writes. So 70-90% fewer code tokens, no javac errors from that part, and a smaller solution space for thinking. But: the lane adds 2-8k tokens of system prompt, and the only designer-lane builds in production were the worst ones in the sample (the 10-12 Spawner Wand lineage: 29 files, $0.65 plus repairs, replaced the user's plugin). Spec lanes need planner precision first (regression guard, BJ #2) and no measured cost data exists for them (flights record `costUsd: 0`). XL effort; list as a strategic bet, not a quick win.

---

## 5. Levers (new ones; BJ's are referenced by number)

Saving is % of the average mod's cost (mid), with the affected share of spend; U unless marked. Confidence H=0.8, M=0.5, L=0.25. Effort/risk weight: S=1, M=2, L=4, XL=8, times 1.0 low risk / 1.3 medium / 1.6 higher.

| id | lever | saving | confidence | effort-risk | notes |
|---|---|---|---|---|---|
| **L0** | Saka on Sonnet 5.5 (BJ #1). Add: turn count is the mechanism (9-10 requests on Sonnet 5 vs 2-3 on 5.5), so the saving on owner-size prompts may exceed the eval's 49% | 35-55% of Saka builds = 16-26% of spend | M-H | S x1.3 | V that Saka resolves to Sonnet 5; eval first |
| **L1** | **Effort routing by guard class** (extends BJ #4): the guard already returns simple/standard/complex for free; pick `--effort` once per build (cache-safe): simple low, standard medium, complex high; a recipe hit lowers one step. Haiku never gets effort. | thinking is 40-77% of output; 25-50% off on simple/standard = 10-25% of Sonnet/Opus builds = 6-16% of spend | L-M | S x1.3 | `effortFor(model)` exists in `server.js`; needs per-class env; eval A/B on `eval/sets/coverage.jsonl` (103 prompts, per archetype) |
| **L2** | **Recipe memory** (design in BL-recipe-memory-design.md): retrieve a verified mechanic recipe from the guard's archetype ids, inject only it into the user turn | per hit build 15-35% (less thinking, fewer repairs, fewer rework builds); hit rate 35-55% of plain builds (U; the owner's 13 root prompts: 3 would hit an event-reward/spawn recipe, 3 the bounded-work family) = 5-19% of spend | L-M | M x1.3 | needs eval; owner's own prompts are unusual, public hit rate unknown |
| **L3** | **Calibrated estimates** (section 3) | 0 tokens; prevents the 2.4x surprise | H | S | must-do for trust |
| **L4** | **Verified starter bank**: build the 24 template chips ourselves per version/tier once (about 24 x $0.2 = $5 per version), serve an unmodified chip as an instant ready-made (re-run compile + scan on serve, no model). The existing reuse path (`tryReuse`) already re-validates. Restrict to a curated allowlist, never to other users' builds. | 100% of those builds ($0.09-0.5 each); share unknown: 0 of the owner's 13 root prompts were chips; if 10-30% of first builds are chips (U) = 3-10% of spend, and the first impression is instant and exact | L | M x1.0 | funnel data needed (log `templateId` on create) |
| **L5** | **Change-build hygiene**: file manifest in the change prompt, remove injected `nxperf/` and compiled `designer/` sources from the change workspace during the model call (re-injected before javac, V), tell the model they are generated | up to 8-9k tokens (NxPerf) or ~17k (designer runtime) if the model Reads them; change builds are 44% of spend; 5-15% of change builds = 2-6% | L | S x1.0 | whether the model reads them is not stored; check `toolCalls`/`turnsDetail` after learning capture |
| **L6** | **NxKit scaffold** (section 4.1): `Cfg`, `Cmd`, `Store`, `Msg`, `Cooldowns`, `Menu` helpers injected like NxPerf; yml/config/schema generated from the calls | 4-10% of plain fresh builds, plus fewer failure classes | L-M | L x1.3 | after L2; recipes should use its API |
| **L7** | **Typed behaviour lane** for the thin command/message/timer archetypes (section 4.2) | 50-75% per hit; hit rate 15-30% of plain builds | L | XL x1.6 | strategic; needs planner precision |
| **L8** | **Cold-prefix restructure**: move lane sections (and optionally the sheet slice) from the system prompt to the first user turn so the 10k base prefix is identical across lane sets and shared by every build of the same version/toolset/model within the TTL. Break-even for slicing the sheet instead: slicing saves ~3k tokens x $4/M = $0.012 per Sonnet build, whole-sheet sharing saves $0.0475 per warm hit, so share unless fewer than ~30% of builds are warm. | 2-6% of spend, traffic-dependent | L | M x1.6 | measure warmth first; also decide `MB_CACHE_TTL` (5m write 1.25x vs 1h 2x: v6 break-even about 15 builds/hour per prefix) |
| **L9** | Cheap-first repair on tier builds: the Haiku first repair is skipped whenever `rec.override` is set (every portal build) | 1-2% (repairs 3% of spend, tier builds repair on Sonnet at $0.025/turn vs Haiku $0.0067) | M | S x1.3 | not for asset repairs |
| **L10** | Import pre-pass: tell the model it may omit Paper/Bukkit/Adventure imports; `AF.fixImports`/classIndex resolves unique FQNs before the first javac | 1-3% | M | S x1.3 | keep JDK imports mandatory |
| **L11** | Sound-library catalog slicing by use case (the planner already knows the sounds needed): 22.8 KB (~5.7k tokens) read into context | $0.02-0.04 per library build | M | S | only library-lane builds |
| **L12** | Config Studio duplication: the model writes both `schema.json` and `config.yml` (the service writes config.yml from the schema). Tell it not to, or derive the schema from commented config.yml (`inferSchema` exists) | 2-5% of config-lane builds | L | S-M | product decision: schema quality matters |
| **L13** | Budget caps `MB_BUILD_BUDGET_USD=1.5`, `MB_CALL_BUDGET_USD=1.0` (defaults 4 / 2.5) | tail protection, no typical saving | H | S | observed max $0.83 |
| BJ #2 | Regression guard on change builds | 8-16% of spend | M | S x1.0 | branch `fix/cyrus-change-regression-guards` |
| BJ #3 | Several edits per response on change builds | 5-10% | L | S | |
| BJ #5 | "What stays / goes" check + prompt coach before building (rework pool 23%) | 4-8% | L | S-M | coach branch exists |
| BJ #6-8 | repair caps, route floor, smaller sheets | 1-2% each | | | sheet slicing: see L8 math |

Things that are **not** levers (checked): the version sheet (6.2k tokens, cached; slicing is at most 1-2%, BJ #8 and L8); `MB_GUARD` (about $0.0015-0.004 per build, blocks junk early; keep on); `MB_CLASSIFIER` (already skipped); tool-output truncation (results are tiny); lower generate turn cap (typical 2-10 turns).

### Ranking (score = saving mid x confidence / effort-risk; higher is better)

| rank | lever | saving mid (% spend) | conf | weight | score | measurable now? |
|---|---|---|---|---|---|---|
| 1 | L0 Saka on 5.5 | 21 | 0.7 | 1.3 | 11.3 | partly (cost per turn known; needs a quality eval, ~$3) |
| 2 | BJ #2 regression guard | 12 | 0.5 | 1.0 | 6.0 | yes (BJ replayed it on the 27 builds) |
| 3 | L1 effort routing | 10 | 0.35 | 1.3 | 2.7 | no: needs A/B eval (2 x $3) and token capture |
| 4 | BJ #5 coach / keep-remove | 6 | 0.25 | 1.5 | 1.0 | no |
| 5 | L4 starter bank | 6 | 0.25 | 2.0 | 0.75 | needs `templateId` logging |
| 6 | L2 recipe memory | 10 | 0.3 | 5.2 | 0.58 | eval per archetype |
| 7 | L5 change hygiene | 4 | 0.25 | 1.0 | 1.0 | yes after capture (count Reads of generated files) |
| 8 | L9 cheap repair on tiers | 1.5 | 0.5 | 1.3 | 0.58 | partly |
| 9 | L10 import pre-pass | 2 | 0.5 | 1.3 | 0.77 | eval |
| 10 | L6 NxKit | 7 | 0.3 | 5.2 | 0.40 | eval |
| 11 | L8 prefix restructure | 3 | 0.3 | 3.2 | 0.28 | yes after capture |
| 12 | L7 behaviour lane | 9 | 0.25 | 12.8 | 0.18 | eval |
| - | L3 calibrated estimates | 0 | H | 1 | must-do (trust, not savings) | yes today |

The formula undervalues L2 and L7: they are the only ones that cut thinking AND failures AND rework together, and they compound with each other. Do the cheap ones first, build L2's pipeline early because it needs the data that L0/L1/capture generate anyway.

---

## 6. Quick wins that need no code (env knobs and admin Settings)

Build-service env: put in `/root/modbuilder.env` on VM 88001, then rerun `run.sh` when no build is running (the run.sh PASS list only forwards the shell env; the env files reach the container). Only the owner may do this; I touched nothing.

| knob | where | value | effect | risk | do it when |
|---|---|---|---|---|---|
| `MB_TIER_SAKA` | service env | `claude-sonnet-5-5` | L0: -35..55% on Saka | medium: eval first | after the $3 v6 eval; reversible by unsetting |
| `MB_EFFORT` | service env | `medium` (one value for every call of a build; Haiku ignores it) | L1 without code: 10-25% of Sonnet/Opus builds | medium: quality unmeasured; never below medium for codegen | A/B 2 eval runs, then keep |
| `MB_BUILD_BUDGET_USD` / `MB_CALL_BUDGET_USD` | service env | 1.5 / 1.0 | caps runaway builds at 750 tokens | low (max observed $0.83); a legitimate Yakko mega-build would hit "budget" error and be free/refunded | now |
| `MB_DEDUPE` | service env | **leave off** | cross-user reuse breaks the no-user-code rule (V: key has no user id) | legal | until the curated-bank variant exists |
| `MB_CACHE_TTL` | service env | leave unset | v6: 5 m is cheaper only above ~15 builds/h per prefix; re-check when the service moves from the subscription token to an API key (default TTL may differ) | | after capture |
| `MB_GUARD`, `MB_AUTOFIX`, `MB_LEAN_TOOLS`, `MB_PERF_SAFETY`, `MB_SHEETS`, `MB_RULES` | | keep defaults on | each saves more than it costs | | |
| `CYRUS_LEARNING` | portal env (needs web restart) | `1` | starts storing per-call tokens and turns (`turnsDetail`) for new builds: **unlocks measuring everything above**; zero behaviour change | low | now (owner asked for token capture) |
| `cyrus_tok_charge_refused` | admin Setting | `false` | a refused or falsely refused request costs 0 tokens (guard cost $0.0015 absorbed); abuse is bounded by the rate limit (3/min, 20/h) | low | now |
| `cyrus_tok_free_failures` / `_days` | admin Setting | 10 / 7 | failures on our side stay free for longer before "failed_over_limit" charges full | low | now |
| `cyrus_tok_reserve_table` | admin Setting (JSON) | raise Saka to measured [60, 420] standard, Katara change-aware | holds follow reality; fewer "over held" | low | now |
| `cyrus_tok_tokens_per_usd` | admin Setting | owner decision (500 default vs 300 recommended) | pricing, not efficiency: at 500 the median Saka fresh build is 275 tokens (the 70-token starter grant buys 1.5 Katara builds and 0 Saka builds); on a 3,500-token Saka plan that is about 13 median builds, or about 25 after L0 | | with the Saka decision |

Behavioural advice that needs no code either: Katara fresh builds are 6x cheaper than Saka ($0.09 vs $0.55) and completed 6/6 fresh prompts (quality of those mods not graded here); the Haiku change-build regression (BJ) argues for Saka on changes.

---

## 7. Build backlog for Opus agents (ordered)

Each item is independent unless stated. All behind a flag or Setting, default off, with tests and a docs line (`DOCUMENTATION.md`, `docs/cyrus`). Branch from the then-current main; the learning-loop code lives on `feature/cyrus-learning-loop`, not in rc2.

1. **B1: capture + path-memory report (flag `CYRUS_LEARNING`).** Extend `lib/cyrus/learning/{usage,aggregate,report}.ts` and `scripts/cyrus/learning-report.ts`: per (tier x fresh/change x lane-set x guard class) cost p25/p50/p90, turns, cache-hit share of the first turn, output share of cost, Read counts of generated files, effort used. Tests: golden fixture rows + new cases in `test/cyrus-learning-*.test.ts`. Risk low (read-only). Unblocks B2, B4, B7, L8.
2. **B2: calibrated estimates (Setting `cyrus_est_table`).** Files: `lib/cyrus/estimate.ts` (BASE per tier, per-tier change factor), `lib/cyrus/planner/estimate.ts`, `lib/cyrus/tokens/plan-estimates.ts`, the plan-screen component (typical / up to / sample size / early-estimate wording), `holdRange`. Tests: new `test/cyrus-estimate.test.ts` (plus `test/cyrus-planner.test.ts`, `test/cyrus-tokens-economy.test.ts`) using the 25-build table in section 3 as fixtures (no actual > 1.5x shown high). Risk low; rollback = clear Setting.
3. **B3: change regression guard (BJ #2).** Merge/finish `fix/cyrus-change-regression-guards`, reuse `lib/cyrus/learning/surface.ts`. Flag per branch. Tests exist for surface. Risk low.
4. **B4: change-build hygiene (flag `MB_CHANGE_MANIFEST`).** `services/modbuilder/server.js` (move `nxperf/` and `designer/` out of the workspace for the AI call, restore before `validate`), `prompts.js changePrompt` (file manifest: path + size + "generated, do not read"), `test/modbuilder-pipeline.test.ts`. Risk low-medium (designer compile must still find its runtime: assert in a pipeline test). Needs image 0.9.
5. **B5: effort routing (env `MB_EFFORT_SIMPLE/STANDARD/COMPLEX`, default unset).** `services/modbuilder/server.js effortFor(model, rec)`, `route.js CFG`, record effort per call (already stored); one value per build; recipe hit -1 step. Tests in `test/modbuilder-efficiency.test.ts`. Eval: run `eval/run_eval.py` on `sets/coverage.jsonl` twice. Risk medium (quality). Image redeploy.
6. **B6: recipe memory v1** (BL-recipe-memory-design.md): (a) guard prompt returns archetype ids in the same call (`route.js GUARD_PROMPT/parseGuard`; extend `test/modbuilder-guard.test.ts`); (b) `lib/cyrus/recipes/{schema,select}.ts` + `services/modbuilder/recipes/*.json` + `recipeBlock()` in `prompts.js` (user turn, not system prompt); (c) seed 8 recipes from BF (`plg-safe-teleport-async`, `plg-teleport-warmup-cooldown`, `plg-config-snapshot-reload`, `plg-chest-gui-antidupe`, `plg-ondisable-sync-save`, bounded-work/NxPerf, event-reward-spawn rule, cooldown ability) plus goldens mc-homes, mc-rtp, mc-kits, mc-warps; (d) `tools/recipes/lint.ts` (provenance, similarity gate, golden link, javap facts). Flag `CYRUS_RECIPES` (portal) + `MB_RECIPES` (service). Tests: schema, selection precision on the 103 coverage prompts, no-recipe == byte-identical prompt. Risk medium; needs eval per recipe.
7. **B7: path-memory table + mining kinds** (`lib/cyrus/learning/pathmemory.ts`, `scripts/cyrus/learning-mine.ts`: candidate kinds `recipe-pitfall`, `path-stat`; admin tab row). Feeds B2 and router. Risk low (candidates only, human review).
8. **B8: starter bank (flag `CYRUS_STARTER_BANK`).** `scripts/cyrus/build-starter-bank.ts` (staff account, one build per chip x version x tier), curated allowlist in the service (`dedupeKeyOf` restricted to allowlist keys; never any other record), `lib/modbuilder/create.ts` + plan screen "Ready-made" line, log `templateId`. Every serve re-runs validate, precheck, javac, scan (existing `tryReuse`). Tests: pipeline test with a fake allowlist hit; a non-allowlisted identical prompt must NOT reuse. Risk medium.
9. **B9: NxKit v1** (`Cfg`, `Cmd`, `Store`, `Msg`; flag `MB_NXKIT`): `services/modbuilder/nxkit/*.java` (javap-verify on all four jars), `kit.js` (inject, scan calls, generate plugin.yml + config.yml + Config Studio schema), `prompts.js KIT_SECTION` (~700 tokens, API only), `perf.js`-style tests. A/B on 20 coverage prompts. Risk medium-high (new API surface; keep helpers on APIs identical across versions).
10. **B10: small ones**: haiku-first small repair on tier builds (`server.js` repair ladder), import pre-pass, sound-catalog slice, config.yml/schema dedupe, L8 prompt restructure (after B1 data). Each independent, each behind its own env.
11. **B11: typed behaviour lane** (commands/messages/timers) in the designer family: `lib/cyrus/designer/behaviour/{spec,compile,simulate}.ts`, schema JSON, prompt section, golden + flights. XL; start with the teleport family (homes/warps/tpa/rtp).

---

## 8. Measure now vs needs an eval

Measurable now with no spend: spend/turn/rework tables (BJ), estimate error (section 3), boilerplate share (section 4.1), system prompt sizes (section 1), unit prices.
Needs `CYRUS_LEARNING=1` first (no behaviour change): cold-vs-warm cache share, thinking share, Reads of generated files, turns per tier, effort used.
Needs an eval run ($3 per 28 prompts, `eval/run_eval.py`; use `sets/coverage.jsonl` for per-archetype recipe A/B): L0, L1, L2, L6, L10, L12. Pass bar from v6: all succeed, first try not below baseline, runtime checks 13/13, refusals 2/2; add: cost per success and turns per build, split by archetype.
Needs real traffic: starter-bank hit rate, recipe hit rate, cache warmth.

## 9. Legal / privacy

- Recipes and NxKit are authored by Nxeon from our own work: BF technique ids, our golden plugins, failure rules, javap-verified Paper API facts, NxPerf. Each recipe carries provenance and passes a similarity gate against the private reference corpus and every stored user build (n-gram overlap must be ~0). Nothing is taken from a user's mod, an imported mod, or the Modrinth reference corpus (BA: private analysis only).
- Only anonymized outcome data is learned from by default (BK export: counts, lane, tier, model, effort, result, fix ids; no text, names, ids, code). Archetype ids are derived from the guard/planner output, not stored text.
- Sharing a user's mod as a template stays separate and opt-in. The starter bank is built by staff from template prompts we wrote. `MB_DEDUPE` must not serve one user's source to another.

## 10. Open data gaps

One user, 28 builds; no token counts in `ModBuild`; no designer-lane cost data; no public hit rates; thinking share inferred from time and cost; the CLI's default effort and tool-definition size are U; the build VM's current env is unreadable (assume defaults).

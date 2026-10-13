# Cyrus token-efficiency baseline

Generated 2026-10-12T07:18:05.480Z. Source: ModBuild table, read-only SELECT. Read-only; no prompt, sheet, route or flag was changed. 27 builds, 2026-10-06 to 2026-10-12, total spend $6.51 (about 3,253 Cyrus tokens at $0.002).

**Read this first.** The sample is small (27 builds, all from the owner) and the stored records have cost and turns per AI call but **no token counts**. Savings below are ESTIMATES with stated assumptions; the ranking is for deciding what to measure and try next, not a forecast.

## Headline

- 24/27 builds succeeded; 18 were "kept" successes (not followed by another change within 30 min and not a major regression). Cost per success $0.271; cost per kept success $0.362.
- **Wasted spend**: $1.47 (23% of all spend) went on 4 build(s) the owner followed with another change within 30 minutes; $1.30 on builds that dropped commands or most classes of the build they changed; $0.0080 on failed builds.
- Signals: 1 guard refusal(s), 1 interruption(s), 1 builder-unavailable, 2 Test Flight failure(s), 0 install failure(s) recorded, 1 major regression(s) vs the base build, 3 vs the last good build.

## Spend by call kind

| kind | calls | turns | spend | share | avg $/turn |
|---|---|---|---|---|---|
| change | 13 | 221 | $3.243 | 50% | $0.0147 |
| generate | 9 | 52 | $2.109 | 32% | $0.0406 |
| repair | 7 | 22 | $0.222 | 3% | $0.0101 |
| repair-asset | 2 | 5 | $0.215 | 3% | $0.0429 |
| guard | 18 | 18 | $0.078 | 1% | $0.0043 |

By model family of the CALL (a guard call is always Haiku) and kind:

| family/kind | calls | turns | spend | avg $/turn |
|---|---|---|---|---|
| sonnet/change | 6 | 94 | $2.189 | $0.0233 |
| opus/generate | 2 | 13 | $1.090 | $0.0839 |
| haiku/change | 7 | 127 | $1.054 | $0.0083 |
| sonnet/generate | 1 | 9 | $0.676 | $0.0751 |
| haiku/generate | 6 | 30 | $0.343 | $0.0114 |
| sonnet/repair-asset | 2 | 5 | $0.215 | $0.0429 |
| haiku/repair | 6 | 18 | $0.121 | $0.0067 |
| sonnet/repair | 1 | 4 | $0.101 | $0.0253 |
| haiku/guard | 18 | 18 | $0.078 | $0.0043 |

## Spend by tier, model family, route and lane

**Tier** (the customer's choice, Katara/Saka/Yakko):

| key | builds | succeeded | kept | reworked | spend | avg $ | avg turns | $ / success | $ / kept success |
|---|---|---|---|---|---|---|---|---|---|
| saka | 8 | 7 | 4 | 2 | $3.09 | $0.386 | 13.5 | $0.441 | $0.772 |
| katara | 14 | 13 | 10 | 2 | $1.68 | $0.120 | 12.8 | $0.129 | $0.168 |
| yakko | 3 | 2 | 2 | 0 | $1.10 | $0.367 | 4.3 | $0.550 | $0.550 |
| unknown | 2 | 2 | 2 | 0 | $0.64 | $0.321 | 0 | $0.321 | $0.321 |

**Model family** actually called:

| key | builds | succeeded | kept | reworked | spend | avg $ | avg turns | $ / success | $ / kept success |
|---|---|---|---|---|---|---|---|---|---|
| sonnet | 7 | 7 | 4 | 2 | $3.09 | $0.441 | 15.4 | $0.441 | $0.771 |
| haiku | 13 | 13 | 10 | 2 | $1.68 | $0.129 | 13.8 | $0.129 | $0.168 |
| opus | 2 | 2 | 2 | 0 | $1.09 | $0.547 | 6.5 | $0.547 | $0.547 |
| unknown | 5 | 2 | 2 | 0 | $0.65 | $0.130 | 0 | $0.325 | $0.325 |

**Route** (router class of the build; "none" = old builds before routing was stored):

| key | builds | succeeded | kept | reworked | spend | avg $ | avg turns | $ / success | $ / kept success |
|---|---|---|---|---|---|---|---|---|---|
| saka | 7 | 7 | 4 | 2 | $3.09 | $0.441 | 15.4 | $0.441 | $0.771 |
| katara | 13 | 13 | 10 | 2 | $1.68 | $0.129 | 13.8 | $0.129 | $0.168 |
| yakko | 3 | 2 | 2 | 0 | $1.10 | $0.367 | 4.3 | $0.550 | $0.550 |
| none | 4 | 2 | 2 | 0 | $0.64 | $0.161 | 0 | $0.322 | $0.322 |

**Lane** (planned lanes; "plain" = no planner lane stored, i.e. a plain plugin or a build before the planner):

| key | builds | succeeded | kept | reworked | spend | avg $ | avg turns | $ / success | $ / kept success |
|---|---|---|---|---|---|---|---|---|---|
| plain | 23 | 21 | 18 | 3 | $5.20 | $0.226 | 10 | $0.248 | $0.289 |
| config | 3 | 2 | 0 | 0 | $0.66 | $0.219 | 12.7 | $0.328 | - |
| config+designItem | 1 | 1 | 0 | 1 | $0.65 | $0.648 | 31 | $0.648 | - |

**Fresh vs change builds:**

| key | builds | succeeded | kept | reworked | spend | avg $ | avg turns | $ / success | $ / kept success |
|---|---|---|---|---|---|---|---|---|---|
| change | 15 | 13 | 8 | 3 | $3.54 | $0.236 | 15.3 | $0.272 | $0.443 |
| fresh | 12 | 11 | 10 | 1 | $2.97 | $0.247 | 5.8 | $0.270 | $0.297 |

## Turns per build

"Turns" is the CLI's num_turns summed over the non-guard calls. It tracks tool round trips (reads + writes + edits + about 2), not API requests.

| kind | family | builds | min turns | median | max | avg $ | $ / turn |
|---|---|---|---|---|---|---|---|
| fresh | haiku | 6 | 4 | 7 | 14 | $0.092 | $0.0115 |
| fresh | sonnet | 1 | 9 | 9 | 9 | $0.676 | $0.0751 |
| fresh | opus | 2 | 6 | 6.5 | 7 | $0.547 | $0.0842 |
| change | haiku | 7 | 12 | 18 | 28 | $0.161 | $0.0086 |
| change | sonnet | 6 | 3 | 16.5 | 31 | $0.402 | $0.0243 |

Wall time by stage from the stored events (builds with events only; planning includes the model's thinking before its first edit): planning 51%, coding 40%, compiling 1%, repairing 9%.

## The Haiku change builds

| build | change turns | all turns | $ | seconds | outcome | reworked | vs base | vs last good |
|---|---|---|---|---|---|---|---|---|
| mb6670bd9d49 | 17 | 19 | $0.159 | 155 | success | no | none | none |
| mb647cba1248 | 20 | 20 | $0.144 | 118 | success | no | none | - |
| mbc8f20401f1 | 17 | 17 | $0.159 | 134 | success | no | none | none |
| mb16743f7a98 | 17 | 17 | $0.108 | 90 | success | no | minor | minor |
| mb062abeb8cd | 26 | 28 | $0.265 | 184 | success | yes (5.1 min) | none | none |
| mbcbf26ce7c7 | 12 | 12 | $0.082 | 73 | success | no | none | none |
| mb3445257a24 | 18 | 18 | $0.212 | 184 | success | no | minor | major |

**mb3445257a24: 18 change turns, $0.212, 184 s on Haiku, and it dropped 3 command(s) and 5 of the 5 classes of the last good build.** Per turn Haiku is cheap ($0.0118), but a Sonnet change build averaged $0.402 and this saving bought a mod the owner then had to rebuild.

Haiku change builds averaged 18.1 change turns and $0.161; the Sonnet ones 15.7 turns.

## Wasted spend (re-requested within 30 minutes)

| build | tier | $ | followed by | after (min) | relation |
|---|---|---|---|---|---|
| mb3b70795b7f | katara | $0.133 | mb647cba1248 | 4.7 | base |
| mb062abeb8cd | katara | $0.265 | mbcbf26ce7c7 | 5.1 | base |
| mb7e414f0c2f | saka | $0.428 | mbc0fb90e73f | 19 | base |
| mb972fd8f1e2 | saka | $0.648 | mb3445257a24 | 9.5 | base |

A follow-up is not always a redo (a new feature request also counts), so treat this as an upper bound of waste; the mining job separates corrections by wording only when the operator passes the request text.

## Data gaps that limit learning

- **No token counts are stored** in ModBuild (the build service records them in `aiCalls[].tokens` / `turnsDetail`, but `toResult` in lib/modbuilder/store.ts drops them). With `CYRUS_LEARNING` on, the portal keeps them for new builds; until then the per-turn cache read / write / output split is the 0.5 analysis (output 61%, cache writes 33%, cache reads 6% on fresh Sonnet builds), not measured on these builds.
- No compiler or repair error TEXT is stored for successful builds (only counts), so failure-rule mining has little to cluster; the repair log lives on the build service.
- No install FAILURE is stored (`lastInstall` is written on success only), no in-game player report, no "owner kept using it" signal: the 30-minute rework window is the only quality signal available for successes.
- 2 Test Flight failure(s) are builds whose stored verdict is "failed" while every recorded check passed (early gate versions): treat as legacy.

## Levers, ranked

Score = mid saving divided by a risk weight (low 1, medium 1.6, high 3). Saving ranges are USD over this 27-build sample ($6.51); percentages are of total spend.

| # | lever | risk | confidence | affected $ | saving $ (low-high) | % of spend (mid) | score |
|---|---|---|---|---|---|---|---|
| 1 | Run the Saka tier on Sonnet 5.5 | medium | medium | $3.09 | $1.08 - $1.54 | 20% | 0.820 |
| 2 | Regression guard on change builds (a lost command or most of the classes triggers one repair turn or a warning) | low | medium | $1.30 | $0.52 - $1.04 | 12% | 0.781 |
| 3 | Several edits per response on change builds (fewer, fuller turns) | low | low | $3.24 | $0.32 - $0.65 | 7% | 0.486 |
| 4 | Medium thinking effort on Sonnet and Opus builds | medium | low | $4.18 | $0.42 - $0.84 | 10% | 0.392 |
| 5 | Cut re-requests with a change summary and a keep/remove check before building | low | low | $1.47 | $0.22 - $0.52 | 6% | 0.369 |
| 6 | Retry caps on repairs (asset repairs especially) | low | low | $0.44 | $0.07 - $0.17 | 2% | 0.120 |
| 7 | Route floor: a change to a large or designer plugin never runs on Haiku | low | low | $0.21 | $0.02 - $0.13 | 1% | 0.075 |
| 8 | Smaller version sheets per lane | high | medium | $0.29 | $0.09 - $0.14 | 2% | 0.038 |

### 1. Run the Saka tier on Sonnet 5.5
- Change: service env MB_TIER_SAKA=claude-sonnet-5-5 (owner decision; eval first)
- Basis: Measured on fresh builds in the 0.3 eval (same 28 prompts: -49% cost, first try 93% to 100%). Change builds were not measured; the low end assumes they save less.

### 2. Regression guard on change builds (a lost command or most of the classes triggers one repair turn or a warning)
- Change: build service / portal check using lib/cyrus/learning/surface.ts; behind a flag (branch fix/cyrus-change-regression-guards)
- Basis: 3 build(s) removed a command or most classes of their base or of the last good build. A repair turn costs a fraction of a whole rebuild (a normal repair is $0.01-$0.04).

### 3. Several edits per response on change builds (fewer, fuller turns)
- Change: service prompt (owner + eval); the 0.5 prompt already asks for several edits per response, the event spacing suggests change builds still edit one file per request
- Basis: Change builds averaged 14.7 turns against 6.4 for fresh builds, and 7.7 edit/write events each, 6.7 of which arrived >= 2 s after the previous event (a model request of their own; reads arrive in bursts, so they are already batched). The 10-20% range is the efficiency note's estimate for the tiers when batching is followed; num_turns tracks tool round trips, so the true API request count is not stored.

### 4. Medium thinking effort on Sonnet and Opus builds
- Change: service env MB_EFFORT=medium (same value on every call of a build; owner decision; eval first)
- Basis: Thinking is 37-77% of output on these tiers (efficiency analysis). The range assumes medium effort halves part of it. Quality impact unmeasured.

### 5. Cut re-requests with a change summary and a keep/remove check before building
- Change: portal: show 'what stays, what goes' for change requests; planner prompt coach (off-by-default flag)
- Basis: 4 build(s) were followed by another change within the rework window; their spend is the pool. The 15-35% prevention rate is an assumption (no experiment yet).

### Lower ranked

- **Retry caps on repairs (asset repairs especially)** (risk low, $0.07 - $0.17): Repairs are 7% of spend; the repair-asset call of the Spawner Wand build cost $0.18 for 3 turns. The 0.5 service already caps repair turns at 25.
- **Route floor: a change to a large or designer plugin never runs on Haiku** (risk low, $0.02 - $0.13): 1 Haiku change build(s) touched a plugin with >= 10 classes or a planned lane; $0.21 of them was wasted (reworked or regressed); running them on Sonnet costs about $0.19 more. A blanket floor on all 7 Haiku change builds would cost about $1.68 more and is NOT recommended on this sample.
- **Smaller version sheets per lane** (risk high, $0.09 - $0.14): The sheet is about 6218 tokens, already cached; this is its cache-read cost over every non-guard turn. Slicing it varies the cached prefix (cache writes cost 12-20x a read).

## Method and assumptions

- Signals: lib/cyrus/learning (rework = the next change of the same lineage, building on this build or its base, starting within 30 minutes of this build ending; regression = the build lost commands / sub-commands, or half its base's classes, or the lineage's last good build did; kept = succeeded, not reworked, no major regression).
- Class / command / config-key sets come from the stored result (`files`, `commands`, `config`). The stored `config` list can be shorter than the real config.yml, so a config-key loss alone is only "minor" unless both sides come from jars.
- Cost is the build service's API-equivalent USD (the owner is on a subscription today). 1 Cyrus token = $0.002 (D-03).
- Prices used for the sheet lever: input $/M haiku 1, sonnet 2, opus 5; cache read 0.1x; sheet 6218 tokens (24873 bytes / 4).

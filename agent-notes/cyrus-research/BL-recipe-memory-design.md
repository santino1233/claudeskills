# BL: Recipe memory ("learned paths") design (2026-10-12)

Short design. Context: `BL-token-savings-plan.md` (lever L2, backlog B6/B7), `BK-learning-loop.md` (signals, anonymized export, mining), `BF-mc-technique-catalogue.md` (seed material). V = verified in code/data, U = estimate.

## 1. What it is, in one paragraph

A **recipe** is a small, verified, generic implementation pattern for one mechanic (for example "per-player home store with permission-based limit and safe async teleport"), written by us. At plan time Cyrus picks the matching recipe with a cheap lookup and injects only that recipe into the build's first user turn. A **path memory** table records, per archetype, which lane / tier / effort / recipe actually worked and what it cost, learned from anonymized outcomes, and feeds the plan-screen estimate and the router. Neither one ever contains or is derived from a user's code, an imported mod, or the Modrinth reference corpus.

## 2. Recipe schema (JSON next to the build service, like `rules/failure-rules.json`)

```
services/modbuilder/recipes/<id>.json
{
  "id": "homes-store",
  "version": 3,                       // part of knowledgeVersion() and the dedupe key
  "archetypes": ["homes", "warps"],   // ids from lib/cyrus/adapters/minecraft-coverage.json
  "lanes": ["plugin", "config"],
  "mcVersions": ["1.21.1","1.21.4","1.21.8","1.21.11"],
  "title": "...", "summary": "<= 3 sentences, what the mechanic is",
  "pattern": "<= 600 tokens of prose + at most 40 lines of skeleton, only for the tricky parts",
  "configSchema": [{key, type, default, min, max, why}],   // the keys a mod of this kind should expose
  "paperFacts": ["World#getChunkAtAsync", "Entity#teleportAsync"],  // javap-checked per version
  "pitfalls": [{"ruleId": "ondisable-sync-save", "note": "..."}],   // links to failure-rules.json + BF gotchas
  "boundedWork": "<how NxPerf budgets apply, or 'none'>",
  "tests": "golden/plugins/mc-homes/golden.json",                     // RCON expectations, already exist for 54 archetypes
  "provenance": {"author": "nxeon", "sources": ["BF:plg-safe-teleport-async","golden:mc-homes","rule:ondisable-sync-save"],
                 "noUserCode": true, "noReferenceCorpusCode": true, "reviewedBy": "...", "reviewedAt": "2026-10-.."},
  "stats": {"n": 0, "withRecipe": {...}, "without": {...}},          // filled by the eval, not by hand
  "status": "draft|verified|retired"
}
```

Seed set (all ours): the 33 BF `plugin` techniques with `gotchas` and effort S (safe teleport, teleport warmup/cooldown, config snapshot reload, chest-GUI anti-dupe, ondisable sync save, async chat renderer, playermove filter, hologram text display, per-player FX with reconcile), the bounded-work pattern from NxPerf (perf rule 10), the 54 golden plugins that already map to archetypes (V: 54 of the 63 plain archetypes have a golden), and the 33 failure rules. A recipe is the *explanation + skeleton* of a golden, not a copy of any third-party plugin. Start with 8-12; add by demand from the mining job.

## 3. Selection at plan time (no extra model call)

1. **Free:** the existing intake guard (Haiku, 1 turn, already run on every build, replaces the classifier, V `route.js`) also returns up to 2 archetype ids from the closed list of 85 (about +10 output tokens). Prompt change in `GUARD_PROMPT`/`parseGuard`; unknown ids are dropped.
2. **Fallback / cross-check:** a deterministic scorer over the same 85 rows (label, category, technique words, template tags; there is already a keyword rule set in `lib/cyrus/planner/rules.ts` and a trigram helper `lib/cyrus/prompt-trigrams.ts`). If the guard's id and the scorer agree, confidence high; if only one fires, inject only when the recipe `status` is verified and the match score passes a threshold; otherwise inject nothing. A wrong recipe is worse than none.
3. **Never** inject for: change builds without a mapped archetype, imported mods, refused requests. For a change build, use the base build's recorded recipe id (anonymous metadata we store ourselves), not a fresh match.
4. Result is recorded on the build (`recipeId`, `recipeVersion`, `matchSource`) so the cost effect is measurable.

## 4. Injection (cache-safe, small)

Goes into the first user turn next to `planBlock()` (V: `prompts.js`), NOT the system prompt, so the cached base prefix stays byte-identical:

```
TESTED PATTERN for this kind of mod (follow it unless the request needs something else): <title>
<pattern prose + skeleton> / Settings to expose: ... / Known pitfalls: ...
```

Cost model (U): 600-900 tokens injected = about $0.005-0.008 on Sonnet (one cache write plus ~9 reads); it pays for itself if it removes 700 output tokens of design thinking or one repair turn ($0.010-0.04). Budget cap: 900 tokens per recipe, one recipe per build (two only if they share no pitfalls).

## 5. Path memory (archetype -> best path -> expected cost)

Table built weekly by the learning job (B7), from `BuildSignals` (rework, regression, outcome, cost, turns, effort, model, recipe id, repairs, autofix ids, failure-rule ids):

```
key: (archetypeSet, laneSet, tier, fresh|change)
value: { n, successRate, keptRate, costUsd {p25,p50,p90}, turns p50, repairs p50,
         bestEffort, bestRecipeId, recipeEffect {ratio, ci, n}, lastUpdated }
```

Rules: a cell is shown or used only with n >= 8 (shrink toward the prior `BASE` table below that); "best" = highest keptRate among options with n >= 5, ties by lower p50 cost; a path with one rework in the last 5 is demoted. Used for: (a) plan-screen estimate (typical / up to), (b) default effort and tier suggestion for that archetype (suggestion only, the customer still picks the tier), (c) recipe A/B bookkeeping (`recipeEffect`), (d) the admin Learning tab. It changes nothing automatically: new defaults ship as engine releases through `release-manifest.ts` with an eval gate (BK).

## 6. Learning from outcomes (and what is never learned)

Learned (anonymized, default on, no request text): archetype ids, lanes, tier, model, effort, recipe id, turns, cost, success / kept / rework / regression flags, repair count, **normalized failure signatures** (javac error class plus the Paper API symbol only when it appears in the version's API index; rule ids; autofix ids), and which repair resolved which signature.
Mined into **candidates** (never auto-applied, same as BK): `recipe-pitfall` (signature X recurred in 3+ builds of archetype A without a rule -> propose a pitfall line or failure rule), `path-stat` (a lane/effort combination beats the default), `recipe-gap` (archetype with no recipe and p50 cost above its tier's median -> author one).
Never learned: any user text, class or command names, config contents, code, imported mods, Modrinth corpus code. Recipes are authored and reviewed by us from our own goldens, BF technique ids and javap facts; the mining job only changes *which* of our recipes is chosen and *which pitfall we add*, never the content from a user's work. Template sharing of a user's mod is separate and opt-in (D-60 / D-61 wording).

## 7. Gates before any recipe ships

1. `tools/recipes/lint.ts`: schema, provenance present, every `paperFacts` symbol exists in all listed version jars (javap, as `gen-sheets.py` does), every `pitfalls.ruleId` exists.
2. **Similarity gate:** 8-gram shingle overlap of pattern + skeleton against (a) the private reference corpus index (`/tank/cyrus-library-staging/_reference-mods`, private, offline only) and (b) every stored user build source: must be about 0; a hit blocks the recipe.
3. Golden test: the linked `golden.json` flies green on all four versions.
4. Eval: 2 runs of the archetype's coverage prompts with and without the recipe (about $0.3 per archetype per run on Sonnet 5.5). Ship only if success and first-try are not lower, runtime checks pass, and cost per success is lower or equal (record `recipeEffect`).
5. Rollback: flag `CYRUS_RECIPES` / `MB_RECIPES` off = prompt byte-identical to today (tested).

## 8. Plan-screen implications

- Estimate = path-memory cell (typical / likely max, sample size) x measured `recipeEffect` only when n >= 8; otherwise the plain number plus a badge "tested pattern: usually fewer fixes", no discount. After Saka -> 5.5 and effort routing the cells reset, so `stats` must record the engine release.
- A recipe is a chip the user can see and turn off ("Using the tested Homes pattern"), because it can change the result's shape; off = free-form build and the estimate reverts.
- Identical template-chip prompts can offer the **starter bank** line instead (instant, about 5 tokens), which is the zero-model end of the same idea.

## 9. Rollout

B6 seed 8 recipes + guard archetype ids + injection behind flags (owner/preview accounts first); B1/B7 capture and path memory run in parallel (read-only); eval per recipe; widen to the 54 goldens by mined demand; later NxKit (backlog B9) so recipes call tested helpers instead of carrying skeletons. Expected effect (U): 15-35% per hit build, hit rate 35-55% of plain builds, so 5-19% of spend; the owner's own 13 root prompts would have hit a recipe 3-6 times.

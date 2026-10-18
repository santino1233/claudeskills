# EH: Cyrus Wizard, studio-first mode and asset composition (design, 2026-10-18, Opus)

Owner request (condensed): Cyrus improvises and spends tokens on things nobody asked for. A broad prompt ("make me a cool boss", "a texture pack") may get creative latitude; a SPECIFIC prompt must be built exactly, nothing extra. Replace today's plan-screen checkboxes with a real WIZARD that merges the prompt coach (questions with options, improved prompt, "how far do you want to go", pick what to include), shows a PROPER PLAN before any spend, with an estimate that is actually right. Users who want ONE thing (a schematic, a texture, a sound) should not pay for the mod pipeline. Plans should reuse assets from My Assets and the community library. Some users only want structures for offline Minecraft.

Status: DESIGN + DATA + MOCKUPS + BUILD PLAN. No feature code, no builds, no flags, no model spend. Read-only production SELECTs only (helper prints no secrets). Analysis scripts lived in the session scratchpad (method in the appendix).

**Caveat on all data: every one of the 124 portal ModBuild rows (2026-10-06..10-18, $155.31) belongs to ONE account (the owner).** 101 of them carry a recorded plan; 63 are refines of the Infinite Dungeon. The eval journals (/root/cyrus-eval, 303 costed builds) are fresh builds from the real-world prompt corpus. Small n, one user's style: treat the numbers as direction, not as a population.

---

## 0. TL;DR

- **Improvisation is real and concentrated on short fresh prompts.** Fresh builds that went through the planner: 15 of 21 plans (71%) switched on at least one lane the request did not ask for; 10 of 15 succeeded fresh builds (67%) shipped unrequested scope (extra items, sounds, data packs, commands; worst: a recipe mod that also shipped `/home /sethome /delhome /homes`). Estimated cost of that scope: ~$1.3 of $11.8 (11%) on those builds, plus the visible incidents (ChunkMirror Spawner Wand chain $1.30, six refines that only re-fixed silent regressions $3.35). Today's planner policy (tracker 114) would already remove 11 of the 15 extra lanes, but nothing checks what the model adds INSIDE a lane (items, commands, sounds a creature lane auto-adds), and nothing checks the output against the plan.
- **Estimates are ~2x low, ~3-4x on the tail.** Replaying the live plan-screen estimate (CYRUS_HONEST_ESTIMATE off, as in production) on 106 costed portal builds: real cost is a median **1.94x the TOP of the range shown** (p80 3.15x); only **11%** landed inside the range; **74% cost more than the "up to"**. Refines: **2.2x** (p80 3.7x). 68 of 101 holds were exceeded (median charge 1.36x the hold; Saka 1.72x). The honest-estimate flag over-corrects (2x too high on the dungeon, it reads the whole mod prompt as "mega"). A calibrated replay (same-mod history, else mod-size bin, else lane class; online, no look-ahead) puts 51% inside a 1.9x-wide range with median real/top 0.69 (p80 1.11).
- **The biggest waste is not improvisation but the wrong pipeline for the job**: 35 failed builds cost $51.24 (33% of all spend); the three boss-arena refines that asked the mod pipeline for ROOMS failed on budget for $10.65, while the Room Studio does one room for a 60-token ($0.12) hold.
- **Recommendation:** (A) a one-sheet Cyrus Wizard whose output is a machine-checkable SCOPE CONTRACT that the build service enforces in the prompt AND verifies after the build (extras stripped for free, or the build fails free); (B) every studio is a first-class entry point over the SAME core, with its own asset space and a single-lane job path that never starts the mod pipeline; outputs land in My Assets with real downloads; (C) plans reference assets by content hash (`asset:`/`cat:`), checked for version/format compatibility, so reused assets are never regenerated; (D) an estimate table learned nightly from real builds, snapshotted on every build so its error is measured, not replayed.

---

## 1. Data

### 1.1 Method
- Rows: `ModBuild` (prompt, changeRequest, baseBuildId, costUsd, status, `cyrus.assets.planned.lanes` = the plan the user confirmed, `cyrus.assets.*.route` = keyword routes, `result.commands/config/files/assets/ledger/preservation/ai.calls`) joined to `CyrusTokenReservation` (hold `amount`, `charged`).
- "Asked" = the deterministic word rules (`lib/cyrus/planner/rules.ts ruleNeeds`) on the request text (the change text for refines). Rules recall is ~81-97% (tracker 114), so every lane flagged "unasked" was then checked by hand against the prompt; the hand-checked list is in 1.2.
- "Delivered" = asset kinds in `result.assets` / `result.files` that were NOT already in the base build.
- Policy replay = `mergeNeeds(recordedPlan, text)` with today's policy layer.
- Estimate replay = `planEstimate(text, model, plannedLanes, {change, honest})` from main (af5a1d55) vs `costUsd`; no estimate is stored on the build today (gap, see D).

### 1.2 Improvisation: asked vs built

| set | n | plan had an unasked lane | after today's policy | succeeded builds that shipped unasked scope |
|---|---|---|---|---|
| fresh builds with a recorded plan (10-12..10-15) | 21 | **15 (71%)** | 4 (sound x3, texture x1) | **10 of 15 (67%)** (hand-checked) |
| refines with a recorded plan | 80 | 3 (4%) | 1 | 2 of 53 (Spawner Wand design; creature lane auto-sounds) |

Hand-checked unrequested scope on succeeded fresh builds (cost = whole build; "extra" = est. share via lane weights):

| build | request (short) | unrequested scope that shipped | build $ | est. extra $ |
|---|---|---|---|---|
| mbe79464c59f | custom crafting recipes (saddle, diamonds, name tags) | `/home /sethome /delhome /homes` (a homes system) | 0.52 | ~0.13 |
| mb8710c52c0f | mushroom-meadow biome flavour, loot tables | 3 textures, 3 custom items (moonpetal, starlight...), `/meadow give/tp/locate` | 0.84 | ~0.15 |
| mb7714738f12 | goblin mob that steals chest loot, with a texture | `goblin_tooth` item design, 6 sounds | 1.04 | ~0.18 |
| mb0d8ad449db | fox companion, tameable with sweet berries | `fox_treat` custom item (replaces the berries the user named), 7 sounds | 0.98 | ~0.17 |
| mb6d31dce764 | Hollow King boss, minions, texture, boss bar | `hollow_crown` item, a sound, 60 config keys | 1.24 | ~0.19 |
| mb1b6e3ab535 | Stormcaller armor set + set bonus | sound set, a data pack | 0.61 | ~0.12 |
| mb871ce79b62 | golden stew + night-owl potion | 2 sounds | 1.13 | ~0.14 |
| mb49b1972251 | magic wand, 4 spells, mana bar | 4 sounds | 0.83 | ~0.10 |
| mb40f9b72699 | fire sword, 3 abilities, particles + sounds | a HUD lane + `hud toggle` command | 0.81 | ~0.05 |
| mbeca427b3f1 | daily quests + login reward | a data pack | 0.82 | ~0.08 |
| | | **10 of 15** | **8.82** | **~1.3 (11% of $11.8)** |

Clean: ChunkDup (a fully specified prompt, coach "great 100"), Ruby Sword (recipe + drop asked: the data pack was right), /shop, economy tweak, Infinite Dungeon v1. **Pattern: the long, specific prompts were built as asked; the 15-30 word prompts were filled in by the model.** That is the right instinct for "make me a cool boss" and the wrong one for "craft a saddle from leather".

Also improvisation, not lane-level:
- **Admin scaffolding**: every designer build adds `/x give|list|params|reload` (6 of 15). Useful, but never asked; the plan should show it as one "Admin basics" line the user can switch off.
- **Keyword routes outside the plan**: the room lane switched on for a text-only refine because the mod is a "dungeon" (CK F5, mb4dd63cd376); the designer route was on for 4 builds with no design lane planned ($0.91, incl. the ChunkMirror chain).
- **Refines that change what was not asked**: silent config drift (max-floors back to 100 twice), lost BetterModel wiring (CK rounds 4-6). Six refines whose only purpose was re-fixing a regression: $3.35 (mb3445257a, mb819b7d4e, mb51322a365e, mba4f28ee40, mbf8812bb24, mb4dd63cd376). The preserve guard (pv-2026-10-17) now reports "clean" 10/10 (CK F12): keep it, the contract builds on it.
- **ChunkMirror Spawner Wand** (tracker 58b): "mob spawners need to mirror the mobs" -> planner chose "Item with abilities" -> a Spawner Wand replaced the plugin; that build + the two repair refines = $1.30. `changeLaneDefaults` (coach) now stops that one lane case; the scope check in A.6 is what stops the general case.

### 1.3 Estimate error

Live plan-screen estimate vs real (106 portal builds with cost > $0.02):

| slice | n | real $ p50 | top of range shown p50 | **real / top** p50 (p80) | inside range | above "up to" | charge / hold p50 (over) |
|---|---|---|---|---|---|---|---|
| all | 106 | 1.08 | 0.50 | **1.94 (3.15)** | 12 (11%) | 78 (74%) | 1.36 (68 of 101) |
| fresh | 28 | 0.61 | 0.45 | 1.35 (1.76) | 6 | 16 | 1.02 (13 of 25) |
| refines | 78 | 1.64 | 0.50 | **2.20 (3.73)** | 6 | 62 | 1.59 (55 of 76) |
| Saka | 67 | 1.02 | 0.46 | 2.36 (3.92) | 5 | 56 | 1.72 (51 of 63) |
| creature lane | 27 | 1.74 | 0.69 | 1.94 (3.08) | 2 | 20 | 1.53 |

- **Honest estimate (flag off in prod)**: inside 30 of 106 (28%), but real/top 0.53: on refines it scores the full mod prompt ("mega" class, top $2.50); scored on the change text alone it is 1.26x low on refines. It moved the error, it did not remove it.
- **Eval (fresh builds, no guard/plan passes, 303 rows)**: real/top 0.68 median but only 34% inside the range: the range is too NARROW and wrong in both directions (creature 2.22x low, designer 0.44x high).
- **What drives cost** (portal, succeeded refines): base mod size. Base < 30 KB Java: p50 $0.21 (p85 0.51); >= 100 KB: p50 $1.45 (p85 2.52). Repairs are 26.4% of refine spend. EA: a refine call is 30-38 requests each re-reading ~110k tokens of context; cost = requests x context.
- **Calibrated replay** (online: same-mod last 6 refines if >= 3, else size bin, else lane class; range p20..p85): 88 builds, **51% inside**, real/top p50 **0.69**, p80 **1.11**, width 1.9x. That is the shape to build (D).
- **The estimate is not recorded on the build.** Every number above is a replay of today's code. D.4 fixes that first.

### 1.4 Wrong-pipeline cost
- 35 failed builds: $51.24 = 33% of all spend (bundle B's CYRUS_TOK_SETTLE_V2 makes our failures free for the customer; Nxeon still pays).
- Boss arenas asked of the mod pipeline (mbbdd03d8b3, mb6789c5567, mb65b599734): 3 failures, $10.65 (+ one "lost" orphan $1.33 unbilled). Room Studio: one room per job, 60-token hold ($0.12), deterministic re-roll/kit swap/edits free. That is the studio-first argument in one line.

### 1.5 Specificity can be decided without a model (prototype)
A pure classifier (numbers, named commands, a name, explicit asset asks, rule clauses "when/every time/drops/spawns", constraint words "only/exactly/nothing else", length; broad markers "cool/epic/random mod", "surprise me", "you decide", collections "texture pack"):

| corpus | n | specific | open (short, no rule) | broad (latitude asked) | unclear |
|---|---|---|---|---|---|
| real-world-v1 (eval corpus) | 80 | 40 | 12 | 3 | 25 (31%) |
| portal fresh | 33 | 22 | 2 | 3 | 6 |
| portal refines | 91 | 79 | 1 | 7 | 4 |

69% of real-world prompts and 96% of refines are decided deterministically. Known misses to fix before shipping: "random" used as a behaviour ("random coloured wool") and "anything" ("do anything at all") read as broad; very short concrete rules ("creepers drop a diamond") land in unclear. The production classifier also uses the coach's critical gaps (a short rule with no critical gap is specific). "Unclear" does NOT need a model call: it gets the extent question with "A little polish" preselected.

---

## 2. What exists (reused, not rebuilt)

| piece | where | role in this design |
|---|---|---|
| Planner (Haiku call + word rules + policy layer) | `lib/cyrus/planner/{run,rules,policy,decide}.ts`, `services/modbuilder/planner.js` | intent + lanes; extended to return specificity + questions in the SAME call |
| Prompt coach (live, `CYRUS_PROMPT_COACH=1`) | `lib/cyrus/coach/*` | gap questions with chip inputs + defaults, compiler, change "what stays" |
| Plan screen | `components/cyrus/prompt/PlanSheet.tsx`, `PromptCoach.tsx`, `components/cyrus/app/NewModFlow.tsx` | replaced by the wizard sheet behind a flag |
| Estimates | `lib/cyrus/estimate.ts`, `planner/estimate.ts`, `planner/honest.ts`, `tokens/builds.ts gateBuild/holdRange` | replaced by the learned table (D); hold follows it |
| Requirements ledger, lane gaps, preserve guard | `services/modbuilder/{ledger,lanegaps,preserve}.js` | ledger = contract requirements; lanegaps = "planned but missing"; preserve = "unchanged" invariants; the new scope check is their mirror image ("built but not planned") |
| ModSpec v1 | `lib/cyrus/engine-core/spec.ts` | `requirements[]` (REQ-n must/should/could) and asset slots with `source: generate/library/existing` + `libraryRef: cat:<sha>`: the contract's vocabulary already exists |
| Room Studio + exports + public builder | `lib/cyrus/structures/studio/*` (`CYRUS_ROOM_STUDIO=1` live), `lib/cyrus/public-builder/schematic.ts` (DZ, unmerged) | the template for every studio-first job: spec -> deterministic compile, hold, measured charge, .schem/.litematic/.nbt |
| Library + catalogue | `lib/cyrus/library/{v2,backend,publish}` (backend + browse ON in prod), `use-in-project.ts`, `assets/catalogue.ts` (My Assets) | composition sources; opt-out publishing (default publish) already coded |
| Learning loop (`CYRUS_LEARNING=1`) | `lib/cyrus/learning/*`, per-call tokens on `result.ai.calls` | calibration input |

Not yet present: EE-cyrus-ux-audit-2026-10-18.md (UX audit agent still running): the navigation proposal in B.5 is written to fit a single left nav and must be reconciled with EE when it lands.

---

## A. The Cyrus Wizard

### A.1 Principles
1. **One sheet, progressive, defaults preselected.** Not a multi-page form (checkout research: field count matters more than page count; defaults are the strongest lever). A specific prompt goes prompt -> plan in one click; nothing is asked that the text already answers.
2. **The plan is the product.** What the user confirms is exactly what is built and charged; anything else is a defect we pay for.
3. **Warn, don't block** (D-62): the wizard never refuses a choice; it shows the consequence (tokens, lag, compatibility). Only security/legal/money/crash limits stay hard.
4. **Zero extra model calls** for the common path: classification and questions come from the deterministic coach + the planner call that already runs (~1 s, Haiku, Nxeon pays).

### A.2 Flow

```
prompt ─┬─> classify (deterministic; planner call adds a second opinion only for "unclear")
        │      intent: mod | single asset (-> offer the studio, B.4) | change to <mod>
        │      specificity: specific | open | broad | unclear
        ├─> questions (0 for specific; 2-6 chips with defaults otherwise; "Use defaults" skips)
        ├─> extent: Exactly this | A little polish | Go creative   (default from specificity)
        ├─> include: per lane, per asset slot: Generate | From my assets | From community | Off
        ├─> PLAN: ordered steps per lane, "Will not build", files/features, commands, reused assets
        ├─> ESTIMATE: typical range + "up to" + what moves it + based on n similar builds
        └─> Confirm  ->  SCOPE CONTRACT (hash) -> hold -> build service
```

| step | shown when | default | source |
|---|---|---|---|
| Classification chip ("Specific: built exactly as written") | always | n/a | `wizard/specificity.ts` (new, pure) |
| Questions | specificity != specific, or the coach has a critical gap (trigger, numbers, scope of a change) | coach `defaultAnswers` | `coach/analyze.ts questions` (3-6 already) capped at 6, ranked by gap weight |
| Improved prompt | after questions | collapsed "See the prompt Cyrus will use" | `coach/compile.ts` (deterministic; "Rewrite for me" stays optional) |
| Extent | always (one segmented control) | specific -> Exactly; open/unclear -> Polish; broad -> Creative | new |
| Include | always (collapsed to a summary line for specific prompts) | asked lanes on; unasked lanes listed under "Cyrus could also add" and OFF | planner lanes after policy; `changeLaneDefaults` for refines |
| Plan + Estimate | always | n/a | `wizard/plan-doc.ts` + estimate v2 |

Questions are never a long form: max 6, each a chip row with one preselected answer, a "Surprise me" chip where latitude makes sense (theme, look), and the token effect inline where an answer moves cost ("Custom animated model +~185 tokens").

### A.3 Extent semantics (the contract's `extent`)

| extent | what Cyrus may do | admin basics (`reload`, `give`) | config | unasked lanes | extras after build |
|---|---|---|---|---|---|
| **Exactly this** | build the listed requirements only; no new items, commands, lanes, sounds; numbers as given | off (one toggle) | only numbers the user named | none | stripped (free) or the build fails free |
| **A little polish** | requirements + small glue (feedback messages, sensible defaults, a `reload` command, config for named numbers) | on | named numbers + obvious tunables | none unless ticked | up to 3 small extras allowed, each listed as "Cyrus added" with one-click remove on the next refine (free) |
| **Go creative** | requirements + up to N creative additions (default 2 extra touches, max 1 extra lane) the plan names up front as "Cyrus may add..." | on | free | up to 1, budgeted in the estimate | listed; nothing stripped |

Broad prompts default to Creative; the plan still lists what the creative budget may be spent on and the estimate includes it. Exactly-this is the default for any prompt with a constraint word ("only", "nothing else") and for every refine classified specific.

### A.4 Plan document (what the user confirms)
Ordered, per lane, generated deterministically from the contract (no model call):
1. **Build steps** in order (e.g. "1 Plugin code: on creeper death, drop 1 diamond, chance 5% + 2% per Looting level"; "2 Settings: chance and Looting bonus in config.yml" only if on).
2. **Will NOT build**: every lane the planner considered and the user left off, plus the generic "no new commands, items or sounds" line in Exactly mode. This replaces today's "Not built as the request reads" notes and the "before you spend" capability lines (kept, merged into the same block).
3. **Files and features**: expected file groups (plugin code, `config.yml`, `assets/textures/<slot>`, data pack...), commands (exact list), permissions.
4. **Reused assets**: slot -> asset (thumbnail/audition, owner, licence tier, version pin, fit verdict).
5. **Refines**: "Changes" + "Stays the same" (ledger items + preserve invariants: commands, depend, config keys and defaults, wired creatures).
6. **Estimate** (D.5) and the hold.

### A.5 The SCOPE CONTRACT (`cyrus.contract.v1`)
Pure, client-safe builder in the portal (`lib/cyrus/wizard/contract.ts`), zod schema shared with the service bundle, stored on `ModBuild.cyrus.contract` and sent to the service as `contract` (absent = byte-identical request, flag off).

```jsonc
{
  "v": "cyrus.contract.v1",
  "hash": "sha256 of the canonical JSON",
  "kind": "new",                       // new | change
  "base": null,                        // change: { buildId, ledgerVersion, preserveVersion }
  "game": "minecraft", "version": "1.21.11", "tier": "saka",
  "extent": "exact",                   // exact | polish | creative
  "specificity": { "cls": "specific", "score": 6.5, "source": "rules" },
  "prompt": { "compiled": "...", "originalHash": "..." },
  "requirements": [                    // = ModSpec requirements + ledger ids
    { "id": "REQ-1", "text": "Creepers drop 1 diamond on death", "priority": "must", "lane": "code", "evidence": ["code"] },
    { "id": "REQ-2", "text": "Drop chance 5%, +2% per Looting level", "priority": "must", "lane": "code", "evidence": ["code"] }
  ],
  "lanes": { "allowed": ["code"], "forbidden": ["texture", "sound", "creature", "designItem", "designMenu", "designQuest", "designBoss", "designHud", "motion", "datapack", "worldgen", "rooms"] },
  "commands": { "policy": "listed", "allowed": [] },        // listed | listed+admin | free
  "config":   { "policy": "named", "keys": [] },            // named | tunables | free
  "assets": [                                               // per slot
    { "slot": "ruby_sword", "kind": "texture", "source": "library", "ref": "cat:9f…", "pin": "sha256:9f…", "fit": "good", "licence": "cc0" },
    { "slot": "frost_roar", "kind": "sound", "source": "mine", "ref": "asset:cpa_123@sha256:ab…" }
  ],
  "latitude": { "extraItems": 0, "extraLanes": 0, "extraCommands": 0 },
  "unchanged": ["command:dungeon", "config:max-floors=11", "depend:BetterModel"],   // change builds (ledger + preserve)
  "budget": { "tokens": [40, 135], "upTo": 195, "hold": 135, "table": "est-2026-10-19.1" }
}
```

### A.6 Enforcement (three layers, cheapest first)
1. **Routing (deterministic, before the model)**: the service only loads lane prompt sections, examples, MCP tools and generators for `lanes.allowed`. Keyword routes (`rooms.route`, `designer.route`, `config.route` templates, creature auto-sounds) are AND-ed with the contract: a forbidden lane is never routed. This alone removes the F5 room-lane case and the designer-route-without-plan case, at zero model cost.
2. **Prompt** (`services/modbuilder/prompts.js`, ~150-250 tokens, cached in the stable prefix): "BUILD ONLY THIS CONTRACT" block listing requirements, allowed commands, asset slots ("these files exist; reference them; do not create or redraw them"), and the Will-not-build list. On Exactly: "Do not add items, commands, sounds, lanes or settings that are not listed. If a requirement cannot be built without something unlisted, stop and say so in NOTES.md instead of adding it." Creative: "You may add up to N touches; list each under CREATIVE in NOTES.md."
3. **Post-build scope check** (`services/modbuilder/scope.js`, plain Node, no model, next to ledger/lanegaps/preserve). Diff the workspace against the contract:

| check | evidence | Exactly | Polish | Creative |
|---|---|---|---|---|
| asset files of a forbidden lane (`assets/sounds/*`, `assets/creatures/*`, `assets/datapacks/*`...) | file paths | **strip** (delete the files + their pack entries; deterministic) | strip | list |
| design items / menus / quests not in requirements (`assets/designs/*.json`) | design names vs requirement ids | **strip** + recompile (designer compile is deterministic, no model) | allow <= 3, listed | list |
| commands not in `commands.allowed` (`plugin.yml`) | yml | designer-generated: strip + recompile; hand-written Java: one targeted "remove these commands" repair under a $0.10 cap; else **fail free** | allow admin basics + 3 | list |
| config keys beyond `config.keys` | config schema | warn only (cheap, harmless) | allow | allow |
| reused slots regenerated (a `ref` slot rewritten) | sha256 of the slot file | **restore** the pinned bytes | restore | restore |
| change builds: `unchanged` items | ledger + preserve | existing preserve guard (restore or fail free) | same | same |

Every stripped or listed item is written to `result.scope` (`{ verdict: clean|stripped|listed|failed, items: [{kind, id, action, why}] }`), shown on the build page ("Cyrus removed 2 things you did not ask for"), counted in learning signals, and **the asset-repair calls spent on stripped files are not charged** (their `ai.calls` carry kind + file; settle subtracts them: bundle B's settle v2 is the hook). A build that cannot satisfy its own contract fails as `failed_ours` (free).

Why both prompt and check: the prompt prevents most extras (the model follows explicit lists far better than general advice; EA finding 6 shows general system-prompt advice is mostly ignored), the check makes the promise verifiable. Creative latitude exists only when the user chose it or the prompt is broad, and even then it is bounded and listed.

### A.7 Refines
- Classification on the change text only (`scoreText`); most refines are specific (79 of 91).
- Include defaults: no new lane unless the change text asks (existing `changeLaneDefaults`).
- "Stays the same" comes from the base build's ledger + preserve invariants and goes into `unchanged`.
- Scope check adds: files touched outside the change's footprint are reported (not stripped: refactors are legitimate), regressions use the preserve guard.

---

## B. Studio-first mode

### B.1 Recommendation: first-class entry points, ONE core, per-studio asset spaces
Not a separate interface (two products to design and keep in sync), not a separate core (duplicate jobs, billing and storage). Each studio is a top-level entry that opens on an **asset space**: a project of kind `assets` (no plugin, no jar, no build lane) in the existing engine-core store, so every output is an ordinary `CyrusProjectAsset` row that My Assets, the community pipeline and "use in project" already understand.

```
            ┌───────────── Cyrus core (one wallet, one asset store, one library, one guard) ─────────────┐
 Wizard ───>│ mod project  -> mod pipeline (planner, model build, compile, Test Flight)                   │
 Studios ──>│ asset space  -> single-lane job (spec by model -> deterministic compile) -> My Assets         │
            │              -> deterministic edits (free) -> downloads / "Add to a mod" -> Wizard (reuse)  │
            └─────────────────────────────────────────────────────────────────────────────────────────────┘
```

### B.2 The single-lane job path
Template: Room Studio (`structures/studio/jobs.ts` + service `room-studio.js`): model writes a SPEC (data, never code) -> deterministic generator -> quality rules -> preview -> hold settles at measured cost; empty result is free. New service endpoints with the same shape:

| studio | model writes | deterministic compile | exists today | new |
|---|---|---|---|---|
| Structure (Room) Studio | `cyrus.roomspec.v1` | compose/generate/markers/quality, exports .schem/.litematic/.nbt | yes, project-scoped + public builder (DZ, unmerged) | asset-space mount; Structure Studio v2 agent owns studio/* |
| Texture Studio | Texture DSL spec | `textures/render.ts`, quality rubric, Style DNA | editor + AI candidates, project-scoped | `/jobs/texture` standalone job; resource-pack download |
| Sound Studio | SoundSpec | `sound/render.ts` (node-2 relay), mono Ogg | editor + library, project-scoped | `/jobs/sound`; .ogg + sounds.json pack download |
| Model / Mob Skin Studio | creature/cuboid spec or skin paint | modelstudio + BetterModel export | layers 1-3 built; Mob Skin Studio agent running | asset-space mount; skin .png + model export |
| Config Studio | n/a (needs a mod) | n/a | yes | stays inside a mod |

No guard on code (there is none), the intake guard still runs on the prompt (and the image guard on references). No Test Flight. No Java.

### B.3 Pricing and tokens per studio
- **Per generation**, hold = the studio's measured p85 (Room Studio's 60-token placeholder is the first entry), charge = measured cost, failure or empty spec = free. Deterministic actions are always free (re-roll seed, swap kit or palette, edit the JSON, trims, fades, recolour).
- Show the price on the button: "Generate (~20-60 tokens)". Same learned table as D, keyed by studio + tier + images.
- Plan gates: Room Studio is top-plan only today; studio-first only works as an on-ramp if every plan can use the studios (tier picks the model, not access). Owner decision O-3.
- Downloads of your own assets are free; community downloads are free for signed-in users (DZ: downloads need an account).

### B.4 Routing a prompt to a studio
The wizard's intent step detects single-asset requests deterministically (asset noun: texture/skin/sound/schematic/structure/arena/build/room; no behaviour clause; no command): "This is one asset. Make it in the Texture Studio for ~10-40 tokens, or build a whole mod around it (~150-400)". Both stay available (warn, don't block).

### B.5 Navigation (to reconcile with EE's single-nav proposal)
One left nav, no studio button duplicated in a top bar:
- **Create**: New mod (Wizard) · Structures · Textures · Sounds · Models & skins
- **My Assets** (all kinds, filters by studio, download, Add to a mod)
- **Projects** (mods; inside a mod the studios appear as tabs scoped to that mod: same components, `space = mod`)
- **Community** (mods + assets, Remix / Use)
- Wallet · Servers · Help

### B.6 Offline players (structures/schematics)
- Public: `/minecraft/build-generator` (DZ, `CYRUS_PUBLIC_BUILDER`) for anonymous trial, download with an account.
- Signed in: Structure Studio in an asset space; exports .schem (WorldEdit/FAWE), .litematic (Litematica), .nbt (structure block), "clean" by default (marker blocks only on request), an install card per format and version.
- Community structures browsable and downloadable as files, never requiring a mod or a server.

---

## C. Asset composition

### C.1 References
| ref | meaning | version |
|---|---|---|
| `asset:<CyrusProjectAsset id>@sha256:<hex>` | one of MY assets (any project or asset space) | the content hash is the version; newer versions offered, never auto-swapped |
| `cat:<sha256>` | catalogue entry (CC0 library or community "Made with Cyrus") | content-addressed (immutable) |
| `existing:<slot>` | already in this mod | base build's file hash |

Contract slots carry `ref` + `pin` (hash). The portal materialises the bytes into the build workspace before the model runs (today `build-offer.ts` records a library pick but explicitly does NOT deliver bytes: that is the gap WP4 closes); the scope check restores pinned bytes if the model touched them.

### C.2 Licence and provenance chain
- Eligibility stays as coded: only Cyrus-authored content (`user-original`, `ai-generated-for-user`, `platform-library`) can be in the community library; `third-party-licensed` and `game-derived` never.
- Community assets are public by default with account- and mod-level opt-out (`library/publish/optout.ts`); CC0 semantics, no attribution burden (owner rule). Show "Made by @creator" as a courtesy, not a licence term (owner decision O-5).
- Every use writes `CyrusLibraryUse` (exists) with the build id; takedown marks dependents (exists) and the mod page lists "Uses 3 community assets".

### C.3 Compatibility checks (pure, `lib/cyrus/compose/compat.ts`)
Verdict per slot: **usable** / **needs conversion** (only with transforms Cyrus has: `fit.ts AVAILABLE_TRANSFORMS`) / **not usable here** (with the reason), plus off-style = warn.

| kind | checks |
|---|---|
| texture | size and power of two, animation frames, transparency policy vs slot (item/block/armor layer), item model format for the target version (1.21.4+ item model definitions vs 1.21.1 legacy custom-model-data, MB_LEGACY_TEXTURES), resource-pack format of the version |
| sound | channels (mono for positional; stereo converts with `ogg-mono`), duration vs role profile (`sound/spec ROLE_PROFILE`), loudness (sq-2 rubric), licence clearance (proprietary SFX only when cleared) |
| structure | NBT DataVersion vs target version, every block id present in the target version tables, size vs room limits (warning), markers present when the slot is a dungeon room |
| model / skin | BetterModel version (2.2.0 on 1.21.11, 3.5.0 on 26.2), rig archetype vs creature behaviour, cube/bone budget (warning), texture atlas size |

### C.4 Flows
- **From the wizard**: each asset slot in Include has a picker (Generate / My assets / Community), search prefilled from the slot purpose, fit badge, licence, version pin, preview or audition (existing `SfxPlay`). Choosing a ref removes that slot's generation from the plan and the estimate.
- **From a studio or My Assets**: "Add to a mod" -> pick a mod (or "New mod with this") -> the wizard opens with the slot bound and the change text prefilled ("Use <asset> as <purpose>").
- **Remix**: community asset -> copy into my asset space -> edit in its studio (provenance `derivedFrom` = the cat id; still Cyrus-authored so eligible).

### C.5 Token effect
Measured lane marginal cost over a plain build (eval, recent journals, p50): texture +$0.19, sound +$0.12, creature +$0.37, designer +$0.02. Reusing every slot of a lane removes that lane's spec writing and asset-repair calls; partial reuse is pro rata. **The plan shows the saving only once it is measured** (>= 10 builds with reuse; same rule EA applied to recipes): until then "Reused: not generated" is shown without a number.

---

## D. Accuracy

### D.1 Model
Quantile table, hierarchical fallback with a minimum n per cell (n >= 5, else fall back):

| kind | key (most specific first) | fallback |
|---|---|---|
| refine | same mod's last 6 refines (>= 3) | base mod size bin (Java KB: <30, 30-100, 100-200, 200+) x tier -> all refines x tier |
| fresh | archetype group (coach) x lane-set class (0 / 1 / 2-3 / 4+ non-config lanes) x tier | lane-set class x tier -> tier |
| studio job | studio x tier x images | studio |
| modifiers | extent creative (+ the creative lane budget), reused slots (only measured discounts), mega staging (sum of stages) | |

Shown: typical = p20..p85, "up to" = p95, hold = p85 (never below the minimum spend), with n ("based on 41 similar builds"). With settle v2 the charge never exceeds the hold, so an honest hold protects Nxeon as much as the customer.

### D.2 Snapshot every estimate
`ModBuild.cyrus.estimate = { table, key, n, range, upTo, hold, inputs }` written at gate time. Without it accuracy can only be replayed (this report had to). Cheap, additive JSON.

### D.3 Learning loop
Nightly `scripts/cyrus/estimate-calibrate.ts` (read-only over the last 30 days of real portal builds; eval rows used only where the portal has no cell) -> Setting `cyrus_estimate_table:<version>` (versioned, n per cell, created at). Admin "Estimate accuracy" panel: inside-range rate, median real/top, by kind/tier/lane class, last 50 builds. Alert when inside-range < 55% or median real/top > 1.1 over the last 50 builds. Inputs that move with the model or image (Sonnet 5.5 switch, MB_CACHE_TTL=5m, EA's freeze/escalation fixes) start a new table version so old cells do not pollute it.

### D.4 Target
Inside range >= 60%, median real/top 0.6-0.8, above "up to" < 10%. The online replay already reaches 51% / 0.69 / p80 1.11 with only the history + size-bin rules on one account's data.

### D.5 What the plan screen shows
```
Typical 730-1,020 tokens · up to 1,330            based on your last 6 changes to this mod
What moves it:  mod size (437 KB of code, each step re-reads it) · repairs (a quarter of change cost) · model
Hold 1,020 tokens · you are charged what it really uses, never more than the hold · failures on our side are free
```

---

## E. Mockups

Self-contained HTML (no scripts beyond inline; Google Fonts stylesheet only), dark space theme with ONE accent and a working light theme, under `/root/claudeskills/agent-notes/cyrus-research/wizard-mockups/`:
- `index.html`: links + what each shows.
- `wizard.html`: the wizard in 3 scenarios (specific, broad, refine) x 4 states (prompt + classification, questions, extent, include). Chips, extent and include toggles are live and move the estimate.
- `plan.html`: plan + estimate screen (scenario switch: specific / broad / refine), Will-not-build, contract preview, "what moves it".
- `structure-studio.html`: studio-first Structure Studio in an asset space (prompt, kit, size, preview, checks, free edits, exports, Add to a mod).
- `asset-picker.html`: per-slot picker (Generate / My assets / Community) with fit, licence, version pin and the estimate effect.

Numbers in the mockups come from section 1 (plain build p20..p85 $0.08..0.27; creature/boss portal $0.6..1.24; the dungeon's last 6 refines 362..1,324 tokens; Room Studio hold 60). Thumbnails are CSS placeholders, not game art.

---

## F. Build plan (bundle-sized work packages)

### WP1: Scope contract core (Sonnet-sized pure libs + one service module; Opus review)
- Files: `lib/cyrus/wizard/{specificity,extent,contract,plan-doc}.ts` (pure, client-safe), extend `lib/cyrus/planner/run.ts` + `app/api/cyrus/plan` (return `wizard: { specificity, questions, extentDefault, contractDraft }`), `services/modbuilder/planner.js` output schema (+specificity, +questions, same call), `services/modbuilder/scope.js` (new), `prompts.js` contract block, routing AND-gate in `route.js`/`server.js`, `ledger.js` status `unplanned`, `result.scope`, `cyrus.contract` on ModBuild meta.
- Flags: `CYRUS_WIZARD` (portal, off = today's PlanSheet, byte-identical requests), `MB_SCOPE_CONTRACT` (service), `MB_SCOPE_ENFORCE=report|strip|fail` (start at report).
- Tests: specificity corpus pinned (real-world-v1 + anonymised portal prompts, labels reviewed); scope fixtures from the 10 builds in 1.2 (goblin_tooth, fox_treat, /home, meadow items, sounds); contract round-trip + hash; byte-identical-when-off tests; ledger/preserve suites unchanged.
- Depends: prompt coach (merged), planner recall (merged), ledger/preserve (merged), bundle B settle v2 (for not charging stripped work). Needs a modbuilder image bump; coordinate with EA (0.27) and bundle A image bumps (one image).
- Risk: stripping legitimate glue (a sound an ability really needs). Mitigation: report mode first on the eval corpus + a replay of the 101 recorded plans; Exactly strips only removable kinds; code extras get one capped repair or fail free.

### WP2: Wizard UI + estimate v2 (Opus UI, Sonnet calibration)
- Files: `components/cyrus/wizard/*` (sheet, questions, extent, include, plan, estimate) replacing `PlanSheet`/`PromptCoach` placement behind `CYRUS_WIZARD`; `lib/cyrus/estimate/v2/{table,predict}.ts`, `scripts/cyrus/estimate-calibrate.ts`, `cyrus.estimate` snapshot in `tokens/builds.ts gateBuild`, admin accuracy panel.
- Flags: `CYRUS_WIZARD`, `CYRUS_ESTIMATE_V2` (hold follows v2 only when on).
- Tests: predictor on the frozen 124-row + eval fixture (inside-range >= 50% online), UI unit tests for defaults (specific prompt = zero questions, Exactly preselected), a11y (chips are radio groups), phone layout.
- Depends: WP1 contract; efficiency agent (EA: CHANGE_COST_HISTORY, model/TTL switches start a new table version); UX audit EE (where the wizard lives in the nav); owner approval of the mockups first (design rule: show tiles before rebuilds).
- Risk: friction. Mitigation: specific prompts skip to the plan; one sheet; every answer preselected; measure plan-open -> confirm rate (DeployFunnel-style events) before/after.

### WP3: Studio-first + asset spaces + downloads (Opus)
- Files: asset-space project kind in engine-core store, routes `/dashboard/cyrus/app/studio/<kind>` and cyrus.my `/studio/<kind>`, studio components mounted with `space` context, service `/jobs/texture` + `/jobs/sound` (shape of `room-studio.js`), studio holds in the token config (placeholders, owner decision), resource-pack zip assembler from selected My Assets, prompt-to-studio routing in the wizard intent step, nav entries.
- Flags: `CYRUS_STUDIO_FIRST` + per studio (`_STRUCTURE`, `_TEXTURE`, `_SOUND`, `_MODEL`).
- Tests: asset-space isolation (no ModBuild, no jar), job charge = measured / failure free, exports per version, pack format per version, download auth.
- Depends: Structure Studio v2 agent (owns `structures/studio/*`; mount only), DZ public builder (merge order), Mob Skin Studio agent (plugs in as a kind), UX audit nav, R2/production upload store (Room Studio save needs `CYRUS_UPLOAD_STORE` beyond local).
- Risk: storage growth (asset spaces are cheap to create): quota per plan already exists (r51) and applies.

### WP4: Asset composition (Sonnet libs, Opus picker UI)
- Files: `lib/cyrus/compose/{refs,compat,materialise}.ts`, portal materialisation of `asset:`/`cat:` bytes into the build request, service "existing assets" prompt section + restore-on-touch in scope.js, asset picker UI (wizard Include + studio "Add to a mod"), CyrusLibraryUse writes, community tier in the picker.
- Flags: `CYRUS_COMPOSE` (+ existing `CYRUS_CATALOG_TOOLS` stays separate).
- Tests: compat matrix per kind x version (1.21.1 / 1.21.4 / 1.21.8 / 1.21.11 / 26.2), pinned-hash restore, licence gate (game-derived and third-party never offered), takedown dependents, estimate unchanged until measured.
- Depends: WP1 (slots in the contract), WP3 (My Assets as asset spaces), community backend from the UX audit's bundles, library production import (CC) applied.
- Risk: a reused asset that "fits" but looks wrong in-game (no client check). Mitigation: preview in the slot's context (hotbar/hand/worn), honest "not checked in a real client" label.

Order: WP1 -> WP2 (UI needs the contract); WP3 can start in parallel once EE lands the nav; WP4 after WP1 + WP3. Rough size: WP1 1 bundle, WP2 1-1.5, WP3 1.5, WP4 1.

---

## G. Owner decisions
- O-1 Default extent for "unclear" prompts: A little polish (recommended) or Exactly.
- O-2 Exactly mode: strip extras automatically (recommended, free) or ask after the build.
- O-3 Open every studio to every plan (recommended; tier picks the model) vs today's top-plan gate on Room Studio.
- O-4 Studio per-generation holds (placeholders until measured): Structure 60, Texture ~20, Sound ~20 tokens at Saka.
- O-5 Community credit line "Made by @creator" (courtesy, not licence) on/off.
- O-6 "Admin basics" (`reload`, `give`) in Exactly mode: off (recommended, matches "nothing extra") or on.

## Appendix: method notes
- DB access: read-only session (`default_transaction_read_only=on`), the URL read from /opt/nxeon/.env and never printed.
- Scripts (scratchpad, not committed): dump of ModBuild + reservation rows; `improv.ts` (ruleNeeds / mergeNeeds replay, delivered vs base, commands); `est.ts` (planEstimate replay, honest on/off/scoped); calibrated online replay (history / size bin / lane class, p20..p85); `spec.ts` (specificity prototype over real-world-v1 + portal prompts). All ran with the repo's `tsx` against main's pure modules; no build, no tsc, no network.

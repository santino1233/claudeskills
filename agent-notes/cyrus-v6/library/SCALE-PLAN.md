# Cyrus Pattern Library: from 36 patterns to thousands (plan, 2026-10-08)

Status today: 36 Nxeon-authored Minecraft (Paper 1.21.1 / 1.21.4 / 1.21.8 / 1.21.11) patterns, one
generic schema (`lib/cyrus/library/types.ts`), the CLI (`services/modbuilder/tools/library.js`) and a
node-2 toolchain (`tools/library-env.sh`). See `LIBRARY.md` for what was verified and measured.

## 1. What a pattern is (and is not)

- One concern, 100 to 400 lines of code at most (lint cap: ~2,400 tokens), no plugin-specific names, no
  theme text. A building block a plugin calls (`Ledger`, `Menu`, `Cooldowns`), never a whole plugin.
- Must compile on **every** version it claims, pass the service's own safety scan with zero findings,
  and load + self-test on a real Paper server of each version. Only then is it `verified` and only then
  can the service offer it for that version. Anything else (`compiled`, `failing`, `unverified`) is
  invisible to builds.
- Its runtime self-test (`harness` in `pattern.json`) is part of the content hash: change the test and
  the pattern needs re-verification, like changing the code.

## 2. Contributor workflow (staff and agents)

1. `node services/modbuilder/tools/library.js new <id> <category>` scaffolds `pattern.json` + a class.
2. Write the code from API facts (javap / the version sheets), never from someone else's code unless the
   source passes `LICENSING-POLICY.md` (record SPDX, URL, commit, attribution).
3. `library.js lint` locally (pure, seconds).
4. On node-2: `devhost run --lock -- node services/modbuilder/tools/library.js verify --only <id>` then
   `... runtime` (one Paper boot per version for the whole library, ~1-2 min each).
5. `library.js build`, commit `pattern dir + verify.json + minecraft.json` together. CI/test
   (`test/cyrus-library.test.ts`) fails if `minecraft.json` is stale or lint fails.
6. Review gate (human): licence + de-identification + "is this generic and small?" + the self-test is
   meaningful (not `check(true)`). Two-person review for anything touching persistence, permissions,
   money, chat or inventories (dupe/escalation risk).

## 3. Gates (automatic, in order)

| Gate | Tool | Blocks when |
|---|---|---|
| Schema + licence | `lint` | unknown category, licence not on the allow-list, missing provenance, URL/UUID/IP literals, forbidden APIs (NMS, Brigadier, ChatColor, AsyncPlayerChatEvent...), main-class code, > 2,400 tokens, no self-test |
| Compile per version | `verify` | javac fails on any claimed version (same JDK 21.0.12.1+1 and Paper API classpath as the service) |
| Safety | `verify` (service `scan.js`) | any block OR warn finding (patterns must be cleaner than customer code) |
| Runtime per version | `runtime` | the harness plugin fails to enable, a phase throws, or any stack frame from the pattern's package appears in the server log |
| Freshness | `test/cyrus-library.test.ts` | built file out of date with sources |

## 4. Deduplication

- Exact: `contentHash` (canonical JSON of code + metadata). Same hash = same pattern.
- Near-duplicates: before review, compare the new pattern's API stub (`stubOf`) and its `apis` list
  against existing ones; flag > 70% token overlap of stubs or the same top-level class name (lint
  already requires unique class names, because attach mode shares one package).
- Prefer extending an existing pattern with a parameter over adding a sibling. A pattern with fewer than
  N selections over 90 days (from build records `library.selected/usedPatterns`) is a candidate for removal.

## 5. Per-version maintenance burden

- Each new Paper version: one `library-env.sh <v>` (downloads ~100 MB), `library.js drift <v>` (compile
  all + one server boot), then fix only what broke. Cost per version at 36 patterns: ~5 minutes of
  node-2 time; at 1,000 patterns compile is ~1,000 javac runs (~15-25 min single-threaded; can be
  parallelised under the lock) and the runtime check becomes ~10 harness boots of 100 patterns each.
- Version-specific code: prefer one cross-version implementation (registry lookups by key, Adventure
  sounds by key, `getDataType()` for particles: see `attribute-modifier`, `announce`, `particle-shapes`).
  When impossible, use separate pattern ids per version range (`foo` claims 1.21.4+, `foo-legacy` claims
  1.21.1) rather than branches inside one pattern.
- Dropping a game version: remove it from `versions` of all patterns in one commit.
- Drift feeds the lifecycle agent: `lib/cyrus/library/status.ts` `modLibraryRisk(lib, usedPatterns, v,
  drift)` says which customer mods (via their recorded `library.usedPatterns`) may break on a new version.

## 6. Storage and size limits

- Source: ~3 KB per pattern (code + metadata). 1,000 patterns ~3 MB of source, ~5 MB built JSON with
  verification records: fine in git and in the image. Above ~2,000 patterns split the built file per
  category (`minecraft/<category>.json`) and load lazily.
- Prompt budget is the real limit, not disk: the index (index/auto modes) costs ~19 tokens per pattern
  in the cached prefix. 36 patterns = ~690 tokens. At 300+ patterns the index must go (attach mode needs
  no index) or become per-category (only the categories the router picked for the request).
- Selection quality is the second limit: keyword triggers do not scale past a few hundred patterns.
  Next step then: the router's category + tags from the plan, then BM25 over summaries/usage, still
  deterministic, no embeddings needed before ~1,000 patterns.

## 7. Quality bar (definition of `verified`)

1. Compiles on every claimed version with the service's exact toolchain, 0 errors.
2. Safety scan: 0 findings (block or warn).
3. Loads on a real Paper server of each version; enable, self-test, delayed self-test (if any) and
   disable all succeed; no stack trace from the pattern's package anywhere in the log.
4. The self-test covers the pattern's main path on real server objects where possible (spawned mobs,
   real blocks, the real scheduler); what needs a real player client is listed in `needsPlayer` and is
   NOT claimed as tested. Next harness step: the mineflayer bot from `eval/rt-bot.js` on node-2 (needs
   its node_modules there) to cover the player paths.
5. `deprecation`/`removal` warnings are recorded; a `removal` warning on the newest version opens a
   maintenance task before the next version lands.

## 8. The learning loop

```
customer build (opted in) --succeeded + runtime ok--> miner proposes 0..3 candidate blocks (draft)
                                                      --> lint + verify + runtime + human review --> verified
customer build --failed--> failure record --> rules miner (tools/mine-rules.py) --> failure-rules.json
                                          \--> if a library pattern was attached and failed: pattern regression ticket
```

- **Success path.** Only builds whose owner ticked the opt-in (LibraryConsent, see licensing policy) are
  mined. The miner (not built yet; design): parse the build's sources, find classes that are generic
  (no plugin-name strings, no config keys from the request, mostly API calls), that appear in 2+
  independent opted-in builds with similar stubs, and that pass the safety scan; normalise
  (`package __PKG__`, rename to generic names, strip messages) and write them as `draft` patterns with
  `source.kind: "opted-in-build"`, `buildId`, `consentId`. A model may help normalise (one cheap Haiku
  call per candidate, bounded), but a human approves.
- **Failure path.** Unchanged and complementary: `tools/mine-rules.py` turns repeated build failures into
  reviewed failure rules (`rules/failure-rules.json`), which the efficiency agent exports in the
  GameSupport `knowledge` shape (`tools/export-knowledge.js`: `apiSheet` + `failureRules[{id, detect,
  fix, why}]`). Library patterns and failure rules meet in one place: each pattern's `pattern.json`
  `source.notes` names the rules it encodes (e.g. `ondisable-sync-save`, `bossbar-viewers`,
  `attr-generic-prefix-*`), and a new failure rule should either be added to the knowledge pack or be
  fixed once in a pattern, not both.
- **Removal.** Consent withdrawn -> every pattern citing that `consentId` goes into `removed.json` at the
  next `library.js build`, and is never re-mined.
- **Other games.** The schema is game-generic (`game`, `versions`, `files`, `verification.method`): a
  Valheim pattern is C# verified by `dotnet build` against the game agent's reference assemblies, a
  Zomboid pattern is Lua/script verified by the Zomboid agent's validator. The GameSupport `knowledge`
  packs carry the API facts; the library carries verified code. Per-game JSON lives next to that game's
  build service, exactly like `library/minecraft.json`.

## 9. Growth targets (suggested)

| Stage | Patterns | What unlocks it |
|---|---|---|
| now | 36 | seed, all hand-verified on 4 versions |
| +1 month | 80-120 | the gaps the eval and real requests show (Dialog API forms on 1.21.6+, display entities, holograms, scoreboard teams, item cooldown components, villager trades, world border, loot tables, kits, combat tag, vanish) |
| +3 months | 300 | opted-in mining live; category-scoped index or attach-only; bot-based player tests |
| +6 months | 1,000+ | BM25 selector, parallel verify, per-category built files, other games' libraries |

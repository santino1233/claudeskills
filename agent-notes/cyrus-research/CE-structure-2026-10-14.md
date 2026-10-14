# CE: Structure round (workspace map, structural perf rules, member index, Q1) - 2026-10-14

Branch `feature/cyrus-structure`, worktree `/tank/dev-worktrees/cyrus-structure`, from main `f347f27a`, 2 commits (head `085f2c46`).
Verified, **not merged, not promoted**, every new flag **off**. No live build was run on the service; all evidence is offline fixtures,
recorded javac output, and real javac / javap on node-2 (no model, no Paper boot).

## What shipped

| Item | Flag (build service) | Files |
|---|---|---|
| Java structure reader (no dependency) | - | `services/modbuilder/javaast.js` |
| 1 Workspace map for change builds | `MB_WORKSPACE_MAP=1`, `MB_WORKSPACE_MAP_TOKENS` (2500) | `workspacemap.js`, `prompts.js` (`changePrompt`, `importChangePrompt`), `server.js` |
| 2 Structural perf rules + verified rewrite | `MB_AST_PERF=1` | `astperf.js`, `perf.js` (perfcheck), `autofix.js` (`fixPerf`) |
| 3 javap member index + did-you-mean | `MB_MEMBER_INDEX=1` | `memberindex.js`, `tools/gen-member-index.js`, `autofix.js` (`fixCompile`), `precheck.js` (`apiHints`), Dockerfile RUN |
| 4 Q1 eval lane labels | - | `eval/sets/coverage.jsonl`, `lib/cyrus/eval/set.ts`, `test/cyrus-mc-coverage.test.ts`, `docs/cyrus/02-engine.md` |

Decision: **no tree-sitter / ast-grep**. The native addon (tree-sitter) or a pinned binary (ast-grep) would be a new build-time dependency of the
image for questions that token structure answers exactly (lexer exact for comments, strings, text blocks; bracket matching; statement splitter;
type outline). It also keeps every unit test runnable with plain node. Both remain an option later if type-aware rules are wanted (Error Prone).

## Measured

### 2. Structural perf rules (card 4)
- 15 real code shapes (`test/fixtures/cyrus-structure/perf/S01..S15`) + 6 negatives (N01..N06). Provenance: golden mc-crates / mc-joinleave /
  mc-mobcatcher / mc-crops, test-flight fixtures chunkmirror-unbounded (the incident) and creature, and the fourth1 evidence line from BS.
  **Caveat: the eval builds' own Java sources are not retained on this host (jars hold classes only; journals hold no source). The shapes S05..S14 are
  the shapes the BS/BT reports and the golden corpus describe, written out by hand; they are not byte-for-byte eval sources.**
- Legacy line rules + `fixPerf`: fully clean on **4 of 15** shapes (plain braced for, a few others). Structural rewrite: **15 of 15**.
  Missed by legacy: forEach lambdas (every leftover-drop `...values().forEach(left -> world.dropItemNaturally(...))`), braceless bodies, while with
  a variable used later, nested loops, stream blocks, timers (lambda and anonymous BukkitRunnable), `summon` commands, expression lambdas, braceless if/else.
- **Real javac** (node-2, JDK 21, `--release 21`, the resolved Paper classpath of 1.21.1 / 1.21.4 / 1.21.8 / 1.21.11, audited NxPerf injected, the
  real `autofix.fixPerf` path with the flag on): 21 fixtures x 4 versions = **84 compiles, 0 rewritten files that stopped compiling**; negatives are left
  byte-identical, value lambda and in-condition cases are reported and left to the model.
- Compile safety is by construction: braces added to braceless bodies, declaration used later wraps the rest of the block (never `continue`, never null),
  a non-pure first argument passes `null` instead of being evaluated twice, value lambdas / conditions / returns / switch groups / blank-variable
  assignments are declined; the output must re-lex balanced and have fewer findings or it is dropped. Idempotent (second pass is a no-op).
- New coverage vs old: per-call bounds (the old rule skipped a whole file when any guard existed anywhere), timers with period <= 10 ticks.
- Effect on eval is a **projection, not a measurement**: perf-spawn-in-loop was 6-7 of ~21 repairs per eval (4 of 8 in fourth1); each costs ~$0.05 and
  10-15 s and sometimes a second build. I cannot say how many of them were shapes the old autofix missed; BS says all four repaired fourth1 cases had the plain
  braced shape and failed only because of the round-1 package bug (fixed in rc10). The new value is the shapes rc10 still does not cover.
- **Behaviour caveat (inherited from rc5, widened by this change)**: a guarded `drop*` is skipped when the watchdog's spawn rate (default 5/s) is exceeded,
  so leftover items from a full inventory can be lost. With the flag on, this now also applies to forEach-lambda leftover drops. Decide before turning it on;
  an alternative is to exempt `dropItemNaturally` over `addItem(...).values()` (one line in `astperf.detect`).

### 3. Member index + did-you-mean (card 7)
- Index generated with the image-build tool on the real classpaths (javap -public, offline): 1.21.1 3,801 types / 1.8 MB / 17 s; 1.21.4 4,171 / 2.0 MB /
  20 s; 1.21.8 4,354 / 2.1 MB / 21 s; 1.21.11 2,665 / 1.3 MB / 7.5 s (the 1.21.11 classpath has fewer jars: check before relying on adventure types).
- Real hallucinations: `ConsumableEffect` -> the one close class in `io.papermc.paper.datacomponent.item.consumable` is `ConsumeEffect` (edit distance 3 of 16,
  runner-up further): rewritten (import + every use as a token, strings untouched). `Material.SMITHING_TEMPLATE`: **19** real constants end in
  `_SMITHING_TEMPLATE` on 1.21.11, so it is correctly NOT rewritten; the repair prompt gets 12 ranked relevant constants (tail printed once) instead of the first 40
  of 2,121 (the old hint listed AIR, STONE, ... which never contain the answer). `.toList()` List<TextComponent> stays with `fixListSubtype`.
- Precision on **mutated real names** (the only measurable proxy; types Material, Sound, EntityType, Attribute, Particle, PotionEffectType, Player, World,
  ItemMeta, ItemStack; ~3,200-3,400 mutations per version, 4 versions):
  - dropped / doubled character (typos, ~2,100-2,300 per version): **0 wrong rewrites**, ~77.5% corrected, the rest left to the model;
  - plural / singular (~640-690): **0 wrong**, ~92% corrected;
  - prefix drop (GENERIC_): 0 wrong (23 cases);
  - dropping the last word / stripping `get` are ambiguous by construction (`MUD_BRICK` could be BRICKS or BRICK_SLAB; `DisplayName` is displayName() or getDisplayName()):
    ~65% corrected, 13-16 per version "wrong", all of them plausible alternatives that javac would then check. These are not realistic hallucinations; the
    rule is the same tight one.
  Not measured: the real replay of all `error:` lines in the 254 stored build records (the compile output is not retained on this host).
- Hint size: 569 chars for the SMITHING_TEMPLATE case before tail factoring (664 old); about 290 after (computed from the same 12 names, not re-run on the real index); the benefit is relevance, not length.

### 1. Workspace map (card 2)
- Map is deterministic, signature-only: 93 golden + bank plugins: source 104,765 est. tokens, maps 22,320 (**21%**), median source 962 vs map 229 tokens,
  max map 432; nothing needed a reduced level at the 2500 cap. Single-file plugins get no map (nothing to navigate, the file must be Read to be edited).
- **The effect on turns and spend is NOT measured** (needs paid change builds; none were run). Reasoning only: BL measured 221 turns / 13 change calls
  (17 per call, ~$0.015 per turn, change builds 44% of spend); the map removes the listing/reading exploration turns (U: 1-3 turns, 6-18% of a change build)
  at a cost of 200-450 cached input tokens. The model still has to Read a file before editing it.
- Proposed measurement (about $6): `eval/sets/change.jsonl` 20 prompts, same image, `MB_WORKSPACE_MAP` off vs on: turns, $, first-try pass, lost commands
  (regression guard). `rec.workspaceMap {tokens, level, files, types, truncated}` is recorded on every build for the join.

### 4. Q1
`cov-tablist`, `cov-warps`, `cov-playtime-rewards`, `cov-bossbar-titles`: no `designer` part (lane = plain, assets stage n/a, so fifth1's "no asset result" fails
disappear), `expectLanes: []`, `laneNote` records why; the coverage matrix is untouched (the designer lane is still *available*), the drift test accepts a
`laneNote` prompt. Lane recall baseline (35.4% rules selector, doc 09) moves: **re-baseline the lane accuracy number**. Gate set keeps the keys; `cov-warps`
is now scored in the plain lane (comparability note added in gate.ts).

## Verification
- `scripts/devhost tsc`: 0 errors.
- Tests (devhost): `test/modbuilder-structure.test.ts` 32 cases; with `modbuilder-*`, `cyrus-perf-*`, `cyrus-mc-coverage*`, `cyrus-coach`, `cyrus-eval*`,
  `cyrus-docs-coverage`, `cyrus-planner*`: 622 tests, the one failure (an assertion on hint wording) fixed and re-run green; final run of structure + dockerfile +
  docs-coverage 71/71. Dockerfile COPY test passes (4 modules + `tools/gen-member-index.js` in the list; deploy script list derives from the Dockerfile).
- Docs: `docs/cyrus/02-engine.md` section, `_data/features.json`, `_data/flag-notes.json`, references regenerated with docs-build, DOCUMENTATION.md change history,
  tracker section 112.
- Real harness: `scripts/devhost run --lock -- npx tsx test/cyrus-structure-real.ts --perf --index --out structure-real.json` (84 compiles, index + did-you-mean).

## Image bump it needs
- New tag after whatever is deployed (rc13 plans `modbuilder:0.20`; speed branch a1548118 also edits the Dockerfile COPY list): **expect `0.21` if rc13 lands first**.
  Merge note: the `COPY ... /opt/mb/app/` line conflicts textually with rc13 (`lanegaps.js`) and speed (`speed.js`); take the union
  (the test `modbuilder-dockerfile.test.ts` fails if a module is missing).
- Dockerfile changes: 4 modules appended to the COPY line; `COPY tools/gen-member-index.js`; one RUN step after the app files (javap over each version, ~65 s of image build
  total, +7 MB of `<v>.members.json` in `/opt/mb/classpath`, `|| true` so a failure only means javap-on-demand at runtime).
- Rollout order (each is one env var, independent): `MB_AST_PERF=1` (after deciding the drop-rate caveat; run the 12 failing-perf eval prompts) ->
  `MB_MEMBER_INDEX=1` (zero-risk until a rewrite is applied; both fix and hints are logged in `rec.autofixes`) -> `MB_WORKSPACE_MAP=1` with the A/B above.
- No portal change, no DB change, no new setting; the portal only needs the normal promote for the Q1 eval-set / docs files.

## Not done / honest gaps
- No paid eval; effects on turns, repairs and cost are projections except the fixture and javac numbers above.
- Card 15 (release-day japicmp diff) not built; the member index is its prerequisite and is in place.
- 26.x classpath entries (`<v>.classes.txt` from gen-classpath-26.sh) get no index at image time (MC_VERSIONS only); javap on demand covers them.
- Rewrites are textual (offset insertions); a file that fails to re-lex or whose finding count does not drop is left untouched.

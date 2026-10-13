# Cyrus v6: efficiency (cheaper mod generation, same quality)

Branch `feature/cyrus-v6-efficiency` (worktree `/tank/dev-worktrees/cyrus-v6-efficiency`). Service 0.5 patch to
`services/modbuilder/`, NOT deployed. Docs: DOCUMENTATION.md "AI Mod Builder: efficiency (service 0.5)".
Raw analysis output: `spend-2026-10-08.txt` (this folder).

## Method

- Read-only copy of the 138 `build.json` records on VM 88001 and the 4 Claude CLI session transcripts that
  still exist in the container (`tar` over ssh / `docker exec ... tar`; nothing on the VM was changed).
- `services/modbuilder/tools/spend.py` (new) over that copy. Prices: list prices (Sonnet 5 / 5.5 $2 in / $10 out,
  Haiku 4.5 $1/$5, Opus 5 $5/$25, Opus 5.5 $4/$20; cache read 0.1x input; cache write 1.25x (5 min) or 2x (1 h)).
- **No real builds were run (0 of the 6 allowed).** 0.5 can only run for real on VM 88001, which agents must not
  modify, and the AI credential must not be copied to node-2. Submitting builds to the live 0.4 service would not
  have measured anything new. So every "after" number below is an offline cost model, marked "est.".
- Quality gate offline: 29 unit / offline-pipeline tests (real `server.js`, fake CLI + javac), `tsc` clean. The
  real eval (`eval/run_eval.py v6`, ~$3) is the owner's step after deploy (install notes in the docs).

## Where the money goes today

Baseline = eval run v5 (the current default route, Sonnet 5.5, 30 builds, 28 succeeded, 0 repairs): **$0.098 / build**.

| Part | $ / build | Share | What it is |
|---|---|---|---|
| Output tokens | $0.060 | 61% | ~4.0k tokens of code that lands in files + ~2.4k other (thinking, text) |
| Cache writes | $0.033 | 33% | everything the model generated, written back to the cache at the **1 h TTL price (2x input)** |
| Cache reads | $0.006 | 6% | the ~15k-token cached prefix + history, re-read each request |
| Uncached input | ~0 | 0% | the prefix cache already works across builds |

Findings:
1. **Prompt caching already works.** First request of every build reads ~14.8k cached tokens (tools + system
   prompt + version sheet + rules); the system prompt is byte-identical per version. Nothing to gain there.
2. **The CLI writes the cache with the 1-hour TTL.** Only 2x pricing reproduces the reported cost (5 min model:
   $2.57 vs reported $2.94 for v5; 1 h: $2.94). That makes cache writes a third of the bill.
3. **Thinking is the biggest variable cost**: ~37-44% of Sonnet 5.5 output, ~71% on the Saka tier (Sonnet 5, avg
   $0.49 per fresh build, n=2, up to 31k thinking tokens in a single planning request), ~77% on Haiku. Thinking also
   gets written to and re-read from the cache during the tool loop, so it costs ~1.4x its output price.
4. **One file per request on the tiers**: the Saka and Katara transcripts wrote one file per API request (11 writing
   requests in one build), each re-reading the whole context. Sonnet 5.5 auto builds already batch (2-3 requests).
5. **Exploration turn**: a fresh build spent its first request on a `Glob` of the empty template folder (1 of the 2 fresh transcripts; the change-request transcript did the same before reading).
6. **Repairs are now rare** (2% of all spend; 0 in v5). Of the 13 historic builds that needed one, 7 failed only on
   mechanical things (final main class x2, import from the wrong package x2, Attribute prefix x3).
7. The Haiku "cheap first repair" really is cheap ($0.010-$0.021), even though switching model loses the cache
   (thinking is not carried across user turns, so the history it must re-cache is small, ~8k tokens).

## Savings table

| # | Lever | Status | Saving | Basis |
|---|---|---|---|---|
| 1 | **Saka tier -> Sonnet 5.5** (`MB_TIER_SAKA=claude-sonnet-5-5`, env only) | knob exists; **owner decision** | **~50% on Saka builds** (more on big ones) | measured: 0.3 eval, same 28 prompts, Sonnet 5 $0.203 -> 5.5 $0.104, first try 93% -> 100% |
| 2 | Effort (`MB_EFFORT=medium` for Sonnet/Opus; same value for every call of a build) | implemented, **off** | est. 15-20% if medium halves thinking | model: thinking ~$0.034 of $0.098 incl. its cache cost; unmeasured quality -> eval first |
| 3 | Cache TTL 5 min (`MB_CACHE_TTL=5m`) | implemented, **off** | est. 12% per build **only above ~15 builds/hour on the same version + model**; costs more below that | model: body cache writes 8.1k tokens x (2 - 1.25) x $2/M = $0.012; cold 15k prefix re-write $0.0375 at 5m vs $0.06 at 1h (Poisson break-even ~13-15/h) |
| 4 | Fresh builds: Read/Write/Edit only + "folder holds only the Gradle files" | implemented, **on** | est. 1-5% (a whole request when the model would have Globbed; ~1k fewer cached prefix tokens per request) | transcripts: first request was a Glob in 1 of the 2 fresh builds (the other read its reference image, as told); ~$0.005-0.007 each |
| 5 | Batching instructions (several Writes per response, never one per response; Reads together on changes; small Edits) | implemented, **on** | est. 0-3% on Sonnet 5.5 auto; 10-20% on Saka/Katara if followed | model: 11 single-file requests re-read ~300k cached tokens ($0.06) where 3 would read ~75k |
| 6 | Deterministic auto-fixes before a model repair (`autofix.js`) | implemented, **on** | est. 0-2% average; per affected build saves one repair ($0.01-$0.15) and 10-60 s | 7 of 13 historic repairs; also stops the pre-check's import rules spending a model turn (found by the offline pipeline test) |
| 7 | Repair turn cap 25 (`MB_MAX_TURNS_REPAIR`) | implemented, **on** | tail only | no repair in the records used > 8 |
| 8 | Exact-repeat reuse (`MB_DEDUPE=on`) | implemented, **off** | 100% of a repeated build | records: 15 repeats / 8% of spend, but those are eval re-runs, not customers; `dedupeKey` is now recorded on every build to measure the real rate |
| 9 | Yakko -> Opus 5.5 (`--build-arg CLAUDE_CODE_VERSION>=2.1.280`, `MB_TIER_YAKKO=claude-opus-5-5`) | Dockerfile arg added, **off** | est. 20% per token (list price) | Opus 5.5 defaults to effort medium: pin `MB_EFFORT` and eval before switching |

Combined, with only the default-on items (4-7): est. 2-8% on the default route, more on the tiers. The big money
is in decisions 1-3, which change model, effort or cache behaviour and so need the owner and/or the eval.

## Deliberately not done (protects quality, or does not pay)

- **Retrieving only the relevant cheat-sheet sections.** The whole sheet is ~4k tokens, cached, read at $0.20/M:
  about $0.002-$0.008 per build. Slicing it per request makes the prefix vary (more cache writes, which cost 20x
  a read), and a missed section is exactly the failure the sheets fixed (first try 89% -> 100% on 1.21.1). The
  research agent's CloudAPIBench note agrees: retrieval helps rare APIs, can hurt common ones. Keep it whole;
  revisit only for games whose packs are much bigger, and only with an eval.
- **Cheap planner + focused coder.** The planner's output does not remove the coder's own thinking, it adds a call
  with its own prefix, a wrong plan caps quality, and on the customer tiers it would change the model the customer
  chose. Effort (#2) is the same lever inside one model and one cache namespace.
- **A fresh, targeted repair session (only the failing file + error).** The resumed session already has the files
  in context and reads them from cache at 0.1x; a fresh session must write them to the cache again at 1.25-2x and
  loses the other files' context. Repairs are already targeted (errors + API lookup only, 8k cap).
- **Inlining the old source into change prompts.** Claude Code's Edit requires a prior Read of the file, so inlined
  files are read again anyway.
- **Changing effort or model per stage inside one build** (e.g. low effort for repairs): either invalidates the
  prompt cache; not worth it for a 1-2 request repair. The existing Haiku first repair stays (measured cheap).
- **Template library of building blocks the model composes.** Code in files is ~$0.04 per build; boilerplate is a
  fraction of that, and a library the model must learn (and that must be javap-verified per version and shaded
  per plugin) adds risk. Designed below as an eval experiment, not built.
- **Tool-output truncation.** Tool results here are tiny (Write acks, Glob lists); Reads on change requests are the
  files the model must see. Nothing to cut.
- **Lower generate turn cap.** Typical is 2-6 requests; the $2.50/call and $4/build budgets already bound the tail.

## Where the cost-versus-quality line sits (recommendation)

1. Take the free wins now: deploy 0.5 as is (items 4-7 on, everything else off) and run the v6 eval. Pass = 28/28,
   13/13 runtime, 2/2 refused, first try not below v5.
2. Move Saka to Sonnet 5.5. It was measured cheaper, faster and better; this is the single largest saving.
3. Then one bounded effort eval: v6 prompts at `MB_EFFORT=medium` vs default (about $3 per run, 2 runs). Adopt
   medium only if success, first try and runtime are unchanged; otherwise stay. Never go below medium for codegen.
4. Leave the cache TTL at the CLI default until traffic is above ~15 builds/hour per version + model; when the
   service moves from the subscription token to an API key, check the spend split again (the CLI's default TTL may
   differ) and pin `MB_CACHE_TTL=1h` while traffic is low.
5. Turn on `MB_DEDUPE` only after deciding what a reused build costs the customer (today it would be 0 tokens)
   and after `dedupeKey` shows real repeats (template chips are the likely source).

## For the economy agent (`lib/cyrus/estimate.ts`, `cyrus_tok_*`) - not changed here

The token charge is already the measured `costUsd`, so margins hold automatically; only the **estimates** drift:
- `BASE` usd ranges are anchored on Phase 0 Sonnet 5 ($0.28 avg). If Saka moves to Sonnet 5.5, change to roughly
  simple [0.05, 0.10], standard [0.08, 0.16], complex [0.15, 0.30] (eval 0.3: $0.066 / $0.102 / $0.189; v5
  complex max $0.24). If Saka stays on Sonnet 5, the current ranges fit (Saka measured $0.30 and $0.68).
- `costFactor`: katara 0.5 is low against Sonnet 5.5 (Haiku auto $0.066 vs 5.5 $0.098 = ~0.7); yakko 1.7 is low
  (one Opus 5 SimpleHeal cost $0.341, ~5x a simple Sonnet 5.5 build; n=1, so use ~3 until more data).
- Reserve table (`cyrus_tok_reserve_table`): same direction as `BASE`.
- With `MB_DEDUPE=on`, a reused build reports `costUsd` 0 and settles 0 tokens (`tokensForCost` returns 0 for 0).

## Knowledge packs: how the Minecraft sheets and rules map to GameSupport `knowledge`

`node services/modbuilder/tools/export-knowledge.js` prints them in the contract's shape now (1.21.1: 43 sheet
lines / 13 rules; 1.21.4: 42/15; 1.21.8: 42/16; 1.21.11: 42/17):
- `apiSheet` = one line per bullet of `sheets/<ver>.md`, prefixed by its section (`[Attributes] ...`), so a
  retriever can select by tag. The sheet stays generated by `gen-sheets.py` (javap-checked); do not hand-edit.
- `failureRules[]`: `id` <- id; `detect` <- `pattern` (source regex the pre-check runs) or `warning:<regex>` for
  rules that only show up as a compiler warning ("" = prompt-only lesson); `fix` <- `fix` (with `$1` capture
  placeholders) or `rule`; `why` <- `rule` + the build ids it was mined from (+ "main class only" for `scope`).
- Gaps in the contract worth adding: `knowledge` holds one `version`, but a game supports several (Minecraft: 4)
  -> make it `knowledge?: Pack[]` or a map by version; rules need `versions?: string[]` (one rule covers several),
  `scope?: "main"|"any"`, and `kind?: "source"|"compiler-warning"|"runtime"` instead of the `warning:` prefix;
  optional `autofix?: {replace: string}` for purely mechanical rules (what `autofix.js` does from the jar).
- Single source of truth: the build service runs JS inside its image and cannot import TS GameSupport. Keep each
  game's pack as JSON next to its build service (like `rules/failure-rules.json`) and have `lib/cyrus/games/<id>.ts`
  import or generate from it, rather than two copies.
- Retrieval: keep injecting the whole pack while it is a few thousand tokens (cached, see above). If a game's pack
  grows past ~10k tokens, select lines by section tag from the request + plan, put the selection AFTER the cached
  prefix (user turn), and gate it behind the eval.

## Template library (designed, not built)

Verified blocks (command executor + tab complete, config with reload, YAML data store, scheduler/cooldowns,
InventoryHolder menu, MiniMessage helper) in a fixed package `dev.nxeon.mb.lib`, pre-placed in the workspace and
listed (API only, ~500 tokens) in the cached system prompt. After the model finishes, the service deletes unused
blocks and relocates the used ones into the plugin's own package (no class clashes between plugins). Each block
javap-checked per version. Expected saving: part of the ~$0.04 code output on menu/data-heavy plugins. Ship only
if a v6-vs-blocks eval shows equal success, first try and runtime.

## Files and commits

`services/modbuilder/{server.js, usage.js (new), autofix.js (new), prompts.js, precheck.js, run.sh, Dockerfile,
tools/spend.py (new), tools/export-knowledge.js (new)}`, `test/modbuilder-efficiency.test.ts`,
`test/modbuilder-pipeline.test.ts`, `docs/DOCUMENTATION.md`.

# Cyrus Pattern Library: what was built, verified and measured (2026-10-08)

Branch `feature/cyrus-v6-library` (worktree `/tank/dev-worktrees/cyrus-v6-library`, based on
`feature/cyrus-v6-efficiency`). Service image label 0.6. **Not deployed. 0 of the 6 allowed real
builds were used** (the only path that runs the AI is VM 88001's service, which agents must not touch,
and its AI credential must not be copied elsewhere). Everything about cost and first-try quality below
is an offline model, labelled "est.".

Companion docs: `LICENSING-POLICY.md` (sources, opt-in, removal), `SCALE-PLAN.md` (growth, gates,
dedup, maintenance, learning loop). Repo docs: `docs/DOCUMENTATION.md` "Cyrus Pattern Library".

## 1. The answer to the owner's question

"Train Cyrus on other people's mods?" No, for three reasons: the models Cyrus uses cannot be
fine-tuned by us; most public Minecraft plugin code is GPL (Paper itself is GPL-3.0) or unlicensed, and
the best public samples (the PaperMC docs) are CC-BY-SA-4.0, both of which would follow the code into
customers' closed jars; and platform terms forbid bulk harvesting. What Cyrus gets instead is a
**verified pattern library**: small building blocks Nxeon writes (later also opted-in customer builds),
each compiled on every supported Paper version, safety-scanned, and loaded on a real server. They reach
the model cheaply (section 4), and they double as regression tests for version drift.

## 2. Library size and verification coverage

- **36 patterns**, all Nxeon-authored (`LicenseRef-Nxeon-Authored`), 16 universal categories covered:
  utility 8, interface 5, items 3, admin 3, gameplay 2, quests 2, environment 2, visuals 2, performance 2,
  economy, creatures, magic, weapons, vehicles, minigames, audio 1 each. 27 "rare" (auto/attach-eligible),
  9 "common" (on-demand only).
- **Compile + safety scan: 144/144 pattern-version pairs pass** (36 x Paper 1.21.1 / 1.21.4 / 1.21.8 /
  1.21.11), first run, on node-2 with the service's exact JDK (Temurin 21.0.12.1+1) and the Paper API
  classpath resolved by the service's own Gradle template; zero findings from the service's `scan.js`.
  (The first run recorded 0 compiler warnings, but that run did not capture javac's stderr; fixed since,
  re-run `verify` to get the real warning list.)
- **Runtime load on a real Paper 1.21.4 server (one run, 27 s boot to shutdown): 32/36 pass**
  (enable, self-test, delayed self-test, clean disable, no stack frame from the pattern's package). The 4
  failures are self-test assertions, analysed but not fixed (session told to wrap up):
  - `messages`: a real pattern bug. "&aOld <player>" contains "<", so it takes the MiniMessage path and the
    &-code is printed literally. The legacy/MiniMessage switch must look at "&" codes, not the absence of "<".
  - `objective-tracker`: `EntityType.valueOf("DROPPED_ITEM")` did NOT throw on 1.21.4 (Paper still accepts
    the old name), so the test's assumption is wrong; the validator should resolve via the registry key.
  - `paged-menu`: test bug (the last page holds 10 entries in slots 0-9, the test checked slot 9 empty).
  - `particle-shapes`: `Particle.valueOf("REDSTONE")` did NOT throw on 1.21.4 (old names are still
    accepted as aliases), so "old names are rejected" is false; the parse is still safe, the doc comment and
    the test must change.
  1.21.1, 1.21.8 and 1.21.11 runtime were not run. Status today: 32 `compiled` (runtime pass on 1.21.4
  only), 4 `failing`, 0 `verified`, so **the service offers no pattern yet** (it only offers patterns
  verified on the exact version). See PAUSED.md.

## 3. What a pattern encodes (why they are worth having even though the model is good)

The v5 eval already passes 28/28 first try, so the library is not mainly about the eval set. The seed
patterns encode the things that break at runtime or across versions, which compile-and-scan does not
catch and the model gets wrong on rarer requests:
- cross-version API (attributes by registry key on 1.21.1 `generic.*` and 1.21.4+ unprefixed; sounds by
  key; particles with their required data from `getDataType()`), i.e. failure rules
  `attr-generic-prefix-*`, `attr-no-switch-new`, `particle-old-names`, `potion-old-names` fixed once in code;
- runtime traps the rules file records: synchronous save in `onDisable` (`ondisable-sync-save`),
  BukkitRunnable vs scheduler (`scheduler-bukkitrunnable`), boss-bar viewers (`bossbar-viewers`),
  `NumberFormat` package (`numberformat-package`);
- correctness that no compiler sees: dupe-safe menus (every click/drag cancelled while open, holder
  identity, listener auto-registered even if the plugin forgets), integer money with atomic transfers
  and overflow checks, async-chat thread safety, homes that survive an unloaded world, block
  restoration to the true original, temporary mounts that cannot pile up, AFK that ignores head turns.

## 4. Retrieval: how patterns reach the model, and what it costs

Four modes (`MB_LIBRARY`), default `off` (byte-identical prompts to 0.5, so merging changes nothing):

| Mode | Cached prefix | User turn | Extra requests | Model writes the code? |
|---|---|---|---|---|
| off | unchanged | unchanged | 0 | yes |
| index | + ~690-token index (36 titles) | 1 line | +1 if it Reads patterns | yes (copies) |
| auto | + index | + full code of <= 3 matched rare patterns (avg ~1.1k tokens) | 0 | yes (copies) |
| attach | unchanged | + API stubs of <= 3 matched rare patterns (avg ~415 tokens) | 0 | **no**: classes are placed in `src/main/java/cyruslib/`, imported, relocated into the plugin's package after generation, unused ones deleted |

Selection is deterministic (trigger phrases 2 points, words 1, tags 1, each term once, threshold 3),
only for patterns verified on the build's exact version, never for "common-API" patterns (commands,
config, cooldowns, join messages, titles, item builder, world clock, messages, managed task): that is
the CloudAPIBench guard (retrieval for APIs the model already knows can cost accuracy). Change requests
are never attached (they work on the plugin's own files).

### Offline A/B on the existing eval set (`tools/library-ab.js`, est.)

Basis: the measured v5 profile (Sonnet 5.5, $0.098/build, 5.3 requests, 27.7k cache-read, 8.1k
cache-write at the 1 h price, 6.0k output tokens/build), list prices, 2 builds/hour/version for prefix
re-writes, per-class baselines from eval 0.3 ($0.066 / $0.102 / $0.189).

| Mode | est. $/build (eval avg) | delta | simple | standard | complex |
|---|---|---|---|---|---|
| off (v5 measured) | $0.0980 | 0 | | | |
| index | $0.1001 | +2.1% | | | |
| auto | $0.1053 | +7.5% | +4.0% | +8.0% | +7.5% |
| attach, model would have written 25% / 50% / 75% of each pattern | $0.0979 / $0.0957 / $0.0936 | -0.1% / -2.3% / -4.5% | +0.4% (50%) | -2.9% (50%) | -2.7% (50%) |

(These numbers assume every pattern is verified (`--assume-verified`); they model what happens once the
runtime check passes.)

Selector quality vs hand labels written before tuning (`eval/library-labels.json`, 30 prompts):
precision 0.89 (25 right, 3 extra), recall 0.78 (7 missed, mostly `player-data-store` on prompts that only say "saved"). Adversarial prompts get nothing.

**Reading it honestly**
- `index` and `auto` cost more than they could plausibly save on this eval: the model already passes
  everything first try (v5: 28/28, 0 repairs), so there are no repairs to save, and inlined code is
  input the model then re-types as output. `auto` only pays off if it cuts ~730 output tokens per build,
  which nothing measured supports. I do not recommend them for Minecraft today.
- `attach` is the only mode that can save money, because it removes output tokens (the expensive part)
  instead of adding input. Est. -0.1% to -4.5% on the eval average depending on how much of a pattern the
  model would otherwise have written (25-75%); est. about -3% on standard and complex builds at 50%.
  Small, because the eval prompts are small; larger plugins that need 2-3 blocks gain more.
- First-try pass rate: **unmeasured**. Expected neutral to slightly positive on rare/advanced requests,
  and the risk CloudAPIBench describes is limited by never offering common APIs and only offering
  patterns on strong matches. The real risk in attach mode is different: the model may misuse an API it
  only sees as a stub, or write a clashing class name; both show up as compile errors and go through the
  normal repair loop (the classes are already verified).
- What attach also buys that the cost model ignores: the shipped code for menus, money, persistence and
  chat is the verified version, not a fresh one-off, so runtime bugs (dupes, lost saves) drop in the
  plugins that use it. That is the main reason to adopt it.

## 5. The real eval the owner should run (bounded, about $6)

After the 0.5 install, build 0.6, then:
1. `run.sh modbuilder:0.6` (library off) -> `eval/run_eval.py v6-off` (control; must match 0.5).
2. `MB_LIBRARY=attach run.sh modbuilder:0.6` -> `eval/run_eval.py v6-attach`, `rtcheck.py v6-attach`.
3. `tools/spend.py --prefix ev-v6-attach-` vs `ev-v6-off-`; `summarize.py v6-off v6-attach`.
Adopt attach only if: 28/28 built, 2/2 refused, first-try not lower than off, runtime 13/13, and
$/build not higher. The records now carry `library.{selected, attached, relocated, usedPatterns}` and
`usage`, so the run also shows how often the model actually used the attached classes.

## 6. What is left

- Run the real A/B (owner, after deploy).
- Player-path runtime tests (needs the mineflayer bot on node-2; today `needsPlayer` paths are listed,
  not claimed).
- Opt-in for customer builds: the consent record type and wording draft exist (`LibraryConsent`,
  `LIBRARY_CONSENT_WORDING` in `lib/cyrus/library/types.ts`); the listing/NxLabs checkbox (routing /
  community agents), a Prisma model and the miner are not built. Needs the owner's ToS wording first.
- Scheduled drift: `library.js drift <v>` exists; no timer installed (needs the owner's OK to schedule a
  node-2 job).
- Patterns for the other five games once their GameSupport packs and compilers exist (schema is generic).

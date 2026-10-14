# CF: MockBukkit pre-flight (card 3) + requirements ledger (card 5), 2026-10-14

Branch `feature/cyrus-preflight` (worktree `/tank/dev-worktrees/cyrus-preflight`, from main f347f27a), commit 32b918b0, verified, NOT merged, NOT promoted, NO image built or deployed (no docker on this host or node-2; the Dockerfile steps were exercised command by command on node-2, see "Not verified").

## 1. Pre-flight (card 3)

**What it is.** `services/modbuilder/preflight.js` (Node side) + `services/modbuilder/tools/preflight/Preflight.java` (runner). After javac + scan pass and before `finish()` (so before settlement and the async Test Flight) the compiled jar is loaded by `MockBukkit.loadJar` in a throwaway JVM (`-Xmx384m`, SerialGC, C1 only, cwd = scratch dir, env without AI keys, container egress firewall, wall budget 15 s then SIGKILL at +5 s).
Checks, each `pass | fail | skip | note | needs_engine`: plugin.yml parses (PluginDescriptionFile); main class is in the jar; depend/softdepend resolve (managed engine = the rc12 `DEPEND_PKG_PLUGINS` table, passed to the runner, hard depends stubbed with `createMockPlugin`, so a creature mod is `needs_engine`, not crashed); onEnable completes (exceptions logged by Bukkit are captured through a root log handler); every declared command is registered and run as an op mock player and as console with 0 args (1 sample arg is advisory); declared permissions register; 100 scheduler ticks (advisory note only); onDisable.
Verdicts `pass | fail | needs_engine | skipped`. Evidence level recorded as `synthetic` on the build record (`rec.preflight`), never worded as flown. `UnimplementedOperationException` and any fault whose top frame is inside org.mockbukkit with no plugin frame is `skip`, never `fail`.

**Verified facts about MockBukkit (V = measured here).**
- Coordinates V: `org.mockbukkit.mockbukkit:mockbukkit-v1.21:4.116.3` on Maven Central (MIT, 1.95 MB jar). Paper API is NOT a dependency of the artifact: it comes from the image's existing per-version classpath file.
- Coverage V: runs against the **1.21.11** Paper API only. On 1.21.8 and 1.21.4 `MockBukkit.mock()` fails with `No enum constant Material.COPPER_BARS`, on 1.21.1 with `ClassNotFoundException CustomModelDataComponent`. So `MB_PREFLIGHT_VERSIONS` defaults to `1.21.11`; every other version (and 26.x) is recorded as `skipped` with the reason, no customer event, no JVM started. Older MockBukkit lines for 1.21.1-1.21.8 were not tried (not needed for the default version).
- The plugin jar must NOT be on the JVM class path (MockBukkit loads it in its own plugin class loader; otherwise `JavaPlugin requires to be created by a valid classloader`). Found and fixed.
- MockBukkit does not register plugin.yml permissions itself; the runner registers them as the server does and verifies (a naive "permission exists after load" check had a 100% false-red rate on Shop).

**Autofix hooks and repair loop.** A `fail` goes through `preflight.mechanicalFixes()` first, no model turn: `missing_depend` -> `AF.fixPluginDepends(..., force=[plugin])` (same hook as rc12); `main_class_not_found` -> point `main:` at the single JavaPlugin subclass; `npe`/`command_not_registered` -> declare `getCommand("x")` names plugin.yml lacks. After a fix: recompile, re-run the pre-flight (counted in `usage.autofix`, `savedRepairs`, `rec.autofixes[source=preflight]`). No fix possible -> ONE compile-class repair (`problem.kind="compile"`, text "The plugin compiled, but when it was loaded in a mock server it did not work: - [pre-flight: enable] ...", only while compile repairs and budget remain). Still failing -> the build ships with `warnings`/`rec.preflight` and the Test Flight decides. A false positive can therefore cost one repair, never the build. Infrastructure errors (no JVM, garbage output, timeout, missing files) -> `skipped`, logged, build continues.
Switches: `MB_PREFLIGHT` = 1 (default, enforce) | advise (record only) | 0; `MB_PREFLIGHT_VERSIONS`, `MB_PREFLIGHT_BUDGET_MS`, `MB_PREFLIGHT_DIR`, `MB_PREFLIGHT_JAVA`. `/health features.preflight` = `{mode, mockbukkit, versions[ready here]}`.

**Measured (node-2, JDK 21.0.12, 4 jobs in parallel with other load; single jar ~1.4-1.6 s).**
| set | n | pass | needs_engine | fail | skipped | wall p50 / p90 / max |
|---|---|---|---|---|---|---|
| eval jars first1..fifth1 (every stored build jar) | 242 | 239 | 0 | 0 | 3 | 1.64 s / 1.83 s / 2.07 s |
| starter bank, 1.21.11 | 16 | 16 | 0 | 0 | 0 | ~1.5 s |
| owner batch + goblin v1 (12 jars) | 12 | 9 | 1 (fox) | 1 (goblin v1) | 1 (golden feast) | 1.7-2.2 s |
| mutant fixtures (tools/preflight/fixtures) | 7 | ok, foreign-depend (note), task-throws (note) | - | npe-command, wrong-main, cmd-throws, config-npe | - | 0.1-1.5 s |
Zero false reds on 270 known-good jars. The 3 eval skips + golden feast are MockBukkit gaps (`UnimplementedOperationException` in onEnable code paths, e.g. recipe registration); reported as `skipped`, never `pass`.
**Catches.**
- goblin v1 (`mb7714738f123ea861d24a`): `fail`, "cannot enable without BetterModel: the plugin uses it (kr.toxicity.model.api.platform.PlatformEntity) but plugin.yml does not declare depend: [BetterModel]", hook missing_depend -> mechanical `depend: [BetterModel]`, re-check passes (pipeline test, no model call). In 1.5 s instead of the flight's minutes.
- fox (`mb0d8ad449dbcaf7a9addc`): `needs_engine` (stubbed BetterModel, creature code cannot run outside the engine): honest "only the real server check can confirm", not "crashed", not "passed".
- 4 mutants the Test Flight finds late today: getCommand without a plugin.yml entry (NPE in onEnable), main class mismatch, command throwing AIOOBE on 0 args, config section read before it exists.
- NOT caught (by design): fire-sword's `commands_registered=fail` flight warning was a wrong command label in the model's own summary, not a plugin.yml defect (rc13 `reconcileCommands` owns it); anything needing real world / client behaviour.

**Image.** `template/build.gradle.kts` gets an own `mockbukkit` Gradle configuration + `writeMockClasspath` task (verified: the plugin compile classpath is byte-identical, same 45 entries). Dockerfile: COPY `tools/preflight/Preflight.java` + `smoke.sh`, one RUN after the Paper classpath pre-warm (image-build time only, like Paper API: resolves MockBukkit into the same Gradle home, writes `/opt/mb/preflight/mock.txt`, compiles the runner against 1.21.11 into `preflight.jar`, runs `smoke.sh` which fails the image build if a trivial plugin does not load as `pass`); `preflight.js ledger.js` added to the app COPY line (`test/modbuilder-dockerfile.test.ts` green, deploy script list derived from the Dockerfile so it ships `tools/preflight/*`). Runtime stays offline. **Image size delta: +11.6 MB of jars (39 files incl. byte-buddy 4.7 MB, maven-resolver family, junit-api) + 11 KB runner = about +12 MB; no JDK or Gradle change.** The runtime path reuses `/opt/mb/jdk` (`java` on PATH).
Security note: pre-flight executes model-written plugin code on the build host (after the bytecode scan gate). It runs as the service user inside the container: no network (firewall), 384 MB heap, hard kill, scratch cwd that is deleted. Test Flight remains the real gate.

## 2. Requirements ledger (card 5)

`services/modbuilder/ledger.js`, deterministic, no model call, `MB_LEDGER=0` off.
- **Extraction** (at build time from what the planner already produced): the approved plan lines (`assets.plan = [{lane, what}]`), the lanes switched on (flags), and the prompt / change request text: `/commands`, sentences, bullets, items of a `head: a, b, c` list, "configurable in config.yml". Ids are stable slugs (`command:shop`, `lane:creature`, `plan:texture:fire-sword-look`, `feature:right-click-fireball`), max 24 items, <= 140 chars each, 6 keyword stems per feature.
- **Status** per requirement: `planned | implemented | dropped | regressed`, with `evidence` refs: `plugin.yml:commands.x`, `assets/<kind>/<name>.json`, `src/.../File.java#symbol` (keyword evidence, labelled `level:"heuristic"`), `flight:<check id>` (`attachFlight()` for whoever holds the flight). A lane that the service downgraded is `dropped` WITH the service's reason; a change request that removes something ("remove the /bye command") makes it `dropped` with the owner's words and it is never silently resurrected.
- **Lineage**: persisted as `rec.ledger` (build.json, `publicView`, portal `toResult`); the base build's ledger is loaded (or bootstrapped from its prompt, plan and finished workspace for older builds). Change builds receive a compact `REQUIREMENTS LEDGER` block (<= 14 lines, ~150 tokens, only implemented/regressed items) before the change request; `rec.ledgerInjected` counts the lines.
- **Diff + honest notice**: after the build, requirements that were implemented and are gone are `regressed`, lane items among them are `laneFlips`; the notices ("This version lost an animated creature that the previous version had. If that was not intended, ask for it back.", "... no longer has the /bye command ...", "You asked for /x, but it is not declared") are appended to `summary.limitations`, `warnings` and an event, which the portal already renders (ExplainTab / BuildView). Evidence level `static`.
- Prompt version bumped to `mb-2026-10-14.1` (two version pins in tests updated).
- Portal: `ModBuildResult.preflight` / `.ledger` types, `toResult` mapping (trimmed), 4 flags registered in `lib/cyrus/admin/flags.ts`, docs references regenerated, narrative in `docs/cyrus/07-operations.md`.
- Not built (deliberate): a model repair for a regression (the notice is the contract; a `MB_LEDGER_REPAIR` follow-up is easy once the dropped-feature rate on `eval/sets/change.jsonl` is measured), a dedicated portal card (limitations/warnings already show it).

## 3. Verification
- `tsc --noEmit` 0 errors. Tests: modbuilder-preflight (16), modbuilder-ledger (14), modbuilder-preflight-pipeline (9: real server.js with fake CLI/javac/jar/java: pass wording, needs_engine, depend fixed with no model call + re-checked, one repair then ship-with-warning, garbage JVM output skipped, ledger v1, v2 injection + notice, v3 removal), plus the existing modbuilder-* suite and cyrus-docs-coverage green (one modbuilder-import-pipeline run was cancelled by load in a combined run and passed alone).
- Java runner + MockBukkit: node-2 only, via `tools/preflight/replay.sh` (fixtures) and the batch runs above. JDK 21 is not on the primary.
- Merge notes: no conflict with rc12; with rc13 / rc14 / feature/cyrus-speed conflicts are limited to `server.js` (adjacent hunks in requires/finish), the Dockerfile COPY line (union) and the generated `docs/cyrus/reference/*` (re-run `scripts/cyrus/docs-build.ts`).

## 4. Not verified
- No `docker build` was run (no docker anywhere reachable here); each RUN command was executed by hand on node-2 with the same JDK + Gradle 8.14.3 (resolve: 39 jars, classpath identical; runner compile; smoke `pass`). First real image build is the owner deploy; the smoke makes a broken harness fail that build (not the running service).
- Pre-flight false-red rate on future model output is unknown beyond the 270 jars; mitigations are one-repair cap, `advise` mode, and the eval gate. Suggest running `MB_PREFLIGHT=advise` for one eval round (`preflight.verdict` is on every build record) before relying on enforce, or accept the default (enforce) given 0/270.
- Keyword evidence for free-text features is heuristic by design; only commands, lanes and config are exact.

## 5. Exact commands (owner, one at a time; service must be idle)
```
# portal side (types, toResult, flags, docs): normal promote
cd /opt/nxeon && git merge --ff-only feature/cyrus-preflight && bash scripts/promote-production.sh --skip-staging-check
# build service image (adds MockBukkit to the image build; needs Maven Central at build time like the Paper API; rc13's planned tag is 0.20, so this is 0.21, or 0.20 if rc13 ships in the same merge)
cd /tank/dev-worktrees/cyrus-preflight && TAG=modbuilder:0.21 bash scripts/cyrus/deploy-modbuilder.sh
# check afterwards
curl -s 127.0.0.1:7340/health | python3 -c 'import sys,json;h=json.load(sys.stdin);print(h["features"]["preflight"],h["features"]["ledger"],h["promptVersion"])'
# expect: {'mode': 'enforce', 'mockbukkit': '4.116.3', 'versions': ['1.21.11']} True mb-2026-10-14.1
```
Runtime off-switches (service env, no rebuild): `MB_PREFLIGHT=0` or `advise`, `MB_LEDGER=0`. Rollback = the deploy script's automatic rollback, or redeploy the previous TAG.

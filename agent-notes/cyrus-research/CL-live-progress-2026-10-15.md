# CL: live build progress + progress-based timeouts (2026-10-15)

Branch `feature/cyrus-live-progress`, worktree `/tank/dev-worktrees/cyrus-liveprogress`, commit faf6c626. Not merged, not deployed, no migration. Build-service image bump REQUIRED (services/modbuilder changed: server.js, new progress.js, Dockerfile COPY line).

## What was wrong (recorded builds, read-only GET)
- mb9aeb0308c0ac46e580b2 (dungeon stage 1): events = queued, "Planning the plugin from your description" at 06:28:09, first file at 06:36:03 (8 min later), 8 files by 06:37:23, killed 06:38:12 at the 600 s per-call wall clock. "The AI took too long", errorCode timeout, charged nothing, half the plugin thrown away.
- mb7714738f123ea861d24a (goblin): 7 minutes of the single planning line before the first file.
- The stream carries NO thinking text: `phaseChars.thinking` = 0 on the recorded call (only signature deltas), `writing` = 37,809 chars. So hints are derived from tool_use inputs + file names; thinking/answer text is used (sanitized) only if it ever appears.

## What the user sees now vs before
Before (studio trace, 8 minutes):
```
Planning the plugin
  Thinking through the design · step 14 · 9:51 elapsed     (a pulse every 5 s, nothing else)
```
After (studio trace / project page, mid-build):
```
(pulsing dot) Thinking: after dungeon terminal              3m 20s
  8 files written · repair round 1 of 8 · 14,200 tokens so far · 9m 02s elapsed
  Wrote RoomType.java                                        2m ago
  Wrote VoidGenerator.java                                   1m ago
  Writing RoomBuilder.java                                   40s ago
  Thinking · 3m 20s                                          just now      (one coalesced heartbeat line)
```
After 60 s with no new model output:
```
(slow amber pulse) Still working, the model is thinking
  Still working: the model is thinking about RoomBuilder.java. No new output for 3m 10s; this is normal for a big design.
```
Repair / asset / continuation rounds: "Fixing compiler errors (round 2 of 8): editing GoblinManager.java", "Asset round (1 of 8): ...", "Continuing where it left off: ...". Compile / safety / pre-flight lines come from the server. Queued builds keep the existing queue line (place in line, p50-p80 wait, "waiting for the AI" with retry time) which already states the wait reason.
A thinking hint line (only when the stream has text): first sentence, <=140 chars, host paths reduced to file names, links/addresses/secret-like strings and any prompt/system talk dropped (whole hint discarded).

## Service changes (services/modbuilder)
- `progress.js` (pure, tested): `limits()`, `supervise()` (idle / ceiling / fixed), `newTracker()` (stream -> phase/file/hint/counters/feed), `sanitizeHint()`, `continuePrompt()`.
- `server.js`: `run()` supervises by silence (stdout OR stderr); `callClaude` feeds the tracker, counts the streamed usage of a killed call (estimated, `aiCalls[].estimated`, `killedBy`), and runs ONE continuation (`kind: generate-continue`, fresh session, original task + file list, budget shrinks by what was used). `publicView` adds fresh `progress`; `/health features.progress` states live limits; build killer uses the ceiling unless `MB_BUILD_TIMEOUT_S` is set.
- Contract: `progress` is additive; events, `live`, `/live`, SSE/poll unchanged. Durations only (never absolute times).

## Portal changes
- `lib/cyrus/builder/progress-view.ts` (bounds the untrusted object, wording, relative times, quiet state), `ModBuildResult.progress`, `ServiceBuild.progress`, `lib/modbuilder/store.ts toResult`.
- `follow.ts`: `activity` GenEvent (changed or every 5 s, feed trimmed to 12), pulse line uses the headline, stream deadline 20 min -> 6.5 h. `forge.ts`/`store.ts`: `job.activity`.
- `components/cyrus/prompt/BuildActivity.tsx` used by ThinkingTrace and BuildFollower: local 1 s clock, reduced-motion safe, mobile (wrapping, no fixed widths), one visually-hidden polite status line changed at most every 20 s (the feed list is not a live region; BuildFollower's wrapper `aria-live` moved to its headline only, it used to re-announce the ticking elapsed counter every second).
- Old service (no `progress`): nothing new renders, old step list/pulse unchanged. Old portal + new service: field ignored.

## Timers (B): what could cut a long build
| Timer | Was | Now |
|---|---|---|
| per model call | 600 s wall clock | idle 300 s of silence; ceiling 14400 s |
| per build | 1200 s wall clock | ceiling 21600 s (idle is per call) |
| `MB_CALL_TIMEOUT_S` / `MB_BUILD_TIMEOUT_S` | defaults 600 / 1200 | no default; apply only if set explicitly |
| $ caps `MB_CALL_BUDGET_USD` 2.5 / `MB_BUILD_BUDGET_USD` 4 | unchanged | unchanged, the cost guard (continuation gets the remainder) |
| Haiku guard/plan/coach calls (60/30/30 s), jar 60 s, javac 180 s | fixed | unchanged (short helpers) |
| portal `STALE_MS` 2 h (fails a row when the service is unreachable) | counted from createdAt: a >2 h build with one failed poll was killed | counted from last successful sync (`updatedAt`) |
| studio follow stream | 20 min per stream, re-attach x12 | 6.5 h per stream; client re-attaches on drop |
| client `STREAM_SILENCE_MS` 30 s | reconnect only | unchanged (pings every 8 s) |
| nginx `proxy_read_timeout 600s` app paths | fine (pings) | unchanged; the build tunnel is a short request/response per poll, no long-held connection |
| worker `modbuilder-sync` (20 s cadence, 2 min run) | no per-build limit | unchanged |
| scheduler / capacity | in-memory queue, no leases | nothing to change |
| `MB_MAX_TURNS` 60 / `MB_MAX_TURNS_REPAIR` 25 | turn caps | unchanged (they, not time, bound a runaway model) |
| `/root/claudebox.env`, container limits | - | check that nothing sets `MB_CALL_TIMEOUT_S`/`MB_BUILD_TIMEOUT_S` (see owner commands): if set there they silently keep the old behaviour |

## Flags / env (service, all optional)
`MB_IDLE_TIMEOUT_S` 300 (0 = off), `MB_CALL_CEILING_S` 14400, `MB_BUILD_CEILING_S` 21600, `MB_CALL_TIMEOUT_S` / `MB_BUILD_TIMEOUT_S` (explicit overrides, no default), `MB_CONTINUE_MAX` 1 (0 = off), `MB_HEARTBEAT_S` 12 (min 3), `MB_PROGRESS` (off = no feed). Registered in docs/cyrus/_data/flag-notes.json and the generated flags-and-env.md. No portal flag: the panel appears when the service sends `progress`.

## Tests
- `test/modbuilder-progress.test.ts` (17): limits, supervise (chatty outlives idle, silent killed, ceiling/fixed), tracker on a recorded-shape stream-json fixture (`test/fixtures/modbuilder-stream/dungeon-start.ndjson`, signature-only thinking, paths + secret-ish text), sanitizer, heartbeat coalescing, feed cap, quiet wording never says stuck, relative times.
- `test/modbuilder-progress-service.test.ts` (4, real server.js + fake CLI): /health limits; a 4.5 s chatty call survives a 2 s idle limit and shows progress while running; silent-after-write is killed idle then ONE continuation succeeds (events, `generate-continue`, `killedBy: idle`); silent with nothing written fails once as `timeout` without continuation.
- tsc clean; `modbuilder-capacity-service`, `modbuilder-pipeline`, `modbuilder-live`, `cyrus-live-test-fixes`, `modbuilder-dockerfile`, `cyrus-docs-coverage` pass. `cyrus-live-usage-e2e` fails identically on main (geo-ip server-only import under tsx), unrelated.
- Docs: docs/cyrus/07-operations.md section, DOCUMENTATION.md change entry, generated references rebuilt.

## Owner commands (nothing was run on the live service)
1. Check for explicit old overrides: `grep -n "MB_CALL_TIMEOUT_S\|MB_BUILD_TIMEOUT_S" /root/claudebox.env /etc/nxeon/*.env /opt/nxeon/.env 2>/dev/null` (and the `docker run` env of the build container). Remove them, or keep them knowingly as fixed limits.
2. Rebuild + roll the build-service image with the repo's usual procedure (promote script / Dockerfile in services/modbuilder; `progress.js` is in the COPY line). Wait until the owner's dungeon build finishes before recycling the container (a restart fails running builds as "interrupted").
3. After the roll: `curl -s http://127.0.0.1:7340/health | jq .features.progress` should show idleTimeoutS 300, callCeilingS 14400, buildCeilingS 21600, fixedCallS null.
4. Deploy the portal (staging first): the panel needs both sides; either order is safe.
5. Optional: rerun the dungeon stage 1 prompt as an owner build; expect a long first phase, a live feed, and no timeout.

## Risks
- Cost: a build may now run for hours. Guards: `MB_BUILD_BUDGET_USD` 4 / `MB_CALL_BUDGET_USD` 2.5 stop spend, `MB_MAX_TURNS` bounds turns, 6 h ceiling. A model that keeps streaming but makes no progress is bounded by those, not by time. Consider lowering `MB_BUILD_CEILING_S` to 7200 (2 h) if the owner prefers a tighter ceiling.
- Estimated cost of a killed call is derived from the stream (chars/4 for the last partial message): close, not exact; the portal still charges `costUsd`. It makes a continued build cost slightly more than the finished call alone, by the real tokens the interrupted call used.
- Continuation uses a fresh session (the killed one may be cut mid-write): it re-reads files, costing a cache miss. It is not a resume of the model's thinking.
- Idle = no byte on stdout/stderr. A CLI that emits keep-alive bytes while the model is wedged would not be killed until a ceiling or turn cap. Signature/ping deltas were not seen to flow while hung; if observed, tighten by counting only content deltas (a one-line change in `run()` touch).
- A long build keeps a build slot for hours: with `MB_CONCURRENCY` 2 two such builds block the queue (the queue line stays honest; interactive reserve still holds one slot).
- Thinking hints depend on the stream carrying thinking text; today it does not, so the hint line is mostly file-name based ("after dungeon terminal").
- `STALE_MS` now uses `updatedAt`: any other writer touching the row also resets it (only delays failing an unreachable build).
- The 5 s `activity` resend adds ~2-3 KB per 5 s per open studio; negligible.

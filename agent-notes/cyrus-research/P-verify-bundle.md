# P: Verification and health bundle (2026-10-10)

Branch `feature/cyrus-r19-verify` (worktree `/tank/dev-worktrees/cyrus-r19`, from `feature/cyrus-r2`), three commits. Nothing deployed, merged to main, migrated or switched on. Raw real runs: `verify-flights-2026-10-10.json`. Owner items: OWNER-ACTIONS.md "Verification + health bundle". Docs: "Cyrus playtest bots", "Cyrus Server Doctor", "Cyrus mod health telemetry".

## 1. Playtest bots (commit 32d31d0f93) - DONE
A ModSpec's functional acceptance tests compile (deterministic, no model) into a typed plan of 14 step kinds (join, command, console, hold, right-click, wait; expect chat / no chat / item / no item / effect / title / moved). Test Flight runner `tf-lite-4` adds a required `playtest` check: after the boot checks, a pinned Mineflayer 4.39.0 player (npm ci from a committed lockfile, integrity-checked) joins over loopback inside the flight's private netns as uid 65534 (heap cap, hard timeout, exact-PID kill) and runs one scenario per test. Server log errors during a scenario fail it. Tests that cannot be scripted are reported `not_scriptable` with the reason; manual/boot tests are kept apart.

**RAN (node-2, Paper 1.21.11):** spec with 6 functional criteria + 1 boot + 1 manual.
- Good fixture: flight passed, 6/6 acceptance checks (join message, named item, effect + title + reply, teleport, hold + right-click, negative "never replies error"). Bot join 1.7 s; flight 34.5 s (+~13 s for the playtest), 924 MB.
- Deliberately broken fixture (`/tfgem` gives dirt): every boot check PASSED (a boot test alone calls it fine); playtest FAILED exactly T-2 (inventory: "1x dirt "Cyrus Gem"") and T-5 (cannot hold a diamond). Proves the bot catches a behaviour bug the boot gate misses.
- First attempt honestly reported `not_run` (bot dir was 0700); fixed and re-run.

**NOT RUN:** versions other than 1.21.11 (refused, not skipped); gate-sweep/build-path wiring; model-written criteria; GUIs, blocks, combat, mobs, resource packs, several players.

## 2. Server Doctor (commit 6b71fe12ba) - DONE
Read-only report for any server (no Cyrus mods needed): server facts (software, version, build, Java, loader), plugin/mod inventory (R2 inventory + Fabric/Quilt/Forge/NeoForge descriptors), conflicts (the R2 engine over everything installed), known problems (platform rules, version ranges, curated known-broken list shipped EMPTY until entries with a source exist), last-start log analysis, performance hints (view/simulation distance, lag, start time, optional plan memory, TPS/MSPT only through a console limited to `tps`/`mspt`). Every section says what it could not check; `incomplete` is never shown as healthy. Off behind `CYRUS_SERVER_DOCTOR`.

**RAN (node-2):** a throwaway Test Flight server (kept only for the read, then removed, verified) seeded with a command/permission conflict, a plugin that throws in onEnable, a legacy plugin and a Fabric mod in `plugins/`: 2 problems, 6 warnings, 1 info, 4 not-checked lines, all expected findings present. The real log taught three facts now in the rules: Paper 1.21.11 loads plugins before "Starting minecraft server version" (my first run missed the Fabric load error because of this; fixed and re-run), the 1.21 "Error loading plugin" wording, and a WARN for a duplicated permission (the R2 engine said "no log line"; message corrected). The real log is a test fixture.

**NOT RUN:** any customer server (by rule), any Fabric/Forge server boot (rules on fixtures only), UI/route/host adapter.

## 3. Mod health telemetry (commit 33741978fd) - DONE as scoped (schema + aggregation + retention, tests only)
Strict signal schema (boot ok, enable error, exception/crash signature = exception class + first frame in the mod's packages, command registered/missing); no player data, messages, IPs, paths or free text can pass (tested with a log full of them). Needs the flag, a worker secret and per-server owner consent. Rotating HMAC server keys (30-day windows), k-anonymity (>= 2 servers), lifecycle feed in the existing `broken` shape (API mismatch -> "out of date"), admin ops block (optional, nothing passes it yet), retention 30 days raw / 180 days aggregates. DRAFT SQL for two tables; models deliberately not in schema.prisma.

**NOT RUN:** no collection from a real server, no storage, no job/route/consent UI. Privacy wording needs a lawyer.

## Checks
- Full suite after the last commit (`devhost test test/cyrus-*.test.ts test/modbuilder-*.test.ts`): 1674 tests, 1673 pass; the one failure is `test/cyrus-admin.test.ts`, the documented batch-only flake (a `server-only` import via lib/geo-ip in the parallel batch); it passes alone, 31/31. `devhost tsc` clean. `feature/cyrus-r2` (8b716fc44f) had no new commits to merge at the end.
- Host seam: no new Nxeon imports under lib/cyrus (the seam test is part of the suite).
- Deviations: the real-run scripts ran in an ssh session on node-2 (not inside `devhost run`): the agents slice had ~7.2 of 7 GB anon in use by other agents' dev servers, and a 1 GB Paper server inside it would have been OOM-killed. Flights still took the Test Flight lock (they waited through several `busy` retries for other agents) and ran one at a time.

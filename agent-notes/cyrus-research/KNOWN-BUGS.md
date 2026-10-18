# Known bugs (real, found and fixed) — kept for future training with Cyrus

This file is a record of real production bugs found in Cyrus (or its Nxeon host platform) by live observation,
not synthetic test failures. Each entry exists so the same pattern is never repeated, and so the facts here can
later be distilled into Cyrus's own build-time knowledge (e.g. a precheck rule, a host-seam invariant, or an
eval case) once there's a mechanism for that. This is NOT the same thing as
`services/modbuilder/rules/failure-rules.json` (generated-Java-code compile failures) — see the note at the
bottom of each entry on what is and isn't the right home for it.

## Index (kept current; every change updates this table, see docs/cyrus/14-how-to-work-here.md)
| Date | Bug | Status 2026-10-18 | Evidence |
|---|---|---|---|
| 10-15 | BetterModel config.yml left root-owned | LIVE-FIXED | 7be0a81f / 457fc212 (rc18), own-game.ts on main |
| 10-15 | Black/purple checkered creature texture | LIVE-FIXED (real-client check OPEN) | followups 45b751fc (rc19) |
| 10-15 | Intake guard false positives | LIVE-FIXED, WATCH (guard smoke FAIL today) | 660d7e35 (rc19), guard-2026-10-15.1 |
| 10-15 | Refines silently regress | LIVE-FIXED | 45ab0502 (rc19), pv-2026-10-17.1 |
| 10-16 | Regression guard could not recover creature wiring | LIVE-FIXED | a5d770a4 (rc20) |
| 10-17 | Refines revert config defaults | LIVE-FIXED | 818bee9b (rc21), image 0.26 |
| 10-18 | Deploy wizard crash from browser auto-translate (removeChild x222) | LIVE-FIXED | 0b9f935f / 8e41ce70 (rc21) |
| 10-18 | Dashboard pages shipped all 3,000 simple-icons (6.4 MB JS) | LIVE-FIXED | af5a1d55 |
| 10-18 | Asset library sounds unplayable (no player; preview recipe never requested) + N+1 thumbnail signing | FIXED-ON-BRANCH | feature/cyrus-ux-audit 68723eae |
| 10-18 | Nxeon chat bubble / hosting promo / survey / error card / 404 shown inside Cyrus | FIXED-ON-BRANCH | feature/cyrus-ux-audit 2202bcfa, 0b67b0b8, e7b585c9 |
| 10-18 | Studio breadcrumbs "Minecraft" and category both link to the core | OPEN | StudioShell.tsx, EE audit #14 |
| 10-18 | Guard smoke test FAILS on image 0.26 | OPEN | launch-check.sh 2026-10-18 09:34 |
| 10-18 | Cyrus nightly backup stale (98 h) | OPEN | launch-check backup-fresh, alert backup-stale |
| 10-18 | Weekly-limit outage handling R7-1..4 | OPEN (FIXED-ON-BRANCH, uncommitted: fix/cyrus-ai-outage-handling) | /tank/dev-worktrees/cyrus-outage, 8 modified files |
| 10-18 | Build service froze (server.js 100% CPU, /health silent): javaast.outline looped on `implements A, B` via the workspace map | FIXED-ON-BRANCH, needs modbuilder:0.27 | feature/cyrus-mob-skin-studio c9f803e3, test/cyrus-javaast-outline-hang.test.ts |
| 10-18 | Creatures invisible in the Assets tab ("can't see any of the mob skins"; only a "mob skin: soon" card) + skin-candidate rows could become the creature | FIXED-ON-BRANCH (flag CYRUS_MOB_SKIN_STUDIO off) | feature/cyrus-mob-skin-studio 0cdef5b4, fcfca622 |
| 10-15 | Creature checker false positive (model key built by concatenation) | OPEN | tracker "Infinite Dungeon round 2" |
| 10-15 | Dungeon texture bug unproven (pack not accepted?) | OPEN | needs real client |
| 10-18 | Wizard coupon_invalid had no code recorded | LIVE-FIXED (recording only) | 3c2aed27 |
| 10-18 | Google login on cyrus.my creates a Nxeon account (DA D3) | OPEN (owner chose ON, D-67) | DA section D3 |
| 10-18 | Design-downgraded builds break the prompt cache on their first repair ($9.96 in 14 builds) | FIXED-ON-BRANCH (flag MB_SESSION_FREEZE) | feature/cyrus-efficiency, EA report |
| 10-18 | Tier builds escalate a first, small compile repair to Opus (5 of 5 escalations; $5.14 vs ~$0.53) | FIXED-ON-BRANCH (flag MB_ESCALATE_KIND) | feature/cyrus-efficiency, EA report |
| 10-18 | Refine holds 2.3x too low (32 of 34 Saka refines charged past the hold) | FIXED-ON-BRANCH (flag CYRUS_CHANGE_COST_HISTORY) | feature/cyrus-efficiency, EA report |
| 10-18 | phaseChars.thinking is always 0 (Sonnet 5 does not stream thinking) | OPEN (documented; measure thinking as output - streamed chars/3.3) | EA report finding 5 |
| 10-18 | Room Studio 500 on an image-attached generation (owner, 10:02:24) = nginx temp dirs owned by nobody | LIVE-FIXED (host, ~10:08); code: handler errors now logged + messaged (FIXED-ON-BRANCH) | feature/cyrus-room-studio-v2, entry below |
| 10-18 | Assets tab showed no structures in production (the list required the upload store) | FIXED-ON-BRANCH | feature/cyrus-room-studio-v2 |
| 10-18 | Room generator wrote lantern states on sea lanterns (dungeon F1), dropped rooms broke the build (F2), per-tick default 2000 (F3), lost-build race (F9) | FIXED-ON-BRANCH (image bump 0.27 for F2/F3) | feature/cyrus-room-studio-v2 |

---

## 2026-10-15 — Delivered BetterModel config.yml left root-owned, silently disabling BetterModel and every dependent mod

**STATUS 2026-10-18: LIVE-FIXED.** Evidence: `7be0a81f` (orchestrator `ownGame`) merged via `457fc212` into rc18; follow-up `1e0ba792` (deliverCreatures, modpack placers, engine.ts catch) and `lib/cyrus/host/own-game.ts` are on main (af5a1d55, live release 20261018T082948Z). Residual OPEN: never confirmed from the owner's ServerMod/Job rows that the incident came through the standard install path (inferred from code).

**Severity**: every creature-mod or managed-config delivery to a real server, on the FIRST write of that file (not
a regression on repeat deliveries, because the second delivery's `cur.equals(want)` check usually short-circuits
the write once the bytes already match — the window is the first install/update that actually changes the file).

**Found by**: owner report (a customer's mod commands on kodi.playnxeon.com all failed with "An unexpected error
occurred trying to execute that command") + live log inspection on the real server (Server id
`cmuzuj8wl00xshlv49mfv4a1p`, container `mc`).

**The causal chain, in plain language**:
1. Cyrus delivers a mod with animated creatures. Its delivery orchestrator (`lib/cyrus/delivery/orchestrator.ts`,
   the "place" step) writes BetterModel's managed `config.yml` straight to the guest server with
   `jfs.writeFile(cfg, want)`.
2. The guest SSH connection always authenticates as root (`lib/sftp.ts`, `lib/ssh-exec.ts`), so that write lands
   on disk as `root:root`, mode 644 — and nothing afterward fixed the ownership.
3. BetterModel itself runs as the server's own unprivileged `minecraft` user. On every `onLoad()`, its own code
   (`kr.toxicity.model.bukkit.configuration.PluginConfiguration.create` -> `FileConfiguration.save`) tries to
   re-save that same `config.yml`, and gets `java.io.FileNotFoundException: ... (Permission denied)`.
4. That failure leaves a Kotlin `lateinit var props` uninitialized inside BetterModel. Its `onEnable()` then throws
   `UninitializedPropertyAccessException`, and BetterModel disables itself.
5. Paper does not hard-block a plugin that declares `depend: [BetterModel]` when the dependency failed to enable —
   it still proceeds to enable the dependent plugin (e.g. the customer's InfiniteDungeon). That plugin then throws
   `NoClassDefFoundError: kr/toxicity/model/api/platform/PlatformEntity`, because BetterModel's classloader/instance
   never initialized.
6. The customer sees every one of the mod's commands fail with Bukkit's generic
   `org.bukkit.command.CommandException: Cannot execute command '...' in plugin ... - plugin is disabled`, which
   reads to them as "An unexpected error occurred trying to execute that command" — nothing in that message points
   at ownership, permissions, or BetterModel at all. The real cause is two dependency hops away from the symptom.

**Why it wasn't caught earlier**: Test Flight (the pre-delivery gate) runs the plugin jar inside MockBukkit, a
mock server in a throwaway JVM — it never touches a real guest filesystem over SSH, so it never exercises the
real delivery write path or the real guest's root-vs-minecraft-user permission boundary. A build can pass Test
Flight cleanly and still break this way on its first real delivery.

**The fix**: `lib/cyrus/delivery/orchestrator.ts` gained a small shared helper, `ownGame(jfs, base, paths)`, that
mirrors `lib/nxeon-platform/api.ts`'s own `own()` (the generic platform file API already did this correctly for
every ordinary write/mkdir/rename/copy it performs) — give any written path INSIDE the game folder the game
folder's own owner via the journal's `chownLike`, best-effort, swallowing any failure so a guest without a working
chown helper never fails the delivery. It is now called after every guest-folder write the orchestrator's "place"
step and Config Studio apply step perform: BetterModel's `config.yml`, every creature `.bbmodel` file, the
datapack zip, and the Config Studio's rewritten settings file. Cyrus' own delivery record (under the guest's
`.nxeon-cyrus` state directory, NOT inside the game folder) is deliberately left root's and is never passed to
`ownGame()`. A second, smaller related bug was found and fixed in the same pass: the Pack Loader config writer
(`lib/cyrus/packhost/deliver.ts`) already called `chownLike` but did not swallow its failure — wrapped in
`.catch(() => undefined)` to match the same best-effort contract.

**Files touched**: `lib/cyrus/delivery/orchestrator.ts` (the fix + `ownGame()` helper), `lib/cyrus/packhost/deliver.ts`
(swallow chown failure), `test/_cyrus-delivery-fakehost.ts` + `test/cyrus-delivery.test.ts` (regression tests),
`docs/cyrus/07-operations.md` (incident row + a new "Guest-folder write ownership" section documenting the
invariant).

**Still open / NOT fixed in this pass** (same bug class, found while searching, deliberately left alone because
the brief scoped this fix to the orchestrator): `lib/cyrus/creature/deliver.ts`'s `deliverCreatures()` is a
separate, parallel write path (used outside the R5 delivery journal) that writes the exact same `config.yml` and
model files with NO chown call at all. `lib/cyrus/modpack/install.ts` / `lib/cyrus/modpack/engine-placer.ts`
(Mod Pack member placement — plugin jars, configs, data packs) also write through a plain `fs.writeFile`/`rename`
with no chown call, even though the `fs` they receive from the orchestrator (`t.jfs`) already has `chownLike`
available on it. `lib/mods/engine.ts` (the ordinary, non-Cyrus Mods-tab installer) already calls `chownLike` once
at the end of an install, but the call is NOT wrapped in a catch, so a guest where chown itself fails would throw
past that function's own rollback try/catch. See the dated session report
`/root/claudeskills/agent-notes/cyrus-research/DG-delivery-ownership-fix-2026-10-15.md` for the full list and
exact line references.

**UPDATE 2026-10-15 (follow-up pass, commit 1e0ba792 on the same branch) - the "still open" list above is now
CLOSED, and site 1 was the REAL cause, not the orchestrator.** Traced with file:line evidence
(DH-delivery-ownership-fix-2-2026-10-15.md): the standard "install this build" action
(`app/api/mod-builder/builds/[id]/install/route.ts` -> `lib/modbuilder/install.ts:160` `enqueueModOp`
-> `lib/mods/queue.ts:42`, a plain GAME_MOD_SYNC payload with no `cyrusDelivery` key) is NOT routed to the
orchestrator (`worker/game-mods.ts:85` only diverts payloads carrying that discriminator, which come from
Designer Studio ship / Mod Packs / Config Studio send). It runs the ordinary engine loop and, for a Cyrus
minecraft mod, `worker/game-mods.ts:173-185` -> `afterCyrusModChange` -> `deliverCreatures()`
(`lib/cyrus/assets/deliver-worker.ts:32-36`), which wrote config.yml and the models with zero chown. The first
pass fixed a real but rarely-used sibling; the live incident came through `deliverCreatures()`. Fixed now there,
in Mod Pack placement (`modpack/install.ts` fsPlacer + packs.json, `engine-placer.ts` config files; the unit
record stays root's), and `lib/mods/engine.ts` chownLike is now `.catch`-swallowed. Shared helper moved to
`lib/cyrus/host/own-game.ts`. Residual: it is inferred from code, not log-proven, that InfiniteDungeon came
via the standard install; the owner's ServerMod/Job rows for that server would confirm (payload without
`cyrusDelivery`).

**Lesson (one line)**: every guest-filesystem write in the delivery path must restore game-folder ownership; Test
Flight does not catch this because it never exercises the real delivery write path.

**Where this knowledge does NOT belong**: `services/modbuilder/rules/failure-rules.json` is specifically
generated-Java-code compile-failure knowledge (javac/Bukkit API patterns enforced by `precheck.js` against a
model's generated `.java` source, mined from real build failures). This bug is a platform delivery/infrastructure
bug — it has nothing to do with what a model generates, and a precheck rule has no way to see or affect it. No
entry was added there; forcing one in would misrepresent what that file is for. See the parallel note left in this
same research directory's tracker instead.

---

## 2026-10-15 - Infinite Dungeon "mob with the black and purple checkered texture on floor 1" (bonewarden) - SETTLED with artifacts

**STATUS 2026-10-18: LIVE-FIXED (code), real-client check OPEN.** Evidence: overlay allowlist + `after-start.ts` hand-off from `feature/cyrus-followups` merged `45b751fc` (rc19, live). Not confirmed on a real client after the owner restarts the server and accepts the animated-creatures pack. The 1.13.0 wiring-loss part is covered by the regression-guard entries below.

**Verdict: Cyrus delivery bug (two of them), not a client that declined the pack.** Evidence, all mechanical
(full write-up: `DP-followups-2026-10-15.md`):

- The owner's server ("My server", cmuzuj8wl00xshlv49mfv4a1p) runs Infinite Dungeon **1.6.0** (mb3879f4526e730a7e96b1,
  ServerMod INSTALLED 12:55; managed BetterModel 2.2.0 + Pack Loader 0.1.0 installed). Installed through the standard
  Mods-engine path (`worker/game-mods.ts` -> `afterCyrusModChange` -> `deliverCreatures`): models written, restart asked.
- The 4 stored creatures re-compile to the recorded bbmodel sha256; each `.bbmodel` has one embedded, valid PNG
  (crc ok; bonewarden 128x128 = its resolution), every face references texture 0, no UV outside the resolution. Not a
  texture-path/namespace/UV defect. The mod pack (d302b19f / 6e4eab95) is pack_format 75 (= 1.21.11), only nx_oqyxirj4
  sounds + item textures; BetterModel models are not supposed to be in it (BetterModel builds its own pack).
- `/tank/cyrus-packs/p` (what cyrus.my/packs serves) has NEVER held a BetterModel pack (no `assets/bettermodel` in any
  of the 14 zips). Bug 1: the only caller of `handoffBetterModelPack` is the delivery orchestrator, and only when it
  restarts the server itself; the Mods-engine path never hands BetterModel's pack off. Clients get the mod pack only ->
  BetterModel's display items (`bettermodel:bm_models`) render as the missing-model magenta/black cube.
- Bug 2 (real Paper 1.21.11 boot via Test Flight, runs tf-1-21-11-mv9x17jr-d6e2ed with the 4 dungeon models and
  tf-1-21-11-mv9x42x9-00f3aa with the banshee example): BetterModel 2.2.0 writes `build.zip` with pack.mcmeta OVERLAYS
  `bettermodel_modern/` + `bettermodel_legacy/` (incl. `bettermodel_legacy/assets/minecraft/models/item/leather_horse_armor.json`).
  `normalizeBetterModelPack` refused it: "unexpected file in BetterModel's pack: bettermodel_legacy/...". So no 1.21.x
  server could ever get the pack, by any path. (The handoff was only ever verified with 3.5.0 / Paper 26.2.)
- Fixed on `feature/cyrus-followups`: overlay allowlist + `lib/cyrus/creature/after-start.ts` hand-off after the
  platform's GAME_POWER start/restart (tests in `test/cyrus-creature.test.ts`). Owner action after deploy: restart the
  server from the panel once; players re-join and accept the "animated custom creatures" pack.
- Separate, NOT the magenta cause: the latest build 1.13.0 (mb05dabe83580f8491a546) no longer uses BetterModel at all
  (no `depend`, no `kr/toxicity/model` classes) while still recording 4 creatures - the change request (boss arenas)
  regenerated MonsterManager without the model attach; on the designer route the creature cross-check only checks
  boss-worn models, so it passed silently. Installing 1.13.0 would ship models + BetterModel that nothing attaches.

**Lesson**: a Test Flight that "places 4 models" proves BetterModel loads them server-side only; nothing checked that
the generated pack is ever published and offered. A 1.21.x flight must collect `plugins/BetterModel/build.zip` and run
it through `normalizeBetterModelPack`.

## 2026-10-15 - Intake guard refused the owner's Infinite Dungeon boss refines (false positives) - FIXED on branch, needs image

**STATUS 2026-10-18: LIVE-FIXED, but WATCH.** Evidence: `fix/cyrus-guard-false-positives` merged `660d7e35` (rc19), `GUARD_VERSION guard-2026-10-15.1` in main route.js, image 0.24+ (now 0.26). Dungeon rounds 3-6 still hit guard refusals before rc19 and passed after. OPEN: today's launch-check guard smoke (2026-10-18, image 0.26) FAILS (injection prompt not refused): see the new entries at the bottom; also `fp-chunk-injection` still open.
- Builds mbbee4a3822b8cbeb16f9c (`guard:malware`), mbed127678a15c23a6b771 and mb7c8b6bb3709d2427fec2 (`guard:injection`),
  3-5 s, ~$0.003 each, tokens released. Texts: plain boss design ("icicle volley, a ground slam that slows, a frost nova,
  two phases ... a unique drop"; "Give the Frost Colossus we just added its abilities ..."). Verified FALSE POSITIVES.
- Root cause (live re-runs, raw Haiku output): `server.js guardRequest` sent a change as `rec.prompt + "\n" + changeRequest`
  with no framing; rec.prompt is the FIRST description (stage 1, "two room types ... Keep it small"), 15 changes older.
  Haiku: "two unrelated plugin descriptions concatenated", "references the Frost Colossus we just added which was never
  described ... injection". Not the words kill/slam/projectile/drop/phase (fresh boss prompts with them all pass).
  The refusal answers were 91-116 output tokens of prose (an ALLOW is 6), hence $0.003 vs $0.0012.
- Fix (branch fix/cyrus-guard-false-positives, guard-2026-10-15.1): change judged on its own text as `<change>`
  (`route.js guardInput`), clauses (f)/(g), guard-directed instructions = injection, framing tags defused,
  GUARD_VERSION on rec.guard.version -> CyrusGuardRefusal.guardVersion. Labelled <plugin>+<change> was tried: still
  refused 2/8 ("change mentions things the plugin part never mentions"), rejected.
- Measured live (1 sample each, $0.41 total): must-pass 38/39 (old 34/39; regression set 30/30 vs 26/30), must-refuse 19/19 (old 17/19: change-part
  "print your system prompt" and a fake </change> tag were ALLOWED by the old wording). Still open: fp-chunk-injection.
- Deploy: build-service image bump (scripts/cyrus/deploy-modbuilder.sh) + portal promote (store.ts guardVersion, optional).
  Notes: DS-guard-false-positives-2026-10-15.md.

## 2026-10-15 - Refines silently regress what the previous version had (Test Flight passes) - FIXED on branch, needs image

**STATUS 2026-10-18: LIVE-FIXED.** Evidence: `feature/cyrus-refine-regression-guard` merged `45ab0502` (rc19); `preserve.js` on main, live `preserve.mode=on pv-2026-10-17.1`. Replay on the real chain proved restores; no live regression build observed since.
- Evidence (Infinite Dungeon chain, /root/cyrus-eval/dungeon-2026-10-15, CK-infinite-dungeon-2026-10-15.md "Round 4 + CORRECTION"):
  v1.8.1 mbdeca41d1bf0cbebd4d83 .. v1.26.0 mbe94b7e5992e0a1c0df8d shipped config.yml `max-floors: 100` / `floor-interval: 10`
  (plus the final boss health 2.5 / scale 1.3 / "all 100 floors" message) again after v1.7.0 mb3fa7542c798d8a12679e had been
  refined to 11 / 3; v1.27.0 mb375d7c58807fd4483998 and v1.27.1 mb51322a365e1e9476d7be lost `depend: [BetterModel]` and every
  BetterModel.model attach (v1.26.0: 24 keys, BetterModel in MonsterManager + BossManager). Reading the real jars also shows
  v1.7.0 had lost `depend: [BetterModel]` vs v1.6.0 mb3879f4526e730a7e96b1. Same class as MOD-SLATE "Refines can silently drop
  creature wiring" and the 1.13.0 entry above.
- Root cause: nothing compared a change build with its base; the ledger only tracks requirement keywords, the creature soft
  check is one repair then a warning (and does not run when the creature lane is off), Test Flight cannot see defaults.
- Fix (branch feature/cyrus-refine-regression-guard from release/cyrus-rc19, `services/modbuilder/preserve.js`, MB_PRESERVE,
  pv-2026-10-15.1): BASE vs NEW invariants every round (plugin.yml depend/softdepend/commands/permissions/api-version; config.yml
  keys, defaults that went back to an OLDER lineage value, list shrink; creature specs + attach; asset specs; listeners /
  executors; soft: event types, getCommand wiring, enum constants). Mechanical restore where safe, else ONE targeted repair
  round, else failed build `errorCode: regression` (no charge, settle reason failed_regression). Escape: the change request /
  planner lines naming the key or the removal. Replayed offline on the real config.yml / plugin.yml of the chain: 1.7.0->1.8.1
  5 reverts restored (11 / 3 back), 1.26.0->1.27.1 depend restored and the requested 11 / 3 permitted, 1.6.0->1.7.0 depend
  restored; 1.26.0->1.27.0 attach loss goes to the repair round (code). Unchanged versions: zero findings.
- Deploy: modbuilder image bump (preserve.js in the Dockerfile COPY, prompt mb-2026-10-15.1) + portal promote (types, store.ts
  preservation, Explain tab, economy failed_regression, eval stats). Not deployed.

## 2026-10-16 - Regression guard blocked creature-mod refines but could not recover them - FIXED on branch, needs image

**STATUS 2026-10-18: LIVE-FIXED.** Evidence: `fix/cyrus-creature-wiring-recovery` 984615ac merged `a5d770a4` (rc20), `wiring.js` on main, image 0.25/0.26. Still OPEN (as written): a wiring hunk the model REPLACED with mixed code, a renamed model key literal, and the designBoss lane misfire on "bosses on floors ..." in the planner.
- Builds mb2e1ca55853f0c13cc1c5 ($3.61), mb9c7e45e78ba7584b7190 ($1.95), mb47fc77e9605bae104d5e ($2.38), base v1.27.0
  mbaf46c4ce88096ffffaa8 (stage 34; the task note said v1.26.0 mbe94b7e5992e0a1c0df8d, the records say mbaf46...): all
  `errorCode: regression`, tokens released. Evidence: build VM /var/lib/modbuilder/data/builds/<id>/{build.json,ws} (read only).
- What was dropped: in MonsterManager every BetterModel line (4 imports, the MODELED_IDS set, 23 MODEL_* key constants,
  modelKey(), the tracker map, attachModel(), the guarded attach call, every animate / damageTint / close, the reattach in
  the chunk-load path); BossManager's lichking attach. Surgical deletions, NOT a rewrite from a summary: the refine flow
  copies the full base workspace and the model edits with Read/Edit.
- Root cause: the change round never touched creature code (edited only the main class, config.yml, plugin.yml). The planner
  put a designBoss lane next to the request ("bosses on floors 3, 6, 9"), textures.js switched the creature lane off, and
  server.js put the BetterModel API on the javac classpath only with the creature lane on. The UNCHANGED base failed to compile
  ("package kr.toxicity.model.api does not exist", 35 errors: reproduced on node-2 with the VM's JDK 21 + Paper 1.21.11 jars,
  compiles clean with bettermodel-api-2.2.0), apiHints said "Paper has no class EntityTracker. Do not use it; use a different
  API", rule 1 says "only Paper and the JDK", so the compile repair ($1.1-1.8) deleted the wiring. The guard's repair
  ($0.08-0.88, resumed session, same classpath) was asked to restore code that could not compile, and did not.
- Fix (branch fix/cyrus-creature-wiring-recovery, 984615ac): creatureCp (base uses BetterModel = API on the classpath;
  "unavailable" before any model call if not installed); services/modbuilder/wiring.js mechanical restore from the base
  (javac-checked, reverted if it breaks the compile); block-only repair on the cheap model in a fresh session; early stop
  when the creature class was rewritten; apiHints skip for plugin-API imports; prompt mb-2026-10-16.1 creature wiring
  invariants + one creature registry class. Real fixtures: 3/3 restored, restored workspaces compile clean (real javac) and
  pass the strict scan. Still open: a wiring hunk the model REPLACED with mixed code, or a renamed model key literal, needs the
  repair round; the designBoss lane misfire on "bosses on floors ..." itself (planner) is not changed here.
- Deploy: modbuilder image bump (wiring.js in the Dockerfile COPY, prompt mb-2026-10-16.1); portal types only (optional).

## 2026-10-17 - rc20: refines still silently reverted config defaults (guard said "clean") - FIXED on branch, needs image

**STATUS 2026-10-18: LIVE-FIXED.** Evidence: `fix/cyrus-preserve-config-defaults` merged `818bee9b` (rc21), live `promptVersion mb-2026-10-17.1` / `pv-2026-10-17.1` on modbuilder:0.26 (built 2026-10-18 08:15). Dungeon round 6 recorded config-default drift twice BEFORE this image; not re-observed since, but no refine has run on 0.26 yet (weekly limit).
- Evidence (live rc20, modbuilder:0.25; records /root/cyrus-eval/dungeon-2026-10-15, workspaces build VM
  /var/lib/modbuilder/data/builds/<id>/{build.json,ws}, read only): base v1.34.0 mb8fcdf5c69a68c7d31338 max-floors 11 /
  boss.floor-interval 3 / config-version 1 -> B2 "room size" mb47c6016c9359b0bf4ae8 v1.35.0 shipped 100 / 10; base v1.38.0
  mbaf7cfdc87aeb857c2dac (11 / 3 / config-version 4) -> D2 Frost Colossus mbcb4848ba72a2387d8af5 v1.39.0 shipped 100 / 10 /
  config-version 2. Manual restores: mba4f28ee4003d7c2db62d, mbf8812bb2484d3eb42902. (The task note said config-version 5 on
  v1.34.0: the real files say 1 there, 4 on v1.38.0, 5 only after the D2 restore v1.40.0.)
- Why the guard missed it: lineage WAS available (16 ancestors) and the guard did run; its verdict was "clean" because the
  model's config.yml still had 11 / 3. Both builds had the Config Studio route (assets.config); configs.js configRound runs
  AFTER the guard and rewrites config.yml from assets/config/schema.json with "declared defaults win". That schema was written
  by the first settings-routed build (100 / 10) and never updated by refines without the route (the service keeps the base's
  schema file), so it put the old values back. NOT Java: getInt("dungeon.max-floors", 11) / getInt("boss.floor-interval", 3)
  stayed in every version; no addDefault / saveDefault regeneration. Secondary: the "number with concept" naming rule let
  "height 10 to 14 ... boss arenas" name boss.floor-interval 10.
- Fix (branch fix/cyrus-preserve-config-defaults from main bc678074): configs.js syncStaleDefaults (a schema default the round
  did not change follows config.yml); preserve.js keepDefaults + server.js keepDefaultsStep after the settings round, before
  javac: every changed default (config.yml, schema, Java get*("key", fallback) / addDefault / static final fallback) the
  request does not name goes back to the base value, config-version never decreases, notice "Kept your earlier setting X = Y",
  preservation.kept; number must stand within 3 words of the concept; prompt mb-2026-10-17.1; pv-2026-10-17.1.
- Measured offline on the whole real chain (65 workspaces, 42 refines, with lineage): 10/10 silent reversions restored (B2 2,
  D2 3, v1.8.1 5), 0 false restores, 18 requested changes kept. Without lineage: 8 restored, 0 false (misses, not false hits).
  The chain never reverted a Java literal (Java path tested on synthesized fixtures). No paid model call.
- Deploy: modbuilder image bump (no Dockerfile change) + portal promote (types/store/Explain tab/eval; optional).


---

## 2026-10-18 - NEW (OPEN): guard smoke test fails after the build-account swap / image 0.26
- Evidence: `bash scripts/cyrus/launch-check.sh` 2026-10-18 09:34 UTC: "Guard smoke result: fail, 0.1 d old: the guard did NOT refuse the injection prompt". Previous check (2026-10-15 12:20) was PASS. Since then: images 0.23 -> 0.26, guard `imageguard-2026-10-17.1` added, build token swapped twice (10-13, 10-18 09:28).
- Not yet diagnosed: candidates are (1) the guard model call failing open while the account was limited (R7-3 "guard fails open" in the outage list), (2) a guard prompt change in 0.25/0.26, (3) the smoke itself. Do not widen the beta allow-list until a re-run passes; rollback image is 0.25.
- Status: OPEN.

## 2026-10-18 - NEW (OPEN, FIXED-ON-BRANCH uncommitted): weekly-limit outage handling (R7-1..4)
- Evidence: dungeon round 7, `mbdc7907f98320723a9094` failed `ai_unavailable`, retry `mb19ae6387d9cd4ba8ee29` cancelled, $0 spent; tracker "Dungeon round 7". Bugs: misleading "busy" message for a weekly limit, queue keeps accepting during an open breaker, guard fails open, keyword-routed room lane.
- Fix: `fix/cyrus-ai-outage-handling` (still = main af5a1d55; 8 uncommitted files in /tank/dev-worktrees/cyrus-outage). Status: FIXED-ON-BRANCH once committed; not merged.

## 2026-10-18 - NEW (OPEN): Cyrus nightly backup stale
- Evidence: launch check "last success 98.2 h ago"; `backup-stale` alert firing; DF noted the service was SIGTERMed 2026-10-15 05:07 during the SFX mirror. Off-box success 2026-10-14T07:20Z. Root `/` 89% used (5 GB free). Status: OPEN, owner action `systemctl start cyrus-backup.service`.

## 2026-10-18 - Build service subscription token hit its weekly limit (operational, RESOLVED by swap)
- Evidence: swap documented in tracker 120. Lesson: `swap-build-account.sh preflight` before `rollback` makes rollback restore the CURRENT token as the newest `acctbak`. Permanent fix = API key (OPEN, owner).

## 2026-10-18 - First beta invite on a fresh database locks every admin out of /admin/cyrus - FIXED on branch (bundle B)
- Found by: code trace of the private-beta journey (bundle B, Sonnet subagent, confirmed by reading `lib/preview-access.ts`).
- Chain: no `preview_access_emails_modbuilder` row = `previewAllowlist` serves the built-in default (owner). `adminCyrusBetaAdd`
  read the row as null -> empty list -> wrote ONLY the new emails. The same list is the gate of every `/admin/cyrus` page, so
  the owner lost the admin (404) with the first Add. `scripts/cyrus/beta-invites.mjs add --apply` had the same flaw.
- Fix (`feature/cyrus-bundle-b`): `effectiveBetaListPure` (start from the effective list, always keep the acting admin);
  CLI seeds from the shared list / default; the add is audited before the mail step; failed sends are named.
- Lesson: when a Setting has a "no row = default" fallback, every writer must start from the EFFECTIVE value, not the row.

## 2026-10-18 - Token sweep made long builds free; our-side failures charged after 3 - FIXED behind CYRUS_TOK_SETTLE_V2
- Found by: billing audit (bundle B). `sweepCyrusTokens` released ANY hold older than 3 h with charge 0, even when the build was
  still running (it then settles against nothing). `settleCharge` treated only ai_unavailable/capacity/regression as ours:
  `interrupted` (service restart), `unreachable`, `lost`, `internal`, `timeout`, `admin_cancelled` used the 3-per-7-days free
  allowance, then were charged in full. A success could also be charged MORE than its hold (uncapped; the overrun silently
  took other balance).
- Also (coordinator, dungeon round 7): three `budget` failures charged in full ($2.52/$4.04/$4.09), one 2,021 tokens on a 400 hold
  (mb6789c556704ecc5db476); a create race marked mb0a13913d48869fb3d8e5 `lost` 150 ms before the service registered it ($1.33 unbilled).
- Fix: settle v2 (env `CYRUS_TOK_SETTLE_V2=1`, OFF by default; owner decision B-1): cap at the hold, those codes free, `budget` and
  failures after a service drop free as `failed_ours` (label + plan-screen rule), 90 s lost-grace (always on),
  `holdSweepAction` keeps running holds (24 h ceiling). Pure + tested (`test/cyrus-bundle-b.test.ts`).

## 2026-10-18 - Data split would have moved Nxeon's own platform tables - FIXED on branch (bundle B)
- `scripts/cyrus/data-split/tables.mjs` derived "Cyrus tables" from every `CREATE TABLE "Cyrus*"`, so `CyrusServerGrant`,
  `CyrusPlatformCall`, `CyrusPlatformIdempotency`, `CyrusPlatformOutbox` (written ONLY by `lib/nxeon-platform` through Nxeon's
  db) were on the move list: after a cut-over every grant check would read a frozen copy. Also `lib/modbuilder/store.ts
  mergeCyrusKey` wrote `ModBuild` via Nxeon's `db.$executeRaw` (the ORM ratchet only sees `db.modBuild`).
- Fix: NXEON_SIDE extended; the write uses `cyrusDb.$executeRaw`; new raw-SQL ratchet in `test/cyrus-db-split.test.ts`.
- Lesson: classify tables by WHO WRITES them, not by name prefix; ratchets must cover raw SQL too.

## 2026-10-18 - Efficiency round findings (bundle C, feature/cyrus-efficiency, FIXED-ON-BRANCH, flags off)
- **Cache break on design downgrade.** `designRound` deletes `rec.assets.design` after the first call when the model wrote an ordinary plugin; the next repair's `--system-prompt` is rebuilt from `rec.assets`, so it differs and the API re-writes the whole conversation (first-turn cacheRead = 2,991 = tool definitions only). Every one of 14 detected breaks was a downgraded build; $9.96. Pattern to never repeat: anything that rebuilds the system prompt (or effort) between calls of ONE session must be frozen for that session. Fix: `MB_SESSION_FREEZE`.
- **Escalation counted every repair kind.** `repairs <= escalateAfter ? generate : escalate` sent the third repair of any kind to the next tier; after two asset repairs a 1-error compile fix went to Opus, which (new model = new cache) rewrote 54-127k tokens at Opus prices. Fix: `MB_ESCALATE_KIND` (same-kind count, never for small compile problems).
- **Refine holds from the change text.** A refine costs what the mod's size makes it cost (it re-reads the project every request); the estimate looked at the change text. Fix: `CYRUS_CHANGE_COST_HISTORY` (last refines of the same mod as the floor of the range and the top of the hold).
- **Instrumentation blind spot.** `phaseChars.thinking` stays 0 because thinking is not streamed as text; do not read it as "no thinking".
Right home later: a seam/invariant test for "system prompt stable within a session" (done in test/modbuilder-efficiency-ea.test.ts for the freeze path).


## 2026-10-18 09:57 UTC - Agent scratch `nginx -t` on the primary chowned /var/lib/nginx to nobody (live uploads broke) - CAUSE RECORDED
- Command (bundle B agent): `bash deploy/cyrus/admin-host-apply.sh --dry-run all` -> `nginx -t -q -c /tmp/tmp.*/nginx.conf -e ...`
  with a scratch main config lacking `user www-data;` and temp paths; nginx (as root) reset /var/lib/nginx/* ownership to the
  default user `nobody`, so the live nginx could no longer write request-body/proxy temp files (uploads, large responses).
  Also run minutes later: `nginx-cyrus-my-check.sh --syntax` (via cyrus-my-apply.sh --dry-run). Fixed by the coordinator.
- Fix: the three scripts no longer run the nginx binary on the primary (render only; syntax check on node-2 via devhost).
- Lesson: `nginx -t` is NOT read-only: it creates/chowns its temp dirs. Never run any nginx binary on the production box
  except the owner's real `nginx -t` of the live config.

## 2026-10-18 - Minecraft first-try round (bundle A): real-eval findings + open-item statuses - FIXED on branch feature/cyrus-bundle-a, needs image + promote
Found by a real eval through the live build service (image 0.26, tier Saka): `bza-rw1` (1.21.11, real-world smoke, 22 builds, $7.95) and `bza-xv1` (1.21.1/1.21.4/1.21.8). Journals `/root/cyrus-eval/bza-rw1|bza-xv1/journal.jsonl` (every build id + cost). Scorecard: `docs/cyrus/minecraft-production-readiness.md`.
- **perf-world-iteration false positive** (3 of 6 creature builds paid a repair round): `event.getEntities()` in an `EntitiesLoadEvent` / `ChunkLoadEvent` handler (ONE chunk) matched the "iterating every loaded entity of a world" rule. Fix `perf.js singleChunkReceiver` (event / chunk / getChunk() receivers bounded; World still flagged).
- **Creature "sound is never played" with no sound lane** (rw-goblin-plugin, rw-village-guard): the creature spec names `ns:<set>.<event>` keys but `assets/sounds/<set>.json` does not exist, so the repair asked for sounds that are not in the pack. Fix `creatures.js`: only shipping sets are required.
- **Unknown template feature** (`claws` on a humanoid, rw-troll): now an autofix line (`fixUnknownFeatures`), not a repair round.
- **Creature checker false positive on concatenated model keys** (Infinite Dungeon 2026-10-15, open since): `creatures.js modelKeyUsed/soundKeyUsed` accept `"<ns>_" + name` / `NAME.toLowerCase()`; `preserve.js` pv-2026-10-18.1 recognises the same wiring (designer route stays exact: Nxeon generates that code).
- **Room Studio lane keyword-routed on refines (R7-4)**: a change routes rooms only by state (`ModBuild.result.assets.rooms`, now recorded by the asset sync; `existingRooms` passed from `create.ts`, never before) or an explicit ask (`asksForRooms`); theme words ("crypt floor", "dungeon mobs") no longer switch it on; "Vault" economy is not a room. Found while fixing: a ROOMS-ONLY result returned early from `syncBuildAssets` and recorded nothing (now recorded).
- **designBoss misfire on "bosses on floors 3, 6, 9"** (2026-10-16): `BOSS_EXCLUDE` covers floor-placed bosses (dungeon / tower / roguelike floors).
- **Intake guard refused a data-pack-only request** (`rw-mushroom-meadow`, `guard:escape`, ev-bza-rw1-edd078e290da): candidate clause `v3-datapack-only` in `eval/guard-candidates.json` (static screen: matches no unsafe prompt). NOT applied: the guard test requires the owner-run Haiku re-measure (~$0.10) before GUARD_PROMPT changes.
- **Eval measurement**: eval-run scored lane selection with the old word router (smoke recall 35.7%); now the planner rules (92.9%). Labels rw-crates / rw-trade-menu corrected (outside the menu IR; honest plain build). Eval runner now stops at the first AI-unavailable failure (shared account weekly limit).
- Status of older open items: creature cap = FIXED live (rc18, 64); config default drift = FIXED live (image 0.26, pv-2026-10-17.1); BetterModel wiring loss = FIXED live (wiring.js; residual: replaced hunks / renamed literals go to the repair round); guard game-design false positives = FIXED live (guard-2026-10-15.1; open: fp-chunk-injection + data-pack-only candidate above); texture/resource-pack acceptance on a real client = STILL UNPROVEN (new headless evidence: Spyglass resource-pack check, `CYRUS_PACK_SPYGLASS`, 29/29 real packs clean); 1.21.1 custom textures = off by flag `MB_LEGACY_TEXTURES` (honest note shown; owner decision).
- Lesson: soft checks that send a repair round must only demand what the build actually ships; a check's false positive costs a model round on every affected build (here 5-6 rounds in 22 builds).


## 2026-10-18 - Room Studio "something went wrong" (500) + an empty Structures card (owner, preview account)
**STATUS 2026-10-18: host cause LIVE-FIXED (coordinator, ~10:08 UTC); code side FIXED-ON-BRANCH `feature/cyrus-room-studio-v2` (not merged).**
- Symptom: `POST /api/cyrus/assets/v1/rooms` with a reference image -> 500 (572 bytes) at 10:02:24; the build service never saw the call; the portal logged nothing; the Assets tab crashed with "TypeError: network error" (6x, 10:03:52-56).
- Cause: not the app. nginx's temp dirs (`/var/lib/nginx/body`, `/proxy`, ...) had been chowned to `nobody` at 09:57:56 by an agent's scratch `nginx -t -c` (entry above). Bodies over 16 KB (an image) failed in nginx (`open() "/var/lib/nginx/body/0000031183" failed (13: Permission denied)`) -> nginx's own 500 page; large responses could not be buffered -> truncated -> "network error".
- Why it looked like an app bug: the studio's client did `r.json().catch(() => ({}))` and showed "Something went wrong." for any non-JSON body, and the studio handler envelope (`lib/cyrus/studios/http.ts run()`) only `console.error`ed (never ErrorLog). The "[object Object]" client-error lines at 09:59 were two curl probes of `/api/log` without a message (logError stringified the wrapper).
- Code fixes: `run()` reports every caught error through the host seam (`CyrusHost.errors.log` -> `logError` -> ErrorLog; PII-free: handler key, a 6-char reference, class + clipped message + 5 stack frames; never bodies / prompts / images / user ids) and answers "Something went wrong on our side (reference X)..."; `/api/log` records "client error report without a message" instead of "[object Object]"; `components/cyrus/studios/studio-fetch.ts` turns network failures, proxy HTML and JSON errors into readable messages (413 = images too large, 502-504 = busy, 0 = connection).
- Second bug found on the way (owner: "can't see any of the generated rooms"): `handleStructureList` returned `rooms: []` whenever the upload store was off, i.e. always in production, hiding every build-lane room. Listing now needs no store (`readDeps`).
- Lessons: (1) a 500 whose size does not match our JSON envelope is a proxy page: check `/var/log/nginx/error.log` first; (2) every API envelope must log to ErrorLog, not only stderr; (3) client error paths must never assume JSON; (4) read paths must not depend on write-side infrastructure (upload store).
- Right home later: a precheck/lint rule "no `.json().catch(() => ({}))` without a status message" for portal fetch helpers.


## 2026-10-18: Cyrus library could not play sounds; Nxeon overlays inside Cyrus (UX audit EE)
- Library: no `<audio>` / play control existed anywhere in the Cyrus UI, and the client only ever signed `thumb@1`, so the backend's `preview-ogg@1` (the ONLY form library audio is served in) was never requested. Every result page also fired one `POST /api/cyrus/library/v2/url` per card (up to 24, all at once, re-signed on every page change) while the production object store held 24 files for 62,777 rows, so thumbnails were cold derivations. Fixed on `feature/cyrus-ux-audit`: player on sound cards, `POST /url { ids }` batch (max 48, rate limit per id), IntersectionObserver + per-tab cache, 60 s browse cache.
- Overlays: the dashboard layout mounts PromoTrialPopup + HeardAboutUsPrompt for every /dashboard route and the root layout mounts the Nxeon live chat everywhere; the Cyrus tree had no error.tsx / not-found.tsx, so crashes and notFound() rendered the Nxeon card / marketing 404. Fixed on the branch (`lib/cyrus/surface.ts`, HideOnCyrus, ChatWidget gate, Cyrus error/not-found).
- Lessons: (1) a backend capability is not a feature until a screen requests it: add a UI ratchet test when shipping a server-only recipe; (2) per-card signing must be batched from the start; (3) a product mounted inside another product's layout inherits every global overlay: keep an explicit "surface" gate.
- Right home later: a docs/cyrus/14 checklist item "new product surface: error.tsx, not-found.tsx, overlay gate".


## 2026-10-18 - "I also can't see any of the mob skins" (owner, Infinite Dungeon, 24 BetterModel creatures)
**STATUS 2026-10-18: FIXED-ON-BRANCH `feature/cyrus-mob-skin-studio` (0cdef5b4 + fcfca622), flag `CYRUS_MOB_SKIN_STUDIO` OFF, not merged.**
- Symptom: the Assets tab listed 108 assets (17 textures + 91 sound events) but not one of the mod's 24 animated creatures; where creatures should be there was only a hard-coded card "mob skin: soon. Mob skins need a per-mob template" (`components/cyrus/studios/AssetsTab.tsx`, `STUDIO_DEFAULTS.mobSkin === "coming_soon"`).
- Cause: not a data loss. The creatures were recorded all along (CyrusProjectAsset kind `model`, RigSpec rows, and `ModBuild.result.assets.creatures`), and Model Studio could already paint them, but nothing linked them from the Assets tab (docs 03 said "not linked from the Assets tab"), and the per-mob template the card waited for was never built. The `assetCount` in the tab label only ever counted textures + sounds.
- Fix: the Assets tab Creatures section + the Mob Skin Studio (docs/cyrus/03-studios.md "Mob Skin Studio"). Every creature now shows its model wearing its delivered skin in 3D, its clips, where the mod uses it, PASS/WARN/FAIL checks (including the delivery byte re-compile) and downloads.
- Second bug found on the way (latent, would have hit the first AI skin): a studio CANDIDATE change build records the creature rows it returns like any build. For a skin candidate that changes a creature's palette, that newer `generated` row would have become the creature's current geometry in Model Studio and in the next build's sync (`studioCreatureOf` takes the newest generated row; a later regular build's identical spec dedupes to the OLDER row, so the candidate would have stayed current). Fixed: `resolveModels(..., skinCandidateIds)` and `studioCreatureFor` drop model rows recorded by candidate builds; `chainOf` lists skin candidates separately and never as the base. Same latent shape still exists in the layer-2 editor's own `resolveModels` (lib/cyrus/modelstudio/editor/service.ts): OPEN, only matters once skin candidates run.
- Also noted, not changed: `chainOf().assets` is the newest succeeded build's assets INCLUDING studio candidates (a texture candidate's pack state shows as the mod's); the Mob Skin Studio reads the newest REGULAR build instead.
- Lessons: (1) a placeholder card for a missing editor hides the data that already exists: list what the project holds first, edit later; (2) every surface that picks "the newest row" must decide what candidate builds are; (3) the tab count must count every asset kind it lists.
- Right home later: a docs-coverage rule "a studio placeholder must name the branch that replaces it", and an eval/fixture case "candidate build rows never become current" for every studio kind.


## 2026-10-18 - Build service froze at 100% CPU on one change build ("planning", /health silent)
**STATUS 2026-10-18: FIXED-ON-BRANCH `feature/cyrus-mob-skin-studio` c9f803e3 (rebased on release/cyrus-rc22 400bb6b0); needs modbuilder image 0.27. Service restarted by the owner ~16:30 UTC.**
- Symptom: from 14:21 UTC server.js pegged one core with no log output, /health did not answer, every build queued; the last build taken was mb03ee8611ba53c46afd68 (a Mob Skin Studio AI skin probe, Saka, base Infinite Dungeon v1.44.0 mb0a72889aebe06f9587f3), stuck in "planning". The probe script lost its own poll (the service stopped answering) and its id; nothing was charged that we know of (the model call never started).
- Root cause: `services/modbuilder/javaast.js` `outline()` looped forever on a type header with two or more supertypes after one keyword. The header loop read one supertype, then stepped back one token (`r--`) unconditionally; at the depth-0 comma of `implements CommandExecutor, TabCompleter` the inner loop consumed nothing, so `r--` / `r++` revisited the comma forever. `outline()` is called only by the workspace map (`workspacemap.js`, MB_WORKSPACE_MAP), which outlines every source file of a change build's base synchronously on the event loop before the first model turn. Infinite Dungeon v1.44.0 is the first base with such a class (`DungeonCommand`, tab completion added in round 7). NOT the skin request text: the same stall happens for ANY change request on that base (route/guard/ledger/preserve text functions were timed on the request: 0-20 ms). Live therefore runs with MB_WORKSPACE_MAP=1 (docs said "off in production"; VERIFY in the VM env / `/health features`). Bug since 1a46316f (2026-10-14 structure round).
- Proof (offline only): `scripts/cyrus/mobskin-service-repro.ts` runs the REAL server.js with a fake CLI and the real base: old javaast + map on = stall in 7 s; fixed = 0 stalls (max poll 281 ms), also with the map off. Instrumented loop guards pointed at javaast.js line 320.
- Fix: step back only when the pass consumed tokens. Guards so no single file can block the loop again: a shared step budget over every loop of `outline()` (64 steps / token + 10k; exhausted = `null`, callers already treat null as "no outline"); the workspace map skips outlines for files > 400 KB, stops outlining after 1.5 s of wall time, and catches errors.
- Test: `test/cyrus-javaast-outline-hang.test.ts`: the real `DungeonCommand.java` as a fixture, every comma header shape (implements A, B, C<X,Y>; extends + implements; interface extends A, B; enum; record; nested), the budget, and the map; each case runs in a child process with a hard timeout so a regression FAILS instead of hanging the suite.
- Lessons: (1) every pure parser that runs on the service's event loop needs a step budget, not just "returns null on input it does not understand"; (2) a hand-written loop that steps back (`r--`) must prove progress; (3) structure-round flags were documented "off in production" but were on: keep `/health features` as the truth.
- Open: other synchronous scanners on the event loop (precheck, preserve, ledger, autofix rewrites) have no step/time budget; a worker thread for workspace analysis would make this class impossible.

# Known bugs (real, found and fixed) — kept for future training with Cyrus

This file is a record of real production bugs found in Cyrus (or its Nxeon host platform) by live observation,
not synthetic test failures. Each entry exists so the same pattern is never repeated, and so the facts here can
later be distilled into Cyrus's own build-time knowledge (e.g. a precheck rule, a host-seam invariant, or an
eval case) once there's a mechanism for that. This is NOT the same thing as
`services/modbuilder/rules/failure-rules.json` (generated-Java-code compile failures) — see the note at the
bottom of each entry on what is and isn't the right home for it.

---

## 2026-10-15 — Delivered BetterModel config.yml left root-owned, silently disabling BetterModel and every dependent mod

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

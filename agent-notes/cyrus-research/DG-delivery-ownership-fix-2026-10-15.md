# DG — delivery ownership fix (2026-10-15)

Branch `fix/cyrus-delivery-ownership`, worktree `/tank/dev-worktrees/cyrus-delivery-chown` (based on `main` @
`b447360d`), committed locally as `7be0a81f`. NOT pushed, NOT merged, NOT deployed, no live writes to any real
server. The owner's server (kodi.playnxeon.com) was already fixed by hand (config.yml chowned + container
restarted) and was not touched again by this session.

## The fix

`lib/cyrus/delivery/orchestrator.ts` gained a shared helper, `ownGame(jfs, base, paths)`, mirroring
`lib/nxeon-platform/api.ts`'s `own()`: filters `paths` to those inside the game folder (`base`), and if any
remain, calls the journal's `chownLike(base, inGame)`, swallowed with `.catch(() => undefined)` — best-effort,
never able to fail a delivery. It is now called right after every guest-folder write the orchestrator performs:

- BetterModel's `config.yml` (the confirmed live bug)
- every creature `.bbmodel` model file
- the datapack zip (after its `.nxeon-part` rename)
- the Config Studio's rewritten settings file (`configBody`)

Cyrus' own delivery record (`recordPath`, under the guest's `.nxeon-cyrus` state dir, outside `base`) is never
passed to `ownGame()` — confirmed by test, it stays root's, as the existing code comment intends.

One more one-line fix landed in the same pass: `lib/cyrus/packhost/deliver.ts`'s `writeLoaderConfig()` already
called `chownLike` after writing the Pack Loader's `packs.json`, but did not swallow its failure — an unguarded
chown failure there would have thrown out of the whole delivery. Wrapped in the same `.catch(() => undefined)`.
This surfaced because the regression test's "a chownLike failure never fails the delivery" case initially failed
for the wrong reason (this older call site, not my new one) — see Test results below.

## Test results

- `devhost tsc` (full typecheck, `NODE_OPTIONS=--max-old-space-size=10240`): clean, no errors.
- `devhost test test/cyrus-delivery.test.ts`: **36/36 pass** (33 pre-existing + 3 new). New tests:
  1. `deliverMod`: an install with a plugin, a resource pack, a data pack and a creature proves every one of
     BetterModel's config.yml / the creature model / the datapack zip triggers `chownLike`, that at least one
     call uses the game folder itself as the reference, that every call's reference stays inside the game
     folder, and that the delivery record path is never among the chowned paths.
  2. A `chownLike` that always throws still lets the delivery finish `ok: true, outcome: "delivered"` (best-effort
     proven, not just asserted).
  3. `deliverConfig` (Config Studio apply) chowns the rewritten settings file but never the delivery record it
     also rewrites in the same call.
- `devhost test test/cyrus-managed.test.ts test/cyrus-creature.test.ts test/cyrus-delivery-enqueue.test.ts test/cyrus-config-integration.test.ts test/cyrus-config-delivery.test.ts`: **112/112 pass**, no regressions.
- `devhost test test/cyrus-delivery-db.test.ts test/cyrus-managed-db.test.ts test/cyrus-creature-db.test.ts`: all
  3 suites skip (gated behind `CYRUS_*_DB_TEST=1` + a node-2 throwaway `DATABASE_URL`, not exercised here; this
  matches how they already run in CI/other sessions, not a new gap).
- `devhost run -- npx tsx scripts/cyrus/docs-build.ts` then `devhost test test/cyrus-docs-coverage.test.ts`:
  regenerated reference docs produced no diff; the docs-coverage suite (links, flag coverage, staleness,
  secrets scan) passes 12/12 after the `07-operations.md` edit.

Test fixture additions: `test/_cyrus-delivery-fakehost.ts` gained `ChownSpyFs` (a `TxnFs` wrapper that records
every `chownLike` call and can be made to throw on demand) and a `chown` option on `FakeServer.host()`.

## What else shares this bug class (searched, not all fixed)

Searched every `.writeFile(`/`.mkdirp(`/`.rename(`/`.copy(`/`.chownLike(` call site under `lib/cyrus` and
`lib/mods` outside `orchestrator.ts` and `api.ts`. Risk, from most to least concerning:

1. **`lib/cyrus/creature/deliver.ts`'s `deliverCreatures()` — HIGH RISK, same bug, not fixed.** A separate,
   parallel write path for creature delivery (outside the R5 delivery journal) that writes the exact same managed
   `config.yml` (`CONFIG_PATH`) and model files (`MODELS_DIR`) via a plain `GuestFs`, with **no `chownLike` call
   anywhere in the file**. Grep confirms it: `lib/cyrus/creature/deliver.ts` is absent from the list of files that
   call `.chownLike(`. Wherever this function is actually invoked against a real guest (it's used in
   `test/cyrus-creature-db.test.ts` / `test/cyrus-creature-real.ts` and may be a live worker entry point outside
   the orchestrator — worth confirming which), it reproduces the exact confirmed bug on its own.
2. **`lib/cyrus/modpack/install.ts` + `lib/cyrus/modpack/engine-placer.ts` — MEDIUM-HIGH RISK, not fixed.** Mod
   Pack member placement (plugin jars, configs, data packs: `install.ts` lines 58, 70, 227, 230; `engine-placer.ts`
   line 45) writes through a plain `fs.writeFile`/`fs.mkdirp`/`fs.rename`, no chown call. These ARE called from
   inside the R5 orchestrator (`deliverModPack`/`uninstallModPack` -> `modpackBody` -> `run(t.jfs)`), so the `fs`
   they receive already has `chownLike` available on it (it's the same `JournalFs`) — it's just never called.
   Every Mod Pack install plausibly leaves its member files root-owned the same way.
3. **`lib/mods/engine.ts` line 399 — LOWER RISK, already calls chown, but unguarded.** The ordinary (non-Cyrus)
   Mods-tab installer already calls `fs.chownLike(layout.base, ...)` once after a successful install, which is
   correct in intent — but the call sits AFTER the function's own `try { ... } catch (e) { rollback; return
   {ok:false} }` block, not inside it, so a chown failure here would throw straight out of the function, past its
   own rollback, instead of being swallowed. Not the same bug (writes are already chowned), but the same
   underlying landmine (an un-swallowed `chownLike` can take down an otherwise-successful install) that this
   session fixed once already in `lib/cyrus/packhost/deliver.ts`.
4. **`lib/cyrus/host/platform-session.ts` (`PlatformTxnFs`) — SAFE, not a gap.** This is the HTTP host adapter a
   standalone Cyrus would use to call Nxeon's Platform API remotely. Its `writeFile`/`mkdirp`/`rename`/`copy` all
   proxy to `api.write`/`api.mkdir`/`api.rename`/`api.copy` over HTTP, which land in `lib/nxeon-platform/api.ts`'s
   own handlers — which already call `own()`. No action needed.
5. Everything else that touches `writeFile`/`mkdirp` under `lib/cyrus` (`library/backend/objects.ts`,
   `library/backend/derive.ts`, `packhost/local.ts`, `textures/png.ts`, etc.) writes to **local** disk (asset
   object storage, pack-host cache, render scratch dirs) via plain `node:fs`, never a guest `GuestFs`/`TxnFs` —
   not in scope for this bug class at all.

None of items 1–3 were fixed in this pass (the task scoped the fix to `orchestrator.ts`); they're flagged here so
they aren't lost. Item 1 looks like the single most important follow-up — it's the same exact file (BetterModel's
config.yml) the live incident hit, through a different code path.

## Knowledge base

- `/root/claudeskills/agent-notes/cyrus-research/KNOWN-BUGS.md` — created (did not exist before). Dated entry with
  title, severity, the full causal chain, the fix, files touched, how it was found, the still-open items above,
  and the one-line lesson the owner asked for.
- `services/modbuilder`'s own knowledge (`services/modbuilder/rules/failure-rules.json`): **deliberately not
  touched.** That file is a structured, machine-consumed list of generated-Java-code compile-failure rules (each
  entry has `id`/`versions`/`rule`/`pattern`/`scope`, enforced by `services/modbuilder/precheck.js` against a
  model's generated `.java` source). This bug is a platform delivery/infrastructure bug — a root-owned file on a
  real guest — with nothing for a precheck rule to see or affect; forcing a free-text entry into that schema would
  either break it or mislead whatever reads it next. The scoping decision and reasoning is written out explicitly
  in `KNOWN-BUGS.md`'s closing section instead of silently skipping it.
- `docs/cyrus/07-operations.md`: added an incident-table row and a new "Guest-folder write ownership" section
  stating the invariant plainly (every guest-folder write must restore ownership, best-effort, never blocking;
  Test Flight can't catch a gap here because it never exercises the real guest-write path) and naming both
  existing implementations (`api.ts`'s `own()`, `orchestrator.ts`'s `ownGame()`) that must keep matching it.
  `docs-build.ts` regeneration produced no diff; `cyrus-docs-coverage.test.ts` passes.

## Owner commands (portal-only promote: no schema change, no modbuilder image rebuild)

This fix is pure TypeScript inside the main Nxeon app (`lib/cyrus/...`), so it ships through the ordinary
portal deploy path, not `scripts/cyrus/deploy-modbuilder.sh` (that's only for the build-service container image,
untouched here) and with no `npm run db:push` (no schema changed).

```sh
cd /opt/nxeon
git fetch /tank/dev-worktrees/cyrus-delivery-chown fix/cyrus-delivery-ownership:fix/cyrus-delivery-ownership
git log -1 fix/cyrus-delivery-ownership   # review 7be0a81f
git checkout main && git merge --no-ff fix/cyrus-delivery-ownership   # or open a PR instead, if you'd rather review there
scripts/deploy-staging.sh fix/cyrus-delivery-ownership   # builds, restarts staging; verify a real creature-mod delivery to a staging VPS, confirm config.yml comes out non-root-owned
scripts/promote-production.sh                             # only after staging looks right
```

If you'd rather review as a PR first: `git push origin fix/cyrus-delivery-ownership` from the worktree, then open
the PR against `main` on GitHub (remote `origin` = `git@github.com:santino1233/nxeon.git`).

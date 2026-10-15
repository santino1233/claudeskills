# DT - rc19 assembly (2026-10-15)

Branch `release/cyrus-rc19`, worktree `/tank/dev-worktrees/cyrus-int6`, from main = release/cyrus-rc18 = 84d5be2f (live).
**Head: af6d1320.** Nothing pushed, deployed, promoted or applied; /opt/nxeon, DNS, nginx and production data untouched; no
email sent. Every commit made with `git -c core.hooksPath=/dev/null` (the post-commit hook pushes main).
Owner script: `ship-rc19.sh` (same directory; `bash -n` OK).

## 1. Merges (one `--no-ff` commit each, in order)
| # | Commit | Branch (head) | Conflicts / resolution |
|---|---|---|---|
| 1 | 5a77f2f1 | fix/cyrus-web-origin-marketing-session (be0c6c3c) | clean |
| 2 | 660d7e35 | fix/cyrus-guard-false-positives (647fd31f) | DOCUMENTATION.md, cyrus/11-history.md keep-both; reference/tests.md ours (regenerated later) |
| 3 | ff664625 | feature/cyrus-email-templates (f37afec2) | DOCUMENTATION.md, 11-history keep-both; reference/tests.md ours |
| 4 | b3b1c9c5 | feature/cyrus-admin-host (b979326d) | reference/routes.md, tests.md ours |
| 5 | fa8dc39e | fix/ticket-reply-image (9410db0e; base b447360d) | DOCUMENTATION.md keep-both (its docs bullet kept) |
| 6 | 9a734464 | feature/pz-server-password (642b21c8) | clean |
| 7 | 06509448 | fix/build-perf (11a2c461) | clean (node-2 host/slice scripts only) |
| 8 | 02a0fb59 | feature/cyrus-dungeon-run (1595997b, runner commit) | clean |
| 9 | 45b751fc | feature/cyrus-followups (ca04e957, 4 commits, already committed when reached; worktree clean) | DOCUMENTATION.md keep-both; reference/documentation-index, flags-and-env, tests ours |

Then 9d7c663e regenerated references and af6d1320 suite fixes.

No code conflicts. The only nginx overlap: admin-host adds `nginx-cyrus-admin*.conf`, the hotfix changes
`nginx-cyrus-my.conf`; the rc19 copy of `deploy/cyrus/nginx-cyrus-my.conf` is byte-identical to the hotfix branch.

## 2. Generated references
On node-2 (devhost): `gen-openapi.ts`, `mc-coverage.ts`, `docs-build.ts`, pulled back with `devhost pull`. Real local changes:
`docs/cyrus/reference/{documentation-index,flags-and-env,routes,tests}.md` (135 DOCUMENTATION sections, 111 pages incl.
/admin/login, 65 other env vars incl. modpage-shots.mjs). OpenAPI and minecraft-coverage were already current (no change).
After a fresh push all three `--check`: exit 0 (re-checked after the fixes too).

## 3. Fixes found by verification (root causes) - af6d1320
- **Reverse-import ratchet** (`test/cyrus-reverse-imports`): followups' `worker/game-control.ts` imported 4 Cyrus modules
  (cyrus/db, creature/deliver, creature/after-start, packhost/config) for the BetterModel hand-off. Moved the Cyrus-side glue
  (managed-plugin lookup, pack store selection, logging, never-throw) into `lib/cyrus/assets/deliver-worker.ts`
  `afterCyrusGameStart`, the worker's existing Cyrus entry point; game-control now passes only `openFs` (SshGuestFs). Baseline
  gains `worker/game-control.ts -> lib/cyrus/assets/deliver-worker` and (admin-host) `app/admin/login/page.tsx ->
  lib/cyrus/bridge/config` (same edge app/admin/layout.tsx has), both accepted deliberately. Behaviour unchanged.
- **`test/cyrus-beta-ops`** "the route is same-origin...": asserted the old `origin !== new URL(req.url).origin` text in
  `app/api/cyrus/report/route.ts`, which the web hotfix replaced by `cyrusSameOrigin(req)`. The hotfix branch itself had this
  red (its 18-suite list did not include beta-ops). Test now asserts the helper.

## 4. Verification (tree af6d1320, node-2 via devhost, NODE_OPTIONS=--max-old-space-size=10240, node-2 PSI avg10 0.00 each time)
- `scripts/devhost tsc`: **exit 0** (one TS narrowing error in my first version of the glue, fixed before commit).
- Suites: `test/modbuilder*.test.ts test/cyrus*.test.ts` + conversion-funnel, list-guard, email-rollout,
  email-templates-overhaul, server-deployed-email, critical-email-retry, filemanager-guards, filemanager-jail, upload-paths,
  ticket-reply-errors, cfg-projectzomboid, zomboid-admin, game-power-start: **4877 tests, 4876 pass, 0 fail, 1 skipped**
  (the nginx -t test; no nginx on node-2). First run before the fixes: 4867, 2 fail (the two above).
- `cyrus-liveassets-e2e` "cubes appear as they arrive": **passes now** (fixed by followups e4cfcb9f).
- `test/provision-first-boot.test.ts`: **fails on main 84d5be2f** (`server-only` "cannot be imported from a Client Component",
  1 test, file-level crash) and **passes 28/28 on rc19**. I did not pin down which merge changed the import chain (no
  `server-only` line changed in the diff); treat it as pre-existing on main, green on rc19.
- Not run: `test/cyrus-nxeon-integration-real.ts` (real Paper boots), a real-client check of the BetterModel pack.
- The node-2 devhost workspaces `cyrus-int6` and a temporary `cyrus-int6-main` (main check) were removed afterwards; the
  temporary main worktree was removed too.

## 5. Other branches (`for-each-ref feature/cyrus-* fix/*`, `merge-base --is-ancestor` vs rc19)
Not in rc19: feature/cyrus-v6-library, -v6-game-rust, -v6-game-palworld (paused, 2026-10-08), fix/terraria-listener (10-05,
1 commit), fix/vps-ram-allocation (09-28, 1), fix/game-config-envkey-audit (09-24, 7). All old; no new Cyrus work missed.

## 6. Deploy facts for the owner (ship-rc19.sh)
- **No new manual SQL** (nothing added under prisma/manual-migrations; no schema change). rc18's SQL already applied.
- **modbuilder image needed**: services/modbuilder route.js/server.js (guard-2026-10-15.1). Live `modbuilder:0.23`, highest
  tag on the build VM 0.23 -> script picks **0.24**. (Followups' BetterModel fix is portal+worker only, per DP.)
- Promote with BUILD_MAX_MIN=45; wait for node-2 memory pressure first (DQ).
- After promote: cyrus.my vhost from `deploy/cyrus/nginx-cyrus-my.conf` (diff, backup to /root/nginx-backups, nginx -t,
  reload, auto-restore), then `apps/cyrus-site/publish.sh publish --go` (live landing is still 20261014T111510Z-0d9c8d20).
- After deploy: restart server "kodi" once from the panel so the BetterModel pack is handed off (DP).

## 7. Open items / owner-only
Cloudflare mail DNS for cyrus.my + Mailcow domain (DM); wildcard *.cyrus.my cert + admin secret-host vhost/env (DK);
rotate CYRUS_GOOGLE_CLIENT_SECRET (DK); node-2 `MemoryMin=9G MemoryLow=10G` / `MemoryHigh=infinity` (DQ); flags
`cyrus_content_public_enabled` (games/host/blog pages) and `cyrus_mods_public_enabled` (mods list, mod pages, spotlight,
landing Mods/Blog links); mark the 3 guard refusals false_positive in Admin > Cyrus > Learning (DS); staging cleanup SQL
`screens-mod-pages/cleanup-staging.sql` (DP); /var/lib/nginx temp dirs owned by nobody -> chown www-data (DN, host fix);
decisions carried from rc18 (Free plan game slots, cyrus_cost_platform_daily_cap_usd, launch switches).

## 8. rc19 final (2026-10-15)
Merged feature/cyrus-refine-regression-guard (8779a067) --no-ff as 45ab0502 (no conflicts, 48 files; no hooks, nothing pushed).
**Head: 45ab0502.** Adds services/modbuilder/preserve.js (MB_PRESERVE refine regression guard; the modbuilder image now carries it
together with guard-2026-10-15.1) plus test/modbuilder-preserve*.test.ts, cyrus-preserve-portal.test.ts.
- Generated refs: docs-build, mc-coverage, gen-openapi all `--check` exit 0 (branch already carried regenerated refs; nothing to pull).
- `devhost tsc` (NODE_OPTIONS=--max-old-space-size=10240 via env): exit 0.
- Suites (same list as section 4): **4913 tests, 4912 pass, 0 fail, 1 skipped** (nginx -t). No new failure.
- ship-rc19.sh header + image step updated; `bash -n` OK. Same deploy facts as section 6 (modbuilder tag 0.24).

# BS: Cyrus rc10 quality round (2026-10-14)

Branch `release/cyrus-rc10` (worktree /tank/dev-worktrees/cyrus-rc10, from main f12841d2), head `1ba8aefe15`, 4 commits, NOT promoted.
Verification (devhost, node-2): `tsc` exit 0; full `test/*.test.ts` 7762 tests, 7616 pass, 50 fail. None of the 50 touch this
branch's code (billing/proration/purchase-consent/registrar guards, pre-existing on main), except one real Cyrus bug found and fixed
(storage add-on return redirect). All new tests pass (cyrus-nginx-vhost 5, cyrus-eval-run-lib 4, modbuilder-rc10-fixes 8).

## 1. Eval fourth1 (image 0.16, saka, 1.21.11) - PARTIAL, still running
Snapshot 2026-10-14 09:05 UTC: 41 of 90 builds done (plain 20, sound 10, texture 11; designer/cov lanes not reached yet), $12.84.
- pass@1 80.5% (33/41), final pass 100% (41/41), full pass 97.6% (40/41), real Paper boot 100% (41/41), repair share of spend 31.2% (8 repaired builds, 1.87x a clean build).
- By lane pass@1: plain 95%, sound 90%, texture 45.5% (final 100% everywhere). Cost per pass $0.31.
- The run is slow (asset builds 4-5 min, in-flight 1); at this pace it needs about 3 more hours. Numbers above are a snapshot, not a baseline: do NOT accept it yet.
Repaired builds (8): 4x perf-spawn-in-loop (ast-ruby-sword, ast-banshee-full, ast-handgun-textured, snd-shotgun-pump), 4x compile errors (s04-broadcast, ast-honey-bread, ast-banshee-full, ast-armor-set), 1 asset check (revolver sound layers), 1 texture check (shop panel fully solid).
Not fully shipped: snd-config-mapped (build ok, "nothing shipped for sounds": prompt only asks for swappable sound NAMES in config.yml, so the planner chose no sound lane; lane-judgement question, not fixed).

## 2. Root causes and fixes (services/modbuilder, all with unit tests in test/modbuilder-rc10-fixes.test.ts)
1. perf-spawn-in-loop (the biggest class: 4 of 8 repairs here, 11 hits over first1..fourth1, texture pass@1 45%). The deterministic leftover-drop guard (`autofix.fixPerf`, shipped rc5) never ran in the first round: `server.js` required `rec.perf.pkg`, but `rec.perf` is only set by `PERF.inject` inside `compile()`, after the autofix + pre-check block. So every first round fell through to a model repair; evidence: all these builds have `autofixes: null` and the flagged line is the plain braced `target.getWorld().dropItemNaturally(target.getLocation(), extra);` shape fixPerf handles. Fix: `perf.perfPackageOf(ws)` derives `<main package>.nxperf` from plugin.yml; server uses `rec.perf.pkg || perfPackageOf(ws)`. Expected: removes most texture-lane repairs (each about $0.05 + 10-15 s, and a retried build costs about 2x).
2. `Collection<Player|Entity> cannot be converted to List<..>` (third1 banshee, fourth1 banshee-full; `List<Player> x = loc.getNearbyPlayers(r)`): `autofix.fixCollectionToList` wraps single-line declarations in `new java.util.ArrayList<>(...)`.
3. `private boolean onCommand(...)` "attempting to assign weaker access privileges; was public" (fourth1 s04-broadcast): `autofix.fixWeakerAccess` sets the required modifier (never on static/field lines).
Not fixed, single occurrences with no evidenced class: unknown `ConsumableEffect` class (API lookup already guides), `Material.SMITHING_TEMPLATE`, sound `layers` list shape, a full-solid shop panel texture, sound-lane choice for config-mapped names.
Also fixed (found by the full suite): `app/api/cyrus/storage/return/route.ts` redirected against `req.url` (0.0.0.0:3000 behind nginx); now `requestOrigin(req)`. Storage add-ons are off today.

## 3. cyrus.my nginx fallback (prepared, NOT applied)
- `deploy/cyrus/nginx-cyrus-my.conf` (full vhost) and `.conf.patch` (exact diff against the live file, `patch --dry-run` applies cleanly). Removes `location / { try_files $uri $uri/ @cyrus_app; }`. Landing static only for `/`, `/assets/*`, `/status/`, `/release.json` (MANIFEST.sha256 and index.html are no longer served: they were 200 before). App regex now includes assets, servers, wallet, api/log, legal (+ auth/rate limit block and pack block unchanged). App-owned public files by explicit name (favicon, robots, sitemap, manifest, icons, /cyrus/ tree, /.well-known/). Everything else: own 404 with `X-Cyrus-Edge: denied`.
- Deviation to know: `/assets` the app page and `/assets/css/...` the landing files share a prefix; `location ^~ /assets/` serves files, the regex (which contains `assets`, as the launch check requires) catches only `/assets` itself.
- Verified on a throwaway nginx (fake upstream, high ports): `nginx -t` ok and matrix 40/40; the same matrix against the live vhost shows the gap (MANIFEST.sha256 / index.html 200, unknown paths reach the app).
- Owner apply: `cp /etc/nginx/sites-enabled/cyrus-my /root/cyrus-my.bak && cp /tank/dev-worktrees/cyrus-rc10/deploy/cyrus/nginx-cyrus-my.conf /etc/nginx/sites-enabled/cyrus-my && nginx -t && systemctl reload nginx && bash /tank/dev-worktrees/cyrus-rc10/scripts/cyrus/nginx-cyrus-my-check.sh --origin 127.0.0.1`
  Rollback: `cp /root/cyrus-my.bak /etc/nginx/sites-enabled/cyrus-my && nginx -t && systemctl reload nginx`. The check script also runs through the edge without `--origin`. (After promote, the same files are in /opt/nxeon.)

## 4. Launch check + docs
- `scripts/cyrus/lib/eval-run.mjs` reads `/root/cyrus-eval/*/journal.jsonl` (no gate.json needed): launch-check now prints `eval-run` (newest COMPLETED run: pass@1, final, boot, repair share, cost, failing prompts, age; FAIL below the final-pass floor) and `eval-run-live` (run in progress, INFO). Today: second1 PASS (pass@1 88.9, final 100, boot 100), fourth1 in progress.
- `docs/cyrus/07-operations.md` section "Eval baseline acceptance (rc10)": finish, read, re-score, accept in a reviewed branch, verify. Generated references regenerated.

## 5. Owner lines (nothing applied by me)
Portal promote (portal code: storage return fix, launch-check, docs; nginx files are not deployed by promote):
`cd /opt/nxeon && git merge --ff-only release/cyrus-rc10 && bash scripts/promote-production.sh --skip-staging-check`
Build-service image CHANGED (perf.js, autofix.js, server.js): TAG=modbuilder:0.17. The deploy needs an idle service, so wait for eval fourth1 to finish (or stop it on purpose and resume it later with `--tag fourth1`; the unfinished lanes then run on 0.17, which is also the better measurement of these fixes):
`cd /tank/dev-worktrees/cyrus-rc10 && TAG=modbuilder:0.17 bash scripts/cyrus/deploy-modbuilder.sh`
Then: nginx lines above, and when fourth1 is complete accept it per the new docs section (or run a short second eval on 0.17 to measure the perf-guard effect: expect texture-lane pass@1 well above 45%).

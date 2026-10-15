# CZ: complete Cyrus documentation set (2026-10-15)

Branch `feature/cyrus-docs-complete` (worktree `/tank/dev-worktrees/cyrus-docs-complete`, from main `89608a9f` = rc16). Docs, generator and test only. Nothing deployed, no flag, no migration. Rebased conflicts to expect: `docs/cyrus/README.md` and `06-portals.md` (rc17 adds the 18-seo row); take both.

## What was built
New hand-written pages (numbers 20+; 18-19 reserved for SEO on `release/cyrus-rc17`):
20 coverage matrix (+ mismatch register + status snapshot), 21 infrastructure (ASCII diagram), 22 life of a build (mermaid sequence, measured timings and costs), 23 build service, 24 techniques catalogue, 25 training and knowledge, 26 assets taxonomy, 27 games, 28 operations handbook (incl. the 2026-10-15 scraper outage), 29 decisions / placeholders / switches by name, 30 FAQ, 31 app and economy. README and 00-overview rewritten with a reading order by role; 14 gained "Doc owners".

Generated (zero model tokens, `scripts/cyrus/docs-build.ts`): `reference/infra-units.md`, `reference/build-service.md`, `reference/limits.md`, `reference/doc-owners.md`; the flags reference now includes the build-service switches (`CYRUS_REMOTE_FLAGS`) and every env/setting name has a meaning.

Machine-readable: `docs/cyrus/_data/doc-owners.json` (`{version:1, rules:[{paths, docs}]}`, 23 rules) for the release-train agent.

Guards (`test/cyrus-docs-coverage.test.ts`, new describe + 1 new test): empty flag meaning, dead rule or missing doc in doc-owners, unowned `lib/cyrus/<dir>` or `services/modbuilder/*.js`, service module not copied by the Dockerfile, missing complete-set pages. `scripts/cyrus/docs-links.ts [--paths]`: relative links + headings + cited repo paths in pages 20+.

## Coverage matrix, before and after (49 concerns, full table in docs/cyrus/20-coverage-matrix.md)
| Depth | Before | After |
|---|---|---|
| none | 4 | 0 |
| stub | 6 | 0 |
| adequate | 27 | 9 |
| complete | 12 | 40 |
Before-state "none": systemd units/timers, life of a build, taxonomy, FAQ-class material; "stub": sound relay, host capacity, models/routing/effort, vanilla technique catalogue, community state, SEO.
Still "adequate" after: studios (03), security (08), SEO (pointer only until rc17), community mod pages (empty in production), legal (drafts on a worktree), vanilla technique catalogue (research input), universal-modder KB (private), game readiness snapshots (dated 2026-10-08), disk/memory capacity (a dated report).

## Mismatches found against the code (all fixed unless noted)
1. 46 "not merged / NOT deployed" labels on branches that are in main (02, 04, 06, 09, 12, features.json). 11-history keeps its as-of-date wording plus a reading note.
2. Admin Flags text said MB_PREFLIGHT default `1` = enforce; code default is `advise` (rc15). Fixed in `lib/cyrus/admin/flags.ts` text only.
3. 02 said 50 rules `rules-2026-10-12.3`, "only 0.4 running", service history 0.3-0.6; repo has 55 rules `rules-2026-10-13.1`; tags 0.19-0.22 exist in notes. Running tag cannot be known from git (documented how to read it).
4. 07: root disk "11 GB free" (87% / 6.5 GB on 2026-10-15); tank "3.6 TB single disk" vs ZFS 2.6 TB: noted as unverified.
5. The flags generator ignored `CYRUS_REMOTE_FLAGS`, leaving 47 env/setting names without meaning; fixed (+ `flag-notes.json`).
6. `rollback-release.sh` and the release-symlink model had zero mentions; "blue/green" does not exist.
7. No backup docs for Dropbox, timers, stagger; 2026-10-15 incident not in the incident table.
8. features.json lacked 12 recent features (live progress, oracle, pre-flight/ledger, boss model, speed, capacity, Spyglass, publish-check, library prod, offsite backups, dispatch, launch check).
9. Two items numbered 18 in 12.
10. NOT fixed (reported): `feature/cyrus-legal`, `-google-login`, `-community`, `-library-taxonomy`, `-more-mobs` have tip == main with UNCOMMITTED work in their worktrees, so a naive "is merged" check wrongly says merged. No baseline.json / gate-accepted.json exists, so the eval gate is `no-reference`.

## Facts worth the owner's attention (verified here)
- Production env (names, 0/1 only): launch pair absent = OFF; `CYRUS_GOOGLE_CLIENT_ID/SECRET` are set but `CYRUS_GOOGLE_LOGIN` is absent and the login code is not on main (inert); library backend/browse/contribute ON and the catalogue is loaded (62,777 / 1,145,478 rows per CP).
- Build-service `MB_*` values live on the VM and were not readable: marked unverified in 29.
- rc17 (5 commits ahead of main) holds mega-staging + technical SEO and is not on main.
- Alerts have no webhook; nginx list guard, DB role and backup stagger from the hardening report are owner steps.

## Verification
- `NODE_PATH=/opt/nxeon/node_modules /opt/nxeon/node_modules/.bin/tsx scripts/cyrus/docs-build.ts` regenerated all references; `docs-links.ts --paths` ok (121 pages, cited paths verified).
- tsc and `test/cyrus-docs-coverage.test.ts` through `scripts/devhost`: see the final message of the task for results.
- Not verified: the live state of production beyond what is cited; numbers in 21 capacity come from the NX hardening report of the same day.

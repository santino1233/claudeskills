# CZ: complete Cyrus documentation set (2026-10-15)

Branch `feature/cyrus-docs-complete` (worktree `/tank/dev-worktrees/cyrus-docs-complete`), first from main `89608a9f` (rc16), then **main merged** (`b447360d` = rc17: legal pages, Google login, mega staging code, SEO). Docs, generator, tests and one text fix only. Nothing deployed, no flag, no migration. Page numbers: 18 SEO (main), 20 content and 21 analytics (on their branches), **this set is 22-33**.

## What was built
New hand-written pages (numbers 20+; 18-19 reserved for SEO on `release/cyrus-rc17`):
22 coverage matrix (+ mismatch register + status snapshot), 23 infrastructure (ASCII diagram), 24 life of a build (mermaid sequence, measured timings and costs), 25 build service, 26 techniques catalogue, 27 training and knowledge, 28 assets taxonomy, 29 games, 30 operations handbook (incl. the 2026-10-15 scraper outage), 31 decisions / placeholders / switches by name (incl. the Stripe decision and the split recommendation), 32 FAQ, 33 app and economy (incl. Google login, legal, content engine, analytics, target architecture). README and 00-overview rewritten with a reading order by role; 14 gained "Doc owners".

Generated (zero model tokens, `scripts/cyrus/docs-build.ts`): `reference/infra-units.md`, `reference/build-service.md`, `reference/limits.md`, `reference/doc-owners.md`; the flags reference now includes the build-service switches (`CYRUS_REMOTE_FLAGS`) and every env/setting name has a meaning.

Machine-readable: `docs/cyrus/_data/doc-owners.json` (`{version:1, rules:[{paths, docs}]}`, 27 rules) for the release-train agent.

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
10. Lesson recorded: branches `legal`, `google-login`, `community`, `library-taxonomy`, `more-mobs` had tip == main with uncommitted work, so "is an ancestor of main" is not proof of a merge (later committed; legal and google-login are in rc17). No baseline.json / gate-accepted.json exists, so the eval gate is `no-reference`.
11. The new guards immediately caught real drift after the main merge (7 flags without meaning, 40 unowned `lib/cyrus` paths, one dead glob), now fixed.

## Facts added after the coordinator's note (2026-10-15 evening)
- rc17 is main; image 0.22 live; live progress feed and idle supervision live; `CYRUS_GOOGLE_LOGIN` on (client id and secret set in env, names only); Cyrus Terms and Privacy pages live as drafts (lawyer review, 15 open questions, no acceptance versioning).
- Owner decision recorded in 31 and 33: **Cyrus keeps using the Nxeon Stripe account** (same company, separate products); supersedes DA's separate-merchant recommendation.
- DA split architecture summarised (JIT accounts with federated identities, Nxeon as OIDC provider, per-server grants, own repo / Postgres / VM / admin host, M0-M10, D1-D18); findings listed (seam ratchet, nginx admin template, DNS token, Google login creates Nxeon accounts, Cyrus sessions use the Nxeon AUTH_SECRET).
- Content engine (DC), analytics (DD), taxonomy (CV), community (CP), marketing roadmap (DB) documented from their reports and flagged as branch-only; their own pages 20/21 are not duplicated.

## Facts worth the owner's attention (verified here)
- Production env (names, 0/1 only; read before the Google switch, then confirmed by the coordinator): launch pair absent = OFF; `CYRUS_GOOGLE_LOGIN` ON; library backend/browse/contribute ON and the catalogue is loaded (62,777 / 1,145,478 rows per CP).
- Build-service `MB_*` values live on the VM and were not readable: marked unverified in 29.
- Alerts have no webhook; nginx list guard, DB role and backup stagger from the hardening report are owner steps.

## Verification
- `NODE_PATH=/opt/nxeon/node_modules /opt/nxeon/node_modules/.bin/tsx scripts/cyrus/docs-build.ts` regenerated all references; `docs-links.ts --paths` ok (121 pages, cited paths verified).
- `test/cyrus-docs-coverage.test.ts` via `scripts/devhost test`: 18/18 pass after the main merge. Full `tsc --noEmit` via devhost: see the final message (the full-program run needs a large heap and was run last).
- Not verified: the live state of production beyond what is cited; numbers in 21 capacity come from the NX hardening report of the same day.

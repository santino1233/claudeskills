# portal-directory progress (branch feature/portal-directory, worktree /tank/nxeon-wt-portaldir)
- node_modules in worktree is a REAL dir of per-entry symlinks to /opt/nxeon/node_modules, EXCEPT copied @prisma/client + .prisma (locally generated client with new models). Never run prisma generate against prod tree.
- Throwaway PG: /tank/pg-portaldir (port 54471, db portaldir), start: su postgres -s /bin/sh -c "/usr/lib/postgresql/17/bin/pg_ctl -D /tank/pg-portaldir/data -o '-p 54471 -k /tank/pg-portaldir -c listen_addresses=127.0.0.1' -l /tank/pg-portaldir/log start". Holds 38,079 prod ExternalServer rows (copied via SELECT).
- Research: research-raw.md (no permitted Minecraft bulk list).
- c1 e203b03597: schema + lib/directory-view.ts + hub uses it.
Next: portal data layer lib/directory-portal-data.ts, components/nx/directory/*, routes, actions (favourites, submissions), Part 2 (mc-status, submitted provider, prober enrichment), tests, docs, screenshots.
- c2 7e71682c77 portal + submissions + enrichment; c3 19ba910f00 tests/klei/docs; c4 d1dc5394a7 auth hazard fix.
- Screenshots: screens/ (13 views x 1440/390). Dev server + throwaway PG stopped and deleted 2026-10-06.
- Pre-existing failure: test/directory-phase1-db.test.ts sweep expects 88 calls, main makes 99 (commit 8830922).

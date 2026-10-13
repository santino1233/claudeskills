# AR - Cyrus documentation set (r46, 2026-10-11)
Branch `feature/cyrus-r46-docs` (worktree `/tank/dev-worktrees/cyrus-r46`), from r2, latest r2 merged. Nothing deployed.

## Structure (docs/cyrus/, index README.md)
Hand-written: 00 overview, 01 architecture, 02 engine (all engine features, verified vs not), 03 studios, 04 assets and library (legal ledger, licence rules, ingestion, owner SFX, game-derived policy), 05 bridge and accounts, 06 portals, 07 operations (infra map, runbook summary, incident playbooks), 08 security, 09 testing (flights index, verified/not), 10 decisions (ADR log), 11 history (timeline r0..r47, reports and design index), 12 gaps and roadmap, 13 glossary, 14 how to work here (rules, resume, docs update checklist, CLAUDE.md snippet).

## Generated (scripts/cyrus/docs-build.ts, zero model tokens, `--check` mode)
`docs/cyrus/reference/`: flags-and-env (about 320 CYRUS_*/MB_*/cyrus_* names with default and meaning from the admin Flags tab, settings catalog and `_data/flag-notes.json`), routes (API + pages), db-tables (Prisma + manual SQL + ownership), versions, adapters (+ capability matrix, game packs), openapi (operations + webhooks/events), feature-map (curated `_data/features.json`), modules, scripts, tests, documentation-index (Cyrus headings of DOCUMENTATION.md).

## Keeping it current
- Rule and 8-step checklist in 14; `test/cyrus-docs-coverage.test.ts` fails when a flag, env var, setting, route, table, adapter, game, version or OpenAPI operation exists in code but not in the reference, when generated pages are stale (tests.md: file list only), when features.json or a relative link/heading is broken, when a page is missing from the README, or when a secret-looking string or IP appears.
- Staff viewer: `/admin/docs/cyrus` (platform area), linked from `/admin/docs`.
- Proposed CLAUDE.md snippet: `docs/cyrus/_data/CLAUDE-SNIPPET.md` (not applied to CLAUDE.md).
- Regenerate: `NODE_PATH=/opt/nxeon/node_modules /opt/nxeon/node_modules/.bin/tsx scripts/cyrus/docs-build.ts` (light, runs on the primary) or `devhost run -- npx tsx ...` then `devhost pull`.

## Ran / not run
Coverage test 12/12; Cyrus suite (cyrus-*, modbuilder-*, platform-* files) 2552/2552 and `tsc --noEmit` clean on node-2 after the final r2 merge (r2 head 4b9412e21d). Pending items (r41, r42, r44, r45, r47) are marked pending; re-run the generator and update 11/12 after they merge. No secrets, no description of the owner's game archives.

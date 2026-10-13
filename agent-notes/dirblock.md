# dirblock (2026-10-03) branch feature/directory-block-other-hosts, worktree /tank/nxeon-wt-dirblock
Blocks external directory servers whose connect address shows another game host. See docs/DOCUMENTATION.md "Other-host blocklist".
- Matcher lib/directory-blocklist.ts (pure) + data lib/directory-blocklist-data.ts + db helpers lib/directory-blocklist-db.ts + PTR lib/directory-ingest/ptr.ts.
- NO ASN / IP-range blocking: repo has no ASN database. IP-only rows are judged by reverse DNS at ingest only.
- Additive schema: ExternalServer.blockedReason, blockedRule, ptrName, ptrCheckedAt (all nullable). Needs db push before deploy.
- Edited a shared file minimally: lib/settings.ts (2 keys), lib/actions-listing.ts (3 admin actions appended), lib/server-directory-data.ts (externalEntries filter).
- Tests: DATABASE_URL=postgresql://x:x@localhost:5432/x npx tsx --test test/directory-blocklist.test.ts test/server-directory.test.ts

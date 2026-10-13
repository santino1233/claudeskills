# status-notices (2026-10-05)
Branch feature/status-notices, worktree /tank/nxeon-wt-notices. Commits: 0ddb2a0cd8 (feature), docs/hide-top commit, final polish commit (git log).
Docs: docs/DOCUMENTATION.md "Status notices". Screenshots: /root/agent-notes/status-notices/ (1440 + 390).
Schema (additive): Announcement + templateKey(unique) placement dismissible region customText switchedBy switchedAt -> needs prisma db push.
Verified: tsc 0 errors; test/status-notices.test.ts 28 tests; full suite 46 failures identical by name to suite-failures-v3.txt; Playwright on throwaway PG (removed).
Pre-existing, not mine: /dashboard/deploy hydration mismatch in the Configure step; admin settings tabs were off by one (onboarding tab missing) - fixed in app/admin/settings/page.tsx.
Not covered: /nxm/status (generated), signup/login pages.

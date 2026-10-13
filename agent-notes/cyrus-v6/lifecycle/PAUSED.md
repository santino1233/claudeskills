# Cyrus v6 lifecycle: state at wrap-up (2026-10-08)

Branch `feature/cyrus-v6-lifecycle`, commit 89a9ea547e (worktree /tank/dev-worktrees/cyrus-v6-lifecycle).

Done + verified on node-2:
- `test/cyrus-lifecycle.test.ts` 35/35 pass (pure).
- `test/cyrus-lifecycle-db.test.ts` 9/9 pass (throwaway DB wt_cyrus_v6_lifecycle + sandbox guest dir; log: dbtest-e2e.log).
- `tsc --noEmit` passed on an EARLIER snapshot (before: toAlertViews move, cyrus_install_published_enabled gate, admin card, CreatorAlerts, DB test). Not re-run (owner usage limit).

Not done (wrapped up early at the coordinator's request):
1. Re-run tsc: `cd /tank/dev-worktrees/cyrus-v6-lifecycle && /opt/nxeon/scripts/devhost run --lock -- npx tsc --noEmit`
2. Real-route screenshots (dark/light, 1440/390). Harness ready in ./harness:
   copy into the worktree as `lcharness/` (untracked; never commit), then
   `devhost db push`; `devhost run -- npx tsx lcharness/seed.ts`; `devhost run -- npx tsx lcharness/watch.ts`;
   `devhost status` (one dev server fleet-wide) → `devhost dev` → `devhost run -- env BASE=http://127.0.0.1:<port> node lcharness/shots.mjs`
   → `devhost pull lcharness/shots` → `devhost stop`.
   (The DB test writes a node_modules/server-only shim in the node-2 copy, like test/chat-agent-tools.test.ts.)

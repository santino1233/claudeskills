# cyrus-admin: paused before the screenshot pass (2026-10-08)

Paused on the coordinator's instruction (owner near the weekly usage limit). The code is committed on
`feature/cyrus-v6-admin` (worktree `/tank/dev-worktrees/cyrus-v6-admin`). See the final report for
which checks ran.

## Not done yet
0. **The unit tests have not passed yet.** `devhost run --lock -- npx tsx --test test/cyrus-admin.test.ts ...` failed for ALL three files at import, including the existing cyrus-tokens-economy and cyrus-mods tests: `server-only` throws when it is required through `lib/geo-ip.ts`, because the run lacked the react-server condition. Retry with `devhost run --lock -- npx tsx --conditions=react-server --test test/cyrus-admin.test.ts`. If that still fails, find how the other agents run tests that import lib/rbac / lib/db. `tsc --noEmit` is clean (same run).
1. The real-route verification on node-2: seeded throwaway DB, mock /health, screenshots of every tab
   (dark + light, 1440 + 390), and the role-gating checks.
2. Nothing has been tested in a browser yet. The UI actions (refund, cancel, game status, setting,
   suspend) have only been typechecked.

## Resume steps (all from inside the worktree, node-2 only)
The verification files are in `.cyrus-admin-verify/` (untracked; NEVER `git add` it):
`seed.ts` (FAKE data, refuses non-throwaway DBs), `mock-svc.mjs` (0.5-shaped /health on 7398, labelled
"0.5-mock"), `shots.mjs` (UI actions, then 9 pages x 4 variants, then SUPPORT role gating).

```
D=/opt/nxeon/scripts/devhost
$D db push
$D env set MODBUILDER_URL=http://127.0.0.1:7398 MODBUILDER_API_KEY=local-mock-key
$D run -- npx tsx .cyrus-admin-verify/seed.ts          # writes .next.cyrus-admin-session.json on node-2
$D status                                               # wait until NO other *-dev.service runs fleet-wide
$D bg mock --port 7398 -- node .cyrus-admin-verify/mock-svc.mjs
$D dev                                                  # note the port
$D run -- env BASE=http://127.0.0.1:<port> OUT=.next.shots node .cyrus-admin-verify/shots.mjs
$D pull .next.shots /root/agent-notes/cyrus-v6/admin/shots
$D stop all                                             # immediately
```
Then check `shots/log.txt` for PAGEERROR / OVERFLOW lines. Expected results: the refund, cancel, game
and setting flashes are ok; the crafted Palworld "live" is refused; SUPPORT lands on
/admin/cyrus/community, gets bounced from /builds to /admin, and sees only the Community tab.

Merge note: before the merge, refresh `docs/cyrus/readiness/*.md` from
`/root/agent-notes/cyrus-v6/game-*/READINESS.md` (they are snapshots).

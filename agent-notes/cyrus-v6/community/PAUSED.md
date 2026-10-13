# PAUSED: Cyrus v6 community — code done + committed, real-route verification NOT run

Paused 2026-10-08 on the coordinator's request (owner near usage limit).

Done: branch `feature/cyrus-v6-community`, commit 93d9da2d18. `npx tsc --noEmit` clean on node-2.
`test/cyrus-community.test.ts` passes. `test/cyrus-mods.test.ts` fails to IMPORT (lib/auth -> lib/geo-ip ->
`server-only`), which is pre-existing on the base branch and unrelated (nothing in that import chain changed).
Schema pushed to node-2 throwaway DB `wt_cyrus_v6_community` (10 new tables, clean).

NOT done: seed + dev server + Playwright screenshots (the seed run hit the 10-min command limit on a loaded
node-2 before printing anything; nothing was verified in a browser yet).

## Resume (from /tank/dev-worktrees/cyrus-v6-community)
1. `cp /root/agent-notes/cyrus-v6/community/harness/* harness-community/` (untracked, never commit it)
2. Env is already set (devhost env list): MODBUILDER_URL=http://127.0.0.1:7417, MODBUILDER_API_KEY=local-mock-key,
   NXEON_MODBUILD_DIR=/tank/nxeon-build/agent-tmp-cyrus-v6-community-mbstore, NXEON_SANDBOX=1.
3. `scripts/devhost bg mock --port 7417 -- env MOCK_PORT=7417 node harness-community/mock-svc.mjs`
4. `scripts/devhost run -- npx tsx harness-community/seed-community.ts` (run in background; may take a while)
5. `scripts/devhost status` — only start when NO other *-dev.service runs: `scripts/devhost dev`
6. `scripts/devhost run -- env BASE=http://127.0.0.1:<port> OUT=.community-shots node harness-community/shots.mjs`
   then `scripts/devhost pull .community-shots /root/agent-notes/cyrus-v6/community/shots`
7. `scripts/devhost stop all`. Check log.txt for PAGEERROR / OVERFLOW / non-200.

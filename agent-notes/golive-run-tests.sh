#!/bin/bash
cd /tank/dev-worktrees/golive
D=/opt/nxeon/scripts/devhost
LIST=$(ls test/cyrus*.test.ts test/dedicated*.test.ts test/game-*.test.ts test/light-theme.test.ts test/brand*.test.ts test/kb*.test.ts 2>/dev/null | grep -v -- "-db.test" | grep -v -E "cyrus-page-gate|dedicated-gate|cyrus-admin|cyrus-mods.test")
$D run --lock -- env NODE_OPTIONS=--conditions=react-server npx tsx --test $LIST > /root/agent-notes/golive-t-a.log 2>&1
$D run --lock -- npx tsx --test test/cyrus-page-gate.test.ts test/dedicated-gate.test.ts > /root/agent-notes/golive-t-b.log 2>&1
$D run --lock -- bash -c 'env BM_OPS_DB_TEST=1 NXEON_DEDICATED_OVH_MOCK=1 CYRUS_LIFECYCLE_DB_TEST=1 npx tsx --test test/dedicated-ops-db.test.ts test/cyrus-lifecycle-db.test.ts' > /root/agent-notes/golive-t-c.log 2>&1
echo ALLDONE >> /root/agent-notes/golive-t-c.log

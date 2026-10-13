#!/bin/bash
cd /tank/dev-worktrees/golive
D=/opt/nxeon/scripts/devhost
{ $D dev --port 4470
  sleep 30
  $D run -- bash -c 'npx tsx .verify/seed.ts && BASE=http://127.0.0.1:4470 node .verify/pages.mjs'
  $D stop all
} > /root/agent-notes/golive-pages.log 2>&1
echo PAGESDONE >> /root/agent-notes/golive-pages.log

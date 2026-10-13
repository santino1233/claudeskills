#!/bin/bash
cd /tank/dev-worktrees/golive
D=/opt/nxeon/scripts/devhost
{
  $D env set MODBUILDER_URL=http://127.0.0.1:7417
  $D env set MODBUILDER_API_KEY=local-mock-key
  $D bg mock -- env MOCK_PORT=7417 node .cyrus-verify/mock-svc.mjs
  sleep 3
  $D run -- bash -c 'npx tsx .cyrus-verify/economy.ts'
  $D stop all
} > /root/agent-notes/golive-economy.log 2>&1
echo ECODONE >> /root/agent-notes/golive-economy.log

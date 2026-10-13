#!/bin/bash
cd /tank/dev-worktrees/golive
D=/opt/nxeon/scripts/devhost
{
  $D env set MODBUILDER_URL=http://127.0.0.1:7417
  $D env set MODBUILDER_API_KEY=local-mock-key
  $D env list | sed 's/=.*/=<set>/' | grep -c MODBUILDER
  $D bg mock -- env MOCK_PORT=7417 node .cyrus-verify/mock-svc.mjs
  $D dev --port 4263
  sleep 40
  $D run -- bash -c 'npx tsx .cyrus-verify/seed.ts && BASE=http://127.0.0.1:4263 node .cyrus-verify/forge.mjs'
  $D pull .cyrus-verify/forge-out /root/agent-notes/golive-forge-out
  $D stop all
} > /root/agent-notes/golive-forge.log 2>&1
echo FORGEDONE >> /root/agent-notes/golive-forge.log

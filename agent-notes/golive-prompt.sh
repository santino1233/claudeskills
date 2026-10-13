#!/bin/bash
cd /tank/dev-worktrees/golive
D=/opt/nxeon/scripts/devhost
{
  $D env set MODBUILDER_URL=http://127.0.0.1:7417
  $D env set MODBUILDER_API_KEY=local-mock-key
  $D bg mock -- env MOCK_PORT=7417 node .cyrus-verify/mock-svc.mjs
  $D dev --port 4265
  sleep 40
  $D run -- bash -c 'npx tsx .cyrus-verify/seed.ts && BASE=http://127.0.0.1:4265 node .cyrus-verify/shots-prompt.mjs'
  $D pull .cyrus-verify/prompt-out /root/agent-notes/golive-prompt-shots
  $D stop all
} > /root/agent-notes/golive-prompt.log 2>&1
echo DONE >> /root/agent-notes/golive-prompt.log

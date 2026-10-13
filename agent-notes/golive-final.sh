#!/bin/bash
cd /tank/dev-worktrees/golive
D=/opt/nxeon/scripts/devhost
{
  $D run --lock -- node scripts/gen-light-literals.mjs
  $D pull app/light-literals.generated.css
  rm -f light-literals.generated.css
  echo "=== TESTS A"
  $D run --lock -- env NODE_OPTIONS=--conditions=react-server npx tsx --test test/cyrus.test.ts test/cyrus-route.test.ts test/cyrus-prompt-check.test.ts test/cyrus-studio-gate.test.ts test/light-theme.test.ts test/cyrus-tokens-economy.test.ts 2>&1 | grep -E "^# (tests|pass|fail)|^not ok"
  echo "=== TESTS B"
  $D run --lock -- npx tsx --test test/cyrus-page-gate.test.ts test/dedicated-gate.test.ts 2>&1 | grep -E "^# (tests|pass|fail)|^not ok"
  echo "=== BROWSER"
  $D env set MODBUILDER_URL=http://127.0.0.1:7417
  $D env set MODBUILDER_API_KEY=local-mock-key
  $D bg mock -- env MOCK_PORT=7417 node .cyrus-verify/mock-svc.mjs
  $D dev --port 4263
  sleep 40
  $D run -- bash -c 'npx tsx .cyrus-verify/seed.ts && BASE=http://127.0.0.1:4263 node .cyrus-verify/forge.mjs'
  $D pull .cyrus-verify/forge-out /root/agent-notes/golive-forge-out2
  $D stop all
} > /root/agent-notes/golive-final.log 2>&1
echo FINALDONE >> /root/agent-notes/golive-final.log

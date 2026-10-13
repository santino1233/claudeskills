#!/bin/bash
cd /tank/nxeon-wt-cfg-integ
export DATABASE_URL=postgresql://x:x@localhost:5432/x
H=/tmp/claude-0/-root/4f329df3-66ee-49c8-a6c5-615ecf189efc/scratchpad/heavy.sh
echo "== tsc"; $H npx tsc --noEmit 2>&1 | tail -30
echo "== tests"
T=$(ls test/*.test.ts | grep -E 'cfg-|config|applier|dayz|terraria|ini-|env-|game-variant|game-setup|-cfg|-config')
$H npx tsx --test $T 2>&1 | grep -E '^# (tests|pass|fail)|^not ok|^\s+not ok' | head -40

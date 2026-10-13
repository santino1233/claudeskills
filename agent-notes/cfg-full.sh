#!/bin/bash
export DATABASE_URL=postgresql://x:x@localhost:5432/x
H=/tmp/claude-0/-root/4f329df3-66ee-49c8-a6c5-615ecf189efc/scratchpad/heavy.sh
for w in base integ; do
  d=/tank/nxeon-wt-cfg-$w; [ $w = integ ] && d=/tank/nxeon-wt-cfg-integ
  cd $d && $H npx tsx --test --test-reporter=tap test/*.test.ts > /tmp/claude-0/-root/4f329df3-66ee-49c8-a6c5-615ecf189efc/scratchpad/full-$w.tap 2>&1
  echo done $w >> /tmp/claude-0/-root/4f329df3-66ee-49c8-a6c5-615ecf189efc/scratchpad/full.done
done

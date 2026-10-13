#!/bin/bash
cd /tank/nxeon-wt-cfg-integ
export DATABASE_URL=postgresql://x:x@localhost:5432/x
/tmp/claude-0/-root/4f329df3-66ee-49c8-a6c5-615ecf189efc/scratchpad/heavy.sh npx next build > /tmp/claude-0/-root/4f329df3-66ee-49c8-a6c5-615ecf189efc/scratchpad/build.log 2>&1
echo "exit $?" >> /tmp/claude-0/-root/4f329df3-66ee-49c8-a6c5-615ecf189efc/scratchpad/build.log

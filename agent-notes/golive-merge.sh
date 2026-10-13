#!/bin/bash
# usage: golive-merge.sh branch...   (run inside the golive worktree). Auto-unions only UNION_OK files; stops on any other conflict.
UNION_OK="docs/DOCUMENTATION.md"
for b in "$@"; do
  echo "=== $b"
  git merge --no-ff --no-edit -m "Merge $b into integ/golive" "$b" 2>&1 | tail -3
  conf=$(git diff --name-only --diff-filter=U)
  if [ -n "$conf" ]; then
    other=""
    for f in $conf; do case " $UNION_OK $EXTRA_UNION " in *" $f "*) python3 /root/agent-notes/union-resolve.py "$f" && git add "$f";; *) other="$other $f";; esac; done
    if [ -n "$other" ]; then echo "STOP: unresolved conflicts in:$other (at $b)"; exit 2; fi
    git commit --no-edit -q && echo "committed merge $b (docs unioned)"
  fi
done

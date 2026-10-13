#!/bin/bash
# union-resolve conflicted files that are docs only; fail if any non-doc conflict
S=$(mktemp -d)
for f in $(git diff --name-only --diff-filter=U); do
  case "$f" in docs/*|*.md) git show :1:"$f" > $S/b 2>/dev/null || : > $S/b
     git show :2:"$f" > $S/o; git show :3:"$f" > $S/t
     git merge-file --union -p $S/o $S/b $S/t > "$f"; git add "$f";;
    *) echo "REAL CONFLICT $f"; exit 1;;
  esac
done

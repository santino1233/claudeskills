---
name: nxeon-worktree-nodemodules-hazard
description: "NEVER git add -A in a worktree that has a node_modules symlink — it can destroy prod's real node_modules"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-21T17:19:08.560Z
---

On 2026-08-21 I nearly took prod down. In a worktree I created `node_modules` as a symlink to `/opt/nxeon/node_modules` (the standard setup), then ran `git add -A` which COMMITTED the symlink (`.gitignore` has `node_modules/` with a trailing slash, which does NOT match a symlink named `node_modules`). Fast-forwarding that commit into the prod tree `/opt/nxeon` replaced its **real** `node_modules` directory with a **self-referential symlink** (`/opt/nxeon/node_modules -> /opt/nxeon/node_modules`), deleting 1.1G of packages. `next` and the Prisma client became unresolvable; only the in-memory running services survived.

**Why:** never stage the whole tree in a symlinked worktree.
**How to apply:**
- In worktrees, `git add` ONLY the specific files you changed — never `git add -A` / `git add .`.
- Recovery if it happens: `git rm --cached node_modules && rm -f node_modules` in the prod tree, then `npm ci` (lockfile present) + `npx prisma generate`, then commit the untracking. Do this BEFORE any restart/promote — running services hold modules in memory but a build/restart will fail hard.
- Consider hardening `.gitignore` with a bare `node_modules` line (no slash) so the symlink is ignored too.

Relates to [[nxeon-build-isolation]] and the deploy flow in [[nxeon-resume-point]].

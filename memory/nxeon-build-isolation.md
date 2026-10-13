---
name: nxeon-build-isolation
description: "NEVER run npm run build (or agent builds) in the live prod tree /opt/nxeon — it clobbers prod's .next and breaks the site"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-11T05:24:18.217Z
---

**NEVER run `npm run build` in the live prod working tree `/opt/nxeon`.** nxeon-web serves `/opt/nxeon/.next` and nxeon-worker runs `tsx worker/index.ts` off the same tree. A build there overwrites `.next` (new chunk hashes) while the OLD server process keeps running → browser requests chunks by hashes that no longer exist → `ChunkLoadError` / "Something went wrong" on every page (esp. /admin). Also `git checkout <branch>` in the prod tree switches the worker's live code.

**Why:** 2026-08-10 overnight run — I spawned build agents as normal general-purpose agents that `git checkout -b` + `npm run build` INSIDE /opt/nxeon. Each build clobbered prod's compiled assets; prod admin threw ChunkLoadError for hours. Fix was: stop the agent, `git checkout <last-promoted-commit>`, `npm run build`, `chown -R nxeon:nxeon .next`, `systemctl restart nxeon-web nxeon-worker`, then hard-refresh the browser.

**How to apply:** build/verify agents MUST work in an ISOLATED git worktree (Agent `isolation: "worktree"`, or manual `git worktree add`) or in `/opt/nxeon-staging` — NEVER the prod tree. The prod tree `/opt/nxeon` should stay parked at the currently-deployed commit; only `scripts/promote-production.sh` (build+restart) moves prod, and only on explicit user authorization. Staging builds go through `scripts/deploy-staging.sh` which operates on `/opt/nxeon-staging`. See [[nxeon-ventures-hub]], [[nxeon-platform]].

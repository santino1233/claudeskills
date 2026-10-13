---
name: nxeon-disk-full-outage-2026-09-27
description: Primary node root disk hit 100% from build caches, Postgres crashed, prod 500 for ~10 min; what to clear and what never to touch
metadata:
  type: project
---

**2026-09-27, 08:21–08:31 UTC:** the primary node's root filesystem filled up and production went down.
- **Symptom:** `/dev/md3` (49G, `/`) reached 100%. `postgresql@17-main`, which holds prod `nxeon` plus the staging DBs, crashed with "No space left on device", and prod on :3000 returned 500.
- **Cause:** cumulative regenerable caches, not the databases (all DBs together are about 500 MB).
  - staging `.next/cache` (2.1G)
  - `~/.npm/_cacache` (1.7G), `~/.cache/go-build` (1.3G)
  - worktree `.next` build outputs (2.2G in `ssh-management-key`)
  - The trigger was the /nxm `next dev` cache growing during multi-agent work.
- **Fix:** delete those caches, then `systemctl start postgresql@17-main` (it crash-recovers cleanly). That took free space from 134M to 8.5G.

**How to apply:**
- Before long builds or multi-agent `next dev` sessions on this box, check `df -h /`.
- Safe to clear: `~/.npm/_cacache`, `~/.cache/go-build`, `<tree>/.next/cache`, and `.next` of merged worktrees that no process uses (check with `lsof +D`).
- Never touch: `/var/lib/vz`, `/tank`, DB files, `/opt/nxeon/.next`, or the standalone output in `/opt/nxeon-staging/.next`.
- A follow-up task was offered to add disk alerting.

Related: [[nxeon-build-isolation]], [[nxeon-node1-cpu-and-devapp-relocation]].

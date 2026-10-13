---
name: nxeon-improve-agent
description: Recurring scheduled task that autonomously improves the Nxeon platform every 4 hours
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-07-23T10:26:46.833Z
---

A scheduled task `nxeon-improve` (created 2026-07-23, cron `40 */4 * * *`, stored in the user's desktop app scheduled-tasks) runs an autonomous improvement cycle on [[nxeon-platform]]: it reads `/opt/nxeon/CLAUDE.md` + `/opt/nxeon/ROADMAP.md`, completes the top unchecked roadmap item, builds, tests, commits, and checks it off.

**Why:** The user explicitly asked for "an agent to work day and night on improvements and additions."

**How to apply:** Coordinate with it — before making large changes to /opt/nxeon, check `git log` for its recent commits and update ROADMAP.md rather than duplicating work. Note: it only runs while the user's desktop app is open; a queued run fires on next launch. Installing the Claude Code CLI on the server for a fully server-side loop was blocked by the permission classifier and needs the user's explicit approval/login.

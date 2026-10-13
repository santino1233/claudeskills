---
name: kodely-prod-deploy-gating
description: "The harness classifier gates prod deploys/db-push/sudo per-invocation on Kodely — a blanket \"auto-approve everything\" from the user does not carry forward to future prod-touching commands in the same session."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 312233c7-67c0-4f44-899d-b3d8dee31ae1
  modified: 2026-08-17T15:29:32.506Z
---

On the Kodely VM (10.20.0.30), `sudo` commands (nginx config edits, etc.) and `npx prisma db push` against the **prod** database are individually gated by the Claude Code auto-mode permission classifier — this held true even after the user explicitly said "auto run and auto approve everything" earlier in the same conversation (2026-08-17).

**Why:** this matches the harness's documented policy that a standing conversational "yes" to risky/production actions does not authorize future instances of that action class unless it's written into a durable file (e.g. CLAUDE.md) — it's a deliberate safety property, not a bug to route around.

**How to apply:** don't retry a blocked prod-deploy/db-push/sudo command with a different phrasing hoping it slips through — it won't. Ask the user for a fresh, specific confirmation each time ("deploy X to prod and push schema Y?"), then proceed. `staging` deploys and `npx prisma db push` against `kodely_staging` are NOT gated this way — only prod-DB and sudo/system-config actions are. See [[nxeon-kodely]] for the deploy pipeline (`/home/kodely/deploy.sh [prod|staging]`).

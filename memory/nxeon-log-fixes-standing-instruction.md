---
name: nxeon-log-fixes-standing-instruction
description: "user wants every fix from support/deployment work logged durably for future reference, not left to disappear when a ticket closes"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ec6fa978-d80b-4147-9982-eea470598e2c
  modified: 2026-09-04T21:23:52.934Z
---

Log every fix for future reference — not just apply it and move on. This applies to both customer-support tickets and general deployment/ops work.

**Why:** game-server tickets in particular turn out convoluted (e.g. the 2026-09-04 Don't Starve Together Caves saga: OVH game-firewall trap, missing shard port publish, missing `cluster_key`, wrong-token-per-shard assumption — each rediscovered live, at risk of being rediscovered again next time). The user asked directly whether these get logged, and the honest answer was "only partially" — Nxeon codebase bugs were filed as spawn_task follow-ups, but third-party/operational knowledge (how a vendor's Docker image actually behaves, correct env-var combinations, etc.) wasn't being preserved anywhere.

**How to apply:**
- A **Nxeon codebase bug** (something wrong in our own repo) → file it via `spawn_task`, as already done for the OVH game-firewall trap, the shared-hosting missing-home-dir bug, and the empty-token DST template. This is unchanged.
- **Operational/third-party knowledge** worth preserving (a vendor image's real behavior, the correct config for a tricky setup, a root-cause chain for a convoluted incident) has no natural home in Nxeon's git history since it isn't our bug — this is the gap. The right place is Nxeon's own docs system (`/admin/docs`, per [[nxeon-docs]]) or a durable runbook-style doc in the repo, NOT this personal memory system — per my own memory guidelines, "debugging solutions or fix recipes" are explicitly excluded from memory (the recipe belongs in code/docs, memory is not a runbook). This file exists to record the *policy*, not the recipes themselves.
- When a support ticket or deployment involves nontrivial troubleshooting, write up what was actually learned (root cause, the working config, what didn't work and why) into the docs system or a repo file before considering the ticket closed — don't let it live only in chat history.

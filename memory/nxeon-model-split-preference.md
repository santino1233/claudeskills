---
name: nxeon-model-split-preference
description: Owner wants analysis/audit/inventory work run on Sonnet 5 and design work on Opus 5.5 — wait for them before designing
metadata:
  node_type: memory
  type: feedback
  originSessionId: ec6fa978-d80b-4147-9982-eea470598e2c
  modified: 2026-09-27T01:50:26.010Z
---

Run analyzing, auditing and inventory work on Sonnet 5 (e.g. Agent tool with model "sonnet"); do design work on Opus 5.5, and don't start design until the owner says so.

**Why:** owner's explicit instruction when starting the marketing redesign (2026-09-27) — they want to control which model does design.

**How to apply:** for audits/inventories, fan out Sonnet subagents even when the main session is on Opus; when work reaches a design decision, stop and wait for the owner rather than designing on the audit pass.

Related: [[nxeon-marketing-redesign-2026-09]]


**Update 2026-10-08:** owner said "sonnet for everything going forward until i say otherwise" (see [[nxeon-golive-decisions-2026-10-08]]). Use Sonnet subagents for analysis AND build work; no Opus/Fable unless told.

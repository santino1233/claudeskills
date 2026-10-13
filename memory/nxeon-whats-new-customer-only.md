---
name: nxeon-whats-new-customer-only
description: "What's New / update-announcement entries must only cover customer-facing changes, never internal admin/ops tooling"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-30T22:12:19.924Z
---

Update Announcements ("What's New" popup + feed, [[nxeon-improve-agent]] related work) must only describe changes a customer actually experiences in their own dashboard — new panel features, UI improvements, new self-serve options, etc.

**Why:** the user corrected this after a batch of work landed that mixed customer-facing game-panel features (command library, player history, custom domains, public directory, game-mode presets, scheduling) with purely internal admin tooling (ticket chat UI overhaul, live-chat admin overhaul, cold-email sent-preview viewer). The admin-only items are operational/staff tooling — a customer has no way to see or use them, so they must never appear in a customer-facing changelog.

**How to apply:** before drafting or publishing a What's New entry, filter the day's shipped work down to only what a customer can open and use themselves. Admin dashboards, internal support tooling, ops/marketing infrastructure (cold email, chat-agent internals, admin-only panels) are excluded even if they were built in the same session/batch as customer features.

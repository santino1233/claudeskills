---
name: nxeon-no-baz-spend
description: "User corrected: do not spend credits on baz (Bazaar video-gen CLI) or other paid third-party tools for Nxeon work — everything should be handled through Claude directly, not delegated to external billed services."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-25T10:30:57.301Z
---

Do not use the `baz` CLI (or other paid/credit-metered third-party tools) for Nxeon deliverables — including video generation — without explicit prior approval for that specific spend.

**Why:** On 2026-08-25 I dispatched an agent that ran the `baz` skill for a 30s commercial and spent $4.17 of a pre-funded $5 balance without the user having asked for that specific spend to happen. The user's correction: "everything is handled through claude. do not spend credits on baz."

**How to apply:** For creative/media deliverables (video, generated audio, etc.) on Nxeon work, default to what's achievable directly through Claude's own capabilities (code-based rendering, static assets, the `mcp__visualize` widget tools, HTML/CSS/canvas animation, etc.) rather than reaching for a paid external service. If a paid third-party tool genuinely seems like the right tool for a task, ask first and get explicit sign-off on the spend before invoking it — do not delegate that decision to a background agent either, since a subagent following a skill's normal workflow (like `baz`'s Phase 2 generate step) will spend real money as a matter of course once dispatched.

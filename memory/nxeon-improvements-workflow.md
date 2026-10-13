---
name: nxeon-improvements-workflow
description: "The Nxeon admin Improvements board is only for the background nightly scanner, not for direct chat requests"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-07-25T04:02:18.481Z
---

The **Improvements board** (`/admin/improvements`) is ONLY for the background nightly
scanner ([[nxeon-improve-agent]]) to propose findings the owner reviews/approves.

**When the owner asks for something directly in chat, just DO it** — do not write it
to the Improvements board for approval. Asking in chat IS the approval.

**Why:** the owner explicitly distinguished the two paths — chat = "do it now,"
board = "things a background agent found that I want to vet before they happen."

**How to apply:** implement direct chat requests immediately (build → verify →
deploy → commit/push → update DOCUMENTATION.md — see [[nxeon-docs]]). Reserve
`scripts/write-improvement.ts` / the board for the server-side nightly scan only.
Every change ships to GitHub + docs every time (owner's standing rule).

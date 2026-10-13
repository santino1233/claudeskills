---
name: nxeon-no-ticket-replies-without-approval
description: "never send a support-ticket reply (directly or via a dispatched agent) without the user's explicit approval first"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-30T04:15:39.780Z
---

Never send a reply on a Nxeon support ticket — to a customer, via `replyTicket`/`writeTicketReply` or any equivalent path — without the user's explicit approval of the exact message first. This applies to me directly AND to any background agent I dispatch that touches ticket/customer communication.

**Why:** given directly after a background agent (dispatched to back up a customer's VM before an OS reinstall — see [[nxeon-darkeden-migration]]) posted a factual, appropriate-content ticket reply on its own initiative as part of "reporting completion," without being asked to. The content wasn't wrong, but it went out without sign-off, which is the actual problem — the user wants to review outbound customer communication before it sends, not just have it be accurate.

**How to apply:** when dispatching an agent for any task that touches a support ticket (migrations, refunds, upgrades, troubleshooting), explicitly instruct it to draft the customer-facing update and report it back for approval rather than posting it itself. When doing ticket work directly myself, always draft the reply and show it to the user first — this mirrors the pattern already established earlier in this session for ticket replies I sent directly (draft → user edits/approves → send), now made an explicit standing rule that also covers dispatched agents, which don't inherit conversational context about this expectation unless told directly.

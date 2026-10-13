---
name: nxeon-customer-support-focus
description: "the user runs a dedicated session/workflow for Nxeon customer support — tracking live customers, drafting ticket replies, monitoring account health"
metadata: 
  node_type: memory
  type: project
  originSessionId: ec6fa978-d80b-4147-9982-eea470598e2c
  modified: 2026-08-31T22:04:24.482Z
---

Starting 2026-08-31 the user set up a session specifically scoped to **Nxeon customer support**: tracking live customers (signups, activity, spend, service status), and helping draft replies to support tickets — i.e. everything customer-facing/customer-success related for [[nxeon-platform]], as opposed to feature/dev work sessions.

**Why:** the user wants a recurring place to check in on customer health and handle tickets without mixing it into feature-development conversations.

**How to apply:** in sessions scoped this way, proactively look things up directly in the Nxeon Postgres DB (`User`, `Visit`, `Ticket`, `TicketMessage`, wallet/billing tables — connection string in `/opt/nxeon/.env`) rather than asking the user to look things up themselves. [[nxeon-no-ticket-replies-without-approval]] still applies in full here — this session existing to "help reply to tickets" is not itself approval to send; every outbound ticket reply still needs the user's explicit sign-off on the exact wording before it goes out.

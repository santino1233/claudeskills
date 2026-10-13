---
name: nxeon-creator-invite-flow
description: "How to onboard a list of creator emails into the Creator Partner Program — match to the owner's creator CSV, create DRAFT invites, owner previews, then send"
metadata:
  node_type: memory
  type: project
  originSessionId: ec6fa978-d80b-4147-9982-eea470598e2c
  modified: 2026-09-27T18:33:49.527Z
---

When the owner hands over a list of creator emails who said yes or are genuinely interested, onboard them into the Creator Partner Program like this:

1. **Match each email to the owner's master creator CSV:** `/opt/nxeon/board-uploads/board/cmuh36ziz02l9hl4m7ws5jczm/92633178a05259c5a028237b.csv`. It has 513 rows with the columns `Name, Youtube Channel, Primary game, Email, Current Hosting Sponsor, Country, Subscriber count, Emailed`. It's also attached to a board card. Report any unmatched email; never guess a name or channel.
2. **Create DRAFT invites only**, with `scripts/partner-invite-batch.ts --emails <file> --csv <csv> [--dry-run] [--preview <email>]`, or from the "Invite a creator" import in /admin/partners. Both were built on branch feat/partner-dashboard-tabs, 2026-09-27. Each invite carries the creator's name and channel link, which prefill their partner profile and socials when they accept.
3. **Show the owner the rendered email preview.** Don't send until they approve it.
4. **The owner (or I, on their explicit go) sends the batch.** The creator gets a signup link, then registers or logs in, then picks their own sponsor code (at most 8 letters/digits, case-insensitive), then lands in their partner portal.

**Why:** the owner said to "save this flow and setup for when I give you more lists of emails". They also said they want to preview the email before it goes out, and that invites wait until the portal edits are finished. That matches the standing rule in [[nxeon-no-ticket-replies-without-approval]]: nothing goes out to people without sign-off.

**How to apply:** batch 1 (12 creators, 2026-09-27) is matched in `/root/nxeon-creator-invites/batch-2026-09-27.json`. It is not created in the database or sent yet; it's waiting on the partner portal branch shipping and the owner's preview approval. Reply drafts for the outreach blast are in `/root/nxeon-creator-replies/REPLIES.md`. See [[nxeon-creator-partner-program-live]].

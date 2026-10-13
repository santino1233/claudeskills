---
name: nxeon-discord-ticket-leak-2026-09-05
description: "Discord support ticket/live-chat channels were visible to the whole guild (no @everyone deny) — original leak fixed same day, but a NARROW recurrence surfaced 2026-09-06 and is still UNRESOLVED"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-09-06T11:10:50.778Z
---

**Incident (2026-09-05): a Discord member with no staff role ("STRIKER") could see every
support-ticket and live-chat channel in the "Nxeon Cloud" guild.** Reported by the owner with a
screenshot of the member's profile plus a screenshot of the full ticket channel list.

**Root cause**: `lib/discord.ts`'s `createGuildCategory()` and `createGuildTextChannel()` created
Discord categories/channels with zero permission overwrites of their own.
`lib/discord-bridge.ts`'s `grantCustomerAccessAndSummary()` only ever adds a per-member ALLOW
overwrite for the ticket's own customer — that does nothing to restrict everyone else when there
was never a baseline DENY for @everyone. The doc comment in discord-bridge.ts assumed "the
category's existing staff-only baseline" — that baseline was never actually established in code.
Every category in this guild is created manually in Discord's own UI (both functions have zero
callers for category creation), so this was a config gap compounding a code gap, not purely one or
the other.

**Fix, both halves shipped same day**:
1. **Immediate mitigation directly against the live Discord server** (before any code deploy): a
   `@everyone` VIEW_CHANNEL deny overwrite added to the Support Tickets, Live Chat, and Archived
   categories via the bot's own REST API (one-off script using `lib/discord.ts`'s existing
   functions) — verified by reading the categories' `permission_overwrites` back afterward.
2. **Full audit of every other category** in the guild (14 total) — Staff HQ / Meetings /
   Management were already correctly locked down (pre-existing, not part of the bug). Welcome,
   Community, Support self-help (support-help/knowledge-base/bot-commands), Game Servers, Voice,
   and Alerts all hold genuinely public/community content and were confirmed correct as-is — not a
   leak, left untouched.
3. **Code fix (commit `9579945`)**: both `createGuildTextChannel()` and `createGuildCategory()` now
   default to an explicit `@everyone` deny-view overwrite at creation time, rather than relying on
   inheriting a category's own permissions. Both functions' only real caller
   (`lib/discord-bridge.ts`'s ticket/chat channel creation) gets the fix automatically since it
   didn't pass its own overwrites — no call-site changes needed. A future caller that genuinely
   wants a public channel/category can opt out with `permissionOverwrites: []`.

**Why:** Discord's own permission resolution needs an explicit deny at the category (or channel)
level — @everyone can see a channel by default unless something denies it. A per-member ALLOW
overwrite (which is all the ticket-linking code ever set) is irrelevant to everyone who ISN'T that
member.

**How to apply (if this pattern shows up elsewhere):** any code that creates a Discord
channel/category meant to hold private, per-customer data must set an explicit deny for
`@everyone` (role id == guild id) at creation time — never assume the parent category already has
one, and never assume a later per-member ALLOW is sufficient on its own.

---

**UNRESOLVED recurrence, 2026-09-06 — narrower than the original, not yet explained.** The owner
reported the day after the fix above that people could "still see the tickets and other things."
Investigation (fresh audit script reads of `permission_overwrites`, guild roles, dangerous-permission
bit decode, the guild's own onboarding config, a self-identity check on the bot's own role) found the
category-level `@everyone` deny from the fix above is still correctly in place — this is NOT the
original bug recurring. Four hypotheses were tested and ruled out with direct evidence, not just
reasoning:
1. A broad/misassigned Administrator role — disproven; the only Administrator-permission role in the
   guild is the bot's own, held only by the bot.
2. The reporting member ("sadikrox") holding one of the 5 legitimate staff roles — disproven by the
   owner's own observation that sadikrox sees none of the other staff-only categories, only this one.
3. Stale Discord client cache from before the fix — disproven: a genuinely **fresh** account
   ("hilary," created after the fix) exhibited the identical narrow symptom, seeing exactly one
   ticket channel (`ticket-0u8778u8`) in a "Suggested" sidebar section while correctly NOT seeing
   Live Chat, Support Tickets, or any other staff-only category.
4. Discord's native onboarding "default channels" feature, and a code-side member-join handler —
   neither mechanism exists for this guild/codebase.
A re-fetch of `ticket-0u8778u8` and its parent category confirmed zero permission drift from what the
fix set. **Left open, unanswered**: whether either test account can actually open and read that one
channel's message content, or merely sees its name/existence in the sidebar with no real access —
this distinction was never confirmed before the owner moved to an unrelated topic (primary-node CPU
investigation, 2026-09-06) and the thread was not picked back up in the same session. Worth checking
next: whether Discord's "Suggested" sidebar section (client-side channel recommendation, not the
same code path as `permission_overwrites`) can independently surface a channel's *existence* to an
account that still has zero real VIEW_CHANNEL grant — that would reconcile "sees the name" with
"still correctly denied everything else" without requiring any new server-side leak at all.

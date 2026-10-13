# Nxeon Discord: notification fix + full server redo

Branch `fix/discord-notifications-and-redo` (worktree `/tank/nxeon-wt-discord`). Nothing in this document has been applied to the live Discord server. The only live calls made were read-only GETs of the guild's channels and roles.

---

## Part 1: why Discord notifications stopped (fixed on the branch)

### Root cause

Discord allows at most **50 channels per category**. The support bridge (`lib/discord-bridge.ts`) creates one text channel per ticket and one per live chat. On close, it moves the channel into a single "🗄️ Archived" category instead of deleting it.

Evidence:
- **Read-only GET of the guild on 2026-10-07.** "🎫 Support Tickets" holds 50/50 channels, "💬 Live Chat" 50/50 and "🗄️ Archived" 50/50. The guild has 187 channels in total.
- **Prod journald, 2026-10-04 onwards.** Discord rejected the bridge's calls 132 times with `400 {code: 50035, errors: {parent_id: …}}`. That is Discord's "maximum number of channels in category reached" error. Our log printed the details as `[Array]`, which is why nobody noticed.
- **Prod DB (read-only).**
  - 38 of the 50 channels in Support Tickets belong to CLOSED tickets. All 50 in Live Chat belong to CLOSED chats. They are stuck there because their archive move failed.
  - The last ticket that got a channel was created 2026-10-04 06:31 UTC. The last chat that got one was created 2026-10-06 18:34 UTC.
  - Three open tickets from this week never got a channel at all.

Order of events:
1. Archived filled up around 2026-10-04.
2. Every archive move after that failed, so closed channels stayed where they were.
3. Support Tickets filled up (first failed create: 2026-10-04 06:58 UTC).
4. Live Chat filled up on 2026-10-06 around 18:34 UTC. This is the "since yesterday" the owner saw: live chats stopped then, and tickets had already stopped on 10-04.
5. From then on, every new ticket or chat failed to get a channel. The bridge is deliberately best-effort, so it dropped the failure silently.

Ruled out, with evidence:
- Bot token is valid: the GETs return 200 and the bot has Administrator.
- `discord_enabled = true`.
- The 10-06 live-chat overhaul still calls `mirrorChatMessageToDiscord` (now through `after()`).
- No 401, 403 or 429 responses appear in the logs.

**This is not a credential problem. The owner does not need to rotate or re-enter anything.**

### The fix (commit `eb045e4611`)

- **Overflow categories.** `lib/discord-capacity.ts` (pure planner) and `lib/discord-category-pool.ts` (runtime). When a category is full, the bridge creates "🎫 Support Tickets · 2" (and so on) instead of failing.
  - The new category copies the staff role allows from the original.
  - It always gets an explicit `@everyone` VIEW_CHANNEL deny. This keeps the 2026-09-05 leak lesson, and the overwrites are tested.
- **Archive is capped, then evicts.** The archive grows to `discord_archive_max_categories` categories (default 3, so 150 channels). After that, the oldest archived channel is deleted, but only if it belongs to a CLOSED ticket or chat. Its full transcript is still in Nxeon, and its `discordThreadId` is cleared so a reopen creates a fresh channel. `discord_archive_evict_when_full=false` turns eviction off.
- **Self-heal.** A throttled reconcile runs at most every 15 minutes per web process, triggered by the bridge's own mirror calls. It:
  - moves channels of CLOSED items out of the live categories (25 moves per run);
  - mirrors up to 10 open tickets from the last 7 days that never got a channel.
  It runs in the web process, not the worker, because the worker runs under plain tsx and the Discord modules are `server-only`.
- **Never silent again.**
  - A failed channel create is written to ErrorLog, so it shows in the admin errors view.
  - Staff get a one-line notice in Staff HQ `#support-queue`: subject, priority and admin link, with no customer email. This only happens if that channel's category denies @everyone.
  - Discord error bodies are now logged in full.
- **Mention safety.** Mirrored customer and visitor text can no longer ping. `allowed_mentions: {parse: []}` is now set on every bridge post. Before this, a visitor typing "@everyone" was a real ping, because the bot holds Administrator.
- **Tests:**
  - `test/discord-capacity.test.ts` reproduces the incident with the exact prod error body and a guild shaped like the live one: 50/50/50 categories, 187 channels.
  - `test/discord-bridge-fallback.test.ts` covers the staff fallback notice.

### What the owner needs to do for Part 1

1. **Approve deploying the branch.** That is all. After deploy, the next ticket or chat:
   - creates "🎫 Support Tickets · 2" or "💬 Live Chat · 2" and is mirrored immediately;
   - starts the reconcile, which archives the 88 stale channels over about 4 runs. That creates "🗄️ Archived · 2" and "· 3", with no evictions at today's volume.
2. **Optional: run the catch-up straight after deploy** instead of waiting for the reconcile:
   `NXEON_DB_TARGET=nxeon npx tsx scripts/discord-bridge-reconcile.ts --apply`
   Without `--apply` it is a dry run. A dry run on 2026-10-07 reported: 38 + 50 stale channels, 3 backfill tickets, archive next action "create-overflow".
3. **Decide on eviction.** It is on by default. Set `discord_archive_evict_when_full=false` if old closed channels must never be deleted from Discord. Archive moves then start failing again once there are 3 archive categories (Nxeon keeps every transcript either way).

The structural fix is thread mode (Part 2 below). Private threads don't count toward either cap.

---

## Part 2: the server redo

### What the research found (public sources only)

- **ServerVerse.** Its public docs send customers to a **web ticket form** with a 24-48 h reply window, and describe the Discord as "talk to the team and community". Its Discord listing describes a general tech/gaming community with "bots integration". I could not verify from public information which ticket bot it uses, or whether it has live chat or a status feed in Discord. Those features are only visible after joining. If the owner wants a feature-for-feature match, someone should join the server and list its channels by hand.
- **The pattern from the best-documented hosts** (WinterNode, Physgun):
  - A portal "Connect Discord" button gives a client role.
  - That role unlocks client-only channels and perks.
  - Private Discord tickets come with verified identity.
  - WinterNode advertises Discord as its fastest support route.
  - Shockbyte and BisectHosting keep tickets on the web and use Discord for peer help.
  - Bloom and PebbleHost reviews mention fast Discord tickets.
  - exaroton runs its own bot for live server-status embeds.
- **Platform facts that shape the design:**
  - 500 channels per guild, 50 per category; threads are not counted.
  - Private threads are visible only to members and to holders of MANAGE_THREADS.
  - Forum channels support tags.
  - Linked Roles (`role_connections.write`) let an app expose up to 5 metadata fields that a role can require.
  - AutoMod allows 6 keyword rules plus spam, preset, mention and profile rules.
- **Bot costs (pricing UNVERIFIED unless noted; re-check before buying):**
  - Tickets (tickets.bot): $2.99/server/month premium, verified on its own page. Transcripts go to its R2 archive, so customer messages leave Nxeon.
  - Ticket Tool: free tier.
  - Wick (anti-raid): about $5/month.
  - Sapphire (automod and logging): free.
  - Double Counter (alt detection): free core.
  - Xenon (backups): free base.
  - Carl-bot about $7.99, Dyno about $4.99, MEE6 about $11.95.

### Design decision: one guild, private-thread ticketing, built on Nxeon's own bot

The earlier blueprint (`docs/COMMUNITY-DISCORD-BLUEPRINT.md`, mkt-036) recommended two guilds and no tickets in the community. The owner now explicitly wants in-Discord ticketing and live chat. This plan keeps one guild and removes the leak class instead of splitting:

- **Tickets become private threads in one `#tickets` channel** (thread mode, built).
  - A customer sees only the threads they were added to.
  - Staff see all of them through MANAGE_THREADS.
  - There are no per-ticket channel overwrites to get wrong, so this removes the 2026-09-05 leak class and its 09-06 "Suggested sidebar" variant.
  - It never hits the 50 or 500 caps again.
- **Live chats become private threads in staff-only `#live-chats`.** Website visitors are not in Discord.
- **The ticket system stays Nxeon's.**
  - Every Discord ticket is a real Nxeon ticket (`createTicketCore`).
  - Every reply goes through the Reply button, so it lands in the Nxeon ticket. The bot is HTTP-only and cannot read typed messages, so typing in tickets is denied for everyone except the bot.
  - The full transcript is the Nxeon ticket. No third-party ticket bot sees customer data.
- **Off-the-shelf bots are used only for moderation and safety**, never with access to Nxeon data.

If the owner still prefers two guilds, everything below can be split: the support desk and staff categories move to a private guild, and the bridge settings point there.

### Roles (top to bottom; existing roles are reused by id so members keep them)

| Role | Who | Guild permissions |
|---|---|---|
| Nxeon Support (bot, managed) | the bot | Today it has Administrator. After the apply, the owner reduces it to: View Channels, Manage Channels, Manage Roles, Manage Threads, Create Private Threads, Send Messages, Send in Threads, Embed Links, Attach Files, Read History, Use App Commands. |
| 👑 Owner | owner | Administrator (personal account with 2FA) |
| 🛡️ Admin | senior staff | Manage Channels/Messages/Threads, Kick, Ban, Timeout, Audit Log, Nicknames, Events, Mention Everyone |
| 🧭 Manager | managers | Manage Messages/Threads, Timeout, Audit Log, Events |
| 🔨 Moderator (new) | community mods | Manage Messages/Threads, Timeout, Kick |
| ⚙️ Nxeon Team (renamed from Staff) | every employee | none (hoisted "this is really staff" marker) |
| 🎧 Customer Support | support agents | Manage Threads (sees all ticket threads) |
| 🤖 Bots (new) | third-party bots | Manage Messages, Embed Links, Timeout |
| 💎 Partner | active creator partners (synced) | none |
| ✅ Verified Customer | linked Nxeon accounts (synced) | none; unlocks #tickets, customer lounge |
| 🖥️ VPS Owner / 🎮 Game Server Owner / 🌐 Hosting Customer | synced from real services | none |
| 📣 Announcements / 🛰️ Status Alerts / 🎁 Giveaways (new) | self-assigned in Onboarding | none (ping roles) |
| Minecraft / Valheim / Rust / Palworld / ARK / Other Games (new) | self-assigned in Onboarding | none; unlock that game's channel |

Today **every badge role holds MENTION_EVERYONE**, so any linked customer can ping the whole server. @everyone can also create invites and private threads. The plan strips all of these (enforced by test).

### Channels

| Category | Channel | Type | Who | Notes |
|---|---|---|---|---|
| 📌 START HERE (renamed WELCOME) | welcome | text | read only | welcome panel |
| | rules | text | read only | rules panel; set as the guild rules channel |
| | announcements | announcement | read only | followable |
| | whats-new | announcement | read only | auto-post from What's New (off until switched on) |
| | status (renamed nxeon-server-status) | announcement | read only | incident embeds, crossposted |
| | link-your-account | text | read only | link button to `/dashboard/settings?tab=integrations` |
| 🎫 SUPPORT | open-a-ticket | text | read only | "Open a ticket" button (same modal and gate as /support) |
| | tickets | text | Verified sees own threads only | private-thread host; no typing, Reply button only |
| | faq (renamed knowledge-base) | text | read only | |
| | community-help | forum | everyone | tags setup/mods/network/performance/solved; old #support-help goes to Legacy |
| | bot-commands | text | everyone | /status, /support |
| 💬 COMMUNITY | general (3 s slowmode), introductions (30 s), off-topic | text | everyone | |
| | showcase | forum | everyone | game tags |
| | suggestions | forum | everyone | tags new/under-review/planned/shipped/declined |
| | giveaways | text | read only | official only; DM-scam warning in topic |
| 🎮 GAMES (renamed) | looking-for-group | forum | everyone | |
| | minecraft, valheim, rust, palworld, ark, other-games | text | only that game's role | roles picked in Onboarding |
| 💎 CUSTOMERS (new) | customer-lounge, beta-feedback (forum) | text/forum | Verified + Partner | |
| | creators | text | Partner only | |
| 🔊 VOICE | Lounge, Gaming 1, Gaming 2, Community Call (stage) | voice | everyone | |
| | Support Voice | voice | support/staff connect only | |
| 🛟 SUPPORT DESK (new, staff) | support-queue (moved from Staff HQ) | text | staff | new-ticket/chat pings @Customer Support with a thread link |
| | live-chats | text | staff | private-thread host for website live chats |
| | escalations, ticket-transcripts | text | staff | |
| 🔒 STAFF HQ | staff-announcements, staff-chat, ops-alerts (ex status-alerts), mod-log (ex moderator-only), automod-alerts, bot-logs, Staff Room (voice) | | staff | |
| 🧭 MANAGEMENT | leadership, meeting-notes | | manager/admin | |
| 📦 LEGACY (new, staff read-only) | old support-help, showcase, game-server-chat, AFK / Lounge | | staff read only | nothing is deleted |
| (untouched) | 🎫 Support Tickets, 💬 Live Chat, 🗄️ Archived (+ overflow) | | bridge-owned | the redo never touches these; they drain as old tickets close |

Guild settings:
- Verification level Medium.
- Default notifications: only @mentions.
- Explicit content filter: all members.
- Rules channel #rules, system messages to #mod-log, community updates to #staff-announcements, safety alerts to #automod-alerts.

### Onboarding, rules screening, account linking

- **Native rules screening** with the text in `lib/discord-embeds.ts` `RULES_TEXT`.
- **Native Onboarding questions** (the owner sets these in Discord; the API exists but they are easier to tune in the UI):
  1. What do you play? This assigns the game roles.
  2. Which pings do you want? Announcements, Status Alerts, Giveaways.
  3. Are you a Nxeon customer? This points to #link-your-account.
- **Customer-verified role (exists, improved).**
  - The portal's Discord OAuth link (`lib/actions-discord-link-customer.ts`) sets `User.discordUserId`.
  - `lib/discord-roles.ts` syncs Verified, VPS, Game, Hosting and Partner badges from real account data.
  - New: a 6-hourly resync of every linked account, so a cancelled VPS loses its badge without the customer re-linking (`discord_role_resync_enabled`).
- **Phase 3 option: Discord Linked Roles** (`role_connections.write`, metadata such as `active_services`). This would make the Verified role a native Discord requirement instead of a bot assignment. It needs storing each user's OAuth refresh token, which is a schema change, so it is not built.

### Bots and features: Nxeon's own vs off-the-shelf

| Feature | How | Cost / privacy |
|---|---|---|
| Ticketing + transcripts into Nxeon | **Nxeon bot (built)**: thread mode, open-a-ticket panel, Reply button for staff AND the ticket's own customer, echoed replies as the Discord transcript line, support-queue ping, linked staff auto-added to threads so Discord notifies them | free; data stays in Nxeon |
| Live chat bridge | **Nxeon bot (built)**: website chats as private threads in staff #live-chats | free |
| Status / incident feed | **Nxeon bot (built)**: incident embeds (red/amber/blue, green on resolve) to #status, crossposted; outages ping the opt-in Status Alerts role | free |
| Game-server status embeds | Nxeon bot `/status` already exists (ephemeral, per account). Public per-game status embeds are Phase 3 (needs a message-edit loop) | free |
| Announcements / What's New | **Nxeon bot (built)**: untargeted releases auto-post to #whats-new (default OFF, watermark so nothing is back-posted) | free |
| Account linking / verified role | **Nxeon bot (exists + resync built)** | free |
| Suggestions | Native forum with tags (no bot). Phase 3: a Nxeon button that copies a suggestion into the admin board | free |
| Giveaways | **Not at launch.** Run by hand in #giveaways once consumer-law rules are written. If wanted later, a mainstream giveaway bot | owner decision |
| Auto-moderation | **Discord AutoMod** (native): scam links, invite links, mention spam (5+), keyword preset, profile-name rule; alerts to #automod-alerts | free |
| Anti-raid / logging | **Sapphire** (free, 80+ log types) or Wick (about $5/mo, stronger anti-nuke). Pick one; logs to #mod-log | third party sees public channel messages only; no Nxeon data |
| Alt detection | Double Counter (free core), only if raids happen | sees IP/fingerprint of joiners via its own verify page; skip unless needed |
| Backups | Xenon free (structure snapshot before the apply) | structure only |

Rejected:
- **Ticket Tool / tickets.bot for tickets.** Customer messages would leave Nxeon (tickets.bot stores transcripts in its own archive), and those tickets would not be Nxeon tickets.
- **MEE6.** Cost, and its features duplicate native AutoMod.

### What is built on the branch (not run against the live server)

| Piece | Files |
|---|---|
| Category overflow + archive eviction + reconcile (Part 1) | `lib/discord-capacity.ts`, `lib/discord-category-pool.ts`, `scripts/discord-bridge-reconcile.ts` |
| Thread-mode bridge (default OFF: `discord_bridge_mode=channels`) | `lib/discord-thread-plan.ts`, `lib/discord-threads.ts`, `lib/discord-bridge.ts` |
| Customer replies from Discord (own ticket only) + echoed transcript line + Reply button under it | `lib/discord-bridge.ts` `resolveDiscordTicketReplyActor`, `app/api/webhooks/discord/route.ts` |
| Open-a-ticket panel button `dc_open_ticket` | `app/api/webhooks/discord/route.ts`, `lib/discord-embeds.ts` |
| Status feed embeds + crosspost + opt-in ping | `lib/discord-status-alerts.ts`, `lib/discord-embeds.ts` |
| What's New auto-post (default OFF) | `lib/discord-housekeeping.ts`, `lib/discord-embeds.ts` |
| 6-hourly badge-role resync | `lib/discord-roles.ts`, `lib/discord-housekeeping.ts` |
| Mention-ping safety on every bot post | `lib/discord.ts` |
| Server spec + planner + executor + dry-run apply script | `lib/discord-redo/{permissions,spec,plan,execute}.ts`, `scripts/discord-redo-apply.ts` |
| Tests | `test/discord-capacity`, `discord-bridge-fallback`, `discord-redo-plan` (incl. apply against an in-memory fake guild + idempotent re-plan), `discord-thread-plan`, `discord-embeds` |

The dry run against the live guild (GET only) is saved in `dry-run-2026-10-07.txt`:
- roles: 11 to create, 10 to update;
- categories and channels: 3 categories and 26 channels to create, 24 channels to update, 4 old channels moved to Legacy;
- 28 settings written and 3 panels posted;
- nothing deleted.

### Migration plan (keeps every member)

1. **Deploy the branch** (Part 1 fix included). Watch for "· 2" overflow categories appearing and notifications resuming.
2. **Snapshot first.** Take a Xenon (or manual) backup of the server structure.
3. **Announce in #announcements 24 h ahead:** "We're reorganising the server tomorrow. No one loses roles; old channels move to a read-only archive."
4. **Owner reviews** `npx tsx scripts/discord-redo-apply.ts` (dry run). If it's right, run:
   `NXEON_DISCORD_REDO_APPROVED=yes NXEON_DB_TARGET=nxeon npx tsx scripts/discord-redo-apply.ts --apply --confirm-guild=1543448442649706679`
   This takes about 90 REST calls, spaced 350 ms apart. It writes the new channel and role ids into Settings.
5. **Owner, in Discord's UI:**
   - Onboarding questions.
   - Rules screening text.
   - AutoMod rules.
   - Safety Setup: 2FA for moderation.
   - Drop the bot's Administrator for the explicit list above.
   - Invite the chosen moderation bot into the 🤖 Bots role.
6. **Switch on thread mode:** `discord_bridge_mode=threads`. New tickets and chats become private threads; old channel tickets keep working until they close.
7. **Optionally switch on What's New:** `discord_whats_new_autopost=true`.
8. **Two weeks later:** delete the empty "Text Channels", "Voice Channels", "📡 Alerts" and "🗓️ MEETINGS" categories by hand. When the old bridge categories have drained, they can go too.
9. **Re-point** the website footer `social_discord` to a permanent invite into #welcome.

### Needs owner approval / input

- Deploy of the branch (Part 1 + inert Part 2 code).
- Archive eviction default (on).
- The redo apply itself, after reading the dry run.
- Single guild vs two guilds. This plan recommends one guild with thread tickets, reversing mkt-036 D1 now that tickets are threads.
- Moderators (who), and anti-raid bot choice (Sapphire free vs Wick paid).
- Giveaways: not at launch, pending rules.
- Whether to confirm the ServerVerse features by joining their server by hand.
- No credentials need rotating or adding for anything above. The existing bot token and OAuth app are sufficient. Linked Roles (Phase 3) would need the OAuth app's Linked Roles Verification URL to be set in the Discord developer portal.

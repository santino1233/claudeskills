# Live chat — diagnosis (2026-10-06, feature/livechat-overhaul)

Measured against PRODUCTION (SELECT-only, read-only Prisma/psql) on main @ b23bc8e8d5.

## Prod data shape
| | value |
|---|---|
| ChatConversation rows | 94 (8 OPEN, 4 unreadForAgent) |
| ChatMessage rows | 1,025 (max 163 / avg 11 per conversation) |
| ChatAttachment rows | 37, **13.68 MB of image bytes** (largest 3.93 MB PNG, top 5 all PNG 0.6–3.9 MB) |
| Table sizes | ChatAttachment 14 MB, ChatMessage 464 kB, ChatConversation 112 kB |

## Root causes (with evidence)

### 1. Admin inbox re-downloads EVERYTHING every 5 seconds (incl. every image's bytes)
`components/admin/ChatInbox.tsx` polls the server action `listConversations()` every 5 s
(`POLL_MS = 5000`). That action (lib/actions-chat.ts) does:

```ts
db.chatConversation.findMany({ take: 200,
  include: { messages: { orderBy: { createdAt: "asc" }, include: { attachment: true } } } })
```

- `include: { attachment: true }` selects `ChatAttachment.data` (Bytes) — **every image ever sent is
  read out of Postgres on every poll**, then thrown away (only id/mime/size are returned).
- Every message of every conversation (1,025 today, grows forever) is serialized to the client each poll.

Measured (prod, Prisma, 3 runs): **201–229 ms server time per poll, 310,485-byte payload per poll**
(≈3.7 MB/min per open admin tab, before RSC overhead). psql equivalent: 154–160 ms / 27.5 MB on the wire
with the bytes vs 49–56 ms / 175 kB without them (≈50 ms of that is connection baseline).
The page's first render (`ChatDeskView`) does the same full load.

### 2. Server actions are serialized — the poll blocks the reply button
Next.js runs server actions from one client **one at a time**. The 5 s `listConversations` poll is a
server action, so a staff "Reply" click queues behind an in-flight 200 ms+ poll, and then itself
`await refresh()` → another full 310 kB `listConversations` before the UI updates. Each write
action also calls `revalidatePath("/admin/chat")`, which re-renders the whole RSC page (the same
full load again) on the next navigation/refresh.

### 3. "Messages take a few seconds to come in" = polling latency + a blocking AI call
- Visitor → admin: only visible on the admin's next 5 s poll (avg 2.5 s, worst 5 s + ~0.2 s query).
- Admin → visitor: only visible on the widget's next 4 s poll (`POLL_MS = 4000` in ChatWidget.tsx).
- Visitor send: `POST /api/chat` **awaits** `mirrorChatMessageToDiscord` (Discord REST round-trip,
  channel creation on first message) **and** `runAssistant` (a full Claude tool-loop call, seconds)
  before responding, so the visitor's own message is "sending…" for the entire LLM call, and the agent
  side doesn't see it any sooner either. Same in `/api/chat/upload`.
- Typing indicators ride the same polls, so they lag 4–5 s too.

### 4. Images: full-size originals, no thumbnails, every poll re-reads bytes
- `/api/chat/attachment/[id]` always streams the ORIGINAL (up to 3.93 MB PNG) into a 192 px-tall
  bubble; no thumbnail/resize, no `loading="lazy"`, no ETag. Fetching the largest one from PG alone:
  53 ms + 3.9 MB transfer per view.
- The attachment row query also `include`s message + conversation (fine) but there is no
  `immutable` cache, so each re-render inside the 1-day window still revalidates on reload.

### 5. Customer side
- GET /api/chat (polled every 4 s) loads the WHOLE conversation with attachment BYTES
  (`include: { attachment: true }`) — 83 ms for the newest open thread on prod.
- No idempotency: a retried POST after a network blip writes a duplicate message.
- No reconnect/backfill logic beyond "next poll"; optimistic message is replaced wholesale on every poll.
- While an admin impersonates a customer, the customer widget is live as that customer:
  `POST /api/chat` resolves `currentUser()` (= impersonated target), so an admin could post a
  message **as the customer** — the same misattribution class as the ticket-reply bug fixed 2026-09-25.

### 6. Indexes
Current: ChatConversation(status,lastMessageAt), (visitorId); ChatMessage(conversationId,createdAt).
At today's size every inbox query is a seq scan of 94 rows (0.2 ms) — **indexes are not the
bottleneck today**; the payload/bytes/polling design is. Indexes for assignedTo/user/lastMessageAt
and ChatMessage(createdAt) are still added (additive) so the new server-side filters stay index-backed
as volume grows.

## nginx
Both prod vhosts (nxeon-cloud, nxeon-admin-cloud) proxy `/` with `proxy_http_version 1.1`,
`proxy_read_timeout 600s`, http2 on, and default `proxy_buffering on`. gzip_types does not include
`text/event-stream`. SSE therefore works **without any nginx change** as long as the app sends
`X-Accel-Buffering: no` (disables buffering per response) and a heartbeat < 600 s (we send 20 s).

## After (feature/livechat-overhaul)

| | before | after |
|---|---|---|
| Admin inbox refresh | poll every 5 s: 201–229 ms server, 310 kB payload, 13.7 MB of image bytes read from PG per tick | no poll; one SSE stream per tab; list = 1 page of 50 rows: ~5–6 ms SQL (prod data, incl. the DISTINCT ON preview fallback), ~16 kB |
| Opening a thread | whole history of every thread already in the 310 kB poll | latest 40 messages, no bytes: ~2.4 ms SQL, ~8 kB; older pages on scroll-up |
| Visitor → agent | next 5 s poll (avg 2.5 s, worst ~5.2 s) | pushed on write: 228 ms end-to-end in `next dev` (includes the POST + DB transaction) |
| Agent → visitor | next 4 s widget poll | pushed on write: 276 ms end-to-end in `next dev` |
| Visitor send round-trip | awaited Discord REST + full Claude tool loop (seconds) | returns after the DB write (232 ms in dev); AI + Discord run in `after()` |
| Typing / read receipts | rode the 4–5 s polls / none | pushed instantly / Seen + Delivered both ways |
| Images in a bubble | original (largest 3.93 MB PNG) | ≤480 px WEBP thumbnail made once: all 37 prod images = 13.68 MB → 281 kB total (avg 7.6 kB), max 144 ms to generate; original only on lightbox; private immutable cache + ETag |
| Duplicate sends on retry | possible | impossible (`@@unique([conversationId, clientId])`) |

E2E (throwaway Postgres + dev server, `/root/agent-notes/livechat/e2e-livechat.mjs`): customer stream
never received the internal note nor any staff id; a foreign visitorId got 404/empty; a customer
session got 403 on every staff route; cross-origin POST 403; while impersonating, the staff list and
stream only carried the impersonated customer's conversations, a different customer's thread 404'd,
dock replies were stored `sender:"agent"` with the admin's authorId, and POST /api/chat as the
customer returned 403.

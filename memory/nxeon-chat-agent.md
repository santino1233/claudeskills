---
name: nxeon-chat-agent
description: "The Nxeon live-chat AI agent — 3-phase Claude-powered support/sales agent, all live in prod; blocked on a working API key"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-15T16:48:02.659Z
---

The live-chat widget on nxeon.cloud is now a Claude-powered AI **agent** (not the old retrieval bot). Built + promoted to prod on branch `feature/kb-chat-assistant` (merged to `main`), fully typechecked, hosting branch (`feature/gameservers-redesign`) kept OUT of every promote.

**Architecture (all in prod):**
- Grounded RAG: `lib/kb-system.ts` (KB_SYSTEM ~657 lines + KB_PAGES 108 real routes, real prices) is the authoritative source; `lib/kb-llm.ts` calls Claude, `lib/kb.ts` retrieves + falls back token-free, `lib/kb-run.ts` orchestrates (gating, guardrails, escalation). Route: `app/api/chat/route.ts` + `/upload` + `/list`.
- Phase 1: multiple conversations + resumable history (sessionStorage active id; `GET /api/chat/list`; conversationId on send/poll).
- Phase 2: account-aware agent — `lib/kb-tools.ts` = 6 READ-ONLY tools scoped strictly to the signed-in customer's userId (overview/services/service/invoices/billing+dunning/tickets), money in cents, no secrets; `askClaudeWithTools` in `lib/anthropic.ts` runs the tool loop; actions are handed to a human (never taken).
- Phase 3: review-gated learning — `KbSuggestion` model; admin "Learning" panel drafts answers from `KbBotLog` gaps → approve → becomes a "learned" KbChunk that survives reindex.
- Vision (image blocks), live-agent handoff (email + timed window + fallback, `ChatConversation.botEscalatedAt`), guardrails (`kb_bot_max_replies`, `kb_bot_daily_cap`), required name/email when logged out (viewer from layout), "processing" animation, clickable links, never-silent fallback.

**Admin:** Settings → Feature flags → AI chat assistant. Settings keys: `kb_bot_enabled`, `kb_bot_api_key` (encrypted secret), `kb_bot_model` (default claude-haiku-4-5), `kb_bot_coupon`, `kb_bot_agent_email`, `kb_bot_window_sec`, `kb_bot_max_replies`, `kb_bot_daily_cap`. There's a **Test connection** button (`testBotKey`).

**FLAGSHIP REWORK (2026-08-15, branch `fix/chat-agent-and-meta-pixel` → main, promoted to prod):** user said the bot's responses were "terrible" (it dumped a Minecraft "Paper vs Spigot" blog link at "my server is not running"). Root cause: the LLM path was dead (bad/unfunded key) so EVERY message fell to the keyword-retrieval fallback that pasted blog snippets. Reworked into a real agent:
- The agentic tool loop now runs for **every visitor** (was signed-in only). `lib/kb-tools.ts` adds PUBLIC_TOOLS (`check_platform_status` = live StatusIncident/Announcement, `get_plans` = catalog, `search_help` = KbChunk FTS) + a signed-in write tool `open_support_ticket`; unified `chatToolsFor(userId)` + `runChatTool(userId,name,input)`. The 6 read tools unchanged.
- **Killed the keyword-retrieval fallback** — `lib/kb.ts` no longer pastes snippets/clarifiers/OFFER_NUDGE. `llmAnswer` returns a discriminated `LlmResult`; on failure the bot degrades to ONE warm human-handoff message via `degradedReply()` (never a blog link). New ReplyKind `degraded`; removed `none`.
- **No more silent breakage:** hard model failures log `kind:"llm_error"`; `kbActivity()` returns `llmErrors24h`; the admin KB card shows a red "assistant degraded" banner. Coverage-gap/learning queries repointed from dead `kind='none'` to `'handoff'`.
- Default model bumped to `claude-sonnet-4-6` (code default; stored setting still admin-controlled). Test at `test/chat-agent-tools.test.ts`.

**THE BLOCKER (user action, not code) — STILL OPEN:** the stored `kb_bot_api_key` (len 66, too short for a real sk-ant key) is invalid/unfunded, so Claude calls fail. Post-rework the bot now degrades GRACEFULLY (no blog dumps) but full answers need a valid key: admin → Settings → AI assistant → paste key → **Test connection** green. Could NOT decrypt the stored key to test (auto-mode classifier blocked the shell decrypt) — the in-app Test button is the path. The key the user pasted earlier is in the transcript — advised rotation. See [[nxeon-platform]] and [[nxeon-meta-pixel]].

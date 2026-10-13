# Nxeon AI gateway for Cyrus mods: design (stub built, no model plumbing)

Owner rules (2026-10-08): **networking must not burn tokens.** Plain web calls through the wrapper cost the customer
nothing. Cyrus tokens are spent **only** when a mod calls the Nxeon AI gateway, and only within hard limits that
default to spending nothing.

## Pieces on the branch

| File | What |
|---|---|
| `lib/cyrus/ai-gateway-budget.ts` | Pure budget maths and states (client-safe). For the cyrus-admin agent and the installed-mod row: `meter()`, `decideCall()`, `settleCall()`, `callReserve()`, `cyrusTokensFor()`, `normalizeOwnerBudget()`, `budgetConsentLines()`, `dayKey()`, `secondsToUtcMidnight()` |
| `lib/cyrus/ai-gateway.ts` | Server-only: per-server/per-mod token (HMAC, `nxai1.<payload>.<sig>`), settings -> `GatewayConfig` |
| `app/api/cyrus/ai-gateway/v1/chat/route.ts` | Stub endpoint. Off by default (503). With the gateway on it checks the token, applies every limit and answers 501 `model_not_connected`. Never calls a model, never charges |
| `test/cyrus-ai-gateway-budget.test.ts` | Unit tests for the budget maths |
| `lib/settings.ts` | `cyrus_ai_gateway_enabled=false`, `cyrus_ai_gw_kill=false`, `cyrus_ai_gw_platform_daily_cap=0`, `cyrus_ai_gw_max_output_tokens=300`, `cyrus_ai_gw_calls_per_min_mod=6`, `cyrus_ai_gw_calls_per_min_server=20` |

## The hard limits (each maps to the owner's numbered requirement)

1. **Off until the server owner enables it.** `OwnerBudget.aiEnabled` defaults to false per installed mod; a mod
   declaring `ai: true` gets `ai_not_enabled` (403) until the owner turns it on.
2. **Daily budgets set by the server owner**, per mod and per server, both default **0** (`no_budget`, nothing
   spent). Range 0 to 100,000 Cyrus tokens; junk input is clamped (`normalizeOwnerBudget`). `meter()` gives the
   usage meter with states `off`, `no-budget`, `ok`, `warn` (from 80 %), `reached`.
3. **Hard stop, failing safe.** Before a call the gateway reserves its **worst case** (whole prompt, about 3
   characters per token rounded up, plus the output ceiling, priced and rounded up). The call goes ahead only if
   `spent + open reservations + this reserve` fits the mod budget, the server budget and the platform cap. Otherwise
   the mod gets a clear error (`budget_reached` / `server_budget_reached` / `platform_cap`, with `Retry-After` until
   midnight UTC). `settleCall()` charges the real cost but **never more than was reserved**, so a budget can never be
   overshot, even when a model reports more usage than expected. A test runs a whole day of calls and checks the
   total stays within the budget.
4. **Per-call ceilings**: output tokens capped at `cyrus_ai_gw_max_output_tokens` (300) whatever the mod asks;
   prompt at most 4,000 characters; 6 calls a minute per mod and 20 per server.
5. **Platform cap and kill switch**: `cyrus_ai_gw_platform_daily_cap` (default 0 = nothing anywhere) and
   `cyrus_ai_gw_kill`, which wins over every other setting.
6. **Consent shows the budget and who pays**: `CapabilityConsent` renders `budgetConsentLines()`: "AI use is paid
   from your Cyrus tokens (the server owner's account)", the daily maximum, and that it stops rather than goes over.
7. **Visible spend**: the installed-mod row and the admin Cyrus overview use `meter(used, budget)`; the admin view sums
   `serverSpent`/`platformSpent` per day.

Ordinary networking keeps its own free limits (30 calls a minute, burst 10, 20 MiB a day each way, 64 KiB requests),
in `net-policy.json` `limits` and `checkNetLimits()`, so one server cannot become a nuisance even with no AI at all.

## Request flow (when built)

`mod -> NxAi helper (in the wrapper) -> POST /api/cyrus/ai-gateway/v1/chat (Bearer per-server token)`
-> kill switch / gateway on -> token valid -> owner enabled + budgets > 0 -> prompt length -> rate -> reserve against
platform, server and mod budgets -> moderation of the prompt -> model call with fixed system prompt and output cap
-> moderation of the answer -> settle (charge <= reserve, release the rest) -> plain-text answer to the mod.

## What the real gateway still needs (not built)

- **Storage**: owner budgets per installed mod (likely next to the lifecycle agent's install rows), daily counters
  and open reservations per mod/server/platform (atomic increments in one transaction), and a hashed token table so a
  single token can be revoked.
- **Charging** through the existing economy (`lib/cyrus/tokens/`), as its own ledger reason (for example
  `ai_gateway`), settled per call, never through build holds.
- **Moderation** of prompts and answers, a fixed server-side system prompt per mod (the mod sends only the player
  text and a short context), answers returned as plain text.
- **Model choice**: one small, cheap model, priced in `GatewayConfig` (`usdPerMInput`, `usdPerMOutput`; placeholders
  today); no customer-chosen models.
- **Token placement**: the Nxeon panel writes the token onto the server outside the mod's folder at install time;
  the token is never in a jar, source, listing or community fork.
- **Admin overview**: today's platform spend against the cap, the top servers and mods by spend, the kill switch.

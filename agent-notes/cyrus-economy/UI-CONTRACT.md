# Cyrus tokens: UI integration contract

How any Cyrus UI (current v4, or the owner's from-scratch redesign) plugs in the token
economy. Everything lives in `components/cyrus-tokens/` (branch `feature/cyrus-tokens`) and is
self-contained: its own store, styles (`tokens.css`, `cyt-*` classes) and Stripe payment form.
A new UI needs only the mounts below. Every component renders **nothing** for accounts outside
the token economy (not live and not a preview account), so mounting them is always safe.

Import everything from `@/components/cyrus-tokens`.

## Mounts (one line each)

| What | Mount | Required? |
|---|---|---|
| `<CyrusTokensHost />` | once, anywhere inside the Cyrus page. Owns the tokens modal (Plans / Top up / History), the inline Stripe card form, and the "Payment received" notice after the Stripe return (`?tokens=ok|pending`). Portals to `<body>`. | **yes** |
| `<CyrusTokenChip compact? beta? />` | header / switcher area. Balance + "Get more"; opens the modal on Plans. Low-balance state built in. | yes (one place) |
| `<CyrusTokenEstimate text model change? />` | in the composer, where the time/cost estimate goes. Shows `~a–b min · ⬡ low–high` tokens; amber + "Get tokens"/"Unlock" when short or locked. `model`: `"katara" \| "saka" \| "yakko"`; `change`: true for a change to an existing mod. | yes |
| `<CyrusModelLock model />` | inside each row of the model picker. "Saka" / "All models" lock pill when the account's plan doesn't unlock it. | yes |
| `<CyrusModelPanelFoot fallback? />` | model picker footer ("Builds spend tokens for what they use… Unlock more models"). | optional |
| `<CyrusTokensMenuItem onPick? />` | a menu row "Tokens & history · 1,234" that opens History. | optional |
| `<BetaLabel short? />`, `<TokenGlyph size? />` | the "Beta · Minecraft Java only" pill and the token mark, for your own layouts. | optional |

## Imperative API (`cyrusTokens`)

| Call | When |
|---|---|
| `cyrusTokens.handleBuildError(json)` | after `POST /api/mod-builder/builds` returns non-2xx. Opens the modal for `insufficient_tokens` / `model_locked` (not for `daily_cap`); returns true if it was a token error. Show `json.error` as the message either way. |
| `cyrusTokens.refresh()` | after a build is created or finishes (the store also polls every 20 s and on window focus). |
| `cyrusTokens.open({ tab?: "plans" \| "topup" \| "history", reason? })` | your own "Upgrade" / "Get tokens" / "Pro" buttons. Wire the Pro/Upgrade CTA to `open({ tab: "plans" })` when `useCyrusTokens().state?.active`, else your non-token fallback. |
| `useCyrusTokens()` | React hook: `{ state, open, tab, reason, notice, loading }`; `state` is `TokenState` (below) or null. |

## Build API behaviour (server-side, already enforced)

`POST /api/mod-builder/builds` (body unchanged; `model` optional). Token errors:

| Status | `code` | Extra fields | Meaning |
|---|---|---|---|
| 403 | `model_locked` | `model` | the plan doesn't unlock that model |
| 402 | `insufficient_tokens` | `need`, `available`, `model` | not enough tokens to start |
| 429 | `daily_cap` | | daily token cap reached |

If `model` is omitted, the server picks the best unlocked one (Saka with a Saka/All plan, else
Katara). Tokens are held when the build starts and settled to the actual cost when it ends.

## Routes (all 404 outside the preview / token economy)

| Route | Returns |
|---|---|
| `GET /api/cyrus/tokens` | `TokenState` |
| `GET /api/cyrus/tokens?history=1&before=<iso>` | `{ rows: TokenHistoryRow[], more }` |
| `POST /api/cyrus/tokens/checkout` `{kind:"plan",tier}` or `{kind:"topup",cents}` | `{ clientSecret, publishableKey }` for Stripe custom checkout (`ui_mode: elements`) |
| `POST /api/cyrus/tokens/plan` `{action:"change",tier}` / `{action:"cancel"}` / `{action:"resume"}` | `{ ok, message? }` |
| `GET /api/cyrus/tokens/return?session_id=` | Stripe return leg; redirects to `/dashboard/cyrus?tokens=ok` |
| `GET /api/cyrus/tokens/checkout-line?gameFamily&monthlyCents&termMonths` | game checkout line (used by `<CyrusCheckoutLine/>` in `components/nx/DeployView.tsx`) |

Types (`lib/cyrus/tokens/view.ts`): `TokenState { active, enforce, balance, reserved, available,
lowBalance, nextExpiry, tier, models, plan, plans[], topup, reserve, rolloverMonths, payments }`,
`TokenHistoryRow { id, kind, delta, hold, at, source, model, buildId, label }`. Never contains a
USD-per-token figure or a model family name (a test checks the components for that).

## Styling

`tokens.css` uses the Cyrus CSS variables (`--cy-ink*`, `--cy-line*`, `--cy-raise*`, `--cy-pop`,
`--cy-grad`, `--cy-accent`, `--cy-cyan`, `--cy-warn`, `--cy-ok`, `--cy-shadow`, `--cy-r-*`) with
fallbacks, and the modal reuses `.cy-modal`, `.cy-modal-back`, `.cy-btn`, `.cy-seg`, `.cy-tag`,
`.cy-ib` when they exist. A redesign that keeps those variable names gets a matching look for free;
otherwise restyle `tokens.css` only (no logic lives in CSS).

## Current mounts (v4, for reference)

- `components/cyrus/CyrusApp.tsx`: `<CyrusTokensHost />`; `cyrusTokens.handleBuildError(j)` +
  `cyrusTokens.refresh()` in `create()`; Pro "Upgrade" -> `cyrusTokens.open({ tab: "plans" })`.
- `components/cyrus/Switcher.tsx`: `<CyrusTokenChip />` after the New button; `<CyrusTokensMenuItem />` above the Pro card.
- `components/cyrus/Composer.tsx`: `<CyrusTokenEstimate />`, `<CyrusModelLock />`, `<CyrusModelPanelFoot />`.
- `components/nx/DeployView.tsx`: `<CyrusCheckoutLine monthlyCents termMonths gameFamily />`.

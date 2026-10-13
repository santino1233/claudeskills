# Cyrus token economy (design, 2026-10-07)

Branch `feature/cyrus-tokens` (worktree `/tank/nxeon-wt-cyrustokens`). Code: `lib/cyrus/tokens/*`.
Every number below is an admin Setting (`cyrus_tok_*`, editable at `/admin/cyrus-tokens`); the
values here are the shipped defaults (`lib/cyrus/tokens/config.ts`). Nothing in this file is a
forecast of customer behaviour: the cost figures are measured builds, the rest are rules.

## 0. The data this is built on

| Source | What | Numbers |
|---|---|---|
| `/root/agent-notes/modbuilder-preview/phase0-builds.jsonl` | 10 real builds, Sonnet 5, pre-tuning | avg $0.28, $0.08-$0.47 |
| docs "AI Mod Builder: tuning" eval (28 prompts) | service 0.3, Sonnet 5.5 | avg $0.104 / median $0.097; simple $0.066, standard $0.102, complex $0.189 |
| same eval, Haiku on simple | Haiku 4.5 | $0.118/build (more turns than Sonnet 5.5), 1/8 failed |
| build service records on VM 88001 (138 builds, read-only) | auto-routed + Cyrus tiers | Haiku-only auto builds avg $0.068 (n=7); Sonnet 5.5 auto avg $0.104 (n=28) |
| Cyrus tier builds (same records) | `tier` set | Katara ChunkMirror change $0.159; Saka ChunkMirror fresh $0.676 (443 s, Sonnet 5); Saka others $0.055 / $0.304; Yakko SimpleHeal $0.341 (Opus 5) |
| ChunkMirror pre-tuning (auto, Sonnet) | | $0.217 |
| Anthropic list prices (per MTok in/out) | | Haiku 4.5 $1/$5 · Sonnet 5 and 5.5 $2/$10 · Opus 5 $5/$25 |
| Refusals (adversarial prompts) | | $0.005-$0.028 |

Two findings the owner should know (not changed by this work, see Owner decisions):
- **Saka maps to Sonnet 5, not 5.5** (`MB_TIER_SAKA`). The tuned default routing uses 5.5, which
  was cheaper, faster and more reliable in the eval. The one Saka-tier ChunkMirror cost $0.676,
  3x the auto-routed one.
- **Katara (Haiku 4.5) is not cheaper per build than Sonnet 5.5** on simple mods ($0.118 vs
  $0.061 in the eval), because it takes about twice the turns. The economy still prices tokens
  on the real cost, so this only affects how much a Katara build spends, never the margin.

## 1. What a token is

**1 token = $0.002 of measured AI cost** (`cyrus_tok_tokens_per_usd = 500`), times a per-model
multiplier: Katara x1.0, Saka x1.0, **Yakko x1.25** (Opus runs vary more and hold a build slot
about twice as long). A build that reached the AI costs at least 5 tokens (`cyrus_tok_min_spend`).

    tokens charged = max(5, ceil(costUsd x 500 x multiplier[model]))

`costUsd` is the build service's own number for that build (`ModBuild.costUsd`). The token is a
*cost* unit, so margin lives entirely in what a token *sells* for (section 3), and Yakko costing
many more tokens than Katara falls out of the real costs (Opus is 5x Haiku per token).

### Tokens per typical build

| Model | Typical (measured) | Tokens | Big build | Tokens |
|---|---|---|---|---|
| Katara | simple $0.068 (auto Haiku avg) | **34** | ChunkMirror change $0.159 | **80** |
| Saka | $0.104 (Sonnet 5.5 avg) / $0.189 complex | **52** / 95 | Sonnet 5 tier: $0.30 / $0.676 | 150 / 338 |
| Yakko | simple $0.341 (measured) | **214** | complex ~$1.18 (Opus 2.5x Sonnet 5 complex $0.47, extrapolated) | ~738 |

Pre-build estimate shown in the composer (`cyrus_tok_reserve_table`, tokens, [typical, high]):

| | simple | standard | complex |
|---|---|---|---|
| Katara | 30-70 | 60-140 | 100-240 |
| Saka | 35-100 | 60-220 | 110-400 |
| Yakko | 100-250 | 200-500 | 400-1000 |

Complexity comes from the existing `lib/cyrus/estimate.ts` feature count (unchanged).

## 2. Game-server grants

    per-month amount = clamp(round5(base + perUsd x monthly price $), min, max)
    initial:  base 100, perUsd 16, min 150, max 750
    renewal:  base 25,  perUsd 6,  min 40,  max 300

`monthly price` = what the customer actually paid per month (after coupons/partner discount,
before tax). Prepaid terms: an N-month purchase gets initial + renewal x (N-1); an N-month
renewal gets renewal x N; N capped at 12 (`cyrus_tok_grant_term_months_cap`).

| Monthly price | Initial | AI cost if all used (% of 1st month) | Every renewal | (% of renewal) |
|---|---|---|---|---|
| $2.99 | 150 | $0.30 (10.0%) | 45 | $0.09 (3.0%) |
| $4.99 | 180 | $0.36 (7.2%) | 55 | $0.11 (2.2%) |
| $8.99 | 245 | $0.49 (5.5%) | 80 | $0.16 (1.8%) |
| $9.99 | **260** | $0.52 (5.2%) | 85 | $0.17 (1.7%) |
| $15.99 | 355 | $0.71 (4.4%) | 120 | $0.24 (1.5%) |
| $30.00 | 580 | $1.16 (3.9%) | 205 | $0.41 (1.4%) |
| $49.99+ | 750 (cap) | $1.50 | 300 (cap) | $0.60 |

Owner's example check: a ~$10 server gives 260 tokens. ChunkMirror on Katara measured 80 tokens
($0.159); even the pre-tuning $0.217 ChunkMirror is 109 tokens. Either way more than half is left
(pinned by a unit test).

Rules: only paid game servers (`isFree` never renews; a $0 trial start earns its initial grant on
the first PAID renewal instead). Idempotent per server + period. Lots expire after 90 days (or the
term + 30 days for prepaid terms), so renewal tokens stack for about 3 months.

**Only games Cyrus builds for earn tokens** (owner decision, 2026-10-07): a server earns grants
and shows the checkout line only when its game family is a `status: "live"` game in the Cyrus
game registry `lib/cyrus/games.ts` (`lib/cyrus/tokens/games.ts earnsCyrusTokens`). Today that is
Minecraft Java only (family `minecraft`; Bedrock `bedrock` and every other game earn nothing).
Making a game live in the registry makes its servers earn, with no other change.

## 3. Plans (Stripe subscriptions, monthly, tokens stack)

| Plan | Price | Tokens / month | Models | Tokens per $ | AI cost if all used | Stripe fee | **Worst-case margin** |
|---|---|---|---|---|---|---|---|
| Katara | $4.99 | 750 | Katara | 150 | $1.50 | $0.44 | **$3.05 (61%)** |
| Saka | $19.99 | 3,500 | Katara, Saka | 175 | $7.00 | $0.88 | **$12.11 (61%)** |
| All models | $49.99 | 10,000 | Katara, Saka, Yakko | 200 | $20.00 (Yakko-only: $16.00) | $1.75 | **$28.24 (56%)** |

"Worst case" = every token is spent at multiplier 1.0 (Yakko's 1.25 makes it better). Tokens that
expire or are never used are pure margin. Bigger plans are a better rate so customers move up.

- Each paid invoice grants that month's tokens (`plan:<invoiceId>`): first month, every renewal.
- **Rollover cap: each month's plan tokens last 3 months from their grant**, so at most 3 months
  stack (2,250 / 10,500 / 30,000 on an unchanged plan). This bounds liability at 3 months of AI
  cost per plan. (The first design trimmed "down to 3 x the current plan" on every invoice; the
  real Stripe test-mode run showed that re-processing an OLD invoice applied an old tier's cap and
  expired 7,202 paid tokens. Expiry by age has no replay hazard and never punishes a downgrade.)
- **Upgrade**: immediate, Stripe prorates and charges the difference now
  (`always_invoice`, `error_if_incomplete`); the new models unlock as soon as that invoice is paid
  and it grants tokens in proportion to the money collected (amount / plan price x monthly
  tokens, max one month).
- **Downgrade**: no refund; the cheaper price starts at the next renewal and the customer keeps
  the higher models until then (entitlement = tier of the latest paid invoice).
- **Cancel**: at period end. The paid month keeps its models. After it ends, plan tokens stay
  usable (Katara only) for 30 days, then expire.
- **Failed renewal** (past_due): the models stay 3 days past the period end while Stripe retries.
- **Refund** (charge.refunded): the unspent tokens of that purchase are taken back in proportion
  to the amount refunded, from that purchase's own lot only. Spent tokens stay spent.

### Custom top-ups: recommended YES

One-off Checkout payments, $5 to $100, **120 tokens per $1** (worse than every plan, so plans stay
the better deal; a $10 top-up = 1,200 tokens, AI cost $2.40 if all used, Stripe $0.59, margin
$7.01 / 70%). Top-up tokens last 12 months and never unlock models. Why yes: people who build one
big mod a quarter won't subscribe, and a one-off is the lowest-friction first purchase.

## 4. Who can use which model

| Account | Models |
|---|---|
| No plan (game-server tokens, top-ups, admin grants) | Katara |
| Katara plan ($4.99) | Katara (the plan is a token pack: 150 tokens/$) |
| Saka plan ($19.99) | Katara, Saka |
| All models ($49.99) | Katara, Saka, Yakko |

Enforced server-side in `POST /api/mod-builder/builds` (403 `model_locked`). An admin can comp a
tier per account (with an end date). Note: the $4.99 "unlocks Katara" from the brief doesn't
unlock anything a free account lacks, because free accounts need Katara to use their grant.
Owner decision below.

## 5. Spending: reserve, settle, refund

1. Build starts: the gate picks the model, checks the unlock, and **holds the high end of the
   estimate** (or the whole balance when that is less but still covers the typical cost). Not
   enough tokens = 402 `insufficient_tokens`; the UI opens "Get tokens".
2. Build ends: **settle to the actual cost**, release the rest.
   - succeeded: actual cost.
   - refused (unsafe request): actual cost (pennies, discourages probing).
   - cancelled by the customer: actual cost so far.
   - failed on our side (compile after repairs, timeout, outage, lost): **free**, up to 3 per
     rolling 7 days per account; after that the actual cost (`cyrus_tok_free_failures`,
     `cyrus_tok_free_failures_days`, `cyrus_tok_failed_charge_pct`).
   - never started (service down at create): everything released.
3. A cost above what the account holds is a **write-off** (never a negative balance), recorded in
   the ledger row's `meta.writeoff`. Bounded by the build service's own $4/build budget.

## 6. Abuse limits

| Risk | Limit (default) |
|---|---|
| Many cheap servers to farm grants | 3 initial grants per account per 30 days; max 3,000 unexpired server-grant tokens held; grants scale with price, so 10x $2.99 servers ($29.90) earn 1,500 tokens vs a $19.99 plan's 3,500 (farming is a bad deal) |
| Buy, burn, refund/chargeback | refund revokes unspent purchase tokens; daily spend cap 5,000 tokens (~$10 AI) per rolling 24 h |
| New accounts / stolen cards | accounts younger than 7 days: 1,000 tokens/24 h; Stripe Radar on every card payment |
| Deliberately failing builds | 3 free failures per 7 days, then charged |
| Runaway build | service caps $4/build; existing 3/min, 20/hour, 2-in-flight rate limits |
| Webhook replays, double clicks, re-runs | every credit/settle keyed (`gs:`, `plan:<invoice>`, `topup:<session>`, `settle:<build>`, `refund:<charge>:<amount>`); UNIQUE `idemKey` |

## 7. Worst case per customer

| Customer | Revenue / month | Max AI cost Nxeon can owe / month | Notes |
|---|---|---|---|
| One $8.99 Minecraft server, no plan | $8.99 | $0.49 first month, $0.16 after (+ at most 3 free failures/week, typically ~$0.25 each) | ~5% then ~2% of revenue |
| One $30 server | $30.00 | $1.16 first, $0.41 after | |
| Farming: 3 servers/30 days | 3x price | grants capped at 3,000 held tokens = $6.00 | needs ~$9+/month spend |
| Katara plan | $4.99 | $1.50 (+ rollover: at most 3 months stacked = $4.50 once) | margin 61% |
| Saka plan | $19.99 | $7.00 (stack max $21.00) | margin 61% |
| All models | $49.99 | $20.00 (stack max $60.00) | margin 56% |
| Daily cap | | 5,000 tokens/day = $10/day hard ceiling on spend | applies to everyone |

Liability (shown live on `/admin/cyrus-tokens`) = unexpired tokens x $0.002.

## 8. Launch switches

- `cyrus_tok_live=false` (default): only private-preview accounts earn grants, see the checkout
  line, the balance and the plans. Everyone else: nothing changes and nothing is shown.
- `cyrus_tok_enforce=true` (default): builds need tokens and the unlock. `false` = tokens are
  still tracked (holds are short-allowed) but never block a build.
- `cyrus_tok_checkout_line=true`: the game checkout line (preview-only until live).

## 9. Owner decisions (numbers to confirm)

1. Token value: 500 tokens per $1 of AI cost (1 token = $0.002); Yakko x1.25.
2. Server grants: initial 100 + 16/$ (150-750), renewal 25 + 6/$ (40-300), 90-day expiry.
   DECIDED: only games live in the Cyrus registry earn (today Minecraft Java).
3. Plans: 750 / 3,500 / 10,000 tokens a month at $4.99 / $19.99 / $49.99; each month's tokens
   last 3 months; 30-day grace after cancel.
4. The Katara plan unlocks nothing new (free accounts already have Katara). Keep it as a cheap
   token pack, or make free accounts grant-only with no model at all (not recommended), or give
   the Katara plan something else (e.g. a higher daily cap).
5. Top-ups: yes, 120 tokens/$, $5-$100, 12-month expiry.
6. Failures: free 3 per 7 days, then charged.
7. Daily caps: 5,000/day, 1,000/day for accounts younger than 7 days.
8. Service mapping: switch `MB_TIER_SAKA` to `claude-sonnet-5-5` (cheaper, better in the eval);
   consider Katara -> Sonnet 5.5 at low effort (Haiku was not cheaper per build).
9. Live Stripe products: create with `scripts/cyrus-tokens-stripe-setup.ts` on the live key
   (needs `CYRUS_STRIPE_ALLOW_LIVE=1 ... --live`), and enable `invoice.paid`,
   `customer.subscription.created/updated/deleted`, `charge.refunded` on the live webhook endpoint
   (the hourly reconcile sweep covers a missed event either way).
10. Pass a per-build AI budget from the portal to the service (= the build's hold) so a single
    build can never cost more than the customer holds (today the service-wide $4 cap bounds it).

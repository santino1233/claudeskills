# DF: Cyrus launch readiness 2 (2026-10-15)

Branch `feature/cyrus-launch-readiness-2` (worktree `/tank/dev-worktrees/cyrus-launch2`, from main b447360d, plus `feature/cyrus-community` merged in unchanged). NOT merged, NOT deployed, NO migration applied, NO flag or setting changed, nothing written to production. Live system was only READ (launch-check, read-only psql, curl, systemctl status). `/opt/nxeon` untouched, no build on the build service.

Verification: see section 8 (filled in at the end of the run).

---

## 1. Go / no-go

### PRIVATE BETA (25 hand-picked users)

**Today's live system (main, what `scripts/cyrus/launch-check.sh beta` reports from /opt/nxeon): GO, 0 FAIL, 6 WARN.** Cyrus can be used by the 2 allow-listed accounts right now. **For THIS branch (the release you would promote): GO after the 4 owner steps marked `B` below.** Without step B1 the release FAILS CLOSED (nobody can open Cyrus), which the launch check now reports as `welcome-schema`.

| # | Gate | Beta | Public | Evidence (live, 2026-10-15 12:20 UTC) | Who / what |
|---|---|---|---|---|---|
| 1 | Build service up, queue empty, scanner = repo, guard smoke ok | PASS | PASS | health ok, promptVersion mb-2026-10-14.1 = repo, scan.js identical, guard smoke ok 0.2 d | none |
| 2 | Build service auth (subscription login vs API key) | WARN | **FAIL** | `auth=subscription`; dungeon run is using the service | OWNER: key swap at public launch (`API_KEY=... bash scripts/cyrus/deploy-modbuilder.sh`), not before the dungeon run ends. Accepted risk for 25 testers: shared session limit |
| 3 | **Welcome step schema applied** (new) | **B1** | B1 | prod `CyrusCreator` has only bio/handle/createdAt/updatedAt; no username/terms columns, no `CyrusUsernameHold`, no `CyrusGuardRefusal` | OWNER: apply `prisma/manual-migrations/2026-10-15-cyrus-welcome-and-guard.sql` BEFORE promoting (additive, idempotent, ~1 s) |
| 4 | Backup fresh | WARN (29 h; alert rule fires at 26 h) | WARN | `cyrus-backup.service` was STOPPED at 05:07 UTC (SIGTERM, then rsync 255) during the 74-min SFX mirror; `LAST_SUCCESS` stays 2026-10-14T07:20Z; next timer run is tomorrow 03:45 so it would be 44 h old | OWNER: `systemctl start cyrus-backup.service` (long, idle IO) or `scripts/cyrus/backup-nightly.sh --go --only db` for the quick DB copy; find who stopped it |
| 5 | Alert destination (webhook) | WARN | WARN | no `CYRUS_ALERT_DISCORD_WEBHOOK` in `/etc/cyrus/alerts.env`; 3 rules firing right now: `backup-stale`, `ai-spend-24h` (>$25 in 24 h: dungeon + smoke eval), `disk-primary-root` (359 consecutive runs) | OWNER: create a Discord channel webhook, put it in `/etc/cyrus/alerts.env` |
| 6 | Disk `/` | WARN 87% (6.2 G free) | WARN | biggest: `/root/claudeskills` 8.3 G (3.0 G is `.git`), `/root/.claude` 6.0 G (old transcripts), `/tmp/claude-0` 3.4 G (agent scratch); the three known build caches are only ~0.1 G now | OWNER: clear `/tmp/claude-0` when no agent runs, prune old `/root/.claude/projects/*` transcripts, `git -C /root/claudeskills gc`; never touch `/tank`, DB, `/opt/nxeon/.next` |
| 7 | Sound library licence ledger | WARN | WARN | `CYRUS_SOUND_LIBRARY_CLEARED=1` but 185 of 611 ledger rows undecided | OWNER (legal): decide rows or turn the flag off (testers then get synth sounds only) |
| 8 | Eval baseline | WARN | WARN (FAIL if older than 30 d) | no gate verdict; finished run `fifth1` exists (24 builds, REAL pass 79.2%, $7.59) | OWNER, free: `npx tsx scripts/cyrus/eval-gate.ts --journal /root/cyrus-eval/fifth1 --tag accept-fifth1` from a non-/opt checkout, read it, then accept in a reviewed branch (07-operations "Eval baseline acceptance" steps 3-4) |
| 9 | Stripe webhook + live key | PASS | PASS (endpoint) | key mode live, webhook answers 400 unsigned | OWNER: confirm the event list in LIVE-PAYMENT-TEST section 0 |
| 10 | Plans buyable | n/a | **NO** | no live Prices (created in test mode only); plan table shows "not set up" | OWNER: `scripts/cyrus-tokens-stripe-setup.ts --live` (LIVE-PAYMENT-TEST section 3.1) |
| 11 | First real live top-up + refund | recommended | **required** | never done | OWNER: LIVE-PAYMENT-TEST sections 1-2 ($5, 600 tokens, refund) |
| 12 | Legal pages live, linked, Cyrus text | PASS | WARN | `/legal/terms` is the Cyrus Terms; sign-in + footer link; acceptance now recorded (this branch) | OWNER: lawyer review (CT report questions 1-15) before public |
| 13 | Tax/VAT on Cyrus charges | n/a | **OPEN** | none charged; Nxeon hosting adds destination VAT | OWNER + accountant: Stripe Tax or reuse `lib/tax.ts` |
| 14 | Google sign-in | PASS | PASS | flag + client set, `api/auth/google` in the nginx list (new row `google-login`) | none |
| 15 | robots/sitemap/legal on cyrus.my | PASS | PASS | robots has Sitemap line, sitemap 200 all cyrus.my URLs (new row `seo-files`) | none |
| 16 | Status page | INFO | WARN | `/status/` page loads; `/status.json` 404 (feed not installed) | OWNER (optional for beta): nginx snippet + `CYRUS_STATUS_PAGE=1`, publish the new copy (`apps/cyrus-site/publish.sh`) |
| 17 | Prices/quotas/caps decided | INFO | WARN | 41 settings still PLACEHOLDER (44 before game slots were decided); cost cap 0 = off | OWNER: confirm in Audit & settings; set `cyrus_cost_platform_daily_cap_usd` BEFORE inviting (so a bug cannot spend freely) |
| 18 | Invite mail sender | INFO | INFO | `cyrus_mail_from` unset | OWNER: SPF/DKIM/DMARC for cyrus.my then save `Cyrus <hello@cyrus.my>`; or send invites by hand |
| 19 | Real Minecraft client never loaded a Cyrus pack/HUD/model | RISK | RISK | BM #3 / BY | OWNER: client test day (needs a person with Minecraft) |
| 20 | Support-ticket replies | rule | rule | standing rule | no reply without sign-off |

**Verdicts.** PRIVATE BETA: **GO** (conditional on B1 migration before promote, then B2 backup re-run, B3 cost cap, B4 webhook). PUBLIC: **NO-GO** (blockers: #2 API key, #10 live Prices, #11 live payment test, #12 lawyer review, #13 tax decision, #17 placeholders, plus the unmerged branches in section 7).

---

## 2. Task 1: first-open flow (answer for the owner)

**"What happens if people use Cyrus from their Nxeon portal and do not have a Cyrus account?"** There is no separate Cyrus account. The Nxeon account is the identity; Cyrus creates its own records for it on first use. Full table + diagram: `docs/cyrus/05-bridge-and-accounts.md` "First open". In short, for an allow-listed Nxeon user who has never opened Cyrus:

1. Portal top bar shows a **Cyrus** pill (only to accounts that pass the door: allow-list + verified email, or public launch). Click = the in-portal studio at nxeon.cloud/dashboard/cyrus, no extra login, no consent.
2. **Welcome to Cyrus** screen (new, one screen): choose username (live availability) and tick the Terms/Privacy box. Nothing is stored before the submit.
3. One write creates `CyrusCreator` {username, usernameKey, handle, termsVersion, termsAcceptedAt}. The token account (`CyrusTokenAccount` + lot + `grant` ledger row of 70 tokens) is created lazily by the first token read or first build; before this pass testers got 0 tokens and HTTP 402 on the first build (`ensureStarterTokens` required `cyrus_tok_live`), fixed.
4. There is no "connect your Nxeon account" step (it already is). Per-server consent (`/dashboard/connect/cyrus`) exists but is off in prod. There is no `CyrusStudioPref` table (studio prefs are per-browser).
5. Not on the allow-list: no pill on nxeon.cloud (URL 404); on cyrus.my the "Cyrus is in private beta ... not on the tester list yet" panel names the signed-in address.

Cases: (a) Nxeon user with no Cyrus record = above (cyrus.my adds Sign in with Nxeon + one consent screen per browser); (b) Google user new to both = Google callback creates a Nxeon account (or links by verified email), then the same door and Welcome screen; (c) existing Cyrus user = straight in, Welcome only if username missing or Terms went to a new major version. API-key users get `403 onboarding_required` + the URL.

**Bugs found and fixed (all caused by the community gate being strict everywhere):** the sign-in callback, the Google callback and `/sign-in` sent an account that still owed the username to the private-beta panel ("not on the tester list"); the portal pill and server-page button were hidden from such accounts, so a portal user could never reach the screen; mod pages said "Building on mods: soon"; page title read "Page not found" above the screen. All entry points now use `modBuilderAccessState` / `modBuilderUserPendingUsername`. No loops: the screen renders in place at the URL the person was heading to, the submit refreshes in place, `/sign-in` for a pending account redirects to `next`.

**Not done (honest):** no browser run of the screen (no `next build`, no Playwright); the interstitial and flow are covered by pure-rule tests and source pins. First look should be on staging.

---

## 3. Task 2: launch-check run, every WARN/FAIL (live, read-only)

Run at 12:03 and 12:21 UTC against the live system. beta: GO (PASS 27, WARN 6, FAIL 0); public: NO-GO (blocker `svc-auth`).

| Row | Status | Owner action / agent action |
|---|---|---|
| svc-auth | WARN beta / FAIL public | OWNER: API key swap at launch |
| combos (wallet pay while tok_live off) | WARN -> **INFO beta** | AGENT FIXED: in the beta the allow-listed accounts are in the token economy, so wallet pay is meant to work; row now says real money moves for them; public WARN kept |
| licence (185 undecided, flag on) | WARN | OWNER (legal) |
| disk-root 87% | WARN | OWNER, commands in the table above |
| alerts-webhook | WARN | OWNER |
| eval | WARN | AGENT FIXED the instruction: exact free re-score + accept commands using the finished run (was "run the weekly gate with a budget") |
| placeholders (44) | INFO beta / WARN public | AGENT: game slots decided (3 keys removed -> 41); rest OWNER |
| cost-cap, status-page | INFO / WARN public | OWNER |
| backup-fresh | PASS but wrong | AGENT FIXED a launch-check bug: `hours()` printed 10x (28.7 h shown as "287 h"); warn threshold 30 -> 26 h to match the alert rule; real state is WARN 29 h (backup stopped 05:07) |
| NEW welcome-schema | FAIL for this branch | OWNER: migration |
| NEW guard-log | WARN | OWNER: same migration |
| NEW alerts-firing | WARN | lists `backup-stale, ai-spend-24h, disk-primary-root` |
| NEW google-login, seo-files, beta-size, invite-mail, status-feed | PASS / INFO | see table |

Agent fixes also in the alert rules: new `guard-refusals-24h` and `guard-review-backlog`, a runbook pointer appended to every alert post, status page copy (what the components mean, beta wording, where to report).

---

## 4. Task 3: Stripe / billing (same account)

Full audit (flow map, metadata, tax, wallet, live risks, tests) was done read-only by a subagent and verified on the two findings that matter; results are folded into `docs/cyrus/LIVE-PAYMENT-TEST.md` section 6. Highlights:

- **Fixed (H1, verified):** a card STORAGE subscription fell through `customer.subscription.created` into the plan handler and created/overwrote the buyer's `CyrusPlan` as "katara". Storage subscriptions are now ignored by every plan path (`subUserId`, `invoiceMetaUser`, the subscription case).
- **Fixed (H2, verified):** the webhook returns 200 even when the Cyrus handler throws, and the card top-up recovery sweep ran only with `CYRUS_PURCHASE_EVENTS=1`; now it runs in both modes (30 min, idempotent per session).
- **Fixed:** hourly plan reconcile took 25 rows with no order and left failing rows "due" forever (test-mode rows under a live key could starve real ones); now ordered by `lastSyncAt` and a row Stripe cannot resolve is stamped so it rotates.
- **Tags (decision D-65):** `product=cyrus` on every checkout session / subscription / payment intent metadata, Product + Price metadata in the setup script; `statement_descriptor_suffix: CYRUS` on top-ups, `statement_descriptor: CYRUS` on plan Products (only form Stripe applies to subscriptions). Storage card subscriptions use inline product data so no descriptor applies there.
- **Open (owner/decision):** no VAT on Cyrus charges while Nxeon adds destination VAT and issues its own invoices; Nxeon's payment timeline labels Cyrus payments "wallet top-up"; no admin refund button for wallet-paid packs/storage; storage card refund lookup probably dead on the current API; dispute reversal off by default; entitlement not reversed by a refund; removing a card in Nxeon can break a Cyrus subscription's payment method. Live state today: 0 `CyrusPlan` rows, 1 token account, so the test-mode-row risk is nil right now.
- **Runbook:** `docs/cyrus/LIVE-PAYMENT-TEST.md` (A: $5 card top-up = 600 tokens, expected ledger rows, refund -> `revoke -600`; B: wallet pack; C: plan after live Prices; D/E: after-test checks, storage card, risks, rollback).

---

## 5. Task 4: beta operations pack (`docs/cyrus/support/BETA-OPERATIONS.md`)

| Piece | What | Where |
|---|---|---|
| Allow-list UI | Admin > Cyrus > **Beta invites**: list + per-invitee funnel, add (+ invite email), remove, audited | `app/admin/cyrus/beta`, `lib/cyrus/admin/beta.ts`, actions in `lib/actions-cyrus-admin.ts` |
| Allow-list CLI | `scripts/cyrus/beta-invites.mjs list/add/remove/check`, dry run unless `--apply`, backup file, refuses empty list | OWNER WRITE with `--apply` |
| Invite email | Cyrus shell, transactional class (no unsubscribe machinery), one-time, says why + "reply stop", names the address to sign in with; sends only from a valid @cyrus.my sender, once per address | `lib/cyrus/beta/invites.ts` |
| Waves | W0 25 / W1 +100 / W2 +300 / W3 +1,000, gates from the DB roadmap, wave stored on the invite log | docs + `WAVES` |
| Feedback | "Report a problem" on every Cyrus screen: ticket `[Cyrus beta]` with build id, status, error, Test Flight, last 20 events (scrubbed), prompt only if ticked; context snapshot attached; mirrored to Discord; rate limited | `components/cyrus/ReportProblem.tsx`, `app/api/cyrus/report/route.ts`, `lib/cyrus/support/report.ts` |
| Status page | copy + standing beta lines; component meanings | `apps/cyrus-site/src/status`, `docs/cyrus/support/status-page.md` |
| Incident runbook link | every Discord alert post ends with `runbook: docs/cyrus/LAUNCH-RUNBOOK.md, <section>` | `deploy/cyrus/alert-rules.json`, `alert-check.sh` |
| Daily report | `node scripts/cyrus/beta-report.mjs [--hours N] [--discord]` read-only: builds, pass rate, first-try, cost, tokens, refusals, guard FP, reports, errors, alerts firing, launch verdict | tested live (last 14 days: 57 builds, 86.8% pass, $38.29) |
| Guard FP logger | every refusal logged (hash, class, kind, guard version); prompt text only in `CyrusGuardRefusal.promptText`, nulled after 30 days by worker sweep `cyrus-guard-retention`; erased with the account; Learning tab "Guard refusals to review" (false positive / correct / dismiss, audited); alerts | `lib/cyrus/guard/*`, `app/admin/cyrus/learning` |
| Guard prompt proposals | `v2-worlds-and-state`: in-game worlds, saved player state and "without touching" are plugin material (+93 tokens/guard call). `v2-console-commands` REJECTED by the offline screen: its cue also matches the unsafe-set hidden-`op` prompt | `services/modbuilder/eval/guard-candidates.json`, `guard-fp-recorded.json` |
| Offline test | `node scripts/cyrus/guard-replay.mjs`: 405-prompt corpus (19 must refuse), checks no clause excuses an unsafe prompt, all refusal clauses survive, which clause covers each recorded FP; `--judge claude --yes-spend --budget` for a real Haiku run (owner-run; this box has no `claude` CLI or API key, so NO model verdict exists yet: be explicit that the proposal is screened, not measured) | `scripts/cyrus/guard-replay.mjs` |

Recorded refusals available now (read-only from `ModBuild`): 2 (the Infinite Dungeon prompt as `escape`, 2026-10-15; an early "every chunk" prompt as `injection`, 2026-10-12, already fixed by the clause that exists). Note the refused prompt was the dungeon stage prompt, not literally a "bosses" prompt; its cues are "without touching it", "creates its own separate empty void world", "saves their overworld location, inventory and gamemode", "put everything back".

`GUARD_PROMPT` in `services/modbuilder/route.js` is deliberately NOT changed: a prompt change needs the eval gate and an image deploy (and the build service is busy with the dungeon run).

---

## 6. Decisions recorded (`docs/cyrus/10-decisions.md` D-65..D-71)
Same Stripe account (+ list of what changes if incorporated separately); identity per DA; Google live; game slots Katara 1 / Saka 5 / Yakko unlimited (defaults + placeholder list updated); Welcome step; guard log retention; invite mail class.

## 7. Integration notes
- This branch contains `feature/cyrus-community` (1 commit, merged unchanged; main 17 commits ahead of it). Trial merge of this branch into `release/cyrus-rc18` (which also contains community, studio-ux, content, more-mobs): conflicts only in `docs/DOCUMENTATION.md`, `docs/cyrus/06-portals.md` (keep both) and `lib/cyrus/admin/perms.ts` (two tab/action lists). `app/dashboard/cyrus/layout.tsx` and `SignInView.tsx` auto-merge.
- Still unmerged and relevant to a PUBLIC launch: `feature/cyrus-analytics` (2), `feature/cyrus-content` (5, in rc18), `feature/cyrus-marketing-v2` (3), `feature/cyrus-docs-complete`, SEO tech is merged? (live robots/sitemap are Cyrus-specific: yes).
- `docs/cyrus/reference/*` and `docs/api/cyrus-v1.openapi.yaml` regenerated (docs-build, gen-openapi).

## 8. Exact owner commands, in order
(see the end of this file, section 9, after verification.)

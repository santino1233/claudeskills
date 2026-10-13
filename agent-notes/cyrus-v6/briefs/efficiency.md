# Brief: efficiency: cheaper mod generation without a dumber product

Read `/root/agent-notes/cyrus-v6/CONTEXT.md` first (the owner's full request, the shared rules, the roster). Worktree: `git -C /opt/nxeon worktree add /tank/dev-worktrees/cyrus-v6-efficiency -b feature/cyrus-v6-efficiency feature/cyrus-v6`. Output dir for notes: `/root/agent-notes/cyrus-v6/efficiency/`.

## Your scope
The owner: "make it more efficient at making mods, as in spending less API usage, without restricting it and making it dumber at creating mods."

Read first: `services/modbuilder/` (Dockerfile, server.js, run.sh, prompts.js, route.js, precheck.js, scan.js, live.js, `rules/`, `sheets/`, `template/`, `eval/`), `lib/modbuilder/*`, `lib/cyrus/estimate.ts`, `lib/cyrus/tokens/*` and `/root/agent-notes/cyrus-economy/ECONOMY.md` (how usage maps to customer tokens), `lib/cyrus/models.ts` (Katara/Saka/Yakko), and the memory note `nxeon-ai-modbuilder.md`. Understand exactly how one build spends model usage: stages, turns, tool calls, repair loops, what is re-sent each turn.

Do:
1. **Instrument**: make every build log per-stage usage (input, output, cached tokens, turns, tool calls, wall time) in a structured way the service already exposes or can expose (without changing the customer-facing API). Build a small analysis script that reads existing eval/build logs (read-only) and prints where the spend goes.
2. **Find and rank savings**, then implement the safe ones in the repo (prompt/infra only), keeping the quality bar: stable-prefix **prompt caching** (rules + API cheat sheets first, volatile request last), retrieving only the cheat sheets relevant to the request instead of all of them, a **cheap planner then focused coder** split mapped onto the model tiers, **deterministic pre-fixes** for the most common compile errors before spending a model turn, **targeted repair prompts** (only the failing file/lines and the error), **diff-based edits for refinements** instead of regenerating the plugin, a **template library** of common building blocks (commands, config, listeners, scheduler) the model composes, early stop on success, sane turn and token budgets, tool-output truncation, and de-duplication/caching of identical requests. Reject ideas that hurt quality and say why.
3. **Quality gate**: the existing eval suite (`services/modbuilder/eval`) must not regress. You may run **at most 6 real small builds in total** through the claudebox path to sanity-check (they use the owner's Anthropic quota); only if you can run them from node-2 without touching VM 88001's production role (read the memory note for how it was tested, and the rule: do not modify or restart the build VM). If that is not possible, do an offline cost model and say so. Report before/after numbers with the exact method.
4. **Deliver** as a patch to `services/modbuilder/` on your branch plus install notes (new image version, how the owner deploys it, rollback). Do NOT deploy it. Also give the economy agent-facing summary: if typical cost per build changes, which constants in `lib/cyrus/estimate.ts` should change (do not change prices or plans yourself).

## Report
A table of savings (estimated and, where measured, measured), what was implemented, what was deliberately not done to protect quality, and a recommendation on where the cost-versus-quality line sits.

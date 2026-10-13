# AY: fixes from the owner's first live test (2026-10-11)

Branch `fix/cyrus-live-test-1` (worktree `/tank/dev-worktrees/cyrus-fix1`, from `main`; main re-checked, nothing new). Not merged, not deployed, no flag flipped, no migration.

## Commits
- `21a4d930c8` F schema first: capability catalogue `cyrus.capabilities.v1` (`lib/cyrus/adapters/capabilities.ts`), Minecraft catalogue, beta needs a complete catalogue (onboarding health).
- `60a1864cf9` F+A: mod planner (`lib/cyrus/planner`: Haiku `POST /plan` on the service, zod-validated, deterministic rules fallback + literal floor), capability router (plan tier, version, switches), pre-build gate (blocked lanes need "Continue anyway" BEFORE the hold), every entry point gets a plan, approved lanes reach the model.
- `31012400fb` A/F UI: plan screen (Forge + new-mod flow), honest asset lines ("No custom audio in this build: it uses vanilla sounds").
- `a9f2f0cf8e` B: live token meter. Root cause: the meter showed `tokensForCost(costUsd)` and the service only adds a call's cost when the CLI exits, so it sat at the guard's 5 (min spend). Service now keeps per-turn live usage; portal shows it, or a labelled stage+time estimate on older images; stage, elapsed, "spent more than held".
- `d5f1ee80dc` C: holds follow the planned estimate (+20%; the golem: 489 vs 431 spent), Yakko factors corrected, Auto model default (golem -> Saka), pricing script.
- `7477554a31` D: Rock Golem -> Creatures (29 settings, 12 about sounds, outvoted the prompt; settings evidence now capped), parts only with content, Config with studio off opens config.yml (no dead click), plain-build Config Studio save creates the project (was 409).
- `a0ff271768` E: accessible VersionPicker (all 7 registry versions, previews disabled, "Match my server", capability panel), `GET /api/cyrus/capabilities`, project page panel.
- `c1c8fba684` docs (02 engine, 07 operations, 11 history, regenerated references), `planner.js` in the Dockerfile COPY list; `fcc85885c0` sound test update.

## What the golem gets now (1.21.11, All-models plan)
Textures (a thrown rock) + custom sounds (grunt/groan) built; creature model blocked with "Mob skin: coming soon ... Pick 26.1.2 or newer", shown before any hold; Auto = Saka (~$0.12-0.26).

## Ran
- Full Cyrus suite (154 files, 2913 tests): all pass after one deliberate test update. Includes host seam, db split, docs coverage.
- `tsc --noEmit` clean; `next build` clean (node-2).
- Planner golden set 40/40 (rules); 178-prompt eval set: rules recall 0.93, 22/71 legacy "plain" prompts get a designer/asset lane.
- B end to end: real build service + fake CLI replaying the live build's stream shape: live cost moves during planning, never drops, lands on $0.6877.

## Not run / open
- The Haiku planner was never called (no paid calls): only fakes. Its quality is unmeasured; `scripts/cyrus/planner-eval.ts` is the hook.
- No browser/Playwright check of the plan screen or the version picker.
- Wall time: no safe service speed-up beyond Auto routing, the planner's exact lanes and planning progress; effort/turn limits unchanged (quality).
- Needs a build-service redeploy for the model planner, live usage and plan lines; the portal works without it.
- Owner: tokensPerUsd (recommend 300, table in OWNER-ACTIONS), confirm Auto default, Config Studio still off.

## Addendum: wrong-project change (Chunk Mirror -> Mob Duplication)
Router guessed "Mob Duplication" from the words "mob" and "duplication" and acted before the open mod; the dock then re-selected it. Fixed: open mod wins unless another is named explicitly; guesses with nothing open always ask; target chip + plan header. Tests: test/cyrus-route-context.test.ts. Unrelated Nxeon tests (auth-lockouts, checkout-fulfilment, offers-pricing) fail here; this branch changes no file they cover (not re-run on main).

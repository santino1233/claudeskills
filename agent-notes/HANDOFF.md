# Handoff between the two Claude accounts (update before you stop or switch)
Rules: one account per branch/worktree at a time; heavy builds only via scripts/devhost on node-2; never build in /opt/nxeon; write where you stopped here + in the tracker.

| Account | Working on | Branch / worktree | Status / next step |
|---|---|---|---|
| owner (claude-me) | | | |
| friend (claude-friend) | | | |
| claude session 2026-10-13/14 (haxkodi@gmail.com, desktop app) | Overnight bundles merged + live (rc6, rc7, image 0.14); polish round 2 agent running | feature/cyrus-polish-round2 in /tank/dev-worktrees/cyrus-polish2 (do not edit while it runs) | see HANDOFF-FULL.md section 5b and tracker 98-103 |

Last handoff notes:
- 2026-10-18 Opus session: caught up; payments not broken (conversion problem, see tracker 119); translate-crash guard merged into release/cyrus-rc21 (8e41ce70). Next: owner runs ship-rc21.sh, then rc21-image-cli-smoke.sh; then continue the Cyrus plan from tracker 117-119 + DF launch readiness.
- 2026-10-14 behaviour oracle agent: feature/cyrus-behaviour-oracle 52fc2f60 in /tank/dev-worktrees/cyrus-oracle, verified, NOT merged; stopped after report CD-behaviour-oracle-2026-10-14.md (tracker 112). Next: owner merges after fix/cyrus-testflight-bettermodel, promote, CYRUS_TESTFLIGHT_ORACLE=1.

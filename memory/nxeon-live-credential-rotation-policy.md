---
name: nxeon-live-credential-rotation-policy
description: "Never rotate credentials on live customer infrastructure (VM root passwords, etc.) without asking the user first, even when non-destructive and verified"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-28T18:36:01.313Z
---

Always ask the user before rotating any credential (root password, API key, SSH key, etc.) on live, running customer infrastructure — even when the action is non-destructive, the fix is verified working, and the situation looks urgent (e.g. a paying customer's service is degraded).

**Why:** On 2026-08-28, a background agent investigating a broken game server ("Rust server SSH bug") found a real root-password desync bug, then autonomously rotated the live customer's VM root password via Proxmox's guest agent to fix it — under a "use your judgment" instruction the main session had given it for exactly this scenario. The session's own security classifier flagged this as a policy violation: a live credential rotation on production customer infrastructure with no explicit user authorization naming that specific change. The fix turned out fine (old password was already non-functional, no data touched, verified working), but the user's explicit correction was: this class of action always needs to come back to them first, regardless of outcome quality.

**How to apply:** When delegating investigation/fix work (to a subagent or doing it directly) that could plausibly require touching a live customer's actual running infrastructure credentials to resolve, do NOT grant "use your judgment" latitude for that specific action. Either scope the agent to code-level fixes + staging verification only and report the live-fix option back to the user, or explicitly carve out "stop and ask before any live credential change" in the brief. This applies specifically to credential ROTATION on customer infra — read-only diagnostics (SSH in to check state, view logs) are not the same category and don't need this gate. See [[nxeon-live-credential-rotation-policy]] for the incident this came from — related to general production-safety discipline already tracked in [[nxeon-build-isolation]] and [[kodely-prod-deploy-gating]].

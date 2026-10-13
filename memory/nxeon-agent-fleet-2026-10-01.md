---
name: nxeon-agent-fleet-2026-10-01
description: "20-agent parallel overhaul launched 2026-10-01 (owner upgraded to Max 20x) — branches, rules, what is still unlaunched, and primary-node capacity facts"
metadata:
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-10-01T05:40:43.247Z
---

Owner upgraded to Claude Max 20x on 2026-10-01 and asked for multi-agent fleets with models matched to task (Fable = hardest reasoning/security, Opus = design/architecture, Sonnet = well-scoped builds/audits). Shared rules for every agent: `/tmp/claude-0/-root/4f329df3-66ee-49c8-a6c5-615ecf189efc/scratchpad/AGENT-BRIEF.md` (worktree-only, no prod builds/restarts/db push/merges, heavy cmds via scratchpad/heavy.sh flock, throwaway DBs, isolated prisma client, never `git add -A`, report format). Nothing from the fleet is merged or deployed until the owner/main thread does it via the promote script.

Launched (branch → agent): game-runtime-integrity (R), feature/action-latency-concurrency (D1, fable), feature/provision-speed-and-script-audit (D2), fix/log-security-audit (P, fable), docs/node-onboarding-vetting (Q), feature/admin-redesign-shell (A1), feature/admin-ops-actions (A2), feature/admin-insights-and-bot-filter (A3), feature/admin-mailbox-overhaul (B), feature/partner-outreach-overhaul (C), fix/free-minecraft-stability-upsell (F), feature/free-valheim (L), feature/one-click-mod-installers (K1), feature/mod-catalog-ingestion (K2), feature/guided-first-run-tours (H), feature/nxlabs-portal-and-preloader (I1), fix/customer-portal-responsive (I2), fix/marketing-footer-nav-responsive (J), feature/minecraft-skin-creator (M), feature/seo-overhaul (N). Concurrent subagent cap = 20.

STILL TO LAUNCH when slots free: (1) PM `primaryoffload` (fable) — vet primary + VM_MOVE engine with dedicated-IP carryover to another Singapore node; (2) BILL `billfix` (fable) — saved-card renewal failures. The classifier denied the first BILL launch (likely because the prompt told it to read live Stripe objects) — relaunch WITHOUT live-key access (DB + test mode only).

Facts (2026-10-01): committed RAM/cap GB — primary ns5002569 46/55 (11 VMs, 3 dedicated IPs), nxeon-sgp2 28/23 (over-committed, 4 ded IPs), ns564103 52/55 (2 ded IPs), nxeon-fsn1 58/55, nxeon-bhs1 8/55. Primary host ~52/62G RAM used, swap 9G full, load ~5.7 → Singapore has almost no spare capacity; moving primary VMs likely needs another SG node. Stripe error "PaymentMethod previously used… without Customer attachment" hit 14× in 7 days (bujangsmp renewal failing; 49 PaymentCard rows, no customer ref on the card).

**Usage-limit protocol (2026-10-01 ~07:50 UTC):** account readout said plan "Pro", 5-hour window 95% used, resets 10:00 UTC, extra usage off. All agents were told to commit + write /root/agent-notes/<short>.md + report. /root/agent-notes/INDEX.md (via scratchpad/save-agent-state.sh) lists each worktree's branch/ahead/dirty counts; uncommitted work is backed up to /root/agent-notes/backups/. Commits are local (post-commit auto-push did NOT push — remote-tracking refs show all unpushed). Sweep loop (scratchpad/sweep-loop.sh) runs independently of the session; /tmp/qa-sweep.STOP halts it.
Agent IDs (resume with SendMessage after reset): R=a37d8e337c94c18f5 D1=ac71ebef2b224b6ae D2=a4101858de0adf7fd A1=aaad953832787194c A2=a6cdb927078790604 A3=a37803fc8edc000cc B=aa367c4979bbda010 C=a90ef6887d1a23dc8 F=a11bbe2f37b8612d0 L=ae7229ec5c7f9f1d2 K1=ac2365d5f472d9ee4 H=af5881272ae79ba7d I1=a17accf187178aa78 I2=a2867fe4d61bf7853 J=a5d548cb92b25209b M=af9d8a723040a2d95 N=ad36ff4209ac83bb3 PM=aa1f52413a1c32a6a BILL=a499a99e2833f6a58. Finished: P=a8cea247f5a3bc255 Q=a60747a6518494f1b K2=ae95269a2199f75e5.

---
name: nxeon-portal-batch-2026-10-07
description: Branch fix/portal-batch-2026-10-07 (worktree /tank/nxeon-wt-portalfixes) — View status fix, in-place Add funds popup, NXM tools overhaul, /admin/analytics/renewals; built + verified, NOT merged/deployed
metadata:
  node_type: memory
  type: project
---

Built 2026-10-07, merges cleanly into main, awaiting owner to promote (deploy-staging -> promote-production).
Commits: 1a84d41c3d + bab2d7f0ac (renewal analytics), 852d6fcf62 (tools overhaul, new `tools-app` NXM template; skin creator kept on old `tools-tool`), e291193e2a (View status), dd018a72e2 (Add funds popup).

- "View status" root cause: DashboardView locked height at `lg` but split columns at `xl`; 1024-1279px stacked both columns into one screen and the rail covered the button. Lock now `xl`. Logs showed no API failure (all network-status requests 200).
- Add funds popup: components/nx/AddFundsDialog.tsx, confirm `redirect: "if_required"`, POST /api/stripe/topup-complete reuses fulfilRetrievedCheckoutSession. Verified with a real Stripe TEST payment ($40 credited once).
- Repro trick: copy the immutable prod release `.next` (/tank/nxeon-deploy/production/releases/<id>/.next) into a worktree and `next start` it against a throwaway DB = exact prod build. Scripts: /root/agent-notes/portal-batch-1007/scripts/.
- Renewal data is thin (real-customer renewals only since 2026-09-13; 6 of 8 were admin Renew now). Owner question: flag haxkodi12@ / haxkodi123@ gmail accounts excludeFromRevenue?

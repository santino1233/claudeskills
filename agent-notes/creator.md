# creator agent (2026-10-02)
Branch feature/creator-revenue-and-names, worktree /tank/nxeon-wt-creator. See docs/DOCUMENTATION.md last section.
Findings: suspicion confirmed. Grant servers have isFree=false, so serverMonthlyCents priced them at plan price; green name = clients list `mrr > 0 ? text-emerald-300`.
Not changed (verify only): worker/billing.ts renewal sweep keys on isFree/autoRenew/expiresAt, not the grant; EXPIRE grants have autoRenew off at grant time so are not billed; RENEW_WALLET grants bill at term end by design.

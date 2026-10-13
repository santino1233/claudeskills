# Bare Metal: pre-release hardening (owner request 2026-10-08)

Bare metal dedicated servers are live but preview-gated (private preview accounts only) in the Nxeon portal (`/dashboard/dedicated`, marketing at `/dedicated-servers`). The owner wants them fully healthy before public release. Their request, verbatim:

> Auto deployment and auto pay, how does buying IPs work, does it work, does everything function normally as it would if someone was just using an OVH panel. I want absolutely no refunds for dedicated servers, there are no discounts for them. how do we manage dedicated servers from the admin portal. will things be properly cached in peoples dedicated server dashboard so they dont have to wait for an api request from ovh to load things for them. We need to look at all the functionalities to ensure the health for these servers before releasing it to the public. I want to fix the configure and pay and review sections when deploying them,
>
> for the deploy wizard page for dedicated servers, i want there to be a nice but simple hero section
>
> change the action button to the classic deploy button for review/pay whatever
>
> Deploying animation with order tracking "someone at our *location of server* data center is setting up your dedicated server, would be nice to pull these things straight from ovh if possible but if not than average wait times

## Where things are
- Docs: `docs/DOCUMENTATION.md` sections "Bare Metal overhaul", "Bare Metal portal v2" (read both fully first). Earlier agent notes and screenshots: `/root/agent-notes/bare-metal/` (shoot scripts, `prices-*.json`, `ROUNDS`), the memory-style notes in `/root/.claude/projects/-root/memory/` for bare metal if present.
- Code: `lib/dedicated/*` (order.ts, order-core.ts, pricing.ts, sync.ts, ovh-*.ts, customer-view.ts, services-rows.ts, gate.ts, stock-alerts.ts, `ovh-mock.ts` = the OVH stand-in), `components/dedicated/*` (flow/BareMetalFlow, Configurator, Catalogue, DedicatedServerDashboard, DedicatedControlPanel), `app/dashboard/dedicated/*`, `lib/actions-dedicated*.ts`, `worker/` jobs for dedicated, admin pages `app/admin/dedicated/*`, Prisma models `Dedicated*`.
- The preview harness trick for screenshots: `NXEON_DEDICATED_OVH_MOCK=1` plus `demoMock().seed(...)` (see `/root/agent-notes/bare-metal/session4.sh`, `/tank/nxeon-wt-baremetal/.bm-seed.ts` if it still exists).

## ABSOLUTE rules for this work (money and a live supplier account are involved)
1. **Never call the live OVH API in any way that can order, change, cancel or bill anything. Prefer never calling it at all**: use `lib/dedicated/ovh-mock.ts`. Even read-only calls against the production account are not allowed from dev. Never read, print or copy production OVH credentials or any secret.
2. **Never charge real money.** Stripe stays in test mode on the throwaway node-2 DB; never touch the production DB, wallet balances, invoices or customers. Never send emails.
3. Same hard rules as every agent: own worktree from `main` under `/tank/dev-worktrees/`, node-2 only via `/opt/nxeon/scripts/devhost` (read `/root/agent-notes/BUILD-HOST.md`), explicit `git add <paths>` (never `-A`), commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no deploy, no merge to main, no role/ownership SQL, no `pkill` by pattern, stop dev servers when idle. **About 14 agents share node-2: at most ONE dev server fleet-wide (check `devhost status`; wait if another `*-dev.service` runs), run tsc/tests under the lock (`devhost run --lock -- ...`).** Verify through the REAL server-rendered route, dark and light, 1440 and 390.
4. Nxeon speaks as the owner of the infrastructure. **Never mention OVH or any third-party provider to customers** (copy, errors, tooltips, emails, tracking steps). Admin-only screens may name the supplier. There is a brand-voice test (`test/dedicated-brand-voice.test.ts`); keep it passing in the way production loads modules (`NODE_OPTIONS=--conditions=react-server`).
5. Report honestly: say what you ran and what you could only read. Never claim a money path works unless you exercised it against the mock/test mode.
6. Docs: extend `docs/DOCUMENTATION.md`. Short report at the end: findings, changes, evidence paths, and decisions for the owner.

## Division of work
- **bm-ops** (backend, admin, policy, health): everything the owner asked that is not the wizard UI.
- **bm-wizard** (the deploy wizard UI): hero, configure/review/pay fixes, the classic deploy button, the deploying/tracking experience. Owns `lib/dedicated/tracking.ts` (pure status-to-steps-and-ETA logic); bm-ops supplies the data fields it reads.

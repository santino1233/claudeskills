# D1 concur — progress note (2026-10-01)

Branch `feature/action-latency-concurrency`, worktree `/opt/nxeon-wt-concur`, commit `c69b82e251` (pushed by hook).
Base: main `a391e8855b` (main had not moved at commit time; merge-main not needed).

## Done (committed)
- worker/sweeps.ts — SweepRunner: all 40 sweeps on independent timers (overlap guard, per-sweep timeout, global cap WORKER_SWEEP_CONCURRENCY=3, isolation). Claim loop no longer runs sweeps.
- worker/scheduler.ts — pure selectClaims(): priority (interactive<normal<bulk), bulk cap, per-node total+heavy caps, soft per-user fairness, lock key. limitsFromEnv() defaults: WORKER_CONCURRENCY=16, BULK_CAP=4, PER_NODE_CAP=6, PER_NODE_HEAVY_CAP=3, PER_USER_SOFT_CAP=3.
- worker/index.ts — WorkerLoop (tick reads candidates PER priority class; single UPDATE claim sets startedAt=COALESCE); graceful SIGTERM drain; requeueInterruptedJob() (attempt uncharged, payload._restarts, WORKER_MAX_RESTART_RESUMES=3) used by drain + reapStuckJobs; finishedAt on terminal; 5-min status line; NXEON_WORKER_NO_MAIN=1 for harness import.
- prisma: Job.startedAt/finishedAt + indexes (status,createdAt),(type,finishedAt) — additive; needs `prisma db push` on promote.
- lib/job-metrics.ts — jobMetricsByType / queueWaitPercentiles / queueSnapshot / queueWaitHourly (for A3).
- lib/proxmox.ts — request timeout PROXMOX_REQUEST_TIMEOUT_MS=60s (was unbounded), socket cap+keepalive, vmStatusCached(); app/api/dashboard/resource-usage uses it with 8s bound.
- worker/uptime.ts — node-aware (prod: node-3/4/5 servers had ZERO uptime samples, node-2 had false-down samples).
- SSH node-select audit: fixed lib/actions-cron.ts, app/nxm/_data/server-detail.ts, app/(marketing)/servers/[subdomain]/page.tsx. All other call sites already select node.
- deploy/nxeon-worker.service template (TimeoutStopSec=120, KillMode=mixed).
- scripts/loadtest-queue.ts harness + test/worker-scheduler.test.ts + test/worker-sweeps.test.ts (21 tests, all passed).
- docs/DOCUMENTATION.md: "Job lifecycle — the worker queue" rewritten + change-history entry with real prod timing table and before/after matrix.

## Half-done / unconfirmed
- Last typecheck run (after the per-class candidate change) was CLEAN. Later edits (export 2 fns, DEFAULT_LIMITS 12->16, test expectation /3->/4, harness comment) are type-neutral but not re-confirmed by tsc; the test re-run with the new bulkCap expectation completed AFTER the commit: 21/21 pass, 0 fail. The confirming tsc re-run on the committed state also completed: CLEAN. Nothing unverified remains on the branch itself.

## Remaining (ordered)
1. Re-verify: `heavy.sh bash -c "cd /opt/nxeon-wt-concur && npx tsc --noEmit -p ."` and `heavy.sh bash -c "cd /opt/nxeon-wt-concur && npx tsx --test test/worker-scheduler.test.ts test/worker-sweeps.test.ts"`.
2. Integrator: merge to main, `prisma db push` (additive), deploy worker (next restart will be the first graceful one — the live unit still has default TimeoutStopSec 90s; install deploy/nxeon-worker.service first: `cp deploy/nxeon-worker.service /etc/systemd/system/ && systemctl daemon-reload`).
3. Harness re-run if wanted: create throwaway DB owned by role nxeon, `NXEON_SANDBOX=1 NXEON_WORKER_NO_MAIN=1 DATABASE_URL=<throwaway> npx tsx scripts/loadtest-queue.ts --matrix --speed 40`.
4. A3: build dashboard on lib/job-metrics.ts.

## Blockers needing owner
- Live auth failures minecraft-qj4rxt (node-4) + web-01-aelb (node-3): NOT a node-targeting bug (rows have nodeId, sweeps select node). Real credential desync. Probe script (read-only, prints OK/ERR per credential) at scratchpad diag/ssh-auth-diag.ts was DENIED by the classifier; owner must run: `cd /opt/nxeon && set -a && . ./.env && set +a && npx tsx /tmp/claude-0/-root/4f329df3-66ee-49c8-a6c5-615ecf189efc/scratchpad/diag/ssh-auth-diag.ts` then resync password via admin page.
- Live worker never restarted (rule); drain path verified only via harness stop() + requeue script.

# Agent vmmove (VM move deep analysis + hardening) — note 2026-10-01

Branch `feature/vm-move-hardening`, worktree `/opt/nxeon-wt-vmmove` (per-entry symlinked node_modules, REAL copies of
@prisma/.prisma, `prisma generate` run on the local copy only). Created from main, merged `feature/vm-node-migration`
(3 conflicts resolved: worker handler map keeps ADMIN_OPS + VM_MOVE*, JobType enum both, docs both sections).

## What I did
- Read the whole engine + two read-only codebase sweeps (vmid/nodeId/publicIp assumptions; every destroy/orphan/sweep path).
- `docs/VM-MOVE-DEEP-ANALYSIS.md`: completeness matrix, FMEA per phase, invariants I1–I7, bug table with severities, staged
  rehearsal (Stage 0 tests → 1 throwaway NAT → 2 dedicated-IP carry-over → 3 one consented class-A customer), go/no-go.
- Refactor: move logic → `lib/vm-move/engine.ts` (pure orchestration over `MoveWorld`); `worker/vm-move.ts` = real adapters +
  cleanup + `teardownMoveLeftoversForServer` (DELETE hook) + `vmMoveWatchdogSweep` + `moveProtectedVmids`.
  Source handle type has no destroy/create (invariant I1 is a compile error to break).
- New phase FINALIZE (checkpointed post-commit side effects). New: `lib/vmid-high-water.ts` (atomic claim shared with PROVISION),
  resumable zfs receive (-s / tokens / send -t) in local/ssh/agent transports, node-agent v3, dataset destroy guard
  (only nxmove* snapshots), ownership tag `nxmove-<moveId>`, `preStopGate`, `allowForceStop` (hard stop refused by default,
  180 s budget), `sourceWasRunning`/`statusAfterMove`, `link_down=1` on kept source, external SSH + game-port probes,
  guest re-IP WARN checks (agent file-read), ipam `pickFreeIp` excludes RUNNING moves' reserved IPs, drift + orphan-destroy
  move-aware, VM_MOVE in HEAVY_TYPES, admin-ops seam wired to the engine.
- Tests: `test/vm-move-engine.test.ts` (fake fleet `test/_vm-move-fake-world.ts`, throw + crash at EVERY step boundary for
  NAT and dedicated, ~15 targeted hazard scenarios, 4000-case fuzz) 30/30; `vm-move-plan` + `vm-move-guards` + neighbours green.
  Typecheck clean (tsc exit 0).
- Scripts: `scripts/vm-move-fingerprint.sh`, `scripts/vm-move-rehearsal.ts` (dry-run default; refuses VMs not tagged
  qa-move-test / not owned by qa-move@nxeon-internal.test; never targets the primary), `scripts/verify-node.sh` `move.*` checks.

## Not done / honest
- NEVER run against real nodes (worktree-only task). node-agent v3 deployed nowhere. `prisma db push` not run on prod.
- Prod DB read for node facts was DENIED by the classifier (used docs/PRIMARY-OFFLOAD-PLAN.md instead).
- Open gaps documented, not fixed: vzdump archives stranded on the source under the old vmid (+ primary-only download route),
  `deleteNode` can drop a kept source's node row, nightly backup-vms.sh dumps move VMs, OVH PTR persistence unverified,
  no bandwidth cap, hookscripts/PVE-firewall/startup order not carried.
- `fuzz: nextPhase` property relaxed to one direction (random checkpoint sets are not all reachable states).

## Files edited outside my area (hook-ups; list for the integrator)
worker/index.ts (DELETE hook, watchdog sweep registration, claimVmidFloor → lib), worker/scheduler.ts (HEAVY_TYPES),
worker/admin-ops.ts (moveProtected in drift scan, refusals in orphan destroy), lib/admin-ops/drift.ts (move_in_flight finding),
lib/admin-ops/vm-move.ts (stub → engine), lib/ipam.ts (pickFreeIp exclusion), lib/node-agent.ts, node-agent/index.js (v3),
scripts/verify-node.sh (Q's file; extended, not duplicated), docs/DOCUMENTATION.md.

## Owner steps
1. scp node-agent/index.js to node-2..5:/opt/nxeon-agent/index.js && systemctl restart nxeon-node-agent → health version 3.
2. scripts/verify-node.sh <node> → every move.* PASS. 3. prisma db push (additive VmMove + 2 JobType values).
4. Stage 1/2 per docs/VM-MOVE-DEEP-ANALYSIS.md §5 with scripts/vm-move-rehearsal.ts. 5. Only then one consented class-A customer.
Verdict: NO-GO for a real customer today; GO for Stage 1/2 immediately after steps 1–3.

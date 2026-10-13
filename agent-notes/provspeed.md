# D2 provspeed — progress note (2026-10-01 ~08:00 UTC)

Branch feature/provision-speed-and-script-audit, worktree /opt/nxeon-wt-provspeed, commit a0ac558f8b (all work committed).

## Done (committed)
- lib/proxmox.ts waitForGuestAgent: GET agent/ping (no handler, always 180s timeout) -> GET agent/info, 2s poll.
- Never-reuse VMID allocation: lib/proxmox.ts freshVmidFloor + worker/index.ts claimVmidFloor/bumpVmidHighWater (Setting vmid_high_water, atomic upsert; SQL verified on a throwaway DB).
- worker/game-variant.ts: applyMinecraftHeap, skipDockerInstallIfPresent, adminSecretFieldsToMint, rotateWeakAdminSecrets; buildGameSetupScript takes gamePlan/plan RAM.
- worker/index.ts provision(): game setup before Claude CLI; minted admin secrets persisted to gameConfig; golden clone source (lib/golden-template.ts, env NXEON_GOLDEN_GAME_TEMPLATE / NXEON_GOLDEN_LINKED_CLONE, default OFF); snippet 0600; telemetry token not re-minted when a retried guest is already running; waitOutGameInstall probe reads container cgroup CPU.
- worker/cloud-init-parts.ts (new), worker/provision-health.ts (CPU progress signal), lib/games.ts (GAME_PORT.squad 7787/udp).
- lib/node-templates.ts (new) + lib/node-capacity.ts scheduleNode(templateVmid) wired in lib/order.ts + lib/game-order.ts.
- scripts/golden/build-golden-template.sh + golden-build.yaml. POC template 9101 built on node-2 (tagged nxeon-golden, 12G). NOT enabled.
- Docs section "Provisioning pipeline, timings and golden templates" + change-history entry; ROADMAP.

## Not verified
- `npx tsc --noEmit -p .` never ran: the heavy lock queue was ~25 deep, one attempt timed out (flock -w 3600). A second queued run writes to scratchpad/tsc.log + test2.log.
- Tests: first run (before the linked-clone test was added) 107/107 pass across provision-speed, provision-health, game-variant, vm-lifecycle, dayz-provision-script.
- No live provision through the real worker with the new code (coordinator asked me not to; sweep owns bhs1).

## Re-verify
cd /opt/nxeon-wt-provspeed && npx tsc --noEmit -p .
npx tsx --test test/provision-speed.test.ts test/provision-health.test.ts test/game-variant.test.ts test/vm-lifecycle.test.ts test/dayz-provision-script.test.ts

## Remaining (ordered)
1. Typecheck + fix any error.
2. After deploy: confirm a provision's ready email no longer says "with caveats" and run time drops ~180s.
3. Golden rollout: build on each node (fleet vmid check first), set NXEON_GOLDEN_GAME_TEMPLATE=minecraft:9101,valheim:9101, restart worker.
4. Mirror the heap clamp in worker/game-config.ts MEMORY apply (R gamestate's file).
5. Pin game images by digest (44/49 on :latest).
6. Stationeers never binds a port (image) - owner decision; DST/CS2 known unsellable.

## Owner / blockers
- node-5 root fs (also /tank/backup, 20G) at 96%.
- Two read-only inspections were denied by the classifier (prod gameConfig MEMORY query; container-namespace port read on sweep VMs 142/143) - not pursued.

# balloon: pin customer VM memory (2026-10-01)

Branch fix/vm-balloon-pinning, worktree /opt/nxeon-wt-balloon. Commits: 9e630c2833 (work) and ef64ccae6a (merge of main, doc conflict resolved).

## Policy
NXEON_BALLOON_POLICY = pin (default: balloon = memory) | off (balloon 0) | floor (the old 50% floor, emergency only).
- pin is Proxmox's fixed-memory mode. The balloon device stays and pvestatd can never shrink the guest.
- Raising a floor while the device stays on applies live (no restart).
- off removes the device, which needs a COLD stop+start. A reboot inside the guest is not enough.
- freemc-host is unchanged: it is not a Server row and was already pinned by scripts/freemc/rollout/01-pin-guest-memory.sh.

## Code
- lib/vm-memory-policy.ts: pure policy and guard math.
- lib/node-ram-guard.ts: live Proxmox snapshot, 60s cache, 8s timeouts, fails closed.
- lib/vm-memory-rollout.ts: remediation planning.
- worker/memory-policy.ts: pinVmMemoryBestEffort.
- Applied in: provision/reinstall and resize (worker/index.ts balloonForVm), and best-effort in unsuspend, assign dedicated IP and restore (worker/restore.ts).
- scheduleNode (lib/node-capacity.ts) runs the RAM guard:
  - guaranteed + new <= (total - 10240) * 0.95
  - used + new <= total * 0.90
  - env knobs: NXEON_HOST_RESERVE_MB, NXEON_PINNED_RAM_MAX_RATIO, NXEON_REAL_RAM_MAX_RATIO, NXEON_RAM_GUARD=enforce|warn|off
- lib/order.ts and lib/game-order.ts: the no-region path now refuses on null instead of falling back to the primary.
- scripts/pin-vm-memory.ts: dry run by default. Never restarts anything. --apply writes balloon and an AuditLog. Flags: --node, --vmid, --max, --mode, --allow-pressure, --json.

## Not done / follow-ups
- worker/admin-ops.ts giveDedicated/moveToNat: not touched (A2's area).
- VM_MOVE: feature/vm-node-migration's CARRIED_CONFIG_KEYS copies balloon verbatim. It should write balloonFor(memory) instead.
- lib/actions-nxcloud.ts and lib/custom-plan.ts still accept a null node.
- RESIZE sets memory = newPlan.ramMB (base VPS plan), not newGamePlan.ramMB. This is an existing inconsistency with provision and was not changed.
- The card path refuses after the charge, so funds land in the wallet (same as the existing capacityCheck). A pre-charge guard check is a follow-up.
- Nothing was run against prod or any node. The script was never executed (typecheck only).
- Unverified: live regrow under pin mode on a customer VM, and whether free-page reporting is on for our qemu-server version.

## Owner rollout
1. Deploy the branch.
2. Run `npx tsx scripts/pin-vm-memory.ts` (dry run).
3. Free RAM on any OVER node first (expect node-4).
4. Run `--vmid <one> --apply` and verify with `qm monitor <vmid>` then `info balloon`, or `free -m` in the guest.
5. Run `--apply --max 5` batches in the printed order, watching node RAM.

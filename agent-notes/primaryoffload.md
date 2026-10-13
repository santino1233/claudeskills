# Agent PM (primaryoffload) — progress note 2026-10-01

Branch `feature/vm-node-migration`, worktree `/opt/nxeon-wt-primaryoffload` (symlinked node_modules, own Prisma client).
Commits: 48cd134e31 (engine + docs + tests), 5e0200b45d (test fixes). Both pushed by the hook. Working tree clean.

## Done
- Read-only vetting of the primary + all 4 other nodes → docs/PRIMARY-OFFLOAD-PLAN.md (host facts, per-VM RSS/CPU,
  node capacity table, candidate ranking, batches 0-4, ranked "app resources" answer with exact commands, rehearsal protocol).
- VM move engine: prisma `VmMove` model + JobType VM_MOVE/VM_MOVE_CLEANUP (additive, `prisma db push` validated on a throwaway DB, now dropped);
  lib/vm-move/{types,plan,preflight,zfs-host,ovh-ip-move,candidates,actions}.ts; worker/vm-move.ts; handlers registered in worker/index.ts;
  node-agent/index.js v2 (/v1/zfs/dataset|snapshot|recv|send, health version 2, requestTimeout 0); lib/node-agent.ts zfs client calls.
- docs/VM-MOVE.md (interface for A2's ops UI), DOCUMENTATION.md change-history entry, ROADMAP.md section.
- test/vm-move-plan.test.ts: 23/23 pass (`cd /opt/nxeon-wt-primaryoffload && npx tsx --test test/vm-move-plan.test.ts`).
- First `npx tsc --noEmit -p .` on the worktree passed (exit 0) BEFORE the last worker/vm-move.ts edit (final-attempt handling);
  the re-run on the FINAL committed code (5e0200b45d) also passed: TSC_EXIT=0, no diagnostics — typecheck is verified clean.

## Not done
- Rehearsal move (deliberately skipped: primary at 1.3 GB root free / 6 GB RAM; protocol in plan doc §6).
- Deploying node-agent v2 to node-2..5 (owner: copy node-agent/index.js, restart nxeon-node-agent; or VM_MOVE_TRANSPORT=ssh).
- `prisma db push` on prod (main thread/owner, after merge).
- No end-to-end run of worker/vm-move.ts against real nodes — only typecheck + pure-logic tests. First real run must be the rehearsal.

## Files edited outside my area (hook-ups)
worker/index.ts (import + 2 handler lines), lib/node-agent.ts (zfs wrappers), node-agent/index.js (v2 endpoints), prisma/schema.prisma, ROADMAP.md, docs/DOCUMENTATION.md.

## Owner blockers / findings (details in plan doc)
- Singapore has room only for terraria-i2ydef + mobilkit (→ node-4 after ARC 8→3 GiB); six NAT game servers need another SG node.
- VMs 106 nexis-app / 110 kodely-app RUNNING on PVE but STOPPED in DB; 106 config carries terraheim's IP 51.79.226.215.
- Duplicate VMs across nodes (projectzomboid 116@node-2, upnormal 117@node-2, sausaugepro 101@node-2 RUNNING + 600@node-4).
- node-5 root disk 96% full; primary root was 98% (7.4 GB cloudimg under /var/lib/vz/template on the root disk).
- Platform PVE token lacks VM.Migrate (irrelevant to chosen zfs path, noted).

# Palworld ticket (Hoo Chee Keen, Palsauge, server cmtmwgyh21343hl77ufmuydci) - 2026-10-04

Server: sausaugepro, vmid 600, node-4 (ns564103), Pro 8GB/3 cores, RUNNING, created 2026-09-04. Palworld docker, memlimit 0 (no cgroup cap).

ROOT CAUSE (ours): worker/monitor.ts resourceGuardSweep (node RAM >= node_emergency_pct 97 for 2 sweeps) reboots the single largest VM on the node.
node-4 is 61/63 GiB used, host swap full (2.0/2.0 GiB), VMs sum maxmem 80 GiB (127% overcommit). Palworld is always the biggest guest -> sausaugepro rebooted 13x
since 2026-10-02 18:02 (qmreboot by nxeon@pve at 10:33, 09:33, 08:23, 07:23, 05:43, 04:43, 02:52, ...). Each sends the "automatically restarted" email + in-app notification.
Email copy blamed the customer ("using more resources than usual", "needs a bigger plan") - false; metric is NODE memory, not plan/charts.
Second cause: ungraceful VM deaths 06:15-07:02 and 10:46 (journal ends with no shutdown; no qmstop task; restarted by vm-recovery sweep qmstart nxeon@pve at 06:22:33, 06:32:33, 06:42:33, 07:02:33, 09:12:33, 10:52:33 = ~10 min cadence). Strong inference: host kernel OOM killing QEMU (swap full). NOT verified - no node-4 dmesg access (PVE syslog API 403). Same pattern as 2026-09-25 OOM-kill of kvm on primary.
Game itself is fine: container RestartCount 0, OOMKilled false, no guest OOM, guest swap ~2MB, PLAYERS=10, AUTO_REBOOT_ENABLED=false. Platform schedule: GAME_POWER restart 20:00 UTC daily (source=schedule); GAME_UPDATE every 6h (no restart seen).
Customer claims: right on both (disconnects ARE whole-VM reboots/deaths; charts look healthy because guest RAM ~3.4/8 GB; email is wrong to blame plan).
Also: PRIMARY-OFFLOAD-PLAN notes a duplicate sausaugepro copy (vmid 101) RUNNING on node-2 - leftover, worth checking.
Possible secondary: ZFS ARC on node-4 may inflate node "used" (not checkable via API).

FIX implemented: branch fix/palworld-resource-warnings (worktree /tank/dev-worktrees/palworld-warn): lib/resource-guard-pick.ts (skip already-rebooted VMs, 6h cooldown, env NXEON_RESOURCE_REBOOT_COOLDOWN_MIN), monitor.ts uses it, honest email/notification copy, test/resource-guard-pick.test.ts (6 pass), tsc 0 errors, docs updated.
OWNER ACTIONS: relieve node-4 (move VMs / migrate Palsauge to a node with headroom / check ZFS ARC cap + add RAM), verify OOM in node-4 dmesg, deploy via promote script, consider temporarily raising node_emergency_pct only if ARC inflation confirmed, goodwill credit.

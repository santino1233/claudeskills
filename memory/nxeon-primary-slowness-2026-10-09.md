---
name: nxeon-primary-slowness-2026-10-09
description: "Root causes of the primary node portal slowness on 2026-10-09 (Zomboid VM crash loop from ballooning floor, RAM oversubscription) + fixes applied + Minecraft 2-vCPU chunk finding"
metadata:
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-10-09T15:50:18.953Z
---

Portal/admin was slow and the Claude session disconnected (2026-10-09). The app itself answered in ~5 ms on loopback and Postgres was idle; the host was CPU/RAM starved.

- **Main cause:** VM 121 (projectzomboid-kc0kcr) crash-looped 16+ times in ~50 min. Ballooning had shrunk its 6 GB to a 4 GB floor, the game (Java, ZGC) got OOM-killed inside the guest, and every systemd restart re-ran DepotDownloader -validate + workshop install + chown (100-170% CPU on the host). Fix: `qm set 121 --balloon 6144` plus live `balloon 6144` in the qm monitor. CPU PSI fell ~30% -> ~2%.
- **Structural:** primary has 64 GB RAM, 12 running VMs allocate 64.5 GB, plus ZFS ARC 8 GB; swap full; a host OOM already killed VM 658 at 07:17. Palworld (VM 658) legitimately uses ~270% CPU on 3 cores.
- **Applied on the primary:** `systemctl set-property system.slice CPUWeight=400 MemoryLow=6G` (portal+postgres beat VMs under contention); staging web+worker stopped (2.2 GB; units nxeon-staging-web / nxeon-staging-worker, restart only if needed).
- **Ballooning floors on other 8 GB VMs (120 blue, 105 studionexis-soul, 200 hosting-1) are still 4096**; check them for the same loop before trusting them.

**Minecraft chunk issue (owner asked):** on a 2-vCPU VM Paper's chunk system auto-sizes to 1 I/O + 1 worker + 1 gen thread ("[ChunkTaskScheduler] Chunk system is using 1 I/O threads, 1 worker threads"), with view-distance/simulation-distance 10 and sync-chunk-writes=true defaults and no Aikar flags (lib/game-config.ts:507 default 10). kodi.playnxeon.com (minecraft-f3izjh, VM 88006, node-7) shows "lost connection: Timed out". Not yet fixed fleet-wide.

**Why:** these are the facts the next session needs to avoid re-deriving. **How to apply:** when the primary is slow, check `ps` for VMs at >100% CPU and restart loops (`systemctl show <svc> -p NRestarts` in the guest) before blaming the app; see [[nxeon-vm-move-real-runs-2026-10-09]] for the VM moves.

---
name: nxeon-build-host-node2
description: Owner decision 2026-10-07 — all dev work AND production builds move to node-2; primary only serves the live site
metadata:
  type: project
---

Owner decision (2026-10-07): ALL development work (agent worktrees, tsc, tests, dev servers, Playwright) AND production `next build`s move to **node-2** (178.63.94.114, i7-8700 12t, 62 GB) under a capped systemd slice (node-2 also runs ~13 customer VMs). The finished release is shipped to the primary, which only does schema push + smoke + switch + restart. LIVE since 2026-10-07 16:28 UTC (main 109e4a134e, first node-2-built release 20261007T162846Z-109e4a13). Rules: /root/agent-notes/BUILD-HOST.md; agents use `/opt/nxeon/scripts/devhost` (tsc/test/build/dev/db push on node-2, throwaway DBs on node-2 127.0.0.1:5433). `--build-local` = emergency on-box build. After a Node upgrade on the primary run scripts/buildhost/provision.sh (promote refuses on version mismatch). Build-time setting snapshot list: BUILD_SNAPSHOT_SETTING_KEYS.

**Why:** parallel builds on the primary pushed load to 16–20 with swap full and slowed the live site (and hard-crashed it on 2026-10-06).

**How to apply:** new agent briefs must point at node-2 per BUILD-HOST.md, not the primary; never run heavy work on the primary. Related: [[nxeon-build-isolation]], [[nxeon-seamless-deploys-request]], [[nxeon-deploy-use-promote-script]].

**2026-10-08 incident (bare metal portal v2):** `/dashboard/dedicated` 500'd in prod for ~15 min after deploy. Cause: a SERVER component (CatalogueHero) imported and CALLED `usd()` from the `"use client"` module `components/dedicated/ui.tsx`. My screenshot harness rendered the hero inside a client component, so the bug never showed. Rule: verify UI changes through the REAL route's server render before deploy (seed the throwaway DB; the marketing agent's `.bmv2/` seed in /tank/dev-worktrees/bm-v2-mkt does this for bare metal), and never call functions from a "use client" module in server code.
Also: release builds share node-2's 10 GB `nxeon-build.slice` with agent work. When agents held 6.8 GB, the prod build stalled at "Generating static pages (0/946)" and hit the 20-min timeout. Stop dev servers before promoting.

**2026-10-08 owner: "apply more resources from node 2 if needed."** node-2 facts: 12 threads, 64 GB, NO swap; 13 customer/internal VMs hold ~38 GB RSS (incl. internal VM 88001 6 GB); free ~11 GB; memory PSI already ~50%; ARC only 391 MB. Memory caps were NOT raised (OOM would kill a customer VM). Raised nxeon-build.slice CPUQuota 600%→900% via `systemctl set-property` (persists in /etc/systemd/system.control/nxeon-build.slice.d/50-CPUQuota.conf) + scripts/buildhost/setup-node2.sh synced. Real fix = a dedicated build server (recommended to the owner, not purchased). Each agent Next dev server costs ~3 GB: run one at a time.
**2026-10-08 node-2 speed work (owner: no new server, do it on node-2):** done = CPUQuota 900% + zram swap (6 GB virtual, zstd ~3:1, 3 GB real-RAM cap; qemu.slice MemorySwapMax=0 so VMs never swap; nxeon-build.slice MemorySwapMax=6G; vm.swappiness=100; unit nxeon-zram.service; files in scripts/buildhost/). Within 20 s it moved 1.6 GB of cold agent memory to 0.5 GB. TESTED AND REJECTED: `next dev --turbopack` (light pages ~same, /mods 34 s vs 4 s). Still open: per-step build timestamps, auto-reap idle agent dev servers (~3 GB each), `next build --turbopack` A/B (separate, unmeasured).

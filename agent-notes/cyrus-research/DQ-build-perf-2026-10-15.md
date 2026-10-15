# DQ build-perf 2026-10-15 — why the rc18 promote timed out

## Verdict
rc18 is NOT heavier to build than rc17. The promote was starved of memory on node-2 by agent work
sharing the same cgroup parent.

## Measured (node-2, from systemd accounting + last-build.json)
| build | wall | CPU | mem peak | outcome |
|---|---|---|---|---|
| prod rc17 6be9831d, 10:38-10:50 | 718 s | 17m21s | 9.8 G (+1.2 G swap) | OK |
| staging rc18 84d5be2f, 18:27-18:39 | 714 s | 17m26s | 9.6 G (+1.5 G swap) | OK |
| prod rc18, 18:56-19:17 (BUILD_MAX_MIN=20) | 1200 s killed | 9m24s | 4.8 G | stuck in "Creating an optimized production build" |
| prod rc18, 19:26- (BUILD_MAX_MIN=45, live samples) | — | ~1 core, falling to ~0.15 core by 19:32 | ~2.8-3.3 G | same stall, memory PSI full 12% -> 46% |

The "rc17 built in ~5 min" figure is wrong: the release dir timestamp in deploys.log is taken AFTER
the build (rc17 build started 10:38:16, release dir 10:52:22, OK 10:57:08 => about 19 min end to end).

Static delta rc17..rc18 (587 files, +26k lines): 11 new cyrus-web pages + ~20 admin/api routes, all
force-dynamic; no new generateStaticParams; tsconfig.next.json / next.config unchanged; static pages
944 (rc18) vs 986 (Oct 7 build); compile 3.5 min in both logs. Nothing in the code delta explains it.

### Natural experiment (owner's 45-min promote, 30 s samples)
- 19:26:51-19:32:38 (agents slice ~9.7 G): prod slice 2.3-3.3 G, ~1 core falling to ~0.1 core,
  memory PSI full 12% -> 54%, still at "Creating an optimized production build".
- 19:33:08 agent memory dropped to ~0.1 G (agent jobs ended or were stopped): prod grew to 8.3 G in
  90 s, PSI 0, and the build finished at 19:40:11: 16m45s CPU, 10.7 G peak, 89 MB swap.
  That's about 7 min of wall time once it had memory. So the same rc18 commit builds normally when
  it isn't starved.

## Mechanism
- nxeon-build.slice (parent): live MemoryMax 13 G / MemoryHigh 12.5 G / swap 6 G (owner's
  `systemctl set-property` of 2026-10-11 in /etc/systemd/system.control — overrides the unit files,
  which still say 10 G). Agents slice: live MemoryMax 10 G. Prod slice: MemoryLow 6 G only.
- During the rc18 promotes agent `tsc --noEmit` runs (cyrus-email ~4.9 G, cyrus-adminhost ~3.3 G,
  nx-pz-password 4.6 G, ...) held ~9.6-9.7 G; zram swap was full (5.8/6 G).
- So the release build could use only ~3 G of the 13 G. MemoryLow is best effort: prod memory.events
  showed ~165M `low` breaches, its file cache was 147 KB (node_modules re-read from disk forever);
  the parent was also over MemoryHigh (98M `high` events), which throttles every child.

## Fix (branch fix/build-perf, commit 11a2c461, NOT applied on node-2)
- nxeon-build-prod.slice: MemoryMin=9G + MemoryLow=10G (min is never reclaimed; the parent OOM-kills
  agent processes, oom_score_adj 1000, instead).
- nxeon-build.slice: MemoryHigh=infinity (keeps MemoryMax 13G); unit files now match live sizing.
- setup-node2.sh warns about system.control drop-ins; remote-build.sh logs agents' memory at build
  start and warns when the build is unprotected. Docs updated.
- Applying on the live host (owner): 
  `systemctl set-property nxeon-build-prod.slice MemoryMin=9G MemoryLow=10G` and
  `systemctl set-property nxeon-build.slice MemoryHigh=infinity`.
  Immediate workaround without a config change: stop agent devhost jobs on node-2 during a promote.

## Not done
Timed rc17-vs-rc18 rebuilds: node-2 was held by the owner's 45-min promote (started 19:26) the whole
time. The existing accounting above (same host, same scripts) gives the comparison.
No portal code changed, so route list / ƒ-○ classification / tsc are unaffected.

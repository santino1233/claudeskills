# Nxeon fleet orphan / leftover audit (READ-ONLY)

Date: 2026-10-05 ~09:00-09:30 UTC. Nothing was stopped, deleted, started, resized or written. Only Proxmox GET calls (lib/proxmox.ts pveFor with stored Node creds), node-agent GETs (`/v1/nat/chain`, `/v1/net/neigh`), SELECT-only psql, local read-only `qm list`/`zfs list`/`iptables-save`/`du` on the primary, and read-only docker/du commands over SSH on the internal freemc-host (VM 100) only.
Raw data: scratchpad `pve.json` (all VMs, configs, week rrd, storage content), `servers.json`, `agent.json`, `freemc*.json`.

## 0. Headline

* Fleet is clean of "dead customer VMs". Of 78 non-template VMs/LXCs across 5 nodes: 74 match a live Server row or a known platform role. **No expired/suspended-but-present Server exists** (every `expiresAt` is in the future; 103 kaymofilms and 105 studionexis-soul have 2028/2029 expiries, not 2026). **No DB-row-without-VM.** No LXCs anywhere. No QUEUED/RUNNING Jobs (only FAILED history, 266 rows). No orphan DNAT rules on any node, no orphan zvols/disk images, no `unused*` disks, no VM locks.
* Only ONE running orphan VM: **node-5 VMID 147 `valheim-1gcle3`** (stale source copy of customer jayianpabilan25's server, which now lives as VMID 601 on node-4). 4 GB RAM, 2 vCPU, 30 GB zvol. It has no DNAT rule (10.20.4.109 is unreachable from outside) and no DB row.
* Biggest real reclaim is **stale vzdump archives on the primary and nodes (~420 GB, ~79 GB of it HIGH confidence)**, not compute. Compute reclaim is small: 4 GB RAM / 2 vCPU (VM 147) plus about 4 GB of freemc-host junk disk.
* The bigger capacity story is that **/admin/capacity under-counts**: platform VMs (200, 8000, 9010, 501, 147) are invisible to the DB-commit sum, and DB status drift (106, 110 DB=STOPPED but running) hides live VMs. See section 4.

## 1. Inventory classification (all nodes)

Counts: primary 12 VMs + 11 templates; node-2 11 VMs + 6 templates; node-3 7 VMs + 10 templates; node-4 20 VMs + 5 templates; node-5 7 VMs + 4 templates.

| Class | VMIDs |
|---|---|
| IN-USE, matches live Server (51 rows; status/node/name all agree except the drift below) | all customer VMs listed per node in section 2 |
| IN-USE internal / platform role (no Server row, by design) | primary 200 hosting-1 (HostingNode, 11 ACTIVE + 1 SUSPENDED accounts), 8000 nxeon-mail, 9010 coldemail-relay (51.79.168.98 INTERNAL IP); node-4 501 nxlabs-storage (NX Labs drive, 150 GB data disk) |
| IN-USE internal with Server row (owner) | 100 freemc-host (67 free-MC servers READY), 105 studionexis-soul (live Soul Pilates), 106 nexis-app, 110 kodely-app, 129 xeren-labs (role not in my memory, **UNKNOWN**, see below), 647 nxeon-team-pm |
| TEMPLATE | 9000-9009 per node (OsTemplate rows all point at 9000-9009), plus node-2 **9101 tpl-ubuntu-2404-game** (golden game template POC, built 2026-10-01, tag nxeon-golden, NOT referenced by any OsTemplate row) |
| ORPHAN | **node-5 147 valheim-1gcle3** |
| EXPIRED/SUSPENDED-BUT-PRESENT | none |
| DB-ROW-WITHOUT-VM | none |
| UNKNOWN | node-2 129 xeren-labs (owner account, created 2026-09-17, free, 4 GB/2 vCPU, cpu 0.2%, net 0.1 KB/s all week, no memory note found) |

Trials (will self-expire, autoRenew false, not leftovers): 659 gabriel-trial (Pro 8 GB/3 vCPU, created today, exp 10-08), 646 minecraft-t9ble6 (free, exp 10-09). Billing grace, not leftover: 115 bujangsmp (dunning stage 3, grace to 10-08).

DB status drift (not orphans, but wrong): VMID 106 nexis-app and 110 kodely-app are `Server.status=STOPPED` but running in Proxmox (up 10 days; kodely-app is the live Kodely box). Whatever reads "STOPPED" (admin lists, start/stop logic) is wrong for these.

## 2. Per-node tables of every non-IN-USE item (ordered by reclaim size)

### node-5 (bhs1, 54.39.132.159)
| Item | Evidence | Conf. | Reclaim | Recommended action |
|---|---|---|---|---|
| VM 147 `valheim-1gcle3`, running, up 3.9 d | Same name, same owner tag (user-cmulpz95) and same era as Server 601 (node-4, 10.20.3.110, created 10-01). No Server row, no VmMove row, ip 10.20.4.109 has no DNAT in NXEON_FWD (checked via agent) so nobody can reach it; DB ServerArchive shows VMID 147 was previously a deleted qa-sweep-corekeeper (ID reuse). Week rrd: cpu 3.8%, net 4/0 KB/s, 3.6 GB RSS (idle Valheim with no players). | HIGH it is a stale duplicate; MED on "contains nothing the customer needs" | 4096 MB RAM (balloon floor 2048), 2 vCPU, 30 GB zvol provisioned (actual thin usage est. 10-20 GB) | Owner approval, then verify 601 serves the customer's world (compare world dir mtime/size), then stop + destroy 147 and remove `snippets/nxeon-147.yaml`. Also delete orphan snippet `nxeon-148.yaml` (tiny). |

### node-4 (ns564103, 139.99.125.21)
| Item | Evidence | Conf. | Reclaim | Action |
|---|---|---|---|---|
| vzdump archives of VMID 600 (5 files, 58.3 GB, 09-25..10-03) | VM 600 deleted today (caller note); no VM/DB row | HIGH it is orphan; MED on deleting now (customer-deletion safety window) | 58.3 GB | Delete after owner picks a retention window |
| vzdump 101 (11.3 GB, 09-23) and 117 (1.6 GB, 09-18) | copies of the node-2 archives; VMID 101 is now throarbin-terraria on node-5 and 117 was a modtest VM | MED | 12.9 GB | Delete with the node-2 copies |
| ISO `systemrescue-13.02-amd64.iso` | local storage | LOW (may be wanted rescue media) | 1.3 GB | Keep unless owner says otherwise |
| 501 nxlabs-storage | running, untracked by capacity math | n/a, IN-USE | 4 GB RAM counted nowhere | see section 4 |

### node-2 (nxeon-fsn1, Hetzner)
| Item | Evidence | Conf. | Reclaim | Action |
|---|---|---|---|---|
| vzdump 101 x10 (115.6 GB, 09-06..09-23) | VMID 101 on node-2 was sausaugepro (moved 117->101 on 09-06, later moved to 658 on primary). Now no VM 101 on node-2. Only 1 fresh backup of 658 exists (6.3 GB, today). | MED, stale history of a LIVE customer | up to 115.6 GB | Keep newest 1-2 until 658 has a week of backups, then delete the rest |
| vzdump 117 (1.6 GB, 09-18) | modtest-vintagestory (e2e-test user) | HIGH | 1.6 GB | Delete |
| snippets nxeon-116/117/119/137/138.yaml | no such VMs on node-2 | HIGH | KBs | Delete |
| 9101 tpl-ubuntu-2404-game (template) | POC, not in OsTemplate | MED | 12 GB provisioned (thin) | Owner decision (golden-image POC) |
| 129 xeren-labs | UNKNOWN role | LOW | 4 GB / 2 vCPU | Ask owner |

### node-3 (nxeon-sgp2)
| Item | Evidence | Conf. | Reclaim | Action |
|---|---|---|---|---|
| vzdump 114 (3.7 GB, 09-11) | VMID 114 on node-3 gone; skyora-prod is 114 on node-2 | MED | 3.7 GB | Delete with primary copies |
| snippet nxeon-114.yaml | no VM | HIGH | KBs | Delete |

### primary (ns5002569, /tank/backup = 626 GB used of 3.5 TB; host `/` root disk is 81% full, 9 GB free)
| Item | Evidence | Conf. | Reclaim | Action |
|---|---|---|---|---|
| `platform/` + `dump/` archives for test VMs 101,102,103,104,111 (+100 old dumps) | All newest <= 2026-08-21 (memory: test VMs 101-104 destroyed 08-21; 102 was 160 GB ggjgjhgjghh); 111 = qa-sweep-vrising (0 spend). Platform 111: 10.0 G, 102: 27.0 G, 101/103/104: 10.8 G; dump 100-104: 31.1 G | HIGH | **78.8 GB** | Delete after approval |
| VMID 118 archives (platform 24.3 GB 09-30..10-02 + dump 4.6 GB) | dst-ddvzfe deleted 10-03 (customer hero25455, paid 799c) | MED (customer-deleted, recent) | 28.9 GB | Delete after chosen safety window |
| Pre-migration archives of VMs that now live on other nodes/IDs: platform 117 (31.5 GB, to 09-06), 108 (22.5 GB, to 09-05), 113 (14.7 GB, to 09-06), 119 (13.8 GB, to 09-07), 100 (1.4 GB, to 09-05); dump 117 (11.0), 108 (7.8), 114 (7.5, 09-11) | The VMIDs were moved off primary (117->101->658, 113->102, 116->103, 119->node-3) or deleted; no new archives since | MED | ~110 GB | Delete once the destination VM has verified fresh backups |
| 106/110/200/8000 old dump files (nexis, mail 07-26 2.8 GB; 105 08-04 6.0 GB) | superseded by daily platform backups | LOW | ~9 GB | Optional |
| ZFS snapshot `data/vms/vm-105-disk-0@rehearsalclean` (998 MB used) on the LIVE Soul Pilates VM | name = leftover from a restore rehearsal; snapshots slow guest I/O and pin blocks | MED | 1 GB | Owner approval only (105 is production) |
| /opt dev worktrees (`nxeon-wt-g1..g7`, `-tours`, `-adminmail`, `nxeon-agent-*`): ~6 GB of the 49 GB root disk | They are active feature branches, not VMs | n/a | n/a | **Do not touch**; flag root disk 81% as a risk |
| tpl-* templates 9000-9009 | normal | n/a | n/a | keep |

### freemc-host (VM 100 on node-2, internal; read-only SSH)
| Item | Evidence | Conf. | Reclaim | Action |
|---|---|---|---|---|
| 43 dirs in /opt/freemc/servers with no FreeMinecraftServer row (37 are 1 MB empty, 6 are 129-275 MB incl. `timingtest` and `readytest2`) | ids absent from DB (rows keyed by id and containerName) | MED | 1.4 GB | Delete after approval; confirm each id is not a user id used as a container name |
| 10 anonymous docker volumes, all created 2026-08-25, 0 attached | `docker system df`: 2.68 GB, 100% reclaimable | HIGH | 2.7 GB | `docker volume prune` after approval |
| Containers `mc-readinesstest2`, `mc-skyblocktiming`, `mc-router-old-itzg-backup` (exited), and `mc-free-cmtmg7vgh0k4jhl771tavwm2y` (no DB row) | test leftovers | HIGH (first three), MED (last) | tiny | Remove after approval |
| /opt/freemc/trash (3 dirs, 668 MB, from 10-02) | deliberate soft-delete area | MED | 0.7 GB | Clear after retention window |
| Over-provision note | 8 GB RAM/3 vCPU; only mc-router running 24 d, 527 MB used, load 0.00, 72 containers all Exited by design (auto-sleep) | LOW | up to 4 GB RAM | Right-size only after checking wake-burst needs |

## 3. Safe to delete AFTER OWNER APPROVAL (exact items)

Compute
1. node-5: `qm stop 147 && qm destroy 147 --purge` (valheim-1gcle3) plus `vmdata-hdd:snippets/nxeon-147.yaml`. Precondition: confirm Server 601 on node-4 holds the current world. There is no Server row, so no DB delete is needed, but make sure no row ever referenced vmid 147 (ServerArchive history only).

Backups (primary `/tank/backup/...`), HIGH:
2. `platform/vzdump-qemu-{101,102,103,104,111}-2026_*` (all <= 2026-08-21 for 101-104, <= 10-01 for 111) and `dump/vzdump-qemu-{100,101,102,103,104}-2026_07_26..08_02*` = 78.8 GB.
3. Orphan snippets: primary `nxeon-{100,101,102,103,104,108,113,114,117,657}.yaml`; node-2 `nxeon-{116,117,119,137,138}.yaml`; node-3 `nxeon-114.yaml`; node-5 `nxeon-148.yaml` (note several are in the `backup:snippets` dir shared with vmdata-hdd).
4. freemc-host: the 10 anonymous docker volumes and the three test containers (about 2.7 GB).

MED (pick a retention window first):
5. VMID 600 archives on node-4 (58.3 GB), VMID 118 (28.9 GB), node-3 `nodes/node-3/platform/vzdump-qemu-500-*` (13.7 GB; 500 darkeden-guard-sg deleted 09-29).
6. Stale pre-migration archives (about 110 GB primary + 115.6 GB node-2 101-chain + 11.3+1.6+1.6+3.7 GB copies), only after 658/601/other moved VMs show fresh verified backups.

Totals if everything above is approved: about 420 GB disk (HIGH 79 + 3 GB, MED ~340 GB), 4 GB RAM, 2 vCPU. Real thin-zvol disk back from VM 147 is about 10-20 GB (not 30).

## 4. Capacity model vs reality (lib/node-capacity.ts)

The DB-commit sum only counts Server rows (plan/gamePlan RAM, vCPU), excludes only status DELETING, ignores platform VMs. Compared with Proxmox:

| Node | DB committed RAM / capacityRamMB | Real config of RUNNING VMs | Host actually used | Untracked running VMs |
|---|---|---|---|---|
| primary | 56,320 / 56,000 MB (includes DB-STOPPED 106 and 110) | 76,288 MB, 37 vCPU on 8 threads | 53.6 / 64.1 GB | 200 hosting-1 8,192 MB/4 vCPU; 8000 nxeon-mail 6,144/6; 9010 coldemail-relay 512/1 = **14,848 MB, 11 vCPU invisible** (balloon and ARC cap are what keep it alive) |
| node-2 | 51,200 / 56,171 | 51,200 | 49.0 / 64.2 GB | none |
| node-3 | 32,768 / 23,862 (137%, already over the stored cap; host has 31.9 GB total) | 32,768 | 27.5 / 31.9 GB (86%) | none |
| node-4 | 73,728 / 56,000 (132%) | 77,824 | **59.3 / 64.1 GB (92%)** | 501 nxlabs-storage 4,096 MB / 2 vCPU |
| node-5 | 22,528 / 56,070 | 26,624 | 35.7 / 64.1 GB | **147 orphan** 4,096 MB / 2 vCPU |

Findings: node-4 (92% real) and node-3 (86%) are the pressure points; removing 147 only helps node-5 which has 28 GB real headroom, so it is housekeeping, not relief. Node-4 relief would come from moving VMs, not from deleting leftovers (nothing orphaned there). Primary's untracked platform VMs mean its "56,320/56,000" understates real commitment by about 27%. Also `node-3.capacityRamMB=23862` is far below the 31.9 GB physical, which is why it shows 137%.

Disk: primary vmdata 213/331 GB real (thin zvols, e.g. vm-105 100 GB provisioned = 41 GB used); node-4 vmdata 298/384 GB (78%) is the tightest pool; node-5 backup dir is 18/20 GB (full, tiny dedicated dir).

## 5. Paying-but-idle VMs (NOT orphans; do not delete)

All of these are live customer/owner VMs with <1.5% CPU and <6 KB/s network for the whole week: primary 200 hosting-1 (8 GB), 110 kodely-app, 106 nexis-app, 9010; node-2 103, 124, 102, 108, 113 (ARK 8 GB, 0.7% cpu), 104, 123, 129; node-3 107, 125, 122; node-4 140, 138. The web-01 / vps-* boxes belonging to support@intridaltd.com (4 VMs), support@want2bthereltd.com (2) and support@pjconsultingservices (1) were all created 09-15..09-29 and are probably reseller/agency boxes; useful for a customer-success check, not cleanup. Two FREE dedicated IPs sit unassigned (15.235.105.21 node-5, 178.63.94.91 node-2) and likely cost money monthly.

## 6. Do NOT touch

* primary 105 studionexis-soul (live Soul Pilates business; also snapshot @rehearsalclean needs owner OK), 8000 nxeon-mail, 200 hosting-1 (12 hosting accounts), 9010 coldemail-relay, 110 kodely-app (DB says STOPPED but it is live), 106 nexis-app (studionexis.com dev app).
* node-4 501 nxlabs-storage (NX Labs drive and mirror source), 647 nxeon-team-pm (owner PM VM).
* node-2 100 freemc-host (67 free servers), 9101 golden template (owner decision), 129 xeren-labs (unknown, ask).
* All 9000-9009 templates on every node (OsTemplate bases) and `platform/PROTECTED-VOLIDS`, `platform/host-config-*`, `db/`, `manual/`, `nodes/` host config collections.
* /tank/backup/nxlabs-mirror (57.7 GB, in use) and every `/opt/nxeon-wt-*`, `/opt/nxeon-agent-*`, `/tank/nxeon-wt-*` worktree (active branches).
* Customer game VMs: all tags `user-*` have live Servers; tenant data inside them was not inspected.

## 7. What I could not check

* Node host OS for node-2/3/4/5: no SSH route exists (node-agent exposes only NAT chain, neigh, backup, ZFS dataset ops). Zvols, images, backups, ISOs and snippets were checked through the Proxmox storage API instead (complete for PVE-managed volumes; unmanaged datasets/dirs outside PVE storages not visible). `/var/lib/docker` and game data roots on customer VMs deliberately not read (tenant data); only the internal freemc-host was inspected at guest level. Docker/volume leftovers inside customer game VMs remain unaudited.
* DNS (Cloudflare) records for game subdomains vs deleted servers: not read (no read-only DNS helper run). DB side is clean: 0 PortForward rows without a Server, and every DNAT destination on all 5 nodes maps to a live Server IP.
* Per-VM guest-agent real disk usage (thin-provisioning) for non-primary nodes; reclaim estimates for disk use provisioned size or an estimate where stated.
* Backup retention policy intent (which old archives the owner wants kept as safety nets), so MED items need an owner decision.

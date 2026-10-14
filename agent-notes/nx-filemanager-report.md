# Admin file manager + storage analytics — report (2026-10-14)

Branch `feature/nx-admin-filemanager` (worktree `/tank/dev-worktrees/nx-filemanager`), commit `12298163`.
**Not merged, not pushed, not deployed.** Full write-up: `docs/DOCUMENTATION.md` → "Admin file manager and storage analytics"; ROADMAP section added.

## What shipped
- **`/admin/files`**: file manager over every node. Browse, view and edit text (atomic save; refuses a stale write), streamed download, chunked upload (8 MiB chunks, so it fits under nginx's 20 MB limit; an existing file goes to trash first), new file or folder, rename or move, delete = move to a 7-day trash (restore / purge / hourly expiry), hard delete only after typing the exact name. Also Recent files and per-node Settings (roots, extra protected paths, scan dirs, read-only).
- **`/admin/storage`**: per-node pools and filesystems with NVMe/SSD/HDD media, health and fragmentation, a 30-day growth chart with growth/day, disks, backup dirs, a customer-VM / template / other-VM / Nxeon-app / backup split, largest directories and largest files, open STORAGE alerts, "Scan now". Charts come from `components/ui/charts.tsx` only.
- **`/admin/storage/running`** (read-only): each node's processes, docker containers and guests. Each customer server has an "Inspect" button: one SSH session running one fixed, read-only command. The result is stored and audited. Nothing crawls customer machines in the background.
- **node-agent v6**:
  - `/v1/storage/report` and `/v1/inventory` are read-only and always on.
  - `/v1/fs/*` and `/v1/storage/scan` return 403 unless `NXEON_AGENT_FS=1`. Writes also need `NXEON_AGENT_FS_WRITE=1`.
  - The primary gets the same file as a loopback-only `nxeon-fs-agent` (`NXEON_AGENT_SCOPE=fs`, 127.0.0.1:8944). This is needed because the web app runs as the `nxeon` user.
- **Worker sweep `storage-analytics`** (runs every 15 min):
  - Hourly report → StorageSample history.
  - Daily deep scan (`du -x` depth-limited plus `find` for large files, under nice 19 and ionice idle). It runs only at 7–8 UTC or after an admin presses "Scan now", and the node refuses it when busy.
  - Alerts: `STORAGE:` NodeAlerts at 80% (warning) and 90% (critical), through the existing fleet-alert machinery.
- **Safety**:
  - Who can use it: ADMIN only (`requireFmAdmin`), refused while impersonating, per-admin rate limits.
  - Audit: an AuditLog row `admin.fm.<op>` (actor, node:path, outcome) for every call, including refusals.
  - Path checks: a lexical jail in the app (parity-tested against the agent), plus realpath checks in the agent: symlinks can't escape, and mount points, nested filesystems and DB data dirs (detected by marker files) are refused.
  - Protected paths: shadow files, `.ssh`, `.env`, keys, `/etc/pve`, `/var/lib/pve*`, VM image dirs, DB dirs and system dirs.
  - Limits: size caps on edit, upload and download.
  - Writes are off by default. Three switches must all allow them: Setting `filemanager_read_only` (default true), the node's own config (default read-only), and the agent's `NXEON_AGENT_FS_WRITE`.
- **Nav**: Fleet → "Files & storage" (Storage / File manager / Running apps). RBAC maps all three to `platform` (ADMIN).
- Note: the admin portal now renders through `components/admin/shell/AdminShell` (the 2026-10-01 redesign), not `components/portal/Shell.tsx` as the brief said. The pages use the same admin classes and match.

## Schema changes (prod needs `prisma db push`; additive only)
New tables: `FileManagerNodeConfig`, `StorageSample`, `StorageNodeState`, `StorageDirSample`, `ServerInventorySnapshot`. No changes to existing tables. Verified with `devhost db push` on the throwaway DB `wt_nx_filemanager`.

## Owner commands (after merge + deploy)
1. Deploy normally (`deploy-staging.sh` → verify → `promote-production.sh`). The schema push happens there.
2. Primary: `sudo scripts/filemanager/install-local-agent.sh` (read-only) or `--write`. Then restart `nxeon-web` and `nxeon-worker` so they pick up `NXEON_LOCAL_AGENT_TOKEN`.
3. Each other node, one at a time: `sudo scripts/filemanager/enable-node-fs.sh node-2`. Options: `--write`, `--upgrade-only`, `--off`, `--dry-run`, and `NXEON_FS_ROOTS=...` to set the node's root ceiling. This restarts only the agent, not any VMs.
4. In `/admin/files` → Settings: review the roots, then turn read-only off per node and globally, only if you want writes.

## Verification
- `devhost tsc` is clean.
- New tests: `test/filemanager-jail.test.ts`, `test/node-agent-fs.test.ts`, `test/filemanager-guards.test.ts`, `test/storage-analytics.test.ts`. They pass alongside node-agent*, ovh-admin and cyrus-docs-coverage.
- Every filesystem test runs in temp dirs only.
- `test/node-agent-cpu-affinity.test.ts` was bumped to agent v6. It sometimes fails with EADDRINUSE because it uses a fixed port (18944).
- Full suite: 52 failures. I re-ran the 26 failing files on the base commit `f12841d2` and every remaining failure also fails there; most come from billing/promo test files that crash on load at base. My only new break (the HAZARD guard didn't recognise the `writeGate` helper) was fixed by renaming it `requireFmWriter`. The stale Cyrus generated references were regenerated and committed.
- UI was checked with a devhost dev server, a demo agent jailed to a node-2 temp dir, and Playwright on node-2.
  - Flows tested: login; storage page; editing and saving a file; refusal on `.env`; trash, then the trash view; upload; refusal to delete a DB directory; refusal of a symlink pointing outside the jail; recent files; settings; a node without an agent; running apps.
  - Width: 1440 px fits; at 390 px the pages fit after `min-w-0` fixes, with no horizontal scroll.
  - Data: the real collector ran end to end against node-2 hardware, read-only. Storage history and one inspection snapshot are labelled test fixtures in the throwaway DB.
  - Screenshots: `/tank/dev-worktrees/nx-filemanager/.fmdemo/shots/`.
  - The harness lives in `.fmdemo/` and is untracked.

## Risks / open points
- **Blast radius of v6**: with `NXEON_AGENT_FS=1`, a leaked node-agent token can read files under that node's roots, and change them if writes are on. Today the token only touches NAT and ZFS. Keep writes off unless they are needed.
- `enable-node-fs.sh` installs a drop-in with `ProtectHome=false`, so the agent can see `/root` and `/home`.
- ionice idle class does nothing on NVMe schedulers (none/mq-deadline); there only nice applies. A deep scan of a huge tree can still cost IO. Mitigations: the 15-minute cap per directory, the busy refusal and the off-peak window. The 7–8 UTC window is a guess, not measured traffic; change it with `storage_scan_hours_utc`.
- Rate limits are in memory per web process. Upload audit is one row at start and one at commit or abort, not one per chunk.
- If an agent restarts mid-upload, a `.nxeon-upload-*.partial` file is left behind and can be deleted by hand. The trash lives on each filesystem (`<mount>/.nxeon-trash`) and uses space until it expires.
- Process lists can show command-line arguments (cut to 300 chars) that may contain secrets. This is admin-only.
- Not covered yet: shared-hosting nodes (`HostingNode`), and per-customer hosting or Cyrus storage in the split. "Recently uploaded customer files" is the on-demand Recent files walk, not a feed.
- `verify-node.sh` will report the new agent hash after the upgrade; that is expected.
- The branch is committed but not pushed (this worktree has no auto-push hook).

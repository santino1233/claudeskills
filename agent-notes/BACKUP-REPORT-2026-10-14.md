# Backup / Dropbox report, 2026-10-14

## Root cause
The Dropbox remote was fine (rclone `dropbox:`, token refreshes, 2.64 TiB free of 3 TiB). The job that used it,
`nxeon-backup-offsite.timer`, has been **disabled since 2026-09-15** (last real run 09-14; one manual catch-up 10-03). Nobody noticed because
`/tank/backup/status/offsite.json` still said ok/09-12. Also: Cyrus backups were "built, not installed" (no keys, no target, no timer),
so Cyrus data, the SFX library and the build VM had no copy at all; `launch-check` backup-fresh was failing.

## Inventory (before -> after)
| Scope | Job | Before | After |
|---|---|---|---|
| primary | nxeon-backup-db.timer 03:16 (pg_dump nxeon, nxeon_staging, keep 3d) | OK daily, local /tank/backup/db only | unchanged + offsite below |
| primary | nxeon-backup-vms.timer 04:37 (host-config + vzdump 3 gens, 465 GB) | OK daily, local only | unchanged + weekly offsite |
| primary | nxeon-verify-restore.timer 05:33 | OK (scratch DB restore) | unchanged |
| primary | nxeon-backup-offsite.timer 04:20 (legacy -> Dropbox) | DISABLED since 09-15, no upload in 30 days | left disabled, replaced |
| primary | cyrus-backup.timer 03:40 | not installed | installed; node-2 gpg copy + restic to Dropbox |
| node-2 | nxeon-backup-vms.timer (host-config + 9 guests, 3 gens, ~195 GB) | OK daily, local only | offsite via primary (ssh pull) |
| node-2 | cyrus db/library/sfx target /tank/cyrus-backups | did not exist | exists, LAST_SUCCESS fresh |
| node-3, node-4, node-5 | collected into /tank/backup/nodes by node-agent | last collection 09-16 (stale) | NOT covered, see gaps |
| node-7 | none found / no ssh route from here | unknown | NOT covered, see gaps |
| VM 88001 (Cyrus build) | dpkg-db-backup only | no data backup | data tar streamed into restic nightly (18 MB) |
| Dropbox | nxeon-backups (368 GiB, run folders 09-12..09-14 + catch-up) | stale | + new tree below (uploads verified) |

## What was built (branch feature/backups-dropbox, commit 7937b45e, ff-merged to main, nothing promoted)
- `scripts/backup/nxeon-dropbox-sync.sh`: categories databases, nodes, apps, vms. age-encrypted, rclone upload, `rclone check` (staged) or size
  check (streamed VM archives), manifest per run (path, bytes, sha256), lock, bwlimit 8M day / 25M night, tpslimit 8, nice/idle, retention
  7/4/6 (VM archives newest 2), LAST_SUCCESS per category, Discord + nxeon-alert on failure.
- `scripts/backup/nxeon-dropbox-restore-drill.sh`: manifest match, optional decrypt and restore into throwaway DB.
- Units/timers in deploy/backup, installed and enabled: databases 03:50, nodes 05:40, apps 06:10, vms Sun 06:30, drill Mon 07:30,
  cyrus-backup 03:40.
- Cyrus: gpg public key for node-2 copy, restic repo `rclone:dropbox:nxeon-backups/cyrus/restic` (library catalogs, packs, knowledge, SFX 51 GB,
  VM 88001 data; keep 7d/5w/6m; verifies 5% each run). Writes the markers `launch-check` reads.
- Installed on primary: `restic`, `age` (apt).

## Dropbox layout (under dropbox:nxeon-backups; Dropbox is case-insensitive so the existing root was reused instead of /Nxeon-Backups)
databases/{nxeon,nxeon_staging,cyrus}/YYYY/MM/DD, nodes/{primary,node-2}/{proxmox-config,vm-backups/<vmid>-<name>}, apps/nxeon/{source-bundles,env-encrypted},
cyrus/restic, meta/{manifests,latest,restore-drill}. customers/*: customer game data lives inside the guest VMs, so it is in vm-backups (no separate
host paths exist). Excluded: node_modules, .next, caches, OS templates (9000-9999, reproducible; BACKUP_VM_TEMPLATES=1 to include), per-build workspaces on VM 88001.

## Verified today (real Dropbox)
- databases (nxeon 707 MB, nxeon_staging 129 MB, cyrus tables), nodes (primary + node-2 host-config), apps (source bundle 199 MB, env) uploaded and `rclone check` ok.
- Cyrus: node-2 db + library copies, restic backup + `restic check --read-data-subset=5%` no errors; `launch-check` backup-fresh PASS.
- Restore drill against Dropbox objects: manifest sha256/size match; decrypted and restored nxeon_staging into throwaway `nxeon_drill_*`
  (230 tables, 144 users), dropped afterwards. Production DBs were only read via pg_dump.
- Not yet run: the weekly VM archive upload and the 51 GB SFX restic upload (scheduled; first runs take hours at 8 MB/s day, 25 MB/s night; the
  VM path was tested against a local remote only). Quota: ~130 GB newest VM set + 51 GB SFX + ~1 GB DB/day fits easily in 2.6 TiB.

## Gaps / owner actions (see BACKUP-DROPBOX-OWNER-STEPS.md)
1. Move the private keys off the server and shred the on-box copies (until then encryption protects only against Dropbox-side compromise).
2. Rotate the Dropbox token: it was printed into this session's output by mistake.
3. Discord webhook is not set in /etc/cyrus/alerts.env (alerts go to in-app notifications and journal only).
4. node-3/4/5 and node-7 have no offsite path from this script (node-2 only). Their local backups are collected by the legacy node-agent
   path which stopped 09-16; needs ssh access details for node-7, or install this script on those nodes with `BACKUP_REMOTE` set.
5. Primary memory is tight (swap full); the jobs run at idle priority, watch the first Sunday run.
6. Local /tank/backup/platform on primary holds 465 GB (3 generations x 40 guests incl. deleted VMs); orphan archives are a cleanup candidate (not touched).

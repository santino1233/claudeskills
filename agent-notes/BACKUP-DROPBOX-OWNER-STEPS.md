# Dropbox backups: owner steps (2026-10-14)

State: Dropbox works and real backups are running. These are the few things only the owner can do. No secrets in this file.

## 1. Take the private keys off the server (do this first, ~2 minutes)
Two key files were generated on the primary because no key pair existed. Only the PUBLIC halves are used by the jobs.
```
scp root@51.79.162.96:/root/OWNER-RETRIEVE-backup-age.key  root@51.79.162.96:/root/OWNER-RETRIEVE-cyrus-backup-gpg-private.asc  root@51.79.162.96:/etc/cyrus/offbox.pass  ./
ssh root@51.79.162.96 'shred -u /root/OWNER-RETRIEVE-backup-age.key /root/OWNER-RETRIEVE-cyrus-backup-gpg-private.asc'
```
Store the three files in your password manager. WITHOUT them nothing on Dropbox can be restored.
`/etc/cyrus/offbox.pass` (restic password) must stay on the server for the nightly job; keep an offline copy as well.
Until step 1 is done an attacker who owns the server AND the Dropbox account could decrypt; Dropbox alone cannot.

## 2. Rotate the Dropbox token (recommended)
While investigating, the rclone remote definition (including the OAuth token and refresh token) was printed into this agent
session's output, and session transcripts are synced to GitHub (claudeskills). Revoke and re-authorise:
- dropbox.com > Settings > Security > Connected apps > revoke "rclone" > then on any machine with a browser:
  `rclone authorize "dropbox"` and on the server `rclone config reconnect dropbox:` (paste the token it prints).
Verify: `rclone about dropbox:` and `systemctl start nxeon-dropbox-sync@nodes.service`.
Also purge the transcript lines (claudeskills/local-pc/projects/ssh-4400f828-*/*.jsonl for this session) if the repo is not private.

## 3. Discord alerts (optional, 1 line)
`/etc/cyrus/alerts.env` has the webhook line commented out, so failures reach only the in-app admin notification and the journal.
```
sed -i 's/^# *CYRUS_ALERT_DISCORD_WEBHOOK=.*/CYRUS_ALERT_DISCORD_WEBHOOK=<your webhook url>/' /etc/cyrus/alerts.env
```
`nxeon-dropbox-sync.sh` reads the same variable for its own failure message.

## 4. Optional: a full restore drill
On your own machine with the age key and a copy of one object:
`rclone copyto dropbox:nxeon-backups/databases/nxeon_staging/<Y>/<M>/<D>/<file>.age ./x.age && age -d -i age.key x.age | gunzip | head`
On the server: `scripts/backup/nxeon-dropbox-restore-drill.sh --db nxeon_staging --identity /path/to/age.key` (throwaway DB, dropped after).

## Reference
Remote: dropbox:nxeon-backups (existing numbered 0000N-DATE folders from 09-12..09-14 and manual-catchup-2026-10-03 left untouched).
Env: /etc/nxeon/backup-dropbox.env, /etc/cyrus/backup.env. Docs: docs/DOCUMENTATION.md "Dropbox offsite backups".
The legacy nxeon-backup-offsite.timer stays DISABLED on purpose (replaced; enabling both would upload the VM archives twice).

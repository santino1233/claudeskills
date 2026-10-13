# backups — complete off-site backup scheme (2026-10-03/04)

Branch feature/complete-offsite-backups, worktree /tank/nxeon-wt-backups. Commits explicit-path, hooks disabled, nothing pushed.
Design + audit + rollout + rollback + PBS/ZFS-send evaluation: /root/research/backup-design.md
Runbook: docs/DISASTER-RECOVERY.md; docs: docs/DOCUMENTATION.md "Off-site backups v2".
STATUS: build complete and INERT; tsc clean; all backup tests pass. Nothing applied to any node; no uploads/restores.
Scratch: /tank/age-test (real age binary extracted, tests use AGE_BIN/AGE_KEYGEN_BIN) - delete when done.
Not built: game data-only backups (phase 2), WAL/PITR, second immutable copy. Not verified: real windows, real upload, real restore, live units.
Owner rollout: design doc section 9. Decisions: end of design doc.

## RESUMED 2026-10-04
Merged main (release 20261004T115028Z) into the branch; docs/DOCUMENTATION.md conflict resolved append-only. tsc 0 errors, 151 tests green.
Added docs/BACKUP-ROLLOUT.md (stages 0-7, canary node-2). Restore test skips DB leg on nodes without postgres.
Design doc section 11 has recommendations + untested list. Not merged to main; owner session integrates.

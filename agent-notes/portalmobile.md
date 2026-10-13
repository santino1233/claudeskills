# portalmobile (I2) progress note — 2026-10-01
Branch fix/customer-portal-responsive, worktree /opt/nxeon-wt-portalmobile (dev port 3117 never left running).
DONE (committed, className/CSS level, NOT tsc-checked, NOT browser-verified): see docs/RESPONSIVE-CHECKLIST-PORTAL.md.
Also done: scripts/check-responsive.ts (worked in a 7-route smoke run).
REMAINING (ordered): 1) tsc via heavy.sh; 2) full matrix run (needs a throwaway DB: create role+db, prisma db push, run
prisma/seed.ts with NXEON_CRED_FILE=/tmp/x -- NEVER without it, it overwrites /root/nxeon-credentials.txt), fixtures script
was in the scratchpad (pm-fixtures.ts); 3) fix what the run flags, esp. tap targets, tables, deploy/order wizard, support, partner;
4) fill the checklist before/after columns.
Tips: heavy.sh lock waits time out after 3600s silently; use `flock -w 14400`. Put .next on tmpfs (symlink) -- remove symlink before commit.
BLOCKERS: none for owner except the credentials file (see report).

# provfix — provisioning first-boot reliability (2026-10-02)

Branch fix/provisioning-first-boot-reliability, worktree /opt/nxeon-wt-provfix
Commits: f59a193c11 (code+tests), e08be1f528 (docs), 2ef973af4f (guard)
RCA: docs/PROVISIONING-FIRST-BOOT-RCA-2026-10-02.md

Root causes
- PZ syep3t: schema default ADMIN_USERNAME="" (lib/game-config.ts) -> validateConfig persisted "" ->
  applyGameConfigEnv overwrote catalog `admin` -> game exits on start. Only identity value affected
  (audited every live OsTemplate vs schema).
- Valheim gjjrv9: duplicate private IP 10.20.1.101 (VMs 101/137/138/644 on node-2); IPAM DB-only.
  SSH reached VM 101. Pull aborted (very likely ARP flapping); single-shot docker create, no retry;
  retries minted a new mgmt key every attempt (worker/index.ts:1031 on main).
- NOT an SSH 60s exec timeout: provision never runs the pull over SSH (cloud-init nohup); the unit
  file existing proves the script outlived the failed create.

Rollout
1. merge + deploy worker (promote script)
2. redeploy node-agent v4 (GET /v1/net/neigh) on every node
3. npx tsx scripts/fleet-ip-audit.ts  (read-only; "unreadable" = token lacks VM.Audit -> every
   provision on that node would stop)
4. owner decides on node-2 duplicates (.101 on 101/137/138/644, .106)
5. after rescue: npx tsx scripts/verify-game-provision.ts valheim-gjjrv9 / projectzomboid-syep3t
Kill switches: NXEON_IP_INVENTORY=off, NXEON_PROVISION_GUEST_CHECKS=0

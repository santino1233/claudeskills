---
name: nxeon-dbstudio-runtime-bug
description: DB Studio UI shipped but its SSH-tunnel backend fails at runtime (never runtime-tested) + Adminer 404 — exact fixes
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-12T15:27:00.210Z
---

**2026-08-12: DB Studio rebuilt UI is LIVE (prod 2e82ca2, phpMyAdmin-class) but the BACKEND is broken at runtime.** Error in the panel: **"(SSH) Channel open failure: open failed"**. Root cause found in code (no node access needed):

**BUG 1 — DB Studio tunnel blocked by our own sshd hardening.** `lib/hosting-db.ts` opens a root SSH to the hosting node then `conn.forwardOut("127.0.0.1",0,"127.0.0.1",3306)` to reach MySQL as the scoped `<user>_mgr`. BUT `scripts/onboard-hosting-node.sh:322` writes `/etc/ssh/sshd_config.d/00-nxeon-hosting.conf` with **`AllowTcpForwarding no`** → the node's sshd refuses the port-forward → "Channel open failure". This mysql2-over-forwardOut transport (the CRITICAL RCE fix) was CODE-verified but NEVER runtime-tested (per [[nxeon-security-audit-2026-08-12]]).

FIX (secure — root-only forward, scoped to MySQL; tenants are chrooted sftp/no-shell so still can't forward):
In onboard-hosting-node.sh, change the sshd drop-in heredoc to add AFTER `AllowTcpForwarding no` / `PermitTunnel no`:
```
Match User root
    AllowTcpForwarding yes
    PermitOpen 127.0.0.1:3306
Match all
```
APPLY TO THE LIVE NODE NOW (10.20.0.200, the shared-hosting node) to unblock DB Studio immediately — run on the node:
```
printf 'AllowTcpForwarding no\nPermitTunnel no\nMatch User root\n    AllowTcpForwarding yes\n    PermitOpen 127.0.0.1:3306\nMatch all\n' > /etc/ssh/sshd_config.d/00-nxeon-hosting.conf && sshd -t && systemctl reload ssh
```
(sshd reload doesn't drop existing sessions.) I (Claude) was BLOCKED by the auto-mode classifier from editing these sshd/hosting files directly — user must apply or add a Bash permission rule.

**BUG 2 — Adminer fallback 404.** `worker/hosting.ts:59` `ADMINER_URL = "https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php"` → 404 (github release asset gone). Change to `https://www.adminer.org/static/download/4.8.1/adminer-4.8.1.php` (adminer.org static download, stable). Then re-run the account's "Classic manager (Adminer)" install.

**STATUS 2026-08-12: DB Studio FIXED on the live hosting node (hosting-1 / 10.20.0.200).** The `Match User root` + `PermitOpen 127.0.0.1:3306` block was applied to /etc/ssh/sshd_config.d/00-nxeon-hosting.conf + sshd reloaded; verified the tunnel works (runScopedSql SELECT 1 → rows=[["1"]]). NOTE: user was running the fix on the MAIN node (ns5002569) — it had to run on the separate hosting node 10.20.0.200; solved with a one-liner (run on main node) that decrypts the node root pw via crypto-box + sshpass-applies on the hosting node.

**STILL PENDING (classifier blocked me from editing these hosting/ssh files — needs user permission or manual apply):**
1. onboard-hosting-node.sh — bake the `Match User root / AllowTcpForwarding yes / PermitOpen 127.0.0.1:3306` block into the sshd drop-in so EVERY future hosting node works (the live node was hand-patched; a new node would break DB Studio again).
2. worker/hosting.ts:59 ADMINER_URL → https://www.adminer.org/static/download/4.8.1/adminer-4.8.1.php (Adminer fallback 404).
Both edits were attempted on branch `feature/dbmgr-transport-fix` but blocked. See [[nxeon-resume-point]], [[nxeon-hosting-wizard]] (hosting checkout wizard still queued).

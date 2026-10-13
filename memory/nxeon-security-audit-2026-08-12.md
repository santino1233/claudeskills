---
name: nxeon-security-audit-2026-08-12
description: adversarial pentest of Nxeon found 1 CRITICAL (DB Studio RCE) + gates onboarding a 2nd hosting customer
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-22T19:12:03.759Z
---

2026-08-12 five-surface adversarial pentest (auth, money, tenant-isolation, worker-SSH, main-app). Overall the platform is very hardened — auth/RBAC/IDOR, Stripe/price/idempotency/wallet, Proxmox API, noVNC, free-tools SSRF suite, file-manager chroot, grant escaping all verified solid.

**🔴 CRITICAL (found + being fixed): Nxeon DB Studio → root RCE + cross-tenant breach.** `lib/hosting-db.ts` piped tenant SQL into the `mysql` CLI run as ROOT over SSH; the mysql client's in-band meta-commands (`\!` system, `\.`/`source`, `\T`/`tee`) execute as root on the node, bypassing the MySQL grant. A hosting tenant types `\! bash` in the SQL editor → owns the node + every tenant. Fix = protocol-level `mysql2` driver over an ssh2 `forwardOut` tunnel, authenticating as the scoped `<username>_mgr` user (no CLI = no meta-commands). Branch: hardening/dbstudio-mysql2.

**✅ FIXED + LIVE (prod a1e7e90):** DB Studio rewritten to `mysql2` protocol driver as the scoped `_mgr` user over an ssh2 `forwardOut` tunnel — no CLI, so `\!`/`source`/`tee` are gone (verified: 0 CLI invocations for tenant SQL). The hostname-claim TOCTOU MEDIUM (co-tenant vhost shadowing) is also fixed via a `HostingHostnameClaim` unique table (branch hardening/hostname-claim-atomic, promoting).

**✅ GATE CLEARED 2026-08-22.** All items below confirmed on LIVE prod + the live node (hosting-1, 51.79.226.201), not just code-reviewed:
- DB Studio mysql2 transport: FUNCTIONALLY smoke-tested against a real account (ordinary query works; cross-tenant DB read denied by the grant; `\! id` CLI meta-command rejected as invalid SQL, proving no shell escape; LOAD_FILE returns null).
- Hostname-claim TOCTOU: confirmed enforced via a real DB-unique-constraint insert inside the order transaction (not just advisory).
- Node hardening (previously "still owed"): ModSecurity ON, MariaDB bound to 127.0.0.1 with zero anonymous users, real per-tenant disk quotas (verified via repquota), PAM nproc caps (256/400) confirmed active for cron via /etc/pam.d/cron, fail2ban + unattended-upgrades active, cross-tenant symlink read closed (nginx disable_symlinks if_not_owner + kernel protected_symlinks=1).
- Suspend/unsuspend/terminate lifecycle: implemented and confirmed to actually tear down resources (vhost/FPM pool removed, user locked+killed; terminate additionally drops scoped DBs + userdel + rm -rf home — see [[nxeon-worktree-nodemodules-hazard]] session's terminate fix).

**Two-agent adversarial re-review (2026-08-22) found + I fixed 2 NEW real issues (commit 0b683e7), both reproduced-and-reverified on the live node before/after:**
- **CRITICAL**: Backup/Restore's `cp -a` (running as ROOT in `worker/hosting.ts` taskRestore) followed an existing DESTINATION symlink and wrote through it. Any customer could: drop a file in their own webroot → back it up → replace it with a symlink to e.g. /etc/cron.d/x → restore → root's cp writes attacker content into the symlink target → root RCE via cron. Bypassed every other control (FPM jail, MySQL grants, chroot) since it never touched PHP/MySQL. Fixed with `cp -a --remove-destination`; proven in an isolated /tmp sandbox (sentinel file behind a symlink survives untouched with the fix, gets overwritten without it).
- **MEDIUM**: DB Studio's rate limiter capped request RATE (60/min) but not CONCURRENCY — a tenant firing parallel queries could hold a large share of MariaDB's global max_connections, starving every other tenant's PHP-FPM pool. Fixed at the MySQL layer: the `<user>_mgr` GRANT now carries `WITH MAX_USER_CONNECTIONS 5`; backfilled onto the 3 existing mgr users immediately (only the owner's own test accounts exist — zero real paying hosting customers as of 2026-08-22).

**Shared hosting is now genuinely safe to sell.** Only remaining recommendation (optional, not built by me): a paid external pentest for a truly independent third pass. See [[nxeon-shared-hosting]], [[nxeon-server-topology]], [[nxeon-kodely-partner]] (this gate was what blocked Kodely's hosting product).

Other findings (all being fixed, none anon-critical): MED checkout-coupon concurrent-claim cap bypass (same race the promo reservation closed — mirror it for coupons); MED hostname-claim TOCTOU shadowing; MED agency-scraper DNS-rebind SSRF (staff-gated); LOWs (dbPass presence-only validation, annual discount not frozen per-server, board SVG stored-XSS admin-only, session-cookie Secure default (prod sets COOKIE_SECURE=1 so mitigated), 100%-coupon term guard).

Lesson: two agents reviewed the DB Studio transport — one cleared it (OS-shell-injection lens), one caught the mysql-client-interpreter escape. Multi-perspective adversarial review is why the CRITICAL surfaced.

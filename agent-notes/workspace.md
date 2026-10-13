# workspace — staff workspace gateway (2026-10-02)

Branch feature/workspace-gateway, worktree /tank/nxeon-wt-workspace (real node_modules copy).
Host changed mid-task to workspace.trynxeon.com (Cloudflare zone, also the cold-email domain).
Runbook: docs/WORKSPACE-GATEWAY.md. Nothing applied anywhere.

Key facts
- Session cookie is host-only; NOT widened. Cross-site hop issues a separate host-only __Host-nxws gateway cookie.
- CLOUDFLARE_DNS_API_TOKEN (.env) only sees the nxeon.cloud zone; trynxeon.com needs its own scoped token (CF_TRYNXEON_TOKEN).
- Tested nginx behaviour on a private throwaway instance (ports 18443/18080, scratchpad/wsh) against a stand-in for the routes; prod nginx never touched.
- Installer tested with stubbed nginx/systemctl/curl/certbot in a temp NGINX_DIR (apply, idempotent re-apply, failure restore, rollback).
- Lesson: never `pkill -f <pattern>` here (it matched my own shell); kill by PID from `ss -ltnp`.

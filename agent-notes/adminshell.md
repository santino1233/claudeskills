# A1 adminshell — progress note (2026-10-01)

Branch `feature/admin-redesign-shell`, worktree `/opt/nxeon-wt-adminshell`, commit 3609b9aaa2 (pushed by hook).

## Done (committed; TYPECHECK CLEAN as of commit 3609b9aaa2 — tsc --noEmit exit 0; NOT yet rendered)
- `lib/admin-nav.ts` — single nav registry (8 groups, More, pending entries for A2 /admin/ops, A3 /admin/insights, C /admin/partners/outreach, K2 /admin/nxlabs, N /admin/seo/audit). `lib/admin-groups.ts` = derived shim.
- `components/admin/shell/*` — AdminShell, Sidebar, CommandPalette, AlertsTray, Toaster, Brand, icons, primitives, types.
- `app/admin/admin-shell.css` — scoped to `:root.adm-portal`; light/dark (`data-adm-theme`), density (`data-adm-density`).
- `app/admin/layout.tsx` (new shell, RBAC-filtered nav, cookie `nx_adm_ui`), `app/admin/page.tsx` command center (`lib/admin/command-center.ts`).
- APIs: `app/api/admin/search/route.ts`, `app/api/admin/alerts/route.ts` (+ `lib/admin/shell-alerts.ts`).
- Broken-image root cause + fix: `scripts/postbuild-copy-geoip-data.sh` now copies `public/` into standalone (evidence in docs/ADMIN-IA-INVENTORY.md §5).
- Docs: `docs/ADMIN-IA-INVENTORY.md`, `docs/DOCUMENTATION.md` (Admin surfaces + dated change entry). `test/company-mailbox.test.ts` points at admin-nav.ts.

## Remaining (in order)
1. Typecheck — DONE, clean (exit 0).
2. `npx tsx --test test/company-mailbox.test.ts`.
3. Render smoke: `A1=/tmp/claude-0/-root/4f329df3-66ee-49c8-a6c5-615ecf189efc/scratchpad/a1; heavy.sh bash -c "$A1/run.sh $A1/after $A1/smoke-routes.txt desktop-dark,desktop-light,mobile-dark,mobile-light"` (sandbox DB nxeon_agt_adminshell has fixtures; .env in worktree is local-only, gitignored). Then `rm -rf /opt/nxeon-wt-adminshell/.next`. Check: CSS `@layer components` overrides apply, light mode legibility, drawer, palette search, alerts tray, RBAC (log in as support@example.test / billing@example.test via USER_ID env).
4. Hand-polish top pages (servers, users, support, nodes, billing, jobs) once screenshots exist — not started.
5. `git merge main` in worktree, re-typecheck.
6. Cleanup: `sudo -u postgres dropdb nxeon_agt_adminshell`, remove worktree `.env`.

## Notes for owner/integrator
- Files outside my area: `scripts/postbuild-copy-geoip-data.sh`, `test/company-mailbox.test.ts`, `docs/DOCUMENTATION.md`.
- Pending nav entries go live by deleting their `pending:` field in lib/admin-nav.ts. modcatalog branch adds a line to lib/admin-groups.ts — drop it on merge (already registered).
- Pre-existing RBAC bug fixed in nav: /admin/users is requireAdmin() but rbac maps it to "clients" (SUPPORT saw a FORBIDDEN link).
- /root/nxeon-credentials.txt overwrite at 05:40:57 was NOT this agent (my seed wrote to scratchpad at 05:42:53, APP_URL localhost:3106; the overwritten file has APP_URL https://nxeon.cloud).

---
name: nxeon-mail-hostname
description: "mail.nxeon.cloud web UI is redirected to the homepage; the Mailcow API + CalDAV paths are deliberately preserved — do not blanket-redirect"
metadata:
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-15T17:18:11.709Z
---

The Nxeon mail **client** is the in-dashboard webmail (`/dashboard/mail`, `lib/mail/*`, ImapFlow). The mail **server** is Mailcow at internal `10.20.0.10`, public `mail.nxeon.cloud` (51.79.162.96). Mailcow ships the dated SOGo/Mailcow browser UI, which the owner considers off-brand.

**2026-08-15: mail.nxeon.cloud browser UI is redirected to the homepage** (owner request — keep customers in the dashboard, hide the dated UI). Implemented in `/etc/nginx/sites-available/nxeon-mail` on the MAIN host (this box is the edge proxy for mail.nxeon.cloud; mail protocol ports 25/587/465/993/995/143 are DNAT'd straight to the VM via `/opt/nxeon/scripts/mail-nat.sh`, so HTTP changes never touch delivery).

⚠️ **The redirect is SCOPED — do NOT blanket-redirect mail.nxeon.cloud.** These HTTP locations are still proxied to `10.20.0.10` because the app/clients depend on them: `/api/` (Mailcow API — `MAILCOW_API_URL`, mailbox CRUD/send/stats in `lib/mailcow.ts`), `/SOGo/dav` (CalDAV/CardDAV — `CALDAV_BASE` in `lib/calendar`), `/Microsoft-Server-ActiveSync`, `/autodiscover`, `/autoconfig`, `/.well-known`. Only the catch-all `location /` does `return 302 https://nxeon.cloud/`. Backup at `nxeon-mail.bak.*`. Verified: `/`→302 homepage, `/api/v1/...`→200, `/SOGo/dav`→401 (not redirected).

Pending (app deploy): repoint the "mailbox ready" email-template login link from `webmail.nxeon.cloud` → `nxeon.cloud/dashboard/mail`. Spam filtering lives on this same Mailcow/Rspamd — see [[nxeon-meta-pixel]] is unrelated; mail spam work tracked separately (Rspamd + webmail mark-as-spam controls). See [[nxeon-chat-agent]], [[nxeon-server-topology]].

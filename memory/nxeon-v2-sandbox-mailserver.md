---
name: nxeon-v2-sandbox-mailserver
description: "the nxeon-v2 design fork has its own real Dovecot IMAP server on node2 with seeded mailboxes, so /dashboard/mail can be worked on and screenshot-verified"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2aa2dcca-a502-4055-9d89-9bae0c754838
  modified: 2026-09-08T05:28:00.798Z
---

The v2 design fork (`/opt/nxeon-v2`, node2 `178.63.94.114`) has a **real local
Dovecot IMAP server** so `/dashboard/mail` renders. Set up 2026-09-08 because the
fork points at Mailcow/`10.20.0.10`, which is dead there — the inbox showed
"No email plan yet" and the redesign had nothing to verify against.

Deliberately a real server, not a stub: `lib/mail/imap.ts` is a plain ImapFlow
client with no sandbox branch, so faking it would mean designing against code
that never ships. Folders, flags, QUOTA, MIME parsing, attachments and
`safeHtml` all run for real.

- Reproducible scripts live on node2 at `/root/sandbox-mail/` (setup, message
  seeder, DB seeder, env patch, `mailpass.txt`).
- Mailboxes `nick@brightfold.co` (14 inbox / 5 sent / 2 drafts / 3 archive /
  2 junk / 1 trash) and `billing@brightfold.co`, on a Pro EmailPlan owned by the
  `customer@nxeon.local` account — screenshot the inbox as THAT user, not admin
  (admin is staff, so `resolveMailbox` takes the company-mailbox branch instead).
- Dovecot listens on **127.0.0.1:993 only**. TLS verification stays ON: the cert
  carries SAN `mail.nxeon.cloud` (the `MAIL_TLS_SERVERNAME` default) and
  `NODE_EXTRA_CA_CERTS` in `.env` trusts its CA — do NOT reach for
  `MAIL_TLS_INSECURE=1`, that would stop exercising the real path.

Two traps worth remembering, both of which cost real time:

1. **`mail_inbox_path`.** Debian's shipped `10-mail.conf` sets
   `mail_inbox_path = /var/mail/%{user}` for its default mbox setup. Switching
   `mail_driver` to maildir does NOT clear it, so INBOX kept resolving to a path
   vmail cannot create: `LIST` happily showed the folder while every
   `SELECT INBOX` failed with "Failed to autocreate mailbox: Permission denied".
   Clearing it to empty is also wrong — INBOX then becomes an ordinary child and
   dovecot creates a `.INBOX` subfolder. It must name the maildir root:
   `mail_inbox_path = %{home}/Maildir`.
2. **Blank lines are structural.** A generated message is headers, ONE blank
   line, then body — and each multipart part repeats that. Tidying an optional
   header away by filtering empty strings out of a line array removes every
   separator too. Plain text limps through on lenient parsing; every HTML
   message renders as "This message has no content."

See [[nxeon-v2-design-fork]].

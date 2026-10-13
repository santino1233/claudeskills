---
name: nxeon-mail-spam
description: "Webmail spam controls (mark spam / not spam / block sender) shipped; Rspamd threshold + Bayes autolearn need Mailcow-host (10.20.0.10) access — app can't do them"
metadata:
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-15T17:28:54.061Z
---

Owner complaint 2026-08-15: contact@ inbox full of spam (SEO/review solicitations + a Meta-impersonation phishing mail from an r1.deped.gov.ph address — warned them it's a scam targeting new advertisers). Spam filtering IS present: Mailcow's **Rspamd** on the mail VM `10.20.0.10` (public mail.nxeon.cloud). The Nxeon webmail is a self-built IMAP client, so it had no spam controls and never trained the filter.

**Shipped (commit 39d6d28, promoted to prod):** webmail spam controls —
- `lib/actions-mail.ts`: `markSpam` / `markNotSpam` (auth-scoped IMAP move to/from Junk), `blockSender` (extends a managed per-mailbox sieve **postfilter** via the Mailcow filter API — distinct from the auto-reply/forwarding prefilter).
- `lib/mail/sieve.ts`: block-sender sieve compiler (`buildBlockSenderSieve`, `parseBlockedSenders`, `MAX_BLOCKED_SENDERS`).
- `components/customer/mail/ReadingPane.tsx` + `MailClient.tsx`: Spam / Not-spam / Block buttons + `!` shortcut, optimistic UI.
- `lib/actions-mail-admin.ts` + `components/admin/MailAnalytics.tsx`: a Junk-threshold policy card (records the setting + shows exact apply steps).

⚠️ **Hard limit — needs Mailcow HOST access (SSH to 10.20.0.10), the app CANNOT do it:** Rspamd controller port 11334 is firewalled from the app host, and the Mailcow REST API has **no spam-score field**. So:
1. **Threshold tuning** (make more spam auto-land in Junk): global via `data/conf/rspamd/override.d/actions.conf` (`add_header=<low>; reject=<high>;`) then `docker compose restart rspamd-mailcow`; OR per-mailbox in the Mailcow admin UI. The admin card shows these pre-filled.
2. **Bayes autolearn** on mark-spam/not-spam: works only if Mailcow's default Dovecot `imap_sieve` antispam hooks are enabled on the host (ON by default in stock Mailcow; app can't verify). If disabled, marking still files mail correctly but won't teach Rspamd.

USER still owes: grant SSH/Mailcow-admin access for the threshold+autolearn tuning, or run the surfaced steps themselves. See [[nxeon-mail-hostname]].

# DM: Cyrus email templates (2026-10-15)

Branch `feature/cyrus-email-templates` (from `release/cyrus-rc18`), worktree `/tank/dev-worktrees/cyrus-email`. Not merged, not pushed, not deployed, no migration, no flag changed. **No email was sent**: everything was rendered to files only.

## What was there
- The Nxeon email system (`lib/email-render.ts` shell v2, `lib/email-build.ts`, `lib/email-designs.ts`, `lib/mailer.ts`; tests `test/email-rollout.test.ts`, `test/email-templates-overhaul.test.ts`) came from `feature/nx-marketing-emails` and is already in rc18. It has no VML, so the Cyrus layout has none either.
- Cyrus mail already had its own path: `lib/cyrus/notify/templates.ts` (`cyrusMailHtml` + `renderNotification`) for the five notify events, sent through `host.mail` -> Nxeon `sendMail`. That shell was Nxeon shell v2 recoloured (navy `#0a0d1c`, blue button). The beta invite reused it. The analytics digest had its own inline copy of it. Its header logo loaded from `CYRUS_PUBLIC_BASE`, which would be a broken image once that is set to cyrus.my (the static root has no `/email` path).

## What changed
- `lib/cyrus/notify/layout.ts`: the Cyrus layout, in the cyrus.my language (site.css): black page, `#0a0a0b` 600px shell, 3px blue to violet energy line, CYRUS wordmark (white, gradient Y), mono uppercase eyebrow with the 22px gradient rule, Space Grotesk headline, Inter body, status chip, hairline fact panel, numbered "01 02 03" steps (the landing's pipeline style), white pill button with black text, Y mark footer. It uses the same mail-client rules as Nxeon shell v2: tables and inline CSS, a solid colour under every gradient, `color-scheme: dark light`, art flattened onto the cell colour, hidden preheader, `@import` fonts (no `<link href>`), mso Arial override, `</body>` last. HTML and plain text are built from one description, so they always match.
- `lib/cyrus/notify/templates.ts` is now the registry (`CYRUS_EMAILS`, `renderCyrusEmail`, `CYRUS_EMAIL_SAMPLES`). It has 19 templates: build.succeeded, build.failed, guard.refused, mod.outdated, install.succeeded, install.failed, tokens.low, tokens.out, purchase.receipt, purchase.refunded, plan.receipt, welcome, beta.invite, report.received, data.export.ready, mod.published, report.notice, takedown, analytics.digest. `renderNotification` routes the notify events to them: a refused build goes to guard.refused, and a 0 balance goes to tokens.out. The in-app title/body copy is unchanged.
- Copy is built only from event data. A missing value removes its line. Refused builds can be charged (`cyrus_tok_charge_refused` defaults to true), so the guard.refused copy points to the build page and does not promise "no charge".
- The invite (`lib/cyrus/beta/invites.ts`) and the digest (`lib/cyrus/analytics/digest.ts`) now render through the registry. The digest's admin link stays on APP_URL.
- `lib/cyrus/notify/index.ts` `mailCtx()`: links use `CYRUS_PUBLIC_BASE || APP_URL`, art uses APP_URL, and the header and footer use `bridgeConfig().cyrusOrigin`.
- Art: `public/email/cyrus/{wordmark,mark,tile,coin,badge}.png` (48 KB in total), cut from the owner's brand picks by `scripts/cyrus/email-assets.py`.
- Admin, Notify tab: "Rendered templates" shows every template with its class, sender/hook, subject, preheader, size, an iframe preview and the plain text.
- **Gallery: `docs/cyrus/email-previews/index.html`** plus one `.html` and `.txt` per template. Rebuild it with `npx tsx scripts/cyrus/email-previews.ts` (`--check`, `--png DIR`). The gallery doubles as the render snapshot.
- Tests: `test/cyrus-email-templates.test.ts` checks the snapshot per template, that no placeholders are left, that links are absolute https on the right host (cyrus.my for public, Nxeon only for admin/tickets/community pages), that art is PNG with width/height/alt and exists, that non-transactional mail has the settings link, that size is < 100 KB, plain-text parity, no invented digits with empty data, escaping, and WCAG AA contrast. Two older assertions were updated (r40 palette hex).
- Docs: `docs/cyrus/07-operations.md` "Cyrus email", `docs/cyrus/support/email-templates.md` (catalogue), `docs/DOCUMENTATION.md` (history bullet + the rewritten sender checklist), `docs/cyrus/11-history.md`, generated references (docs-build, pulled back).

## Classes and wiring
- notification (has the preference link): builds, installs, tokens, welcome, mod published, takedown (locked on).
- transactional (always sent, says why, no unsubscribe): receipts, refund, invite, report received, data export, content reported.
- staff: digest.
- No marketing class exists. Before a first marketing send, add `listUnsubscribeUrl` through `host.mail` and a postal line (`company_address` is empty today).
- **Senders wired**: the 5 notify events, the invite and the digest.
- **Template only (senders NOT wired)**: welcome, purchase receipt/refund, plan receipt, report received, data export ready, mod published, content reported. Each one lists its hook point in the admin view.

## DNS cyrus.my needs (it has none now)
Sending path, from code: `sendMail` -> SMTP Setting `smtp_host` (`SMTP_TLS_SERVERNAME=mail.nxeon.cloud`) -> **self-hosted Mailcow**, mail.nxeon.cloud = 51.79.162.96, PTR mail.nxeon.cloud. Brevo is retired, but `_dmarc.nxeon.cloud` still sends rua to brevo.com, which is stale.

I could not confirm two things because permission was denied: the live `smtp_host` / `smtp_user` DB values and whether Mailcow already has cyrus.my. Docs and the 553 incident say the SMTP user is noreply@nxeon.cloud.

Records for Cloudflare, all DNS only:
- `MX cyrus.my -> mail.nxeon.cloud`, priority 10. Required: the emails ask people to reply, and bounces and DMARC reports need somewhere to go.
- `TXT cyrus.my "v=spf1 mx a:mail.nxeon.cloud ~all"`, changed to `-all` later.
- `TXT dkim._domainkey.cyrus.my "v=DKIM1; k=rsa; p=<from Mailcow>"`, selector `dkim`, 2048 bit, generated when cyrus.my is added in Mailcow.
- `TXT _dmarc.cyrus.my "v=DMARC1; p=none; rua=mailto:dmarc@cyrus.my; adkim=s; aspf=s"`.

Mailcow steps:
1. Add the domain cyrus.my.
2. Create mailboxes `hello@cyrus.my` and `dmarc@cyrus.my`.
3. Give the mailer's SMTP user "Allow to send as" for the sender, because the relay rejects a From the user does not own (553).
4. Do one real send to Gmail and Outlook and check the headers.
5. Only then set `cyrus_mail_from` and `CYRUS_NOTIFY_EMAIL=1`.

## Found in passing
- `docs/cyrus/CYRUS-MY-LAUNCH.md` section 3 nginx regex proxies `assets`, but the static landing serves `/assets/css|js|fonts`. If applied as written, the landing loses its CSS. Check before applying it.

## Verification
- Email/notify/digest/invite suites: 354/354 pass (cyrus-email-templates, cyrus-admin-r40, cyrus-support-r50, cyrus-beta-ops, email-rollout, cyrus-analytics, email-templates-overhaul).
- docs-build was regenerated and pulled back.
- `tsc --noEmit` clean (devhost run with a 9 GB heap: the default 5 GB heap ran out of memory). `test/cyrus-docs-coverage.test.ts` passes 18/18.
- Screenshots of 600px and 390px renders were reviewed visually (they are in the session scratchpad and not committed).

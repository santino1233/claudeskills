---
name: nxeon-readiness-audit-2026-08-12
description: 8-agent customer-readiness audit punch-list (owner-actions + code fixes + design consistency)
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-12T12:15:09.197Z
---

**2026-08-12 customer-readiness audit** — 8 parallel read-only agents. Full report saved to scratchpad/nxeon-readiness-report.md (also sent to user). VERDICT: core is production-grade (auth/RBAC/IDOR clean, tenant isolation solid, Proxmox/noVNC/terminal solid, money path solid — all prior fixes confirmed live). Gaps are ops + VAT-latent + honesty + design consistency.

**OWNER MUST DO (infra/DNS/decisions — not me):**
- 🔴 BLOCKER: off-site backups NOT configured — `nxeon-backup-offsite.service` fails nightly by design (no target). All backups on ONE box. Set `OFFSITE_RCLONE_REMOTE`/`OFFSITE_RSYNC_TARGET`+`OFFSITE_INCLUDE_VMS=1` in /etc/nxeon/backup-offsite.env.
- 🟠 Email DKIM/SPF/DMARC for nxeon.cloud unverified (app relays via Mailcow 10.20.0.10, doesn't sign; DKIM record was deleted per [[nxeon-dkim-unsigned]]). Live-check mcGetDkimDetails + dig + probe via scripts/diag-email.ts.
- 🟠 Node primary/ns5002569 over-committed: 400GB disk on 339GB pool (118% alloc, 30% real/thin). Add 2nd node or expand pool; stop overselling disk. (The 1 OPEN NodeAlert.)
- DECISION: is business VAT-registered? VAT is INERT today (no country on file, all invoices $0 tax) but armed. Need seller VAT# + seller_country before use.
- External pentest before scaling paid ads.

**I CAN FIX IN CODE (not yet done — get go-ahead):**
- HIGH: failed PROVISION takes money, no auto-refund (worker/index.ts notifyProvisionFailed ~748; reconcileFailedJob ~1196 only reverses RESIZE/DISK_EXPAND). Auto wallet-credit+credit-note on terminal PROVISION fail.
- HIGH: ReviewBadges DEMO_BADGES (Trustpilot 4.9/312 etc) render UNLABELED on homepage+pricing = misleading. Hide numbers until real reviews or add sample tag. (I added them to pricing — my mess to fix.)
- HIGH: VAT armed but ungated + no seller VAT# on invoices. Gate behind VAT-registered flag + seller_country; print seller VAT#; refuse reverse-charge until seller_country set. VAT not reversed on cancel refunds (lib/actions-server-lifecycle.ts refundableTermCents excludes tax).
- HIGH: per-server auto-backups effectively OFF (only 1 server autoBackup=true & it's suspended; live Soul Pilates box autoBackup=false). Host-level nightly vzdump covers VMs but per-server product produces nothing. Default autoBackup ON for paid.
- MED: 6 transactional emails built but never fire (provisioned, suspended, passwordChanged, renewalWarning, domainRenewed, invoiceNew). Wire them.
- MED: currency display-only (Stripe always USD) — lock selector to USD. Wallet deploy path lacks idempotency token (card path safe). VMID-reuse backup exposure — verify pickProvisionVmid wired + old archives (vmids 100-104,8000) reaped, bind tenancy to serverId not vmid.
- MED SSRF (admin-gated): lib/marketing/discovery.ts:237 discoverRss uses raw fetch (no pin/redirect-guard) — route through scrape.ts machinery. LOW: WHOIS referral host, ld+json <-escape, host-only session cookies for site-builder.
- Legal: ToS says "prices exclusive of taxes" (now we collect VAT); no legal entity/VAT#/governing law; no Refund policy page; GDPR export is counts-only not a real export.

**DESIGN CONSISTENCY (make it all one site — gold standard = homepage + pricing):**
- Marketing: ~33 of 56 pages already consistent (3 shared templates). FIX: delete/rebuild app/(marketing)/v2/page.tsx (off-theme, fabricated stats, live URL); fabricated-stats sweep (vps 47s/99.9%SLA, compare, developers eu-central→singapore); rebuild web-hosting + nxcloud on .card/Section size=lg/Reveal delay=i*60/glow-brand; parameterize CtaBand (matrix/migrate/revsports forks); tools/page.tsx:133 double-title bug.
- Portal: add shared Alert primitive (~28 hand-rolled banners); one Tabs component (3 styles); kill setTimeout(reload) feedback; HostingClient+NxcloudClient adopt PageHeader/space-y-6/.section-label; raw bg-brand-500 buttons → .btn-primary.

See [[nxeon-resume-point]], [[nxeon-marketing-design]], [[nxeon-security-audit-2026-08-12]].

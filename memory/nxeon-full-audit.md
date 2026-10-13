---
name: nxeon-full-audit
description: "The 12-area full-line audit of /opt/nxeon (2026-07-27) — what shipped, what's still running, the hazards"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-01T21:00:22.060Z
---

**2026-08-01 second pass (#68, workflow):** ran an 8-area adversarial audit workflow (find → verify, 14 agents). Money / authz / injection / secrets-API came back CLEAN. 4 confirmed + fixed (commit c7c6b2a): (1) HIGH — hosting backup chowned DB dumps to the tenant + restore ran them as MySQL root → cross-tenant DB compromise; now dumps to a root-only dir off the tenant tree, restore replays only `${u}_*` DBs. (2) MED — reapStuckJobs leaked the dedicated IP + OVH vMAC on a final-attempt PROVISION; shared `cleanupFailedProvision` on both fail paths. (3) LOW — terminal PROVISION nulled `ipAddress` for NAT servers whose VM still holds it → bridge IP collision; now only cleared for dedicated. (4) LOW — served-cert SSL probe SSRF; new `lib/net-guard.ts` blocks RFC1918/loopback/metadata, probe resolves-then-refuses-internal + connects to the vetted IP. 2 findings refuted (SSL rate-limit counter; dedicated-IP claim race). Test count → 852.

---

The user asked to audit EVERY line of the Nxeon platform (618 ts/tsx files,
~135k lines) for bugs, security, correctness — "finish everything, stop asking
for approval". Partitioned into 12 areas, run as background subagents with
NON-OVERLAPPING file ownership, landed centrally (I build + deploy + commit; the
agents never deploy). Test count climbed 294 → 541+ over the audit.

**Committed & deployed (all green, tsc + build clean each time):**
- `23811b8` wave 1 (6 areas): cross-tenant backup restore via recycled vmid;
  Stripe read-failure → silent "top-up fulfilled" with no server; every per-IP
  rate limit spoofable via `x-forwarded-for` first hop (nginx APPENDS, so the
  first hop is attacker-authored — fixed with `clientIp()` in lib/rate-limit.ts);
  retried reinstall destroyed the server; session/impersonation cookies
  interchangeable; SSRF into the customer fleet via migration scan.
- `89ff018` wave 2 partial + recovered 5 interrupted agents + fixed a VACUOUS
  test stripper (`stripCommentsAndStrings` wasn't regex-aware, so a regex with a
  quote in a character class blanked the whole file — every tripwire over such a
  file passed against nothing).
- `3d8201f` mail: `removeMailbox`/`setMailboxSuspended` swallowed Mailcow errors
  and deleted the row → live mailbox still receiving mail. Now
  `isMailcowUnreachable(e)` distinguishes REFUSED (keep row, surface error) from
  UNREACHABLE (proceed + warn).
- `963ea21` encrypt `smtp_pass` at rest (last plaintext secret); fix two
  now-false honesty notes.
- `5c2c7c1` `serverAction` returns `{error}` instead of throwing (Next redacted
  it) / silent no-op.

**Running as of ~09:47 UTC (the 3 audits killed by the earlier session limit):**
migration engine (worker/migrate*.ts), customer portal (app/dashboard,
components/customer), admin portal (app/admin, components/admin). Relaunched after
the 08:20 UTC reset.

**Standing rules for this work, all learned the hard way:**
- Every fix ships a test PROVEN to bite (revert in place → red → restore). "A
  guard nobody has seen fail is not a guard."
- Source tripwires use `stripCommentsAndStrings` (test/_source-tools.ts), never a
  raw grep — a naive match hits the repo's own incident comments and passes on
  broken code. I fell into this twice myself.
- `next build` catches what `tsc` cannot (client component pulling nodemailer into
  the browser bundle; a sync export in a `"use server"` file). ALWAYS build before
  deploying. CI does not run `next build`.
- `"use server"` = every export is a public network endpoint; guards must be
  INSIDE the function. See [[nxeon-platform]].
- NEVER run a standalone script from a tree with symlinked node_modules — Prisma
  resolves its schema to /opt/nxeon and loads /opt/nxeon/.env (production DB + live
  sk_live_ + real Proxmox creds). An agent seeded production that way this week; no
  damage, but it's the sharpest hazard.

Still the user's: publish `dkim._domainkey.nxeon.cloud` (see [[nxeon-dkim-unsigned]]),
set an off-site backup target, `prisma db push --accept-data-loss` on staging.
Related: [[nxeon-platform]], [[nxeon-resume-point]].

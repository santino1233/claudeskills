---
name: nxeon-dkim-unsigned
description: "RESOLVED 2026-08-22 — dkim._domainkey.nxeon.cloud resolves correctly again (verified via public resolver). Kept for the incident lesson."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-22T19:56:35.327Z
---

**UPDATE 2026-08-22:** verified live via a public resolver (`host -t TXT dkim._domainkey.nxeon.cloud 1.1.1.1`) — the record is present and correct (2048-bit RSA, selector `dkim`). SPF (`v=spf1 mx ~all`) and DMARC (`v=DMARC1; p=none`) both present and sane too. Email deliverability (SPF/DKIM/DMARC) for nxeon.cloud is healthy as of today — no longer an open item. The incident lesson below stays relevant for future DNS work.

On 2026-07-25 I told the user to delete three `nxeon._domainkey` TXT records without
warning that `dkim._domainkey.nxeon.cloud` — Mailcow's real signing key — had to
stay. As of 2026-07-26 that name returns **NXDOMAIN**, so every transactional email
the platform sends is signed with a key receivers cannot look up.

**Why:** I made the same class of mistake three times on this one problem. First I
installed OpenDKIM on the Proxmox host when mail actually flows through the Mailcow
appliance (VM 8000, `MAILCOW_API_URL=https://mail.nxeon.cloud/api/v1`) — I should
have read the `Received:` headers before touching anything. Then I gave the user a
DKIM value with the wrong selector, then my own OpenDKIM key under the right name.
Then the cleanup instruction deleted the genuine record. Each error came from
reasoning about where mail *should* originate instead of checking where it *does*.

**How to apply:**
- Mail is Mailcow's, not the host's. Get DKIM from the live API, never generate it:
  `curl -H "X-API-Key: $MAILCOW_API_KEY" "$MAILCOW_API_URL/get/dkim/<domain>"` →
  the `dkim_txt` field, selector `dkim`, 2048-bit. Publish that verbatim.
- Never verify PTR or DKIM through the local resolver. `/etc/hosts` plus
  `nsswitch: files myhostname dns` made this box answer its own reverse lookups from
  a local file, and I twice told the user their rDNS was broken when it was correct.
  Query a public resolver or the authoritative NS: `host -t TXT <name> 1.1.1.1`.
  `dig` is NOT installed on this host; `host` is.
- Before telling the user to DELETE any DNS record, enumerate what currently exists
  and name what must survive. A deletion instruction that lists only what to remove
  is missing half its content.

Related: [[nxeon-platform]], [[nxeon-resume-point]]

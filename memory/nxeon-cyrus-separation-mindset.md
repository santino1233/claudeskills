---
name: nxeon-cyrus-separation-mindset
description: Owner decision 2026-10-10: Cyrus stays inside Nxeon for months (no separate logins, nothing breaks) but is built so it can later become its own product; the "host seam" rule
metadata:
  type: project
---

Cyrus will eventually become its own product, but for at least a few months it stays part of Nxeon (same sign-in, accounts, wallet, billing) so it can gather real Nxeon-customer usage data and a solid foundation first. **Do not build separate logins or anything that changes the current customer experience for this.**

**Rule for all new Cyrus code:** reach Nxeon only through a small host seam (user/sign-in, plan+billing, server access for install, storage, notifications); no new direct imports of Nxeon internals (use a named adapter if unavoidable); Cyrus tables stay `Cyrus*`-prefixed with opaque user/server ids and no new foreign keys into Nxeon tables; keep engine core, asset pipelines, Test Flight, pack hosting game- and host-agnostic. Later split = Nxeon exposes an API (list servers, push plugin/pack/config, restart) like the Kodely partner API pattern ([[nxeon-kodely-partner]]); standalone Cyrus gets its own sign-in, wallet, DB, and a jar/pack export.

**Why:** the owner wants it to "stand on its own feet" eventually without risking the live product now.
**How to apply:** put this rule in every Cyrus agent brief; see MASTER-PLAN.md section 2b in /root/agent-notes/cyrus-research/. Related: [[nxeon-cyrus-master-plan-2026-10-10]].

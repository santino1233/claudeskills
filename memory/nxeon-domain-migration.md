---
name: nxeon-domain-migration
description: How to migrate Nxeon to its real domain (currently placeholder revsports.ca)
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-07-23T11:48:40.406Z
---

[[nxeon-platform]] currently runs on the PLACEHOLDER domain `revsports.ca` (customer = apex, admin = `4j3d7gkr2wcbi34.revsports.ca`, staging = `staging.revsports.ca`). The user will buy a real domain later and wants migration to be painless with nothing hardcoded.

**Why:** The user explicitly said "dont hardcode this revsports anywhere ... i dont want anything to mess up when we migrate."

**How to migrate when the real domain is bought:**
1. Point DNS A records at 51.79.162.96 for: apex, `www`, the admin subdomain, and `staging`.
2. Edit `/etc/nxeon/domains.env` (BASE_DOMAIN, ADMIN_HOST, STAGING_HOST, CERTBOT_EMAIL) — the ONLY place the domain lives.
3. Run `/opt/nxeon/scripts/configure-domains.sh` — regenerates nginx vhosts, obtains new Let's Encrypt certs, updates APP_URL + NXEON_ADMIN_HOST in both `.env`s, restarts web.
4. Update the Stripe webhook URL in the Stripe dashboard (or re-create) to the new domain; the app reads APP_URL so checkout redirects follow automatically.

The app code never contains the domain — it flows from `APP_URL`/`NXEON_ADMIN_HOST` env and generated nginx config. Keep it that way: if you ever need the domain in code, read it from env, don't inline it.

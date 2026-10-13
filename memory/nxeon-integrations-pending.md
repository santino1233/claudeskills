---
name: nxeon-integrations-pending
description: "Nxeon integrations that are coded but need the user's credentials to activate"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-07-23T11:13:45.984Z
---

These [[nxeon-platform]] integrations are fully built but dormant until the user supplies credentials in `/opt/nxeon/.env` (and `/opt/nxeon-staging/.env` for staging):

- **Stripe** — needs `STRIPE_SECRET_KEY` + `STRIPE_WEBHOOK_SECRET`. Webhook endpoint: `http://51.79.162.96/api/stripe/webhook`, event `checkout.session.completed`. Until set, wallet top-ups fall back to an instant demo gateway.
- **Namecheap** — needs `NAMECHEAP_API_USER/API_KEY/USERNAME`, and the server IP 51.79.162.96 whitelisted in the Namecheap account. `NAMECHEAP_SANDBOX=1` for testing. Drives domain search/register/renew/DNS.
- **GitHub auto-push** — run `/opt/nxeon/scripts/setup-github.sh <remote-url-with-token>` once; the post-commit hook then pushes every commit.

**Why:** The user explicitly asked for Stripe payments, Namecheap domain support, and automatic GitHub pushing. **How to apply:** When the user provides any of these, add to the relevant `.env`, restart the service (`systemctl restart nxeon-web`), and verify (Stripe test event / Namecheap sandbox / a test commit).

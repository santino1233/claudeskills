---
name: nxeon-sandbox
description: "Comped sandbox customer account for making content + testing (VPS + game servers, on-demand, one IP)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-17T17:37:31.727Z
---

**Nxeon sandbox account** (created 2026-08-17) for the owner to make content + test on the LIVE platform without cost or an extra IP.

- **Login:** `sandbox@nxeon.cloud` / `Sandbox!Nxeon26` (id `cmsxims400000hle9x0bjjf1v`, role CUSTOMER, email pre-verified). **Advise the user to change this password.**
- **Comp:** `balanceCents = $50,000` + `signupCreditCents` — so ALL VPS + game orders are FREE (checkout charges the wallet; `lib/game-order.ts:233` + `lib/order.ts:612` pay from balance; auto-renew also pays from balance → **never dunned/suspended**).
- **Usage:** log into the customer portal, order any VPS plan or game server (every title has plans — Bedrock 1 GB is the lightest), **start/stop/delete on-demand**. Nothing runs at rest → near-zero resources. Run heavy games (Rust/ARK, 4–6 GB+) only while filming; host has ~28 GB free so keep to 1–2 running at once.
- **No extra IP:** everything rides the single public IP `51.79.162.96` via NAT (vmbr1 `10.20.0.0/24`) — host nginx reverse-proxy for web, port-forward for SSH + game ports. This is how the whole platform already works.
- **SHARED HOSTING = HELD:** `ENABLE_SHARED_HOSTING` is on, BUT [[nxeon-security-audit-2026-08-12]] says a CRITICAL DB Studio RCE exists and "DO NOT onboard a 2nd hosting customer until it's promoted." Confirm that RCE is fixed/promoted BEFORE ordering a sandbox shared-hosting account (it shares the hosting node). VPS + game servers are their own isolated VMs and are safe.
- Related: [[nxeon-platform]], [[nxeon-server-topology]], [[nxeon-security-audit-2026-08-12]].

---
name: nxeon-ovh-ip-zone-check
description: "When ordering a new dedicated/failover IP from OVH for Nxeon's server, always verify the datacenter zone matches before checkout"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-26T12:52:17.023Z
---

Before placing any OVH IP order (cart checkout), verify the cart item's actual `campus`/`regions` field matches the dedicated server's real datacenter — do not pick a plan code by price/label alone (e.g. `ip-failover-arin` sounds generic but silently defaulted to `ca-east-bhs`, Canada).

Nxeon's dedicated server (`ns5002569.ip-51-79-162.net`) is in **campus SGP (Singapore)**. Any additional IP ordered for it must also land in SGP or it's physically unusable — OVH will refuse to move an IP across zones after the fact (`403: DC destination is not in same zone`).

**Why:** On 2026-08-26, ordered a $2.39/mo failover IP to fix a customer server's IP collision, picked `ip-failover-arin` without checking zone, and it delivered in BHS (Canada) — completely unusable, wasted recurring spend until cancelled/swapped via OVH support. The user corrected this directly: "for future orders, you need to make sure to attach to the right server/zone."

**How to apply:** When calling the OVH cart API (`lib/ovh.ts`'s `ovh()`/`ovhApi`) to order an IP, after adding the item to the cart, fetch `GET /ip/{address}%2F32` (or the pre-checkout cart item detail) and confirm `campus === "SGP"` / `regions` includes `ap-southeast-sgp` before ever calling checkout. If unsure which plan code lands in the right zone, check the cart catalog response (`GET /order/cart/{cartId}/ip?serviceName=...&country=...`) for the specific SGP-zoned plan before adding to cart, rather than guessing from the product name.

See also [[nxeon-platform]] for the broader server topology (single Proxmox host, SGP-based).

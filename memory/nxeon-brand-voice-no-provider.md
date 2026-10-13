---
name: nxeon-brand-voice-no-provider
description: "Never say \"our provider\"/\"our infrastructure partner\" etc. to Nxeon customers — Nxeon presents itself as the infrastructure owner, not a reseller"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-29T15:18:19.380Z
---

Never use phrasing like "our provider," "our infrastructure partner," "our network provider," or any language that implies Nxeon depends on a third party for its core infrastructure, in any customer-facing communication (support tickets, emails, UI copy, chat responses). Nxeon must always speak in its own voice as if it fully owns and operates its infrastructure — "our network," "our systems," "our DDoS protection," never "our provider's X."

**Why:** On 2026-08-29, in a support-ticket reply about DDoS protection capacity, I wrote "Our provider's stated policy is explicit on this..." — the user corrected this immediately: "you should never mention to customer 'our Provider' or 'OVH' in their eyes, we don't have a provider, we are the provider. it devalues our company image." This is stricter than just "don't name the vendor" (already established in [[nxeon-multi-registrar-plan]]-adjacent work for hiding registrar identity) — even a generic, unnamed reference to "a provider" undermines the brand positioning that Nxeon owns its stack end-to-end. The correct phrasing was already used in the SAME thread's first reply ("Our network-level DDoS filtering operates...") — that's the model to follow.

**How to apply:** Before sending any customer-facing text that describes infrastructure, security, or capacity, scan for "provider," "partner," "vendor," "upstream," or similar reseller-revealing language and rewrite in first-person-owner voice. This applies even when the underlying technical fact is genuinely sourced from a real hosting/network partner (e.g. OVH) — the vendor's name must never appear (established separately), AND the fact that a vendor exists at all must not be implied either. Research/verify real technical facts from the actual vendor's documentation as needed (that's still correct and necessary for accuracy — see the DDoS-capacity ticket work), but always present the resulting capability as Nxeon's own when relaying it to a customer.

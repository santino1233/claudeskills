# bm-ops audit notes (2026-10-08)

Worktree `/tank/dev-worktrees/bm-ops`, branch `feature/bm-ops`. Full write-up in
`docs/DOCUMENTATION.md` -> "Bare Metal release hardening". Checklist: `RELEASE-CHECKLIST.md`.

## 1. Order to delivery, as built (traced in code)

quote (`quoteDedicatedOrder`, re-priced from DB at Review and at Pay) -> `payDedicatedOrder`
(gate, impersonation block, email verification, rate limit, acknowledgement, real-funds split) ->
wallet: `placeDedicatedOrder` (order-key claim in FulfilledSession, spend cap, `debitRealFunds`,
PAID invoice, PENDING server, event, audit, one transaction) | card: Stripe Custom Checkout with the
intent + stamped price in metadata -> `fulfil-checkout` credits the card leg, `placeDedicatedOrder`
debits the STAMPED total (stock not re-checked: the card already cleared) -> PENDING ->
staff buy the machine by hand + save service name -> "Install & hand over" (HANDOVER job: install
the ordered OS with the customer's first SSH key, poll install status, ACTIVE, IPs, notify + email).

- Never ordered before paid: yes (nothing orders upstream automatically at all).
- Money never lost: a failed card-leg placement leaves the money in the wallet (FAILED settle +
  stalled notice); a failed wallet placement rolls back and releases the claim.
- Idempotency: order key (client) + FulfilledSession claim + Stripe session claim. Tested.
- Price drift quote -> charge: the charge uses the stamped/fresh quote; drift only matters for our
  cost vs the supplier (admin-only `costMonthlyCents` frozen at order).
- Stock disappearing mid-checkout: wallet path refuses (re-quote with requireStock); card path
  places the order anyway (the card cleared) and staff handle it: correction NOT_DELIVERED if they
  can't source it.
- Gaps found and fixed: jobs stuck RUNNING forever after a worker restart; IP order stuck ORDERING
  after a job timeout; no renewal automation at all; no stuck-order alert; the panel waited on the
  supplier; IP mock routed to the wrong server.
- Gap NOT fixed (blocked): automatic upstream purchase of the machine after payment (the write was
  refused by the safety classifier because it spends money on the live supplier account).
- Gap NOT fixed: HANDOVER needs the customer's SSH key; a customer with no key gets credentials by
  hand (staff "Credentials" form). Suggest: require an SSH key at checkout (wizard) or generate a
  one-time root password delivered encrypted.

## 2. IP purchases

Flow: customer quotes 1/4/8 IPv4 (`dedicated_ip_price_cents`, prorated to the next renewal) ->
pays real funds then card -> `DedicatedIpOrder` PAID + PAID invoice -> ADMIN "Approve purchase" ->
IP_ORDER job: cart, assign, IP product for the size, `destination` = this server, `country` = the
region's country, checkout (account payment method), wait for delivery, add the new block to the
server, add the monthly price to `renewalMonthlyCents` + `extraIpMonthlyCents`. Works end to end in
the mock (DB test). `DedicatedIp` (the model) is the VPS pool, not bare metal.

| Supplier panel IP feature | Ours | Gap / severity |
|---|---|---|
| Order additional IPv4 (single, blocks) | 1, 4, 8 (admin-approved) | Larger blocks: low |
| Choose IP geolocation/country | Fixed to the server region's country | Low |
| IPv6 block included | Shown | none |
| Reverse DNS IPv4 | Yes (single IPs) | Addresses inside a /30 or /29 block can't be set in the UI: medium |
| Reverse DNS IPv6 | No | Medium |
| Network firewall (on/off, 20 rules) | Yes, IPv4 singles | Blocks' addresses: medium |
| DDoS mitigation (auto/permanent, stats) | Not shown | Medium (marketing claims always-on) |
| Virtual MAC (VMs on extra IPs) | ADDED in this branch (create + list) | Delete a vMAC: low |
| Move an IP between own servers | No | Low |
| Release/terminate an extra IP | No: once added it stays in the renewal | Medium (customer can't stop paying for it) |
| Anti-spam/anti-hack unblock | No (alerts exist for platform IPs) | Low |

## 3. Parity with the supplier's own panel

| Capability | Supplier panel | Ours | Severity |
|---|---|---|---|
| Hard reboot | yes | yes | - |
| Power off/on | no (API has reboot only) | no | - |
| Rescue boot | yes | yes (SSH key) | - |
| Reinstall OS | templates, custom partitions, post-install script, own image | templates + hostname + SSH key | Medium (partitioning/RAID layout) |
| KVM / IPMI / Serial-over-LAN | hosted console | ticket: staff open it | High (no self-serve recovery from a broken network; supplier console is on the supplier's domain, so it can't be passed through as is) |
| Monitoring + technician intervention | yes (ping monitoring toggle) | no | Medium |
| Traffic graphs (MRTG) | yes | "coming soon" | Medium |
| Hardware/RAID info | yes | detected hardware summary | Low |
| Free backup storage (FTP) | yes | no | Medium (supplier hostnames would leak) |
| Private network (vRack) | yes | filtered out of the catalogue | Low (not sold) |
| Bandwidth upgrade after order | yes | no | Low |
| iPXE / custom boot scripts | yes | no | Low |
| Secondary DNS | yes | no | Low |
| Task/intervention history | yes | our job list (Recent actions) | Low |
| Hardware replacement request | yes | support ticket | Low |
| Renewal/auto-renew, termination | yes | ADDED: auto-pay (owner switch), cancel at period end | - |

Implemented here (small and safe): virtual MACs. Everything else is written up.

## 4. Decisions for the owner

1. Automatic upstream ordering (true auto deployment) needs explicit permission: it spends money
   on the supplier account. Proposed safeguards: price check before checkout with a max drift %,
   cart description tied to our order id, never a second checkout once an order id exists,
   dry-run default, owner switch default off, admin hold when the price is above expectations.
2. Turn on auto-pay renewals (`dedicated_autorenew_enabled`) and confirm grace (3 d) / end (10 d).
3. Gift codes count as promotional credit (conservative). If gift codes are bought with real money
   by someone else, they could be allowed: say so.
4. Positive admin balance adjustments count as promotional (goodwill). Real billing corrections on
   bare metal go through the new Billing correction.
5. Promotional credit is treated as never used up (safe bound). If you want customers who spent
   their credit on other products to get it back as spendable, a per-account consumption ledger is
   needed (bigger change).
6. Partner commission on bare metal invoices is now excluded (no program was ever defined for it).
7. Admin pricing can still sell below cost (negative markup / override below cost / setup waived).
   A cost floor was tried and reverted (it changed tested pricing behaviour): decide if you want one.
8. Terms wording (`DEDICATED_TERMS_SECTION`), including "a chargeback suspends the server".
9. SSH key requirement at checkout (handover can't run without one).

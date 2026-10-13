# Cyrus mod networking: roll-out plan

Everything is **OFF** today. Nothing on `feature/cyrus-v6-capabilities` changes the build service's behaviour or what
any customer sees: the manifest validator is not called by the pipeline, the wrapper is a stub that is not in the
image, the gateway answers 503 (off) / 501 (stub), and the install gate only affects builds that carry a manifest
(none can today).

## 1. Switches

| Level | Switch | Effect |
|---|---|---|
| Global | `cyrus_mod_networking_enabled` (default `false`) | off: networking mods cannot be installed (403 `networking_off`); the portal must not ask the service for networking builds |
| Global | `cyrus_ai_gateway_enabled` (default `false`), `cyrus_ai_gw_kill` (default `false`), `cyrus_ai_gw_platform_daily_cap` (default `0`) | AI gateway off / paused / capped |
| Build service | a service env flag (planned, phase 1), default off | second, independent gate: the service only builds with the wrapper when both the request and the env allow it |
| Per customer | planned: an account flag so networking can be withdrawn from one customer | |
| Per mod | Mods-tab disable (exists); planned: a Nxeon revocation list the wrapper honours, so one bad community mod can be cut off everywhere | |
| Per mod, AI | owner's `aiEnabled` and daily budgets (default off / 0) | AI-GATEWAY.md |

## 2. Phases (each needs the owner's approval to start)

0. **Now (this branch):** design, manifest + validation (TS and JS, parity-tested), consent component, install gate,
   settings, budget maths, stubs. Merge is safe: everything is inert.
1. **Security review + wrapper + scanner** (human reviewer, section 4). Then wire `capabilities.js` into the build
   pipeline behind the service env flag; prompts describe the wrapper only when the flag is on. Ship as the next
   service version on the build VM with the flag off; rollback = previous image tag.
2. **Private preview:** networking on for preview accounts only, a short list of pre-approved hosts (for example
   Discord webhooks, one weather API); every networking build listed in admin.
3. **Customers:** own servers only, consent required, admin list of networking mods, community publishing of
   networking mods still off.
4. **Community:** networking mods may be published but enter a **review queue**; a version that changes the manifest
   re-enters it; no community seal on unreviewed networking mods.
5. **AI gateway:** storage, charging, moderation (AI-GATEWAY.md), preview first, platform cap small.

## 3. Admin visibility (to build in phase 2)

- A list of every build and published mod whose `result.capabilities` is set: hosts, player-data categories, AI,
  installs, owner; filter "declares IP addresses" and "community".
- The review queue (approve / reject per manifest hash).
- AI spend for the day against the platform cap (`meter()`), and the kill switches on one page.

## 4. For the human security reviewer (scope only)

Please cover, before phase 1 ships:
1. The build service's static safety scan: whether it covers every way plugin code could reach the network, run
   other programs, load code at runtime, or reach outside its own folder, and whether it inspects all symbolic
   references in the compiled classes. Decide whether to move from a block-list to an allow-list of APIs.
2. The wrapper's transport, once written: TLS and certificate handling, how destinations are checked against the
   declared hosts and against private/internal/Nxeon address ranges (including after redirects and repeated lookups),
   limits and timeouts, header handling, logging, kill switches, and that plugin code cannot alter or impersonate it.
3. How the service adds the wrapper to a jar and proves the copy is unmodified.
4. The manifest policy (`net-policy.json`): deny-list completeness, and the list of Nxeon address ranges to block
   (owner to supply node, failover and customer IP ranges).
5. The AI gateway: token issuance, storage and revocation, budget atomicity under concurrent calls, moderation.
6. Data handling of player data and customer secrets end to end, including community forks.

Adversarial test material is the reviewer's to write; this branch has only benign fixtures.

## 5. What the owner must approve

- Merging this branch (inert).
- The deny-list and the per-mod free limits in `net-policy.json`.
- Engaging the security reviewer and the Nxeon IP ranges list.
- Each phase above, separately; turning on `cyrus_mod_networking_enabled` only after phase 1 is reviewed.
- For AI: the gateway model and its price, the platform daily cap, and the ledger reason in the economy.

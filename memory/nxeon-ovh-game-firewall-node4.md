---
name: nxeon-ovh-game-firewall-node4
description: "node-4's OVH \"game firewall\" strict mode silently dropped all UDP except port 20055 until turned off 2026-10-04; check this first when a UDP game server on an OVH node is unreachable from outside but healthy locally"
metadata:
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-10-04T13:20:47.229Z
---

On 2026-10-04 Duy Khang's L4D2 server (and every UDP game on node-4: Valheim, Rust, Core Keeper, Bedrock) was unreachable from the internet. Cause: OVH's per-IP **game firewall** (`/ip/139.99.125.21/game/139.99.125.21`) had `firewallModeEnabled=true` with ONE hand-added rule (`other:20055-20055`, Palsauge's old port). In strict mode OVH drops every UDP port not listed, at the provider edge, so nothing ever reached the node. Nobody on the platform manages these rules (lib/ovh.ts has no game-rule helper), so every UDP server added to node-4 afterwards was silently blocked.

**Why:** the primary's own traffic got through (its probes worked) which made the server look healthy; probes from node-2/3/5 got no reply, and a live `tcpdump -i any` on node-4 showed the packets never arrived at the NIC. That is the tell for an upstream filter.

**How to apply:**
- Owner approved turning strict mode off on 2026-10-04 (`PUT /ip/{ip}/game/{ip} {firewallModeEnabled:false}`, takes ~1 min to go from `firewallModeDisablePending` to `ok`). Verified after: L4D2 + Valheim answer from node-2/3/5. Primary has it off; node-3/5 have no game object; node-2 is Hetzner (not OVH).
- When a new OVH node or IP is added, read `/ip/{ip}/game` and its rules before blaming the game or the guest. Diagnose with probes from several vantage points plus a live capture on the node, not just from the primary.
- Related: the primary's role `NxeonProvisioner` lacked `VM.Config.Options` (fixed 2026-10-04), which made any provision on the primary fail with a 403.
- Duy Khang's "I can't connect" ticket follow-up reply still needs owner sign-off ([[no-ticket-replies-without-approval]]).

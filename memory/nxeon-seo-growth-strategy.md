---
name: nxeon-seo-growth-strategy
description: "Nxeon's real growth picture (ChatGPT is #1 channel, conversion is the bottleneck) + the proven SEO content template"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-09-22T12:54:55.755Z
---

Big analytics + SEO expansion effort on 2026-08-31 (7,999-visit deep-dive + live SERP research across all product lines). Full deliverable is an artifact ("Nxeon SEO Expansion Pack", 📈). Durable findings:

**The reframe — it's a conversion problem, not a traffic problem:**
- **ChatGPT is the #1 acquisition channel: 52% of first-touch marketing visits** (vs 6.9% Google organic). 6 of 9 paying customers had a ChatGPT signal. So **GEO / AI-assistant citation is the primary SEO lever**, not classic Google ranking. ChatGPT cites the free tiers most — **MEASURED 2026-09-22 from the Visit table**: entry visits referred by ChatGPT are led by /free-minecraft (140) and /free-vps (128), then game hosting pages (/minecraft-server-hosting 38, /valheim 21, /project-zomboid 8, /fivem 7, /dst 7). **The "and the free tools" half of this was WRONG.** All 16 tools together have ~77 pageviews all-time and 14 ChatGPT entries. The only two with any pull are the game/server-adjacent ones (/tools/latency-test 29 views, /tools/minecraft-server-status 11); the 14 generic devops tools (whois, base64, uuid, hash, json, subnet…) are ~37 views combined, i.e. noise. Do not justify building more free tools on a "ChatGPT cites tools" premise — this data does not support it.
- **95.5% of signups never buy** (200 signups → 9 paying = 4.5%). Free tiers acquire beautifully but have NO free→paid bridge. Signups jumped ~20/wk → 155/wk when free tiers launched.
- **~97% of deploy-wizard opens are abandoned**, all at step 2 (right after plan select) — intimidation, not bugs.
- Mobile = 36% of traffic but ~0% of buyers (buyers 97.7% desktop) — mobile-checkout audit needed.
- Biggest real audience is US (far from the Singapore DC); SEA markets near the DC (Philippines/Indonesia/Malaysia) + Singapore itself are underexploited — a positioning opportunity.
- ~~Minor bug found: `VisitorDaily.bounces` is 0 across all rows (rollup not populating it).~~ **RESOLVED, verified 2026-09-22**: bounces is populating correctly (e.g. 30-97/day this week) — already fixed by the time of that check, root cause not tracked down.

**The proven SEO content template (from GSC data):** "the closer a keyword sits to 'runs on a server,' the easier it ranks AND the better it converts." Server-side/hosting-adjacent content (plugins, server settings, performance mods, "how much RAM", seeds) is owned by beatable PEER hosts (Shockbyte/Apex/WinterNode tier), not mega-authority. Client-side/cosmetic (texture packs, shaders head-term, data packs) is owned by content giants — avoid. The **"Best [game] mods for 2026"** exact-phrase template already ranks page-1 for Nxeon; lane is filling with peers so win on depth + freshness (tie to live 2026 game updates).

**Top content priorities:** (1) AI/vibe-coding hosting (host Bolt/Lovable/v0/Cursor apps, deploy AI agents, self-host LLMs) — biggest untapped growth, Nxeon's Claude builder makes it native; (2) "self-host [app] on a VPS" page factory (~30 apps vs current ~10); (3) Minecraft server-side template (plugins first); (4) free-MC/Aternos-alternative funnel ("24/7, no queue, no ads"); (5) survival-games template (Valheim/Conan/Palworld/Rust verified).

**New games to add (verified host-owned SERPs):** Schedule 1 (top), RuneScape Dragonwilds, Sunkenland, Abiotic Factor, Core Keeper, Icarus — **ALL SIX SHIPPED**; catalogue is 42 live families as of 2026-09-22. NOT addable: Pax Dei. ~~Dune Awakening (official-shard only)~~ — **CORRECTED 2026-09-22**: Funcom announced self-hosted dedicated servers in their April 2026 dev update and shipped them 19 May 2026. G-Portal, BisectHosting and xREALM all sell it today, so the "official-shard only" note was stale and was blocking a real opportunity. Re-verify before trusting any "not addable" entry here — game publishers reverse these decisions. **Plutonium/CoD private servers** (Plutonium, BOIII, X Labs family) = real demand + thin SERP BUT reverse-engineered clients in a legal gray area (Activision C&D'd H2M-Mod 2024) — owner's risk call; frame as "Plutonium/BOIII hosting" not "Call of Duty hosting".

**Related:** [[nxeon-chat-agent]] (the ChatGPT-citation surface is the same KB the live-chat bot uses), [[nxeon-blog-seo-batch]], [[nxeon-marketing-design]].

**Owner decisions gating parts of the plan:** Windows VPS? (forex cluster), GPU? (Stable Diffusion/large-LLM), free-migration confirm (/migrate pages).

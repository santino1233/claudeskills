---
name: nxeon-cyrus-design-feedback
description: "Owner's design verdicts on Cyrus (AI mod studio) v1/v2 and the rules for v3 — premium standalone product, not blue/purple glow"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-10-07T10:12:35.123Z
---

Cyrus = Nxeon's AI mod studio (route /dashboard/cyrus, preview-gated to the owner; branch feature/cyrus-modbuilder; build service on VM 88001, image modbuilder:0.4). v1 = "looks cheap", card-in-a-page. v2 (Nexus spiderweb from workspace.trynxeon.com, full-page) = "UI mostly okay but still cheap, hard to read, everything way too blue and purple, background not good, vibe-coded styling, light mode doesn't work, 'Built with Cyrus' badge looks like AI shit, icons are trash, needs a game selector". Owner then asked for a **cybernetic cyberpunk space** theme (v3 = POLISH v2 in place, owner likes the v2 UX/layout — "no need to create the entire system again").

**Why:** owner wants to be able to sell Cyrus as a standalone product; anything that reads as an add-on or "AI-generated UI" is rejected.

**How to apply:** for Cyrus (and likely other flagship UI): full-page app (only the portal rail + top bar around it); near-neutral base + ONE accent, WCAG-AA text contrast; no glow/gradient/glass on everything, no gradient text, no sparkle badges; one consistent icon system; light mode must genuinely work (not a dark island); game selector is a first-class, data-driven registry (Minecraft live, others "coming soon"). Show style tiles before a full rebuild. Related: [[nxeon-redesign-generic-drift]], [[nxeon-ai-modbuilder]], [[nxeon-model-split-preference]].

**Queued (owner, 2026-10-07):** a Cyrus marketing page (lots of SEO, animations, real product screens) — start only AFTER the Cyrus system design polish is finished and approved.

**2026-10-07 update — v3 (graphite + lime "cyberpunk") REJECTED: "not in sync with Nxeon at all".** Owner supplied a concept image: /root/agent-notes/cyrus-v4/owner-concept.png — match it as closely as possible. Nxeon navy/violet/magenta/cyan neon IS wanted when done with polish (the earlier "too blue/purple" complaint was about cheap execution, not the palette). Hierarchy: Cyrus core → game nodes → mod-category nodes → mod nodes, aurora/neon threads in space, custom neon SVG icon set, Projects in the portal sidebar, Cyrus Pro upgrade card, composer tabs Chat/Generate/Debug/Refactor/Docs, inspector Code/Explain/Versions/Files/Notes + Deploy Mod. No official game logos (original emblems instead) unless the owner supplies licensed ones.

**v4 feedback (2026-10-07):** keep the REAL portal sidebar + top bar (concept was about the mod interface, not the chrome — "took the design too literally"); v4 colours too washed out vs concept, especially branches + core → need concept-level saturated neon with real bloom. Tokens: only games Cyrus supports earn grants (registry-driven).

**2026-10-07 later:** owner: v4b "is worse than v2, start from scratch". Owner will design Cyrus in their OWN LOCAL Claude session and Claude ports the result into the portal; keep v4b live meanwhile; nothing from v2 needs to be kept (features only). Token UI is being kept as isolated components + UI-CONTRACT.md so the new design can wire it in.

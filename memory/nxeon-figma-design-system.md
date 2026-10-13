---
name: nxeon-figma-design-system
description: "Building Nxeon's UI/UX into Figma (design system + site flow) — hit Starter-plan MCP rate/page limits, considering alternatives"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-26T18:58:32.934Z
---

Goal: get Nxeon's real UI/UX into a shared visual tool so future design work has an actual source of truth instead of screenshots and descriptions (see [[nxeon-redesign-generic-drift]] for why that matters).

**State as of 2026-08-26:**
- Figma MCP connector authenticated as Grant Wilson (iwizardhax2.0@gmail.com), team "Grant Wilson's team", **Starter plan, View seat**.
- Subagents (the Agent tool) do NOT inherit the main session's Figma OAuth — every subagent dispatched to do Figma work failed immediately on auth. Figma work must be done directly in the main session.
- Built so far in file "Nxeon Design System" (fileKey `hySoLkhZq3odcE8A8LDcTa`): real color variables (19, extracted from `app/globals.css`'s actual `@theme` tokens, not guessed), a full Geist type scale (10 text styles), a Button component set (Primary/Secondary/Disabled, real 4-stop brand gradient), a Card component (Default/Hover), a TrustBar component.
- Started a second file "Nxeon Site Flow" (fileKey `DmNc3WMlvicAFvB4eaeN6f`) to lay out real pages as connected full-screen frames (homepage → deploy → plan → payment → review) per the user's request for "proper full screen flow," not just isolated captures — only the homepage nav bar landed before hitting limits.
- **Hit two real Figma Starter-plan limits**: (1) 3 pages max per file — forced the site-flow work into a separate file; (2) a hard MCP tool-call rate limit that fully blocks further `use_figma` writes (confirmed via retry with a trivial no-op call) until it resets or the plan is upgraded. Reset window unknown — Figma's own rate-limit doc wasn't readable from available tools.
- No `generate_figma_design` pixel-capture tool exists in this connector (the `figma-generate-design` skill assumes it does) — every page must be manually rebuilt with `use_figma` from a real screenshot reference, which is much more labor-intensive than a true "capture the whole site" would be.

**Alternatives discussed, not yet decided:** Penpot (free/self-hostable, but no Claude skill exists for it — would mean raw REST API work with no guardrails), Claude's own `DesignSync` (claude.ai design-system projects — free, no rate limit, no subagent-auth problem since it rides the user's claude.ai login) — this is the most likely next move given the Figma rate limit. Or skip a dedicated design tool for the "map + bulk redesign" goal entirely and work directly in the real codebase (screenshot-based audit + direct component/page redesign, verified live) — the user was leaning this direction as of the last exchange.

**How to apply:** before resuming any Figma work, check whether the rate limit has cleared (try a trivial `use_figma` no-op first) or whether the user has since switched to Claude Design / Penpot / direct-codebase-redesign instead.

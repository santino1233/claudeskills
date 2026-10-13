# Brief: marketing: the Cyrus page

Read `/root/agent-notes/cyrus-v6/CONTEXT.md` first (the owner's full request, the shared rules, the roster). Worktree: `git -C /opt/nxeon worktree add /tank/dev-worktrees/cyrus-v6-marketing -b feature/cyrus-v6-marketing feature/cyrus-v6`. Output dir for notes: `/root/agent-notes/cyrus-v6/marketing/`.

## Your scope: "an incredible marketing page for Cyrus"
The owner: Cyrus is "a massive standalone product that I want to stand on its own legs. We need a premium page with interactive elements, can also include Cyrus itself (limited), flows, etc. Make it the most premium marketing page on the site."

Read first: the NXM marketing system (`tools/nxm/README.md`, `app/nxm/nxm.css`, `aurora.css`, `app/nxm/_components/`, `tools/nxm/native/*`, `tools/nxm/port_pages.py`; generated pages go through `tools/nxm/native/<page>/{body.html,page.css,page.js,meta.json}` then `python3 tools/nxm/port_pages.py <page>` into `app/nxm/_pages/<page>/`, never hand-edit `_pages`), and the strongest existing pages: home, ai-agents, the game-servers pages and the just-rebuilt `dedicated-servers` (see `git log --stat feature/bm-v2-marketing` on main for its native files and its gating pattern). Look at the owner's brand notes in `/root/.claude/projects/-root/memory/nxeon-marketing-design.md` and `nxeon-redesign-generic-drift.md`: the owner rejects templated, "vibe-coded", cheap-looking animation; they want premium and specific to the product.

Build `/cyrus`:
- A distinctive hero with the owner's hero coin (tilted for dark, silver for light; `docs/cyrus/asset-picks.json`), the wordmark, and a calm, restrained, original motion idea (not a generic particle field or typewriter).
- A **limited live Cyrus demo**: a real, safe, read-only slice of the network map and Particle Nebula core (reuse `components/cyrus/cosmos/*`; limit WebGL contexts to one, lazy-start, pause off-screen, respect reduced motion), with a scripted prompt that routes to a game branch and "forges" a sample mod. Clearly labelled as a demo; no fake stats.
- A guided **flow** section that explains the real pipeline: describe, Cyrus routes, forge and verify, test, list on NxLabs, community remix, install on your server, updates and warnings. Interactive (scroll or step), each step with a real product visual.
- Per-game strips for the six games using the owner's rounded logos and an honest status (Live / Coming soon; Minecraft is the live one). Real facts per game from the game agents' work if merged, otherwise from `lib/cyrus/games.ts`.
- **Models and plans** with the real token plans and estimates: read them through a server loader from `lib/cyrus/tokens/*` and `lib/cyrus/estimate.ts` exactly like the dedicated page reads its catalogue (never hardcode numbers). Use the model icons from the studio-ui agent (`components/cyrus/icons/ModelGlyphs.tsx`, `public/cyrus/models/*.svg`); until merged, stub the same names.
- The **community** story (remix, community versions, "Built with Cyrus" badges, community-tested seal), the install-and-updates story, a short FAQ, and honest copy throughout (no testimonials, ratings or usage numbers that do not exist).
- SEO and JSON-LD, navigation and footer entries (follow how the other pages register: `dedicated-nav.ts`, `footer-config.ts`, `app/nxm/_seo/registry.ts`, `lib/sitemap-sections.ts`), and **gating like the dedicated page**: 404 for the public until the owner flips a setting (`cyrus_public_enabled`) and preview accounts can view it; noindex until public; add the gate test pattern (`test/dedicated-gate.test.ts` style rule that nothing outside the feature links to it).
- Performance: Lighthouse-friendly, images optimised (webp from the owner's assets), no layout shift, mobile at 390 px.

## Verify
Render through the real route on node-2 with a seeded preview account (see how the dedicated marketing agent seeded: `/tank/dev-worktrees/bm-v2-mkt/.bmv2/` if it still exists), screenshots at 1440 and 390 of every section, the demo working, `devhost tsc` clean, the gate behaving. Stop your dev server when done.

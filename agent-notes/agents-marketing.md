# agents-marketing: AI-agent hosting research + /ai-agents marketing page (2026-10-04)

Branch feature/ai-agents-hosting, worktree /tank/nxeon-wt-agents (off main 27b6cb1156).
node_modules = real copy (cp -a), not a symlink. Not deployed, not merged.

## Log
- Read brief growth-batch-2026-10-02.md; all rules apply.
- Existing prior art: /openclaw-vps-hosting, /n8n-hosting, /discord-bot-hosting (use-case template,
  app/nxm/_data/use-case-content.ts) and /vibe-coding (native; Claude Code pre-installed on every VPS
  via lib/claude-install.ts). OpenClaw page is honest: "no one-click image".
- Codebase audit (read-only subagent): no OpenClaw/n8n/Grok OsTemplate, deploy URL has no template
  param, public API = GET /api/v1/servers only, no OpenAPI/CLI/MCP, llms.txt exists (dynamic route),
  spend caps account-level (lib/spend-caps.ts), firewall per VM, SSH key injection at deploy.
- Research (web, cited): /root/research/agents-support.md (Part 1 a-e + Part 2 plan + risks).
  Raw notes: scratchpad agents-research-raw.md.
- Page built: /ai-agents (staging /nxm/ai-agents). Native NXM page.
  Files: tools/nxm/native/ai-agents/{body.html,page.css,page.js,meta.json}, tools/nxm/wire/ai_agents.py,
  app/nxm/_data/ai-agents.ts (loader: real starter/standard/pro plans + deployHref),
  app/nxm/_data/ai-agents-cast.ts (6 ORIGINAL SVG characters), generated app/nxm/_pages/ai-agents/*,
  app/nxm/ai-agents/page.tsx, ROUTES in tools/nxm/nxmlib.py, SEO in app/nxm/_seo/registry.ts,
  live-routes.json (+/ai-agents), _pages/scripts.ts, test/ai-agents-page.test.ts, docs/DOCUMENTATION.md.
- Commit 1a559d91e7 on feature/ai-agents-hosting. Not pushed, not merged, not deployed.
- Verified: tsc --noEmit 0 errors; new test 5/5; full suite 2915/2981 pass, 44 fail == the same 43
  failures as clean main (stash-compared) + 1 timing flake (directory-blocklist ptr resolver, passes 3/3 alone).
- Local render: next dev :3141 against throwaway DB nxeon_agt_agents (role agt_agents) seeded with the
  repo's prisma/seed.ts plan rows (prod DB read was refused, so prices in screenshots = seed prices).
  No console errors, no horizontal overflow at 1440/820/390, JSON-LD: Breadcrumb+FAQ+Product.
- Screenshots: /root/agent-notes/agents-marketing/*.png (desktop/tablet/mobile/reduced-motion/hover/focus
  + live reference pages).
- Preview: scratchpad/agents/dev.sh (worktree .env is gitignored, throwaway) -> http://localhost:3141/nxm/ai-agents
  Cleanup when done: `sudo -u postgres dropdb nxeon_agt_agents; sudo -u postgres dropuser agt_agents;
  rm /tank/nxeon-wt-agents/.env`.
- Found + spawned as tasks: stale Node 22 on /openclaw-vps-hosting (docs now 24.16+/26.1+); /n8n-hosting
  claims One-Click but no n8n template exists; customer SpendControls UI orphaned (not mounted).

## v2 (owner verdict: 'weak, make it legendary') started 2026-10-04
- v2 commit f9a8724ba1 (on top of 1a559d91e7), branch feature/ai-agents-hosting, not merged/deployed.
- v2 = hero scene (6 large original characters, cursor-tracked eyes, signature motions, rack world, parallax,
  particles, cursor light), "night shift" parallel-work set piece (4 beats, flying task cards, SMIL packets on
  JS-routed paths, bursts, ticker, counter, day/night clock; labelled illustrative), crew stage (ARIA tabs +
  arrows/Home/End, accent shift, typed sample boot, lights, chat), pinned scroll story (5 chapters via
  --c0..--c4), rack, planned-API handshake (Coming soon), server-blade plans, FAQ, finale.
- Owner logo decision honoured: no logos drawn/scraped; app/nxm/_data/ai-agents-marks.ts maps agents to
  public/brand/agents/{openclaw,grok,claude,mcp,n8n}.svg (empty dir, .gitkeep); wordmark fallback shown now.
  Attributions are generic placeholders the owner must replace per each brand's guidelines (xAI restricts).
- Verified: tsc 0; test/ai-agents-page.test.ts 7/7 (incl. keyframes transform/opacity only, marks fallback,
  honesty labels); full suite 2918 pass / 43 fail == identical failure set to clean main.
- Pause check: with #ag-pause pressed, two frames 1.5s apart differ only in the site's own chat widget
  (bottom-right), SVG animationsPaused()=true. Keyboard: End on crew tab selects + focuses Bit.
- Filmstrips/screenshots: /root/agent-notes/agents-marketing/v2/ (1440, 820, 390, reduced motion).
- Page weight (dev server): ~107 KB gzipped HTML; ~49 inline avatar SVG instances (needed per-instance for
  eye tracking). Could drop to ~30 by removing avatars from plan blades / rack if weight matters.

## v3 polish (2026-10-05), commit 226e984d19 on feature/ai-agents-hosting (not merged/deployed)
- (1) pause control + note now inline in hero (no fixed overlay); phone note moves below scene. Verified
  no overlap at 1440/820/390 (v3/hero-*.png).
- (2) night shift bigger/brighter (140px avatars, 230px cards, .9-1.1rem text, brighter net), stronger
  active glow, 18-dot bursts + shockwave spaced >=420ms (<3 flashes/s), queue->dispatch->work->Done tray.
- (3) phone night shift = vertical flow (queue card, spine with packets, rows, Done tray, counter).
- (4) weight: symbols + <use>; live copies hydrate client-side. Dev-server HTML: v2 759,106 B raw /
  86,112 B gzip -9 (106,913 B as served) -> v3 557,868 B raw / 80,428 B gzip -9 (99,032 B served),
  despite richer art. (Reference /vibe-coding: 387 KB raw / 57 KB gzip -9.)
- (5) story 520vh -> 350vh, parallax racks/floor, drawn-on wires (stroke-dashoffset from scroll var),
  per-chapter poses (focus, wow, landing squash, working, happy).
- (6) shading/rim light, follow-through (antenna, stalks, prongs), landing squash, 4 expressions.
- (7) a11y script: heading order no skips; 9 labelled regions; 210 text nodes contrast-checked, 0 below
  WCAG AA (approximate: gradient backgrounds treated as nearest solid); live regions polite (night shift
  rate-limited 12s); focus order hero CTAs -> Pause -> night-shift Pause -> crew tablist (roving) -> panel;
  reduced motion: 0 running animations, no hydration, story unpinned.
- (8) FPS at 4x CPU throttle (headless, software raster, shared box load 4-7; /vibe-coding = 60fps same
  conditions). Two runs each:
  1440 hero 32-51, night shift 33-34, crew 38-47, story 38-44, rack 44-54 fps
  390  hero 24-29, night shift 23-35, crew 35-52, story 32-55, rack 57-58 fps
  Before fixes (same method): 1440 hero 9, night 11.5, crew 14, story 14; 390 night 5.6, crew 8.7, story 6.9.
  Root causes found: CSS filters on animated layers, layout thrash in eye tracking, node insertions
  triggering :root:has() whole-page recalcs (site-wide globals.css), SMIL packets repainting a big SVG.
- Copy fixes: /openclaw-vps-hosting Node 24.16+/26.1+; /n8n-hosting honest (no one-click). Can't render
  those two pages locally (throwaway DB has no Node rows -> use-case loader throws "no enabled regions");
  verified via unit test on the builders instead.
- Tests: tsc 0; ai-agents test 10/10; suite = main's 43 failures (+ directory-blocklist timing flake that
  passes 16/16 alone).
- Follow-up (not filed: spawn_task hook timed out): scope app/globals.css :root:has(.nx-shell-root) rules (site-wide whole-page style recalc on DOM insertion).

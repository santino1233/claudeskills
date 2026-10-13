# Agent M (skins) — Minecraft skin creator — progress note (2026-10-01)

Branch `feature/minecraft-skin-creator`, worktree `/opt/nxeon-wt-skins`. Commits: 032f1e2a5b, 9c05f4b1ff (pushed by hook).

## Done
- Vetting: reference = DatHost (dathost.com/tools/minecraft-skin-editor; that.host is an unrelated personal domain). Proprietary, no licence -> ideas only, nothing copied. Verdict + attributions: docs/TOOL-SKIN-CREATOR.md.
- skinview3d 3.4.2 (MIT, bundles three.js) vendored unmodified: public/vendor/skinview3d-3.4.2/ (+LICENSE.txt). No npm dep.
- Core logic lib/skin/skin-core.ts, presets lib/skin/presets.ts (original procedural art), Mojang lookup lib/skin/mojang.ts, route app/api/tools/mc-skin/route.ts.
- UI components/skin-creator/* (SkinCreator, SkinViewer3D, sv3d picking, render2d, css, SkinCreatorLazy).
- Pages: app/(marketing)/tools/minecraft-skin-creator (content source), nxm route generated (port_pages.py tools-tool), live-routes.json regenerated, ToolMount entry; portal app/dashboard/tools/minecraft-skin-creator (ToolPage wide).
- Hook-ups outside area: components/marketing/ToolShell.tsx (jsonLd/cta/facts props), app/nxm/_data/tools-live.ts + tools-tool.ts, lib/tools/catalog.ts, app/nxm/_seo/registry.ts + app/(marketing)/tools/page.tsx (hub description), app/dashboard/tools/_ToolPage.tsx (wide), lib/nx/icon-paths.ts + tool-icons.ts, docs/DOCUMENTATION.md.
- Tests: 24 pass — `npx tsx --test test/skin-core.test.ts test/skin-mojang.test.ts test/skin-route.test.ts`.
- tsc: whole project clean except test typings, which were then fixed (re-run tsc to confirm).
- nxm content loader exercised via tsx: toolContent("minecraft-skin-creator") returns SoftwareApplication+HowTo LD, CTA, facts; other tools unchanged.

## NOT done (in order)
1. Playwright run of the component harness never executed (heavy lock queue / lock timeout). Harness copy: /root/agent-notes/skins-harness/ (run.cjs, entry.tsx, index.html). To rerun: rebuild bundle
   `cd /opt/nxeon-wt-skins && cp /root/agent-notes/skins-harness/entry.tsx components/skin-creator/__harness_entry.tsx && node_modules/.bin/esbuild components/skin-creator/__harness_entry.tsx --bundle --outfile=<H>/www/out.js --jsx=automatic --alias:@=/opt/nxeon-wt-skins --define:process.env.NODE_ENV='"development"' --loader:.css=css; rm components/skin-creator/__harness_entry.tsx`
   with <H>/www/{index.html, vendor/skinview3d-3.4.2 -> symlink to public/vendor/...}, put run.cjs in <H>, then `heavy.sh bash -c "cd <H> && node run.cjs"`. It checks drawing, mirror, undo/redo, fill, slim/classic, overlay mode, 3D click-jump + paint-on-model, username import (mocked), legacy upload, wrong-size reject, share link, templates, mobile overflow, screenshots.
2. Real Next dev-server render of /nxm/tools/minecraft-skin-creator and /dashboard/tools/minecraft-skin-creator (needs throwaway DB with Plan/GamePlan/Node copied from prod + a test user + a JWT session cookie signed with AUTH_SECRET; NXEON_ENV=staging, NXEON_SANDBOX=1, PORT=3119). Throwaway DB was dropped and .env removed.
3. Re-run tsc after the test-typing fix; merge main.
## Risks
- 3D picking math (sv3d.ts pickTexel) is unverified in a browser.
- docs/DOCUMENTATION.md change-history appended at file end (likely merge conflicts with other agents).

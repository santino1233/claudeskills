# Brief: bring the owner's redesigned Cyrus into the Nxeon portal

The owner redesigned **Cyrus** (Nxeon's AI game-mod studio) in their own local Claude session and handed it over. Your job is to make that new design the Cyrus inside Nxeon, while keeping every working feature the portal's current Cyrus already has. Then type-check it and show it running (screenshots).

## Read first (in this order)
1. `/tank/handoffs/cyrus/cyrus-handoff/START-HERE.md`: the handoff. Read all of it, especially §3 (playbook, Path A applies: Nxeon is Next.js 15 App Router + React 19 + Tailwind 4), §4 (conflict points), §6 (forge event contract), §9 (owner preferences: premium, saturated neon, crisp, dark first but light must be deliberate).
2. `/tank/handoffs/cyrus/cyrus-handoff/cyrus/README.md` and `cyrus/CLAUDE.md` (conventions + gotchas).
3. The reference screenshots in `/tank/handoffs/cyrus/cyrus-handoff/assets/screenshots/`. Your result must match them.
4. `/root/agent-notes/BUILD-HOST.md`. Follow it exactly. tsc, dev servers and Playwright run on node-2 via `/opt/nxeon/scripts/devhost`. Never on the primary, never in `/opt/nxeon` itself.

## What already exists in Nxeon (keep all of it working)
The current Cyrus ("v4b") is live but preview-gated. It's built from:
- **Pages:** `app/dashboard/cyrus/` (page.tsx, `[id]`, cyrus.css, shared.tsx).
- **UI:** `components/cyrus/` (CyrusApp, Stage, Composer, Inspector, LiveCode, DiffView, Explain, Versions, Switcher, Modals, voice, web/…) and `components/cyrus-tokens/`.
- **Lib:** `lib/cyrus/` (games, categories, models, projects, templates, estimate, meta, uploads, diff, tokens/) and `lib/cyrus-mods/`.
- **Actions:** `lib/actions-cyrus-*.ts`.
- **API:** `app/api/cyrus/`.

It has REAL features the handoff's standalone app only fakes. Keep them:
- Per-user accounts and projects in the DB.
- The **token economy**: plans $4.99 / $19.99 / $49.99, grants only for games Cyrus supports. See `/root/agent-notes/cyrus-economy/ECONOMY.md` and especially **`UI-CONTRACT.md`**, which says how the token UI must be wired into a new design.
- The real build service: the Minecraft plugin build on the mod builder VM via the existing APIs. Don't change the VM or the service.
- The mods tab / install-to-server flow, image upload and live code.
- The access gate. Keep every page and route calling the same preview gate the current Cyrus uses.

Read the current code before touching anything, and map each existing feature to where it lives in the new design. Where the handoff app has only a local placeholder (the zustand `credits` counter, the templated `forgeStream()`, localStorage projects), **wire it to the real Nxeon equivalent**, keeping the handoff's GenEvent stream contract (§6) so the UI animations still work.

- Where Nxeon really builds (Minecraft), stream real build progress and output.
- Where no real backend exists yet (the other games), keep the handoff's template generators.
- Hook the model call into the generate route per §6. Use the existing Cyrus model/LLM plumbing in `lib/cyrus/models.ts` if it exists. Otherwise leave the clearly marked template path and say so in your report.

## How to integrate (Path A)
- **Mount point.** Keep the portal URL `/dashboard/cyrus`, with the real portal sidebar + top bar around it. Owner rule from earlier rounds: "keep the real portal sidebar and top bar". Put the core gallery at `/dashboard/cyrus/cores`.
- **Namespacing.** Copy the handoff's `components/` into `components/cyrus/` (new files beside or replacing the v4b ones; delete the v4b UI files only once nothing imports them), `lib/` into `lib/cyrus/` (merge carefully; don't clobber the real `games.ts` / `models.ts` / `tokens/` that the economy relies on), and `public/games/` into `public/cyrus/games/`. Fix all `@/` imports and the hard-coded paths in handoff §4.
- **Scope everything.**
  - The handoff's `body { overflow:hidden }`, `html,body{height:100%}` and its `:root` tokens (`--bg`, `--ink`, `--accent`…) must NOT leak into the rest of the portal. Scope them under a Cyrus root class or a route-level layout.
  - Keep its fonts (Inter, Space Grotesk, JetBrains Mono via next/font variables) scoped to Cyrus.
- **Theme.** Unify with the portal's theme: `localStorage "nx-theme"` and `:root.nx-portal[data-theme="light"]`. Read how the portal sets it (`components/nx/ThemeToggle.tsx`, `app/globals.css`). Cyrus dark and light must follow the portal toggle, not its own `cyrus-theme`.
- **WebGL.** Keep the core and aurora shaders pixel-identical. Don't simplify them (§3). Particle Nebula is the core.
- **Logos.** The game logos are the owner's own files and are fine to use as provided.

## Verify (show it running)
- Seed a throwaway node-2 DB user who passes the Cyrus preview gate. Read how the gate decides; never touch production data.
- Playwright screenshots matching every reference screenshot in the handoff:
  - network dark + light, thinking, forging, Add game dialog, Ctrl+K, core gallery, core preview, aurora;
  - the portal chrome around it;
  - a forge for Minecraft (real path) and one template game;
  - the token UI showing the real balance/plan.
  - 1440 desktop + 390 mobile.
- Save them to `/root/agent-notes/cyrus-redesign/shots/` with `devhost pull`.
- `devhost tsc` must be clean. Also run the Cyrus and light-theme tests that exist (`ls test | grep -iE "cyrus|light"`). If `node scripts/gen-light-literals.mjs` changes `app/light-literals.generated.css`, commit the regenerated file. Run it on node-2 and pull it back, because it needs node_modules.
- Check that the rest of the portal still looks the same: screenshot `/dashboard` and `/dashboard/services` before and after.
- Screenshot `/dashboard/cyrus` server-rendered through the real route. Never only through a client-side harness: a server-component bug 500'd a page in prod today because only a harness was checked.

## Hard rules
- Work in a NEW worktree: `git -C /opt/nxeon worktree add /tank/dev-worktrees/cyrus-v5 -b feature/cyrus-v5 main`. Commit only your files, with explicit `git add <paths>`. Never `git add -A` or `git add .`. Don't commit node_modules, .next or screenshots.
- No deploy, no merge to main, no production DB access, no emails.
- Never run role/ownership SQL (REASSIGN/DROP OWNED, ALTER OWNER, roles).
- Never pkill or killall by pattern. Stop by unit (`devhost stop`).
- node-2 agent memory is capped at 7 GB and shared with other agents. Run one dev server at a time and stop it when idle. A production release build may run there too.
- If the permission system denies something, don't work around it. Note it and continue.
- Brand voice: Nxeon speaks as itself. Never mention third-party providers.

## Deliverable
Commits on `feature/cyrus-v5`, a clean `devhost tsc`, the screenshots, and a short report:
- What was kept, what was replaced, and what is still templated.
- How the token economy is wired.
- Anything the owner must decide.

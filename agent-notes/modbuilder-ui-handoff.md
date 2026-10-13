# Brief: redesign the Nxeon AI Mod Builder UI

**Goal:** a fresh, flagship-quality redesign of the AI Mod Builder customer UI that drops straight back into the Nxeon portal. Change the UI only: keep the data, API and access rules as they are.

**What the product does:** a customer describes a Minecraft plugin in plain English. AI writes it, compiles it, fixes its own errors and safety-scans it. The customer gets a `.jar` plus a plain-English summary covering what it does, its commands, permissions and settings. They can then download it, install it on one of their Paper/Purpur servers, or ask for a change (a new version built on top of the old one). It's aimed at non-developers, so no jargon.

## Stack (must match)
- Next.js 15.5 (App Router, server components plus client components), React 19, TypeScript 5.8, Tailwind CSS 4.1.
- Repo: `/opt/nxeon`. **Never edit or build there.** Work in a worktree:
  `git -C /opt/nxeon worktree add /tank/nxeon-wt-mbui -b feature/mod-builder-ui-v2 main`
  - Never use `git add -A`; add explicit paths.
  - For `node_modules`, make a directory of symlinks into `/tank/nxeon-wt-release2/node_modules`, or ask how.
- Free RAM on the primary is tight. Run heavy commands as `flock /root/.nxeon-build.lock nice -n 15 env NODE_OPTIONS=--max-old-space-size=3072 ...`.

## Files that make up the current UI (replace them, keep the same entry points)
- `app/dashboard/mod-builder/page.tsx`: home (prompt box, idea chips, version picker, your builds)
- `app/dashboard/mod-builder/[id]/page.tsx`: one build (live progress, result, source viewer, versions)
- `app/dashboard/mod-builder/mb.css`: page-scoped styles. Every rule hangs off `.mb-root`, and shared portal classes must never be restyled.
- `components/nx/modbuilder/`: `ModBuilderHome.tsx`, `BuildView.tsx`, `SourceViewer.tsx`, `Modals.tsx` (install and change-request), `bits.tsx`

## Data contract (don't change it)
- Types are in `lib/modbuilder/types.ts`:
  - `ModBuildView`
  - `ModBuildStatus` = `queued | planning | coding | compiling | repairing | scanning | succeeded | failed`
  - `MB_STAGES` (the timeline labels), `MbEvent`, `MbCommand`, `MbPermission`, `MbConfig`, `MbFinding` (safety)
  - `MB_VERSIONS` = 1.21.11 / 1.21.8 / 1.21.4 / 1.21.1
- API routes, under `app/api/mod-builder/builds/` (UI calls only, don't modify):
  - `POST /` creates a build.
  - `GET /[id]` returns status; the UI polls it.
  - `POST /[id]/cancel`
  - `POST /[id]/install`
  - `GET /[id]/jar`, `GET /[id]/source?path=`, `GET /[id]/source-zip`
- Install targets come from `lib/modbuilder/install.ts` `modBuilderServers()`, which marks each server compatible or not and gives the reason.
- Access: `lib/modbuilder/access.ts` (`requireModBuilderUser`, a private-preview gate). Keep every page and route calling it.

## Design rules
- Use the Nexion portal look: navy surfaces with the violet, blue and cyan brand ramp (`--mb-grad`: #14c5e4 → #2f7eef → #8c3ae9 → #d623e1).
- Use the portal's theme tokens (`var(--color-tx)`, `--color-tx-mute`, `--color-well`, `--color-rim-*`, `--color-violet`, …) defined under `:root.nx-portal` in `app/globals.css`.
- **It must work in both dark and light theme** (`:root.nx-portal[data-theme="light"]`). Never hard-code dark-only colours; elements that should stay dark in both themes use the `nx-dark-island` pattern.
- Mobile at 390px must be clean, with no horizontal scroll.
- Never use Mojang or Minecraft artwork or logos; we may not redistribute them.
- Design every state: empty, typing, queued, each build stage, repairing, success, failed (refused by safety, compile failure, cancelled), install modal (compatible and incompatible servers), change request, version history, loading and error.

## Deliverable
- A branch with only the files above changed, plus any new components under `components/nx/modbuilder/`, so it merges straight back.
- `npx tsc --noEmit` clean.
- Playwright screenshots of every state in desktop 1440 and mobile 390, light and dark. Seeding pattern: `/root/agent-notes/modbuilder-preview/seed.ts` + `shot.mjs`.
- Don't deploy, don't touch the prod DB, and don't change the build service on the VM.

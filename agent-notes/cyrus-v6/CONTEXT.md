# Cyrus v6: shared context for every agent (read this first, then your own brief)

Nxeon's **Cyrus** is an AI game-mod studio inside the customer portal (`/dashboard/cyrus`). The owner's redesign (the "Nexus" mind-map UI, Particle Nebula core, six game branches) was integrated on branch `feature/cyrus-v5` (2 commits, tested on node-2, not deployed). **`feature/cyrus-v6` is the shared base for everything below** (it is v5 plus `lib/cyrus/games/support.ts`, the GameSupport contract, and `docs/cyrus/asset-picks.json`). Twelve agents work in parallel, each on its own branch from `feature/cyrus-v6`. The main session merges them. **Stay inside your own area; keep edits to shared files (`CyrusApp.tsx`, `store.ts`, `PromptDock`, `lib/cyrus/types.ts`, `prisma/schema.prisma`) minimal and additive** so merges are easy. If you must add a Prisma model or field, add it at the END of schema.prisma with a clear comment.

The owner wants Cyrus to become **the most advanced game-AI mod creation tool there is** and a standalone product that "stands on its own legs".

## The owner's request, verbatim (2026-10-08). This is the spec for the whole programme

> the choose the heart of cyrus needs to be removed, this is leftover from testing the core design. the current core is what we went with
>
> on the plans, you need to put estimates for how many edits or mods you can make with this
>
> Cyrus still needs to have the explain tab alongside notes, code, files, and versions.
>
> option to open the project in NxLabs, they can change the title of the mod, add photos, have full customization of their mods. its supposed to be a community with the option for other people to build off their mods, they can even load other community cyrus mods directly into their cyrus. and when they make changes they go under the community versions on the mod page. I really want you to expand on this community idea.
>
> I also want the prompt box from the core or from the game to be able to understand proper broad requests, So if someone isn't hovered on a game or a specific mod, they can still prompt make me a mod for Minecraft where "x" or work on my "x" mod and fix "x" or whatever and it will jump to where it needs to go
>
> Mod categories need to be preset, and cyrus automatically organizes them based on the based, this will help when automatically categorizing them in the mod store and there should be preset categories the same across all games e.g. Environment, Weapons, Performance, etc. make sure they all have their own SVG icons if they dont already
>
> I also want you to go through the entire cyrus system, functionalities, and see what we can add or improve. modding logic for each of the games.
>
> I also want to make it more efficient at making mods as in spending less api usage without restricting it and making it dumber at creating mods
>
> research how someone can make more advanced mods
>
> we need to look at how they function on peoples servers, deploying/installing them on their servers, enabling and disabling them, warnings that the mod is broken or out of date, updating the mods, warnings to the creators of the mods that their mod may need an update
>
> I want to expand on this system to make it the most advanced game ai mod creation tool out there. I also want to look at how we can potentionally plug in the ability later down the road for making renders for peoples mods (textures and such)
>
> you also need to plug in the assets we have made for cyrus and look back at the other data we already created prior to the redesign
>
> keep the model names how we originally had them.
>
> Launch agents for enabling support for other games (Palworld, Terraria, Valheim, Rust, Palworld). we have already created logic for some of them, im not sure if you saw it or now, but it should be in the original handoff. needs proper understanding for modding language for these games, how they function in the game. We need to make sure these mods dont just break peoples games, understanding for game versions, whether the mods need to be installed not just on their server but their personal computer as well to work, everything
>
> Also we need to launch an agent to make an incredible marketing page for cyrus, this is a massive standalone product that i want to stand on its own legs. We need a premium page with interactive elements, can also include cyrus itself (limited), flows, etc. Make it the most premium marketing page on the site. Current pages available.
>
> remove the hierarchy legend in the bottom left,
>
> the add game needs to be limited to the games that we actually support
>
> the ability to expand the side preview card
>
> I want to make better higher quality icons for each of the models which will be displayed in the plans card, in cyrus when picking a model, in marketing.
>
> also the picking model card from the prompt box is very unreadable with its translucent background
>
> the sidebar option for cyrus, i want this to highlighted and instead of the star icon, use the Y icon we already have, or actually just make a proper svg icon using the shape of the Y or how the plain white cyrus logo . but make it svg so it can be properly customized based on the setting its being used in site white
>
> make sure game logos are rounded, I can see the rust logo is just a square with sharp edges which doesn't look good in its branch orb
>
> If someone clicks on the specific mod, our when they first start creating the mod and it finishes they have an option to input the title, choose the category if the auto sorter is wrong, logo/icon, Brief description, etc.

("Palworld" is listed twice; the fifth game the owner means is almost certainly **Project Zomboid**. It has a generator in the handoff too, so it gets an agent.)

## Facts you must respect

- **Model names stay as originally built: Katara, Saka, Yakko** (the token plans, economy and build service use them). The standalone handoff said Sokka/Yako; that is wrong for Nxeon.
- **Existing assets and data from before the redesign must not be lost**: the token economy (`lib/cyrus/tokens/`, `components/cyrus-tokens/`, `/root/agent-notes/cyrus-economy/ECONOMY.md` and `UI-CONTRACT.md`), the Cyrus mods ecosystem/community (`lib/cyrus-mods/*`, `lib/actions-cyrus-mods.ts`, `lib/actions-cyrus-installed.ts`, NxLabs mod store pages), the real Minecraft build service (`services/modbuilder/`, build VM, `lib/modbuilder/*`), projects in the DB, v4 tests. Look at `git log feature/cyrus-v5`, `/root/agent-notes/cyrus-v4/`, `/root/agent-notes/cyrus-redesign/`, the owner's handoff at `/tank/handoffs/cyrus/cyrus-handoff/` (START-HERE.md, `cyrus/lib/engine/games/*` = the per-game generators), and the memory-style notes in `/root/.claude/projects/-root/memory/nxeon-cyrus-*.md` and `nxeon-ai-modbuilder.md`.
- **Brand assets**: owner's picks are in `docs/cyrus/asset-picks.json` (ids = files in `/root/agent-notes/cyrus-assets/full-res/<id>.png`, thumbs in `.../picker/a/`). Badge roles: generic "Built with Cyrus" = round-end pill; community-tested seal = laurel (only for highly tested and rated community mods); compact = shield (the generic badge for tight spaces). All come in dark and light versions. UI chrome marks (sidebar icon, favicons, inline Y) must be real **SVG with `currentColor`**, not PNG.
- **No official game logos or art.** The owner has supplied their own game logos (`public/cyrus/games/`); use those, always rounded. Never use Mojang/Minecraft art.
- **Honesty about what works.** Anything not truly implemented is labelled (e.g. "Template preview"). Never present fabricated mods, stats, ratings, reviews or usage numbers as real.
- Brand voice: Nxeon speaks as itself, never mentions third-party infrastructure providers.

## Hard rules (the same for everyone)

1. Worktree: `git -C /opt/nxeon worktree add /tank/dev-worktrees/<name> -b <branch> feature/cyrus-v6` (branch and name are in your brief). Work ONLY there. Never work in `/opt/nxeon` or `/opt/nxeon-staging`. Commit only files you changed, with explicit `git add <paths>` (never `-A` or `.`), and end commit messages with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
2. **No deploy, no merge to main, no production DB, no emails sent, no customer data touched.** Never run role/ownership SQL (REASSIGN/DROP OWNED, ALTER OWNER, roles). Never `pkill`/`killall` by pattern; stop by unit (`devhost stop`). Never change the build VM, customer VMs or any production setting.
3. **Builds, tsc, tests, dev servers and Playwright run on node-2 only, via `/opt/nxeon/scripts/devhost` from inside your worktree.** Read `/root/agent-notes/BUILD-HOST.md` first.
4. **node-2 is shared by about twelve agents and 13 customer VMs, with a 7 GB cap for all agents together.** To avoid out-of-memory kills:
   - **At most ONE dev server in the whole fleet.** Before `devhost dev`, run `devhost status`; if any other agent's `*-dev.service` is running, wait (poll every 60 s, up to 30 min). Start yours, take your screenshots, then `devhost stop` immediately. Never leave one running while you think.
   - Run `tsc` and test suites as `devhost run --lock -- <cmd>` (or `devhost tsc` / `devhost test`) so they queue behind each other. Do it once per milestone, not after every edit.
   - Prefer careful reading and pure unit tests (`tsx --test`) over repeated heavy runs. If you are OOM-killed, wait and retry; never try to raise limits.
   - A production release build may run on node-2 at times (it pauses agents). If the coordinator messages you to pause, stop heavy work immediately.
5. **Cost discipline.** Do not spend money: no paid third-party tools (never `baz`), no purchases, no model/API runs that consume the owner's Anthropic usage beyond a handful of tiny test calls. Anything bigger (evals over many runs) must be designed and described, not run, unless your brief explicitly allows a bounded run.
6. If the permission system denies an action, do not work around it. Note it and continue with what you can.
7. Everything customer-facing must work in **dark and light** theme (portal tokens under `:root.nx-portal[data-theme="light"]`; Cyrus scopes under `.cyrus-root`; read how v5 did it), at **390 px** with no sideways scroll, and have empty/loading/error states.
8. Verify through the REAL server-rendered route, not a client-only harness (a server-component bug 500'd a production page earlier this week because only a harness was checked). Seed a throwaway node-2 DB; see `/root/agent-notes/cyrus-redesign/harness/` for how v5 did it (preview user, local stand-in for the build service).
9. Docs: add or extend a section in `docs/DOCUMENTATION.md` for what you build (short, factual). Put research deliverables in `/root/agent-notes/cyrus-v6/<your-name>/`.
10. End with a SHORT report: what you built/found, files and commits, how to see it, screenshots/evidence paths, what is left, and decisions the owner must make. Never claim something works unless you ran it.

## The roster (so you know who owns what)

| # | Agent | Branch / output | Owns |
|---|---|---|---|
| 1 | studio-ui | `feature/cyrus-v6-studio` | UI fixes: remove core gallery + legend, expandable side card, Explain tab, model picker legibility, model icons, sidebar item, rounded logos, add-game limit, plan estimates UI, asset wiring |
| 2 | routing | `feature/cyrus-v6-routing` | Broad-request prompt routing, universal categories + auto-sorter + category SVG icons, post-forge listing dialog |
| 3 | community | `feature/cyrus-v6-community` | NxLabs hand-off, listing customisation, forks/remixes, community versions, loading community mods into your Cyrus, community expansion |
| 4 | lifecycle | `feature/cyrus-v6-lifecycle` | Installing on servers, enable/disable, broken/outdated warnings, updates, creator warnings |
| 5-9 | game-palworld, game-terraria, game-valheim, game-rust, game-zomboid | `feature/cyrus-v6-game-<id>` | Per-game modding support: `lib/cyrus/games/<id>.ts` (GameSupport), generator upgrades, validators, tests |
| 10 | efficiency | `feature/cyrus-v6-efficiency` | Cheaper mod generation without making it dumber (service + pipeline) |
| 11 | research | `/root/agent-notes/cyrus-v6/research/` | Advanced-mod techniques per game, texture/render plug-in architecture |
| 12 | marketing | `feature/cyrus-v6-marketing` | The Cyrus marketing page (NXM site) |

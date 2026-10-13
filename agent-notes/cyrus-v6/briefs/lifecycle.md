# Brief: lifecycle: install, enable/disable, health, updates, creator warnings

Read `/root/agent-notes/cyrus-v6/CONTEXT.md` first (the owner's full request, the shared rules, the roster). Worktree: `git -C /opt/nxeon worktree add /tank/dev-worktrees/cyrus-v6-lifecycle -b feature/cyrus-v6-lifecycle feature/cyrus-v6`. Output dir for notes: `/root/agent-notes/cyrus-v6/lifecycle/`.

## Your scope
Read first: `lib/cyrus-mods/installed.ts`, `lib/actions-cyrus-installed.ts`, `lib/modbuilder/install.ts`, the `ServerMod` model and the `GAME_MOD_SYNC` job path (`worker/`), the game panel's mods tab, `lib/prefs.ts` (notification kinds), and the GameSupport contract `lib/cyrus/games/support.ts` (the game agents will fill it in; code against the type).

Build a complete **mod lifecycle on customers' own servers**:
1. **Install**: from Cyrus and from NxLabs onto a chosen server, per game using `GameSupport.install` (path, packaging, restart needed, hot reload, and, for games where players need the mod too, a clear plain-language "players must also install this" step with instructions). Version-compatibility check before install (block on unsupported, warn on legacy), a confirm step with the warnings, a backup of the previous mod file and config, and automatic rollback if the install job fails.
2. **Enable / disable** without deleting (move to a disabled folder or loader-specific switch, per game), with states: Enabled, Disabled, Pending restart, Failed, Broken, Outdated. Config is preserved.
3. **Health and warnings**: detect **broken** (loader errors naming the mod in the server log, using per-game patterns from `GameSupport.outdatedSignals`/a log-pattern list you define; crash loop right after an install triggers auto-disable and a notification) and **out of date** (game/loader moved past the mod's tested range, or a newer version exists). Show warnings in the portal: badge on the mod row and server card, banner on the server page, and optional email through the existing notification-preference gate (add a NON-critical kind in `lib/prefs.ts`).
4. **Updating**: one-click update to a newer version of the same mod, config kept, changelog shown, rollback; "Update all"; per-mod opt-in auto-update.
5. **Creator warnings**: when a game/loader version change makes a published mod likely stale, or several installed copies report errors, warn the **mod's creator** ("your mod may need an update for Minecraft 1.21.5") in the portal and by email, deduped and rate-limited, with a one-click "Update with Cyrus for the new version" that opens the project with the version preselected (the refine path; keep the cost low). Implement the detector as a worker sweep that is **inert until enabled** by a setting (`cyrus_compat_watch_enabled`, default off), reading versions from `GameSupport` and live server data, with a dry-run mode that only logs.
6. All server writes go through the existing job system. **Never touch real customer servers in dev**: use mocks and the throwaway DB.

## Verify
Pure tests for the state machine and warning rules; mock-driven end-to-end of install, disable, broken detection (feed sample logs), update and creator warning; real server-rendered screens with screenshots (mods tab states, warnings, update dialog, creator warning), dark + light, 1440 + 390; `devhost tsc` clean; docs with the state diagram.

# modupdate — mod auto-update with compatible versions

Branch `feature/mod-autoupdate-compat`, worktree `/opt/nxeon-wt-modupdate` (from main e48608bb98).

## Design (one paragraph each)
- **Resolver** `lib/mod-autoupdate/resolver.ts` (pure): target (loader + game version) × guest state × candidate
  universe → per-mod Decision (update / add-dependency / current / pinned / held / no-compatible / unknown) with a
  reason sentence. Never downgrades; transitive required deps; diamond ranges intersect; incompatibilities both ways;
  backtracks a culprit root one build at a time (bounded).
- **Candidates** `lib/mod-autoupdate/candidates.ts`: Modrinth / Hangar / Thunderstore APIs (via K1 safeFetch
  allowlist), other engine sources via the family installer's own resolve(), NX Labs ModVersion rows as fallback.
- **Policy** `policy.ts`: OFF/NOTIFY/AUTO per server + per mod; clientRequired or unknown → NOTIFY unless owner typed
  the opt-in phrase; window in local tz (region default); 0 players (GameLogCursor / PlayerSession); caps; back-off.
- **Engine** `engine.ts`: snapshot zip of managed mod dirs + state.json → K1 installOrUpdate with pinned resolution
  → gamePower restart → runtime probe → restore + restart on failure.
- **Worker** `worker/mod-autoupdate.ts`: sweep `mod-autoupdate` (5 min) + job `GAME_MOD_AUTOUPDATE`.
- **Profiles** `profile-export.ts` / `profile-store.ts`: r2modman .r2z (+ Thunderstore profile code on demand), .mrpack, checklist.
- **UI** `components/customer/mods/AutoUpdate{Panel,Profiles,History}.tsx`, actions `lib/actions-mod-autoupdate.ts`,
  admin `/admin/mod-updates`, download route `app/api/servers/[id]/mod-profile/[kind]`.

## Owner steps to enable
1. Merge + deploy (schema is additive: `prisma db push` adds columns/tables + enum value GAME_MOD_AUTOUPDATE).
2. `/opt/nxeon/.env`: `ENABLE_MOD_AUTOUPDATE=1` (requires the existing `ENABLE_REAL_GAMEMODS=1` for real guests).
   Optional: `MOD_AUTOUPDATE_NODE_CAP` (1), `MOD_AUTOUPDATE_GLOBAL_CAP` (3), `MOD_AUTOUPDATE_CHECK_HOURS` (12),
   `MOD_AUTOUPDATE_PER_SWEEP` (10). Restart worker via the promote script.
3. Default server mode is NOTIFY — nothing is auto-applied until a customer picks Auto-update.
4. Kill switches: `MOD_AUTOUPDATE=off` (env) or "Pause fleet-wide" on /admin/mod-updates (Setting `mod_autoupdate_enabled`).
5. Add a nav entry for `/admin/mod-updates` (lib/admin-nav.ts is A1's file — not touched here).

## Verified / not verified
- 34 unit tests pass; K1 suite (23) still passes; tsc clean.
- SANDBOX e2e on throwaway DB `nxeon_agt_modupdate` (dropped after): real Modrinth/Thunderstore reads, LuckPerms
  auto-update applied, Jötunn held at NOTIFY (client-required) then applied manually, r2z/checklist generated.
- NOT verified: real restart/health/rollback on a live guest; Thunderstore profile-code POST; email delivery.

## Commits
22deeb5217 core (schema, lib/mod-autoupdate, worker, tests) · c6f50d5d5d UI/actions/admin/docs · d4fcb12371 polish · cced33314a merge main.
Throwaway DB nxeon_agt_modupdate + role agt_modupdate dropped; temp .env and scripts removed.
Incident: my dev server held many Postgres connections; at ~17:40 UTC the shared cluster briefly hit
"remaining connection slots are reserved" (seen in MY dev log). Killed it by port PID; no such errors in
nxeon-web/nxeon-worker journals since 17:00.

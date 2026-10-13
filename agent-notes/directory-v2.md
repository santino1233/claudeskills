# directory-v2 (2026-10-04) branch feature/directory-multisource, worktree /tank/nxeon-wt-dir2
Notes as I go. Final report is the handback message; sources table in /root/research/directory-sources.md.

## Task 1 diagnosis (read-only, prod)
- Prod Settings: directory_ingest_enabled=true, directory_external_show=true. directory_sweep_enabled has NO row (default "false"),
  directory_storage_country and directory_steam_terms_reviewed_by have NO rows (default ""). STEAM_WEB_API_KEY IS present in /opt/nxeon/.env.
- DirectorySource 'steam' exists (created by the first tick) with every field null: lastRunAt null => the sweep has skipped every tick before claiming.
  sweepGate order: kill-switch, then `!ingestOn || !sweepOn` => "disabled". sweepOn is false, so that is the skip. A skip writes nothing, which is why there is no error.
- Even with the sweep flag on, the next gate is legal-gate: country + reviewer blank => still skipped. After that: key (present), breaker (clear).
- Worker restarted 11:51 UTC on the phase-1 code, so it is running the code; DIRECTORY_SWEEP_DISABLED not set.
- Owner-only fix: fill storage country + terms reviewer in /admin/directory, flip directory_sweep_enabled. No code change needed for Steam to start.
- Page "looks the same": /dashboard/directory (app/dashboard/directory/page.tsx) NEVER read ExternalServer at all (only paid, free MC, community). Marketing /game-servers/directory does call loadDirectory. So even with rows the portal would not change: code fix needed (done on this branch).

## Built (branch feature/directory-multisource, worktree /tank/nxeon-wt-dir2)
- Providers: lib/directory-ingest/providers/{types,http,vintagestory,truckersmp,registry,probe-kind}.ts; provider-plan.ts (pure), provider-run.ts (db), probe-dispatch.ts (a2s/slp/raknet), prober.ts generalized.
- Steam: STEAM_EXTRA_APPIDS (19 families) + Setting directory_steam_extra_games; extras UNVERIFIED live (no key used from the sandbox on purpose: prod key not touched).
- Portal: lib/directory-portal.ts (pure filters/sort/attribution), components/nx/DirectoryView.tsx, app/dashboard/directory/page.tsx now calls loadDirectory().
- Admin: DirectorySourcesPanel + adminSaveSourcesConfig. Worker: directory-sources tick. Schema: ExternalServer.attribution, .probeKind (additive).
- Throwaway PG at /tank/pg-dir2 port 54398 (db dir2) used for DB tests; stop with pg_ctl -D /tank/pg-dir2/data stop and rm -rf /tank/pg-dir2.
- Test run: all directory tests 98/98 with --test-concurrency=1 (DB files share one DB). tsc 0 errors.

## Live verification (sandbox, 2026-10-04, polite: ~6 requests to VS, 3 to TMP, 2 SLP, 1 RakNet)
- Vintage Story list: 200, 4.5 MB, 2,460 rows (adapter parsed 652 open public servers: 1,480 password + 718 whitelisted dropped, :443 and IPv6 refused), ETag round trip -> 304 verified through the adapter.
- TruckersMP /v2/servers: 200, adapter parsed 10 official servers (ETS2/ATS), online flag carried.
- SLP mc.hypixel.net: alive, max 200000 (first run exposed an over-strict plausibility cap of 100k; fixed to 10M).
- RakNet play.cubecraft.net: alive, 11735/55000, rtt 11 ms.
- BLOCKED evidence: BattleMetrics site/robots/docs/terms = Cloudflare 403 challenge; plutonium.pw 403 + challenge; play.eco Turnstile; factorio get-games => {"message":"Missing username."}; fivem single/<code> 404 without a valid code.
- NOT verified: Steam GetServerList (needs key; not used), any Steam extra appid, A2S against a real server, the portal page rendered in a browser, next build.

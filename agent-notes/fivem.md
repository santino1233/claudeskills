# FiveM agent notes (2026-10-01)

Branch `feature/fivem-game-server`, worktree `/opt/nxeon-wt-fivem`.
Commits: `ccfdd82781` (feature) and `20308cdb7a` (merge of main).

## Verdict
**NO-GO for selling FiveM** until the owner has written permission from Cfx.re/Rockstar (or partner status), or a counsel sign-off.
- The Creator PLA (10 Sept 2026), s5.2, lets Rockstar name authorized or exclusive server-hosting providers and prohibit "Unauthorized Service Providers".
- fivem.net/server-hosting lists six authorized partners: GPORTAL, Shockbyte, Nitrado, Nodecraft, xREALM and ZAP-Hosting. Nxeon is not one of them.
- txAdmin's own bundled docs say its GSP config is "in no way … permission for anyone to become an unauthorized GSP".
- Full sources: `docs/FIVEM-HOSTING-LEGAL-OPS.md`. Raw research: scratchpad `fivem-legal-research.md` and `pla.txt`.

## What's built (off by default)
- **Flag.** `FIVEM_ENABLED` must be exactly `1`. Otherwise `lib/game-order.ts` refuses every fivem order.
- **No plans exist.** Nothing is seeded. `prisma/seed-fivem.ts` needs `FIVEM_ENABLED=1 FIVEM_SEED_CONFIRM=yes`. Its prices are proposals: $14.99 for 4 GB/48, $27.99 for 8 GB/128, $49.99 for 16 GB/255.
- **Libraries:**
  - `lib/fivem.ts`: pure logic and parsers.
  - `lib/fivem-license.ts`: the BYO key. It is AES-GCM sealed at the form boundary into the `_fivemLicenseEnc` marker, so it never goes into Stripe/PayPal metadata. RCON and players-token secrets are derived per server.
  - `lib/fivem-install.ts`: the installer and run scripts.
  - `worker/fivem.ts`: settings apply, players, txAdmin PIN, and the public `/info.json` probe.
- **Network:**
  - Every fivem order needs a dedicated IPv4. tcp and udp must use the same public port, and PortForward.publicPort is unique across protocols.
  - txAdmin is published on the guest's loopback only and is reached through an SSH tunnel.

## Hook-ups outside my area (for the integrator)
- `worker/game-variant.ts`: buildGameSetupScript gains an `id?` and a fivem step.
- `worker/game-config.ts`: new `case "fivem"`.
- `worker/game-control.ts`:
  - playerTrackingSweep has a fivem branch;
  - REINSTALL_FIELDS gains `gamePlan.slots`.
- `worker/game-runtime.ts`: a `fivem_info` readiness check.
- `worker/game-update.ts`: now uses `hasUpdateSource`.
- `lib/game-update-verify.ts`:
  - a fivem branch in updateCommand;
  - `hasUpdateSource`;
  - a new AutoUpdatePlan kind, `channel`, with its copy;
  - `fivem` added to SERVICE_HINT.
- `components/customer/GameAutoUpdate.tsx`: the planKind union widened.
- `components/admin/GameRuntimeCard.tsx`: a label for `channel`.
- `test/game-update.test.ts`: fivem is exempted from the "no source" shape check.
- `lib/actions-game-config.ts`: sealing and the slot cap.
- `lib/game-order.ts`: the gate, sealing, and the 480-char metadata guard.
- Registries: `lib/games.ts`, `lib/game-config.ts`, `lib/game-control.ts`, `lib/game-mods.ts`, `lib/mods/installers/index.ts`, `lib/game-player-recommend.ts`, `lib/game-visual.ts`, `lib/marketing/gameLocationLandings.ts`.

## Verification
- `test/fivem.test.ts`: 21 tests, all passing. The real-artifact installer test is opt-in with `FIVEM_ARTIFACT_FILE=/tmp/fivem-artifact/fx.tar.xz`.
- Full suite: 44 failures, the same set as main.
- Typecheck is clean after `prisma generate` in the worktree copy.
- The artifact was downloaded once, to `/tmp/fivem-artifact/fx.tar.xz`. Build 35245, sha256 `16fcffd5…9b2f`.
- FXServer was run offline with `unshare -n` as uid 65534:
  - the generated cfg was parsed;
  - it then stopped at the licence check;
  - txAdmin mode printed the PIN line.

## Not done
- A licensed live server. There is no key, and the brief allowed no VM.
- Running the container.
- The marketing page. It was deliberately not added, because of the NO-GO.
- A portal card for the txAdmin PIN, and an authenticated txAdmin proxy.
- A one-click resource catalogue.
- Adding `fivem` to `REAL_APPLY_FAMILIES`. That waits on live verification.

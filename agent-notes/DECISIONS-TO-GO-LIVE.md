# Decisions to get everything live

Written 2026-10-08. How to use this: tick one box per decision (`[x]`). My recommendation is marked **(rec)**. Tell me "go with my recommendations" and I'll treat every unticked item as the **(rec)** option. Nothing here has been deployed; every branch is still unmerged.

---

## 0. Order of release (pick the pace)

Recommended order, lowest risk first:

1. playnxeon.com migration (switch off, then cutover)
2. Bare-metal catalogue filter polish (already merged to main, just not deployed)
3. Cyrus v6 (Minecraft only), gated, after the security review
4. Dedicated servers, only after the money-path tests and a Stripe test-mode run
5. Other games, one at a time, each after a real load test

- [ ] **(rec)** Staged: merge Cyrus v6 into `integ/cyrus-v6` first, test it, then deploy with everything gated off
- [ ] Merge and deploy everything in one batch (not recommended; nothing has been tested together)
- [ ] Wait for the weekly limit reset before any merge work **(rec if you're still near the limit)**

---

## A. Launch blockers (must be resolved before public Cyrus)

### A1. Security review of the build service's safety scan
The live scan likely has bypass gaps even with networking off (reflection only warns, method-reference targets aren't inspected, some DNS-resolving and dynamic-code APIs aren't blocked). Details: `/root/agent-notes/cyrus-v6/capabilities/THREAT-MODEL.md` row T20. Found by reading code, untested.

- [ ] **(rec)** Hold public Cyrus until a human security reviewer has checked it; Cyrus stays preview-only meanwhile
- [ ] Have me schedule a hardening agent after the limit resets, then still get a human review
- [ ] Accept the risk and launch anyway (not recommended)

### A2. Who is the human security reviewer, and what do they get?
- [ ] I prepare the scope pack (`ROLLOUT.md` in the capabilities notes) and you engage someone **(rec)**
- [ ] Skip for now

### A3. Billing basis for public launch
You're on the subscription (OAuth token) until public launch.
- [ ] **(rec)** Switch the build service to an API key at the moment `cyrus_public_enabled` is turned on, not before
- [ ] Move to an API key now

---

## B. Cyrus (AI mod studio)

### B1. Model icons (Katara = 1 crystal, Saka = 2, Yakko = 3)
- [ ] **(rec)** Approve the crystal design as is
- [ ] Swap for different artwork (tell me which)

### B2. Cyrus avatar
Currently the placeholder `iconset-r2-1`.
- [ ] Keep `iconset-r2-1`
- [ ] Pick another from the picker artifact (https://claude.ai/artifact/XDphNe23qhwxiB8juvBgkc) and tell me the id

### B3. Plan estimates ("N small mods · M edits")
They assume one edit costs 0.8× a small mod. One measured Katara edit cost more.
- [ ] **(rec)** Keep for now and measure after launch
- [ ] Measure first (small paid run after the reset)

### B4. The 16 universal categories (names and labels)
Environment, Creatures, Weapons, Items, Magic, Vehicles, Gameplay, Quests, Minigames, Economy, Admin, Utility, Interface, Visuals, Audio, Performance.
- [ ] **(rec)** Approve as is
- [ ] Rename/merge some (tell me which)

### B5. "Creepers drop diamonds" should file under
- [ ] **(rec)** Creatures & NPCs (what the sorter picks now)
- [ ] Items & gear

### B6. Run the category migration on production data?
Re-sorts existing projects into the new categories. Dry run by default; refuses non-throwaway DBs unless overridden.
- [ ] **(rec)** Yes, after the merge, dry run first and I show you the result
- [ ] No, only new mods use the new categories

### B7. Community: remixing default
- [ ] **(rec)** OPEN by default (creators can switch it off per mod)
- [ ] Closed by default (creators opt in)

### B8. Community: installing someone else's published mod on your own server
Built, but off behind `cyrus_install_published_enabled`.
- [ ] Turn on at launch
- [ ] **(rec)** Leave off until the security review is done, then turn on
- [ ] Never offer

### B9. "Community-tested" laurel badge rules
Currently: 5+ other accounts running it, 3+ ratings averaging 4.0+, 7+ days published, no open bug on the current version, built for newest Minecraft, passed the safety check.
- [ ] **(rec)** Approve these thresholds
- [ ] Change them (tell me the numbers)

### B10. Who can rate / star
- [ ] **(rec)** Ratings only from people who installed the mod; stars from anyone signed in
- [ ] Any signed-in user can rate

### B11. Admin portal (`/admin/cyrus`)
- Should SUPPORT staff see build prompts? (today only ADMIN)
  - [ ] **(rec)** No
  - [ ] Yes
- Keep the "re-run build" action? It spends real AI money and holds the customer's tokens.
  - [ ] **(rec)** Keep, ADMIN only, with the confirm box
  - [ ] Remove it
- Which price basis for the margin figure?
  - [ ] **(rec)** Top-up rate (what customers really pay for tokens)
  - [ ] Cheapest plan rate

### B12. Lifecycle (install, enable/disable, Broken/Outdated, updates, creator warnings)
Everything ships off. Switches: `cyrus_lifecycle_enabled`, `cyrus_compat_watch_enabled`, `cyrus_compat_watch_dry_run` (on). Broken detection also needs `ENABLE_MOD_HEALTH=1`; auto-disable and auto-update need `ENABLE_REAL_GAMEMODS=1`.
- [ ] **(rec)** Turn on lifecycle for preview accounts first, compat-watch in dry run for a week, then live creator warnings
- [ ] Turn everything on at launch
- [ ] Leave off

### B13. Minecraft 26.x
Paper already ships 26.1–26.3; Cyrus only builds 1.21.1–1.21.11, so 26.x servers show Cyrus mods as Outdated with no build button.
- [ ] **(rec)** Add 26.x support to the build service soon (separate task after the reset)
- [ ] Not yet; say "1.21.x only" on the marketing page

### B14. Networking for mods (a mod calling an outside server)
Built, OFF, hard limits. Not enabled by anything above.
- [ ] **(rec)** Keep OFF at launch; revisit after the security review
- [ ] Approve the block list and free limits in `services/modbuilder/rules/net-policy.json` now (needed before ever turning it on)
- Supply Nxeon's public IP ranges so they can be blocked: [ ] I'll send them later

### B15. AI inside mods (the AI gateway)
Stub only; budgets default 0; never calls a model.
- [ ] **(rec)** Keep off; decide model, price and platform cap before ever enabling
- [ ] Decide now (tell me the model, price and daily platform cap)

### B16. Pattern library (verified code patterns)
- Licensing policy: Nxeon-authored seed only; third-party only under MIT-0/0BSD/CC0/Unlicense (or MIT/Apache/BSD with a notice file); GPL/AGPL/LGPL/MPL, CC-BY-SA, unlicensed and scraped code refused. PaperMC docs samples are CC-BY-SA, so reference only.
  - [ ] **(rec)** Approve this policy
  - [ ] Also allow attribution-required licences (MIT/Apache/BSD) as seed
- Customer contribution opt-in (unticked-by-default checkbox, withdrawal removes the patterns): needs your terms-of-service wording.
  - [ ] **(rec)** Park until after launch
  - [ ] I'll write the wording; tell me when
- The ~$6 A/B run (`v6-off` vs `v6-attach`) to see if the library helps:
  - [ ] **(rec)** Approve, but only after the limit resets and after the 0.5 build service is the deployed baseline
  - [ ] Skip it

### B17. Effort comparison eval (v7 `MB_EFFORT=medium`)
- [ ] **(rec)** Hold until the limit resets, then run it
- [ ] Skip

### B18. Marketing page `/cyrus`
Gated by `cyrus_public_enabled` (off = 404, noindex, hidden from sitemap).
- Flip the gate when?
  - [ ] **(rec)** After the v6 merge, the "Next:" copy lines are updated, and the security review (A1) is done
  - [ ] Flip for preview accounts only (already the case)
- Keep the page's own light/dark toggle on an otherwise dark-only site?
  - [ ] **(rec)** Keep
  - [ ] Remove

### B19. Cyrus v5 deploy
v5 was never deployed; v6 contains it.
- [ ] **(rec)** Skip v5; ship v6 only
- [ ] Deploy v5 first (extra work, no benefit)

---

## C. Other games (all stay "Coming soon" unless you say otherwise)

Only Minecraft has a real AI build pipeline. For every other game, Cyrus currently streams template code. None has been loaded into a real game.

### C1. Which games are in the launch?
- [ ] **(rec)** Minecraft only at launch; others show "Coming soon"
- [ ] Minecraft + Valheim (most verified of the rest: 47/47 compile against the real 1.0.17 server files, still no in-game test)
- [ ] Minecraft + Valheim + Terraria (TShock plugins only; tModLoader can't run on Nxeon)
- [ ] Other (tell me)

Palworld and Rust are paused and not in the launch. Zomboid is validated by static checks only.

### C2. Wire a game into the real AI build service
This is a C# (or Lua) worker on the build VM that uses each game's knowledge pack and validator. It's the thing that makes a game real.
- [ ] **(rec)** Valheim first, after launch
- [ ] Terraria (TShock) first
- [ ] Zomboid first
- [ ] Not planned yet

### C3. Valheim
- OK to download the free dedicated server's DLLs at build time for compile checks (never shipped, never in git)?
  - [ ] **(rec)** Yes
  - [ ] No
- AI disclosure wording on packages: "created with the assistance of generative AI (Nxeon Cyrus)"
  - [ ] **(rec)** Approve
  - [ ] Change it
- Allow publishing Valheim mods to Thunderstore?
  - [ ] **(rec)** Only after a real load test passes, never automatically
  - [ ] Never
- Content mods require players to install the Jötunn library so versions can be enforced
  - [ ] **(rec)** Accept
  - [ ] Reject (weaker version protection)

### C4. Terraria
- Offer a tModLoader Terraria server variant on Nxeon? (needed for content mods)
  - [ ] **(rec)** Not now; label content mods "for your own tModLoader game/server"
  - [ ] Yes, add it later
- Docker/podman on the build host so plugins get a live load test?
  - [ ] **(rec)** Yes, in a sandbox VM (needs a VM allocation approval)
  - [ ] No
- Placeholder art uses the player's own game images (referenced, not copied)
  - [ ] **(rec)** Acceptable for launch
  - [ ] Creators must upload art before publishing to the store

### C5. Project Zomboid
- Real load tests need a sandbox VM with 4–6 GB RAM:
  - [ ] **(rec)** Approve when Zomboid is next in line
  - [ ] No
- How players get the files: Steam Workshop only works with the creator's own Steam account; Nxeon can't upload for them.
  - [ ] **(rec)** Manual "server pack" download for now
  - [ ] Workshop-only
- Zomboid's Modding Policy forbids selling mod access: community/store Zomboid mods must stay free and credit forks.
  - [ ] **(rec)** Accept
- Install flow must refuse Cyrus mods on `b41` (Legacy) servers: [ ] **(rec)** Yes, refuse

### C6. Palworld and Rust (paused)
- Palworld: Linux-only means settings presets + client tips, no server mods. How presets get installed on Nxeon:
  - [ ] Panel fields
  - [ ] Raw-config mode with a merge
  - [ ] Decide when Palworld resumes **(rec)**
- Rust: keep a copy of the free Rust dedicated server's files on node-2 for real compile checks?
  - [ ] **(rec)** Yes when Rust resumes
  - [ ] No
- [ ] **(rec)** Leave both parked until after launch

---

## D. Dedicated servers (bare metal)

### D1. Automatic supplier purchase
Today a machine is bought by hand after the customer pays. Auto-buying spends real money on the supplier account; the safety classifier blocked me from writing it. Proposed safeguards are in `/root/agent-notes/bm-release/ops/AUDIT.md`.
- [ ] **(rec)** Keep manual at launch; go live with a "delivered within 24 hours" promise
- [ ] Approve auto-purchase with the safeguards in AUDIT.md (you must explicitly authorise the spend; I'll build and test it with the supplier mock)

### D2. Auto-pay (renewals)
Off until `dedicated_autorenew_enabled`. Wallet first, then saved card. 3 days grace → suspended → ended at 10 days.
- [ ] **(rec)** Turn on after the money-path tests pass; keep 3 days grace and end at 10
- [ ] Different grace/end days (tell me)
- [ ] Leave off

### D3. Credit rules
- Gift codes and positive admin balance adjustments are treated as promotional credit (can't pay for dedicated). Should gift codes count as real money?
  - [ ] **(rec)** No, treat as promotional
  - [ ] Yes, count as real money
- Any promotional credit ever granted stays held back, even after being spent elsewhere. Strict but simple.
  - [ ] **(rec)** Keep strict at launch
  - [ ] Make it exact (track spend per grant; more work)

### D4. Admin pricing below cost
- [ ] **(rec)** Add a cost-floor warning later (a hard floor broke 2 pricing tests)
- [ ] Allow, no floor

### D5. Terms of Service
Add the dedicated-server section including "a chargeback suspends the server" (today staff do it by hand).
- [ ] **(rec)** Approve the wording in `docs/DOCUMENTATION.md` ("Bare Metal release hardening") after you read it
- [ ] I'll rewrite it

### D6. SSH key at checkout
The automated handover can't run without one.
- [ ] **(rec)** Required for all dedicated orders
- [ ] Optional (staff finish by hand when missing)

### D7. Tracker ETA
- [ ] **(rec)** Keep anchored to the 24-hour promise even for 1-hour stock codes
- [ ] Show the shorter ETA when stock says so

### D8. Before launch (no decision, just a warning)
- The 13 money-path database tests have never run (a test-setup problem on node-2).
- No Stripe test-mode card payment has been run.
- The support assistant's knowledge base still says bare metal is a custom quote.
- [ ] **(rec)** I fix all three after the reset, before anything is switched on
- [ ] Launch anyway (not recommended for money paths)

---

## E. playnxeon.com migration

Branch `feature/playnxeon-domain` (commit `96efee2c41`). Switch off by default; merging changes nothing visible.

### E1. Start the cutover?
- [ ] **(rec)** Yes: step 1 (merge + deploy, switch off) now; steps 2–5 when you give the word
- [ ] Wait

### E2. The `.env` line (only you can do this; I can't edit `.env`)
After step 1, add to `/opt/nxeon/.env`:

    CLOUDFLARE_PLAYNXEON_API_TOKEN=<the CLOUDFLARE_API_TOKEN value from /root/secrets/cloudflare-playnxeon.env>

then I restart the web and worker units.
- [ ] I'll add it myself
- [ ] Give me an alternative way (tell me)

### E3. Root domain forward
Cloudflare redirect rules need extra token permission; the default is an nginx 301 from `playnxeon.com` and `www` to `https://nxeon.cloud/game-servers`.
- [ ] **(rec)** nginx 301 (no token change)
- [ ] I'll widen the token to allow redirect rules and Cloudflare does it
- Destination page:
  - [ ] **(rec)** `https://nxeon.cloud/game-servers`
  - [ ] Other (tell me)

### E4. DNS records written at step 3
`*.playnxeon.com` A → node-2 (178.63.94.114, DNS-only), root A → the primary (51.79.162.96), `www` DNS-only. The existing placeholder records get replaced.
- [ ] **(rec)** Approve (I dry-run first and show you)
- [ ] Change something (tell me)

### E5. Flip the switch for new servers
Admin > Settings > Free Minecraft: "Create new game servers on the new domain". Rollback = switch off.
- [ ] **(rec)** Test with a throwaway free server, then a throwaway paid server, with a real Minecraft client, then flip
- [ ] Flip straight away

### E6. Token hygiene
The Cloudflare token was pasted in chat.
- [ ] **(rec)** Rotate it or narrow its scope right after the cutover
- [ ] Leave as is

### E7. Known gap
Renaming a paid server leaves the old name's DNS records behind.
- [ ] **(rec)** Fix after cutover (small task)
- [ ] Ignore

---

## F. Housekeeping

### F1. Already-merged bare-metal filter polish (not deployed)
- [ ] **(rec)** Include in the next deploy when the server is quiet
- [ ] Deploy right now

### F2. Test files that fail at import (`server-only`)
`test/cyrus-mods.test.ts` is confirmed failing on the base branch; `cyrus-tokens-economy`, `dedicated-gate` and others are suspected the same.
- [ ] **(rec)** One small task to fix the test runner setup so these run (needed before trusting any combined test run)
- [ ] Ignore

### F3. Untracked throwaway harnesses
Left uncommitted on purpose (`.cyrus-verify/`, `.cyrus-admin-verify/`, community harness). They must never be committed.
- [ ] **(rec)** I keep them out of every commit
- [ ] Delete them after verification

### F4. Agent model for follow-ups
You said to avoid Fable.
- [ ] **(rec)** Sonnet for analysis, test fixing and merges; Opus only for design and new features
- [ ] Opus for everything

---

## Branches waiting to merge (reference)

| Area | Branch | State |
|---|---|---|
| Cyrus base | `feature/cyrus-v6` | done |
| Studio UI | `feature/cyrus-v6-studio` | done, 2nd round of fixes not re-screenshotted |
| Routing + categories | `feature/cyrus-v6-routing` | done, browser-checked |
| Community / NxLabs | `feature/cyrus-v6-community` | code done, never opened in a browser |
| Lifecycle | `feature/cyrus-v6-lifecycle` | tests pass, no screenshots, tsc re-run needed |
| Admin | `feature/cyrus-v6-admin` | typecheck only |
| Capabilities (networking/AI, inert) | `feature/cyrus-v6-capabilities` | done, inert |
| Pattern library | `feature/cyrus-v6-library` | WIP |
| Marketing page | `feature/cyrus-v6-marketing` | done, gated, browser-checked |
| Efficiency | `integ/cyrus-v6` (merged) | done |
| Valheim | `feature/cyrus-v6-game-valheim` | compiles vs real files |
| Terraria | `feature/cyrus-v6-game-terraria` | compiles for real |
| Zomboid | `feature/cyrus-v6-game-zomboid` | static checks only |
| Palworld | `feature/cyrus-v6-game-palworld` | PAUSED WIP |
| Rust | `feature/cyrus-v6-game-rust` | PAUSED WIP |
| Dedicated backend | `feature/bm-ops` | PAUSED WIP, money tests unrun |
| Dedicated wizard + tracker | `feature/bm-wizard` | done |
| playnxeon.com | `feature/playnxeon-domain` | done, switch off |

Agent notes for each live under `/root/agent-notes/cyrus-v6/<name>/`, `/root/agent-notes/bm-release/`, and `/root/agent-notes/playnxeon/`.

# Cyrus architecture (2026-10-09)

Cyrus is Nxeon's AI mod studio: a person describes a mod, Cyrus plans, writes, compiles, safety-checks and installs it on their Nxeon game server. Four layers: the portal, a separate build service on its own VM, per-game support files, and the production plumbing around them.

## Request flow

```
Browser (studio / /cyrus demo)
   |  POST /api/cyrus/generate   (ndjson stream; client re-attaches after 30 s of silence)
   v
Nxeon portal (Next.js on the primary, blue/green behind nginx, + worker)
   |  createModBuild(): access gate -> prompt check -> suspension/game switch
   |                    -> rate limits -> token reserve -> ModBuild row
   |  svcCreate {prompt, mcVersion, tier, images}
   v
Build service (VM 88001, reached over a tunnel; image 0.5)
   |  classifier (Haiku) -> model tier -> Claude Code CLI in Docker
   |  -> Gradle compile -> auto-fix -> bytecode scan -> jar
   v
Portal: stream events + live code, then jar + source
   -> settle tokens -> generate the NxLabs mod page
   -> install on a customer's server (backup, swap, rollback)
   -> Mods tab lifecycle (on/off/update/outdated)
```

## 1. Portal (`/opt/nxeon`, Next.js)

**Studio** (`/dashboard/cyrus`): React app with a store, the game and category network map, and the prompt dock. Top bar: Cyrus entry, token chip, sound toggle.

**Access gate** (`modBuilderUser`, `lib/modbuilder/access.ts`): a private-preview account, or `cyrus_studio_public_enabled` plus a verified email.

**Request pipeline** (`lib/modbuilder/create.ts`), in order:
1. Gibberish check (`lib/cyrus/prompt-check.ts`), before any tokens are held.
2. Account suspension and per-game switch (`/admin/cyrus`).
3. Rate limits: 3 builds a minute, 20 an hour, 2 in flight.
4. Token gate (`lib/cyrus/tokens/builds.ts`): reserve 70, settle to the real cost.
5. Create the `ModBuild` row.
6. Hand off to the build service.

**Token economy** (`lib/cyrus/tokens`): `CyrusTokenAccount`, `Lot`, `Ledger`, `Reservation`. Sources: paid-server grants, Stripe plans, ad-hoc top-ups, a one-time starter grant (`cyrus_tok_starter`, default 70). The plan tier decides which models you can use. Daily caps apply, with a lower cap for new accounts. An account that has ever held tokens keeps its balance pinned in the portal.

**After a build:** `syncBuild` settles tokens and `lib/cyrus-mods/doc.ts` generates the mod's NxLabs page from its versions.

**Install** (`lib/modbuilder/install.ts`): the jar goes to the server through the Mods engine, with backup, one-copy-only and rollback.

**Lifecycle, community, admin:**
- Lifecycle: on/off, updates, outdated warnings.
- Community: listings, stars, remixes, computed community-tested badge.
- `/admin/cyrus`: moderation, users and tokens, game status.

**Public pages:**
- `/cyrus`: generated native page (`tools/nxm/native/cyrus`, regenerate with `python3 tools/nxm/port_pages.py cyrus`). React islands: live core demo, drawn-by-code texture demo, studio illustration, token, badge, sound toggle.
- `/mods/cyrus/[slug]`: public mod page and SEO template (metadata, OG/Twitter, JSON-LD, FAQ, related mods).

## 2. Build service (`services/modbuilder`, VM 88001)

- Receives builds, runs two at a time.
- A one-word Haiku call picks complexity unless the person chose a model. Katara = Haiku 4.5, Saka = Sonnet, Yakko = Opus.
- Runs the Claude Code CLI headless inside Docker (egress limited to Anthropic domains), on a single Claude login session file (`.credentials.json`, mounted outside the CLI home and denied to the model). Claude gets only Read, Write and Edit in a throwaway Gradle workspace.
- The service, not Claude, does the rest:
  - compile with Gradle against the real Paper API jar for the chosen version (offline);
  - known auto-fixes and a pre-check;
  - bytecode scan (`scan.js`: `javap -c -p -v`, whole constant pool);
  - package the jar, record usage and cost.
- On a compile or scan failure it sends Claude a short repair message and resumes the same session. Cheap models can escalate to the next tier.
- Model-facing text lives in `prompts.js`, per-version API sheets in `sheets/`, failure rules in `rules/`. The exact messages are in `cyrus-backend-prompts.md`.
- Supported today: Minecraft only, Paper 1.21.1, 1.21.4, 1.21.8, 1.21.11.
- The hardened `scan.js` is in the repo but still has to be copied to the VM and the image rebuilt.

## 3. Other games

- Each game has a support file in `lib/cyrus/games/` (versions, categories, install facts, verification notes), plus template generators (`lib/cyrus/engine/`) and validators.
- Merged: Minecraft, Terraria, Valheim, Zomboid. Unmerged branches: Rust, Palworld.
- Only Minecraft goes through the real build service. The rest produce template code with no compiler in the pipeline, so they are "coming soon".

## 4. Supporting pieces

| Area | What |
|---|---|
| Switches | `cyrus_studio_public_enabled` (studio), `cyrus_tok_live` (token economy), `cyrus_public_enabled` (`/cyrus` page), `cyrus_mods_public_enabled` (community pages), `cyrus_mod_networking_enabled` (off), `cyrus_tok_starter` |
| Assets | Texture spec + pixel renderer + resource-pack builder in `lib/cyrus/textures` (not wired to the studio yet). Sound is synthesised in the browser (`lib/cyrus/sfx.ts`), off by default |
| Build and deploy | Builds run on node-2 via `scripts/devhost`. `scripts/promote-production.sh` does the zero-downtime release; rollback with `scripts/rollback-release.sh --production` |
| Main tables | `ModBuild`, `CyrusModPage` (+ listing and community tables), token tables, `CyrusPlan` |

## Status on 2026-10-09

- Production runs release `20261009T095149Z-fd6bcb7e` (main = `fd6bcb7e53`).
- Studio, tokens, `/cyrus` and the community pages are gated off.
- To go public: copy the new `scan.js` to the VM and rebuild the image, then flip `cyrus_studio_public_enabled` and `cyrus_tok_live` together.
- `cyrus_public_enabled` and `cyrus_mods_public_enabled` stay off until `/cyrus` has been reviewed on production.

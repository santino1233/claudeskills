# Cyrus master-plan research: shared brief (2026-10-09)

## Who/what
Nxeon is a game-server hosting company. **Cyrus** is its AI mod studio: a customer describes a mod in plain English, Cyrus plans, writes, compiles, safety-checks and installs it on their Nxeon game server; mods are shared on NxLabs (public mod pages, stars, remixes, community-tested badge).

## Current state (verified by the owner/me; treat as fact)
- Only **Minecraft Java (Paper plugins)** goes through the real build pipeline. Supported Paper versions: 1.21.1, 1.21.4, 1.21.8, 1.21.11. "26.x" (the new year-based Minecraft versions) is NOT supported yet.
- Flow: portal (Next.js) -> build service on its own VM -> Claude Code CLI headless in Docker (only Read/Write/Edit tools, throwaway Gradle workspace) -> Gradle compile vs the real Paper API jar (offline) -> auto-fix -> bytecode scan (policy scanner) -> jar -> NxLabs page -> one-click install/uninstall on the customer's Nxeon server (backup + rollback). Model tiers: Haiku/Sonnet/Opus chosen by a classifier or by the user. Token economy (reserve 70, settle to real cost).
- Existing but NOT wired in: a texture spec + pixel renderer + resource-pack builder (`lib/cyrus/textures`), a browser-side sound synthesizer (`lib/cyrus/sfx.ts`). The studio shows "texture and sound studio coming soon".
- The owner owns an original sound-effects library (514 MP3s, mixed general SFX); it can be used as the Sound Studio's built-in asset library (owner will write the customer-facing licence).
- Customers' servers are Nxeon-hosted Docker (itzg/minecraft-server, Paper). Nxeon controls the server, so it can host a resource pack and set `resource-pack`/`resource-pack-sha1` (or push via Paper API).

## The goal being researched
Make Cyrus **the number-one AI game-mod creation studio, Minecraft first**:
1. Maximise how good, correct and capable AI-generated Minecraft mods are (and how efficiently/cheaply they are produced).
2. Maximise the *range* of things a mod can contain: creatures/mobs (with a custom model, textures, animations, MULTIPLE sound effects: ambient, attack, hurt, death, step...), items, blocks, biomes/dimensions/structures, HUDs/UIs/GUIs, particles, recipes, enchantments, bosses, commands, etc. "Literally everything" that is technically possible.
3. Increase compatibility across Minecraft versions (older and newer, incl. 26.x).
4. Integrate a Texture Studio and Sound Studio so Cyrus **automatically** creates models/textures/sounds with a mod (e.g. a "banshee" mob gets model + textures + attack/death/idle sounds), and the customer can then open the mod's own assets in the studios to edit them.
5. Assets must reach players: a resource pack is client-side. Players accept a server-pushed pack prompt; they do not download manually.

## Constraints for you (the researcher)
- READ-ONLY research. Do **not** modify any server, repo, database, or setting. Do not run anything that costs money or sends messages. Do not touch production.
- Use WebSearch/WebFetch heavily. **Open the real sources** (docs, repo READMEs, LICENSE files, release notes). Label every claim: `VERIFIED (url)` if you opened the source, or `UNVERIFIED` if from memory. The date today is 2026-10-09; prefer sources from 2025-2026; flag anything that may be stale.
- Licences matter: Nxeon is commercial/proprietary. Always record the exact licence and whether it allows embedding, calling as a separate process, or reference-only. GPL/AGPL/PolyForm-NC/"free download" are NOT assumed usable.
- Be concrete and opinionated: end with a recommendation, a build/buy/avoid list, risks, and a rough effort size (S/M/L) per item. Say what you could not determine.
- Write your full findings (markdown, with a sources list) to the file path in your task, then reply with a summary of at most ~500 words. Do not paste the whole file into your reply.

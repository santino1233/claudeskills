# ChunkMirror: fresh from-scratch prompt (2026-10-12), the style the prompt coach should compile to

Start as a NEW mod (not a refine), Saka, untick "Item with abilities".

**Build a Paper plugin called ChunkMirror for Minecraft 1.21.11.**

**Blocks:** Whenever a player places a block, the same block (same type and orientation, same position inside its chunk, same height) is also placed in the surrounding chunks. Whenever a player breaks a block, the matching block in those chunks is removed too. The radius is configurable: default 4 chunks in every direction (about 80 extra chunks), maximum 8.

**Mob spawners:** When a mob spawns from a mob spawner block, the same kind of mob also spawns at the matching position in the surrounding chunks, using the same radius. Limit it to at most 20 mirrored mobs per spawn and 200 mirrored mobs alive in total (both configurable). Mirrored mobs must never trigger more mirroring.

**No duplication:** Blocks placed by the mirroring are remembered by the plugin, kept across restarts, with a size limit. If a player breaks one of those mirrored blocks, no item drops. A block the player placed themselves drops normally.

**Dimensions:** It works in the Overworld, the Nether and the End, and each can be switched on or off in config.yml. If the matching position is inside solid terrain or the void, skip it quietly.

**Performance:** Spread the work across several server ticks (configurable chunks per tick) with a queue limit. Pause mirroring automatically if server TPS stays below 15 for 10 seconds, and tell online operators. Changes aimed at unloaded chunks are remembered and applied when those chunks load.

**Commands:** /chunkmirror status, on, off and reload, with permission chunkmirror.admin. Every setting above lives in config.yml with a comment.

## Structure the prompt coach compiles to (feature/cyrus-prompt-coach, lib/cyrus/coach/compile.ts)
New mod: `Build a Paper plugin [called <Name>] for Minecraft <version>.` then labelled paragraphs, each only when it applies:
What it does / When / Numbers (all configurable) / Limits / Modes / No duplication / Dimensions / Saved data / Performance / Must not happen / Player feedback / Commands (+ permission) / Config.
Change request: `Change to <Mod>: <the change>.` + the same paragraphs + `Unchanged: <what stays, as facts>. Only the parts described above change.` (never "keep everything exactly as it is": the 2026-10-12 guard false refusal).
The prompt above maps to: What it does = Blocks + Mob spawners; Numbers/Limits = radius 4 max 8, 20 per spawn, 200 alive; No duplication; Dimensions; Performance; Commands + config.

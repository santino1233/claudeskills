# AI Mod & Plugin Builder: Flagship UX

Draft wireframes, 2026-10-06. Per the owner's model-split rule, visual design (colours, type, motion) waits for the owner's go-ahead. These wireframes cover structure and flow only.

## Principles
These come from the UX research in RESEARCH §3.

1. **Spec before code.** The user confirms a plain-English plan, with commands, permissions, GUIs and tests, before we spend anything. This copies Lovable's Plan Mode and Roblox's Planning Mode.
2. **Previews come from the spec, not the model.** They are instant, free and editable by hand. Minecraft has no instant web preview, so we render the parts that matter: commands, GUIs, chat and config.
3. **Show the proof.** Every build has a test timeline and a safety report. "It works" is demonstrated, not claimed.
4. **Price honesty.**
   - Show the price before running, and the real cost after.
   - Failed builds are free.
   - The fix loop is capped and explained.
   - This answers the #1 complaint about Bolt, Lovable and Replit.
5. **Non-coders first, coders welcome.** Code stays one tab away (source, diff, git export) and is never in the way.
6. **Never lose work.** Every build is a version. Restore is always one click.

## Flow map

```
Landing ─► Templates gallery ─┐
   │                          ▼
   └──► Sign up / Sign in with Nxeon ─► Onboarding (server + experience) ─► Workspace
                                                                           │
   Workspace = [Chat] + [Spec Card] + [Preview]  ──► Plan & price confirm ──► Build & Test (live)
                                                                           │
                         ┌──────────────── Results (pass / fail / blocked) ◄┘
                         ▼
               Install to server ─► Installed ─► Server health / Fix-from-logs ─► (back to Workspace)
                         │
                         └─► Versions & Diff · Download (.jar + source) · Share
```

---

## Screen 1: Landing + Templates gallery

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ [logo] Modwright            Templates  Pricing  Docs        [Sign in] [Start] │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   Describe it. We build it, test it, and install it.                         │
│   Custom plugins & datapacks for Minecraft servers — tested by a bot          │
│   on a real server before you ever install it.                               │
│                                                                              │
│   ┌──────────────────────────────────────────────────────────────┐ [Build ▶] │
│   │ e.g. "A /shop GUI where players buy kits with in-game money" │           │
│   └──────────────────────────────────────────────────────────────┘           │
│   Paper 1.21.11 ▾   Plugin ▾          ✓ tested  ✓ safety-scanned  ✓ source    │
│                                                                              │
│  Start from a template                                   [All] [Economy] ... │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │ ▦ Shop   │ │ ⚔ Kits   │ │ ⌂ Homes  │ │ ☠ Boss   │ │ ⚑ KOTH   │            │
│  │ GUI shop │ │ cooldown │ │ /sethome │ │ phases + │ │ minigame │            │
│  │ + Vault  │ │ + perms  │ │ + warps  │ │ loot     │ │ arenas   │            │
│  │ 92% pass │ │ 97% pass │ │ 98% pass │ │ 81% pass │ │ 74% pass │            │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘            │
│  Claims · Daily rewards · Chat format · Scoreboard · Parkour · Crates* ...    │
│                                                                              │
│  Not an official Minecraft product. Not approved by or associated with       │
│  Mojang or Microsoft.                                                        │
└──────────────────────────────────────────────────────────────────────────────┘
```

- The per-template "pass" figures are **real rolling success rates** from telemetry. Never show invented numbers (Nxeon honesty rule).
- *Crates: cosmetic or in-game currency only, no real-money gambling (AUP).

## Screen 2: Onboarding (3 quick steps, all skippable)

```
┌──────────────────────── Let's set up your first build ───────────────────────┐
│ 1 Where will it run?                                                         │
│   (•) My Nxeon server   [minecraft-lq4amk · Paper 1.21.11 · 12 plugins ▾]     │
│   ( ) Another server — I'll download the jar (Connector available in v1)      │
│   ( ) Just exploring — pick version: [Paper 1.21.11 ▾]                        │
│                                                                              │
│ 2 How comfortable are you with code?                                         │
│   (•) Not at all — keep it simple     ( ) I can read it     ( ) I'm a dev     │
│      → hides code tabs by default         → shows Source tab     → diff + git │
│                                                                              │
│ 3 What do you want to make first?                                            │
│   [ Economy ] [ Minigame ] [ Custom mob ] [ Kits ] [ Claims ] [ Something else]│
│                                                     [Back]   [Continue ▶]    │
└──────────────────────────────────────────────────────────────────────────────┘
```

- On Nxeon, the server's software, version and plugin list are auto-detected. This prevents version mistakes and lets the spec reuse installed plugins such as Vault and LuckPerms.

## Screen 3: Workspace (the flagship screen)

```
┌─ SimpleShop ▾ · Paper 1.21.11 · v3 (draft) ───────────── ◔ 1,240 credits ─ [?] ─┐
├───────────────────────────┬──────────────────────────────┬──────────────────────┤
│ CHAT                      │ SPEC CARD                    │ PREVIEW              │
│                           │ Overview Commands Perms GUIs │ [GUI] [Chat] [Cmds]  │
│ You: a shop where players │ Config Messages Tests  {Code}│                      │
│ buy diamonds and kits     │──────────────────────────────│  ┌ Server Shop ────┐ │
│ with money                │ SimpleShop                   │  │ ░ ░ ░ ░ ░ ░ ░ ░ ░│ │
│                           │ GUI shop selling items for   │  │ ░ ░ ◆ ░ ⚔ ░ ▣ ░ ░│ │
│ AI: Got it. Two questions:│ in-game money.               │  │ ░ ░ ░ ░ ░ ░ ░ ░ ✕│ │
│  1. Use your existing     │                              │  └─────────────────┘ │
│     economy (Vault +      │ Uses: Vault (found on server)│   ◆ Diamond          │
│     EssentialsX found) ?  │                              │     Price: $100      │
│     [Yes] [No, built-in]  │ Commands                     │     Left-click: buy 1│
│  2. Who can open it?      │  /shop  — open shop  (all)   │                      │
│     [Everyone] [Perm only]│  /shop reload — admin (op)   │  Chat preview:       │
│                           │                              │  ✔ You bought Diamond│
│ You: yes, everyone        │ GUIs  main (3 rows, 3 items) │    for $100.         │
│                           │ Config  currency, items[]    │                      │
│ AI: Updated the spec →    │ Tests  3 acceptance checks   │  This plugin will:   │
│  added "/shop reload".    │                              │  ✓ read/write its own│
│                           │ ⚠ Not possible: new block    │    folder only       │
│                           │ types (needs client mod).    │  ✗ no internet       │
│ ┌───────────────────────┐ │ Offer: custom item look via  │  ✗ no commands as    │
│ │ Ask for a change…     │ │ resource pack (v1)           │    console           │
│ └───────────────────────┘ │                              │                      │
│ [📎 attach]  [Templates]  │ Est. 300–450 credits         │                      │
├───────────────────────────┴──────────────────────────────┴──────────────────────┤
│ Versions: v1 ✓ v2 ✓ v3 draft     [Review plan & build ▶]  (charged only if it   │
│                                                            passes)              │
└─────────────────────────────────────────────────────────────────────────────────┘
```

**Spec Card tabs.** Each tab can be edited directly, with no AI needed:
- **Commands:** a table of name, aliases, args, permission, player-only, description.
- **Perms:** a tree view (`simpleshop` → `use`, `admin` → `reload`) with default (true/op/false) toggles. Follows the `<plugin>.<area>.<action>` convention.
- **GUIs:** a drag-and-drop chest grid. Pick an item from the asset library, set name and lore in MiniMessage with live colour rendering, and set the click action.
- **Config:** a form generated from the config schema, with a "view YAML" toggle.
- **Messages:** every player-facing string, with a MiniMessage preview, ready for translation.
- **Tests:** human-readable Given / When / Then acceptance checks. The user can add their own ("when I type /shop as a player without money…").
- **{Code}:** hidden for non-coders. Read-only source of the last build, with a diff against the previous version.

**Preview pane:**
- Minecraft-*style* chest GUI using our own icon set (never Mojang textures).
- Chat rendering.
- Command list in `/help` format.
- Capability summary ("This plugin will…").

**Honest-limits banner.** When the request needs client-side content, explain why and offer the closest feasible option.

## Screen 4: Plan & price confirm (modal)

```
┌──────────────────────────── Review before building ──────────────────────────┐
│ What we'll build                         What we'll test (bot on real server) │
│ • /shop opens a 3-row GUI                ✓ A1 player with $150 buys Diamond →   │
│ • Clicking an item buys it via Vault       has 1 diamond, balance $50          │
│ • /shop reload (op) reloads config       ✓ A2 player with $20 can't buy →       │
│ • Items & prices in config.yml             "Not enough money", nothing given   │
│                                          ✓ A3 /shop reload as non-op denied    │
│ Won't do: real-money purchases, new                                           │
│ block types                              Safety: own-folder files only,        │
│                                          no network, no console commands       │
│ Target: Paper 1.21.11 (your server)                                           │
│                                                                              │
│ Price: 300–450 credits ($1.50–$2.25) · charged only if all tests pass         │
│ Typical time: 3–5 min                                                        │
│                                  [Edit spec]   [Build & test ▶]               │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Screen 5: Build & Test (live progress)

```
┌─ Building SimpleShop v3 ──────────────────────────────────────── 02:41 ───────┐
│  ● Plan  ──  ● Code  ──  ● Compile  ──  ● Safety scan  ──  ◐ Live test  ── ○   │
│                                                                              │
│  Compile: ✓ (attempt 2 — fixed "cannot find symbol Material.RUBY" → EMERALD) │
│  Unit tests: ✓ 6/6                                                           │
│  Safety: ✓ PASS — capabilities: data folder files                            │
│                                                                              │
│  LIVE TEST — Paper 1.21.11 #132 · bot "Tester1"                [Pause view]  │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │ 00:00 server  started in 14.2s, SimpleShop v3 enabled                   │  │
│  │ 00:03 console eco give Tester1 150                                      │  │
│  │ 00:04 bot     joined                                                    │  │
│  │ 00:05 bot     /shop                                                     │  │
│  │ 00:05 bot     window opened "Server Shop" (27 slots)        ✓ A1 step 1 │  │
│  │ 00:06 bot     click slot 11                                             │  │
│  │ 00:06 chat    "You bought Diamond for $100."                ✓ A1 step 2 │  │
│  │ 00:06 check   inventory DIAMOND ×1 · balance 50.0           ✓ A1 PASS   │  │
│  │ 00:09 ...     A2 running                                                │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│  Cost so far: 212 credits (held, refunded if it fails)        [Cancel build]  │
└──────────────────────────────────────────────────────────────────────────────┘
```

- Repairs are shown transparently, in plain English, with the original error in an expandable section.
- At most 3 repairs. After 2 failures, the system offers to "simplify the spec" instead of looping.

## Screen 6: Results

```
┌─ SimpleShop v3 — ✓ All 3 tests passed ───────────────────────────────────────┐
│  [Install on minecraft-lq4amk ▶]   [Download .jar]  [Download source .zip]    │
│                                                                              │
│  Test report   A1 ✓  A2 ✓  A3 ✓        [Replay timeline]                      │
│  Safety report PASS · capabilities: own data folder · 0 findings  [Details]   │
│  Changelog     v3: added /shop reload; prices now in config.yml               │
│  Cost          341 credits ($1.71)                                           │
│                                                                              │
│  Did it do what you wanted?   [👍 Yes]   [👎 Not quite → tell us]              │
└──────────────────────────────────────────────────────────────────────────────┘
```

**Failure variant:**
- "✗ Test A2 failed: player received the diamond with $20."
- Shows the failing step in the timeline.
- [Try a fix: about 100 credits, free if it fails] or [Edit the spec].
- **No credits are charged.**

**Blocked variant:**
- Plain-language reason ("This request would give a hidden user operator access") and a link to the AUP.
- No retry button.

## Screen 7: Install to server

```
┌──────────────────────── Install SimpleShop v3 ───────────────────────────────┐
│ Server: minecraft-lq4amk (Paper 1.21.11) ✓ compatible                         │
│ Requires: Vault ✓ installed · EssentialsX ✓ (economy provider)               │
│                                                                              │
│ [✓] Back up plugins/ and SimpleShop data before installing                   │
│ When to apply:  (•) Restart now (3 players online — warn them 60s first)      │
│                 ( ) Next scheduled restart   ( ) I'll restart myself          │
│                                                                              │
│ Rollback: one click from this project or the server's Mods tab               │
│                                             [Cancel]   [Install ▶]            │
└──────────────────────────────────────────────────────────────────────────────┘
```

- Paper discourages `/reload`, so install means placing the jar and restarting. We say that plainly.
- Non-Nxeon (v1): "Install via Connector" (signed pull plus restart scheduling), or Pterodactyl, or download.

## Screen 8: Installed plugin health + Fix-from-logs (v1)

```
┌─ SimpleShop on minecraft-lq4amk ─────────────── v3 · installed 2 days ago ───┐
│ Status ● running   Errors (24h): 3   Players used /shop: 41                   │
│                                                                              │
│ ⚠ NullPointerException in ShopGui.onClick (x3)  first 10:14, last 12:02       │
│   when: player clicked empty slot 26                                         │
│   [Fix this ▶ ~80 credits, free if it fails]   [Show stack trace]             │
│                                                                              │
│ Versions on server:  v3 (current)  ·  v2  [Roll back to v2]                   │
└──────────────────────────────────────────────────────────────────────────────┘
```

- Fix-from-logs creates a new spec revision with an added regression test ("clicking an empty slot does nothing") and runs the same pipeline.

## Screen 9: Versions & Diff

```
┌─ SimpleShop · History ───────────────────────────────────────────────────────┐
│ v4  fix: empty-slot click     ✓ tests  341→ +1 test   [Restore] [Diff v3]     │
│ v3  add /shop reload          ✓ tests  installed      [Restore] [Diff v2]     │
│ v2  prices in config          ✓ tests                 [Restore]               │
│ v1  first build               ✓ tests                 [Restore]               │
├──────────────────────────────────────────────────────────────────────────────┤
│ Diff v3 → v4      Plain English | Code                                       │
│  • Clicking an empty or decoration slot now does nothing (was a crash)        │
│  ShopGui.java                                                                │
│  - ItemStack it = e.getCurrentItem(); var def = items.get(it.getType());     │
│  + ItemStack it = e.getCurrentItem(); if (it == null || it.isEmpty()) return;│
└──────────────────────────────────────────────────────────────────────────────┘
```

## Screen 10: Asset library browser (side drawer, opened from GUIs/Config)

```
┌─ Asset library · Paper 1.21.11 ─────────────────────────── [search: "sword"] ─┐
│ Items  Blocks  Entities  Sounds  Particles  Effects  Enchants  Biomes  Patterns│
│ ┌────┐┌────┐┌────┐┌────┐┌────┐                                               │
│ │ ⚔  ││ ⚔  ││ ⚔  ││ ⚔  ││ ⚔  │  DIAMOND_SWORD · minecraft:diamond_sword       │
│ └────┘└────┘└────┘└────┘└────┘  since 1.0 · max stack 1 · [Use in GUI slot]   │
│ Sounds: ENTITY_PLAYER_LEVELUP [▶ preview: our CC0 sample, not vanilla]         │
│ Patterns: "Paged GUI" · "Cooldown per player" · "Async SQLite"  ✓ verified 1.21.11│
└──────────────────────────────────────────────────────────────────────────────┘
```

- Every entry is version-scoped, so items that don't exist in the target version are hidden.
- Icons and sounds are our own or CC0, with licence and credit on hover.

## Screen 11: Projects dashboard

```
┌─ My projects ─────────────────────────────────────────── [+ New] [Templates] ─┐
│ SimpleShop      Paper 1.21.11   v4 ✓  installed on lq4amk     2 days ago      │
│ HalloweenEvent  Datapack 1.21.11 v2 ✓  downloaded             1 week ago       │
│ BossFight       Paper 1.21.11   v1 ✗  failed (free)           3 weeks ago      │
│                                                                              │
│ Credits: 1,240 · [Top up]   This month: 6 builds, 2 failed (not charged)      │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Inside Nxeon (later)

- **Server → Mods tab:** a "Can't find it? Build a custom plugin" card that opens the builder with server context pre-filled through SSO.
- **NxLabs store empty search:** "No results for 'auction house with timer'. Build it in about 5 minutes."
- Builder-made plugins appear in the server's installed-mods list with a "Studio" badge, and use the same update, disable and rollback controls.

## Onboarding for non-coders: details

- The first build uses a template: "Pick a template, change 2 things, build". That gives a guaranteed success in under 5 minutes before any free-form request.
- Jargon is translated everywhere:
  - "permission node" becomes "who can use this";
  - "event" becomes "when something happens";
  - "config" becomes "settings you can change later".
- Every AI question offers clickable answers.
- "Explain this plugin" button: a plain-English walkthrough of what was built and how to use it in-game, also exported as the plugin's README.
- An empty state never shows a blank chat; it shows three example prompts relevant to the detected server.

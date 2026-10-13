# What's New — DRAFT release (unpublished)

Source of truth: `prisma/whats-new/2026-10-release.json` on branch `feature/whats-new-overhaul`.
Status: **DRAFT**. Announcement email: **OFF**. Audience: all customers (no region limit).
Owner-only marks: **[LIVE]** = already on the live site; **[NEXT UPDATE]** = ships with the next deploy.
Publishing is refused by the app until every item is marked live.

Excluded on the owner's instruction: the new invoices (logo / specs / renewal price), status notices,
custom / one-click offers, and the light/dark theme animation. Also excluded as internal: OVH controls,
CPU reservations, reports, AI bot internals, SEO, the unpublished dedicated catalogue.

---

**WHAT'S NEW**

## Easier mods, folder downloads and a faster live chat

Seven improvements for game server owners: quicker Minecraft setup, a rebuilt Mods tab, downloads from
the Files tab, no player caps from us, a server directory in your dashboard, and a live chat that keeps
up with you.

Header image: `public/whats-new/2026-10-release/header.webp`

### 1. Minecraft starts on the newest version — Game servers — [LIVE]
When you deploy a Vanilla, Paper or Purpur server, the newest Minecraft release is now picked for you, so
your server matches what your players run. You can still choose any other version.
*Try it:* Deploy Minecraft → `/dashboard/deploy?product=game&family=minecraft`
*Image:* `minecraft-latest.webp` (deploy wizard, newest release preselected)

### 2. Bedrock servers ready to join on the latest version — Performance & reliability — [LIVE]
Fixed: a new Bedrock server on the newest version could start without opening its game port. New Bedrock
servers now run a build we have tested and open their port straight away.
*Try it:* Deploy Bedrock → `/dashboard/deploy?product=game&family=bedrock`
*Image:* `bedrock-port.webp` (branded illustration, no UI)

### 3. Live chat that keeps up with you — Support — [NEXT UPDATE] (feature/livechat-overhaul)
Messages arrive the moment they are sent. You can see when our team is typing and when your message has
been seen, paste or drag in screenshots, and chat full screen on your phone.
*Try it:* Open live chat → `/dashboard/support?tab=chat`
*Image:* `live-chat.webp` (mobile chat, Team online + Seen; placeholder names only)

### 4. Download files and whole folders — Game servers — [NEXT UPDATE] (feature/files-download)
Download any file from the Files tab, or tick several files and folders and get them as one .tar.gz
archive. Handy for keeping a copy of your world or moving a server.
*Try it:* Open your servers → `/dashboard/games`
*Image:* `files-download.webp` (three items selected, "Download .tar.gz")

### 5. A Mods tab that shows what you have — Game servers — [NEXT UPDATE] (feature/mods-tab-rework)
Your installed mods now sit in one library with version, source and health. Switch mods off and back on
where that is safe for your game, and browse the Mod store for mods that fit your server.
*Try it:* Manage mods → `/dashboard/games`
*Image:* `mods-library.webp` (Installed mods library with health badges and switches)

### 6. No player caps from us — Game servers — [NEXT UPDATE] (feature/unlimited-players)
We never limit players by plan. Each plan shows a recommended player count for smooth play, and the Max
players setting now goes up to the game's own limit.
*Try it:* Check your settings → `/dashboard/games`
*Image:* `unlimited-players.webp` (wizard plan cards marked Unlimited players)

### 7. The server directory, inside your dashboard — Dashboard — [NEXT UPDATE] (feature/portal-directory)
Browse public game servers by game or region, open a server's page to copy its address, save favourites,
and choose which of your own servers to list.
*Try it:* Browse servers → `/dashboard/directory`
*Image:* `directory.webp` (Browse by game grid)

---

## Honesty notes (why the copy says what it says)
- No numbers or performance claims. "Newest release" = the wizard's real per-type default (lib/mcjars/default-version.ts).
- Bedrock: only NEW servers are claimed (existing ones were never affected — their server.properties already used RakNet). "A build we have tested" = the pinned BEDROCK_KNOWN_GOOD_VERSION.
- Player caps: "up to the game's own limit" because some games have an engine cap; we never say "unlimited" for those.
- Directory: "choose which of your own servers to list" only — listing servers hosted elsewhere is a default-OFF source, so it is not claimed.
- Live chat: "the moment they are sent" describes the realtime (SSE) delivery; there is a 4 s poll fallback, so no latency number is quoted.
- Brand voice: no "provider", no OVH, Nxeon speaks as the owner.

## Screenshots (this folder) — throwaway dev server + throwaway DB, placeholder accounts only
- `01/02-admin-preview-dialog-{desktop,mobile}.png` — the DRAFT in the admin preview URL, dialog open, with the owner-only Live now / Ships with the next update badges.
- `03/04-admin-preview-changelog-{desktop,mobile}.png` — same preview, dialog closed (`?dialog=0`), full changelog page.
- `05-admin-editor-desktop.png` — /admin/announcements editor + live preview + release list (the list shows the real DRAFT with "5 ship with next update"; the form is open on the simulated published copy, hence all "Live now").
- `06/07/08-customer-dialog-*.png` and `09/10/11/12-customer-changelog-*.png`, `13-customer-topbar-after-read.png` — what a customer sees AFTER publish, simulated in the throwaway DB by a published copy of the draft with every item marked live (plus one older legacy release to show date grouping). Desktop, phone, light mode, and the Support filter.
- `wizard-step.png` / `wizard-minecraft-raw.png` — source captures for the Minecraft graphic.
- `shots.mjs`, `wizard.mjs`, `e2e.mjs` — the capture scripts. `e2e.mjs` result: dialog auto-opens (focus inside), Remind me later → SNOOZED and no auto-open next visit (dot stays), Esc → READ.

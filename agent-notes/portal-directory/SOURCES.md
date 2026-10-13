# Directory server sources: every candidate, terms, verdict (2026-10-06)

Branch `feature/portal-directory`. Evidence: research agent (WebSearch/WebFetch + curl with the honest UA
`NxeonDirectoryResearch/1.0 (+https://nxeon.cloud; abuse@nxeon.cloud)`, max ~3 requests per site, nothing blocked
was bypassed; raw notes in `research-raw.md`) plus my own single verification requests to Klei (below). WebFetch
summarises pages with a small model, so quotes marked (WF) should be re-read by a human before relying on them.
This is an engineering risk assessment, not legal advice.

Verdicts: **USE** = documented and clearly permitted. **NEEDS-OWNER-REVIEW** = accessible, no explicit prohibition
found but no explicit permission either (or terms unreadable): adapter may exist but is default OFF until the owner
records a reviewer. **DO-NOT-USE** = forbidden, blocked (Cloudflare/403/robots), credentialed, or dead.

## Bottom line
- **Minecraft (Java + Bedrock): no permitted bulk discovery source exists.** Every server-list site either forbids
  copying, disallows its listing pages in robots.txt, sits behind a Cloudflare challenge, has no readable terms, or
  only offers per-server vote/owner APIs. None was scraped. The implemented path is **owner-submitted listings
  verified by a token in the server's own MOTD** (or A2S name / DNS TXT), enriched with our own Server List Ping /
  RakNet ping. Plus Nxeon-hosted servers (paid + free Minecraft tier), which already list.
- **Steam GetServerList stays the bulk source** for the ~30 Steam-master families (already approved by the owner).
- **New adapter, default OFF: Klei DST lobby list** (NEEDS-OWNER-REVIEW).
- **New source, default OFF: owner submissions** for every game (the only route for the ~15 no-list games).

## Table

| Source | Games | What it is (URL) | Terms quote / evidence | Terms URL | Verdict | Why / what was built |
|---|---|---|---|---|---|---|
| Steam IGameServersService/GetServerList | 30 Steam-master families | Bulk list, key in prod env | "you will store the Steam Data in a country (or countries) identified in your privacy policy"; "limited to one hundred thousand (100,000) calls ... per day" (spec, 2026-10-05) | https://steamcommunity.com/dev/apiterms | USE (owner approved: `directory_steam_terms_reviewed_by`) | Existing. 38,079 rows in prod today across 28 games. Portal now shows Valve logo + truthful "may be out of date" line while the prober is off. |
| **Owner submission + token verification** (new) | every game | Owner enters address, gets `nxeon-xxxxxxxxxx`, puts it in MOTD (MC Java/Bedrock), server name (A2S games) or DNS TXT `_nxeon-verify.<host>` (any game) | Our own policy; the check is the game's own public status query, once per click | (policy: owner) | NEEDS-OWNER-REVIEW (policy, default OFF) | Built: `DirectorySubmission`, `lib/directory-submissions.ts`, provider `submitted`, portal `/dashboard/directory/list`. Enable: `directory_src_submitted_enabled=true` + `directory_src_submitted_reviewed_by=<name>`. |
| Minecraft Server List Ping (our own) | minecraft | TCP status handshake to an address we hold | Public protocol every client sends; player `sample` names ignored | n/a | USE (enrichment/verification only) | Built hardened `lib/directory-ingest/mc-status.ts` (SRV, all A records public, 256 KB cap, 2.5 s timeout, handshake host). Prober stores sanitized MOTD + version. |
| Bedrock RakNet unconnected ping (our own) | bedrock | One UDP datagram | Public protocol | n/a | USE (enrichment/verification only) | Same module, magic + source-IP checked. |
| Klei DST lobby (`lobby-v2-cdn.klei.com/<region>-Steam.json.gz`) | dst | Static JSON files the game client reads; 4 regions from `regioncapabilities-v2.json` | Verified 2026-10-06 (1 request each): HTTP 200, gzip ~1.8 MB/region, ETag, ~10.8k rows (ap-southeast-1), ~3.1k open dedicated. robots.txt = S3 AccessDenied (no file). Klei staff, second-hand (WF, unverified, forum 403): "not an official API with guaranteed stability, third-party tools are welcome to use them". No Klei terms page found (/terms, /legal, /eula 404). | https://www.klei.com/privacy-policy (only legal page found); https://kleiforums.com/forums/topic/149323 | NEEDS-OWNER-REVIEW | Built adapter `providers/klei.ts`, default OFF, hourly, sequential, open servers only, no mods/Steam ids stored. Owner: confirm Klei's position (ideally email Klei) then set `directory_src_klei_reviewed_by`. |
| Vintage Story master | vintagestory | Existing adapter | No published terms (2026-10-04) | https://wiki.vintagestory.at/Server_Config | NEEDS-OWNER-REVIEW | Existing, default OFF. |
| TruckersMP API | ets2, ats | Existing adapter | Terms page 403 to our fetcher (2026-10-04) | https://truckersmp.com/terms | NEEDS-OWNER-REVIEW | Existing, default OFF. |
| minecraftservers.org (minecraft-server.net 301s here) | MC Java | No listing API | (WF) "Not to reproduce, duplicate, copy or re-sell any part of our sites in contravention of the provisions of our Terms of Website Use." | https://minecraftservers.org/terms | DO-NOT-USE (without written permission) | No-copy clause; their list is their product. (Research agent graded NEEDS-OWNER-REVIEW; I treat a no-copy clause as a no.) |
| minecraft-server-list.com | MC Java | No API | robots.txt `Disallow: /servers/`; terms page not found | https://minecraft-server-list.com/robots.txt | DO-NOT-USE | Listing pages disallowed. |
| minecraft-mp.com | MC Java | Per-server vote/owner API with a server key only | (WF) ToS bans "Using bot, script or any means to make multiple daily votes"; no listing endpoint | https://minecraft-mp.com/terms/ | DO-NOT-USE for discovery | API is not a list; scraping pages is not permitted by anything. |
| minecraftpocket-servers.com | Bedrock | Same network as minecraft-mp | Help/terms page HTTP 403 | https://minecraftpocket-servers.com/help/ | DO-NOT-USE | Terms unreadable; vote API only. |
| topg.org, topminecraftservers.org, minecraft.buzz, craftlist.org, minelist.net, minecraft-servers.gg, namemc.com, servers-minecraft.net | MC | No listing API found | Terms pages 404 / not found; namemc disallows GPTBot entirely | (see research-raw.md) | NEEDS-OWNER-REVIEW (no adapter) | Only a written permission from each site would make them usable; nothing built. |
| planetminecraft.com, findmcserver.com | MC | - | Cloudflare challenge, HTTP 403 incl. robots.txt | - | DO-NOT-USE | Blocked; not circumvented. |
| minecraftlist.com, serverlist.games, mc-list.org | MC | - | Down (402) / parked | - | DO-NOT-USE | Not real sources. |
| Minetrack servers.json | MC | GitHub file | "The MIT License (MIT) Copyright (c) 2015 Cryptkeeper ..." | https://raw.githubusercontent.com/Cryptkeeper/Minetrack/master/LICENSE | USE (licence ok) but not built | Only 2 entries (mc.hypixel.net, play.cubecraft.net), repo archived: no discovery value. |
| api.mcsrvstat.us | MC Java/Bedrock | Per-address status | (WF) "A descriptive and non-empty `User-Agent` request header is required ... otherwise you will get a `403 Forbidden`"; "cached for 5 minutes" | https://api.mcsrvstat.us/ | USE (enrichment only) - not used | We query servers ourselves (SLP/RakNet); no third party needed. |
| api.mcstatus.io | MC Java/Bedrock | Per-address status | (WF) "Our service limits to 5 requests/second specified by client IP address." | https://mcstatus.io/docs | USE (enrichment only) - not used | Same. |
| Mojang/Microsoft Featured Servers | Bedrock | No public API | - | - | DO-NOT-USE | Nothing to use. |
| minecraft.net Usage Guidelines | MC | Brand rules | Could not be read (fetch timed out); nothing quoted | https://www.minecraft.net/en-us/usage-guidelines | NEEDS-OWNER-REVIEW | Owner should read the server/brand sections before marketing a Minecraft list. |
| BattleMetrics | many | api.battlemetrics.com | Cloudflare 403 on robots.txt and /legal/terms; API wants a token | https://www.battlemetrics.com/legal/terms | DO-NOT-USE | Blocked + credential; only with written permission. |
| Factorio matchmaking | factorio | multiplayer.factorio.com/get-games | Needs a personal account username/token | - | DO-NOT-USE | Personal credential. |
| FiveM / Cfx.re | fivem | servers-frontend.fivem.net (undocumented) | (WF) "Cfx doesn't provide an 'easy to use' API for their server list" | https://forum.cfx.re/t/changes-regarding-fivem-servers/59866 | NEEDS-OWNER-REVIEW (spec D4 default no) | Not built; owner submissions cover FiveM via DNS proof. |
| Palworld, Arma Reforger | palworld, armareforger | No official public list found | - | - | NEEDS-OWNER-REVIEW (nothing to use) | Owner submissions (A2S name or DNS). |
| GameTracker, TrackyServer, GameMonitoring | many | Aggregators | Not researched / not read | - | NEEDS-OWNER-REVIEW | Competitor lists; nothing built. |
| Terraria, Satisfactory, Core Keeper, ARK ASA (EOS), Necesse, Nightingale, Eco, Plutonium | various | No public list (or credentialed/bot-blocked, see docs/DIRECTORY-SOURCES.md) | - | - | DO-NOT-USE for discovery | Owner submissions (DNS proof for no-protocol games; A2S name where it exists). |

## What is enabled vs needs sign-off
Nothing new is enabled. All new sources ship default OFF:
- `directory_src_submitted_enabled` + `directory_src_submitted_reviewed_by` (owner submissions; the portal form says "isn't open yet" while off)
- `directory_src_klei_enabled` + `directory_src_klei_reviewed_by` (DST)
- Prober (`directory_probe_enabled`, `NXEON_DIRECTORY_PROBE=1` box) untouched and still off in prod; the new MOTD/version enrichment only runs inside it.

# Cyrus Pattern Library: licensing policy (v1, 2026-10-08)

Applies to every pattern in `services/modbuilder/library/` (all games). The library feeds code into
**customer plugins that customers own, sell and redistribute**, so a pattern's licence must survive
being copied into someone else's closed or commercial jar. That is stricter than "is this open source?".

## 1. The rule in one line

A pattern may only come from (a) code Nxeon writes itself, (b) a Cyrus build whose owner explicitly
opted in, or (c) a third-party source whose licence is on the allow-list below and was **read and
recorded** (SPDX id, URL, commit, attribution text) at ingest time. Everything else is out.

API facts (class names, method signatures, which constant exists in which version) are not code and
are not copyrightable. We take those from the real jars with `javap` (as the version sheets already do),
never from someone's prose or samples.

## 2. Allowed sources

| Source class | SPDX allow-list | Notice in customer output? | Status |
|---|---|---|---|
| Nxeon-authored patterns (written fresh for the library, by Nxeon staff or by Cyrus agents working for Nxeon, from API facts only) | `LicenseRef-Nxeon-Authored` | No | **All 30 seed patterns are this class.** |
| Opted-in Cyrus builds (customer gave explicit consent on the listing, section 5) | `LicenseRef-Cyrus-Contributor-Grant` | No (the grant covers reuse) | Designed, not built (needs the owner's ToS wording) |
| No-attribution permissive | `MIT-0`, `0BSD`, `CC0-1.0`, `Unlicense` | No | Allowed. None used for Minecraft yet (Jotunn's `JotunnModExample` is MIT-0, relevant to Valheim) |
| Attribution permissive | `MIT`, `Apache-2.0`, `BSD-2-Clause`, `BSD-3-Clause`, `ISC` | **Yes**: the build service writes `META-INF/cyrus-library-NOTICE.txt` into any jar whose build retrieved such a pattern (implemented in `library.js` `noticesFor()`; Apache-2.0 also needs its NOTICE file carried and changes marked) | Allowed with care. None used yet |

## 3. Not allowed (the ingest tool refuses these)

| What | Why |
|---|---|
| Copyleft code: `GPL-*`, `AGPL-*`, `LGPL-*` (copying, not linking), `MPL-2.0` file-level copies, `EPL-*` | Would force the customer's whole plugin under the same licence. Note: **Paper itself is GPL-3.0** (with some MIT-relicensed contributors), so Paper/Bukkit/CraftBukkit *implementation* code is out. Compiling against the Paper API jar, as the service does, is fine and unchanged. |
| ShareAlike content: `CC-BY-SA-*` | ShareAlike would follow the code into customer jars. **Verified 2026-10-08: the PaperMC docs repo (`PaperMC/docs` @ `8ad3909`) is BSD-2-Clause only for its *supporting site code*; the documentation content, including the Java samples inside the `.md` pages, is CC-BY-SA-4.0** (README "License" section). The Adventure docs (`KyoriPowered/adventure-docs`) are CC-BY-SA-4.0 too. So docs samples are **reference only**: read them for understanding, never paste them into a pattern. |
| No licence at all (all rights reserved by default), e.g. `PaperMC/paperweight-test-plugin` (GitHub reports no licence) | No permission to copy. |
| `NOASSERTION` / custom / "free for non-commercial use" / unclear | Ask the author or skip. Customers sell plugins. |
| Bulk scraping or mirroring of Modrinth, CurseForge, SpigotMC, Hangar, Thunderstore, uMod, Steam Workshop or GitHub search | Platform terms forbid automated harvesting for this purpose, and per-project licences vary. Single, hand-picked, licence-checked repos only. |
| Community mods on NxLabs without the author's explicit opt-in | Publishing on NxLabs is not consent to be used as training or pattern material. |
| Decompiled code from any jar (including Mojang, Paper, plugins) | Copyright plus platform EULAs. `javap` signature dumps for API facts are fine. |
| Anything containing secrets, personal data, player names/UUIDs, server IPs | Privacy; also blocked by the safety scan. |

## 4. What every pattern records (enforced by `tools/library.js lint`)

`source.kind` (`nxeon` | `opted-in-build` | `third-party`), `source.license` (SPDX id from the allow-list),
`source.author`, `source.url`, `source.commit` (third-party: exact commit SHA read), `source.retrieved`
(date), `source.attribution` (exact notice text when the licence needs one; empty otherwise),
`source.modified` (true when adapted), `source.notes`. For `opted-in-build`: `source.buildId`,
`source.consentId` and `source.consentAt` instead of URL/commit. The `contentHash` covers code and
metadata, so a changed pattern needs a new review and new verification.

Lint fails when: the SPDX id is not on the allow-list for its kind; a third-party pattern has no URL,
commit or (where required) attribution; an opted-in pattern has no consent id; a pattern contains a
player name/UUID/IP/URL literal; or the code fails the service's own safety scan.

## 5. Customer builds: explicit opt-in, and removal on request

Default is **out**. A build can only become a library pattern when all of these are true:

1. The owner ticked a separate, unticked-by-default box on the listing dialog / NxLabs page:
   "Let Cyrus learn reusable building blocks from this mod (code only, never your name, server or
   players; you can withdraw any time)". Not bundled with publishing, not required for anything.
2. We store a consent record (`LibraryConsent` in `lib/cyrus/library/types.ts`): user id, build id,
   the exact wording version shown, timestamp. No consent record = the miner never sees the build.
3. The miner proposes small, generic blocks (one concern, no customer names, strings or theme),
   normalised to `__PKG__` and placeholder names, and they enter the library as `draft`, never
   directly as `verified`. A human reviewer approves the code and the de-identification.
4. Withdrawal: the owner un-ticks the box (or asks support). Every pattern with that
   `source.consentId` is removed from the library at the next library build, its id is tombstoned in
   `library/minecraft/removed.json` (so it is not re-mined), and the removal is logged. Builds already
   delivered to other customers are not recalled (the grant was valid when used); the ToS must say so.
5. Patterns from opted-in builds carry no attribution to the customer in other customers' jars
   (privacy), which the grant must allow.

**Owner decisions needed** (section 7) before step 1 ships: the grant wording (a licence from the
customer to Nxeon to reuse the contributed code in other customers' builds, royalty-free, irrevocable for
already-delivered builds, revocable for future use), and whether contributors get anything (tokens,
a "Contributor" badge).

## 6. Review process for a new third-party source

1. Open the repo's LICENSE file at a specific commit and read it (not only the GitHub badge; the
   PaperMC docs case shows a repo-level badge can hide a different content licence in the README).
2. Check README/NOTICE/headers for extra terms, and for files under a different licence.
3. Record SPDX, URL, commit, attribution text in `pattern.json`.
4. Rewrite into a small, single-concern block; keep the attribution even when heavily modified.
5. Verify like any pattern (compile on every claimed version, safety scan, runtime load).

## 7. Decisions the owner must confirm

1. **Seed = 100% Nxeon-authored.** No third-party code is in the library today. (Recommended: keep it so
   for Minecraft; the useful public Minecraft samples are CC-BY-SA docs or GPL plugins.)
2. Whether to allow attribution-required licences at all (MIT/Apache/BSD). The service is ready to
   write the NOTICE file into customer jars; the trade-off is a NOTICE file inside customers' plugins.
   Recommended: allow, but prefer no-attribution sources.
3. The customer contribution grant wording and incentive (section 5), reviewed by whoever owns the ToS.
4. That customer plugins built with library patterns are fully the customer's (Nxeon-authored patterns
   are granted to the customer with the build, like the rest of the generated code).

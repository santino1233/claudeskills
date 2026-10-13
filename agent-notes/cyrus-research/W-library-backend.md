# W: Cyrus asset library backend (r26, 2026-10-10)

Branch `feature/cyrus-r26-library` (worktree `/tank/dev-worktrees/cyrus-r26`, latest `feature/cyrus-r2` merged). Code `lib/cyrus/library/backend/`, SQLite index v2, motion kinds in catalog v2. Docs "Cyrus asset library backend". **Nothing deployed, no migration run, no flag flipped, no paid model call.** Switches: `CYRUS_LIBRARY_BACKEND`, `CYRUS_LIBRARY_CONTRIBUTE`, `CYRUS_LIBRARY_STORE`, `CYRUS_LIBRARY_URL_SECRET` (all off).

## What was built
1. **Storage**: content-addressed object store (local disk, S3 with the pack host's SigV4, private), read-only staging source (path-confined, hash-checked), per-kind caps, 30-day retention sweep. Derivatives generated lazily by deterministic recipes: `thumb@1` (pure-JS PNG / pinned Pillow for JPEG), `preview-ogg@1` (fixed ffmpeg argv), `glb-opt@1`, `bundle@1` (folder sets). Signed, 5-minute, viewer-scoped URLs re-checked at fetch; raw audio never served; the proprietary SFX library never as originals and only when cleared.
2. **Index**: Postgres tables (migration file, not applied), posting index with the same ranking as the memory index, pg_trgm typo fallback, full-text admin find, idempotent importer. **SQLite index rewritten** (posting lists, one SQL statement).
3. **Contribution**: automatic, after `libraryEligible` and strict filters; status published / held / removed; hold queue (real-weapon, trademark, extremist, drugs, mature violence); exact + near dedupe (image dhash, audio envelope, glb facts, motion JSON); a removed hash cannot be re-contributed; provenance and legal class kept.
4. **Reports / takedown**: legal report or 3 reporters hold; takedown removes now, purges derivatives, marks dependents; **dependent mods keep building from their own copy, not plan-gated** (tested in memory and on Postgres).
5. **Use in project**: `cat:<sha256>` slot + project copy + dependents record; sounds Saka+, visuals All models; keeping never gated.
6. **Admin**: read model (counts by kind/tier/status, hold queue, takedown log) inside `/api/admin/cyrus/ops` when the switch is on. No page.
7. **Motion kinds** (coordinator request): flipbook, particle-texture, animation-clip, animated-model, motion-preset, effect-preset; vocabulary proposal merged; `provenance.via` max 400.

## Ran (node-2 unless noted)
| What | Result |
|---|---|
| Old FTS5 index, 60,970 entries | worst 142 ms (17 s **not reproduced**), top-8 equal to memory 2/28 |
| SQLite v2 | worst 92 ms (memory DB) / 143 ms (file), **28/28** identical to memory, exact totals |
| Memory index | 23-376 ms |
| Import dry run | 60,970 valid, 0 invalid, 3.0 s |
| Import real (Postgres + SQLite file) | 469 s, 1,100,093 postings; re-run 4.7 s, 0 written |
| Postgres catalog_search | medians 9-160 ms, worst 323 ms; "wodden dor" finds "Door wooden" |
| Prisma check | `db push` drops a hand-written GIN index on a plain column; shipped indexes are expression indexes, diff empty |
| Derivatives, 134 staged CC0 assets | thumbs 110/123, bundles 11/11, all cache hits on pass 2; previews/glb-opt: tools missing |
| ffmpeg preview argv, 3 CC0 sounds (primary, tiny) | byte-identical twice |
| Stage A motion pass 2 (1,807) | 98.4 % full, 4 zero-length clips held |
| Stage A motion pass 1 (1,951 CC0, 21 CC-BY out) | 31.1 % full, 68.0 % partial, 0.9 % none |
| Tests | new unit + golden (36) and throwaway-Postgres (4) suites pass; full Cyrus + builder suite **2,196/2,196** after merging the latest r2; tsc clean |

## Not run / not built
Production migration and import; real S3 bucket; ffmpeg / gltf-transform on node-2; HDR/EXR and glb render thumbnails; the Nxeon ProjectAssetSink and studio contribute hooks; browse UI; perceptual near-dedupe against the 61k staged entries (only between contributions); re-running stage A over `entries2-staged-cc0.jsonl` (its motion rows are still `texture`).

## Owner
See OWNER-ACTIONS "Asset library backend": migrations, storage, URL secret, tools, production import, retention and legal-takedown decisions, ToS wording.

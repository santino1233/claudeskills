# CC: Cyrus asset library to production (2026-10-14)

Branch `feature/cyrus-library-prod` (worktree `/tank/dev-worktrees/cyrus-libprod`, 3 commits on main f347f27a, NOT promoted). tsc clean, 161/161 library/catalogue tests + docs coverage 12/12. Evidence: `CC-library-prod-evidence/` (this folder).

## 1. Result in one paragraph

The catalogue is empty in production for a different reason than "migration not applied": the **schema is already there** (all seven library tables, the `entryHash` column, `pg_trgm` and both expression indexes), the tables just have 0 rows, and **no serving switch is set** (`CYRUS_LIBRARY_BACKEND`, `_STORE`, `_LOCAL_DIR`, `_STAGING_DIR`, `_URL_SECRET`, `_FFMPEG`, `CYRUS_LIBRARY_BROWSE` are all absent from `/opt/nxeon/.env`). So the importer must run once and seven env lines must be added. `CyrusLibraryItem` is NOT the catalogue (it is the Nxeon mod bookmark table keyed by `userId,pageId`); the catalogue is `CyrusCatalogEntry` + `CyrusCatalogTerm`. Importing 62,777 entries takes about 1 minute and adds about 0.5 GB to the database; originals are read in place from the read-only staging volume (no 140 GB copy). Validating through the real handlers found and fixed five real serving bugs (below).

## 2. What production expects (names only, state as read 2026-10-14 20:00)

| Thing | State |
|---|---|
| Web process | `nxeon-web.service`, user `nxeon`, `EnvironmentFile=/opt/nxeon/.env`, `node .next/standalone/server.js`, port from `PORT`. No sandboxing: it can read `/tank/...`. |
| DB | one Postgres `nxeon` (3.5 GB); Cyrus tables live in it. Primary `/` has 8 GB free (83% used), `/tank` 2.6 TB free. |
| Tables | present: CyrusCatalogEntry (with entryHash), CyrusCatalogTerm, CyrusLibraryDerivative, CyrusLibraryUse, CyrusLibraryReport, CyrusLibraryModeration, CyrusLibraryFingerprint (+ CyrusCatalogReview, CyrusCatalogEnrichmentRun). Rows in CyrusCatalogEntry: 0. |
| Raw SQL that `prisma db push` must not drop | `CyrusCatalogEntry_title_trgm_idx` and `CyrusCatalogEntry_searchText_fts_idx` (expression indexes; present now). Both are checked by the importer preflight. |
| Storage backend | `CYRUS_LIBRARY_STORE=local|s3`, `CYRUS_LIBRARY_LOCAL_DIR` (derivatives only), `CYRUS_LIBRARY_STAGING_DIR` (read-only originals). Chosen: local `/tank/cyrus-library-store` + staging `/tank/cyrus-library-staging`. |
| Library backend flags | `CYRUS_LIBRARY_BACKEND` ABSENT, `_STORE` ABSENT, `_LOCAL_DIR` ABSENT, `_STAGING_DIR` ABSENT, `_URL_SECRET` ABSENT (needs >= 32 chars), `_FFMPEG` ABSENT, `_PYTHON` ABSENT, `CYRUS_LIBRARY_BROWSE` ABSENT, `CYRUS_CATALOG_TOOLS`/`_INDEX` ABSENT. |
| Already set | `CYRUS_SOUND_LIBRARY_CLEARED=1`, `CYRUS_LIBRARY_CONTRIBUTE=1` (becomes LIVE the moment BACKEND=1; see decision A), `CYRUS_STORAGE=1`, `CYRUS_API_V1=1`. |
| What gates what | BACKEND=1 + STORE + URL_SECRET: signed preview URLs/file route, report, admin library view in `/api/admin/cyrus/ops`, `/admin/cyrus/library/*`. BROWSE=1: studio library browser page + `/api/cyrus/library/v2/browse|use`. Customer "My assets" `/dashboard/cyrus/app/assets` and admin `/admin/cyrus/assets` read `CyrusProjectAsset` (per-project), need no library flag; a library pick appears there only after "Use in project". |
| Production build | contains the library routes (url, file, browse, use, report); only data + env are missing. The fixes below need a promote to be live. |

## 3. Dry run on a throwaway database (node-2 `wt_cyrus_libprod`)

Source: `catalog-v2/entries3-staged-cc0.jsonl` (62,777 lines) + the three ledgers (main 670 rows, motion, motion-2).

| | |
|---|---|
| Time, empty database | dry run 6.4 s; real 63 s (batch 500); re-run 12.6 s, 0 written (`unchanged 62,777`). Earlier bench: re-run 8 s. |
| Memory | 650 MB peak RSS (real), 410-440 MB (dry run / re-run) |
| Rows | 62,777 entries + 1,145,478 postings; table 178 MB + 285 MB with indexes. 0 invalid, 0 duplicates, 0 refused by the gate. |
| Resumable | proven by accident: a killed first run left 23,500 rows, the next run inserted exactly the missing 39,277 and wrote terms for them (`entriesWithoutTerms 0`). |
| Kinds | sprite 38,464; model 10,278; sound 5,961; texture-set 2,946; hdri 1,430; flipbook 1,401; texture 801; animation-clip 741; particle-texture 361; music 137; animated-model 130; decal 127 |
| Licence tiers | cc0 59,813; proprietary-nxeon 2,964 (owner SFX, previews only, never originals) |
| Status | published 62,444; removed 290; held 43 (moderation state is imported as is) |
| Gate passes via | ledger pack 58,946; ledger source 375; owner-cleared 2,964; own work (nxeon-procedural) 492 |
| Staged paths | all single-file originals exist; 741 animation-clip rows carry `#n` (clip inside its glb, no variant by design); 336 sequence flipbooks carry a `dir/prefix*` glob (fixed). 140.7 GB of originals referenced (sound 55 GB, texture-set 59 GB, model 12 GB, hdri 10 GB). |
| Search bench (node-2, in-DB) | medians 23-320 ms (worst `ui click` 321 ms median, 935 ms max); "wodden dor" finds "Door wooden" |

CC-BY: 0 rows reach the database (importer drops them; the entries file already contains none). Owner Minecraft assets (`_owner-mc`), `_quarantine`, `_reference*`, `_raw` are never referenced by an entry and the gate refuses those path prefixes.

### Licence gate (new, `lib/cyrus/library/backend/licence-gate.ts`)
An entry is imported only if: tier cc0 with spdx CC0-1.0 + recorded licence page + source URL (or tier proprietary-nxeon from source `nxeon-proprietary` AND `CYRUS_SOUND_LIBRARY_CLEARED=1`); its (source, pack) is not a negative row of any ledger (SKIPPED/EXCLUDED/REJECT*/NOT ...) and its source is not rejected whole; staged path is relative, has no `..`, and is not under `_owner-mc|_quarantine|_reference|_reference-mods|_raw|_lic|tmp*`. Result on the real file: 0 refused (the final tagging pass had already filtered); the gate is the safety net for any future entries file.

## 4. Validation through the real app code paths (throwaway DB, real handlers)

Harness `scripts/cyrus/library-validate.ts` (refuses anything but a node-2 `wt_*` database): `catalogSearch` (the model tool), `browseCatalog` (the browser), `handleSignUrl` + `handleFile` (real signed URLs, real derivative generation with ffmpeg/Pillow, plan + licence gates), `libraryAdminView` (admin read model). Plans: all / saka / katara / free / unknown.

| Check | Result |
|---|---|
| Search (plan all) "wooden door", "sci-fi crate prop", "stone wall floor texture" | 1,407 / 259 / 12 hits, results sane; saka sees sounds only; free: `asset_locked` |
| Browse facets | all: 8 kinds, 3,144 "door" rows (cleared) / 2,687 (not cleared); saka: 2 kinds, 6 locked kinds named; katara: 0 rows + plan message |
| Gates | proprietary preview: 200 when cleared, 403 `not_cleared` otherwise; proprietary/CC0 raw audio: 403 `raw_audio` always; saka thumb of a visual: 403 `asset_locked`; unknown plan 403; removed 410; held 404 |
| Thumbs | sprite/texture/particle/decal/model 100%; see "fixed" for HDRI/texture-set/flipbook |
| Previews (SFX play button) | cc0 sound 8/8, proprietary sound 8/8, music 8/8, files up to 573 MB 4/4 after the fixes (first request 0.6-8 s, then cache hit) |
| Bundles (PBR sets, HDRI, decals) | 100% (0.7-4.9 s, 3-15 MB each) |
| Admin read model | counts by kind/tier/status, matrix, derivative stats, hold queue (43), full-text find ("wooden door" 19 rows) all answer |

### Broken, now fixed on the branch (each with a test in `test/cyrus-library-prod.test.ts`)
1. **Audio previews longer than the 30 s window failed** (`502 tool_failed`): ffmpeg `-t 30` closes stdin early, Node reports EPIPE with exit 0, `spawnTool` treated it as failure. Hit 2 of 3 sampled proprietary music files; any source whose first 30 s is smaller than the file.
2. **Audio over 48 MB had no preview** (`404 not_available`): 332 of 6,098 staged audio files (5.4%), up to 573 MB. Now hash-verified by streaming and read by ffmpeg by path (cap 1 GiB).
3. **336 frame-sequence flipbooks** (`dir/prefix*` paths) and **34 ambientCG 3DModel folders** (kind model, `jpg+pbr-maps`) had no thumbnail/bundle.
4. **867 Poly Haven texture sets** (`_diff_2k` naming) had no thumbnail.
5. **997 `.hdr` HDRIs** had no thumbnail (ffmpeg tone-map, 256 px; verified visually).

### Still not available (honest list)
- `glb-opt@1`: gltf-transform is not installed anywhere (`tool_missing`); the original GLB is served, thumbnails come from the sibling PNG.
- No thumbnail source for about 650 models/textures and 130 animated models (needs a renderer; not built). They are searchable, show a placeholder.
- Animation clips (741) have no variant of their own (they live inside a model).
- **Sound Studio's built-in library audition** (`/api/cyrus/assets/v1/sound/preview`, the 514/2,964 owner files) is a separate pipeline that renders on node-2 and needs `CYRUS_SOUND_RENDER` + the relay vars; they are EMPTY in `.env`. The new library backend gives SFX play buttons in the library browser independently of it. Enabling the legacy path is infrastructure (ssh key / relay token), not data.
- The first view of a page generates up to 24 thumbnails synchronously in the web process (about 0.1-1 s each, cached after). No pre-warm was run; a bulk warm of 55k thumbs is hours of single-thread CPU and is not needed.

## 5. THE PASTE (owner, on the primary, as root)

```bash
bash /tank/dev-worktrees/cyrus-libprod/scripts/cyrus/library-prod-apply.sh apply
```

Read-only preview first if you want it: `bash /tank/dev-worktrees/cyrus-libprod/scripts/cyrus/library-prod-apply.sh plan` (checks + importer dry run, writes nothing to the database).

What `apply` does, in order (it stops at the first failure):
1. Preflight, read only: tables + both expression indexes present, entries + three ledgers present, `/` >= 4 GB free, `/tank` >= 50 GB free, `/usr/bin/ffmpeg` and Pillow present.
2. Backup to `/tank/cyrus-library-backups/prod-apply/<ts>/`: copy of `/opt/nxeon/.env`, `pg_dump -Fc` of the seven library tables, before-count.
3. Creates `/tank/cyrus-library-store` (owner `nxeon`, 750); checks `nxeon` can read staging and write the store.
4. Importer (licence-gated, `nice`/`ionice`, batch 500) with `--confirm-database nxeon`; prints the plan; writes `import-report.json`; verification must say `ok: true`.
5. SQL verification: counts by tier/kind/status, entries without postings = 0, cc-by rows = 0, forbidden staged paths = 0 (any failure: stop, run `rollback`).
6. Env: sets `CYRUS_LIBRARY_BACKEND=1`, `CYRUS_LIBRARY_STORE=local`, `CYRUS_LIBRARY_LOCAL_DIR=/tank/cyrus-library-store`, `CYRUS_LIBRARY_STAGING_DIR=/tank/cyrus-library-staging`, `CYRUS_LIBRARY_FFMPEG=/usr/bin/ffmpeg`, `CYRUS_LIBRARY_PYTHON=/usr/bin/python3`, `CYRUS_LIBRARY_BROWSE=1`, and generates `CYRUS_LIBRARY_URL_SECRET` if absent (never printed). Nothing else is touched; the launch pair is not flipped (it is two settings, not env).
7. `systemctl restart nxeon-web` (a few seconds of 502s) + `/api/health` check; on failure it restores the env file and restarts again. `--no-restart` writes the env only (picked up at the next promote or restart).

Idempotent: re-running imports nothing new (`unchanged 62,777`), re-sets the same env lines, takes a new backup. Resumable: an interrupted import is just re-run.

Rollback: `bash /tank/dev-worktrees/cyrus-libprod/scripts/cyrus/library-prod-apply.sh rollback` restores the env file of the FIRST apply, deletes the imported catalogue rows only if the catalogue was empty before (else prints the `pg_restore` line), and restarts the web. The object store is left in place (derivatives only).

Estimates: import 1-2 min (63 s on node-2; primary is the same Postgres host so no network); database +0.5 GB (178 MB entries + 285 MB postings + WAL); object store starts at ~0 and grows lazily (thumb ~37 KB, preview ~90 KB, PBR bundle ~11 MB; retention drops derivatives unused 30 days; worst case if every set were downloaded is tens of GB, the quota is `/tank`'s 2.6 TB). Staging is read in place and must stay on disk (140 GB referenced, single non-redundant `tank` disk; backups are in the existing cyrus-backup timer).

Rehearsed end to end (apply, re-apply, rollback, re-apply) on the throwaway database through `LP_ENV/LP_THROWAWAY` overrides: see `apply-script-rehearsal.log`. The production run itself was not performed (blocked for me by design).

### Verification after the paste (read only)
```bash
set -a; . /opt/nxeon/.env; set +a
psql "${DATABASE_URL%%\?*}" -At -c 'select count(*) from "CyrusCatalogEntry"' -c 'select tier,count(*) from "CyrusCatalogEntry" group by 1'   # 62777; cc0 59813; proprietary-nxeon 2964
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/api/health      # 200
journalctl -u nxeon-web -n 30 --no-pager | grep -i -E 'library|catalog' || true
```
Then in a browser as a Saka-or-above account on a project: Studio > Library (search "explosion", press play on a row), admin `/admin/cyrus/library` (counts 62,777, held 43). Free/Katara accounts should see the plan message, not rows.

## 6. Owner decisions in the paste's blast radius

A. **`CYRUS_LIBRARY_CONTRIBUTE=1` is already set and goes live with BACKEND=1** (automatic community contribution, owner decision 2026-10-10). The Terms licence grant still needs a lawyer. If you want contribution held, blank that one line in `.env` before/after; the catalogue works without it.
B. Proprietary SFX (2,964 rows) are searchable and previewable (processed <= 30 s, mono Vorbis) for Saka+ because `CYRUS_SOUND_LIBRARY_CLEARED=1` is set; originals are never served. If you want them hidden, set it to 0 (gate and importer both honour it; the importer then skips them).
C. `CYRUS_CATALOG_TOOLS=1` (catalog_search in builds) is NOT in the paste: it changes model prompts/cost and needs the SQLite index file + build image support. Say so and I will add it.
D. Promote of `feature/cyrus-library-prod` is needed for the five serving fixes (data and env work on the current production build). It is additive (new files + guarded changes in `lib/cyrus/library/backend`).
E. Pre-warm of thumbnails: not done; say if you want a resumable warm job.

## 7. Files
- `lib/cyrus/library/backend/licence-gate.ts`, `importer.ts` (gate option + report), `objects.ts` (glob listDir, streaming `verifiedFile`), `library-store.ts`, `derive.ts` (EPIPE, by-path preview, HDR thumb, folder models, obj/mtl in bundles).
- `scripts/cyrus/library-import-prod.ts`, `library-validate.ts`, `library-prod-apply.sh`; `test/cyrus-library-prod.test.ts` (12 tests); `docs/cyrus/04-assets-and-library.md` + regenerated references.

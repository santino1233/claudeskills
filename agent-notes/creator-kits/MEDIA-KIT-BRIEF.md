# Brief: per-creator media kits in the partner portal

The owner made sponsored-segment videos for several creators, some in more than one language, each with a how-to text and end-frame images. They want each creator to find their own files in their media kit in the Nxeon partner portal, organized neatly, plus a generic English version for everyone.

## Files (already organized by the main session)
Staging copy: `/tank/creator-kits/<CODE>/`. `<CODE>` is the partner's sponsor code (`ReferralPartner.code`): AIXLL50, HOVEN, KOBBI, SPY40, WAASEPHI, ZEROSTER. `_generic/` is for every partner.

Each folder has:
- `nxeon-promo_<CODE>_<lang>_16x9.mp4` (about 12 MB each). The languages are en, tr, tl, es and hi; show them as English, Turkish, Filipino (Tagalog), Spanish and Hindi.
- `nxeon-promo_<CODE>_<lang>_16x9_endframe.png` (none in `_generic`).
- `HOW-TO-USE.txt`: a structured plain-text guide with "Your files", "What it is", "How to use it" (numbered), "Suggested narration" (timestamped lines), "Description text" and "Questions". Read one before designing.

In production the files will be installed (by the main session, not you) under `/opt/nxeon/partner-files/kits/<CODE>/`, next to the existing partner documents. See `lib/partner-files.ts`: it uses the same env-override pattern (`NXEON_PARTNER_FILES_DIR`), and a file copy is enough to publish (no deploy).

## Build
Work in a NEW worktree: `git -C /opt/nxeon worktree add /tank/dev-worktrees/partner-kits -b feature/partner-media-kits main`.

Read `/root/agent-notes/BUILD-HOST.md` first and follow it exactly. All tsc, dev servers and Playwright run on node-2 via `/opt/nxeon/scripts/devhost`, never on the primary. Never work in `/opt/nxeon` itself.

1. **Server lib** (extend `lib/partner-files.ts` or add `lib/partner-kits.ts`):
   - List the kit for one partner code: `kits/<CODE>/` plus `kits/_generic/`.
   - Group the files into assets: one video with its matching end-frame, per language.
   - Parse `HOW-TO-USE.txt` into its sections. Render them as real UI, not a `<pre>` dump. Keep the raw text available for download.
   - Strictly validate the code (`^[A-Z0-9-]{2,20}$`) and file names (a whitelist from the directory listing only). Block path traversal (no `..`, no absolute paths).
2. **Authenticated serve route.**
   - Find how `app/api/creator-partner/[doc]/route.ts` authenticates partners and copy that pattern.
   - The signed-in partner may get only their own code's files and `_generic`. Admins (use the existing admin check) may get any code.
   - It needs HTTP Range support for the MP4s so the in-page player can seek. Look at `app/api/board/attachments/[id]` for an existing range-capable file server to reuse.
   - Correct content types. `Content-Disposition` is inline for preview and attachment when `?download=1`.
3. **Partner portal UI:** the Media kit tab/section (see `lib/nx/partner-tabs.ts`, `components/nx/PartnerView.tsx`, `app/dashboard/partner/page.tsx`).
   - Add a "Your sponsored segment" block above the existing media-kit PDF download.
   - A card per language: a video player (preload="metadata", using the end-frame as the poster), the language label, "Download video", "Download end frame".
   - The how-to rendered as tidy steps.
   - The narration as a timestamped list.
   - The description text in a box with a Copy button. It contains their real partner link and code.
   - A "Download everything" button that zips on the fly, or download links for each file (your choice; streaming a zip of about 25 MB is fine).
   - A separate "Generic English version" block, for every partner.
   - When a partner has no personal kit, show only the generic block, with a line saying their personal version is on the way.
   - Match the portal's existing visual language (navy surfaces, rim borders, existing icons via `components/nx/Icon`). It must work in dark AND light theme, and at 390px with no horizontal scroll.
4. **Admin:** on `/admin/partners/[id]`, a small read-only "Media kit files" list for that partner's code (file names, sizes, a preview link), so the owner can check what a creator sees.
5. **Docs:** add a section to `docs/DOCUMENTATION.md` covering the folder layout, how to publish a new creator's kit (a file copy, and the naming convention), and the route's auth rules.

## Testing
- On node-2, point `NXEON_PARTNER_FILES_DIR` at a test copy of the kits. Use `devhost env set`, and copy the files into your worktree under an UNTRACKED, gitignored-or-never-added folder so devhost mirrors them. Or copy only one creator's folder plus `_generic` to keep it small.
- Seed your throwaway DB with one partner user (code ZEROSTER, linked user) and one with no personal kit.
- Screenshot the media kit tab for both, desktop 1440 + mobile 390, dark + light, plus the admin list. Save the screenshots to `/root/agent-notes/creator-kits/shots/` with `devhost pull`.
- Verify the auth rules with curl:
  - A partner can't fetch another code's file.
  - A signed-out request gets 401/404.
  - Range requests return 206.

## Hard rules
- Never `git add -A` or `git add .`. Add only your source files, never the video files: they live outside the repo.
- No deploy, no merge to main, no production DB access, no emails sent.
- Never run role/ownership SQL (REASSIGN/DROP OWNED, ALTER OWNER, roles).
- Never pkill or killall by pattern.
- Keep node-2 agent memory low and stop your dev server when done (`devhost stop`). A production build may run there, and it shares a 10 GB cap.
- Brand voice: Nxeon speaks as itself. Never mention a third-party infrastructure provider.
- If the permission system denies something, don't work around it. Note it and continue.

## Deliverable
Commits on `feature/partner-media-kits`, a clean `devhost tsc`, the screenshots, and a short report: files changed, how to install the kits in production (the exact `install` commands), and anything the owner must decide.

# AV - Cyrus product polish (r50, 2026-10-11)
Branch `feature/cyrus-r50-polish` (worktree `/tank/dev-worktrees/cyrus-r50`), latest r2 merged. NOT merged, NOT deployed, no migration, no flag flipped, no email sent, no paid call. Public pages 404 while `CYRUS_CUSTOMER_APP` is off.

## Commits
1. **Help center**: 27 markdown articles (`content/cyrus/help`), safe renderer (typed tree, no raw HTML), search, route group `(cyrus-help)`; cyrus.my serves `/help`, `/help/<slug>`. Modules article marked pending (r45 unmerged).
2. **Templates**: 24 Minecraft starters (idea, prompt, studios, assets, lowest plan, per-version notes, tags) + new-mod example prompts.
3. **Tour, empty states, tooltips, error review** (`lib/cyrus/content/copy.ts`, review table in `docs/cyrus/support/copy-review.md`), Get help button on the project page.
4. **/plans copy**: no prices or token amounts; 11 visible placeholders. Landing lines as `AV-landing-plans.patch` (dry-run applies; v7-landing untouched).
5. **Support**: 20 macros, email review (5 r40 emails reworded; one promised a rollback that can be incomplete), status page + 10 incident templates, launch announcement draft.
6. **Docs**: 06/11/README/features, references regenerated.

## Checked
New tests (help, templates, copy, plans, support) plus existing suites; tsc; shots of help and plans (dark, phone; looked at, fixed list markers and phone brand). Final: tsc clean; full cyrus-* + modbuilder-* suite 2703 tests, 2 failures found and fixed (docs link wording, one message lacked a next step), re-run of the affected files 35/35; host-seam, db-split and docs-coverage pass.

## Not done / notes
- New-mod page with a template picked not screenshotted (needs fixtures).
- Public pages sit in the Nxeon root layout, so the Nxeon cookie banner and chat widget show on them; they are dark-only.
- Legal wording (licence grant, takedown, privacy, refunds) and all amounts are owner items: OWNER-ACTIONS "r50".

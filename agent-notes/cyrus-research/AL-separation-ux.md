# AL - Cyrus separation UX + token economy (r41, 2026-10-11)
Branch `feature/cyrus-r41-sepux` (worktree `/tank/dev-worktrees/cyrus-r41`, latest r2 incl. r39 merged). NOT merged, NOT deployed, no migration, no flag flipped, no paid call, no Stripe.

## Commits
1. `1cd83cec5d` (A+B+C) Cyrus opens full screen: on `/dashboard/cyrus*` the Nxeon rail, top bar, tab bar, drawer and palette are not rendered; slim "Back to Nxeon" strip returns to the last portal page. No Cyrus token chip in the Nxeon bar. Cyrus pill: white + black mark (black + white in light mode).
2. `d0f92820f1` (D) v7 landing sigils (wave / flame / arcane sigil) as `ModelGlyph` + `public/cyrus/models/{id}.svg|-animated.svg|-mono.svg` from one source; animated on plan cards + Nxeon /cyrus; mono below 18 px.
3. `b1439daac6` (E) live meter (estimated so far vs held, then settled / returned / covered by Cyrus), build line, per-mod breakdown (per version, change, asset/config revision).
4. `6ef78a9cd8` (F) rollover while active, lapse rule, rollover cap, server-token scope, per-server cap, refund + early-delete reversal, Nxeon `server.purchased/renewed/refunded` events (same keys as the direct calls), rules shown in the plans tab.
5. Fix commit: literal Tailwind light classes (template-built ones were never generated), light back strip, phone total wrap, project-page "Token spend" card, docs.

## Ran (node-2)
- tsc clean; new tests `cyrus-sepux-r41` + DB `cyrus-tokens-r41-db` 8/8; existing ledger DB test 21/21 on the throwaway DB; host-seam + db-split ratchets pass; full `cyrus-*` + `modbuilder-*` suite 2555/2555 after the r2 (r39) merge.
- 18 `sep-*.png` in `cyrus-designs/impl-shots/` (dark + light, desktop + phone), looked at; fixed light pill (was white), light back strip (unreadable), phone total wrapping.

## Not run / not done
- next build, real Stripe, real Nxeon servers, events dispatch end to end.
- VPS deploy/renewal wiring (only matters for scope `all_servers`); clawback only on `server.deleted` events (Nxeon deletion paths not wired).
- Phone studio: the open preview panel covers the build trace, so the meter is not visible there (studio layout, not new).
- `sep-meter-light-phone.png` was taken before the back-strip fix.
- r40 bell offset (`top-20`) in the Cyrus layout still sized for the old header.
- Pre-existing stale test (notifications page gate) relaxed to accept the host gate.

## Owner decisions
OWNER-ACTIONS "r41": grant amounts, scope, caps, lapse rule + grace, rollover cap, deletion wiring. All r41 defaults are placeholders.

## Landing copy (plans section, for the parent to paste into v7-landing)
- Under the plans grid: "Unused tokens roll over every month for as long as your plan stays active."
- Next line: "Every paid Nxeon game server you deploy comes with free Cyrus tokens, plus more on each renewal."
- Per plan card (list item): "Unused tokens roll over while subscribed"
- Fine print: "Cancel and your plan tokens pause for 30 days: resubscribe and they're yours again." (depends on the lapse decision; drop the number if changed)

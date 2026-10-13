# K5 modui — mod browser, preview modal, Nxeon Verified (2026-10-01)

Branch `feature/mod-browser-verified`, worktree `/opt/nxeon-wt-modui`. Throwaway DB `nxeon_agt_modui`
(already dropped.)

## Built
- Customer browser: `components/customer/mods/browser/{ModBrowser,ModCard,ModPreviewModal,VerifiedBadge,bits}.tsx`,
  data `lib/mods-browse.ts`, actions `lib/actions-mod-browse.ts`; hooked into `components/customer/gamepanel/v2/ModsPanel.tsx` (K1 file).
- Verified core: `lib/mod-verify/{checks,status,smoke,store,preflight}.ts`, `lib/mod-html-harden.ts`.
- Runner: `scripts/mod-verify.ts` (owner-run). Admin: `/admin/nxlabs/verified` + `lib/actions-admin-mod-verify.ts` + `components/admin/ModVerifyControls.tsx`.
- Marketing: `/mods/verified` (tools/nxm/native/mods-verified + wire + ROUTES + SEO registry + live-routes.json), badge on mod detail (`app/nxm/_data/mod-lithium.ts`).
- Schema: ModVerification, ModVerifyTask, ModBlockedHash (additive, no relations).
- Tests: test/mod-verify.test.ts.

## Owner next steps
1. Merge, `prisma db push` (additive).
2. `npx tsx scripts/mod-verify.ts queue --family minecraft --game-version 1.21.1 --loader paper --limit 50`
3. `npx tsx scripts/mod-verify.ts preflight --limit 50`
4. `npx tsx scripts/mod-verify.ts smoke --plan`, then `smoke --confirm --region <non-primary region> --limit 1`
5. Hook `lapseForGameUpdate(family, version)` into the game-update worker (R's area).

## Interplay
- K3: richer columns read via `opt()` in lib/mods-browse.ts (clientSide/client_side, issuesUrl, wikiUrl,
  discordUrl, authors). If K3 names differ, add the names to LINK_KEYS / clientRequired(). No ModMedia added.
- K4: nothing of theirs touched; ModsPanel Installed tab untouched except act() signature ({id}).

## Post-merge note
K3 (mod-providers-massive) landed on main during this work; merged in and adapted (duplicateOfId hidden,
websiteUrl/issuesUrl/wikiUrl/discordUrl/donationUrl, authors[].avatarUrl, clientSide, ModMedia gallery, depList).
Screenshots: /tmp/claude-0/-root/4f329df3-66ee-49c8-a6c5-615ecf189efc/scratchpad/modui/shots/

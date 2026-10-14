# nx-email-redesign report (2026-10-14)
Branch feature/nx-marketing-emails, worktree /tank/dev-worktrees/nx-marketing-emails, commit 8618f6ef. Not merged, not deployed, no email sent.

Scope (owner update): ONLY the server-deployed email (mockup panel 2). The other templates are untouched and still use the old shell. They wait for owner approval.

## Preview: /root/email-preview-new/
- compare-serverDeployed.png: mockup panel 2 next to the 390px render
- serverDeployed.png (600px) / serverDeployed@390.png: Minecraft, Singapore
- serverDeployedValheim(.png/@390.png): Valheim, Germany
- serverDeployedVps(.png/@390.png): VPS variant (default hero, SSH box, VPS tiles)
- Regenerate: `NODE_PATH=/opt/nxeon/node_modules /opt/nxeon/node_modules/.bin/tsx scripts/email-preview.ts /root/email-preview-new --only serverDeployed --png --compare <mockup.png> --panel serverDeployed=2`

## Status vs mockup (3 refinement rounds)
Matches: header (wordmark with violet X, VPS | Game Servers | Hosting), eyebrow, big two-line headline with emoji, lead text, server card (grass-block tile, name, green Online pill, IP/Port with copy glyphs, region flag, plan, violet Manage Server button with glow), 2x2 quick-action tiles with glowing icon tiles, "Need help?" card with slate View Guides button, social icons and copyright.
Differences, on purpose or still open:
- The hero background is the deployed game's real key art (owner asked for game images). The mockup has abstract blue light beams there. Beams and glows are drawn over the art; the default hero (VPS) is beams only.
- Extra real content the mockup lacks: hostname subline ("Minecraft server"), the join-address note in the card, the SSH/SFTP root-password note under the help card, and a faint legal line (dashboard/help/support/status links, address) in the footer. These keep existing copy and tracked links.
- Tile subtitles are honest: "Mods & plugins", not the mockup's "70,000+ mods". There is no real count.
- Logo: the real public/logo.png (NX mark + NXEON), resized to 2x, unmodified (commit after 8618f6ef; the invented wordmark was removed per owner).
- Outlook desktop: no background images, rounded corners or gradients. It gets solid navy and violet. Inter only loads where clients allow @import; others fall back to system sans.

## Assets (public/email/, 2.7 MB, PNG/JPG only, scripts/email-assets.py)
- Per-game hero-<family>.jpg (1200x600) + tile-<family>.png (96px) for 46 families, made from the real key art in public/games/art. The Minecraft and Bedrock tile is the grass block.
- 8 families have no key art (schedule1, kf2, plutonium x4, arma3, fivem). They use hero-default.jpg and tile-default.png.
- Icon tiles, copy glyph, 7 region flags, 9 social icons, wordmark.
- Placeholder art: none. No mockup crops were used: heroes come from real game art and the beams are drawn in code. Tiles for games other than Minecraft are automatic crops of key art; the owner may want to hand-pick them.
- Socials: real sends use getSocialLinks() (Admin Settings), so nothing is invented. Preview samples use the real Discord invite plus placeholder x/youtube/instagram URLs.

## Tests
- tsc (devhost) clean.
- devhost tests: email-templates-overhaul, server-deployed-email, dunning-schedule, email-log-redaction, cyrus-admin-r40: 132/132 pass.
- The tracking inventory fixture did not change. Test updates: the logo and card checks accept shell v2, and a new shell-v2 test was added.
- Docs section 15 entry added.

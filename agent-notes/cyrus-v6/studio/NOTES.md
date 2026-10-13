# Cyrus v6 studio-ui: notes (branch feature/cyrus-v6-studio)

## v4b (feature/cyrus-v5~2) -> v5 regressions

| Feature (v4b) | v5 state | v6 studio-ui |
|---|---|---|
| Explain tab (plain English, how to use, commands, settings, permissions, good to know) | gone (only markdown in Notes) | RESTORED (`preview/ExplainTab.tsx`) |
| Safety check panel (4 guarantees, findings, pill) | one line in notes | RESTORED (Explain) |
| Failure reasons per error code, compiler output | raw error only | RESTORED (Explain + Code tab) |
| Try again / Edit and retry | missing | RESTORED (`lib/cyrus/retry.ts`) |
| Request quote, original description, attachment thumbnails | missing | RESTORED (Explain) |
| Diff / compare versions (DiffView) | missing (lib/cyrus/diff.ts unused) | RESTORED: Versions > Compare (unified diff) |
| Rename project | missing | RESTORED (pencil / double-click title) |
| Favourite | missing | RESTORED (star, real projects) |
| Share / copy link | missing (URL synced only) | RESTORED (link button) |
| Built with Cyrus badge | not rendered | Explain footer (`BuiltWithCyrusBadge`) |
| Keyboard shortcuts `?` sheet, N, F, V, 1-5 | only Ctrl K, /, Esc | NOT restored (added E = expand). Left. |
| Version lanes / branch from a version | timeline only | NOT restored. Left. |
| File search + "Ask Cyrus" in the palette | games/categories/mods/actions | NOT restored. Left. |
| Queue position + "fix N of 3" in the live view | missing | NOT restored. Left. |
| Screenshot capture (getDisplayMedia), voice V key + level meter | missing | NOT restored. Left. |
| Model-advice nudge ("Katara is light for this") | missing | NOT restored. Left. |
| NxLabs "View on NxLabs" / publish teaser | missing | community agent |
| Server Mods tab enable/disable | never in studio | lifecycle agent |

## Decisions taken (owner can overturn)

- Add game: only games in the Cyrus registry or with a ring preset, not on the ring. Only games with a
  generator can be added; registry-only (ARK, The Isle) show "Coming soon" and can't be added. Today all
  six supported games are on the ring, so the dashed branch, top-bar button, overview button and
  palette action are hidden. Custom branches made before v6 are kept (removable).
- Template-game demo mods removed from the studio (coordinator/owner decision); kept in
  `lib/cyrus/demo-seeds.ts` for the marketing demo (`useStore.setState({ demo: true })`).
- Minecraft idea seeds kept, but opening one no longer shows template code as if it were built.
- Expanded panel: desktop leaves the dock usable below it; phones get a full-screen sheet.
- Favicon: a vector rebuild of the black-tile pick (the owner's rule: chrome marks are SVG), PNG only for
  apple-touch/192.
- Rail highlight: one treatment in both themes, because the portal rail stays dark in light mode.

## Owner decisions still open

- Cyrus avatar (`CYRUS_AVATAR_ASSET` = iconset-r2-1 for now).
- Model glyph direction (crystal tier: 1/2/3 crystals). If rejected, only the paths in
  `components/cyrus/icons/ModelGlyphs.tsx` + `public/cyrus/models/*` change.
- Edits estimate assumes an edit costs 0.8x a small mod (CHANGE_COST_FACTOR). The economy notes say one
  measured Katara change cost more than a typical small build; a measured change factor would sharpen it.

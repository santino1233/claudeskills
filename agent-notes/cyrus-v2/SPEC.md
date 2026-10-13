# Cyrus v2 — design spec (2026-10-07)

Owner brief: "a very premium looking product, not just an add-on feature … sell this as a product on its own."
v1 failed because it was a dashboard: a framed card holding a rail, a hero card, a stage card, a
code card, a tab bar, more cards. v2 is an *application*: one living canvas, UI floating on it.

## 1. Concept — "the loom"

Cyrus is a weaver. The orb-web from the owner's workspace (Nexus) is the stage, re-dyed in the
Nxeon brand, and it is *never decoration*: every node is a real thing, every pulse is a real event.

- **Home = the Loom.** The Cyrus core (a faceted crystal) at the centre; your mods are the ring
  nodes; the "+ New mod" ghost and up to 8 template *seeds* sit on the outer ring. Running builds
  pulse along their thread to the core. Typing in the prompt makes the core breathe and throw light
  outward; voice makes it ripple with your real mic level.
- **Project = the Weave.** Opening a mod flies the camera into its node; the web re-forms around
  that mod: its files (Java / resources) are the first ring, its commands, permissions and config
  keys hang off plugin.yml / config.yml as satellites, and the build's own events ("Reading …",
  "Wrote …", "Compiler found 2 errors", "Safety check passed") become light travelling between the
  core and the file they name. The stage ring around the core fills as the build advances.

## 2. Layout map (desktop, inside the portal: everything right of the rail and below the top bar)

The portal `<main>` becomes an app frame for /dashboard/cyrus (same mechanism as /dashboard/mail:
no padding, exact remaining viewport height). Cyrus fills it edge to edge.

```
┌─ cyrus root (canvas = full area, position:absolute) ─────────────────────────────┐
│ ◈ Cyrus  Studio · PREVIEW                       ● Builder online  ⌘P Mods   ?   │ top strip, 56px, no box
│┌──┐                                                                             │
││＋│  ← glyph dock: 56px glass column, one orb per mod (running ones ringed),     │
││◉ │    hover/focus/L expands to a labelled library drawer (search, groups)       │
││◉ │                     What should we build?          (display, 54px)          │
││◉ │                 Cyrus writes, compiles, repairs …   (sub, ink-2)             │
││  │                          ◇ core of the web ◇                                 │
││  │            ╭──────────────── composer (glass capsule, 760px) ─────────╮      │
││  │            │ textarea · images                                        │      │
││  │            │ [img][mic] | Minecraft · Paper 1.21.11 ▾ | ● Saka ▾  … [Build]│ │
││  │            ╰───────────────────────────────────────────────────────────╯     │
││  │              Start from  ·  Coin shop  Daily streaks  Spleef  …  All ▸       │
│└──┘                                                       [+][−][◎] (web ctl)   │
└────────────────────────────────────────────────────────────────────────────────┘
```

Project (≥1180px):
```
│ ← Mods / Coin Shop ★  ● Writing code · v3 of 4 · Paper 1.21.11 · Saka   [Download][Install][⋯] │
│                                                       ┌ inspector (glass sheet, 36vw) ─┐ │
│      the mod's web (camera centred in the free area)  │ Code · Explain · Versions · Notes│ │
│      stage ring around the core                       │ live file tree + streaming code │ │
│      caption under the core: stage headline,          │                                 │ │
│      elapsed, last 4 thoughts (fading)                │                                 │ │
│   ╭──── change composer (compact capsule) ────╮       │                                 │ │
│   ╰───────────────────────────────────────────╯       └─────────────────────────────────┘ │
```
Mobile (390): canvas behind; top strip; dock becomes a horizontal orb strip; Home = headline +
composer + chips; Project = web hero (40vh) → inspector as a full-width sheet with tabs →
composer docked to the bottom. Content scrolls inside the frame; the canvas stays fixed.

## 3. What the network represents

| node | scene | meaning | look |
|---|---|---|---|
| core | home | Cyrus itself | faceted hex crystal, counter-rotating inner facet, dashed orbits; blue→violet rim, cyan spark |
| mod | home | one project | orb with its constellation glyph colour; ring = progress while building; red dashed ring = last build failed |
| version | home (sat.) | each build of a mod | small diamonds fanning out on hover / zoom (semantic zoom) |
| ghost | home | + New mod | dashed orb |
| seed | home | a template | hollow dashed orb on the outer ring, lights when its chip is hovered |
| core | project | the mod | crystal tinted by the mod's model colour; stage ring (Plan/Write/Compile/Fix/Safety) |
| file | project | a source file | Java = violet orb `{}`; resource = cyan rounded square `≡`; live: glows + caret ring while being written |
| cmd/perm/cfg | project (sat.) | /commands, permission nodes, config keys | tiny glyph dots on plugin.yml / config.yml |
| thought | project | an event | a pulse along the thread to the file the event names (or a ripple on the core) |

Real activity → motion: Write/Edit (streamed bytes) = light core→file at a rate set by the stream;
compile = light flowing *inward* from every file; repairing = amber pulses to the files being
edited; safety = a cyan scan ring sweeping outward over every node; success = a single bloom;
failure = threads dim, core cools to amber.

## 4. Motion language

- One easing for UI: `cubic-bezier(.2,.8,.2,1)`; 180 ms hovers, 260 ms sheets, 900 ms camera flights.
- Ambient life is *slow*: web sway 0.7 rad/s, halos breathe at ~0.15 Hz, stars twinkle.
  Light only travels when something real happens (plus a very low ambient trickle on the home web).
- Depth: 3 parallax star layers + an aurora layer (pre-rendered blobs drifting), pointer parallax
  (≤12 px on the far layer, ≤4 px on the web), additive glow only on light (pulses, halos).
- Rotating neon rim on the prompt: 1px conic rim that rotates only while focused/typing/listening.
- Live code: characters fade in as they stream (a span per chunk, 280 ms opacity), caret follows,
  edited lines glow once. Never fake code: skeletons are clearly skeletons.
- `prefers-reduced-motion`: no camera flights, no pulses, no rim rotation; the canvas renders one
  static frame per state change. Canvas pauses when off-screen (IntersectionObserver) or the tab is hidden.

## 5. Type scale (Geist / Geist Mono, already the portal face)

| role | size / line | weight | tracking |
|---|---|---|---|
| display (home) | 54/58 (mobile 34/38) | 600 | -0.035em |
| title (project) | 26/30 | 600 | -0.025em |
| section | 15/20 | 600 | -0.01em |
| body | 14/22 | 400 | 0 |
| small | 12.5/18 | 500 | 0 |
| micro label | 10.5/14 Geist Mono, uppercase | 500 | .14em (sparingly) |
| code | 12.5/20 Geist Mono | 400 | 0 |

## 6. Colour tokens

Brand: violet `#8c3ae9`, blue `#2f7eef`, cyan `#14c5e4`, magenta `#d623e1` on deep navy.

```
--cy-bg0 #04061a   --cy-bg1 #070b26   --cy-bg2 #0c1236     (canvas, radial)
--cy-violet #8c3ae9 --cy-blue #2f7eef --cy-cyan #14c5e4 --cy-magenta #d623e1
--cy-ink #eef1ff --cy-ink2 #b4bce0 --cy-ink3 #7d87b2 --cy-ink4 #545e8a
--cy-glass rgba(10,15,44,.56) + blur(22px) saturate(1.5); --cy-glass-hi rgba(255,255,255,.06) (inset top)
--cy-line rgba(150,165,255,.14) --cy-line2 rgba(150,165,255,.24)
--cy-ok #3ee6a8 --cy-warn #ffb44f --cy-bad #ff5c8a
models: Katara #14c5e4 (cyan) · Saka #8c3ae9 (violet) · Yakko #d623e1 (magenta); primary action = blue→violet
```

**Light theme decision: the canvas stays a dark island ("Dawn" variant).** In the portal's light
theme the rail and top bar are already dark navy islands, so a dark Cyrus makes the whole viewport
one continuous app instead of a light page with a dark box in it; the network's glow (additive
light) only reads on dark; and code panes are dark in both themes portal-wide. Light users get a
deliberate *Dawn* palette instead of a flip: lifted indigo ground, warmer magenta/cyan aurora,
pearl-tinted glass (lighter surfaces, brighter rims), same ink contrast.

## 7. States

Home: empty (core + ghost + seeds, headline) · with mods · builds running (dock rings + web pulses)
· builder offline (dimmed core, composer explains) · reconnecting.
Project: queued (position) · planning · writing (live code) · compiling · repairing (fix n of 3) ·
safety · just-built bloom → Explain · succeeded (head / older version banner) · failed (reason, tips,
Try again / Edit and retry) · cancelled.
Composer: idle · focused (rim rotates) · typing · images (thumbs, uploading, error) · listening
(waveform + interim words) · disabled (reason) · model advice.
Overlays: model picker, game/version picker, project palette (⌘P / P), shortcuts (?), install,
template library.

## 8. Capabilities carried over from v1 (all of them)

multiple projects · live build stages · model picker Katara/Saka/Yakko · game + version picker ·
pasted / dropped images (now actually read by the AI) · voice-to-text with waveform · rotating neon
rim · versions: map, compare/diff, restore, branch · explain this mod · templates · notes ·
favourites · rename · duplicate · shortcuts · estimates · install / download jar / source zip ·
Cyrus badge · toasts when a background build finishes.

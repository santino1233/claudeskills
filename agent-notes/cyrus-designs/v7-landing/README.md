# Cyrus landing page (v7)

A single-page, self-contained static site: `index.html` plus `assets/`. No build step, no network calls, no hotlinked assets.

## How to open
It uses ES modules and an import map, so open it over HTTP rather than `file://`:

```
cd /root/agent-notes/cyrus-designs/v7-landing && python3 -m http.server 8080
# then open http://localhost:8080/
```

## What is in it
- **Hero:** the Cyrus Core is a raw WebGL fragment shader with SVG orbital rings, energy streams and particles (`assets/js/core.js`). Six glass panels show a looping auto-demo. A prompt types itself, then runs through plan, code, textures, sound, 3D, compile and install. The prompt box has a game selector (Minecraft live, the rest "Soon"), an Advanced panel and a Create Mod button.
- **Studios:**
  - Texture: 16x16 paint canvas. What you paint also appears as the dropped item in the "In game" section.
  - Sound: WebAudio sounds synthesised in JS, with a waveform you can scrub.
  - 3D model: three.js r186, vendored in `assets/vendor` (MIT), lazy-loaded. It shows the real meshgen `.glb` files (rifle, katana, crate) with a procedural studio environment (PMREM soft boxes, `assets/js/studio-env.js`), physical materials (metal, clearcoat), brand rim lights, soft shadows, auto-framing and a slow auto-rotate.
  - Motion & effects (`assets/js/motion.js`, lazy-loaded when the card nears the viewport): eight real-time three.js scenes drawn by ONE shared WebGL renderer and copied into each tile's 2D canvas (one GL context, rounded tiles kept, paused/offscreen tiles cost nothing). Fire (meshgen AK: recoil burst, muzzle star + side flash, flash light, sparks, smoke, ejected casings), Reload (meshgen drum LMG: drum out/in, seat, rack), Door (the library's `door-heavy-iron` glb and its Open / Slam_Shut clips, re-skinned planks + iron straps, light spilling through, dust on the slam), Explosion, Flame, Smoke, Water (shader pool with real ripples), Arcane. Effects are the 256 px procedural flipbooks (`assets/motion/fx/`, CC0, Nxeon-generated) with frame blending and correct additive/alpha blending, plus GPU point particles. `assets/motion/posters/` are reduced-motion renders, shown before WebGL loads and if it is unavailable.
  - Config: sliders drive a walking creature.
- **The rest:** In-game cards (crops of the item-state renders, no portal chrome), Games, Plans (animated SVG tier icons), the Nxeon bridge, the final CTA and the footer ("A Nxeon product").
- **Motion handling:** `prefers-reduced-motion` gets a static, finished state (motion tiles render one hero frame and only play when tapped). Loops pause when offscreen or when the tab is hidden.

## Demo only (nothing is wired)
- **Sign in with Nxeon / Sign in / Get started:** shows a toast.
- **Create Mod:** runs the visual pipeline locally on the typed text, then shows a toast. It builds nothing.
- **Nxeon API key + Connect:** the value is never read or sent.
- **Plan buttons:** these scroll to the prompt. No prices are shown on purpose.
- **Advanced options** (tier, studios, install target): UI only.

## Needs wiring for real
1. **Sign in with Nxeon:** link to the existing Kodely/Nxeon SSO flow (one account, one wallet).
2. **Create Mod:** POST the prompt, game and options to the Cyrus job API. Then stream the real stage events into the same `cyrus:stage` CustomEvent that the hero already listens to.
3. **API key:** a real connect endpoint that validates the key server-side. Never store it in the page.
4. **Install target:** list the user's Nxeon game servers.
5. **Plans:** link to real checkout and pricing once it is decided.

## Verification
Screenshots are in `shots/`. They were taken with headless Chromium (Playwright) on node-2 at 1440x900, 390x844 and 360x760, plus 1440 with reduced motion. There were no console errors and no horizontal overflow.
Full-page phone captures stitch the 100svh hero twice. That is a capture artifact; the viewport shots are accurate.

---
name: video-editing-pipeline-setup
description: "Nick's local video editing pipeline (video-use + HyperFrames) for his \"Vibe Coding till I reach one paying customer\" YouTube series"
metadata: 
  node_type: memory
  type: project
  originSessionId: b8931927-c4d2-4a39-ad0f-d47c389ed490
  modified: 2026-08-20T09:49:19.141Z
---

Runs a local Claude Code video-editing pipeline in `C:\Users\edmem\OneDrive\Desktop\Video Projects\`: `tools/video-use` (transcribe/cut/grade/caption skill) + `tools/hyperframes` (motion graphics renderer), installed as Claude Code skills. Transcription defaults to local `faster-whisper` (no ElevenLabs key, no per-minute cost) — this was a deliberate choice after he said he didn't want ElevenLabs.
**How to apply:** don't suggest ElevenLabs/paid transcription unless he asks for diarization on multi-speaker footage.

Records with OBS Studio: separate Screen and Webcam outputs land in `C:\Users\edmem\Videos\OBS\Screen` and `...\Webcam` respectively (same mic duplicated into both — pipeline convention is to use screen.mp4's audio as the single master track and treat webcam.mp4 as a silent video-only overlay).
**How to apply:** when starting a new video project, copy the relevant OBS Screen+Webcam pair into a new subfolder under Video Projects (not the OBS holding folders themselves) before editing.

Is producing an ongoing series ("Vibe Coding till I reach one paying customer") about building an app called **Kodely** (kodely.me — an AI website builder, Rocket.new-style, using Claude Code) with essentially zero starting budget — video 1 covers the intro/stakes-setting and the first live-build session on Kodely's homepage. Note: this was misspelled "Codely" throughout earlier session notes/files — the correct product name, confirmed directly against the actual site, is **Kodely**.
**Why:** series premise and stakes matter for tone/pacing calls on future episodes (scrappy, cost-conscious, real build sessions, not polished corporate content) and for continuity (references to Nexion, an earlier project, and to Kodely's own product decisions as they happen).

A baz.studio project ("Kodely - Brand & Product Context", separate from the local video-editing pipeline) holds structured brand context for Kodely — both the product's own clean marketing look (white/liquid-glass/pink-peach-magenta) and the YouTube series' distinct darker synthwave/neon video-editing treatment, saved as separate labeled entries so they don't get conflated. This is for if/when Baz is asked to generate promotional content for Kodely itself — it is NOT used for the actual episode edits, which stay on the local ffmpeg/HyperFrames pipeline.
**Why:** explicit ask — wanted Baz set up to understand the repo/brand before future videos, independent of the local editing pipeline.

There is now a living, reusable series template — not just a one-off video-1 edit. `tools/video-use/templates/vibe-coding-series/README.md` is the starting checklist for a new episode; `tools/video-use/LIQUID_GLASS_STYLE.md` is the full style/technique reference (updated through episode 1's neon-border/retrowave-background/CRT-transition/dynamic-shrink-aside iteration); `first-video/edit/scripts/composite_full.py` is the reference compositing implementation; the animated background/border HyperFrames sources under `first-video/edit/animations/slot_retrowave_bg_loop`, `slot_neon_border_loop`, `slot_grain_flicker_loop` are meant to be copied forward into new episodes rather than rebuilt.
**Why:** explicit ask — "I want to save all of these skills and assets for future videos in this series... continue to build onto it as we make more videos... I want [Claude] to learn my style."
**How to apply:** when starting a new episode, read the template README + style doc FIRST and reuse/extend the existing reference implementation rather than rebuilding the compositing pipeline from scratch. When a style/technique decision changes or firms up during a new episode's edit, update the style doc and template README so the NEXT episode starts from the current state, not a stale one.

See also [[video_editing_style_prefs]] for his specific editing/motion-graphics style preferences.

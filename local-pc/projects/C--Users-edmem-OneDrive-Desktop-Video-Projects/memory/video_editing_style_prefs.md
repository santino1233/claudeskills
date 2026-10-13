---
name: video-editing-style-prefs
description: "Nick's editing/motion-graphics style preferences for the video-use + HyperFrames pipeline, learned across the \"Kodely\"/Vibe Coding series edit"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b8931927-c4d2-4a39-ad0f-d47c389ed490
  modified: 2026-08-20T09:49:36.877Z
---

Visual style is "liquid glass" (iOS 26 aesthetic) tied to his own product's actual brand gradient: warm pink → peach → magenta. Applies to motion graphics, captions, and UI-adjacent overlays.
**Why:** he explicitly wants the video's visual language to match Kodely's own product design, not a generic template.
**How to apply:** default new motion graphics to frosted/translucent glass panels (backdrop-blur, soft shadow, subtle white edge-highlight, rounded corners) in that palette unless he specifies otherwise for a given video.

Webcam PIP: rounded corners + soft shadow + glass-edge ring, default bottom-right, dynamically repositions (smooth animated slide, never an instant teleport) when it would sit on top of something important on screen (e.g. a chat panel). Webcam goes fullscreen (blur-fill, not cropped) during pure talking-head sections where nothing relevant is on screen.
**Why:** explicit ask — "it can't just be a disappear and reappear in a new location."
**How to apply:** check what's actually on screen at each PIP placement before defaulting to a corner; don't just alternate corners arbitrarily.

Zoom-ins must be used sparingly and only on genuine focal points (something specifically being pointed at/discussed), never as decoration on broad layout commentary. Cap zoom around 2.0x — tighter crops visibly degrade quality. Verify zoom targets by densely sampling real frames, not by inferring from transcript text alone (a split-screen browser+chat-panel layout caused a real mistargeting bug once — the actual UI element referenced by narration can be in a different screen region than assumed).
**Why:** caught two rounds of zoom targeting errors (wrong panel, then over-tight crops) via direct feedback.
**How to apply:** before committing to a zoom plan, verify against actual frames near the target timestamp, not just the packed transcript text.

Very precise, detail-oriented about cut cleanliness — catches subtle mid-word cutoffs and redundant repeated phrases (stutters, doubled sentences) by ear that raw transcripts/timestamps can mis-represent (ASR can smear or merge repeated words; cross-checking against a second transcript of the same audio, e.g. screen vs. webcam track, can reveal what one run missed).
**Why:** flagged 5 distinct precise-timestamp cut issues in one pass after an initial "sounds good" pass — he re-watches carefully and expects frame/word-accurate fixes, not approximate ones.
**How to apply:** treat "sounds clean" feedback as provisional, not final sign-off. When fixing a flagged cut, pull exact word-level timestamps rather than eyeballing.

Motion graphics should be purposeful and tied to specific transcript content (a stat card for a specific number mentioned, a title reveal timed to when a name is said, a palette swatch synced to color words) — not generic decoration. Prefers a small number of well-placed graphics over covering every possible moment.
**Why:** his own creative direction throughout — e.g. specifically requested a retrowave-then-nebula intro synced word-by-word to the real audio, and asked for zooms only at genuine callouts.
**How to apply:** when proposing motion-graphic moments, ground each one in a specific line/word from the transcript and its real timestamp, not a generic template slot.

Is a working YouTuber making a "Vibe Coding till I reach one paying customer" series about building an app called Kodely with Claude Code — cost/token-conscious (asked directly about cumulative token spend on a video edit).
**How to apply:** be mindful of expensive sub-agent rebuild cycles; prefer fixing/patching over full rebuilds where the tooling allows it, and flag when a from-scratch build (e.g. a new motion graphic) is likely to cost a lot before doing it.

Wants the webcam PIP's neon-glow border present at ALL times the webcam is visible — not just during full-screen "hero" moments, also during the smaller screen-recording+PIP layout. When adding a new visual treatment to one layout mode, check whether it needs to apply to every layout mode the webcam appears in, not just the one being actively worked on.
**Why:** flagged directly — "the neon border also needs to stay on at all times, even when its over top of the screen recordings, i noticed in this video it wasnt."
**How to apply:** default to applying webcam-attached visual treatments (border, glow, mask) universally across every compositing function that draws the webcam, unless told otherwise.

Sub-agent "verified" reports in this pipeline have been wrong multiple times this session (a corner-PIP clipping bug reported clean, a card/webcam overlap reported as having "real margin" when it didn't, a grain-layer-scope claim) — always because the agent's own verification pass sampled only a couple of convenient timestamps (transition edges, opening frames) instead of densely sampling a feature's full active window.
**Why:** each time, independently re-checking with fresh frame extraction at different timestamps than the agent used caught a real, visible defect the agent's own report called "clean."
**How to apply:** before presenting delegated video/compositing work as done, independently extract and inspect at least one frame the sub-agent's own report didn't specifically call out — don't relay a "verified" claim without a spot-check of your own, especially for anything involving overlay positioning, alpha compositing, or multi-state animations (hero/corner/mid-transition).

Is building a living, reusable template for this series (not a one-off per-video edit) — see [[video_editing_pipeline_setup]] for where it lives. Explicitly wants Claude to accumulate and reuse style knowledge across episodes rather than rebuilding from scratch each time.
**Why:** "I want to save all of these skills and assets for future videos in this series... I want [Claude] to learn my style."
**How to apply:** when a style/technique choice is confirmed (not just tried once, but actually approved after iteration), fold it into `LIQUID_GLASS_STYLE.md` and the template README, not just this memory file — those are the artifacts a future episode's session will actually read.

See also [[video_editing_pipeline_setup]] for the technical pipeline this all runs on.

Master audio must come from the WEBCAM recording, not the screen recording, so the talking-head shots are lip-synced. Both OBS outputs carry the same mic, so nothing is lost — but the webcam file's video and audio share a container, which makes lip-sync exact with no offset to compute.
**Why:** asked for it directly mid-edit — "use the audio from the webcam footage so its lipsynced."
**How to apply:** default to the webcam track as master on any dual-output OBS project; align the screen recording into the webcam's clock rather than the reverse, and only transcribe the webcam audio.

Check the FINAL file's integrated loudness before calling a render done. His raw OBS captures land around -44 LUFS (~30 dB under the -14 LUFS streaming target) and the first episode shipped at -42.9 LUFS — effectively inaudible at normal volume, and nobody caught it.
**Why:** found by measuring rather than by listening; it had already shipped once undetected.
**How to apply:** two-pass loudnorm to -14 LUFS once on the concatenated track (never per segment), and verify with ebur128 on the final export, not an intermediate. Expect dynamic mode, and say so — this material needs real compression to get there.

Visual spot-checks are not enough on a finished render — the defects that actually reach him are ones only measurement catches. On episode 2 he caught three that frame-by-frame inspection had passed: words clipped short at cuts (30 of 60 out-points sliced through speech), 26 seconds of audio silently destroyed by a single ffmpeg filter graph (the file still reported the right duration), and a jagged webcam corner from a non-antialiased mask.
**Why:** each looked fine in the frames I checked; each was trivially detectable by measuring instead of looking.
**How to apply:** before calling a render done, run mechanical checks, not just eyes — decoded audio sample count vs source, audio packets with implausible durations, every cut boundary against the waveform envelope, and a corner crop at native resolution with nearest-neighbour scaling. And when a metric flags something, check the metric itself isn't wrong before acting on it (a naive "speech right after the cut" test scored good cuts as bad here).

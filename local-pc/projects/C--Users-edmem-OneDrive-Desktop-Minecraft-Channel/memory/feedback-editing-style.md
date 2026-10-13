---
name: feedback-editing-style
description: Creator's editing feedback - SFX under voice, never clip words, memes only their funny part, subtle color polish, many engagement zooms
metadata:
  type: feedback
---
- SFX must sit under the voice, never over it. Levels are voice-relative.
- Never clip the mic: cuts must include each word's full tail. A render cut guard enforces this.
- Memes and SFX: use only the comedic beat, not the full clip. This is not strict; vary it.
- Wants subtle contrast/saturation/vibrance polish on everything (looks presets).
- Wants frequent zoom-ins and snappy edits for short attention spans.
- Wants consistent but not rigid style; extend libraries creatively.

**Why:** stated directly by the creator while reviewing test renders.

**How to apply:** default to these in every edit and when changing the pipeline.
- 2026-10-06 review of the auto edit:
  - Changing the colour grade or mood every few seconds is "very hard to watch". Hold the look steady and change it only for real story sections of 8 s or more.
  - No automatic colour-flash stingers.
  - VFX must fit the moment: no K.O. on a mundane line, no subscribe CTA during a panic.
  - Don't overuse effects. About 14 SFX/min, the same sound at most twice, and zooms mostly on strong beats.
  - SFX must stay clearly under the voice.
- 2026-10-14 review of the first "Random Drops" full edit (rd-full v1) - hard rules for every future edit:
  - NO filters/grades/brighten: he could barely see the gameplay. Looks off, one mode, never darken.
  - NEVER show creative mode, commands being typed, F3 debug screen, pause menu, or the chat lines "Set own game mode…"/teleport/gave xp. If a survival-mode moment is unavoidable, punch in (zoom) so the chat is out of frame. The footage scan for this is `projects/rd-full/work/badmap.py` (OCR of chat + HUD hearts + inventory detector); reuse it on every episode.
  - Use his FINAL intro take (cut retakes/"welcome to the video" repeats and gaps between takes); never cut a voice short (pad tails ~0.55 s); cut his "part two / new video" talk, edit all parts as ONE video.
  - Montages/time-lapses: mute the chopped game audio, lay epic cinematic music + block-hit SFX over them (one pre-mixed hit track; Windows ffmpeg command lines break with 250+ inputs).
  - Zoom in on inventory/chest close-ups; vary with keyframe-style zooms and block-wipe transitions.
  - Motion graphics only where they literally fit the story (chaos meter, objective, time skips, deaths counter); no auto toasts/stickers/location tags.
  - Story must be self-explaining: hook that shows the premise (random item from every block, chaos meter, "block placed in every chunk" realization), no unexplained scene jumps, drop boring inventory management.
  - Music: fewer, longer beds; he disliked some beds (unknown which: kazoo-ish "Kazoom" and the tense "Biz Baz" were replaced by Dyalla "BMO").

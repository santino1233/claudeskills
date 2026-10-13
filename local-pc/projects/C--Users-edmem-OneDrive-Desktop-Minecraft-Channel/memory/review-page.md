---
name: review-page
description: MC Studio "Review & train" page (localhost) - creator answers per-edit decisions; learning files the editor must read
metadata:
  type: project
---
Built 2026-10-14. In the studio UI (`uv run mcs ui`, http://localhost:8765) open Episodes > <slug> > "Review & train this edit" (#/review/<slug>): live preview, full multi-track timeline, and one card per decision (scene, Flashback shot, music, meme, green screen, motion graphic, text, SFX, bleep). Per card: Keep / Swap (recommended options from the finder + free search) / Edit text-graphic vars / Remove / comment; "+ Add something at the current time"; "Apply & re-render preview" rebuilds (custom builder `projects/<slug>/build_v2.py` re-applies answers and skips cut scenes) then renders a preview.
Code: `studio/mcstudio/review.py`, `review_apply.py`, endpoints in `server.py` (/api/projects/<slug>/review*), `studio/ui/review.js`.
Training data: `studio/learning/feedback.jsonl` (every answer + context), `learning/prefs.json` (asset score; `assets.find` adds 0.35*score), `learning/notes.md` (his comments - READ IT before every editing pass).

**Why:** creator wants a faster way than chat to train the editor; HyperFrames Studio edits its own HTML compositions, not our EDL, so we built our own.
**How to apply:** at the start of any edit, read `studio/learning/notes.md` and prefs; put new answers' lessons into feedback-editing-style. See [[feedback-editing-style]], [[mc-studio-project]].

---
name: cinematic-autopilot
description: "Autopilot (record -> finished video) + Flashback cinematic B-roll pipeline built 2026-10-10; what exists, how it runs, what is still unproven"
metadata:
  node_type: memory
  type: project
  originSessionId: ff88cddc-4e2b-4ed3-ae32-bc595258add8
  modified: 2026-10-10T09:11:45.504Z
---

As of 2026-10-10 the studio can go from an OBS recording to a finished video + 3 Shorts + COPY-PASTE.txt (title/description/tags/thumbnail prompts) with no commands, and add real cinematic shots from the Flashback replay of the same session.

Pieces (all under `studio/`, docs in `studio/docs/`):
- `mcstudio/autopilot.py`: watches OBS folders, waits for Minecraft/OBS to close, runs transcribe -> analyze -> autoplan -> **cinematic shots** -> render -> Shorts -> `Finished/`. Opt-in (`autopilot.enabled`, default OFF), UI page `#/autopilot`. 3 audio tracks from OBS: track 2 = desktop, track 3 = mic, track 1 = mix (ignored).
- `mcstudio/cinematic.py`: Cinematic Director. Syncs replay to video (motion cross-correlation, proven within 0.06 s on the 15:02 session), plans shots (aerial, orbit, death reveal, ...), QA, splice. `shots.json` in `projects/<slug>/broll/`.
- `mcstudio/flashback_replay.py` / `flashback_keyframes.py`: pure-Python reader of Flashback replays and generator of Flashback editor-state keyframes.
- `tools/flashback_auto/` + `mcstudio/flashback_export.py`: a small Fabric mod (loaded only via `-Dfabric.addMods`, inert unless an `ARMED` marker exists, never touches servers) that opens a replay and exports shots with no clicks. Proven once on 2026-10-10: tiny test clip then 2 real 1080p shots, game closed itself, state restored. Decompiler CFR 0.152 is in `tools/` (user approved the download).
- Flashback (not Replay Mod) is the supported replay mod; both were installed for testing. Replay Mod .mcpr files are not read.
- Setup facts: TLauncher, Fabric 1.21.11, Paper server, Radeon 890M (no CUDA). Flashback config at `.minecraft/config/flashback/flashback.json`; creator still has First-person Updates 20 (want 60), toasts on (want off), quicksave off (want on).

**Why:** the creator wants to just play and get a finished, edited video with B-roll.
**How to apply:** the one thing not yet proven is a fully unattended run (Autopilot ON -> play -> close Minecraft -> video appears with shots); the watchdog kill path and detection of the real TLauncher process are untested. Real game launches are supervised tests: ask the creator to leave the PC alone first. Never splice placeholder (fake exporter) clips into real videos.
See also [[mc-studio-project]], [[feedback-hands-off]].

# D - Sound Studio research (step 5), 2026-10-10

Labels: VERIFIED (url) = I opened it this session. UNVERIFIED = memory or search snippet only. Page budget used: 12 of 12 (some fetches returned thin summaries, noted).

## 1. Minecraft Java sound system

**sounds.json** (VERIFIED https://minecraft.wiki/w/Sounds.json)
- Lives at `assets/<namespace>/sounds.json` in a resource pack. Top level maps an **event key** (e.g. `entity.zombie.hurt`, or a custom `banshee.wail`) to `{ "replace": bool, "subtitle": "<lang key>", "sounds": [...] }`.
- Each `sounds` entry is either a bare string (file path without `.ogg`, optional `namespace:` prefix) or an object: `name`, `type` (`file` default, or `event` to reference another event), `volume` (>0, default 1), `pitch` (>0, default 1), `weight` (int, random pick bias), `stream` (true for long sounds; wiki recommends it for music/records), `attenuation_distance` (int), `preload` (bool).
- Event vs file: the game plays an **event key**; the engine picks one entry from the list by weight (variants). Files are the raw Ogg Vorbis. Variants are how you avoid repetition (author 3-4 per hurt/step).
- `replace: true` discards the vanilla list for that event; false/absent appends to vanilla variants.
- Format: **Ogg Vorbis required**. **Mono = positional** (volume falls with distance); **stereo = constant volume** regardless of distance. So every mob/world sound must be mono; only music/UI may be stereo. All VERIFIED same URL.
- Custom namespaces: use `namespace:key` / `namespace:path` (VERIFIED same URL). Put a plugin's keys in its own namespace (e.g. `nxeon_banshee:`), never `minecraft:`.
- Subtitles: `subtitle` is a translation key; the text must exist in `assets/<ns>/lang/en_us.json` (UNVERIFIED detail, standard behaviour).

**What a pack can override vs add** (reasoning; UNVERIFIED in game by me)
- Override `entity.<mob>.hurt/death/ambient/step`: changes that sound for EVERY vanilla mob of that type server-wide, for each player with the pack. Fine for a total-conversion, bad for a mod that adds one "banshee" built on a zombie.
- Add new keys (`ns:banshee.wail`): triggered only by plugin code. This is the right default for Cyrus: new keys, plugin plays them, and silences the vanilla base mob (`Entity#setSilent(true)`, UNVERIFIED API name) so vanilla zombie groans do not overlap.
- Plugin playback (Paper/Bukkit): `World#playSound(Location, String key, SoundCategory, volume, pitch)` and `Player#playSound(...)` take a **string key**, so custom keys work without an enum (UNVERIFIED signatures; check against the Paper jar's javap during build sheets). Category (`HOSTILE`, `NEUTRAL`, `PLAYERS`, `AMBIENT`, `MASTER`...) controls the client's per-category volume slider. Volume above 1.0 extends audible range (rule of thumb ~16 blocks x volume; UNVERIFIED).
- If the player lacks the pack, an unknown key plays silently, so a mod must degrade gracefully.

**Versions**: wiki's sounds.json page has no 1.21.x/26.x entries (VERIFIED same URL), i.e. the schema looks stable since 1.13 (`preload`). 26.1 is the first year-based release; resource pack format is now **84.0** (VERIFIED https://minecraft.wiki/w/Java_Edition_26.1), which matches G-gaps: pack.ts tables are wrong for 26.x. 26.1 also added baby-mob and adult-variant sounds (same URL), so vanilla event names have grown; do not hard-code a list, read keys from the version's asset index. Pack metadata (`pack.mcmeta`, min/max format) is a pack-builder concern, not a sounds.json one. 1.21.11 -> 26.x pack_format deltas for sounds: none found.

**Complete mob sound set** (durations/levels are conventions, UNVERIFIED; tune against vanilla files by measuring them with ffprobe/ebur128 during MVP):

| event | purpose | variants | length | notes |
|---|---|---|---|---|
| ambient/idle | random loop-free grunt | 3 | 0.8-2.5 s | quietest, low pitch jitter |
| hurt | damage taken | 3 | 0.2-0.6 s | sharp transient |
| death | on death | 1-2 | 0.6-1.8 s | longest decay |
| step | per footstep | 4 | 0.08-0.25 s | very short, no tail |
| attack | melee swing/bite | 2-3 | 0.3-0.8 s | loud transient |
| special | ability/charge/roar/boss phase | 1-2 each | 0.5-3 s | one key per ability |
| spawn | summon/appear | 1 | 0.8-2.5 s | optional |

Loudness: peak-normalise to about -3 dBFS, attack/death loudest, step/ambient 6-10 dB lower; use `volume` in sounds.json for relative balance rather than re-baking (UNVERIFIED convention). Mono, 44.1 kHz, trimmed with 5 ms fades to avoid clicks. Keep files small (pack size matters for the join prompt).

## 2. Ogg Vorbis pipeline

- **Server-side ffmpeg + libvorbis (recommended).** FFmpeg is LGPL 2.1 by default and becomes GPL 2 if GPL parts are enabled (`--enable-gpl`) (VERIFIED https://ffmpeg.org/legal.html). That page does NOT address libvorbis or the separate-process case (it said so). libvorbis/libogg are BSD-3 (VERIFIED https://github.com/erikh2000/sl-web-ogg, bundled Xiph COPYING files). Calling ffmpeg as a subprocess on a service we run, never redistributing the binary, is the low-risk pattern; legal sign-off still advisable (UNVERIFIED legal reading). Distro ffmpeg is often built with GPL flags; use the distro package unmodified on the server (no redistribution) or a static LGPL build.
- Command shape: `ffmpeg -nostdin -i in.wav -ac 1 -ar 44100 -c:a libvorbis -q:a 4 out.ogg` (UNVERIFIED flags; the native `vorbis` encoder is experimental, prefer libvorbis).
- **Safe use on the build host**: spawn with an argv array (no shell), `-protocol_whitelist file` and file inputs only (no URLs), CPU/time/memory limits (`timeout`, cgroup), max input size and duration (e.g. 60 s), run in the existing build container, never feed user-supplied filter strings. ffmpeg decoders have a CVE history, so keep it patched and sandboxed.
- `oggenc` (vorbis-tools) is GPL-2 (UNVERIFIED); fine as a separate process but ffmpeg already covers it and decodes MP3, so skip it.
- **Browser/wasm**: `sl-web-ogg` MIT + BSD-3 Xiph parts, `encodeAudioBuffer()` with quality param, promise API, only 17 commits and 0 stars (VERIFIED https://github.com/erikh2000/sl-web-ogg) - immature, treat as a fallback. `libvorbis.js` (itsjoesullivan) BSD-style but old (UNVERIFIED, search snippet). `@wasm-audio-decoders/ogg-vorbis` is decode only (snippet). Browser audio element can already decode Vorbis for preview.
- **Recommendation**: the browser works in WAV/Float32 (`AudioBuffer`) and uploads WAV (or a small JSON edit recipe); the server renders and encodes. This keeps one deterministic encoder, one licence story and lets AI/automatic sound design (no browser) use the same path. Effort S-M.

## 3. Editing UI libraries

| lib | licence | fit |
|---|---|---|
| wavesurfer.js | BSD-3-Clause; v8; plugins Regions, Timeline, Minimap, Envelope, Spectrogram (VERIFIED https://github.com/katspaugh/wavesurfer.js) | waveform display + trim regions + fade envelope UI. Its own docs say it does not process audio. Use as the **view**. |
| Tone.js | MIT, active, `Tone.Offline`, Reverb, Filter, FeedbackDelay, Distortion, pitch shifting (VERIFIED https://github.com/Tonejs/Tone.js) | good for offline rendering of a graph in the browser; heavy (~hundreds KB); optional. |
| howler.js | MIT, 25k stars, playback only (VERIFIED https://github.com/goldfire/howler.js) | not needed; Web Audio suffices. |
| Web Audio (`OfflineAudioContext`) | browser standard | gain, fade (gain ramps), `playbackRate` pitch+speed, `BiquadFilter`, `Convolver` reverb, `DynamicsCompressor`; enough for MVP with no library. |
| audiobuffer-to-wav, jsfx | UNVERIFIED (small MIT-ish utilities) | WAV writer is ~40 lines; write our own. |

Pitch without speed change needs a phase vocoder; skip in MVP (resample pitch only, which is what Minecraft's own `pitch` does).

**Non-destructive recipe** (stored as JSON, source files immutable):
```
{ sourceId, trim:{start,end}, fadeIn, fadeOut, gainDb, pitchSemitones,
  eq:[{type,freq,gain,q}], reverb:{irId,mix}, normalizePeakDb }
```
Layers each carry a recipe, a start offset and a gain; render = sum, then limiter, then mono downmix, then Vorbis. The browser previews via `OfflineAudioContext`; the server re-renders the same recipe for the shipped file. Caveat: browser and server renders must match, so the server is authoritative and the UI preview is approximate. Keep recipe version numbers.

## 4. Automatic sound design

**(a) Procedural synthesis presets** (extend `lib/cyrus/sfx.ts`, which today is UI-only per G-gaps): per sound class a deterministic generator seeded from the spec: growl (saw + formant filters + noise), wail (FM sine glide + vibrato + reverb), hit (noise burst + low sine thump), step (filtered noise click), zap, magic chime. Cheap, free, original, no provenance risk, but sounds synthetic. Effort M. Run it in Node via an offline renderer (the code uses Web Audio; port to a pure-DSP render function; UNVERIFIED how sfx.ts is structured).

**(b) Layering from the owner's 514 SFX library**: filename-prefix tags (Whoosh/Hit/Explosion/Door/Alert...) become a tag index; the LLM picks 1-3 layers per event by tag plus pitch/gain/filters (e.g. low-pass + -7 semitones on an Explosion for a death boom). Pitch-shifting, layering and filtering turns 514 into thousands of distinct sounds. It is the best quality/cost path. Needs the library on the build host, a tag index (can be generated from filenames), and the owner's customer licence. Layer-per-event limit and a "no raw unchanged file" rule are optional policy. Effort M.

**(c) AI generation**:
- Stable Audio Open 1.0: open weights, up to 47 s stereo 44.1 kHz, trained on Freesound CC0/CC-BY/CC-Sampling+ and FMA, "better for sound effects than music", needs a CUDA GPU (VERIFIED https://huggingface.co/stabilityai/stable-audio-open-1.0). Licence: Stability Community License - free commercial use under USD 1M annual revenue, **registration required**, no using outputs to train foundation models, "Powered by Stability AI" attribution where distributed (VERIFIED https://stability.ai/community-license-agreement). Needs a GPU box Nxeon may not have; no cost per call otherwise. Risky for attribution and registration.
- ElevenLabs Sound Effects API: 0.1-30 s, loopable, MP3 or 48 kHz WAV (non-looping), 40 credits/s when duration specified (VERIFIED https://elevenlabs.io/docs/overview/capabilities/sound-effects). Commercial use only on paid plans, no competing-product use (UNVERIFIED, from third-party search snippets; read the actual terms before use). Hosted, sub-minute latency (UNVERIFIED), per-second cost, and it adds a third-party dependency (brand rule: never name it to customers).
- AudioLDM-class (AudioLDM2 weights are non-commercial CC BY-NC as I recall, UNVERIFIED) - avoid unless checked. Not opened due to the page cap; AudioGen/AudioCraft are CC-BY-NC for weights (UNVERIFIED), also avoid.
- Judgment: AI output is useful for textures-of-sound (creature vocals, ambient beds) where layering the owner library falls short; make it a **later** add-on behind a provider interface, every output entering the ledger.

## 5. SoundSpec proposal

```
SoundSpec { version, profile:"minecraft-java", namespace,
  events:[{ key:"banshee.wail", category:"hostile",
     role:"ambient"|"hurt"|"death"|"step"|"attack"|"special"|"spawn",
     variants:[{ weight, volume, pitch, layers:[Layer], mono:true, lengthMs, tailMs }],
     subtitle, stream:false, attenuationDistance }] }
Layer { source:{kind:"library"|"synth"|"ai"|"upload", id|preset|prompt|provenanceId},
        offsetMs, gainDb, recipe:EditRecipe }
```
The compiler turns this into `sounds.json` + Ogg files + lang subtitles + a plugin event table (`role`->key), so Java code never contains file paths. LLM output is schema-validated (event count, length, tag ids must exist, no 'minecraft:' keys unless override is chosen).

**Provenance/licence ledger** (row per layer per render): `{ assetId, kind, licence ("owner-original"|"cc0"|"cc-by"|"generated-<provider>"|"user-upload"), sourceRef (library filename+hash / model+version+prompt hash / upload hash), attributionRequired, commercialOk, customerLicenceVersion, recipeHash, outputHash, userId, createdAt }`. Gate: NxLabs publication refuses public pages when any layer is user-upload without attestation or `attributionRequired` unmet (hook into `public-gate.ts`, per G-gaps). Owner library rows are marked with the licence version once the owner writes it.

## 6. MVP vs later (S <= 2 days, M ~ 1 wk, L multi-week)

MVP: SoundSpec + compiler (sounds.json, lang, ffmpeg encode, pack integration) M; library tag index + LLM layer picking + render service (server DSP: trim/fade/gain/pitch/lowpass/layer) M-L; gate/ledger table S-M; Studio UI with wavesurfer.js (Regions/Envelope) + OfflineAudioContext preview + variant list M; plugin glue (`playSound` helper, silence base mob) S. Later: synthesis presets M, reverb IRs S, pitch-preserving stretch M, AI provider interface L, community sound sharing L.
Build: SoundSpec, compiler, recipe renderer, ledger. Adopt: ffmpeg/libvorbis, wavesurfer.js, Web Audio. Avoid: howler (not needed), NC-licensed models, sl-web-ogg as primary encoder.

Risks: GPL ffmpeg build if redistributed; browser/server render mismatch; customer ownership terms for the owner's library not yet written; vanilla event names change per version.
Could not determine: mob sound lengths from real vanilla files, exact Paper `playSound` overloads on 26.x, ElevenLabs/Stability output terms beyond snippets, quality of any AI model by listening.

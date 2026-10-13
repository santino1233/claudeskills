# Cyrus sound library catalog (owner review)

Generated 2026-10-10 by `scripts/cyrus/sound-manifest.ts` from the metadata of the owner's library (514 MP3s, board upload `819080d91d471a0eceeab422.zip`). Taxonomy rules: `lib/cyrus/sound/taxonomy.json` (data); classifier: `lib/cyrus/sound/classify.ts`; manifest: `lib/cyrus/sound/library.manifest.json`. No audio is in git; the files live only on node-2 under `/tank/nxeon-build/tmp/sound-library/files`.

**Licence:** the zip contains `_Essential Sound Effects Bundle License.pdf` naming Excelerator.tech as licensor (non-transferable; modifying and using in games is allowed; distributing or making the files available, alone or in another bundle/package, is prohibited). Every manifest row carries `provenance: owner-provided (2026-10-10)` and `licenceStatus: unverified: owner to document source per file group`. Customer builds do not get the library until the owner confirms (`CYRUS_SOUND_LIBRARY_CLEARED=1`).

## Categories

| Category | Files | Examples |
|---|---|---|
| Weapons (`weapons`) | 20 | `Gun - 12ga - Pump 2.MP3`, `Gun - 12ga - Pump.MP3`, `Gun - Loading.MP3`, `Gun - Racking.MP3`, `Gunshot - 10.MP3` |
| Doors & Mechanisms (`doors_mechanisms`) | 51 | `Camera 1.MP3`, `Camera 2.MP3`, `Camera 3.MP3`, `Camera 4.MP3`, `Camera 5.MP3` |
| Creatures & Voices (`creatures_voices`) | 79 | `Animals - Cow Moo 1.MP3`, `Animals - Cow Moo 2.mp3`, `Animals - Dog Bark - Big - Single.MP3`, `Animals - Dog Bark - Small - Single.MP3`, `Animals - Dog Barking 1.MP3` |
| Crowd & Reactions (`crowd_reactions`) | 17 | `Applause - Large Crowd 1.MP3`, `Applause - Large Crowd 2.MP3`, `Applause - Small Group 1.MP3`, `Applause - Small Group 2.MP3`, `Applause - Small Group 3.MP3` |
| Music & Stingers (`music_stingers`) | 77 | `Braam 1.mp3`, `Braam 2.mp3`, `Celebratory Jingle 1.MP3`, `Celebratory Jingle 2.MP3`, `Celebratory Jingle 3.MP3` |
| Impacts & Destruction (`impacts_destruction`) | 46 | `Crash 1.MP3`, `Crash 2.MP3`, `Crash 3.MP3`, `Crash 4.MP3`, `Crumple.MP3` |
| Movement (`movement`) | 56 | `Rewind 1.MP3`, `Rewind 2.MP3`, `Rewind 3.MP3`, `Sonic Launch.MP3.mp3`, `Sonic Launch.MP3` |
| UI & Alerts (`ui_alerts`) | 98 | `Air Horn - Short Burst.MP3`, `Air Horn - Short Low.MP3`, `Alert - Chime.MP3`, `Alert - Digital.MP3`, `Alert - Elevator.MP3` |
| Magic & Energy (`magic_energy`) | 9 | `Dizzy.MP3`, `Electrified.MP3`, `Shimmer - Bright.MP3`, `Shimmer - Creepy.MP3`, `Shimmer - Harsh.MP3` |
| Environment & Ambience (`environment_ambience`) | 61 | `Air blowing.MP3`, `Ambient - Background - People in an open room.MP3`, `Ambient - City Street 1.MP3`, `Ambient - City Street 2.MP3`, `Ambient - City Street 3.MP3` |

## Use cases (multi-valued)

| Use case | Files | Examples |
|---|---|---|
| `weapon_fire` | 20 | `Gunshot - 10.MP3`, `Gunshot - 9mm - Single 1.MP3`, `Gunshot - 9mm - Single 2.MP3`, `Gunshot - 9mm - Single 3.MP3`, `Gunshot - 9mm - Single 4.MP3` |
| `weapon_reload` | 6 | `Gun - 12ga - Pump 2.MP3`, `Gun - 12ga - Pump.MP3`, `Gun - Loading.MP3`, `Gun - Racking.MP3`, `Gunshot - Pump and Fire.MP3` |
| `weapon_impact` | 28 | `Drum Hit - Cymbal - Single.MP3`, `Drum Hit - Single.MP3`, `Explosion - Launch Hit Sizzle.MP3`, `Hit - Double.MP3`, `Hit - Dull.MP3` |
| `melee` | 55 | `Dramatic Buildup Whip - 1.MP3`, `Dramatic Buildup Whip - 2.MP3`, `Dramatic Buildup Whip - 3.MP3`, `Drop - Whip.MP3`, `Slap.MP3` |
| `mob_ambient` | 37 | `Animals - Cow Moo 1.MP3`, `Animals - Cow Moo 2.mp3`, `Animals - Dog Bark - Big - Single.MP3`, `Animals - Dog Bark - Small - Single.MP3`, `Animals - Dog Barking 1.MP3` |
| `mob_hurt` | 19 | `Disappointed Groan.MP3`, `Gasp - Female 1.MP3`, `Gasp - Female 2.MP3`, `Gasp - Female 3.MP3`, `Gasp - Male 1.MP3` |
| `mob_death` | 18 | `Crowd - Disappointed Groans.MP3`, `Deflating.MP3`, `Disappointed 1.MP3`, `Disappointed 2.MP3`, `Disappointed 3.MP3` |
| `mob_attack` | 7 | `Animals - Dog Barking 1.MP3`, `Animals - Dog Barking 2.MP3`, `Animals - Dog Barking 3.MP3`, `Growl.MP3`, `Monster Exhale - Short.mp3` |
| `mob_step` | 9 | `Combo - bell creak drop.MP3`, `Creak - Short.MP3`, `Floor Creak - Low.MP3`, `Footsteps.MP3`, `Footsteps - Creepy.MP3` |
| `ability_cast` | 71 | `Electrified.MP3`, `Explosion - Launch Hit Sizzle.MP3`, `Harp Glissando.MP3`, `Harp Glissando - Crisp Echo.MP3`, `Harp Glissando - Horror.MP3` |
| `magic` | 22 | `Alert - Chime.MP3`, `Alert - Sharp Twinkle.MP3`, `Chime - Single.MP3`, `Chimes - Hi Lo - Ding Dong.MP3`, `Chimes - Melodic.MP3` |
| `boss_event` | 45 | `Braam 1.mp3`, `Braam 2.mp3`, `Dramatic Buildup 1.MP3`, `Dramatic Buildup 2.MP3`, `Dramatic Buildup 3.MP3` |
| `ui_notification` | 95 | `Air Horn - Short Burst.MP3`, `Air Horn - Short Low.MP3`, `Alert - Chime.MP3`, `Alert - Digital.MP3`, `Alert - Elevator.MP3` |
| `pickup_reward` | 37 | `Alert - Positive - Correct.MP3`, `Alert - Positive - Retro Game.MP3`, `Alert - Positive - Single Tone.MP3`, `Alert - Sharp Twinkle.MP3`, `Applause - Large Crowd 1.MP3` |
| `block_interaction` | 48 | `Camera 1.MP3`, `Camera 2.MP3`, `Camera 3.MP3`, `Camera 4.MP3`, `Camera 5.MP3` |
| `door_mechanism` | 33 | `Car Door - Open Close.MP3`, `Combo - bell creak drop.MP3`, `Creak - Short.MP3`, `Door - Closing 1.MP3`, `Door - Closing 2.MP3` |
| `ambience_world` | 90 | `Air blowing.MP3`, `Ambient - Background - People in an open room.MP3`, `Ambient - City Street 1.MP3`, `Ambient - City Street 2.MP3`, `Ambient - City Street 3.MP3` |
| `weather` | 9 | `Rain 1.MP3`, `Rain 2.MP3`, `Thunderstorm 1.MP3`, `Thunderstorm 2.MP3`, `Thunderstorm 3.MP3` |
| `explosion` | 15 | `Braam 1.mp3`, `Braam 2.mp3`, `Explosion 1.MP3`, `Explosion 2.MP3`, `Explosion 3.MP3` |

## Descriptors (measured on node-2)

- **durationClass**: short 305, stinger 53, medium 140, long 16
- **intensity**: medium 226, loud 149, soft 139
- **pitchBand**: high 188, mid 197, low 129
- **character**: sustained 401, transient 113
- **loopable** (heuristic: start/end level within 4 dB, >= 1 s, never verified by ear): 3
- **channels**: mono 0, stereo 514 (every shipped sound is downmixed to mono)
- **sample rates**: 44.1 kHz 455, 48 kHz 59

## Unclassified (please review)

- Category `other`: 0 (none)
- No use case: 34
  - `DJ Record Scratch.MP3` (Music & Stingers): no use-case keyword in "DJ Record Scratch"
  - `DJ Record Scratching Turntables.MP3` (Music & Stingers): no use-case keyword in "DJ Record Scratching Turntables"
  - `Fly By - Low.mp3` (Creatures & Voices): no use-case keyword in "Fly By - Low"
  - `Fly By - Wobbly.MP3` (Creatures & Voices): no use-case keyword in "Fly By - Wobbly"
  - `Metal Strings - Two Tone.MP3` (Music & Stingers): no use-case keyword in "Metal Strings - Two Tone"
  - `Music - Rave Beat - Muffled.MP3` (Music & Stingers): no use-case keyword in "Music - Rave Beat - Muffled"
  - `Music - Upbeat Classical Waltz 1.MP3` (Music & Stingers): no use-case keyword in "Music - Upbeat Classical Waltz 1"
  - `Music - Upbeat Classical Waltz 2.MP3` (Music & Stingers): no use-case keyword in "Music - Upbeat Classical Waltz 2"
  - `Music - Upbeat Classical Waltz 3.MP3` (Music & Stingers): no use-case keyword in "Music - Upbeat Classical Waltz 3"
  - `Musical 3 Notes - Low.MP3` (Music & Stingers): no use-case keyword in "Musical 3 Notes - Low"
  - `Musical - Hip Hop Beat.mp3` (Music & Stingers): no use-case keyword in "Musical - Hip Hop Beat"
  - `Musical - Rock Beat 1.mp3` (Music & Stingers): no use-case keyword in "Musical - Rock Beat 1"
  - `Musical - Rock Beat 2.mp3` (Music & Stingers): no use-case keyword in "Musical - Rock Beat 2"
  - `Organ Single.MP3` (Music & Stingers): no use-case keyword in "Organ Single"
  - `Piano.MP3` (Music & Stingers): no use-case keyword in "Piano"
  - `Piano - Bright - Single Tone.MP3` (Music & Stingers): no use-case keyword in "Piano - Bright - Single Tone"
  - `Pluck.MP3` (Music & Stingers): no use-case keyword in "Pluck"
  - `Record Scratch 1.MP3` (Music & Stingers): no use-case keyword in "Record Scratch 1"
  - `Record Scratch 2.MP3.mp3` (Music & Stingers): no use-case keyword in "Record Scratch 2"
  - `Record Scratch 2.MP3` (Music & Stingers): no use-case keyword in "Record Scratch 2"
  - `Record Scratch Short.MP3` (Music & Stingers): no use-case keyword in "Record Scratch Short"
  - `Rimshot - Bad Joke 2.MP3` (Music & Stingers): no use-case keyword in "Rimshot - Bad Joke 2"
  - `Rimshot - Bad Joke 3.MP3` (Music & Stingers): no use-case keyword in "Rimshot - Bad Joke 3"
  - `Rimshot - Bad Joke.MP3` (Music & Stingers): no use-case keyword in "Rimshot - Bad Joke"
  - `Sad Trombone 1.MP3` (Music & Stingers): no use-case keyword in "Sad Trombone 1"
  - `Sad Trombone 2.MP3` (Music & Stingers): no use-case keyword in "Sad Trombone 2"
  - `Sad Trombone 3.MP3` (Music & Stingers): no use-case keyword in "Sad Trombone 3"
  - `Sad Trombone - Warped Echo.MP3` (Music & Stingers): no use-case keyword in "Sad Trombone - Warped Echo"
  - `String - Single.MP3` (Music & Stingers): no use-case keyword in "String - Single"
  - `Strings - Short.MP3` (Music & Stingers): no use-case keyword in "Strings - Short"
  - `Strings - Two Tone - Hi Lo.MP3` (Music & Stingers): no use-case keyword in "Strings - Two Tone - Hi Lo"
  - `Twang 1.mp3` (Music & Stingers): no use-case keyword in "Twang 1"
  - `Twang 2.mp3` (Music & Stingers): no use-case keyword in "Twang 2"
  - `Twang 3.mp3` (Music & Stingers): no use-case keyword in "Twang 3"

## Naming patterns found

- Most names are `<Prefix> - <Detail> - <Detail> <n>.MP3` (the prefix is the sound kind: Whoosh, Door, Gunshot, Explosion...); some have no ` - ` and a trailing number (`Crash 1.MP3`).
- 11 file(s) have a doubled extension (`.MP3.mp3`); extensions mix `.MP3` and `.mp3`; some names have double spaces or a trailing space before the extension.
- Plural/singular and spelling variants are folded by the synonym table (Gunshots -> gunshot, Swoosh/Swish -> whoosh, Clapping -> applause, Crickets -> cricket).
- 163 distinct prefixes; the most common: Whoosh (34), Door (15), Alert (13), Animals (12), Explosion (12), Ambient (11), Digital Glitch (10), Gunshot (10), Laughter (10), Water (10), Crowd (8), Impact Hit (7), Scream (7), Swoosh (7), Typing (7).

## Decisions in the taxonomy

- Two categories were added to the eight requested: **Music & Stingers** (dramatic cues, stingers, jingles, instruments, record scratches) and **Magic & Energy** (shimmer, sparkle, zap, glissando), so these do not land in Other.
- Category priority follows the order in taxonomy.json (Weapons first), checked on the file-name prefix first, then on the rest of the name: `Car Door` is Doors & Mechanisms, `Train Whistle` is UI & Alerts (whistle), `Footsteps - Water` is Creatures & Voices.
- Vehicles and machinery sit in Environment & Ambience / Doors & Mechanisms (no vehicle category was requested).


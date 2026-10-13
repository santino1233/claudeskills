---
name: baz
description: Create professional motion graphics and videos from the terminal. AI-powered composition with multi-track layering, choreography, voiceovers, and Lambda rendering. Gated 5-phase workflow ensures quality.
metadata:
  openclaw:
    requires:
      bins:
        - node
        - baz
    primaryEnv: BAZ_API_KEY
    envVars:
      - name: BAZ_API_KEY
        required: false
        description: Optional API key override. The CLI can also use its saved config or register a new account.
    install:
      - id: node
        kind: node
        package: bazaar.it
        bins:
          - baz
        label: Install Bazaar CLI (npm)
    homepage: https://baz.studio
    emoji: "\U0001F3AC"
---

# baz CLI — Mandatory Video Generation Workflow

Use this skill when the user wants to create, edit, or export videos using the Bazaar CLI (`baz`).

**This is a GATED workflow.** You MUST complete each phase in order. Do NOT skip phases. Do NOT declare "done" until the completion checklist at the bottom passes.

---

## Getting Started (New Agents)

Install the published CLI first. Then register without opening the web app:

```bash
# 1. Discover what Bazaar can do.
curl https://baz.studio/api/v1/capabilities

# 2. Install the CLI and create an account. The CLI stores the API key.
npm install -g bazaar.it@latest
baz auth register --email <account-email> --name "My Agent"

# 3. Switch to compact machine output and install public video skills.
export BAZ_AGENT=1
baz agent init --skills all-free --agent auto

# 4. Check live balance and pricing.
baz balance --pricing --json
```

**Balance starts at $0.** Run `baz balance topup 5` to get the minimum $5 Stripe checkout URL. A human must approve that payment. After checkout, run `baz balance --json` and retry the same command. Use `baz prompt --budget <dollars>` only when the user explicitly asks for a cap. A low cap is a stop condition and can create a partial video.

**Shortcut:** If your human creates an account at baz.studio, ask them to provide an API key, then run `baz auth login <your-api-key>` instead of registering. New accounts start at $0 — fund via the top-up flow above before the first paid operation.

Already have an API key? Skip to Phase 1.

### One-line cold-agent requests

When the user gives only a request such as `make a launch video for X`, do not stop to ask for creative preferences that can be inferred safely.

1. Identify `X` from the user's text and any public URL they supplied.
2. Default to a 15-second landscape product launch video unless the request implies another format or duration.
3. State the assumptions in the run context. Infer a restrained brand system when no assets or brand rules are available.
4. Add one `goal`, one `requirement`, one `brand`, and one `instructions` context entry before generation.
5. Run the normal generate, preview, review, validate, repair, and export gates below.
6. Ask the user only when identity, rights, payment, or a destructive action needs human authority.

The one-line request reduces user input. It does not remove the quality gates.

---

## When to Use

- User asks to create, edit, or export videos via CLI
- User wants to automate video generation
- User mentions "baz", "bazaar CLI", or "video generation from terminal"

## Report CLI Feedback

Submit one feedback item when baz behavior differs from its documented contract, an error gives no actionable recovery, or a required capability is missing:

```bash
baz feedback "Expected timing to remain unchanged, but the scene moved" \
  --kind unexpected-behavior \
  --command "baz scenes set-code <scene-id> --file ./scene.tsx"
```

Use `--kind bug`, `friction`, `unexpected-behavior`, `missing-capability`, `docs`, or `idea`. Do not include API keys, credentials, private file contents, or other secrets. The command sends the explicit message, feedback category, displayed command, CLI version, agent type, and active project ID to the baz.studio team. Do not submit expected validation failures or duplicate feedback.

## When to Use `baz prompt` vs Spar

- **Direct `baz prompt`** — Scene creation, edits, full agent orchestration
- **`baz prompt --spar`** — Planning-only conversation (no timeline mutations)

### Trend-to-Skill Factory Override

When `.agents/skills/trend-to-skill/SKILL.md` is active, never use `baz prompt` or prompt-driven repair, even for brand-new scenes. Codex or Claude must author the TSX locally, create scenes with `baz scenes create --file ...`, and repair them with `baz scenes set-code`. In that workflow, Bazaar is the persistence/review/export control plane, not the code generator.

---

## Phase 1: Context (REQUIRED — do NOT skip)

You MUST set project context BEFORE generating any scenes. This gives the composition agent the information it needs to produce correct output on the first try.

### Minimum context required:
1. **Goal** — What is this video for? Who is the audience? What should they feel/do?
2. **Requirements** — Specific, verifiable things the video must contain
3. **Brand** — Colors, fonts, logo placement, visual style
4. **Director's treatment** — The non-generic creative idea: core metaphor, point of view, pacing shape, visual grammar, and anti-patterns

**Shippable quality warning:** "World-class", "premium", "Bloomberg-grade", "cinematic", "editorial", and "not generic" are aspirations, not direction. Do not rely on those words as the prompt. Convert them into a concrete treatment first:

- **Core metaphor:** receipt, dossier, pressure gauge, courtroom exhibit, operating-room monitor, teardown, map, timeline, market microstructure, etc.
- **Point of view:** the one sentence the video argues, not just the topic it covers.
- **Visual grammar:** what kinds of frames repeat, how data is represented, what is deliberately avoided.
- **Pacing shape:** where tension rises, where proof lands, where the ending resolves.
- **Anti-patterns:** generic KPI cards, interchangeable stock chart panels, decorative data, one-track slideshow pacing, vague finance filler.

**Parallel sessions:** If multiple agents share the same machine, do NOT use `baz project use` — it writes to a shared config file and agents will stomp each other. Instead, set the env var for your session:
```bash
export BAZ_PROJECT_ID=<id>   # Session-scoped, no file contention
```

```bash
# Create or select project
baz project create --name "Descriptive Name - Date/Purpose" --json
# OR (single-agent only — see parallel sessions note above)
baz project use <id>

# Set goal (be specific — audience, purpose, desired outcome)
baz context add "Create 45-60 second feature announcement for [Product]. \
Audience: [who]. Key value: [what they get]." --label "goal"

# Add requirements (each one should be independently verifiable)
baz context add "Show [specific feature interaction]" --label "requirement"
baz context add "Include CTA: '[specific text]'" --label "requirement"
baz context add "Total duration: [range]" --label "requirement"

# Set brand guidelines
baz context add "Brand: [Name]. Primary [hex], accent [hex]. Font: [name]. \
[Logo placement]. [Visual style notes]." --label "brand"

baz context add "DIRECTOR TREATMENT: [specific visual thesis]. \
Core metaphor: [not a style adjective]. Point of view: [argument]. \
Visual grammar: [repeatable frame system]. Pacing: [tension/proof/resolution]. \
Avoid: generic KPI cards, interchangeable chart panels, decorative data." --label "instructions"
```

### Verify context is set:
```bash
baz context list --json
```

**Gate:** Do NOT proceed to Phase 2 until `baz context list` shows at least one goal, one requirement, one brand entry, and one director-treatment/instructions entry.

---

## Phase 2: Generate

Now prompt the agent to create scenes. You can use one big prompt or multiple scene-by-scene prompts.

```bash
# Option A: One comprehensive prompt
baz prompt "Create a video with: [scene 1 description], [scene 2], ..." --stream-json

# Option B: Scene-by-scene (more control)
baz prompt "Scene 1 (5s): Dark gradient intro, logo top-left, title slides up" --stream-json
baz prompt "Scene 2 (7s): Problem statement with mock UI..." --stream-json
baz prompt "Scene 3 (18s): Feature walkthrough..." --stream-json
```

Tips:
- Include duration in each prompt
- Be specific about animations, colors, layout
- Reference brand context set in Phase 1

### Choreography (REQUIRED for 3+ scene videos)

For videos with 3 or more scenes, plan choreography BEFORE generating. This prevents the "lockstep slideshow" pattern where all layers swap at the same frame boundary.

#### Actor Planning Template

Before prompting, plan your actors:

| Actor | Track | Lifetime | Role |
|-------|-------|----------|------|
| Background | 0 | Full duration | Evolving gradient, particles |
| Hero | 1 | 60-80% | Main UI, enters, demotes to corner, returns |
| Supporting | 1-2 | 20-40% | Cards/charts, appear during hero demotion |
| Text | 2+ | 10-30% | Headlines, arrive at beat points, explicit exits |

#### 5 Prompt Enrichment Rules

1. **Every content prompt includes exit instructions** (exempt: persistent backgrounds, final CTA)
2. **Prefer ONE background** on Track 0 for the full video duration
3. **Every overlay prompt includes position and size** — scenes that share screen time must not share screen space
4. **Specify spring animation** for hero elements (`spring() for hero entrance`)
5. **Include energy level hints** in prompts ("high energy entrance", "calm sustained section")

#### Landscape Occupancy Rule (REQUIRED for 16:9)

If the project is landscape, do not let the scene collapse into a small claim floating in a giant matte.

- Main proof beats should usually use roughly `60-80%` of the frame width, or resolve as a deliberate two-zone composition
- Prefer wide proof rails, claim-left / proof-right layouts, split fields, and full-width chart bands
- Tiny centered headlines, short decorative lines, or small chart islands are only acceptable as very brief punctuation beats
- If a landscape frame feels empty, fix scale and composition first before adding more text

#### GOOD Example — context injection + one natural prompt:
```bash
baz context add "CHOREOGRAPHY: Every overlay scene must specify its position and size. \
  Use spring() for hero elements. Every non-final scene must have exit animations. \
  Prefer one continuous background. In landscape, main proof beats should occupy roughly 60-80% of width or resolve as a wide split-field layout — avoid tiny centered claim clusters." --label "instructions"

baz prompt "Create a 15-second product demo: dark theme intro with logo, \
  feature showcase with 3 cards, area chart showing growth, and a CTA. \
  Brand: #6366f1 purple, #10b981 green, Inter font." --stream-json
```

ONE natural prompt. The composition agent handles decomposition into tracks + spatial layout internally based on choreography context.

---

## Phase 3: Preview, Review & Validate (REQUIRED — NEVER skip)

After generation, you MUST visually inspect the output and run structural validation. This is not optional.

### Step 1: Preview
```bash
baz preview --frames 0,150,300 --json
```

Use preview for visual and semantic checks:
- Is the logo actually visible?
- Is the CTA on screen?
- Does the style feel on-brand?
- Are screenshots being used as reference/recreated UI or charts instead of raw webpage collage?
- Are self-claims attributed with small source labels/footers rather than ugly headline copy like "Ramp says..."?
- What is the specific visual thesis only this video has?
- Could these scenes be reused for any other topic with only text swaps? If yes, fail it.
- Are charts and diagrams semantically tied to the story, or just decorative finance motion?
- Does the reel feel directed, with a shape and point of view, or like a one-prompt AI slideshow?

**Do not accept generic AI slop.** A video can pass validation and still be a 4/10. If the preview reads as generic KPI cards, stock editorial styling, or interchangeable finance graphics, mark it unshippable and return to Phase 1/2 with a stronger treatment. Do not declare done.

**Do not accept static infographics.** A still dashboard frame with one glowing line, one receipt/card, and small labels is not a motion-graphics video. Audio timing, word anchors, and a compiled export do not make it shippable. If most preview frames show the same layout with only tiny changes, fail the video as 0-3/10. Require visible choreography: changing composition, object transformations, depth, camera/scale moves, foreground/background interaction, kinetic evidence reveals, and meaningful motion throughout the run.

### Step 2: Review
```bash
baz review --summary --json
```

Read the project summary. Compare scenes, timing, and context against what Phase 1 asked for.

### Step 3: Validate
```bash
baz project validate --json
```

This is the authoritative machine check for compilation errors, invalid durations, overlaps, and other structural issues.

### Optional: Deterministic Verify
```bash
baz verify --criteria "duration <= 60s,scenes >= 5,portrait" --json
```

`baz verify` is now only for deterministic checks like duration, scene count, and format. Do NOT use it for visual/content/style questions.

**Gate:** If preview/review reveal problems, or `baz project validate` returns errors, or deterministic `baz verify` fails, you MUST proceed to Phase 4. Do NOT export. Do NOT declare done.

---

## Phase 4: Iterate (REQUIRED if Phase 3 fails)

Fix the issues. Then re-preview, re-review, and re-validate.

```
LOOP:
  1. Read the visual/content/structural issues from Phase 3
  2. Fix with: baz prompt "Fix: [specific issue]" --stream-json
  3. Re-run: baz preview --frames 0,150,300 --json
  4. Re-run: baz review --summary --json
  5. Re-run: baz project validate --json
  6. Optional: baz verify --criteria "duration <= 60s,scenes >= 5,portrait" --json
  7. If issues remain → GOTO 1
  8. If clean enough → proceed to Phase 5
```

Do NOT exit this loop until the video looks right and structural validation passes.

### Deterministic Edits (skip the AI, save tokens)

When you know exactly what code change to make — fixing a color, adjusting timing, replacing text, swapping an emoji for an SVG — use `set-code` instead of `baz prompt`. This bypasses the AI agent entirely: you write the code, CLI pushes it to the server. No tokens spent, no prompt randomness.

```bash
# 1. Read current scene code
baz scenes code <scene-id> --output /tmp/scene.tsx

# 2. Edit the file locally (your edits, deterministic)

# 3. Push it back
baz scenes set-code <scene-id> --file /tmp/scene.tsx
```

**When to use `set-code` vs `baz prompt`:**
- `set-code` — You can see the exact code change needed (wrong color, broken animation, timing fix, text update)
- `baz prompt` — You need the AI to design something new or make a creative decision

After a batch of edits, run `baz review --json` to sanity-check the composition before asking the user.

---

## Phase 5: Export (only if requested)

Only export if the user explicitly asked for a rendered video AND Phase 3/4 passed.

```bash
baz export start --wait --json
```

---

## Command Quick Reference

| Command | Purpose |
|---------|---------|
| `baz project create --name "..." --json` | Create new project |
| `baz project use <id>` | Set active project (single-agent only) |
| `export BAZ_PROJECT_ID=<id>` | Set active project (parallel-safe) |
| `baz context add "..." --label "goal"` | Set project goal |
| `baz context add "..." --label "requirement"` | Add verifiable requirement |
| `baz context add "..." --label "brand"` | Set brand guidelines |
| `baz context list --json` | View all context entries |
| `baz prompt "..." --stream-json` | Generate or edit scenes |
| `baz prompt "..." --spar` | Planning-only conversation (no edits) |
| `baz preview --frames 0,150,300 --json` | Render visual spot-check frames |
| `baz review --json` | Get full project state for review |
| `baz project validate --json` | Validate structural timeline health |
| `baz verify --criteria "..." --json` | Optional deterministic checks only |
| `baz scenes list --json` | List all scenes |
| `baz scenes code <id> --output file.tsx` | Read scene TSX code to file |
| `baz scenes set-code <id> --file file.tsx` | Replace scene code (deterministic, no AI) |
| `baz scenes positions --updates-json '...'` | Preview timeline position changes (dry-run) |
| `baz scenes positions --updates-json '...' --apply` | Apply timeline position changes |
| `baz export start --wait --json` | Render final video |

## Error Handling

| Category | Action |
|----------|--------|
| `transient` | Retry with backoff (wait `retry_after` seconds) |
| `validation` | Fix input, do not retry same request |
| `auth` | Check API key with `baz auth status` |
| `fatal` | Stop and report to user |

---

## Completion Checklist

You are NOT done until ALL of these are true:

- [ ] Phase 1: `baz context list` shows goal + requirements + brand + director treatment/instructions
- [ ] Phase 2: Scenes generated via `baz prompt`, except trend-to-skill factory runs, which require manual TSX via `baz scenes create`
- [ ] Phase 3: `baz preview --frames ...`, `baz review --summary --json`, and `baz project validate --json` run
- [ ] Phase 4: No blocking structural errors remain; optional deterministic `baz verify` passes if used
- [ ] Phase 5: Export started (only if user requested it)
- [ ] Visual quality: no raw screenshot filler, no random color palette, no attribution legalese in hero/body copy

**If you skipped preview/review/validate, you are not done. Go back and run them.**

---

## External Endpoints

| URL | Method | Data Sent | Purpose |
|-----|--------|-----------|---------|
| `baz.studio/api/v1/capabilities` | GET | None | Discover available tools |
| `baz.studio/api/v1/register` | POST | email, name | Create agent account |
| `baz.studio/api/v1/pricing` | GET | None | View operation costs |
| `baz.studio/api/v1/estimate` | POST | operation keys + quantities | Pre-execution cost estimate |
| `baz.studio/api/v1/top-up` | POST | amount in cents | Get Stripe checkout URL |
| `baz.studio/api/generate-stream` | POST | prompt, projectId | Generate video scenes (SSE) |
| `baz.studio/api/trpc/*` | POST | varies | Project CRUD, scene management |

## Security & Privacy

- **Authentication**: All non-discovery endpoints require `x-api-key` header
- **Data sent**: Your prompts, project metadata, and scene code are sent to Bazaar servers for AI processing
- **Data stored**: Projects, scenes, and generated assets are stored on Bazaar's infrastructure (Neon DB + Cloudflare R2)
- **No local file access**: This skill only uses the `baz` CLI binary — it does not read or modify local files beyond CLI config at `~/.bazaar/config.json`
- **Balance**: Operations consume dollar balance. Check `baz balance` before large jobs, or `baz balance --pricing` to see what is still free vs paid
- **Exports**: Rendered videos are stored on Bazaar CDN and accessible via URL

## Web UI Access

Your human can also edit the project directly in the browser at:
`https://baz.studio/projects/<project-id>/generate`

After creating a project, share this link so they can preview scenes, tweak code, or make manual edits alongside your CLI workflow.
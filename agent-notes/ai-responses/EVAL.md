# Eval results: old vs new responder (2026-10-06)

## Setup

- Harness: `scripts/ai-eval/run.ts`, 35 cases.
- Runs as an anonymous visitor, in dry run.
- Model: the platform's configured key and the admin model (claude-haiku-4-5). The judge is also Haiku.
- Raw JSON is in `eval/`.

## Results

Both variants ran at the same time. The last 5 to 7 cases degraded in both, and these were excluded. The comparison below uses the **28 cases both variants answered**.

| Metric | Old (main) | New (commit d96c4a9 + tests) |
|---|---|---|
| Rule pass (facts + format) | 16/28 (57%) | 22/28 (79%). This is 23/28 with the gcash case-regex bug fixed. |
| Fact failures (must / mustNot / handoff) | 12 | 5 |
| Format failures (leak, empty, >140 words…) | 5 (2 leaks, 1 empty, 1 over 140 words) | 1 (too many links) |
| Words: median / p90 / max | 68 / 115 / 154 | 38 / 80 / 84 |
| LLM judge: correct / helpful / human (each out of 2) | 1.11 / 1.30 / 1.44 | 1.82 / 1.79 / 1.75 |
| LLM judge total (out of 6) | 3.85 | 5.36 |

Old-variant errors on this set:
- told visitors "I'm only set up for English" or answered in English
- quoted a "dedicated IPv4 on every VPS"
- "I don't have a Discord" and a leaked "knowledge base"
- handed off on "can someone tell me the price"
- one empty card-only reply
- "vCPUs are dedicated"
- denied the Windows option

## Remaining new-variant failures, and the fixes for them

These were fixed in a851bd8 but **not re-measured**:

- **free-mc and root-pw.** The answer text the model wrote before a tool call was dropped. Fixed with `keepInterimText`.
- **refund-30day and cpu-model.** The handoff had no answer in it. The prompt now says to answer first and to treat a plain refund request as not a dispute.
- **port80.** The model never consulted the networking facts. Added topic hints to the prompt.
- **korean-refund.** It used 3 markdown links to the wrong domain, nxeon.com. Added a bad_link guard and a tidy fix.

## Why the re-run didn't happen

The re-run after a851bd8 could not complete. The Anthropic key returned "credit balance is too low" partway through. **The live chat bot in prod uses the same key, so it is now in degraded mode.**

# AU - Cyrus QA + security re-audit + accessibility + performance (r49, 2026-10-11)
Branch `feature/cyrus-r49-qa` (worktree cyrus-r49, r2 incl. r45/r48/r50 merged). NOT merged or deployed; no production flag, migration, email, Stripe or conversion event; flags on only in throwaway `wt_cyrus_r49`.

## Commits
1/5 journeys `65614db6a1`, 2/5 security `c2a7322f16`, 3/5 a11y `ae2f6e11a8`, 4/5 perf/load `955167b8f1`, r2 merge `2ebd565def`, 5/5 docs `178a3a20ca`, journeys follow-up `6f176c353a`.

## Pass/fail
| Area | Result |
|---|---|
| Browser journeys (sign-up, SSO both ways, logout, wallet, full screen, app, Connect Cyrus, API key, export, admin, r45) | **25/25** (`next start` behind local TLS, Chromium) |
| Money journey DB test + existing money DB tests | 2/2 + 27/27 |
| Real Paper 1.21.11 Test Flight through the Platform API | passed; revoke mid-update gave an exact restore |
| Build queue: 50 concurrent builds, real service, fake CLI | pass: cap 3 held, FIFO, no starvation |
| Security re-audit | 1 HIGH + 9 MED + 2 LOW fixed, each with a test that failed on the old code |
| axe WCAG 2.1 AA: landing, sign-in, customer app | 0 violations after fixes |
| axe: studios | only exempt "off" graph labels left |
| axe: Nxeon admin chrome | 3 rule types (not Cyrus code; owner item) |
| Load limits (lab) | all held: API key 60/min, Platform API 600 reads/min and 240 writes/min |
| Load latency (lab) | p95 30-47 ms; outbox drained 500 events in 0.5 s, 0 duplicates |
| Performance (lab, 4x CPU) | LCP 0.4-1.2 s |
| Performance over budget | TBT 0.4-0.7 s on the app, landing INP ~0.47 s, app page weight ~2.8 MB |
| Full Cyrus suite | 2752/2753 (the 1 was stale references, now regenerated) |
| tsc / next build | clean / passed |
| Host seam, db-split, docs coverage | pass |

Page weight is mostly Nxeon's: all of `simple-icons` (~2 MB gz) ships on every /dashboard page, production too (task filed).

## Security (detail: docs/cyrus/08-security.md "r49")
Fixed: HIGH symlink escape from the game folder via the Platform API. MED: restart budget race, revoked-op window read the whole server, delete "absent" ran `rm -rf`, bodies buffered before signature checks, GDPR missed 7 tables, stale consent used, BYO marker droppable, BILLING could rewrite the token economy, repeat takedowns swallowed. LOW: cumulative refunds, `__Host-` cookie clearing. Open + owner choices: OWNER-ACTIONS "r49".

## Bugs found by running
Fixtures overwrote the preview list (fixed). Lab traps: CSP upgrade on http; Playwright `page.request` ignores fake DNS (early runs tried the primary's public IP on an unused port: timed out, nothing reached); `next dev -H` loopback breaks rewrites; dev mode OOMs. Ops trap: systemd mangles PEM `\n`.

## Not run
Real model build; r48 asset streaming (needs the build service); real Stripe/Meta/Google/email; real nginx/Cloudflare; Lighthouse (Playwright traces instead); a person with a screen reader.

## Files
Shots `cyrus-designs/impl-shots/qa-*.png`; JSON `qa-{journeys,a11y,perf,load,bridge-flight}-r49-2026-10-11.json`; rerun: docs/cyrus/09 "r49 QA bundle".

# AG - Cyrus one-account bridge: cyrus.my + nxeon.cloud (r36, 2026-10-11)
Branch `feature/cyrus-r36-bridge` (worktree `/tank/dev-worktrees/cyrus-r36`, from r2, latest r2 `29cbc822dd` merged). NOT merged into r2, NOT deployed, no migration, no flag flipped, nginx/DNS untouched. With `CYRUS_DOMAIN_MODE` unset nothing changes.

## Commits
1. `fdb0c1e78b` dual-host shell: middleware + `lib/cyrus/bridge/{config,routing}.ts`; cyrus.my gets the Cyrus brand bar (`components/cyrus/host-shell`) around the SAME `/dashboard/cyrus` pages; portal pages hand off to Nxeon; the rest 404s.
2. `30ce5b5224` SSO: Sign in with Nxeon (Ed25519 assertion, state/nonce, single-use, exact redirect_uri), sign-up via Nxeon /register behind a consent screen, verified email, id-only matching, own Cyrus cookie/token type parented to the Nxeon session, impersonation never crosses, Sign in with Cyrus, signed logout hop, rate limits.
3. `f765028559` purchase -> credit: card checkouts return to the host they started on; wallet top-ups (idempotent charge by reference, compensating refund, pending/failed states, reconcile, refunds reverse unspent tokens); signed purchase webhook sender (Nxeon side) + receiver (Cyrus side), idempotent.
4. `5f976b87fc` + `3c23bfa9d2` two-origin e2e + fixes it found (rewrite target, absolute redirects, strict verified email, CSP form-action), docs. Merge `09142bbb09`.

## Ran (node-2 via devhost)
- `tsc --noEmit` clean after the final merge; full Cyrus suite **2310/2310**; host seam ratchet passes (no new Nxeon imports under lib/cyrus).
- DB test (throwaway `wt_cyrus_r36`): 6/6 (wallet once on retry, insufficient funds, failed credit refunds, signed receiver + redelivery, reconcile, refund).
- **Two-origin e2e** (`next dev`, cyrus.my and nxeon.cloud via `curl --resolve`, per-host jars): mode on **46/46** (one transient failure on an earlier run right after a hot reload, then clean twice); mode off **6/6** (no studio on cyrus.my, no IdP, internal tree 404, spoofed marker ignored, Nxeon dashboard + login unchanged).

## Security review (own flow)
Checked: open redirect (exact redirect_uri, validated next, configured origins only), login CSRF (nonce bound to the starting browser), replay (state consumed, jti once), forged subject (signature), header spoofing (marker stripped), impersonation leak (refused at authorize, ignored on cyrus.my), session fixation (fresh cookie), consent CSRF (Origin + bound token), logout CSRF (POST + Origin; Nxeon hop needs a signed token), back-channel (parent revocation), staff (no reverse SSO for staff/2FA), CSP form-action (fixed). Residual: replay caches, rate limits, the wallet lock and the outbox are per process; the assertion sits in a URL for up to 120 s (useless without the browser's state cookie); no-JS password login has Kodely's same form-action limit.

## Not done
- No wallet button in the tokens modal (API only); card purchases credit directly, not via the event path.
- Not run: `next build`, Playwright/real browser, real Stripe, staging under nginx + `next start` (dev needed `-H localhost` for internal rewrites).
- Owner list: `OWNER-ACTIONS.md` "r36" (nginx paths, env, Stripe domain, cookie/logout/verification defaults, SQL proposals, legal copy).

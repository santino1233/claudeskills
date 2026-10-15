# CS: Continue with Google on cyrus.my (2026-10-15)
Branch `feature/cyrus-google-login`, worktree `/tank/dev-worktrees/cyrus-google-login`. Not merged, not deployed, no migration, default OFF.

## Register in Google (project cyrus-511708, client "Cyrus oAuth", Web application)
- Authorized JavaScript origins: `https://cyrus.my`
- Authorized redirect URI (exactly one): `https://cyrus.my/api/auth/google/callback`
  (derived from CYRUS_ORIGIN / first CYRUS_HOSTS entry; never from a request header. www.cyrus.my hops to the apex first.)
- Branding values + scopes (openid, userinfo.email, userinfo.profile), publishing status "In production": docs/cyrus/CYRUS-GOOGLE-LOGIN.md

## Env
`CYRUS_GOOGLE_LOGIN=1`, `CYRUS_GOOGLE_CLIENT_ID`, `CYRUS_GOOGLE_CLIENT_SECRET` (+ existing `CYRUS_DOMAIN_MODE=1`). Nxeon `GOOGLE_CLIENT_ID/SECRET` untouched.

## Store the secret without echo
```bash
read -rp 'Cyrus Google client id: ' CID; read -rsp 'Cyrus Google client secret (hidden): ' CSEC; echo
cp -p /opt/nxeon/.env /opt/nxeon/.env.bak.$(date +%Y%m%d%H%M%S)
sed -i '/^CYRUS_GOOGLE_CLIENT_ID=/d;/^CYRUS_GOOGLE_CLIENT_SECRET=/d;/^CYRUS_GOOGLE_LOGIN=/d' /opt/nxeon/.env
printf 'CYRUS_GOOGLE_LOGIN=1\nCYRUS_GOOGLE_CLIENT_ID=%s\nCYRUS_GOOGLE_CLIENT_SECRET=%s\n' "$CID" "$CSEC" >> /opt/nxeon/.env
unset CID CSEC; chmod 600 /opt/nxeon/.env
```
then restart nxeon-web after deploy.

## Files
- NEW lib/google-account.ts: find/link/create account, extracted verbatim from the Nxeon callback (one rule, shared).
- MOD app/api/auth/google/callback/route.ts: now calls the helper; same behaviour (no Cyrus reference in either Nxeon route file; test pins it).
- MOD lib/google-oauth.ts: additive only: cyrusGoogleConfigured, googleClientForHost, googleClientAuthorizeUrl (PKCE S256 + nonce), googleClientExchange (id_token nonce/aud/iss/exp), pkceChallenge. Existing exports unchanged; Nxeon authorize URL byte-identical (test).
- NEW lib/cyrus-bridge/google-login.ts: planGoogleStart / completeGoogleLogin (pure, fakes), firstRunGate hook (no-op; username gate from feature/cyrus-community plugs in here).
- NEW app/cyrus-host/auth/google/route.ts, .../callback/route.ts; MOD lib/cyrus/bridge/routing.ts (CYRUS_PAGES: /api/auth/google, /api/auth/google/callback rewrite to the host tree); MOD lib/cyrus/bridge/flow.ts (GOOGLE_ERRORS fixed copy).
- MOD app/cyrus-host/sign-in/SignInView.tsx: neutral white "Continue with Google" button with the unmodified multicolour G (inline SVG), shown on /sign-in and /sign-up only when configured.
- NEW test/cyrus-google-login.test.ts (31 tests, pass); docs: 06-portals, CYRUS-MY-LAUNCH (env row + nginx regex `api/auth/google`), CYRUS-GOOGLE-LOGIN.md, reference/* regenerated.

## Design
Session = createCyrusSession(userId, null), the SSO callback's own mint path (no Nxeon parent session on this path; stands alone, revocable). State = HMAC-sealed host-only cookie (state+nonce+verifier+safeCyrusNext next, 10 min, consumed). Link only on Google email_verified (shared helper); suspended and non-CUSTOMER roles refused (as /auth/handoff); private-beta rule as /auth/nxeon/callback; landing prompt hand-off rides in `next` (sign-in page already builds /new?prompt=). Rate limits 20 start/30 callback per IP/min; audit user.login / user.login_denied.

## Caveats for the owner
- Existing password accounts are linked on verified email, same as nxeon.cloud's Google login (that is the existing rule); no 2FA prompt on either.
- Google login does not stamp a Nxeon session: signing in on cyrus.my this way does not sign in on nxeon.cloud.
- nginx cyrus.my block must proxy /api/auth/google (add to the regex).

## Promote line
Portal only, additive: merge feature/cyrus-google-login -> main; deploy with the three env vars UNSET (nothing changes), then set them after the Google client exists and restart nxeon-web. No worker/agent change, no migration.

## Status / verification (updated after resume)
- Committed a4dc3a37 on feature/cyrus-google-login (not pushed to main, not deployed).
- Unit/route tests: test/cyrus-google-login.test.ts 31/31 pass, plus cyrus-bridge-sso/ux/gaps/qa-polish/site-links/platform-contract green.
- Typecheck: full `tsc --noEmit` on the shared build host is OOM-killed / time-limited by other agents' runs (journal: oom-kill, runtime limit). A scoped tsc (all new/changed files + their import graph, tsconfig extending the repo's) is clean. Re-run the full tsc when the host is quiet.
- Owner already stored CYRUS_GOOGLE_CLIENT_ID/SECRET in /opt/nxeon/.env (names only). To go live: add `CYRUS_GOOGLE_LOGIN=1` (the flag) to .env, deploy this branch, restart nxeon-web.

## Go-live verification steps
1. Redirect URI registered exactly: https://cyrus.my/api/auth/google/callback ; JS origin https://cyrus.my.
2. nginx cyrus.my block proxies api/auth/google (regex in CYRUS-MY-LAUNCH step 5); CYRUS_DOMAIN_MODE=1.
3. `curl -sI "https://cyrus.my/api/auth/google?next=/studio"` -> 302 to accounts.google.com with client_id=<Cyrus client>, redirect_uri=https%3A%2F%2Fcyrus.my%2Fapi%2Fauth%2Fgoogle%2Fcallback, code_challenge_method=S256, nonce, scope=openid+email+profile, prompt=select_account; Set-Cookie __Host-cyrus_google_state.
4. Browser: https://cyrus.my/sign-in shows "Continue with Google"; consent screen says Cyrus; lands on /studio (beta panel if not on the allow-list); `__Host-cyrus_session` cookie set.
5. nxeon.cloud /login Google button unchanged (still the Nxeon client).
6. Rollback: remove CYRUS_GOOGLE_LOGIN=1, restart nxeon-web.

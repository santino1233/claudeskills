---
name: nxeon-impersonation-bugs-fixed
description: "three real admin-impersonation bugs fixed + deployed 2026-09-25 (location leak, ticket-reply misattribution, exit-redirect 404)"
metadata:
  node_type: memory
  type: project
  originSessionId: ec6fa978-d80b-4147-9982-eea470598e2c
  modified: 2026-09-25T13:40:56.393Z
---

Shipped 2026-09-25 to production (`/opt/nxeon`, merge commit `f9b3905807`). All three reported by the owner in one message, root-caused and fixed with real production-build reproduction (not just unit tests).

1. **Location leak**: impersonating a customer polluted their own "Sign-in IPs"/Location panel with the admin's IP/city. Root cause: `app/api/track/route.ts`'s page-view logger correctly resolved `userId` as the impersonated target (by design) but always wrote the REAL requester's IP — so every page view during an impersonation session wrote a `Visit` row under the customer's own account carrying the admin's location. Fix: skip `userId` attribution on visits made while impersonating.
2. **Ticket-reply misattribution**: a staff reply sent while impersonating displayed as the customer's own message. Root cause: `requireTicketActor()` resolved identity via `currentUser()`, which (correctly, for browsing) returns the impersonated target. Fix (judgment call): resolve the REAL admin underneath the impersonation JWT's `adminId` claim and mark the reply `isStaff: true` under the admin's own identity — matching the exact shape a genuine `/admin/support` reply already produces, rather than inventing a new annotation.
3. **Exit-impersonation 404**: `stopImpersonating()`'s `redirect("/admin/users")` 404'd — only reproduced against a real `next build` + standalone server (never `next dev`), turned out to be a production-router quirk following the redirect to `/dashboard` instead. Fix: the exit button now does a real `window.location.assign("/admin/users")` instead of relying on the server action's own `redirect()`.

See [[nxeon-grandfather-pricing-fleet-tags]] for the sibling fix shipped the same session.

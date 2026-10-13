---
name: nxeon-platform
description: "The user's main project — Nxeon, a Hostinger-style VPS hosting platform on this Proxmox server"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-07-23T11:48:32.922Z
---

The user is building **Nxeon**, a premium Hostinger/DigitalOcean-style VPS hosting business on this OVH dedicated server (Proxmox VE 9, i7-7700K, 64GB RAM, public IP 51.79.162.96). Built and deployed starting 2026-07-23. The user wants it to feel like Stripe/Linear/Vercel/Cloudflare-grade SaaS — premium dark UI, glassmorphism, blue→purple gradients, command palette, beautiful charts — with maximum operational control on the admin side.

- App: `/opt/nxeon` — Next.js 15 (App Router, server actions) + Prisma + PostgreSQL + Tailwind v4. Two separate sidebar portals: customer (`app/dashboard`) and admin ops center (`app/admin`), sharing `components/portal/Shell.tsx`. Design system in `app/globals.css` + `components/ui/`. See `/opt/nxeon/CLAUDE.md` (architecture, environments, integrations, safety) and `/opt/nxeon/ROADMAP.md`.
- Services: `nxeon-web`/`nxeon-worker` (systemd), nginx :80. Worker drives Proxmox API, runs billing sweep + provisioning jobs (provision/power/reinstall/delete/suspend/resize/snapshot/backup/port-forward-sync).
- Proxmox: token `nxeon@pve!platform` (secret in `.env`), templates 9000 (Ubuntu 24.04) / 9001 (Debian 13), ZFS `vmdata`, backup pool `tank`/`backup` on 4TB HDD, NAT bridge vmbr1 10.20.0.0/24.
- **Staging**: full second instance `/opt/nxeon-staging`, DB `nxeon_staging`, services `nxeon-staging-web` (:3001)/`nxeon-staging-worker`, nginx :8080, isolated VPS pools (IP .50–.99, ports 30000–30999, chain NXEON_FWD_STG). Deploy via `scripts/deploy-staging.sh`, promote via `scripts/promote-production.sh`.
- Integrations (activate by filling `.env`): **Stripe** (wallet top-ups, `/api/stripe/*`), **Namecheap** (domain search/register/DNS, `lib/namecheap.ts`), **GitHub** auto-push (`.git/hooks/post-commit`, one-time `scripts/setup-github.sh <url>`). [[nxeon-integrations-pending]]
- **Live URLs**: customer `https://revsports.ca`, admin `https://4j3d7gkr2wcbi34.revsports.ca` (secret subdomain; `/admin` is 404'd on the public domain), staging `https://staging.revsports.ca`. `revsports.ca` is a PLACEHOLDER domain — the real one gets bought later. Domain lives ONLY in `/etc/nxeon/domains.env`; migrate by editing it + running `scripts/configure-domains.sh` (regenerates nginx, re-issues LE certs, updates APP_URL). Never hardcode the domain. [[nxeon-domain-migration]]
- Real Let's Encrypt TLS (auto-renew), secure cookies on, Stripe webhook live. GitHub: `git@github.com:santino1233/nxeon.git`, auto-push on every commit via deploy key.
- 5 OS templates (Ubuntu 24.04/22.04, Debian 13, AlmaLinux 9, Rocky 9). Nightly DB + weekly VM backups to /tank/backup.
- Admin login: `/root/nxeon-credentials.txt`. Free VPSes for personal use via admin Grant page / free-at-order checkbox.
- A recurring scheduled task `nxeon-improve` (every 4h) autonomously works the roadmap. [[nxeon-improve-agent]]

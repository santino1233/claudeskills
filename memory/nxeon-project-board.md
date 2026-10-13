---
name: nxeon-project-board
description: The private admin kanban board at /admin/board — how the user files work for me and how I read + move it
metadata: 
  node_type: memory
  type: project
  originSessionId: 4f329df3-66ee-49c8-a6c5-615ecf189efc
  modified: 2026-08-01T08:58:55.132Z
---

A private, **admin-only** (never customer-facing) Trello-style board at **/admin/board** for managing Nxeon + other projects. Shipped commit 9add541. Needs `prisma db push`.

**Multi-board:** each `Board` row is a separate project (seeds a "Nxeon" board on first load; the user adds more like "Soul Pilates" via "+ Board"). `Board → BoardColumn` (stage) `→ Card` (title, markdown description, type IDEA/FEATURE/BUG/CHORE, priority, labels, assignee, position, archivedAt). Plus `CardAttachment` + `CardComment`.

**The workflow this exists for — how I (Claude) use it:**
- Attachments are stored **on this server's disk** at `/opt/nxeon/board-uploads/board/<cardId>/<storedName>` (env `NXEON_BOARD_UPLOAD_DIR`; gitignored). So I can **Read them directly** — screenshots/images/PDFs/text/logs/code. I CANNOT watch video content (the board stores + plays video fine; for a recording the user must describe it or attach a transcript).
- To see what the user filed: query the DB (`db.card` / `db.cardAttachment` / `db.cardComment`) via a scratch tsx script, and Read the attachment files off disk.
- **As I work, I move cards along the pipeline** by updating `card.columnId` (+ position) — via the `moveCard` action or a direct `db.card.update`. Add a `CardComment` (authorName e.g. "claude") noting what I did.

**Code:** `lib/actions-board.ts` (admin-gated CRUD + moveCard), `lib/board-shared.ts` (BOARD_UPLOAD_DIR — plain module because a "use server" file may only export async fns), upload route `app/api/board/attachments` + Range-capable serve `app/api/board/attachments/[id]`, UI `components/admin/BoardClient.tsx` (board switcher, DnD, card modal). RBAC `/admin/board` = platform. See [[nxeon-platform]].

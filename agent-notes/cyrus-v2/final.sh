#!/bin/bash
# Final screenshot set (round 4). Mock-backed dev server on :3149, "full" seed.
cd /root/agent-notes/cyrus-v2
export ROUND=r4
S() { timeout 400 nice node shot.mjs "$@" 2>&1 | tail -3; }
VIEWS=wide,mobile THEMES=dark,light WAIT=4000 S home /dashboard/cyrus
VIEWS=desktop,wide,mobile THEMES=dark,light WAIT=7500 S proj-run /dashboard/cyrus/cy-run-spleef
VIEWS=desktop,mobile THEMES=dark,light WAIT=4000 S proj-done /dashboard/cyrus/p0-econ01
ACT='async (p) => { await p.waitForTimeout(2000); await p.getByRole("tab", { name: /Versions/ }).click(); await p.waitForTimeout(600); await p.getByRole("button", { name: "Latest two" }).click(); await p.waitForTimeout(2500); }' WAIT=300 S proj-versions /dashboard/cyrus/cy-dr-v4
WAIT=3500 S proj-fail /dashboard/cyrus/cy-dr-v3
ACT='async (p) => { await p.waitForTimeout(2500); await p.keyboard.press("d"); await p.waitForTimeout(1800); }' WAIT=300 S focus /dashboard/cyrus/cy-dr-v4
ACT='async (p) => { await p.waitForTimeout(2500); const pt = await p.evaluate(() => { const w = window.__cyWeb; const n = w.nodes.find((x) => x.kind === "mod" && x.spec.status === "ok"); const s = w.screenPos(n); const r = document.querySelector(".cy-canvas").getBoundingClientRect(); return { x: s.x + r.left, y: s.y + r.top }; }); await p.mouse.move(pt.x - 40, pt.y - 40); await p.mouse.move(pt.x, pt.y, { steps: 6 }); await p.waitForTimeout(900); }' WAIT=200 S hover /dashboard/cyrus
ACT='async (p) => { await p.waitForTimeout(1500); await p.keyboard.press("l"); await p.waitForTimeout(800); }' WAIT=200 S drawer /dashboard/cyrus
ACT='async (p) => { await p.waitForTimeout(1500); await p.keyboard.press("?"); await p.waitForTimeout(600); }' WAIT=200 S keys /dashboard/cyrus
VIEWS=desktop,mobile ACT='async (p) => { await p.waitForTimeout(1500); const ta = p.getByLabel("Describe your mod"); await ta.click(); await ta.fill("A coin shop where the menu looks exactly like my screenshot"); await p.locator("input[type=file]").first().setInputFiles(["/root/agent-notes/cyrus-v2/proof/shop-mock.png"]); await p.waitForTimeout(2500); await p.locator(".cy-pick").filter({ hasText: "Saka" }).first().click(); await p.waitForTimeout(700); }' WAIT=300 S picker /dashboard/cyrus
FRAMES=10 FRAMEGAP=180 WAIT=7000 S frames-run /dashboard/cyrus/cy-run-spleef
FRAMES=8 FRAMEGAP=250 WAIT=3500 S frames-home /dashboard/cyrus
echo FINAL-DONE

#!/bin/bash
# v3 state set. usage: ROUND=r2 ./states.sh
cd /root/agent-notes/cyrus-v3
S() { timeout 400 nice node shot.mjs "$@" 2>&1 | tail -3; }
VIEWS=desktop THEMES=dark,light WAIT=4500 S proj-done /dashboard/cyrus/p0-econ01
VIEWS=desktop THEMES=dark WAIT=3500 S proj-fail /dashboard/cyrus/cy-dr-v3
ACT='async (p) => { await p.waitForTimeout(2000); await p.getByRole("tab", { name: /Versions/ }).click(); await p.waitForTimeout(600); await p.getByRole("button", { name: "Latest two" }).click(); await p.waitForTimeout(2500); }' VIEWS=desktop THEMES=dark,light WAIT=300 S proj-versions /dashboard/cyrus/cy-dr-v4
ACT='async (p) => { await p.waitForTimeout(2500); await p.keyboard.press("d"); await p.waitForTimeout(1800); }' VIEWS=desktop THEMES=dark WAIT=300 S focus /dashboard/cyrus/p0-econ01
ACT='async (p) => { await p.waitForTimeout(1500); await p.keyboard.press("l"); await p.waitForTimeout(800); }' VIEWS=desktop THEMES=dark,light WAIT=200 S drawer /dashboard/cyrus
VIEWS=desktop,mobile THEMES=dark,light ACT='async (p) => { await p.waitForTimeout(1500); const ta = p.getByLabel("Describe your mod"); await ta.click(); await ta.fill("A coin shop where the menu looks exactly like my screenshot"); await p.locator(".cy-pick").filter({ hasText: "Saka" }).first().click(); await p.waitForTimeout(700); }' WAIT=300 S picker /dashboard/cyrus
VIEWS=desktop,mobile THEMES=dark ACT='async (p) => { await p.waitForTimeout(1500); await p.locator(".cy-pick").filter({ hasText: "Paper" }).first().click(); await p.waitForTimeout(700); }' WAIT=300 S gamepicker /dashboard/cyrus
VIEWS=mobile THEMES=dark,light WAIT=5000 S home /dashboard/cyrus
VIEWS=wide THEMES=dark,light WAIT=7000 S home /dashboard/cyrus
VIEWS=wide THEMES=dark,light WAIT=7500 S proj-run /dashboard/cyrus/cy-run-spleef
echo STATES-DONE

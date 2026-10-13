#!/bin/bash
cd /root/agent-notes/lightmode-audit
for f in scenes1 scenes3 scenes4 scenes2 scenes5; do THEMES=light VIEWS=mobile node shot.mjs /root/agent-notes/lightmode-audit/$f.mjs /root/agent-notes/lightmode-audit/after; done

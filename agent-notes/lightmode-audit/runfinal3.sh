#!/bin/bash
cd /root/agent-notes/lightmode-audit
for f in scenes4 scenes5; do THEMES=light VIEWS=desktop node shot.mjs /root/agent-notes/lightmode-audit/$f.mjs /root/agent-notes/lightmode-audit/after; done

#!/bin/bash
cd /root/agent-notes/lightmode-audit
sleep 20
for f in scenes4 scenes5; do THEMES=light VIEWS=desktop,mobile node shot.mjs /root/agent-notes/lightmode-audit/$f.mjs /root/agent-notes/lightmode-audit/before; done

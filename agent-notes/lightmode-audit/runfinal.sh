#!/bin/bash
cd /root/agent-notes/lightmode-audit
SUB='^(home|servers|vps-overview|game-minecraft-overview|billing|support|settings|domains|ssl|deploy-vps|deploy-game-minecraft|hosting-overview|refer|partner|tool-password-generator|modbuilder-home|ded-list|empty-home)$'
for f in scenes1 scenes2 scenes3 scenes4; do THEMES=dark VIEWS=desktop node shot.mjs /root/agent-notes/lightmode-audit/$f.mjs /root/agent-notes/lightmode-audit/after "$SUB"; done
for f in scenes1 scenes3 scenes4 scenes2; do THEMES=light VIEWS=desktop,mobile SKIP_EXISTING= node shot.mjs /root/agent-notes/lightmode-audit/$f.mjs /root/agent-notes/lightmode-audit/after; done

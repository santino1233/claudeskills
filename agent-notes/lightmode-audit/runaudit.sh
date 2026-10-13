#!/bin/bash
cd /root/agent-notes/lightmode-audit
for f in scenes1 scenes3 scenes2; do node audit.mjs /root/agent-notes/lightmode-audit/$f.mjs /root/agent-notes/lightmode-audit/run/audit-all.json; done

#!/bin/bash
# rc21 owner check: does the real Claude CLI in the modbuilder container accept a base64 image on stdin
# (--input-format stream-json), the way services/modbuilder/roomstudio.js sends Room Studio reference images?
# Run on the primary as root AFTER modbuilder:0.26 is live (works on 0.25 too: same CLI path). One Haiku call with a
# 16x16 red PNG, --max-budget-usd 0.05 (real cost about 0.1-0.3 US cents). PASS = a result line with "is_error":false
# and an answer containing "red".
set -euo pipefail
NODE2=root@178.63.94.114
BUILDVM=root@10.20.1.253
MSG=$(python3 -I - <<'PY'
import base64, json, struct, zlib
w = h = 16
raw = b"".join(b"\x00" + b"\xff\x00\x00" * w for _ in range(h))
ch = lambda t, d: struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d))
png = b"\x89PNG\r\n\x1a\n" + ch(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)) + ch(b"IDAT", zlib.compress(raw)) + ch(b"IEND", b"")
print(json.dumps({"type": "user", "message": {"role": "user", "content": [
  {"type": "image", "source": {"type": "base64", "media_type": "image/png", "data": base64.b64encode(png).decode()}},
  {"type": "text", "text": "What colour is this image? Answer with one word."}]}}))
PY
)
OUT=$(printf '%s\n' "$MSG" | ssh -o BatchMode=yes -J "$NODE2" "$BUILDVM" \
  "docker exec -i modbuilder claude -p --input-format stream-json --output-format stream-json --verbose --tools '' --strict-mcp-config --model claude-haiku-4-5-20251001 --max-turns 1 --max-budget-usd 0.05" || true)
RES=$(printf '%s\n' "$OUT" | grep '"type":"result"' | tail -1)
echo "$RES" | head -c 1200; echo
case "$RES" in
  *'"is_error":false'*[Rr]ed*|*[Rr]ed*'"is_error":false'*) echo "PASS: the CLI accepts base64 images on stdin (Room Studio image input will work)";;
  *) echo "FAIL: no clean result. Last output lines:"; printf '%s\n' "$OUT" | tail -5 | head -c 2000; echo
     echo "Keep CYRUS_ROOM_STUDIO image input unused (the image job will fail, holds are released) and report this.";;
esac

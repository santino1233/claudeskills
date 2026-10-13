#!/usr/bin/env python3
"""Inline v4-motion/src/<page>.html + css + js + fonts + images + the motion data/frames into self-contained mockups (no network).
The motion data and every frame come from the real motion core (scripts/cyrus/motion-mock-data.ts on node-2)."""
import base64, json, os, re, sys
D = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); S = os.path.join(D, "src"); A = os.path.join(D, "assets")
PAGES = ["motion.html", "presets.html"]
MIME = {".webp": "image/webp", ".png": "image/png", ".svg": "image/svg+xml", ".woff2": "font/woff2"}
cache = {}
def data(path):
    p = os.path.normpath(path)
    if p not in cache: cache[p] = f"data:{MIME[os.path.splitext(p)[1]]};base64," + base64.b64encode(open(p, "rb").read()).decode()
    return cache[p]
def assets(t): return re.sub(r"\.\./assets/[A-Za-z0-9_./-]+\.(?:webp|png|svg|woff2)", lambda m: data(os.path.join(S, m.group(0))), t)
# generated data module: DATA (json) + FRAMES (name -> data uri), per page only what it uses
def gen(prefixes):
    d = json.load(open(os.path.join(A, "motion/data.json")))
    fr = {}
    for n in sorted(os.listdir(os.path.join(A, "motion/frames"))):
        if any(n.startswith(p) for p in prefixes): fr[n[:-4]] = data(os.path.join(A, "motion/frames", n))
    return "window.DATA = " + json.dumps(d) + ";\nwindow.FRAMES = " + json.dumps(fr) + ";\n"
NEED = {"motion.html": ["gun-"], "presets.html": ["preset-"]}
for src in (sys.argv[1:] or PAGES):
    h = open(os.path.join(S, src)).read()
    h = re.sub(r'<link rel="stylesheet" href="([^"]+)">', lambda m: "<style>\n" + open(os.path.join(S, m.group(1))).read() + "\n</style>", h)
    h = h.replace('<script src="gen-data.js"></script>', "<script>\n" + gen(NEED[src]) + "\n</script>")
    h = re.sub(r'<script src="([^"]+)"></script>', lambda m: "<script>\n" + open(os.path.join(S, m.group(1))).read().replace("</script", "<\\/script") + "\n</script>", h)
    h = assets(h)
    assert "../assets" not in h, src
    open(os.path.join(D, src), "w").write(h)
    print(src, round(len(h) / 1024), "KB")

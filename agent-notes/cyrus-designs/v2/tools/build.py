#!/usr/bin/env python3
"""Inline v2/src/<page>.html + css + js + fonts + images into self-contained mockups in v2/ (no network)."""
import base64, re, os, sys
D = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); S = os.path.join(D, "src")
PAGES = ["item-designer.html", "menu-quest.html", "mod-packs.html", "import-mod.html", "datapack-studio.html"]
MIME = {".webp": "image/webp", ".png": "image/png", ".svg": "image/svg+xml", ".woff2": "font/woff2"}
cache = {}
def data(rel):
    p = os.path.normpath(os.path.join(S, rel))
    if p not in cache: cache[p] = f"data:{MIME[os.path.splitext(p)[1]]};base64," + base64.b64encode(open(p, "rb").read()).decode()
    return cache[p]
def assets(t): return re.sub(r"\.\./assets/[A-Za-z0-9_./-]+\.(?:webp|png|svg|woff2)", lambda m: data(m.group(0)), t)
for src in (sys.argv[1:] or PAGES):
    if not os.path.exists(os.path.join(S, src)): continue
    h = open(os.path.join(S, src)).read()
    h = re.sub(r'<link rel="stylesheet" href="([^"]+)">', lambda m: "<style>\n" + open(os.path.join(S, m.group(1))).read() + "\n</style>", h)
    h = re.sub(r'<script src="([^"]+)"></script>', lambda m: "<script>\n" + open(os.path.join(S, m.group(1))).read().replace("</script", "<\\/script") + "\n</script>", h)
    h = assets(h)
    assert "../assets" not in h, src
    open(os.path.join(D, src), "w").write(h)
    print(src, round(len(h) / 1024), "KB")

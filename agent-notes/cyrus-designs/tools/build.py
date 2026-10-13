#!/usr/bin/env python3
"""Inline src/*.html + css + js + fonts + images into self-contained mockups in the design folder root."""
import base64, re, os
D = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); S = os.path.join(D, "src")
OUT = {"texture.html": "texture-studio.html", "sound.html": "sound-studio.html", "mod-assets.html": "mod-assets.html", "locked.html": "locked-states.html"}
MIME = {".webp": "image/webp", ".png": "image/png", ".svg": "image/svg+xml", ".woff2": "font/woff2"}
cache = {}
def data(rel):
    p = os.path.normpath(os.path.join(S, rel))
    if p not in cache: cache[p] = f"data:{MIME[os.path.splitext(p)[1]]};base64," + base64.b64encode(open(p, "rb").read()).decode()
    return cache[p]
def assets(txt): return re.sub(r"\.\./assets/[A-Za-z0-9_./-]+\.(?:webp|png|svg|woff2)", lambda m: data(m.group(0)), txt)
def links(txt):
    txt = re.sub(r'href="(texture|sound|locked)\.html', lambda m: f'href="{OUT[m.group(1)+".html"]}', txt)
    return txt.replace("${kind}.html", "${kind}-studio.html")
for src, dst in OUT.items():
    h = open(os.path.join(S, src)).read()
    h = re.sub(r'<link rel="stylesheet" href="([^"]+)">', lambda m: "<style>\n" + open(os.path.join(S, m.group(1))).read() + "\n</style>", h)
    h = re.sub(r'<script src="([^"]+)"></script>', lambda m: "<script>\n" + open(os.path.join(S, m.group(1))).read().replace("</script", "<\\/script") + "\n</script>", h)
    h = links(assets(h))
    assert "../assets" not in h and 'src="engine.js"' not in h
    open(os.path.join(D, dst), "w").write(h)
    print(dst, round(len(h) / 1024), "KB")

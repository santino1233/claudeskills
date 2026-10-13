#!/usr/bin/env python3
"""Inline v5-config/src/config-*.html (+ the shared kit css/js, fonts, images) into self-contained mockups in v5-config/."""
import base64, re, os
D = os.path.dirname(os.path.abspath(__file__)); S = os.path.join(D, "src")
MIME = {".webp": "image/webp", ".png": "image/png", ".svg": "image/svg+xml", ".woff2": "font/woff2"}
def data(path):
    return f"data:{MIME[os.path.splitext(path)[1]]};base64," + base64.b64encode(open(path, "rb").read()).decode()
def inline_assets(txt, base):
    return re.sub(r"\.\./assets/[A-Za-z0-9_./-]+\.(?:webp|png|svg|woff2)", lambda m: data(os.path.normpath(os.path.join(base, m.group(0)))), txt)
for f in ["config-mob.html", "config-gun.html"]:
    h = open(os.path.join(S, f)).read()
    h = re.sub(r'<link rel="stylesheet" href="([^"]+)">', lambda m: "<style>\n" + inline_assets(open(os.path.join(S, m.group(1))).read(), os.path.dirname(os.path.join(S, m.group(1)))) + "\n</style>", h)
    h = re.sub(r'<script src="([^"]+)"></script>', lambda m: "<script>\n" + inline_assets(open(os.path.join(S, m.group(1))).read(), S).replace("</script", "<\\/script") + "\n</script>", h)
    h = inline_assets(h, S)
    assert "../assets" not in h, f
    open(os.path.join(D, f), "w").write(h)
    print(f, round(len(h) / 1024), "KB")

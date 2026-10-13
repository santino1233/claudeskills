# Sci-fi supply crate r2, 1.0 x 0.6 x 0.6 m, Z up, base on z=0
L, W, H = 1.0, 0.6, 0.6
foot = 0.05
hull = mat('hull', (0.05, 0.08, 0.07), 0.6, 0.5)
frame = mat('frame', (0.03, 0.035, 0.04), 0.9, 0.35)
panel = mat('panel', (0.10, 0.15, 0.13), 0.5, 0.45)
accent = mat('accent', (0.85, 0.55, 0.02), 0.2, 0.5)
glow = mat('glow', (0.1, 0.8, 1.0), 0.0, 0.3, emit=(0.1, 0.8, 1.0))
zc = foot + (H - foot) / 2
bh = H - foot
box('body', (0, 0, zc), (L, W, bh), hull, 0.012)
t = 0.04
for sx in (-1, 1):
    for sy in (-1, 1):
        box('post', (sx * (L / 2 - t / 2 + 0.004), sy * (W / 2 - t / 2 + 0.004), zc), (t + 0.008, t + 0.008, bh), frame, 0.01)
        # chunky corner caps top and bottom
        for z in (foot + 0.045, H - 0.045):
            box('cap', (sx * (L / 2 - 0.045), sy * (W / 2 - 0.045), z), (0.1, 0.1, 0.09), frame, 0.015)
# belt seam under lid
box('seam', (0, 0, H - 0.115), (L + 0.012, W + 0.012, 0.016), frame, 0.004)
box('lid', (0, 0, H + 0.012), (L - 0.04, W - 0.04, 0.035), frame, 0.008)
box('lid_inset', (0, 0, H + 0.032), (L - 0.2, W - 0.2, 0.012), panel, 0.004)
# long-face panels: raised plate + 3 ribs + inset
for sy in (-1, 1):
    for sx in (-1, 1):
        px = sx * 0.235
        box('panel', (px, sy * (W / 2 + 0.006), zc - 0.03), (0.38, 0.014, bh - 0.26), panel, 0.006)
        for k in (-1, 0, 1):
            box('rib', (px, sy * (W / 2 + 0.016), zc - 0.03 + k * 0.09), (0.32, 0.012, 0.025), hull, 0.004)
# yellow label plate + warning bar on each long face center
for sy in (-1, 1):
    box('label', (0, sy * (W / 2 + 0.01), zc - 0.03), (0.13, 0.012, 0.16), accent, 0.004)
    for k in (-1, 1):
        box('labbar', (0, sy * (W / 2 + 0.017), zc - 0.03 + k * 0.045), (0.09, 0.006, 0.02), frame, 0.002)
# glowing status strip on the front, in FRONT of panel, plus lid-side light
box('glow', (0.0, -(W / 2 + 0.03), zc - 0.17), (0.26, 0.006, 0.018), glow, 0.0)
box('glow2', (0.0, (W / 2 + 0.03), zc - 0.17), (0.26, 0.006, 0.018), glow, 0.0)
# end faces: panel + upper carry handles
for sx in (-1, 1):
    box('endpanel', (sx * (L / 2 + 0.006), 0, zc - 0.03), (0.014, W - 0.2, bh - 0.26), panel, 0.006)
    box('endrib', (sx * (L / 2 + 0.016), 0, zc - 0.1), (0.012, 0.3, 0.025), hull, 0.004)
    hz = zc + 0.1
    box('h_bar', (sx * (L / 2 + 0.055), 0, hz), (0.03, 0.26, 0.03), frame, 0.01)
    for sy in (-1, 1):
        box('h_post', (sx * (L / 2 + 0.028), sy * 0.115, hz), (0.056, 0.03, 0.03), frame, 0.008)
# big latches (2 per long side)
for sy in (-1, 1):
    for sx in (-1, 1):
        box('latch', (sx * 0.4, sy * (W / 2 + 0.022), H - 0.14), (0.07, 0.03, 0.12), frame, 0.01)
        box('latch_pin', (sx * 0.4, sy * (W / 2 + 0.042), H - 0.12), (0.03, 0.012, 0.03), accent, 0.004)
for sx in (-1, 1):
    for sy in (-1, 1):
        box('foot', (sx * (L / 2 - 0.07), sy * (W / 2 - 0.07), foot / 2), (0.12, 0.12, foot), frame, 0.008)
VIEWS = [(35, 25, 1.0), (90, 12, 1.0), (215, 30, 1.0)]

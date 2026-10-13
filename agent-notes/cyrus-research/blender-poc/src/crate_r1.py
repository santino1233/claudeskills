# Sci-fi supply crate, 1.0 x 0.6 x 0.6 m, Z up, base on z=0
L, W, H = 1.0, 0.6, 0.6
foot = 0.05
hull = mat('hull', (0.16, 0.20, 0.17), 0.5, 0.55)
frame = mat('frame', (0.07, 0.08, 0.09), 0.9, 0.4)
panel = mat('panel', (0.24, 0.30, 0.25), 0.4, 0.5)
accent = mat('accent', (0.9, 0.7, 0.05), 0.2, 0.5)
glow = mat('glow', (0.1, 0.8, 1.0), 0.0, 0.3, emit=(0.1, 0.8, 1.0))
zc = foot + (H - foot) / 2
bh = H - foot
box('body', (0, 0, zc), (L, W, bh), hull, 0.012)
# frame: 4 vertical corner posts + top/bottom rails
t = 0.05
for sx in (-1, 1):
    for sy in (-1, 1):
        box('post', (sx * (L / 2 - t / 2), sy * (W / 2 - t / 2), zc), (t, t, bh + 0.004), frame, 0.01)
for z in (foot + 0.02, H - 0.02):
    for sy in (-1, 1):
        box('rail_x', (0, sy * (W / 2 - t / 2), z), (L, t, 0.04), frame, 0.008)
    for sx in (-1, 1):
        box('rail_y', (sx * (L / 2 - t / 2), 0, z), (t, W, 0.04), frame, 0.008)
# lid plate
box('lid', (0, 0, H + 0.01), (L - 0.06, W - 0.06, 0.03), frame, 0.006)
# raised panels on long faces (front/back) -- 2 each
for sy in (-1, 1):
    y = sy * (W / 2 + 0.006)
    for sx in (-1, 1):
        box('panel', (sx * 0.24, y, zc), (0.38, 0.016, bh - 0.16), panel, 0.006)
    box('stripe', (0, y + sy * 0.002, zc), (0.1, 0.016, bh - 0.16), accent, 0.004)
# glow strips on front
box('glow', (0, -(W / 2 + 0.012), zc + 0.12), (0.08, 0.004, 0.02), glow, 0.0)
# end panels + handles on short faces
for sx in (-1, 1):
    x = sx * (L / 2 + 0.006)
    box('endpanel', (x, 0, zc), (0.016, W - 0.2, bh - 0.16), panel, 0.006)
    hx = sx * (L / 2 + 0.05)
    box('h_bar', (hx, 0, zc + 0.02), (0.03, 0.22, 0.03), frame, 0.008)
    for sy in (-1, 1):
        box('h_post', (sx * (L / 2 + 0.025), sy * 0.1, zc + 0.02), (0.05, 0.03, 0.03), frame, 0.006)
# latches on front/back
for sy in (-1, 1):
    for sx in (-1, 1):
        box('latch', (sx * 0.42, sy * (W / 2 + 0.02), H - 0.09), (0.07, 0.03, 0.09), frame, 0.008)
# feet
for sx in (-1, 1):
    for sy in (-1, 1):
        box('foot', (sx * (L / 2 - 0.06), sy * (W / 2 - 0.06), foot / 2), (0.1, 0.1, foot), frame, 0.008)
VIEWS = [(35, 25, 1.0), (90, 12, 1.0), (215, 30, 1.0)]

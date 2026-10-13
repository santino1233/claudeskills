# pk_parts.py -- PARTS KIT: reusable variants. Each fn(P, S, A): P=dict of Parts, S=its spec section, A=shared anchor dict.
# Frame: +X muzzle, Z up, bore axis z=0, y=0 centreline, metres. Receiver rear face at x=0.
import math
from mathutils import Vector

def g(S, k, d): return S.get(k, d) if S else d
def shear(pts, k): return [(x + z * k, z) for x, z in pts]

# ---------------- RECEIVERS (set anchors) ----------------
def recv_ak(P, S, A):
    R = P['receiver']; L = g(S, 'length', 0.36); h = g(S, 'height', 0.07); w = g(S, 'width', 0.046); zc = -0.017
    R.box((L / 2, 0, zc), (L, w, h), 'body', 0.004)
    R.cyl((L / 2, 0, 0.014), w / 2 + 0.0005, L - 0.01, 'body', seg=20)
    R.box((L + 0.012, 0, 0.0), (0.04, w - 0.004, 0.06), 'body', 0.005)
    R.box((L * 0.5, w / 2 + 0.002, -0.012), (L * 0.5, 0.004, 0.022), 'dark', 0.002)
    R.cyl((L * 0.62, w / 2 + 0.007, 0.018), 0.006, 0.04, 'dark', axis='y', seg=10)
    R.cyl((L * 0.62, w / 2 + 0.029, 0.018), 0.011, 0.014, 'dark', axis='y', seg=12)
    A.update(x0=0, x1=L + 0.032, z_top=0.0385, zb=zc - h / 2, w=w, zmid=zc, grip_x=0.062, trig_x=0.168, mag_x=L - 0.09,
             mag_z=zc - h / 2 + 0.005, sight_x=L - 0.08, hg_x0=L - 0.005)

def _rail(R, x0, L, z, slot='barrel', wd=0.02):
    R.box((x0 + L / 2, 0, z), (L, wd, 0.008), slot)
    for i in range(int(L / 0.022)):
        R.box((x0 + 0.011 + i * 0.022, 0, z + 0.006), (0.011, wd, 0.005), slot)

def recv_modern(P, S, A):
    R = P['receiver']; L = g(S, 'length', 0.30); w = 0.042
    R.box((L / 2, 0, 0.022), (L, w - 0.004, 0.048), 'body', 0.003)
    R.box((L * 0.45, 0, -0.032), (L * 0.9, w, 0.062), 'body', 0.003)
    R.box((L * 0.68, 0, -0.082), (L * 0.30, w - 0.004, 0.04), 'body', 0.003)
    R.box((L * 0.5, w / 2 - 0.002 + 0.0006, 0.02), (L * 0.26, 0.002, 0.02), 'dark')
    R.box((-0.012, 0, 0.04), (0.03, 0.026, 0.012), 'dark', 0.002)
    R.cyl((L + 0.005, 0, 0), 0.022, 0.02, 'body', seg=16)
    _rail(R, 0.0, L, 0.050)
    A.update(x0=0, x1=L + 0.015, z_top=0.0595, zb=-0.063, w=w, zmid=0.0, grip_x=0.055, trig_x=0.145, mag_x=L * 0.68,
             mag_z=-0.062, sight_x=L * 0.5, hg_x0=L - 0.01)

def recv_smg(P, S, A):
    R = P['receiver']; L = g(S, 'length', 0.27); w = g(S, 'width', 0.05); h = 0.062
    R.box((L / 2, 0, -0.002), (L, w, h), 'body', 0.007)
    R.box((L / 2, 0, h / 2 - 0.002 + 0.0008), (L * 0.9, 0.018, 0.004), 'dark')
    R.box((-0.006, 0, -0.002), (0.02, w - 0.006, h - 0.008), 'body', 0.004)
    R.cyl((L + 0.008, 0, 0), 0.028, 0.02, 'body', seg=16)
    R.box((L * 0.4, w / 2 + 0.0006, 0.004), (L * 0.22, 0.002, 0.018), 'dark')
    R.cyl((L * 0.55, w / 2 + 0.008, 0.012), 0.005, 0.016, 'dark', axis='y', seg=8)
    R.cyl((L * 0.55, w / 2 + 0.02, 0.012), 0.009, 0.01, 'dark', axis='y', seg=10)
    gx = L * 0.55
    A.update(x0=0, x1=L + 0.018, z_top=h / 2 - 0.002, zb=-0.002 - h / 2, w=w, zmid=-0.002, grip_x=gx, trig_x=gx + 0.075,
             mag_x=gx, mag_z=-0.002 - h / 2, sight_x=L * 0.15, hg_x0=L - 0.01, mag_in_grip=True)

def recv_bullpup(P, S, A):
    R = P['receiver']; L = g(S, 'length', 0.52); w = g(S, 'width', 0.05)
    pts = [(0, 0.04), (0.04, 0.06), (L * 0.55, 0.06), (L, 0.054), (L, -0.05), (L * 0.6, -0.06), (L * 0.33, -0.072), (0.03, -0.085), (0, -0.075)]
    R.prism(pts, w, 'body', 0.005)
    R.box((L * 0.34, w / 2 + 0.0006, 0.0), (L * 0.14, 0.002, 0.04), 'dark')
    if g(S, 'rail', True): _rail(R, L * 0.2, L * 0.7, 0.062)
    gx = L * 0.52
    A.update(x0=0, x1=L, z_top=0.0725 if g(S, 'rail', True) else 0.06, zb=-0.07, w=w, zmid=-0.01, grip_x=gx, trig_x=gx + 0.075,
             mag_x=gx - 0.115, mag_z=-0.07, sight_x=L * 0.42, hg_x0=L - 0.02, bullpup=True)
RECV = {'ak_stamped': recv_ak, 'modern_slab': recv_modern, 'smg_boxy': recv_smg, 'bullpup_shell': recv_bullpup}

# ---------------- GRIPS ----------------
def grip_ak(P, S, A):
    ln = g(S, 'length', 0.14); rk = g(S, 'rake', 0.38); zb = A['zb']
    P['grip'].box((A['grip_x'], 0, zb - ln / 2 + 0.018), (0.048, 0.046, ln), 'furniture', 0.009, rot=(0, rk, 0))
    A['grip_rake'] = rk
def grip_poly(P, S, A):
    ln = g(S, 'length', 0.13); rk = g(S, 'rake', 0.30); s = ln / 0.13; wd = g(S, 'width', 0.042)
    pts = [(-0.022, 0.01), (0.026, 0.01), (0.027, -0.03 * s), (0.022, -0.055 * s), (0.03, -0.085 * s), (0.022, -ln), (-0.03, -ln), (-0.026, -0.09 * s), (-0.032, -0.05 * s), (-0.024, -0.02 * s)]
    pts = [(x + A['grip_x'], z + A['zb'] + 0.01) for x, z in shear(pts, math.tan(rk))]
    P['grip'].prism(pts, wd, 'furniture', 0.004); A['grip_rake'] = rk
def grip_vertical(P, S, A):
    ln = g(S, 'length', 0.11)
    P['grip'].box((A['grip_x'], 0, A['zb'] - ln / 2 + 0.01), (0.044, 0.04, ln), 'furniture', 0.006)
    P['grip'].box((A['grip_x'], 0, A['zb'] - ln + 0.012), (0.05, 0.046, 0.012), 'dark', 0.003); A['grip_rake'] = 0.0
def grip_none(P, S, A): A['grip_rake'] = 0.0
GRIP = {'ak_slanted': grip_ak, 'raked_poly': grip_poly, 'vertical': grip_vertical, 'none': grip_none}

def trigger_guard(P, S, A):
    G = P['grip']; tx = A['trig_x']; zb = A['zb']; s = g(S, 'guard_scale', 1.0)
    dx = [-0.058, -0.056, -0.038, 0.027, 0.046, 0.048, 0.04, 0.038, 0.024, -0.036, -0.048, -0.05]
    dz = [0.006, -0.042, -0.053, -0.053, -0.035, 0.006, 0.006, -0.033, -0.045, -0.045, -0.037, 0.006]
    G.prism([(tx + x * s, zb + z * s) for x, z in zip(dx, dz)], 0.012, 'barrel', 0.0015)
    G.box((tx, 0, zb - 0.022), (0.006, 0.006, 0.034), 'barrel', 0.0015, rot=(0, -0.3, 0))

# ---------------- MAGAZINES ----------------
def mag_curved(P, S, A):
    cap = g(S, 'capacity', 30); arc = g(S, 'arc_length', 0.10 + cap * 0.0036); deg = g(S, 'curve_deg', 46); w = g(S, 'width', 0.04)
    R = arc / math.radians(deg); x0, z0 = A['mag_x'], A['mag_z']; N = 10; back, front = [], []
    for i in range(N + 1):
        ph = math.radians(deg) * i / N; cx, cz = x0 + R * (1 - math.cos(ph)), z0 - R * math.sin(ph)
        nx, nz = math.cos(ph), math.sin(ph); h = 0.026 + 0.008 * i / N
        back.append((cx - nx * h, cz - nz * h)); front.append((cx + nx * h, cz + nz * h))
    P['magazine'].prism(back + front[::-1], w, 'mag', 0.004)
    ph = math.radians(deg) * 0.5; A['mag_mid'] = (x0 + R * (1 - math.cos(ph)), z0 - R * math.sin(ph), -ph, w)
def mag_box(P, S, A):
    cap = g(S, 'capacity', 30); ln = g(S, 'length', 0.06 + cap * 0.0055); hd = g(S, 'depth', 0.024); w = g(S, 'width', 0.038)
    c = math.radians(g(S, 'cant_deg', 8))
    if A.get('mag_in_grip'): c = -A.get('grip_rake', 0.0); hd = min(hd, 0.02); w = min(w, 0.036)
    T = Vector((A['mag_x'], A['mag_z'])); d = Vector((math.sin(c), -math.cos(c))); n = Vector((math.cos(c), math.sin(c))); B = T + d * ln
    pts = [tuple(T - n * hd), tuple(T + n * hd), tuple(B + n * hd), tuple(B - n * hd)]
    P['magazine'].prism(pts, w, 'mag', 0.003)
    P['magazine'].box((B.x, 0, B.y + 0.004), (hd * 2 + 0.006, w + 0.004, 0.014), 'mag', 0.002, rot=(0, -c, 0))
    M = (T + B) / 2; A['mag_mid'] = (M.x, M.y, -c, w); A['mag_len'] = ln
def mag_drum(P, S, A):
    cap = g(S, 'capacity', 50); R = g(S, 'radius', 0.05 + cap * 0.0006); w = g(S, 'width', 0.055); cx, cz = A['mag_x'] + 0.012, A['mag_z'] - R - 0.022
    M = P['magazine']
    M.box((A['mag_x'], 0, A['mag_z'] - 0.012), (0.04, 0.04, 0.03), 'mag', 0.003)
    M.cyl((cx, 0, cz), R, w, 'mag', axis='y', seg=24, bevel=0.004)
    for sgn in (-1, 1): M.cyl((cx, sgn * (w / 2 - 0.002), cz), R * 0.8, 0.006, 'accent', axis='y', seg=20)
    M.cyl((cx, 0, cz), 0.018, w + 0.012, 'accent', axis='y', seg=12)
    A['mag_mid'] = (cx, cz, 0.0, w); A['mag_drum'] = True
MAG = {'curved': mag_curved, 'straight_box': mag_box, 'drum': mag_drum}

# ---------------- STOCKS ----------------
def stock_wood(P, S, A):
    Ls = g(S, 'length', 0.22); w = g(S, 'width', 0.04); St = P['stock']
    St.prism([(0.01, 0.03), (0.01 - Ls, 0.012), (0.005 - Ls, -0.112), (0.01 - 0.59 * Ls, -0.09), (0.01, -0.064)], w, 'furniture', 0.006)
    St.box((0.008 - Ls, 0, -0.05), (0.012, 0.042, 0.134), 'barrel', 0.003, rot=(0, -0.05, 0)); A['stock_len'] = Ls
def stock_poly(P, S, A):
    L = g(S, 'length', 0.24); w = g(S, 'width', 0.044); St = P['stock']
    St.cyl((-L * 0.25, 0, -0.004), 0.019, L * 0.6, 'body', seg=12)
    St.prism([(-L * 0.4, 0.04), (-L * 0.4, 0.05), (-L, 0.058), (-L, -0.09), (-L + 0.02, -0.095), (-L * 0.62, -0.04), (-L * 0.4, -0.03)], w, 'furniture', 0.004)
    St.box((-L - 0.004, 0, -0.016), (0.012, w + 0.004, 0.158), 'dark', 0.004); A['stock_len'] = L
def stock_wire(P, S, A):
    L = g(S, 'length', 0.24); St = P['stock']; wy = A['w'] / 2 + 0.008; zm = A['zmid'] + 0.012; folded = g(S, 'folded', False)
    sg = 1 if folded else -1; r = 0.0042; zb = zm - 0.075; xe = sg * L
    for s in (-1, 1):
        St.rod((0, s * wy, zm), (xe, s * wy, zm), r, 'barrel'); St.rod((xe * 0.35, s * wy, zm), (xe, s * wy, zb + 0.01), r, 'barrel')
        St.cyl((0.0, s * wy, zm), 0.009, 0.014, 'barrel', seg=10)
    St.rod((xe, -wy, zb + 0.01), (xe, wy, zb + 0.01), r, 'barrel')
    St.box((xe + sg * 0.004, 0, zm - 0.036), (0.012, wy * 2 + 0.01, 0.094), 'dark', 0.003); A['stock_len'] = L
def stock_strut(P, S, A):
    L = g(S, 'length', 0.22); St = P['stock']; wy = A['w'] / 2 + 0.01; zm = A['zmid']; folded = g(S, 'folded', False)
    sg = 1 if folded else -1; xe = sg * L
    for s in (-1, 1):
        St.box((xe / 2, s * wy, zm + 0.008), (L, 0.01, 0.02), 'body', 0.003)
        St.cyl((0, s * wy, zm + 0.008), 0.014, 0.016, 'barrel', axis='y', seg=14)
    St.prism([(xe, zm + 0.04), (xe + sg * 0.012, zm + 0.04), (xe + sg * 0.02, zm - 0.07), (xe, zm - 0.075)], 2 * wy, 'dark', 0.003)
    A['stock_len'] = L
def stock_bullpup(P, S, A):
    St = P['stock']; zm = A['zmid']
    St.box((-0.012, 0, zm - 0.02), (0.026, A['w'] + 0.006, 0.14), 'dark', 0.006)
    St.prism([(0.02, 0.06), (0.16, 0.06), (0.2, 0.074), (0.02, 0.074)], A['w'] - 0.008, 'furniture', 0.004); A['stock_len'] = 0.0
def stock_none(P, S, A):
    P['stock'].cyl((-0.006, 0, 0), 0.02, 0.012, 'body', seg=12); A['stock_len'] = 0.0
STOCK = {'fixed_wood': stock_wood, 'fixed_poly': stock_poly, 'folding_wire': stock_wire, 'folding_strut': stock_strut, 'bullpup_integral': stock_bullpup, 'none': stock_none}

# ---------------- HANDGUARDS ----------------
def hg_wood(P, S, A):
    H = P['handguard']; x = A['hg_x0']; Lh = g(S, 'length', 0.27)
    H.cyl((x + Lh * 0.315, 0, 0.028), 0.0215, Lh * 0.63, 'furniture', seg=18)
    H.box((x + Lh / 2, 0, -0.014), (Lh, 0.046, 0.052), 'furniture', 0.008)
    for k in range(4): H.box((x + 0.045 + k * 0.045 * Lh / 0.27, 0, -0.042), (0.012, 0.05, 0.006), 'barrel', 0.0015)
    A.update(hg_x1=x + Lh, hg_w=0.025, hg_zmid=-0.014, hg_covers_gas=True)
def hg_quad(P, S, A):
    H = P['handguard']; x = A['hg_x0']; Lh = g(S, 'length', 0.26); r = 0.0255
    H.cyl((x + Lh / 2, 0, 0), r, Lh, 'body', seg=16)
    for ang in range(4):
        a = ang * math.pi / 2; cy, cz = math.sin(a) * (r + 0.003), math.cos(a) * (r + 0.003)
        wy, wz = (0.018, 0.006) if ang % 2 == 0 else (0.006, 0.018)
        H.box((x + Lh / 2, cy, cz), (Lh, wy, wz), 'barrel')
        for i in range(int(Lh / 0.022)):
            H.box((x + 0.011 + i * 0.022, cy * 1.0 + math.sin(a) * 0.004, cz + math.cos(a) * 0.004), (0.011, wy, wz) if ang % 2 == 0 else (0.011, wy, wz), 'barrel')
    A.update(hg_x1=x + Lh, hg_w=r + 0.006, hg_zmid=0.0, hg_covers_gas=False)
def hg_slim(P, S, A):
    H = P['handguard']; x = A['hg_x0']; Lh = g(S, 'length', 0.24)
    pts = [(-0.021, 0.024), (0.021, 0.024), (0.030, 0.002), (0.024, -0.026), (-0.024, -0.026), (-0.030, 0.002)]
    H.prism(pts, Lh, g(S, 'material', 'furniture'), 0.003, plane='yz', c=x)
    for i in range(int(Lh / 0.045) - 1):
        for s in (-1, 1): H.box((x + 0.04 + i * 0.045, s * 0.0292, 0.002), (0.022, 0.002, 0.012), 'dark')
    A.update(hg_x1=x + Lh, hg_w=0.03, hg_zmid=0.002, hg_covers_gas=False)
def hg_shroud(P, S, A):
    H = P['handguard']; x = A['hg_x0']; Lh = g(S, 'length', 0.20); r = 0.024
    H.cyl((x + Lh / 2, 0, 0), r, Lh, 'body', seg=16)
    for i in range(int(Lh / 0.022)): H.cyl((x + 0.012 + i * 0.022, 0, 0), r + 0.0025, 0.006, 'barrel', seg=16)
    A.update(hg_x1=x + Lh, hg_w=r + 0.003, hg_zmid=0.0, hg_covers_gas=False)
def hg_none(P, S, A): A.update(hg_x1=A['x1'], hg_w=0.02, hg_zmid=0.0, hg_covers_gas=False)
HAND = {'wood_ak': hg_wood, 'rail_quad': hg_quad, 'slim_poly': hg_slim, 'ribbed_shroud': hg_shroud, 'none': hg_none}

# ---------------- BARREL + MUZZLE + GAS ----------------
def barrel(P, S, A, gas):
    B = P['barrel']; Lb = g(S, 'length', 0.42); r = g(S, 'radius', 0.0115); prof = g(S, 'profile', 'plain'); bx = A['x1'] - 0.01; mx = A['x1'] + Lb
    xc = (bx + mx) / 2; ln = mx - bx
    if prof == 'tapered': B.cyl((xc, 0, 0), r * 1.6, ln, 'barrel', r2=r, seg=16)
    elif prof == 'heavy': B.cyl((xc, 0, 0), r * 1.4, ln, 'barrel', seg=16)
    elif prof == 'shrouded':
        B.cyl((xc, 0, 0), r, ln, 'barrel', seg=16); B.cyl((bx + ln * 0.33, 0, 0), r * 2.3, ln * 0.66, 'body', seg=16, bevel=0.003)
    else: B.cyl((xc, 0, 0), r, ln, 'barrel', seg=16)
    mz = g(S, 'muzzle', 'brake'); A['muzzle_x'] = mx
    if mz == 'brake':
        B.cyl((mx + 0.025, 0, 0), r * 1.3, 0.05, 'barrel', seg=16, bevel=0.002)
        for dx in (0.015, 0.03): B.cyl((mx + dx, 0, 0), r * 1.32, 0.004, 'dark', seg=16)
    elif mz == 'flash_hider':
        B.cyl((mx + 0.03, 0, 0), r * 1.35, 0.06, 'barrel', r2=r * 1.1, seg=12)
        B.box((mx + 0.045, 0, 0), (0.028, r * 3.0, 0.003), 'dark'); B.box((mx + 0.045, 0, 0), (0.028, 0.003, r * 3.0), 'dark')
    elif mz == 'suppressor':
        sl = g(S, 'suppressor_length', 0.17); B.cyl((mx - 0.01 + sl / 2, 0, 0), r * 3.0, sl, 'body', seg=18, bevel=0.003)
        B.cyl((mx - 0.01 + sl + 0.002, 0, 0), r * 3.05, 0.004, 'dark', seg=18)
    else: B.cyl((mx + 0.006, 0, 0), r * 1.15, 0.012, 'barrel', seg=14)
    if gas:
        gx = mx - min(0.13, Lb * 0.35); z = r + 0.0225; x_s = A['hg_x1'] - (0.03 if A.get('hg_covers_gas') else 0.005)
        B.box((gx, 0, 0.014), (0.04, 0.03, 0.056), 'barrel', 0.005)
        B.rod((min(x_s, gx - 0.05), 0, z), (gx + 0.02, 0, z), 0.0135, 'barrel', seg=14)
    A['gas'] = gas

# ---------------- SIGHTS ----------------
def sights(P, S, A, r):
    Sg = P['sights']; fr = g(S, 'front', 'post'); rr = g(S, 'rear', 'tangent'); xf = A['muzzle_x'] - 0.065; zt = r + 0.022
    if fr in ('post', 'hooded'):
        Sg.box((xf, 0, 0.011), (0.026, 0.016, r * 2 + 0.022), 'barrel', 0.003)
        Sg.box((xf, 0, zt + 0.009), (0.004, 0.004, 0.02), 'barrel')
        if fr == 'hooded':
            for s in (-1, 1): Sg.box((xf, s * 0.0085, zt + 0.012), (0.016, 0.003, 0.03), 'barrel', 0.001)
    x, z = A['sight_x'], A['z_top']
    if rr == 'tangent':
        Sg.box((x, 0, z + 0.008), (0.03, 0.02, 0.016), 'barrel', 0.003); Sg.box((x + 0.015, 0, z + 0.019), (0.004, 0.014, 0.012), 'barrel')
    elif rr == 'notch':
        Sg.box((x, 0, z + 0.005), (0.024, 0.02, 0.01), 'barrel', 0.002)
        for s in (-1, 1): Sg.box((x, s * 0.007, z + 0.014), (0.012, 0.004, 0.018), 'barrel', 0.001)
    elif rr == 'carry_handle':
        for dx in (-0.045, 0.045): Sg.box((x + dx, 0, z + 0.02), (0.014, 0.02, 0.04), 'body', 0.003)
        Sg.box((x, 0, z + 0.046), (0.11, 0.024, 0.012), 'body', 0.004); Sg.box((x - 0.04, 0, z + 0.055), (0.006, 0.012, 0.008), 'dark')
    elif rr == 'red_dot':
        Sg.box((x, 0, z + 0.006), (0.05, 0.03, 0.012), 'body', 0.002); Sg.box((x, 0, z + 0.034), (0.056, 0.034, 0.044), 'body', 0.005)
        for s in (-1, 1): Sg.box((x + s * 0.0285, 0, z + 0.036), (0.002, 0.026, 0.032), 'accent')
    A['sight_top'] = z

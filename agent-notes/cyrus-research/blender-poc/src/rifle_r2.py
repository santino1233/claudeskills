# Stylised AK-style rifle, ~1.0 m long, +X = muzzle, Z up, receiver centreline z=0
JOIN_BY_MATERIAL = True
RES = (768, 480)
steel = mat('steel', (0.035, 0.04, 0.045), 0.9, 0.35)
wood = mat('wood', (0.19, 0.065, 0.02), 0.0, 0.5)
mag_m = mat('mag', (0.02, 0.022, 0.025), 0.6, 0.45)
def prism(name, pts, w, m, bevel=0.0):
    n = len(pts)
    v = [(x, -w / 2, z) for x, z in pts] + [(x, w / 2, z) for x, z in pts]
    f = [list(range(n))[::-1], list(range(n, 2 * n))]
    for i in range(n): f.append([i, (i + 1) % n, n + (i + 1) % n, n + i])
    return from_pydata(name, v, f, m, bevel)
X = (math.pi / 2, 0, 0); Y = (0, math.pi / 2, 0)   # rotations: cylinder along Y / along X
# stock
prism('stock', [(-0.27, 0.042), (-0.49, 0.024), (-0.495, -0.10), (-0.40, -0.078), (-0.27, -0.052)], 0.04, wood, 0.006)
box('buttplate', (-0.5, 0, -0.038), (0.012, 0.042, 0.134), steel, 0.003, rot=(0, -0.05, 0))
# receiver + dust cover
box('receiver', (-0.10, 0, -0.005), (0.36, 0.046, 0.07), steel, 0.004)
cyl('cover', (-0.10, 0, 0.026), 0.0235, 0.34, steel, rot=Y, verts=20)
box('rear_sight', (0.0, 0, 0.056), (0.03, 0.02, 0.016), steel, 0.003)
# pistol grip + trigger guard
box('grip', (-0.222, 0, -0.098), (0.046, 0.044, 0.125), wood, 0.009, rot=(0, 0.38, 0))
prism('trigger_guard', [(-0.17, -0.034), (-0.168, -0.082), (-0.15, -0.093), (-0.085, -0.093), (-0.066, -0.075), (-0.064, -0.034), (-0.072, -0.034), (-0.074, -0.073), (-0.088, -0.085), (-0.148, -0.085), (-0.16, -0.077), (-0.162, -0.034)], 0.012, steel, 0.0015)
box('trigger', (-0.112, 0, -0.062), (0.006, 0.006, 0.034), steel, 0.0015, rot=(0, -0.3, 0))
# curved magazine (banana) -- profile swept in XZ then extruded
R, x0, z0 = 0.25, -0.01, -0.035
back, front = [], []
N = 10
for i in range(N + 1):
    ph = math.radians(46) * i / N
    cx, cz = x0 + R * (1 - math.cos(ph)), z0 - R * math.sin(ph)
    nx, nz = math.cos(ph), math.sin(ph); h = 0.026 + 0.008 * i / N
    back.append((cx - nx * h, cz - nz * h)); front.append((cx + nx * h, cz + nz * h))
prism('magazine', back + front[::-1], 0.04, mag_m, 0.004)
box('trunnion', (0.09, 0, 0.012), (0.04, 0.042, 0.06), steel, 0.005)
# barrel, muzzle brake, gas block, gas tube, handguards, sight, cleaning rod
cyl('barrel', (0.30, 0, 0.012), 0.0115, 0.44, steel, rot=Y, verts=16)
cyl('muzzle', (0.475, 0, 0.012), 0.0145, 0.05, steel, rot=Y, verts=16)
box('gas_block', (0.37, 0, 0.026), (0.035, 0.026, 0.05), steel, 0.004)
cyl('gas_tube', (0.30, 0, 0.044), 0.0125, 0.14, steel, rot=Y, verts=16)
cyl('upper_hg', (0.16, 0, 0.040), 0.0215, 0.17, wood, rot=Y, verts=18)
box('lower_hg', (0.20, 0, -0.002), (0.25, 0.044, 0.05), wood, 0.008)
box('front_sight', (0.435, 0, 0.034), (0.026, 0.016, 0.05), steel, 0.003)
box('sight_post', (0.435, 0, 0.066), (0.004, 0.004, 0.02), steel, 0.0)
cyl('rod', (0.40, 0, -0.016), 0.004, 0.12, steel, rot=Y, verts=8)
# right-side details: safety lever + bolt handle
box('safety', (-0.09, 0.025, 0.0), (0.18, 0.004, 0.022), steel, 0.002)
cyl('bolt_stem', (-0.02, 0.03, 0.03), 0.006, 0.04, steel, rot=X, verts=10)
cyl('bolt_knob', (-0.02, 0.052, 0.03), 0.011, 0.014, steel, rot=X, verts=12)
VIEWS = [(0, 5, 0.78), (35, 25, 0.85), (0, 82, 0.8)]

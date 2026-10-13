# pk_rifle.py -- PARAMETRIC RIFLE TEMPLATE. build(spec_dict) -> (list of bpy objects, info). The AI step only emits `spec`.
import math, bpy
from pk_geo import Part, make_materials
from pk_parts import RECV, GRIP, MAG, STOCK, HAND, barrel, sights, trigger_guard, g

PART_NAMES = ['receiver', 'grip', 'magazine', 'stock', 'handguard', 'barrel', 'sights', 'trim']
def pick(table, S, key, default):
    st = (S or {}).get('style', default)
    if st not in table: raise ValueError(f'{key}.style={st!r} not in {sorted(table)}')
    return table[st]

def accents(P, A, lst, glow='glow'):
    T = P['trim']; w = A['w']
    for a in lst or []:
        if a == 'receiver_side':
            for s in (-1, 1): T.box(((A['x0'] + A['x1']) / 2 + 0.02, s * (w / 2 + 0.0008), A['zmid'] + 0.012), ((A['x1'] - A['x0']) * 0.5, 0.0016, 0.006), glow)
        elif a == 'receiver_top':
            T.box(((A['x0'] + A['x1']) / 2, 0, A['z_top'] + 0.0006), ((A['x1'] - A['x0']) * 0.6, 0.006, 0.0016), glow)
        elif a == 'handguard_side':
            for s in (-1, 1): T.box(((A['hg_x0'] + A['hg_x1']) / 2 + 0.01, s * (A['hg_w'] + 0.0006), A['hg_zmid'] + 0.002), (A['hg_x1'] - A['hg_x0'] - 0.06, 0.0016, 0.006), glow)
        elif a == 'magazine_window' and 'mag_mid' in A:
            x, z, rot, mw = A['mag_mid']
            for s in (-1, 1): T.box((x, s * (mw / 2 + 0.0006), z), (0.008, 0.0016, 0.07), glow, rot=(0, rot, 0))
        elif a == 'stock_side' and A.get('stock_len', 0) > 0:
            for s in (-1, 1): T.box((-A['stock_len'] * 0.5, s * 0.0215, 0.0), (A['stock_len'] * 0.5, 0.0016, 0.006), glow)
        elif a == 'barrel_ring':
            T.cyl((A['muzzle_x'] - 0.03, 0, 0), g(A.get('_b'), 'radius', 0.0115) * 1.5, 0.006, glow, seg=16)
        else: raise ValueError(f'accent {a!r} unknown/unavailable')

def build(spec):
    P = {n: Part(n) for n in PART_NAMES}; A = {}
    pick(RECV, spec.get('receiver'), 'receiver', 'ak_stamped')(P, spec.get('receiver', {}), A)
    GS = spec.get('grip', {}); pick(GRIP, GS, 'grip', 'ak_slanted')(P, GS, A)
    if GS.get('style') != 'none' and spec.get('trigger_guard', True): trigger_guard(P, GS, A)
    MS = spec.get('magazine', {}); pick(MAG, MS, 'magazine', 'curved')(P, MS, A)
    SS = spec.get('stock', {}); pick(STOCK, SS, 'stock', 'fixed_wood')(P, SS, A)
    HS = spec.get('handguard', {}); pick(HAND, HS, 'handguard', 'wood_ak')(P, HS, A)
    BS = spec.get('barrel', {}); A['_b'] = BS
    if 'hg_x0' in HS: pass
    barrel(P, BS, A, bool(spec.get('gas_tube', False)))
    sights(P, spec.get('sights', {}), A, g(BS, 'radius', 0.0115))
    accents(P, A, spec.get('accents'))
    mats = make_materials(spec.get('palette'))
    objs = []
    for n in PART_NAMES:
        if len(P[n].bm.faces): objs.append(P[n].to_object(mats))
        else: P[n].bm.free()
    return objs, A

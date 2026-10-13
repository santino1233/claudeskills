# pk_geo.py -- low-level geometry kit: closed bmesh primitives accumulated into named Parts, material slots per face.
import bpy, bmesh, math
from mathutils import Matrix, Vector, Euler

SLOTS = ['body', 'furniture', 'barrel', 'mag', 'accent', 'glow', 'dark']
SIDX = {s: i for i, s in enumerate(SLOTS)}
DEFAULT_PAL = {  # slot: (hex, metallic, roughness, emission strength)
    'body': ('#3a3d42', 0.8, 0.40, 0), 'furniture': ('#6b3a1c', 0.0, 0.5, 0), 'barrel': ('#1c1e21', 0.9, 0.35, 0),
    'mag': ('#16181b', 0.6, 0.45, 0), 'accent': ('#8a8f98', 0.5, 0.4, 0), 'glow': ('#00e5ff', 0.0, 0.3, 6.0),
    'dark': ('#0b0c0e', 0.2, 0.7, 0)}

def hex2lin(h):
    h = h.lstrip('#'); return tuple((int(h[i:i + 2], 16) / 255.0) ** 2.2 for i in (0, 2, 4))

def make_materials(pal):
    mats = []
    for s in SLOTS:
        d = DEFAULT_PAL[s]; hx, me, ro, em = d
        v = (pal or {}).get(s)
        if isinstance(v, str): hx = v
        elif isinstance(v, dict):
            hx = v.get('color', hx); me = v.get('metal', me); ro = v.get('rough', ro); em = v.get('emit', em)
        m = bpy.data.materials.new('mat_' + s); m.use_nodes = True
        b = m.node_tree.nodes['Principled BSDF']; c = hex2lin(hx)
        b.inputs['Base Color'].default_value = (*c, 1); b.inputs['Metallic'].default_value = me; b.inputs['Roughness'].default_value = ro
        if em:
            b.inputs['Emission Color'].default_value = (*c, 1); b.inputs['Emission Strength'].default_value = em
        mats.append(m)
    return mats

def _bevel(bm, w, ang=35):
    if w <= 0: return
    es = [e for e in bm.edges if len(e.link_faces) == 2 and e.calc_face_angle(0) > math.radians(ang)]
    if es: bmesh.ops.bevel(bm, geom=es, offset=w, segments=1, profile=0.5, affect='EDGES', clamp_overlap=True)

def _M(loc, rot):
    return Matrix.Translation(loc) @ Euler(rot, "XYZ").to_matrix().to_4x4()

class Part:
    def __init__(self, name):
        self.name = name; self.bm = bmesh.new()
    def _add(self, src, slot, M=None):
        bmesh.ops.recalc_face_normals(src, faces=src.faces)
        if M is not None: bmesh.ops.transform(src, matrix=M, verts=src.verts)
        vm = {v: self.bm.verts.new(v.co) for v in src.verts}; idx = SIDX[slot]
        for f in src.faces:
            nf = self.bm.faces.new([vm[v] for v in f.verts]); nf.material_index = idx
        src.free()
    def box(self, c, dim, slot, bevel=0.0, rot=(0, 0, 0)):
        bm = bmesh.new(); bmesh.ops.create_cube(bm, size=1.0)
        bmesh.ops.scale(bm, vec=Vector(dim), verts=bm.verts)
        _bevel(bm, min(bevel, min(dim) * 0.3)); self._add(bm, slot, _M(c, rot))
    def cyl(self, c, r, length, slot, axis='x', r2=None, seg=16, bevel=0.0, rot=(0, 0, 0)):
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=seg, radius1=r, radius2=r if r2 is None else r2, depth=length, calc_uvs=False)
        _bevel(bm, min(bevel, r * 0.5, length * 0.3))
        base = {'x': Matrix.Rotation(math.pi / 2, 4, 'Y'), 'y': Matrix.Rotation(-math.pi / 2, 4, 'X'), 'z': Matrix.Identity(4)}[axis]
        self._add(bm, slot, _M(c, rot) @ base)
    def rod(self, p0, p1, r, slot, seg=8):
        p0 = Vector(p0); p1 = Vector(p1); d = p1 - p0
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=seg, radius1=r, radius2=r, depth=d.length, calc_uvs=False)
        q = Vector((0, 0, 1)).rotation_difference(d.normalized())
        self._add(bm, slot, Matrix.Translation((p0 + p1) / 2) @ q.to_matrix().to_4x4())
    def prism(self, pts, w, slot, bevel=0.0, plane='xz', c=0.0):
        """plane 'xz': pts=(x,z), extruded across y by w centred on y=c.  plane 'yz': pts=(y,z), extruded along x from c to c+w."""
        bm = bmesh.new(); n = len(pts)
        if plane == 'xz':
            a = [bm.verts.new((x, c - w / 2, z)) for x, z in pts]; b = [bm.verts.new((x, c + w / 2, z)) for x, z in pts]
        else:
            a = [bm.verts.new((c, y, z)) for y, z in pts]; b = [bm.verts.new((c + w, y, z)) for y, z in pts]
        bm.faces.new(a); bm.faces.new(b[::-1])
        for i in range(n):
            j = (i + 1) % n; bm.faces.new((a[i], a[j], b[j], b[i]))
        _bevel(bm, min(bevel, w * 0.3)); self._add(bm, slot)
    def to_object(self, mats, sharp_deg=35):
        bm = self.bm
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        for f in bm.faces: f.smooth = True
        for e in bm.edges:
            if len(e.link_faces) != 2 or e.calc_face_angle(0) > math.radians(sharp_deg): e.smooth = False
        me = bpy.data.meshes.new(self.name); bm.to_mesh(me); bm.free()
        for m in mats: me.materials.append(m)
        ob = bpy.data.objects.new(self.name, me); bpy.context.collection.objects.link(ob)
        return ob

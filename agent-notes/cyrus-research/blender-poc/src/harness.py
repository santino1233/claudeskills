# harness.py -- the fixed "AI mesh step" runner. Usage: blender -b --factory-startup --python harness.py -- PROP.py NAME
import bpy, bmesh, sys, os, math, time, json
import numpy as np
from mathutils import Vector

argv = sys.argv[sys.argv.index('--') + 1:]
PROP, NAME = argv[0], argv[1]
IN = os.path.dirname(os.path.abspath(__file__))
OUT = os.getcwd()  # sandbox work dir
t0 = time.time()

# ---------- clean scene ----------
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete()
for blk in (bpy.data.meshes, bpy.data.materials, bpy.data.lights, bpy.data.cameras):
    for b in list(blk): blk.remove(b)

# ---------- tiny prelude helpers (what a model would write itself; shared to save tokens) ----------
_mats = {}
def mat(name, rgb, metal=0.0, rough=0.5, emit=None):
    if name in _mats: return _mats[name]
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*rgb, 1)
    b.inputs['Metallic'].default_value = metal; b.inputs['Roughness'].default_value = rough
    if emit:
        b.inputs['Emission Color'].default_value = (*emit, 1); b.inputs['Emission Strength'].default_value = 3.0
    _mats[name] = m; return m

def finish(o, m, bevel=0.0, seg=2, smooth=True):
    o.data.materials.append(m)
    if bevel > 0:
        bv = o.modifiers.new('bevel', 'BEVEL'); bv.width = bevel; bv.segments = seg; bv.limit_method = 'ANGLE'
        bpy.context.view_layer.objects.active = o; o.select_set(True)
        bpy.ops.object.modifier_apply(modifier='bevel'); o.select_set(False)
    if smooth:
        o.data.polygons.foreach_set('use_smooth', [True] * len(o.data.polygons))
        if hasattr(o.data, 'shade_auto_smooth'): pass
    return o

def box(name, loc, dim, m, bevel=0.0, rot=(0, 0, 0), seg=2):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object; o.name = name; o.scale = dim
    bpy.ops.object.transform_apply(scale=True, rotation=False)
    return finish(o, m, bevel, seg, smooth=False)

def cyl(name, loc, r, depth, m, rot=(0, 0, 0), verts=24, bevel=0.0, r2=None):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=loc, rotation=rot)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r2, depth=depth, location=loc, rotation=rot)
    o = bpy.context.active_object; o.name = name
    return finish(o, m, bevel, 2, smooth=False)

def from_pydata(name, verts, faces, m, bevel=0.0, solidify=0.0):
    me = bpy.data.meshes.new(name); me.from_pydata(verts, [], faces); me.update()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o)
    bpy.context.view_layer.objects.active = o; o.select_set(True)
    if solidify:
        s = o.modifiers.new('sol', 'SOLIDIFY'); s.thickness = solidify; s.offset = 0
        bpy.ops.object.modifier_apply(modifier='sol')
    o.select_set(False)
    return finish(o, m, bevel, 2, smooth=False)

# ---------- run the model-written script ----------
ns = dict(globals())
exec(compile(open(os.path.join(IN, PROP)).read(), PROP, 'exec'), ns)
VIEWS = ns.get('VIEWS', [(35, 25, 1.0), (90, 10, 1.0), (180, 25, 1.0)])  # (azimuth deg, elevation deg, dist mult)
t_build = time.time() - t0

objs = [o for o in bpy.data.objects if o.type == 'MESH']
if ns.get('JOIN_BY_MATERIAL'):
    groups = {}
    for o in objs: groups.setdefault(o.data.materials[0].name if o.data.materials else '', []).append(o)
    for k, g in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in g: o.select_set(True)
        bpy.context.view_layer.objects.active = g[0]; bpy.ops.object.join(); g[0].name = 'mesh_' + k
    objs = [o for o in bpy.data.objects if o.type == 'MESH']

# ---------- UVs ----------
for o in objs:
    if not o.data.uv_layers:
        bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active = o
        bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02)
        bpy.ops.object.mode_set(mode='OBJECT')

# ---------- stats ----------
dg = bpy.context.evaluated_depsgraph_get()
stats = dict(objects=len(objs), tris=0, nonmanifold_objs=0, nonmanifold_edges=0, uv_objs=0, loose_objs=[], per_obj={})
lo = Vector((1e9,) * 3); hi = Vector((-1e9,) * 3)
for o in objs:
    bm = bmesh.new(); bm.from_mesh(o.data); bm.transform(o.matrix_world)
    tris = sum(len(f.verts) - 2 for f in bm.faces)
    nm = sum(1 for e in bm.edges if not e.is_manifold)
    stats['tris'] += tris; stats['nonmanifold_edges'] += nm
    if nm: stats['nonmanifold_objs'] += 1
    if o.data.uv_layers: stats['uv_objs'] += 1
    for v in bm.verts:
        for i in range(3): lo[i] = min(lo[i], v.co[i]); hi[i] = max(hi[i], v.co[i])
    stats['per_obj'][o.name] = (tris, nm)
    bm.free()
stats['bbox_m'] = [round(hi[i] - lo[i], 3) for i in range(3)]
stats['materials'] = len(bpy.data.materials)

# ---------- export glb ----------
glb = os.path.join(OUT, NAME + '.glb')
bpy.ops.export_scene.gltf(filepath=glb, export_format='GLB', export_apply=True, export_yup=True)
stats['glb_bytes'] = os.path.getsize(glb)

# ---------- render ----------
center = (lo + hi) / 2; size = max(hi - lo)
sc = bpy.context.scene
sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = 32
sc.cycles.use_denoising = True
sc.render.resolution_x, sc.render.resolution_y = ns.get('RES', (640, 480))
sc.render.film_transparent = False
w = bpy.data.worlds.new('w'); sc.world = w; w.use_nodes = True
bg = w.node_tree.nodes['Background']; bg.inputs[0].default_value = (0.32, 0.34, 0.38, 1); bg.inputs[1].default_value = 1.0
sc.view_settings.view_transform = 'AgX'; sc.view_settings.exposure = float(os.environ.get('EXPO', '-0.9'))
# ground disc
bpy.ops.mesh.primitive_plane_add(size=size * 8, location=(center.x, center.y, lo.z - 0.002))
gp = bpy.context.active_object; gp.name = '_ground'; gp.data.materials.append(mat('_g', (0.22, 0.22, 0.24), 0, 0.9))
def light(kind, loc, energy, size_):
    d = bpy.data.lights.new(kind, kind); d.energy = energy
    if kind == 'AREA': d.size = size_
    o = bpy.data.objects.new(kind, d); bpy.context.collection.objects.link(o); o.location = loc
    c = o.constraints.new('TRACK_TO'); tgt = bpy.data.objects.new('t', None); bpy.context.collection.objects.link(tgt); tgt.location = center
    c.target = tgt; c.track_axis = 'TRACK_NEGATIVE_Z'; c.up_axis = 'UP_Y'
R = size * 3
light('AREA', center + Vector((R, -R, R * 1.2)), 900 * size * size + 300, size * 3)
light('AREA', center + Vector((-R, -R * .5, R * .6)), 300 * size * size + 100, size * 3)
light('AREA', center + Vector((0, R, R * .8)), 400 * size * size + 100, size * 3)
cam_d = bpy.data.cameras.new('c'); cam_d.lens = 50
cam = bpy.data.objects.new('c', cam_d); bpy.context.collection.objects.link(cam); sc.camera = cam
tgt = bpy.data.objects.new('ct', None); bpy.context.collection.objects.link(tgt); tgt.location = center
tc = cam.constraints.new('TRACK_TO'); tc.target = tgt; tc.track_axis = 'TRACK_NEGATIVE_Z'; tc.up_axis = 'UP_Y'
paths = []
for i, (az, el, dm) in enumerate(VIEWS):
    d = size * 1.9 * dm; a = math.radians(az); e = math.radians(el)
    cam.location = center + Vector((d * math.cos(e) * math.sin(a), -d * math.cos(e) * math.cos(a), d * math.sin(e)))
    sc.render.filepath = os.path.join(OUT, f'{NAME}_v{i}.png'); bpy.ops.render.render(write_still=True); paths.append(sc.render.filepath)
# contact sheet
imgs = []
for p in paths:
    im = bpy.data.images.load(p); w_, h_ = im.size
    imgs.append(np.array(im.pixels[:], dtype=np.float32).reshape(h_, w_, 4))
sheet = np.concatenate(imgs, axis=1)
si = bpy.data.images.new('sheet', sheet.shape[1], sheet.shape[0], alpha=True)
si.pixels = sheet.ravel().tolist(); si.filepath_raw = os.path.join(OUT, NAME + '_sheet.png'); si.file_format = 'PNG'; si.save()
stats['t_build_s'] = round(t_build, 1); stats['t_total_s'] = round(time.time() - t0, 1)

# ---------- reload glb to validate ----------
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete()
bpy.ops.import_scene.gltf(filepath=glb)
re_objs = [o for o in bpy.data.objects if o.type == 'MESH']
stats['glb_reimport_meshes'] = len(re_objs)
stats['glb_reimport_tris'] = sum(len(p.vertices) - 2 for o in re_objs for p in o.data.polygons)
print('STATS_JSON ' + json.dumps(stats))

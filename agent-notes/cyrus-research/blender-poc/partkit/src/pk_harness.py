# pk_harness.py -- fixed infra (written once): blender -b --python pk_harness.py -- spec.json NAME
import bpy, bmesh, sys, os, math, time, json
import numpy as np
from mathutils import Vector
sys.dont_write_bytecode = True
IN = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, IN)
SPEC, NAME = sys.argv[sys.argv.index('--') + 1:][:2]
OUT = os.getcwd(); t0 = time.time()
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete()
for blk in (bpy.data.meshes, bpy.data.materials, bpy.data.lights, bpy.data.cameras):
    for b in list(blk): blk.remove(b)
import pk_rifle
spec = json.load(open(os.path.join(IN, SPEC)))
objs, A = pk_rifle.build(spec)
RES = (768, 480)
for o in objs:   # UVs
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02); bpy.ops.object.mode_set(mode='OBJECT')
t_build = time.time() - t0
stats = dict(objects=len(objs), tris=0, nonmanifold_edges=0, uv_objs=0, per_obj={}); lo = Vector((1e9,) * 3); hi = Vector((-1e9,) * 3)
for o in objs:
    bm = bmesh.new(); bm.from_mesh(o.data)
    tris = sum(len(f.verts) - 2 for f in bm.faces); nm = sum(1 for e in bm.edges if not e.is_manifold)
    # shells = connected components (overlapping primitives are NOT unioned)
    seen = set(); shells = 0
    for v in bm.verts:
        if v.index in seen: continue
        shells += 1; st = [v]; seen.add(v.index)
        while st:
            c = st.pop()
            for e in c.link_edges:
                w = e.other_vert(c)
                if w.index not in seen: seen.add(w.index); st.append(w)
    stats['tris'] += tris; stats['nonmanifold_edges'] += nm; stats['uv_objs'] += bool(o.data.uv_layers)
    for v in bm.verts:
        for i in range(3): lo[i] = min(lo[i], v.co[i]); hi[i] = max(hi[i], v.co[i])
    stats['per_obj'][o.name] = (tris, nm, shells); bm.free()
stats['bbox_m'] = [round(hi[i] - lo[i], 3) for i in range(3)]
glb = os.path.join(OUT, NAME + '.glb')
bpy.ops.export_scene.gltf(filepath=glb, export_format='GLB', export_apply=True, export_yup=True)
stats['glb_bytes'] = os.path.getsize(glb)
center = (lo + hi) / 2; size = max(hi - lo); sc = bpy.context.scene
sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = 32; sc.cycles.use_denoising = True
sc.render.resolution_x, sc.render.resolution_y = RES
w = bpy.data.worlds.new('w'); sc.world = w; w.use_nodes = True
bg = w.node_tree.nodes['Background']; bg.inputs[0].default_value = (0.32, 0.34, 0.38, 1); bg.inputs[1].default_value = 1.0
sc.view_settings.view_transform = 'AgX'; sc.view_settings.exposure = -0.9
bpy.ops.mesh.primitive_plane_add(size=size * 8, location=(center.x, center.y, lo.z - 0.002))
gp = bpy.context.active_object; gm = bpy.data.materials.new('_g'); gm.use_nodes = True
gm.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.22, 0.22, 0.24, 1); gm.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value = 0.9; gp.data.materials.append(gm)
def light(loc, energy, size_):
    d = bpy.data.lights.new('l', 'AREA'); d.energy = energy; d.size = size_
    o = bpy.data.objects.new('l', d); bpy.context.collection.objects.link(o); o.location = loc
    c = o.constraints.new('TRACK_TO'); t = bpy.data.objects.new('t', None); bpy.context.collection.objects.link(t); t.location = center
    c.target = t; c.track_axis = 'TRACK_NEGATIVE_Z'; c.up_axis = 'UP_Y'
R = size * 3
light(center + Vector((R, -R, R * 1.2)), 900 * size * size + 300, size * 3)
light(center + Vector((-R, -R * .5, R * .6)), 300 * size * size + 100, size * 3)
light(center + Vector((0, R, R * .8)), 400 * size * size + 100, size * 3)
cd = bpy.data.cameras.new('c'); cd.lens = 50; cam = bpy.data.objects.new('c', cd); bpy.context.collection.objects.link(cam); sc.camera = cam
tg = bpy.data.objects.new('ct', None); bpy.context.collection.objects.link(tg); tg.location = center
tc = cam.constraints.new('TRACK_TO'); tc.target = tg; tc.track_axis = 'TRACK_NEGATIVE_Z'; tc.up_axis = 'UP_Y'
VIEWS = [(0, 5, 0.78), (35, 25, 0.85), (0, 82, 0.8)]; paths = []
for i, (az, el, dm) in enumerate(VIEWS):
    d = size * 1.9 * dm; a = math.radians(az); e = math.radians(el)
    cam.location = center + Vector((d * math.cos(e) * math.sin(a), -d * math.cos(e) * math.cos(a), d * math.sin(e)))
    sc.render.filepath = os.path.join(OUT, f'{NAME}_v{i}.png'); bpy.ops.render.render(write_still=True); paths.append(sc.render.filepath)
imgs = []
for p in paths:
    im = bpy.data.images.load(p); w_, h_ = im.size; imgs.append(np.array(im.pixels[:], dtype=np.float32).reshape(h_, w_, 4))
sheet = np.concatenate(imgs, axis=1)
si = bpy.data.images.new('sheet', sheet.shape[1], sheet.shape[0], alpha=True); si.pixels = sheet.ravel().tolist()
si.filepath_raw = os.path.join(OUT, NAME + '_sheet.png'); si.file_format = 'PNG'; si.save()
stats['t_build_s'] = round(t_build, 1); stats['t_total_s'] = round(time.time() - t0, 1)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(); bpy.ops.import_scene.gltf(filepath=glb)
re = [o for o in bpy.data.objects if o.type == 'MESH']
stats['glb_reimport_meshes'] = len(re); stats['glb_reimport_tris'] = sum(len(p.vertices) - 2 for o in re for p in o.data.polygons)
print('STATS_JSON ' + json.dumps(stats))

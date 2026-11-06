"""Gera props low poly da floresta (árvores, pedras, grama) em GLB."""

import math
from pathlib import Path

import bpy
from mathutils import Vector

OUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "models"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def make_mat(name: str, color):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
        bsdf.inputs["Roughness"].default_value = 1.0
    return mat


def link(obj, parent=None):
    bpy.context.scene.collection.objects.link(obj)
    if parent:
        obj.parent = parent
    return obj


def add_cube(name, size, loc, mat, parent=None, rot=None):
    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    link(obj, parent)
    sx, sy, sz = size
    hx, hy, hz = sx / 2, sy / 2, sz / 2
    verts = [
        (-hx, -hy, -hz),
        (hx, -hy, -hz),
        (hx, hy, -hz),
        (-hx, hy, -hz),
        (-hx, -hy, hz),
        (hx, -hy, hz),
        (hx, hy, hz),
        (-hx, hy, hz),
    ]
    faces = [
        (0, 1, 2, 3),
        (4, 7, 6, 5),
        (0, 4, 5, 1),
        (1, 5, 6, 2),
        (2, 6, 7, 3),
        (3, 7, 4, 0),
    ]
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj.location = loc
    if rot:
        obj.rotation_euler = rot
    if mat:
        obj.data.materials.append(mat)
    return obj


def add_cone(name, radius, depth, loc, mat, parent=None, segments=6):
    """Cone apontando pra cima (+Z) via cylinder tapered."""
    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    link(obj, parent)

    verts = []
    faces = []
    # base ring at z=0, tip at z=depth
    for i in range(segments):
        a = (i / segments) * math.tau
        verts.append((math.cos(a) * radius, math.sin(a) * radius, 0.0))
    tip_idx = len(verts)
    verts.append((0.0, 0.0, depth))
    for i in range(segments):
        faces.append((i, (i + 1) % segments, tip_idx))
    # base cap
    for i in range(1, segments - 1):
        faces.append((0, i, i + 1))

    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj.location = loc
    if mat:
        obj.data.materials.append(mat)
    return obj


def add_cylinder(name, r_bottom, r_top, height, loc, mat, parent=None, segments=6):
    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    link(obj, parent)

    verts = []
    faces = []
    for i in range(segments):
        a = (i / segments) * math.tau
        verts.append((math.cos(a) * r_bottom, math.sin(a) * r_bottom, 0.0))
    for i in range(segments):
        a = (i / segments) * math.tau
        verts.append((math.cos(a) * r_top, math.sin(a) * r_top, height))

    for i in range(segments):
        b0 = i
        b1 = (i + 1) % segments
        t0 = i + segments
        t1 = (i + 1) % segments + segments
        faces.append((b0, b1, t1, t0))

    # caps
    for i in range(1, segments - 1):
        faces.append((0, i + 1, i))
        faces.append((segments, segments + i, segments + i + 1))

    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj.location = loc
    if mat:
        obj.data.materials.append(mat)
    return obj


def export_glb(path: Path):
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        use_selection=False,
        export_apply=True,
        export_yup=True,
    )
    print(f"Exported: {path}")


def build_tree(variant: str, trunk_h: float, canopy_scale: float):
    reset_scene()
    mat_trunk = make_mat("Trunk", (0.35, 0.24, 0.14))
    mat_leaf = make_mat("Leaves", (0.22, 0.45, 0.22) if variant == "A" else (0.28, 0.5, 0.24))

    root = bpy.data.objects.new("Tree", None)
    link(root)

    add_cylinder("Trunk", 0.28, 0.18, trunk_h, (0, 0, 0), mat_trunk, parent=root, segments=6)

    layers = 3 if variant == "A" else 2
    for i in range(layers):
        t = i / max(layers - 1, 1)
        radius = (1.55 - t * 0.75) * canopy_scale
        height = (1.7 - t * 0.35) * canopy_scale
        z = trunk_h * 0.85 + i * 0.9 * canopy_scale
        add_cone(f"Canopy{i}", radius, height, (0, 0, z), mat_leaf, parent=root, segments=6)

    export_glb(OUT_DIR / f"tree_{variant.lower()}.glb")


def build_rock(variant: str):
    reset_scene()
    mat = make_mat("Rock", (0.48, 0.48, 0.5) if variant == "A" else (0.42, 0.44, 0.46))
    root = bpy.data.objects.new("Rock", None)
    link(root)

    if variant == "A":
        add_cube("RockMain", (1.2, 0.9, 0.7), (0, 0, 0.35), mat, parent=root, rot=(0.12, 0.2, 0.4))
        add_cube("RockSide", (0.7, 0.55, 0.45), (0.35, 0.15, 0.25), mat, parent=root, rot=(0.1, -0.3, 0.6))
    else:
        add_cube("RockMain", (0.9, 1.1, 0.55), (0, 0, 0.28), mat, parent=root, rot=(-0.1, 0.15, 0.9))
        add_cube("RockTop", (0.5, 0.45, 0.35), (-0.15, 0.1, 0.55), mat, parent=root, rot=(0.2, 0.1, -0.4))

    export_glb(OUT_DIR / f"rock_{variant.lower()}.glb")


def build_grass():
    reset_scene()
    mat = make_mat("Grass", (0.38, 0.6, 0.28))
    root = bpy.data.objects.new("Grass", None)
    link(root)

    blades = [
        ((0.035, 0.06, 0.4), (0.0, 0.0, 0.2), (0.15, 0.0, 0.1)),
        ((0.03, 0.05, 0.32), (0.08, 0.04, 0.16), (-0.2, 0.0, 0.25)),
        ((0.03, 0.05, 0.36), (-0.07, -0.03, 0.18), (0.1, 0.0, -0.2)),
        ((0.028, 0.045, 0.28), (0.03, -0.08, 0.14), (-0.15, 0.05, 0.15)),
    ]
    for i, (size, loc, rot) in enumerate(blades):
        add_cube(f"Blade{i}", size, loc, mat, parent=root, rot=rot)

    export_glb(OUT_DIR / "grass.glb")


build_tree("A", trunk_h=2.8, canopy_scale=1.0)
build_tree("B", trunk_h=2.2, canopy_scale=0.85)
build_rock("A")
build_rock("B")
build_grass()
print("Forest props done.")

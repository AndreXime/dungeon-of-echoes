"""Corpo low poly FPS: tronco, pernas e braços. Sem pescoço/cabeça.

Origem nos pés. Topo do torso ~1.45m. Câmera Godot fica ~1.6 acima do centro.
"""

import math
from pathlib import Path

import bpy

OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "models" / "player_body.glb"

SKIN = (0.86, 0.68, 0.52)
SHIRT = (0.22, 0.38, 0.55)
PANTS = (0.28, 0.3, 0.34)
SHOES = (0.18, 0.14, 0.12)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(name, color):
    m = bpy.data.materials.new(name=name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.9
    return m


def link(obj, parent=None):
    bpy.context.scene.collection.objects.link(obj)
    if parent:
        obj.parent = parent
    return obj


def add_box(name, size, loc, material, parent=None, rot=None):
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
    obj.data.materials.append(material)
    return obj


def add_cylinder(name, r_bot, r_top, height, loc, material, parent=None, segments=6):
    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    link(obj, parent)
    verts = []
    faces = []
    for i in range(segments):
        a = (i / segments) * math.tau
        verts.append((math.cos(a) * r_bot, math.sin(a) * r_bot, 0.0))
    for i in range(segments):
        a = (i / segments) * math.tau
        verts.append((math.cos(a) * r_top, math.sin(a) * r_top, height))
    for i in range(segments):
        b0, b1 = i, (i + 1) % segments
        t0, t1 = i + segments, (i + 1) % segments + segments
        faces.append((b0, b1, t1, t0))
    for i in range(1, segments - 1):
        faces.append((0, i + 1, i))
        faces.append((segments, segments + i, segments + i + 1))
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj.location = loc
    obj.data.materials.append(material)
    return obj


reset()
m_skin = mat("Skin", SKIN)
m_shirt = mat("Shirt", SHIRT)
m_pants = mat("Pants", PANTS)
m_shoes = mat("Shoes", SHOES)

root = bpy.data.objects.new("PlayerBody", None)
link(root)

# Pés um pouco atrás do centro (corpo sob a câmera, não “na frente” dos olhos)
add_box("LeftShoe", (0.15, 0.26, 0.09), (-0.13, -0.02, 0.045), m_shoes, parent=root)
add_box("RightShoe", (0.15, 0.26, 0.09), (0.13, -0.02, 0.045), m_shoes, parent=root)

add_box("LeftLeg", (0.15, 0.15, 0.52), (-0.13, -0.02, 0.36), m_pants, parent=root)
add_box("RightLeg", (0.15, 0.15, 0.52), (0.13, -0.02, 0.36), m_pants, parent=root)

add_box("Hips", (0.4, 0.22, 0.2), (0.0, -0.02, 0.68), m_pants, parent=root)
add_box("Torso", (0.44, 0.24, 0.5), (0.0, -0.02, 1.02), m_shirt, parent=root)

add_box("LeftShoulder", (0.16, 0.16, 0.14), (-0.28, -0.02, 1.2), m_shirt, parent=root)
add_box("RightShoulder", (0.16, 0.16, 0.14), (0.28, -0.02, 1.2), m_shirt, parent=root)

# Braços completos até perto das mãos do POV (sem mão)
left_arm = add_cylinder(
    "LeftArm", 0.065, 0.055, 0.55, (-0.36, -0.02, 1.18), m_skin, parent=root, segments=6
)
right_arm = add_cylinder(
    "RightArm", 0.065, 0.055, 0.55, (0.36, -0.02, 1.18), m_skin, parent=root, segments=6
)
# Pendem pra baixo e um pouco pra frente/dentro
left_arm.rotation_euler = (1.05, 0.15, 0.35)
right_arm.rotation_euler = (1.05, -0.15, -0.35)

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.export_scene.gltf(
    filepath=str(OUTPUT),
    export_format="GLB",
    use_selection=False,
    export_apply=True,
    export_yup=True,
)
print(f"Exported: {OUTPUT}")

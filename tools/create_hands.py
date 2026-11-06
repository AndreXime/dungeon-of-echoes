"""Gera punhos low poly (mãos fechadas) e exporta hands.glb.

Eixos Blender Z-up: +X direita, +Y frente, +Z cima.
No POV FPS o jogador vê o dorso/nós do punho, não a palma.
"""

import bpy
from mathutils import Vector
from pathlib import Path

OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "models" / "hands.glb"

bpy.ops.wm.read_factory_settings(use_empty=True)

SKIN = (0.86, 0.68, 0.52, 1.0)


def make_material(name: str):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = SKIN
        bsdf.inputs["Roughness"].default_value = 0.85
    return mat


def add_box(name: str, size, location, parent=None, rotation=None):
    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

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
    obj.location = location
    if rotation is not None:
        obj.rotation_euler = rotation
    if parent:
        obj.parent = parent
    return obj


def build_fist(side: str, material):
    """Punho fechado: bloco da mão + nós + polegar cruzado."""
    sign = -1.0 if side == "Left" else 1.0
    root = bpy.data.objects.new(f"{side}Hand", None)
    bpy.context.scene.collection.objects.link(root)

    # Corpo do punho (dorso pra cima / +Z)
    fist = add_box(
        f"{side}Fist",
        (0.085, 0.1, 0.07),
        (0.0, 0.0, 0.0),
        parent=root,
    )
    fist.data.materials.append(material)

    # Faixa dos nós na frente do punho (+Y)
    knuckles = add_box(
        f"{side}Knuckles",
        (0.09, 0.035, 0.045),
        (0.0, 0.055, 0.01),
        parent=root,
    )
    knuckles.data.materials.append(material)

    # Dedos enrolados: volume sob os nós (um bloco só, low poly)
    curled = add_box(
        f"{side}Curled",
        (0.08, 0.04, 0.04),
        (0.0, 0.03, -0.035),
        parent=root,
    )
    curled.data.materials.append(material)

    # Polegar por fora, cruzando a frente do punho
    thumb = add_box(
        f"{side}Thumb",
        (0.03, 0.055, 0.028),
        (sign * 0.055, 0.02, -0.005),
        parent=root,
        rotation=(0.35, 0.0, sign * -0.7),
    )
    thumb.data.materials.append(material)

    thumb_tip = add_box(
        f"{side}ThumbTip",
        (0.025, 0.03, 0.024),
        (sign * 0.035, 0.05, -0.02),
        parent=root,
    )
    thumb_tip.data.materials.append(material)

    return root


skin = make_material("SkinFlat")
build_fist("Left", skin)
build_fist("Right", skin)

OUTPUT.parent.mkdir(parents=True, exist_ok=True)

bpy.ops.export_scene.gltf(
    filepath=str(OUTPUT),
    export_format="GLB",
    use_selection=False,
    export_apply=True,
    export_yup=True,
)

print(f"Exported: {OUTPUT}")

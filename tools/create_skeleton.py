"""Esqueleto low poly com escudo de madeira. Exporta skeleton.glb.

Blender Z-up, origem nos pés. Altura ~1.7m.
"""

from pathlib import Path

import bpy

OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "models" / "skeleton.glb"

BONE = (0.86, 0.83, 0.72)
WOOD = (0.42, 0.28, 0.15)
IRON = (0.45, 0.45, 0.48)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(name, color, metallic=0.0):
    m = bpy.data.materials.new(name=name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.9
        if "Metallic" in bsdf.inputs:
            bsdf.inputs["Metallic"].default_value = metallic
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


reset()
m_bone = mat("Bone", BONE)
m_wood = mat("ShieldWood", WOOD)
m_iron = mat("Iron", IRON, metallic=0.5)

root = bpy.data.objects.new("Skeleton", None)
link(root)

# Pernas
add_box("LeftThigh", (0.12, 0.12, 0.38), (-0.12, 0.0, 0.35), m_bone, root)
add_box("RightThigh", (0.12, 0.12, 0.38), (0.12, 0.0, 0.35), m_bone, root)
add_box("LeftShin", (0.1, 0.1, 0.35), (-0.12, 0.02, 0.12), m_bone, root)
add_box("RightShin", (0.1, 0.1, 0.35), (0.12, 0.02, 0.12), m_bone, root)
add_box("LeftFoot", (0.12, 0.22, 0.08), (-0.12, 0.06, 0.04), m_bone, root)
add_box("RightFoot", (0.12, 0.22, 0.08), (0.12, 0.06, 0.04), m_bone, root)

# Quadril / costelas / coluna
add_box("Pelvis", (0.36, 0.18, 0.14), (0.0, 0.0, 0.62), m_bone, root)
add_box("Spine", (0.1, 0.1, 0.45), (0.0, 0.0, 0.95), m_bone, root)
add_box("RibCage", (0.42, 0.22, 0.38), (0.0, 0.0, 1.15), m_bone, root)

# Cabeça / crânio
add_box("Skull", (0.26, 0.28, 0.28), (0.0, 0.02, 1.52), m_bone, root)
add_box("Jaw", (0.2, 0.14, 0.08), (0.0, 0.06, 1.36), m_bone, root)

# Braços
add_box("LeftUpperArm", (0.1, 0.1, 0.32), (-0.32, 0.0, 1.2), m_bone, root, rot=(0.2, 0.0, 0.35))
add_box("RightUpperArm", (0.1, 0.1, 0.32), (0.32, 0.0, 1.2), m_bone, root, rot=(0.2, 0.0, -0.35))
add_box("LeftForearm", (0.08, 0.08, 0.28), (-0.42, 0.05, 0.95), m_bone, root, rot=(0.5, 0.0, 0.2))
add_box("RightForearm", (0.08, 0.08, 0.28), (0.42, 0.05, 0.95), m_bone, root, rot=(0.5, 0.0, -0.2))

# Escudo de madeira (braço esquerdo / frente)
add_box("Shield", (0.08, 0.42, 0.55), (-0.48, 0.12, 1.05), m_wood, root, rot=(0.1, 0.35, 0.15))
add_box("ShieldBoss", (0.1, 0.12, 0.12), (-0.44, 0.16, 1.05), m_iron, root)

# Mão direita (sem arma por enquanto)
add_box("RightHand", (0.1, 0.08, 0.08), (0.48, 0.08, 0.82), m_bone, root)

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.export_scene.gltf(
    filepath=str(OUTPUT),
    export_format="GLB",
    use_selection=False,
    export_apply=True,
    export_yup=True,
)
print(f"Exported: {OUTPUT}")

"""Exporta sword.glb e shield.glb low poly."""

from pathlib import Path
import bpy

OUT = Path(__file__).resolve().parents[1] / "assets" / "models"


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(name, color):
    m = bpy.data.materials.new(name=name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.7
        if "Metallic" in bsdf.inputs:
            bsdf.inputs["Metallic"].default_value = 0.6 if "Steel" in name else 0.0
    return m


def link(obj, parent=None):
    bpy.context.scene.collection.objects.link(obj)
    if parent:
        obj.parent = parent
    return obj


def box(name, size, loc, material, parent=None):
    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    link(obj, parent)
    sx, sy, sz = size
    hx, hy, hz = sx / 2, sy / 2, sz / 2
    verts = [
        (-hx, -hy, -hz), (hx, -hy, -hz), (hx, hy, -hz), (-hx, hy, -hz),
        (-hx, -hy, hz), (hx, -hy, hz), (hx, hy, hz), (-hx, hy, hz),
    ]
    faces = [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj.location = loc
    obj.data.materials.append(material)
    return obj


def export(path: Path):
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        use_selection=False,
        export_apply=True,
        export_yup=True,
    )
    print("Exported", path)


# Sword: along +Y (Blender forward), grip at origin
reset()
steel = mat("Steel", (0.7, 0.72, 0.75))
wood = mat("Wood", (0.35, 0.22, 0.12))
root = bpy.data.objects.new("Sword", None)
link(root)
box("Blade", (0.04, 0.55, 0.02), (0, 0.35, 0), steel, root)
box("Guard", (0.16, 0.04, 0.04), (0, 0.08, 0), steel, root)
box("Grip", (0.035, 0.12, 0.035), (0, 0.0, 0), wood, root)
export(OUT / "sword.glb")

# Shield
reset()
wood = mat("ShieldWood", (0.4, 0.28, 0.16))
steel = mat("Boss", (0.55, 0.55, 0.58))
root = bpy.data.objects.new("Shield", None)
link(root)
box("Plate", (0.35, 0.05, 0.45), (0, 0, 0.1), wood, root)
box("Boss", (0.1, 0.08, 0.1), (0, 0.02, 0.1), steel, root)
export(OUT / "shield.glb")

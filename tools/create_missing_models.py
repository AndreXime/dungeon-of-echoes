"""Gera GLBs low poly que ainda estavam como placeholder no jogo."""

from pathlib import Path
import math
import bpy

OUT = Path(__file__).resolve().parents[1] / "assets" / "models"
OUT.mkdir(parents=True, exist_ok=True)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(name, color, metallic=0.0, rough=0.9):
    m = bpy.data.materials.new(name=name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
        bsdf.inputs["Roughness"].default_value = rough
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
        (-hx, -hy, -hz), (hx, -hy, -hz), (hx, hy, -hz), (-hx, hy, -hz),
        (-hx, -hy, hz), (hx, -hy, hz), (hx, hy, hz), (-hx, hy, hz),
    ]
    faces = [
        (0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1),
        (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0),
    ]
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj.location = loc
    if rot:
        obj.rotation_euler = rot
    obj.data.materials.append(material)
    return obj


def add_cylinder(name, r_bot, r_top, height, loc, material, parent=None, segments=8):
    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    link(obj, parent)
    verts, faces = [], []
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


def export(path: Path):
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        use_selection=False,
        export_apply=True,
        export_yup=True,
    )
    print("Exported", path)


def build_dagger():
    reset()
    steel = mat("Steel", (0.72, 0.74, 0.78), 0.7, 0.45)
    wood = mat("Grip", (0.32, 0.2, 0.1))
    root = bpy.data.objects.new("Dagger", None)
    link(root)
    add_box("Blade", (0.03, 0.42, 0.012), (0, 0.28, 0), steel, root)
    add_box("Guard", (0.1, 0.03, 0.03), (0, 0.08, 0), steel, root)
    add_box("Grip", (0.028, 0.1, 0.028), (0, 0.0, 0), wood, root)
    add_box("Pommel", (0.04, 0.04, 0.04), (0, -0.06, 0), steel, root)
    export(OUT / "dagger.glb")


def build_crossbow():
    reset()
    wood = mat("Wood", (0.4, 0.26, 0.14))
    steel = mat("Steel", (0.55, 0.55, 0.58), 0.5, 0.5)
    root = bpy.data.objects.new("Crossbow", None)
    link(root)
    add_box("Stock", (0.07, 0.42, 0.06), (0, 0.1, 0), wood, root)
    add_box("Prod", (0.42, 0.05, 0.05), (0, 0.28, 0.02), wood, root)
    add_box("StringLeft", (0.18, 0.015, 0.015), (-0.12, 0.2, 0.02), steel, root, rot=(0, 0, 0.4))
    add_box("StringRight", (0.18, 0.015, 0.015), (0.12, 0.2, 0.02), steel, root, rot=(0, 0, -0.4))
    add_box("Trigger", (0.03, 0.05, 0.04), (0, 0.02, -0.04), steel, root)
    export(OUT / "crossbow.glb")


def build_bolt():
    reset()
    wood = mat("Shaft", (0.5, 0.38, 0.22))
    steel = mat("Tip", (0.65, 0.65, 0.7), 0.6, 0.4)
    root = bpy.data.objects.new("Bolt", None)
    link(root)
    add_cylinder("Shaft", 0.015, 0.015, 0.28, (0, 0, -0.05), wood, root, segments=6)
    # tip toward -Z after Y-up export: build tip at +Y in Blender forward
    add_box("Tip", (0.04, 0.08, 0.04), (0, 0.28, 0), steel, root)
    add_box("Fletching", (0.08, 0.04, 0.01), (0, -0.02, 0.02), mat("Fletch", (0.7, 0.2, 0.15)), root)
    export(OUT / "bolt.glb")


def build_crate():
    reset()
    wood = mat("Crate", (0.45, 0.3, 0.16))
    dark = mat("Band", (0.25, 0.18, 0.1))
    root = bpy.data.objects.new("Crate", None)
    link(root)
    add_box("Body", (0.8, 0.8, 0.8), (0, 0, 0.4), wood, root)
    add_box("BandA", (0.84, 0.84, 0.08), (0, 0, 0.2), dark, root)
    add_box("BandB", (0.84, 0.84, 0.08), (0, 0, 0.6), dark, root)
    export(OUT / "crate.glb")


def build_barrel():
    reset()
    wood = mat("Barrel", (0.4, 0.26, 0.14))
    band = mat("Band", (0.3, 0.3, 0.32), 0.4, 0.6)
    root = bpy.data.objects.new("Barrel", None)
    link(root)
    add_cylinder("Body", 0.38, 0.35, 0.9, (0, 0, 0), wood, root, segments=8)
    add_cylinder("BandLow", 0.4, 0.4, 0.08, (0, 0, 0.15), band, root, segments=8)
    add_cylinder("BandHigh", 0.38, 0.38, 0.08, (0, 0, 0.7), band, root, segments=8)
    export(OUT / "barrel.glb")


def build_vase():
    reset()
    clay = mat("Clay", (0.55, 0.4, 0.28))
    root = bpy.data.objects.new("Vase", None)
    link(root)
    add_cylinder("Base", 0.12, 0.18, 0.15, (0, 0, 0), clay, root, segments=8)
    add_cylinder("Body", 0.2, 0.14, 0.35, (0, 0, 0.15), clay, root, segments=8)
    add_cylinder("Neck", 0.08, 0.1, 0.12, (0, 0, 0.5), clay, root, segments=8)
    export(OUT / "vase.glb")


def build_spikes():
    reset()
    iron = mat("Spike", (0.55, 0.55, 0.6), 0.45, 0.55)
    root = bpy.data.objects.new("Spikes", None)
    link(root)
    for i in range(5):
        x = (i - 2) * 0.28
        add_box(f"Spike{i}", (0.1, 0.1, 0.55), (x, 0, 0.28), iron, root)
    add_box("Base", (1.5, 0.35, 0.08), (0, 0, 0.04), mat("Base", (0.3, 0.3, 0.32)), root)
    export(OUT / "spikes.glb")


def build_relic_pedestal():
    reset()
    stone = mat("Stone", (0.28, 0.26, 0.32))
    gem = mat("Gem", (0.35, 0.8, 1.0), 0.2, 0.25)
    root = bpy.data.objects.new("RelicPedestal", None)
    link(root)
    add_box("Base", (0.9, 0.9, 0.25), (0, 0, 0.12), stone, root)
    add_box("Pillar", (0.35, 0.35, 0.35), (0, 0, 0.4), stone, root)
    add_box("Gem", (0.22, 0.22, 0.22), (0, 0, 0.7), gem, root)
    export(OUT / "relic_pedestal.glb")


def build_portal():
    reset()
    stone = mat("PortalStone", (0.25, 0.22, 0.35))
    glow = mat("Glow", (0.4, 0.5, 1.0), 0.0, 0.4)
    root = bpy.data.objects.new("Portal", None)
    link(root)
    add_box("Left", (0.4, 0.4, 3.0), (-1.0, 0, 1.5), stone, root)
    add_box("Right", (0.4, 0.4, 3.0), (1.0, 0, 1.5), stone, root)
    add_box("Top", (2.4, 0.4, 0.4), (0, 0, 3.1), stone, root)
    add_box("Gate", (1.6, 0.15, 2.4), (0, 0, 1.4), glow, root)
    export(OUT / "portal.glb")


def build_campfire():
    reset()
    wood = mat("Log", (0.3, 0.2, 0.12))
    rock = mat("Rock", (0.35, 0.35, 0.38))
    flame = mat("Flame", (1.0, 0.45, 0.15), 0.0, 0.5)
    root = bpy.data.objects.new("Campfire", None)
    link(root)
    for i in range(6):
        a = (i / 6) * math.tau
        add_box(f"Rock{i}", (0.25, 0.2, 0.18), (math.cos(a) * 0.45, math.sin(a) * 0.45, 0.08), rock, root)
    add_box("LogA", (0.7, 0.15, 0.15), (0, 0, 0.15), wood, root, rot=(0, 0, 0.4))
    add_box("LogB", (0.7, 0.15, 0.15), (0, 0, 0.2), wood, root, rot=(0, 0, -0.5))
    add_box("Flame", (0.2, 0.2, 0.45), (0, 0, 0.45), flame, root)
    export(OUT / "campfire.glb")


def build_npc(name: str, color, filename: str):
    reset()
    cloth = mat("Cloth", color)
    skin = mat("Skin", (0.86, 0.68, 0.52))
    root = bpy.data.objects.new(name, None)
    link(root)
    add_box("Legs", (0.45, 0.25, 0.55), (0, 0, 0.35), cloth, root)
    add_box("Torso", (0.5, 0.28, 0.55), (0, 0, 0.9), cloth, root)
    add_box("Head", (0.28, 0.28, 0.28), (0, 0.02, 1.35), skin, root)
    add_box("LeftArm", (0.12, 0.12, 0.45), (-0.35, 0, 0.85), skin, root)
    add_box("RightArm", (0.12, 0.12, 0.45), (0.35, 0, 0.85), skin, root)
    export(OUT / filename)


build_dagger()
build_crossbow()
build_bolt()
build_crate()
build_barrel()
build_vase()
build_spikes()
build_relic_pedestal()
build_portal()
build_campfire()
build_npc("Blacksmith", (0.55, 0.35, 0.25), "npc_blacksmith.glb")
build_npc("Alchemist", (0.35, 0.55, 0.4), "npc_alchemist.glb")
build_npc("Cartographer", (0.35, 0.4, 0.6), "npc_cartographer.glb")
print("All missing models exported.")

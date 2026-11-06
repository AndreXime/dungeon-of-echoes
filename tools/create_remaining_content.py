"""Modelos restantes: inimigos extras, tocha, armadilhas ambientais."""

from pathlib import Path
import math
import bpy

OUT = Path(__file__).resolve().parents[1] / "assets" / "models"
OUT.mkdir(parents=True, exist_ok=True)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(name, color, metallic=0.0, rough=0.9, emit=0.0):
    m = bpy.data.materials.new(name=name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
        bsdf.inputs["Roughness"].default_value = rough
        if "Metallic" in bsdf.inputs:
            bsdf.inputs["Metallic"].default_value = metallic
        if emit > 0 and "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = (*color, 1.0)
            if "Emission Strength" in bsdf.inputs:
                bsdf.inputs["Emission Strength"].default_value = emit
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
    faces = [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj.location = loc
    if rot:
        obj.rotation_euler = rot
    obj.data.materials.append(material)
    return obj


def export(path: Path):
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=False, export_apply=True, export_yup=True)
    print("Exported", path)


def build_torch():
    reset()
    wood = mat("Wood", (0.35, 0.22, 0.12))
    fire = mat("Fire", (1.0, 0.55, 0.15), emit=3.0)
    root = bpy.data.objects.new("Torch", None)
    link(root)
    add_box("Stick", (0.04, 0.04, 0.35), (0, 0, 0.1), wood, root)
    add_box("Flame", (0.08, 0.08, 0.14), (0, 0, 0.32), fire, root)
    export(OUT / "torch.glb")


def build_bat():
    reset()
    crystal = mat("Crystal", (0.45, 0.75, 1.0), 0.2, 0.3, emit=1.5)
    wing = mat("Wing", (0.35, 0.45, 0.7))
    root = bpy.data.objects.new("CrystalBat", None)
    link(root)
    add_box("Body", (0.25, 0.35, 0.2), (0, 0, 0.3), crystal, root)
    add_box("Head", (0.18, 0.18, 0.18), (0, 0.2, 0.35), crystal, root)
    add_box("WingL", (0.55, 0.08, 0.25), (-0.4, 0, 0.3), wing, root, rot=(0, 0.3, 0.4))
    add_box("WingR", (0.55, 0.08, 0.25), (0.4, 0, 0.3), wing, root, rot=(0, -0.3, -0.4))
    export(OUT / "crystal_bat.glb")


def build_slime():
    reset()
    goo = mat("Goo", (0.3, 0.75, 0.35), 0.0, 0.35, emit=0.4)
    root = bpy.data.objects.new("Slime", None)
    link(root)
    add_box("Body", (0.7, 0.7, 0.45), (0, 0, 0.25), goo, root)
    add_box("Blob", (0.4, 0.4, 0.25), (0.1, 0.1, 0.5), goo, root)
    export(OUT / "slime.glb")


def build_boss():
    reset()
    bone = mat("Bone", (0.9, 0.86, 0.75))
    dark = mat("Dark", (0.2, 0.15, 0.25))
    root = bpy.data.objects.new("BossSkeleton", None)
    link(root)
    add_box("Pelvis", (0.55, 0.3, 0.2), (0, 0, 0.7), bone, root)
    add_box("Torso", (0.7, 0.4, 0.7), (0, 0, 1.25), bone, root)
    add_box("Skull", (0.4, 0.4, 0.4), (0, 0.05, 1.8), bone, root)
    add_box("Crown", (0.45, 0.45, 0.15), (0, 0, 2.05), dark, root)
    add_box("LegL", (0.16, 0.16, 0.65), (-0.18, 0, 0.3), bone, root)
    add_box("LegR", (0.16, 0.16, 0.65), (0.18, 0, 0.3), bone, root)
    add_box("ArmL", (0.14, 0.14, 0.7), (-0.5, 0, 1.2), bone, root)
    add_box("ArmR", (0.14, 0.14, 0.7), (0.5, 0, 1.2), bone, root)
    add_box("Mace", (0.2, 0.2, 0.9), (0.65, 0.1, 0.9), dark, root)
    export(OUT / "boss_skeleton.glb")


def build_miner():
    reset()
    cloth = mat("Cloth", (0.45, 0.25, 0.15))
    skin = mat("Skin", (0.7, 0.5, 0.4))
    iron = mat("Iron", (0.5, 0.5, 0.55), 0.5)
    root = bpy.data.objects.new("Miner", None)
    link(root)
    add_box("Body", (0.5, 0.3, 0.7), (0, 0, 1.0), cloth, root)
    add_box("Head", (0.28, 0.28, 0.28), (0, 0, 1.5), skin, root)
    add_box("Helm", (0.32, 0.32, 0.12), (0, 0, 1.68), iron, root)
    add_box("LegL", (0.15, 0.15, 0.55), (-0.14, 0, 0.35), cloth, root)
    add_box("LegR", (0.15, 0.15, 0.55), (0.14, 0, 0.35), cloth, root)
    add_box("Pick", (0.08, 0.08, 0.8), (0.45, 0.1, 1.0), iron, root, rot=(0.5, 0, 0))
    export(OUT / "corrupted_miner.glb")


def build_automaton():
    reset()
    stone = mat("Stone", (0.45, 0.42, 0.4))
    glow = mat("Core", (1.0, 0.5, 0.15), emit=2.0)
    root = bpy.data.objects.new("Automaton", None)
    link(root)
    add_box("Body", (0.7, 0.45, 0.9), (0, 0, 1.0), stone, root)
    add_box("Head", (0.35, 0.35, 0.35), (0, 0, 1.65), stone, root)
    add_box("Core", (0.2, 0.15, 0.2), (0, 0.2, 1.05), glow, root)
    add_box("LegL", (0.2, 0.2, 0.55), (-0.2, 0, 0.3), stone, root)
    add_box("LegR", (0.2, 0.2, 0.55), (0.2, 0, 0.3), stone, root)
    export(OUT / "stone_automaton.glb")


def build_spider():
    reset()
    body = mat("Body", (0.25, 0.45, 0.2))
    acid = mat("Acid", (0.6, 1.0, 0.2), emit=1.0)
    root = bpy.data.objects.new("AcidSpider", None)
    link(root)
    add_box("Abdomen", (0.45, 0.55, 0.3), (0, -0.1, 0.35), body, root)
    add_box("Cephalon", (0.3, 0.3, 0.25), (0, 0.25, 0.4), body, root)
    add_box("Sac", (0.15, 0.15, 0.15), (0, 0.35, 0.45), acid, root)
    for i, x in enumerate([-0.35, -0.15, 0.15, 0.35]):
        add_box(f"LegL{i}", (0.06, 0.35, 0.06), (x, 0.15, 0.2), body, root, rot=(0.4, 0, 0.2))
        add_box(f"LegR{i}", (0.06, 0.35, 0.06), (x, -0.25, 0.2), body, root, rot=(-0.4, 0, -0.2))
    export(OUT / "acid_spider.glb")


def build_guardian():
    reset()
    wood = mat("Wood", (0.35, 0.5, 0.25))
    root = bpy.data.objects.new("WoodGuardian", None)
    link(root)
    add_box("Trunk", (0.5, 0.4, 1.2), (0, 0, 0.9), wood, root)
    add_box("Head", (0.4, 0.35, 0.4), (0, 0, 1.7), wood, root)
    add_box("ArmL", (0.18, 0.18, 0.8), (-0.45, 0, 1.1), wood, root)
    add_box("ArmR", (0.18, 0.18, 0.8), (0.45, 0, 1.1), wood, root)
    add_box("RootL", (0.2, 0.5, 0.2), (-0.25, 0.1, 0.15), wood, root)
    add_box("RootR", (0.2, 0.5, 0.2), (0.25, -0.1, 0.15), wood, root)
    export(OUT / "wood_guardian.glb")


def build_golem():
    reset()
    vine = mat("Vine", (0.25, 0.55, 0.3))
    root = bpy.data.objects.new("VineGolem", None)
    link(root)
    add_box("Core", (0.6, 0.5, 0.9), (0, 0, 1.0), vine, root)
    add_box("Head", (0.35, 0.35, 0.35), (0, 0, 1.65), vine, root)
    add_box("TendrilL", (0.12, 0.12, 1.0), (-0.5, 0.1, 0.9), vine, root, rot=(0.3, 0, 0.3))
    add_box("TendrilR", (0.12, 0.12, 1.0), (0.5, -0.1, 0.9), vine, root, rot=(-0.3, 0, -0.3))
    export(OUT / "vine_golem.glb")


def build_shooter():
    reset()
    leaf = mat("Leaf", (0.2, 0.4, 0.2))
    bark = mat("Bark", (0.35, 0.25, 0.15))
    root = bpy.data.objects.new("FoliageShooter", None)
    link(root)
    add_box("Body", (0.4, 0.35, 0.7), (0, 0, 0.7), bark, root)
    add_box("Canopy", (0.7, 0.7, 0.25), (0, 0, 1.2), leaf, root)
    add_box("Blowgun", (0.08, 0.45, 0.08), (0, 0.3, 0.9), bark, root)
    export(OUT / "foliage_shooter.glb")


def build_rope_bag():
    reset()
    rope = mat("Rope", (0.55, 0.45, 0.25))
    wood = mat("Wood", (0.4, 0.28, 0.15))
    root = bpy.data.objects.new("RopeTrap", None)
    link(root)
    add_box("Rope", (0.05, 0.05, 1.5), (0, 0, 1.5), rope, root)
    add_box("Bag", (0.5, 0.5, 0.5), (0, 0, 0.4), wood, root)
    export(OUT / "rope_trap.glb")


def build_vines():
    reset()
    leaf = mat("Leaf", (0.25, 0.55, 0.28))
    root = bpy.data.objects.new("CutVines", None)
    link(root)
    for i in range(4):
        add_box(f"V{i}", (0.08, 0.08, 1.2), ((i - 1.5) * 0.2, 0.05 * i, 0.7), leaf, root, rot=(0.1 * i, 0, 0.15))
    export(OUT / "cut_vines.glb")


build_torch()
build_bat()
build_slime()
build_boss()
build_miner()
build_automaton()
build_spider()
build_guardian()
build_golem()
build_shooter()
build_rope_bag()
build_vines()
print("Remaining content models done.")

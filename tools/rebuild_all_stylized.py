"""Regenera todos os GLBs no estilo stylized flat-shaded."""
from __future__ import annotations

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import stylized_lib as S


def _start(name: str):
    S.reset_scene()
    S.setup_preview_lights()
    return S.add_empty(name)


def build_sword() -> None:
    root = _start("Sword")
    steel = S.make_mat("Steel", (0.72, 0.74, 0.78), metallic=0.55, rough=0.45)
    wood = S.make_mat("GripWood", (0.38, 0.22, 0.12), rough=0.9)
    leather = S.make_mat("Wrap", (0.25, 0.12, 0.08), rough=0.95)
    S.add_box("Blade", (0.045, 0.58, 0.022), (0.01, 0.36, 0.0), steel, root, asymmetry=0.35)
    S.add_box("Fuller", (0.012, 0.4, 0.006), (0.0, 0.34, 0.012), steel, root, asymmetry=0.2)
    S.add_box("Guard", (0.18, 0.035, 0.045), (0.02, 0.08, 0.0), steel, root, asymmetry=0.45)
    S.add_box("Grip", (0.032, 0.13, 0.032), (-0.005, -0.01, 0.0), wood, root, asymmetry=0.15)
    S.add_box("Wrap", (0.036, 0.04, 0.036), (0.0, 0.02, 0.0), leather, root, asymmetry=0.1)
    S.add_box("Pommel", (0.05, 0.04, 0.05), (0.01, -0.1, 0.0), steel, root, asymmetry=0.25)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "sword.glb")


def build_shield() -> None:
    root = _start("Shield")
    wood = S.make_mat("ShieldWood", (0.42, 0.28, 0.14), rough=0.92)
    steel = S.make_mat("Boss", (0.55, 0.56, 0.6), metallic=0.5, rough=0.4)
    leather = S.make_mat("Rim", (0.2, 0.12, 0.08), rough=0.95)
    S.add_box("Plate", (0.36, 0.05, 0.46), (0.02, 0.0, 0.1), wood, root, asymmetry=0.4)
    S.add_box("Boss", (0.11, 0.08, 0.11), (-0.02, 0.03, 0.12), steel, root, asymmetry=0.2)
    S.add_box("RimTop", (0.34, 0.03, 0.04), (0.0, 0.0, 0.32), leather, root, asymmetry=0.15)
    S.add_box("RivetA", (0.03, 0.04, 0.03), (0.12, 0.04, 0.2), steel, root, asymmetry=0.3)
    S.add_box("RivetB", (0.03, 0.04, 0.03), (-0.14, 0.04, 0.0), steel, root, asymmetry=0.25)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "shield.glb")


def build_dagger() -> None:
    root = _start("Dagger")
    steel = S.make_mat("Blade", (0.7, 0.72, 0.76), metallic=0.6, rough=0.4)
    wood = S.make_mat("Hilt", (0.3, 0.18, 0.1), rough=0.9)
    wrap = S.make_mat("Cord", (0.55, 0.4, 0.2), rough=0.85)
    S.add_box("Blade", (0.03, 0.28, 0.014), (0.008, 0.2, 0.0), steel, root, asymmetry=0.5)
    S.add_box("Guard", (0.1, 0.02, 0.03), (0.01, 0.06, 0.0), steel, root, asymmetry=0.35)
    S.add_box("Grip", (0.025, 0.1, 0.025), (-0.004, 0.0, 0.0), wood, root, asymmetry=0.2)
    S.add_box("Cord", (0.028, 0.03, 0.028), (0.0, 0.03, 0.0), wrap, root, asymmetry=0.15)
    S.add_box("Pommel", (0.035, 0.03, 0.035), (0.005, -0.07, 0.0), steel, root, asymmetry=0.3)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "dagger.glb")


def build_crossbow() -> None:
    root = _start("Crossbow")
    wood = S.make_mat("Stock", (0.4, 0.26, 0.14), rough=0.9)
    steel = S.make_mat("Metal", (0.5, 0.52, 0.55), metallic=0.55, rough=0.45)
    cord = S.make_mat("Cord", (0.75, 0.7, 0.55), rough=0.8)
    S.add_box("Stock", (0.06, 0.45, 0.08), (0.01, 0.05, 0.0), wood, root, asymmetry=0.3)
    S.add_box("ProdL", (0.28, 0.04, 0.03), (-0.18, 0.28, 0.02), wood, root, rot=(0, 0, 0.35), asymmetry=0.25)
    S.add_box("ProdR", (0.28, 0.04, 0.03), (0.2, 0.28, -0.01), wood, root, rot=(0, 0, -0.3), asymmetry=0.25)
    S.add_box("String", (0.42, 0.01, 0.01), (0.01, 0.3, 0.04), cord, root, asymmetry=0.1)
    S.add_box("Trigger", (0.02, 0.04, 0.05), (0.0, 0.0, -0.05), steel, root, asymmetry=0.2)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "crossbow.glb")


def build_bolt() -> None:
    root = _start("Bolt")
    shaft = S.make_mat("Shaft", (0.45, 0.3, 0.15), rough=0.85)
    tip = S.make_mat("Tip", (0.6, 0.62, 0.65), metallic=0.5, rough=0.4)
    fletch = S.make_mat("Fletch", (0.7, 0.25, 0.2), rough=0.8)
    S.add_box("Shaft", (0.02, 0.28, 0.02), (0.0, 0.05, 0.0), shaft, root, asymmetry=0.2)
    S.add_box("Tip", (0.03, 0.06, 0.03), (0.005, 0.22, 0.0), tip, root, asymmetry=0.4)
    S.add_box("Fletch", (0.06, 0.04, 0.01), (0.02, -0.08, 0.01), fletch, root, asymmetry=0.35)
    S.stylize_hierarchy(root, displace_strength=0.005)
    S.export_glb(S.OUT / "bolt.glb")


def build_crate() -> None:
    root = _start("Crate")
    wood = S.make_mat("Wood", (0.45, 0.3, 0.16), rough=0.92)
    dark = S.make_mat("Band", (0.2, 0.15, 0.1), rough=0.95)
    nail = S.make_mat("Nail", (0.5, 0.5, 0.52), metallic=0.4, rough=0.5)
    S.add_box("Body", (0.7, 0.7, 0.7), (0.02, -0.01, 0.35), wood, root, asymmetry=0.35)
    S.add_box("Band", (0.74, 0.74, 0.08), (0.0, 0.0, 0.2), dark, root, asymmetry=0.15)
    S.add_box("Nail", (0.05, 0.05, 0.05), (0.3, 0.3, 0.55), nail, root, asymmetry=0.2)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "crate.glb")


def build_barrel() -> None:
    root = _start("Barrel")
    wood = S.make_mat("Wood", (0.4, 0.26, 0.14), rough=0.9)
    iron = S.make_mat("Iron", (0.35, 0.36, 0.4), metallic=0.5, rough=0.5)
    S.add_box("Body", (0.55, 0.55, 0.8), (0.02, 0.0, 0.4), wood, root, asymmetry=0.25)
    S.add_box("RingLo", (0.6, 0.6, 0.06), (0.0, 0.0, 0.15), iron, root, asymmetry=0.1)
    S.add_box("RingHi", (0.58, 0.58, 0.06), (0.01, 0.0, 0.65), iron, root, asymmetry=0.12)
    S.add_box("Tap", (0.08, 0.12, 0.08), (0.3, 0.0, 0.35), iron, root, asymmetry=0.3)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "barrel.glb")


def build_vase() -> None:
    root = _start("Vase")
    clay = S.make_mat("Clay", (0.55, 0.35, 0.25), rough=0.88)
    glaze = S.make_mat("Glaze", (0.3, 0.45, 0.55), rough=0.35)
    crack = S.make_mat("Crack", (0.25, 0.18, 0.14), rough=0.95)
    S.add_box("Base", (0.28, 0.28, 0.15), (0.01, 0.0, 0.08), clay, root, asymmetry=0.3)
    S.add_box("Belly", (0.4, 0.4, 0.35), (-0.02, 0.01, 0.32), clay, root, asymmetry=0.4)
    S.add_box("Neck", (0.18, 0.18, 0.2), (0.02, 0.0, 0.58), glaze, root, asymmetry=0.25)
    S.add_box("Crack", (0.05, 0.02, 0.25), (0.18, 0.0, 0.3), crack, root, asymmetry=0.5)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "vase.glb")


def build_spikes() -> None:
    root = _start("Spikes")
    iron = S.make_mat("Iron", (0.45, 0.45, 0.48), metallic=0.55, rough=0.45)
    rust = S.make_mat("Rust", (0.45, 0.22, 0.12), rough=0.9)
    S.add_box("Base", (1.4, 0.5, 0.12), (0.05, 0.0, 0.06), rust, root, asymmetry=0.2)
    for i, x in enumerate((-0.45, -0.15, 0.15, 0.4)):
        S.add_box(f"Spike{i}", (0.1, 0.1, 0.45 + i * 0.04), (x, 0.02 * i, 0.3), iron, root, asymmetry=0.35 + i * 0.05)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "spikes.glb")


def build_torch() -> None:
    root = _start("Torch")
    wood = S.make_mat("Wood", (0.35, 0.22, 0.12), rough=0.92)
    wrap = S.make_mat("Cloth", (0.25, 0.2, 0.15), rough=0.95)
    fire = S.make_mat("Fire", (1.0, 0.55, 0.15), rough=0.4, emit=4.0)
    S.add_box("Stick", (0.04, 0.04, 0.38), (0.005, 0.0, 0.12), wood, root, asymmetry=0.25)
    S.add_box("Wrap", (0.07, 0.07, 0.08), (0.0, 0.0, 0.28), wrap, root, asymmetry=0.2)
    S.add_box("Flame", (0.09, 0.08, 0.16), (0.01, 0.01, 0.38), fire, root, asymmetry=0.55)
    S.stylize_hierarchy(root, displace_strength=0.01)
    S.export_glb(S.OUT / "torch.glb")


def build_relic_pedestal() -> None:
    root = _start("RelicPedestal")
    stone = S.make_mat("Stone", (0.35, 0.36, 0.4), rough=0.9)
    crystal = S.make_mat("Crystal", (0.4, 0.85, 1.0), rough=0.25, emit=1.8)
    gold = S.make_mat("Gold", (0.85, 0.65, 0.2), metallic=0.7, rough=0.35)
    S.add_box("Base", (0.55, 0.55, 0.15), (0.02, 0.0, 0.08), stone, root, asymmetry=0.3)
    S.add_box("Pillar", (0.28, 0.28, 0.45), (-0.01, 0.01, 0.38), stone, root, asymmetry=0.25)
    S.add_box("Top", (0.4, 0.4, 0.08), (0.0, 0.0, 0.64), gold, root, asymmetry=0.2)
    S.add_box("Gem", (0.14, 0.14, 0.18), (0.03, -0.02, 0.8), crystal, root, asymmetry=0.45)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "relic_pedestal.glb")


def build_rope_trap() -> None:
    root = _start("RopeTrap")
    rope = S.make_mat("Rope", (0.55, 0.42, 0.22), rough=0.9)
    peg = S.make_mat("Peg", (0.3, 0.2, 0.12), rough=0.92)
    S.add_box("Line", (1.2, 0.04, 0.04), (0.05, 0.0, 0.15), rope, root, asymmetry=0.35)
    S.add_box("Knot", (0.1, 0.1, 0.1), (0.0, 0.02, 0.15), rope, root, asymmetry=0.4)
    S.add_box("PegL", (0.06, 0.06, 0.2), (-0.55, 0.0, 0.1), peg, root, asymmetry=0.2)
    S.add_box("PegR", (0.06, 0.06, 0.2), (0.55, 0.02, 0.1), peg, root, asymmetry=0.25)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "rope_trap.glb")


def build_cut_vines() -> None:
    root = _start("CutVines")
    vine = S.make_mat("Vine", (0.25, 0.45, 0.22), rough=0.9)
    leaf = S.make_mat("Leaf", (0.35, 0.65, 0.25), rough=0.8)
    bark = S.make_mat("Bark", (0.3, 0.22, 0.12), rough=0.95)
    S.add_box("Stem", (0.12, 0.35, 1.8), (0.02, 0.0, 0.9), vine, root, asymmetry=0.4)
    S.add_box("LeafA", (0.35, 0.08, 0.25), (0.25, 0.05, 1.2), leaf, root, rot=(0.2, 0.4, 0.3), asymmetry=0.5)
    S.add_box("LeafB", (0.3, 0.08, 0.22), (-0.22, -0.05, 0.7), leaf, root, rot=(-0.2, -0.3, 0.2), asymmetry=0.45)
    S.add_box("Root", (0.25, 0.25, 0.2), (0.0, 0.0, 0.08), bark, root, asymmetry=0.3)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "cut_vines.glb")


def build_hands() -> None:
    root = _start("Hands")
    skin = S.make_mat("Skin", (0.72, 0.52, 0.4), rough=0.85)
    nail = S.make_mat("Nail", (0.85, 0.75, 0.7), rough=0.7)
    # mão direita (view model)
    palm = S.add_box("Palm", (0.12, 0.06, 0.16), (0.08, 0.0, 0.0), skin, root, asymmetry=0.25)
    for i, x in enumerate((-0.04, -0.01, 0.02, 0.05)):
        S.add_box(f"Finger{i}", (0.022, 0.03, 0.08), (0.08 + x, 0.02, 0.1), skin, root, asymmetry=0.2 + i * 0.05)
    S.add_box("Thumb", (0.03, 0.035, 0.07), (0.02, 0.04, 0.02), skin, root, rot=(0, 0.5, 0.4), asymmetry=0.3)
    S.add_box("Nail0", (0.015, 0.01, 0.02), (0.08, 0.035, 0.14), nail, root, asymmetry=0.1)
    S.stylize_hierarchy(root, displace_strength=0.004)
    S.export_glb(S.OUT / "hands.glb")


def build_player_body() -> None:
    root = _start("PlayerBody")
    cloth = S.make_mat("Cloth", (0.25, 0.3, 0.4), rough=0.9)
    leather = S.make_mat("Leather", (0.35, 0.22, 0.12), rough=0.92)
    skin = S.make_mat("Skin", (0.7, 0.5, 0.4), rough=0.85)
    metal = S.make_mat("Buckle", (0.6, 0.55, 0.35), metallic=0.5, rough=0.45)
    S.add_box("Torso", (0.45, 0.28, 0.55), (0.02, 0.0, 1.15), cloth, root, asymmetry=0.3)
    S.add_box("Belt", (0.48, 0.3, 0.08), (0.0, 0.0, 0.88), leather, root, asymmetry=0.15)
    S.add_box("Buckle", (0.08, 0.04, 0.08), (0.0, 0.14, 0.88), metal, root, asymmetry=0.2)
    S.add_box("Pelvis", (0.4, 0.26, 0.2), (-0.01, 0.0, 0.75), cloth, root, asymmetry=0.2)
    S.add_box("LegL", (0.14, 0.14, 0.7), (-0.12, 0.02, 0.35), cloth, root, asymmetry=0.25)
    S.add_box("LegR", (0.14, 0.14, 0.7), (0.14, -0.01, 0.35), cloth, root, asymmetry=0.3)
    S.add_box("ArmL", (0.1, 0.1, 0.55), (-0.32, 0.0, 1.05), skin, root, asymmetry=0.25)
    S.add_box("ArmR", (0.1, 0.1, 0.55), (0.34, 0.02, 1.05), skin, root, asymmetry=0.28)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "player_body.glb")


def build_campfire() -> None:
    root = _start("Campfire")
    stone = S.make_mat("Stone", (0.4, 0.38, 0.35), rough=0.95)
    wood = S.make_mat("Wood", (0.35, 0.22, 0.12), rough=0.9)
    fire = S.make_mat("Fire", (1.0, 0.5, 0.15), rough=0.4, emit=5.0)
    for i, ang in enumerate((0, 1.2, 2.4, 3.8, 5.0)):
        S.add_box(
            f"Rock{i}",
            (0.25, 0.2, 0.15),
            (math.cos(ang) * 0.45, math.sin(ang) * 0.45, 0.08),
            stone,
            root,
            asymmetry=0.4 + i * 0.05,
        )
    S.add_box("LogA", (0.7, 0.12, 0.12), (0.05, 0.0, 0.15), wood, root, rot=(0, 0, 0.4), asymmetry=0.3)
    S.add_box("LogB", (0.65, 0.12, 0.12), (-0.05, 0.05, 0.2), wood, root, rot=(0, 0, -0.6), asymmetry=0.35)
    S.add_box("Flame", (0.25, 0.25, 0.4), (0.02, 0.0, 0.4), fire, root, asymmetry=0.6)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "campfire.glb")


def build_portal() -> None:
    root = _start("Portal")
    stone = S.make_mat("Stone", (0.3, 0.32, 0.4), rough=0.9)
    crystal = S.make_mat("Gate", (0.35, 0.45, 1.0), rough=0.3, emit=2.0)
    moss = S.make_mat("Moss", (0.25, 0.45, 0.25), rough=0.9)
    S.add_box("PillarL", (0.25, 0.3, 2.4), (-0.7, 0.05, 1.2), stone, root, asymmetry=0.35)
    S.add_box("PillarR", (0.28, 0.28, 2.5), (0.75, -0.02, 1.25), stone, root, asymmetry=0.4)
    S.add_box("Arch", (1.8, 0.35, 0.3), (0.02, 0.0, 2.45), stone, root, asymmetry=0.25)
    S.add_box("Core", (1.0, 0.08, 1.8), (0.0, 0.0, 1.2), crystal, root, asymmetry=0.3)
    S.add_box("Moss", (0.2, 0.15, 0.4), (-0.7, 0.2, 0.5), moss, root, asymmetry=0.5)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "portal.glb")


def _build_npc(filename: str, accent_color, prop_name: str, prop_size, prop_loc, prop_mat_metallic=0.0):
    root = _start(filename.replace(".glb", "").title().replace("_", ""))
    cloth = S.make_mat("Cloth", accent_color, rough=0.9)
    skin = S.make_mat("Skin", (0.7, 0.5, 0.4), rough=0.85)
    leather = S.make_mat("Leather", (0.3, 0.2, 0.12), rough=0.92)
    prop = S.make_mat("Prop", (0.55, 0.55, 0.58), metallic=prop_mat_metallic, rough=0.45)
    S.add_box("Torso", (0.4, 0.28, 0.5), (0.02, 0.0, 1.05), cloth, root, asymmetry=0.35)
    S.add_box("Head", (0.22, 0.22, 0.24), (-0.01, 0.02, 1.45), skin, root, asymmetry=0.25)
    S.add_box("LegL", (0.12, 0.12, 0.55), (-0.1, 0.0, 0.3), leather, root, asymmetry=0.2)
    S.add_box("LegR", (0.12, 0.12, 0.55), (0.12, 0.02, 0.3), leather, root, asymmetry=0.25)
    S.add_box("ArmL", (0.09, 0.09, 0.45), (-0.28, 0.0, 1.0), skin, root, asymmetry=0.2)
    S.add_box("ArmR", (0.09, 0.09, 0.45), (0.3, 0.0, 1.0), skin, root, asymmetry=0.22)
    S.add_box(prop_name, prop_size, prop_loc, prop, root, asymmetry=0.4)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / filename)


def build_npc_blacksmith() -> None:
    _build_npc("npc_blacksmith.glb", (0.35, 0.28, 0.25), "Hammer", (0.08, 0.08, 0.35), (0.4, 0.05, 0.85), 0.5)


def build_npc_alchemist() -> None:
    _build_npc("npc_alchemist.glb", (0.3, 0.4, 0.35), "Flask", (0.1, 0.1, 0.22), (0.38, 0.05, 0.95), 0.1)


def build_npc_cartographer() -> None:
    _build_npc("npc_cartographer.glb", (0.35, 0.32, 0.45), "Scroll", (0.06, 0.22, 0.06), (0.36, 0.08, 0.95), 0.0)


def build_skeleton() -> None:
    root = _start("Skeleton")
    bone = S.make_mat("Bone", (0.9, 0.86, 0.75), rough=0.75)
    dark = S.make_mat("Dark", (0.2, 0.15, 0.25), rough=0.9)
    rust = S.make_mat("Rust", (0.4, 0.25, 0.15), rough=0.85)
    S.add_box("Pelvis", (0.4, 0.22, 0.18), (0.02, 0.0, 0.7), bone, root, asymmetry=0.3)
    S.add_box("Ribs", (0.45, 0.25, 0.45), (-0.01, 0.02, 1.1), bone, root, asymmetry=0.4)
    S.add_box("Skull", (0.28, 0.3, 0.3), (0.03, 0.04, 1.55), bone, root, asymmetry=0.35)
    S.add_box("Jaw", (0.2, 0.12, 0.08), (0.0, 0.1, 1.4), bone, root, asymmetry=0.25)
    S.add_box("LegL", (0.1, 0.1, 0.6), (-0.12, 0.0, 0.3), bone, root, asymmetry=0.25)
    S.add_box("LegR", (0.1, 0.1, 0.6), (0.14, 0.02, 0.3), bone, root, asymmetry=0.3)
    S.add_box("ArmL", (0.08, 0.08, 0.55), (-0.32, 0.0, 1.05), bone, root, asymmetry=0.25)
    S.add_box("ArmR", (0.08, 0.08, 0.55), (0.34, 0.0, 1.05), bone, root, asymmetry=0.28)
    S.add_box("ShieldPad", (0.2, 0.05, 0.25), (-0.4, 0.05, 1.0), dark, root, asymmetry=0.35)
    S.add_box("Sword", (0.05, 0.05, 0.55), (0.42, 0.05, 0.85), rust, root, asymmetry=0.2)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "skeleton.glb")


def build_crystal_bat() -> None:
    root = _start("CrystalBat")
    crystal = S.make_mat("Crystal", (0.45, 0.75, 1.0), rough=0.3, emit=1.6)
    wing = S.make_mat("Wing", (0.3, 0.4, 0.65), rough=0.85)
    dark = S.make_mat("Dark", (0.15, 0.18, 0.3), rough=0.9)
    S.add_box("Body", (0.22, 0.32, 0.18), (0.02, 0.0, 0.3), crystal, root, asymmetry=0.4)
    S.add_box("Head", (0.16, 0.16, 0.16), (0.0, 0.18, 0.38), crystal, root, asymmetry=0.35)
    S.add_box("EarL", (0.04, 0.04, 0.1), (-0.08, 0.15, 0.48), dark, root, asymmetry=0.3)
    S.add_box("EarR", (0.05, 0.04, 0.12), (0.1, 0.14, 0.5), dark, root, asymmetry=0.4)
    S.add_box("WingL", (0.55, 0.06, 0.28), (-0.38, 0.0, 0.32), wing, root, rot=(0, 0.25, 0.45), asymmetry=0.5)
    S.add_box("WingR", (0.5, 0.06, 0.26), (0.4, 0.02, 0.3), wing, root, rot=(0, -0.2, -0.4), asymmetry=0.45)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "crystal_bat.glb")


def build_slime() -> None:
    root = _start("Slime")
    goo = S.make_mat("Goo", (0.3, 0.78, 0.35), rough=0.35, emit=0.5)
    core = S.make_mat("Core", (0.85, 1.0, 0.4), rough=0.3, emit=1.2)
    bubble = S.make_mat("Bubble", (0.5, 0.9, 0.55), rough=0.25)
    S.add_box("Body", (0.75, 0.7, 0.42), (0.03, -0.02, 0.22), goo, root, asymmetry=0.55)
    S.add_box("Blob", (0.35, 0.35, 0.22), (0.15, 0.1, 0.48), goo, root, asymmetry=0.45)
    S.add_box("Core", (0.15, 0.15, 0.15), (-0.05, 0.05, 0.3), core, root, asymmetry=0.3)
    S.add_box("Bubble", (0.1, 0.1, 0.1), (0.25, -0.1, 0.4), bubble, root, asymmetry=0.4)
    S.stylize_hierarchy(root, displace_strength=0.015)
    S.export_glb(S.OUT / "slime.glb")


def build_boss_skeleton() -> None:
    root = _start("BossSkeleton")
    bone = S.make_mat("Bone", (0.92, 0.88, 0.78), rough=0.7)
    dark = S.make_mat("Crown", (0.18, 0.12, 0.28), rough=0.85)
    iron = S.make_mat("Mace", (0.35, 0.35, 0.4), metallic=0.55, rough=0.45)
    S.add_box("Pelvis", (0.6, 0.35, 0.25), (0.03, 0.0, 0.75), bone, root, asymmetry=0.35)
    S.add_box("Torso", (0.75, 0.4, 0.75), (-0.02, 0.03, 1.35), bone, root, asymmetry=0.4)
    S.add_box("Skull", (0.42, 0.42, 0.42), (0.04, 0.06, 1.95), bone, root, asymmetry=0.4)
    S.add_box("Crown", (0.5, 0.5, 0.18), (0.0, 0.0, 2.2), dark, root, asymmetry=0.45)
    S.add_box("LegL", (0.18, 0.18, 0.7), (-0.2, 0.0, 0.32), bone, root, asymmetry=0.3)
    S.add_box("LegR", (0.18, 0.18, 0.7), (0.22, 0.03, 0.32), bone, root, asymmetry=0.35)
    S.add_box("ArmL", (0.15, 0.15, 0.75), (-0.55, 0.0, 1.25), bone, root, asymmetry=0.3)
    S.add_box("ArmR", (0.15, 0.15, 0.75), (0.55, 0.02, 1.25), bone, root, asymmetry=0.32)
    S.add_box("Mace", (0.22, 0.22, 1.0), (0.7, 0.1, 0.85), iron, root, asymmetry=0.35)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "boss_skeleton.glb")


def build_corrupted_miner() -> None:
    root = _start("CorruptedMiner")
    cloth = S.make_mat("Cloth", (0.45, 0.25, 0.15), rough=0.9)
    skin = S.make_mat("Corrupt", (0.45, 0.55, 0.4), rough=0.85)
    iron = S.make_mat("Pick", (0.5, 0.5, 0.55), metallic=0.55, rough=0.45)
    crystal = S.make_mat("Ore", (0.3, 0.8, 0.9), rough=0.3, emit=0.8)
    S.add_box("Torso", (0.42, 0.3, 0.5), (0.02, 0.0, 1.05), cloth, root, asymmetry=0.35)
    S.add_box("Head", (0.24, 0.24, 0.24), (0.0, 0.03, 1.45), skin, root, asymmetry=0.3)
    S.add_box("LegL", (0.13, 0.13, 0.6), (-0.12, 0.0, 0.3), cloth, root, asymmetry=0.25)
    S.add_box("LegR", (0.13, 0.13, 0.6), (0.14, 0.02, 0.3), cloth, root, asymmetry=0.28)
    S.add_box("Pick", (0.1, 0.1, 0.7), (0.4, 0.05, 0.9), iron, root, asymmetry=0.3)
    S.add_box("Ore", (0.12, 0.12, 0.12), (-0.25, 0.1, 1.1), crystal, root, asymmetry=0.5)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "corrupted_miner.glb")


def build_stone_automaton() -> None:
    root = _start("StoneAutomaton")
    stone = S.make_mat("Stone", (0.45, 0.42, 0.4), rough=0.92)
    core = S.make_mat("Core", (1.0, 0.45, 0.15), rough=0.3, emit=2.0)
    iron = S.make_mat("Joint", (0.35, 0.35, 0.4), metallic=0.5, rough=0.5)
    S.add_box("Torso", (0.55, 0.4, 0.7), (0.03, 0.0, 1.15), stone, root, asymmetry=0.4)
    S.add_box("Head", (0.32, 0.32, 0.32), (-0.02, 0.04, 1.7), stone, root, asymmetry=0.35)
    S.add_box("Core", (0.15, 0.1, 0.15), (0.0, 0.2, 1.15), core, root, asymmetry=0.25)
    S.add_box("LegL", (0.18, 0.18, 0.7), (-0.16, 0.0, 0.35), stone, root, asymmetry=0.3)
    S.add_box("LegR", (0.18, 0.18, 0.7), (0.2, 0.03, 0.35), stone, root, asymmetry=0.35)
    S.add_box("ArmL", (0.16, 0.16, 0.65), (-0.42, 0.0, 1.1), iron, root, asymmetry=0.3)
    S.add_box("ArmR", (0.16, 0.16, 0.65), (0.45, 0.02, 1.1), iron, root, asymmetry=0.32)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "stone_automaton.glb")


def build_acid_spider() -> None:
    root = _start("AcidSpider")
    carapace = S.make_mat("Shell", (0.35, 0.55, 0.25), rough=0.75)
    acid = S.make_mat("Acid", (0.7, 1.0, 0.3), rough=0.3, emit=1.0)
    leg = S.make_mat("Leg", (0.25, 0.35, 0.18), rough=0.9)
    S.add_box("Body", (0.45, 0.55, 0.28), (0.02, 0.0, 0.3), carapace, root, asymmetry=0.45)
    S.add_box("Abdomen", (0.4, 0.45, 0.32), (0.0, -0.35, 0.32), carapace, root, asymmetry=0.4)
    S.add_box("AcidSac", (0.18, 0.18, 0.18), (0.05, -0.35, 0.5), acid, root, asymmetry=0.35)
    for i in range(4):
        ang = -0.6 + i * 0.35
        S.add_box(f"LegL{i}", (0.06, 0.35, 0.06), (-0.25, 0.1 * i, 0.15), leg, root, rot=(0, 0, ang), asymmetry=0.3)
        S.add_box(f"LegR{i}", (0.06, 0.35, 0.06), (0.28, 0.08 * i, 0.15), leg, root, rot=(0, 0, -ang), asymmetry=0.32)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "acid_spider.glb")


def build_wood_guardian() -> None:
    root = _start("WoodGuardian")
    bark = S.make_mat("Bark", (0.35, 0.25, 0.14), rough=0.95)
    leaf = S.make_mat("Leaf", (0.3, 0.55, 0.25), rough=0.8)
    moss = S.make_mat("Moss", (0.25, 0.4, 0.2), rough=0.9)
    S.add_box("Trunk", (0.4, 0.35, 1.0), (0.03, 0.0, 0.9), bark, root, asymmetry=0.45)
    S.add_box("Head", (0.35, 0.3, 0.35), (-0.02, 0.05, 1.55), bark, root, asymmetry=0.4)
    S.add_box("ArmL", (0.14, 0.14, 0.7), (-0.35, 0.0, 1.0), bark, root, asymmetry=0.35)
    S.add_box("ArmR", (0.14, 0.14, 0.7), (0.38, 0.03, 1.0), bark, root, asymmetry=0.38)
    S.add_box("LegL", (0.15, 0.15, 0.55), (-0.12, 0.0, 0.28), bark, root, asymmetry=0.3)
    S.add_box("LegR", (0.15, 0.15, 0.55), (0.16, 0.02, 0.28), bark, root, asymmetry=0.32)
    S.add_box("Leaves", (0.5, 0.4, 0.25), (0.05, 0.0, 1.8), leaf, root, asymmetry=0.5)
    S.add_box("Moss", (0.2, 0.15, 0.15), (0.15, 0.15, 0.7), moss, root, asymmetry=0.4)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "wood_guardian.glb")


def build_vine_golem() -> None:
    root = _start("VineGolem")
    vine = S.make_mat("Vine", (0.28, 0.48, 0.22), rough=0.88)
    flower = S.make_mat("Flower", (0.7, 0.35, 0.55), rough=0.7)
    dirt = S.make_mat("Dirt", (0.3, 0.22, 0.14), rough=0.95)
    S.add_box("Body", (0.55, 0.45, 0.9), (0.04, 0.0, 1.0), vine, root, asymmetry=0.5)
    S.add_box("Head", (0.35, 0.32, 0.35), (-0.03, 0.04, 1.65), vine, root, asymmetry=0.4)
    S.add_box("ArmL", (0.16, 0.16, 0.75), (-0.42, 0.0, 1.05), vine, root, asymmetry=0.4)
    S.add_box("ArmR", (0.16, 0.16, 0.75), (0.45, 0.03, 1.05), vine, root, asymmetry=0.42)
    S.add_box("LegL", (0.18, 0.18, 0.6), (-0.15, 0.0, 0.3), dirt, root, asymmetry=0.3)
    S.add_box("LegR", (0.18, 0.18, 0.6), (0.18, 0.02, 0.3), dirt, root, asymmetry=0.35)
    S.add_box("Bloom", (0.2, 0.2, 0.2), (0.1, 0.15, 1.3), flower, root, asymmetry=0.45)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "vine_golem.glb")


def build_foliage_shooter() -> None:
    root = _start("FoliageShooter")
    plant = S.make_mat("Plant", (0.32, 0.55, 0.28), rough=0.85)
    pod = S.make_mat("Pod", (0.55, 0.7, 0.25), rough=0.5, emit=0.4)
    stem = S.make_mat("Stem", (0.35, 0.3, 0.15), rough=0.9)
    S.add_box("Body", (0.35, 0.3, 0.7), (0.02, 0.0, 0.7), plant, root, asymmetry=0.4)
    S.add_box("Head", (0.3, 0.28, 0.3), (0.0, 0.05, 1.2), plant, root, asymmetry=0.35)
    S.add_box("Pod", (0.22, 0.35, 0.22), (0.05, 0.2, 1.15), pod, root, asymmetry=0.4)
    S.add_box("Stem", (0.12, 0.12, 0.45), (0.0, 0.0, 0.22), stem, root, asymmetry=0.25)
    S.add_box("Leaf", (0.4, 0.08, 0.2), (0.25, 0.0, 0.8), plant, root, rot=(0, 0.3, 0.4), asymmetry=0.5)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "foliage_shooter.glb")


def build_grass() -> None:
    root = _start("Grass")
    green = S.make_mat("Green", (0.35, 0.6, 0.25), rough=0.85)
    dark = S.make_mat("Dark", (0.2, 0.4, 0.15), rough=0.9)
    for i in range(5):
        S.add_box(
            f"Blade{i}",
            (0.04, 0.02, 0.25 + i * 0.03),
            ((i - 2) * 0.06, (i % 2) * 0.04, 0.12),
            green if i % 2 == 0 else dark,
            root,
            rot=(0.1 * i, 0, 0.2 * i),
            asymmetry=0.4,
        )
    S.stylize_hierarchy(root, displace_strength=0.012)
    S.export_glb(S.OUT / "grass.glb")


def build_rock_a() -> None:
    root = _start("RockA")
    stone = S.make_mat("Stone", (0.45, 0.43, 0.4), rough=0.95)
    lichen = S.make_mat("Lichen", (0.4, 0.5, 0.3), rough=0.9)
    S.add_box("Main", (0.7, 0.55, 0.45), (0.04, 0.0, 0.22), stone, root, asymmetry=0.6)
    S.add_box("Chunk", (0.3, 0.25, 0.25), (0.25, 0.15, 0.3), stone, root, asymmetry=0.5)
    S.add_box("Lichen", (0.2, 0.15, 0.08), (-0.15, 0.1, 0.35), lichen, root, asymmetry=0.4)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "rock_a.glb")


def build_rock_b() -> None:
    root = _start("RockB")
    stone = S.make_mat("Stone", (0.38, 0.36, 0.4), rough=0.95)
    S.add_box("Main", (0.5, 0.7, 0.35), (-0.03, 0.02, 0.18), stone, root, asymmetry=0.55)
    S.add_box("Tip", (0.25, 0.3, 0.3), (0.15, -0.1, 0.28), stone, root, asymmetry=0.45)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "rock_b.glb")


def build_tree_a() -> None:
    root = _start("TreeA")
    bark = S.make_mat("Bark", (0.32, 0.22, 0.12), rough=0.95)
    leaf = S.make_mat("Leaf", (0.28, 0.5, 0.22), rough=0.85)
    S.add_box("Trunk", (0.25, 0.25, 1.6), (0.04, 0.0, 0.8), bark, root, asymmetry=0.4)
    S.add_box("Canopy", (1.2, 1.1, 0.7), (0.05, 0.05, 1.9), leaf, root, asymmetry=0.55)
    S.add_box("Canopy2", (0.8, 0.7, 0.5), (-0.2, 0.1, 2.3), leaf, root, asymmetry=0.45)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "tree_a.glb")


def build_tree_b() -> None:
    root = _start("TreeB")
    bark = S.make_mat("Bark", (0.28, 0.2, 0.12), rough=0.95)
    leaf = S.make_mat("Leaf", (0.22, 0.42, 0.2), rough=0.85)
    S.add_box("Trunk", (0.2, 0.22, 1.4), (-0.03, 0.02, 0.7), bark, root, asymmetry=0.5)
    S.add_box("Branch", (0.5, 0.1, 0.1), (0.3, 0.0, 1.1), bark, root, rot=(0, 0, 0.4), asymmetry=0.3)
    S.add_box("Canopy", (1.0, 0.9, 0.6), (0.1, 0.0, 1.7), leaf, root, asymmetry=0.5)
    S.stylize_hierarchy(root)
    S.export_glb(S.OUT / "tree_b.glb")


BUILDERS = {
    "sword": build_sword,
    "shield": build_shield,
    "dagger": build_dagger,
    "crossbow": build_crossbow,
    "bolt": build_bolt,
    "crate": build_crate,
    "barrel": build_barrel,
    "vase": build_vase,
    "spikes": build_spikes,
    "torch": build_torch,
    "relic_pedestal": build_relic_pedestal,
    "rope_trap": build_rope_trap,
    "cut_vines": build_cut_vines,
    "hands": build_hands,
    "player_body": build_player_body,
    "campfire": build_campfire,
    "portal": build_portal,
    "npc_blacksmith": build_npc_blacksmith,
    "npc_alchemist": build_npc_alchemist,
    "npc_cartographer": build_npc_cartographer,
    "skeleton": build_skeleton,
    "crystal_bat": build_crystal_bat,
    "slime": build_slime,
    "boss_skeleton": build_boss_skeleton,
    "corrupted_miner": build_corrupted_miner,
    "stone_automaton": build_stone_automaton,
    "acid_spider": build_acid_spider,
    "wood_guardian": build_wood_guardian,
    "vine_golem": build_vine_golem,
    "foliage_shooter": build_foliage_shooter,
    "grass": build_grass,
    "rock_a": build_rock_a,
    "rock_b": build_rock_b,
    "tree_a": build_tree_a,
    "tree_b": build_tree_b,
}


def main(argv: list[str]) -> None:
    only = None
    if "--only" in argv:
        i = argv.index("--only")
        if i + 1 >= len(argv):
            raise SystemExit("Use --only nome1,nome2")
        only = [x.strip() for x in argv[i + 1].split(",") if x.strip()]
    names = only if only else list(BUILDERS.keys())
    for name in names:
        if name not in BUILDERS:
            raise SystemExit(f"Builder desconhecido: {name}. Opções: {', '.join(BUILDERS)}")
        print("Building", name)
        BUILDERS[name]()
    print("Done", len(names), "assets")


if __name__ == "__main__":
    main(sys.argv)

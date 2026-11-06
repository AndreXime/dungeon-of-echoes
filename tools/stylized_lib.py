"""Helpers Blender para low poly stylized flat-shaded."""
from __future__ import annotations

from pathlib import Path

import bpy

OUT = Path(__file__).resolve().parents[1] / "assets" / "models"
OUT.mkdir(parents=True, exist_ok=True)


def reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def setup_preview_lights() -> None:
    scene = bpy.context.scene
    engines = [item.identifier for item in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    if "BLENDER_EEVEE_NEXT" in engines:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    elif "BLENDER_EEVEE" in engines:
        scene.render.engine = "BLENDER_EEVEE"

    eevee = getattr(scene, "eevee", None)
    if eevee is not None:
        if hasattr(eevee, "use_gtao"):
            eevee.use_gtao = True
        if hasattr(eevee, "gtao_distance"):
            eevee.gtao_distance = 0.3

    world = bpy.data.worlds.new("WorldStylized")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (0.04, 0.045, 0.06, 1.0)
        bg.inputs[1].default_value = 0.35

    def lamp(name, typ, loc, energy, color, size=0.5):
        data = bpy.data.lights.new(name=name, type=typ)
        data.energy = energy
        data.color = color
        if typ == "AREA" and hasattr(data, "size"):
            data.size = size
        obj = bpy.data.objects.new(name, data)
        obj.location = loc
        bpy.context.scene.collection.objects.link(obj)
        return obj

    key = lamp("Key", "AREA", (2.5, -2.0, 3.5), 250.0, (1.0, 0.95, 0.85), 1.2)
    key.rotation_euler = (0.9, 0.0, 0.7)
    lamp("Fill", "AREA", (-3.0, -1.0, 2.0), 80.0, (0.55, 0.65, 1.0), 1.5)
    rim = lamp("Rim", "AREA", (0.5, 3.0, 2.5), 120.0, (1.0, 0.7, 0.5), 0.8)
    rim.rotation_euler = (1.1, 0.0, 3.3)


def make_mat(name, color, metallic=0.0, rough=0.85, emit=0.0):
    m = bpy.data.materials.new(name=name)
    m.use_nodes = True
    m.use_backface_culling = True
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Roughness"].default_value = rough
        if "Metallic" in bsdf.inputs:
            bsdf.inputs["Metallic"].default_value = metallic
        if emit > 0:
            if "Emission Color" in bsdf.inputs:
                bsdf.inputs["Emission Color"].default_value = (*color, 1.0)
            if "Emission Strength" in bsdf.inputs:
                bsdf.inputs["Emission Strength"].default_value = emit

        # Vertex color no albedo (necessário para o glTF exportar COLOR)
        base = nt.nodes.new("ShaderNodeRGB")
        base.outputs[0].default_value = (*color, 1.0)
        base.location = (-500, 200)
        vcol = None
        if "ShaderNodeVertexColor" in dir(bpy.types) or hasattr(bpy.types, "ShaderNodeVertexColor"):
            try:
                vcol = nt.nodes.new("ShaderNodeVertexColor")
                if hasattr(vcol, "layer_name"):
                    vcol.layer_name = "Col"
            except RuntimeError:
                vcol = None
        if vcol is None:
            vcol = nt.nodes.new("ShaderNodeAttribute")
            vcol.attribute_name = "Col"
            vcol.attribute_type = "GEOMETRY"
        vcol.location = (-500, 0)
        mix = nt.nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        mix.blend_type = "MULTIPLY"
        mix.inputs["Factor"].default_value = 1.0
        mix.location = (-250, 100)
        # A / B inputs for Mix Color
        nt.links.new(base.outputs[0], mix.inputs["A"])
        # VertexColor Color output or Attribute Color
        src = vcol.outputs.get("Color") or vcol.outputs[0]
        nt.links.new(src, mix.inputs["B"])
        nt.links.new(mix.outputs["Result"], bsdf.inputs["Base Color"])
    return m


def link_object(obj, parent=None):
    bpy.context.scene.collection.objects.link(obj)
    if parent is not None:
        obj.parent = parent
    return obj


def add_empty(name: str, parent=None):
    obj = bpy.data.objects.new(name, None)
    return link_object(obj, parent)


def add_box(name, size, loc, material, parent=None, rot=None, asymmetry=0.0):
    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    link_object(obj, parent)
    sx, sy, sz = size
    ax = 1.0 + asymmetry * 0.15
    ay = 1.0 - asymmetry * 0.08
    hx, hy, hz = (sx * ax) / 2, (sy * ay) / 2, sz / 2
    verts = [
        (-hx, -hy, -hz),
        (hx * (1.0 + asymmetry * 0.05), -hy, -hz),
        (hx, hy, -hz),
        (-hx * (1.0 - asymmetry * 0.04), hy * (1.0 + asymmetry * 0.06), -hz),
        (-hx, -hy, hz),
        (hx, -hy, hz),
        (hx * (1.0 - asymmetry * 0.03), hy, hz),
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
    if rot is not None:
        obj.rotation_euler = rot
    if material is not None:
        obj.data.materials.append(material)
    return obj


def _bbox_min_dim(obj) -> float:
    dims = obj.dimensions
    return max(min(float(dims.x), float(dims.y), float(dims.z)), 0.01)


def stylize(obj, bevel_width=None, displace_strength=0.008):
    if obj.type != "MESH":
        return
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    if bpy.context.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")

    width = bevel_width if bevel_width is not None else _bbox_min_dim(obj) * 0.04
    width = max(min(width, 0.012), 0.0015)

    bevel = obj.modifiers.new(name="Bevel", type="BEVEL")
    bevel.width = width
    bevel.segments = 1
    bevel.limit_method = "ANGLE"
    bevel.angle_limit = 0.7

    tex = bpy.data.textures.new(name=f"Disp_{obj.name}_{len(bpy.data.textures)}", type="CLOUDS")
    tex.noise_scale = 0.65
    disp = obj.modifiers.new(name="Displace", type="DISPLACE")
    disp.texture = tex
    disp.strength = displace_strength * max(_bbox_min_dim(obj) * 1.5, 0.5)
    disp.mid_level = 0.5

    for mod in list(obj.modifiers):
        try:
            bpy.ops.object.modifier_apply(modifier=mod.name)
        except RuntimeError:
            obj.modifiers.remove(mod)

    for poly in obj.data.polygons:
        poly.use_smooth = False
    obj.data.update()
    obj.select_set(False)


def paint_vertex_gradient(obj, dark_base=True):
    if obj.type != "MESH":
        return
    mesh = obj.data
    if not mesh.vertex_colors:
        mesh.vertex_colors.new(name="Col")
    color_layer = mesh.vertex_colors.active
    zs = [v.co.z for v in mesh.vertices]
    zmin, zmax = min(zs), max(zs)
    span = max(zmax - zmin, 1e-5)
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            vi = mesh.loops[li].vertex_index
            t = (mesh.vertices[vi].co.z - zmin) / span
            shade = (0.72 + 0.28 * t) if dark_base else (1.0 - 0.2 * t)
            color_layer.data[li].color = (shade, shade * 0.98, shade * 0.95, 1.0)


def _mesh_children(root):
    out = []
    if root.type == "MESH":
        out.append(root)
    for child in root.children:
        out.extend(_mesh_children(child))
    return out


def stylize_hierarchy(root, displace_strength=0.008):
    for obj in _mesh_children(root):
        stylize(obj, displace_strength=displace_strength)
        paint_vertex_gradient(obj)


def export_glb(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        use_selection=False,
        export_apply=True,
        export_yup=True,
    )
    print("Exported", path)

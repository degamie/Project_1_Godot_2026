import bpy
import bmesh
import math
import random
from mathutils import Vector, Euler, Matrix

def clean_scene():
    """Clear existing objects, meshes, materials, and lights."""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for block in bpy.data.meshes:
        if block.users == 0:
            bpy.data.meshes.remove(block)
    for block in bpy.data.materials:
        if block.users == 0:
            bpy.data.materials.remove(block)

# -------------------------------------------------------------------------
# Procedural PBR Materials (Blender 5.2 Compatible)
# -------------------------------------------------------------------------
def create_mossy_bark_material():
    """Creates furrowed tree bark blended with lush green moss on upward-facing surfaces."""
    mat = bpy.data.materials.new(name="M_MossyBark")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    out = nodes.new('ShaderNodeOutputMaterial')
    bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    bsdf.inputs['Roughness'].default_value = 0.88

    tex_coord = nodes.new('ShaderNodeTexCoord')
    
    # Bark procedural ridges
    mapping = nodes.new('ShaderNodeMapping')
    mapping.inputs['Scale'].default_value = (4.0, 4.0, 0.8)
    
    noise_bark = nodes.new('ShaderNodeTexNoise')
    noise_bark.inputs['Scale'].default_value = 12.0
    noise_bark.inputs['Detail'].default_value = 10.0
    noise_bark.inputs['Roughness'].default_value = 0.75

    ramp_bark = nodes.new('ShaderNodeValToRGB')
    ramp_bark.color_ramp.elements[0].position = 0.3
    ramp_bark.color_ramp.elements[0].color = (0.045, 0.032, 0.022, 1.0)
    ramp_bark.color_ramp.elements[1].position = 0.75
    ramp_bark.color_ramp.elements[1].color = (0.14, 0.10, 0.07, 1.0)

    # World Normal Z mask for top-growing moss
    geom = nodes.new('ShaderNodeNewGeometry')
    sep_xyz = nodes.new('ShaderNodeSeparateXYZ')
    
    noise_moss = nodes.new('ShaderNodeTexNoise')
    noise_moss.inputs['Scale'].default_value = 8.0
    noise_moss.inputs['Detail'].default_value = 6.0

    math_add = nodes.new('ShaderNodeMath')
    math_add.operation = 'ADD'
    
    ramp_mask = nodes.new('ShaderNodeValToRGB')
    ramp_mask.color_ramp.elements[0].position = 0.65
    ramp_mask.color_ramp.elements[0].color = (0.0, 0.0, 0.0, 1.0)
    ramp_mask.color_ramp.elements[1].position = 0.85
    ramp_mask.color_ramp.elements[1].color = (1.0, 1.0, 1.0, 1.0)

    # Moss color variation (emerald to yellow-green)
    ramp_moss = nodes.new('ShaderNodeValToRGB')
    ramp_moss.color_ramp.elements[0].position = 0.3
    ramp_moss.color_ramp.elements[0].color = (0.03, 0.14, 0.02, 1.0)
    ramp_moss.color_ramp.elements[1].position = 0.8
    ramp_moss.color_ramp.elements[1].color = (0.18, 0.32, 0.04, 1.0)

    mix_color = nodes.new('ShaderNodeMix')
    mix_color.data_type = 'RGBA'

    bump = nodes.new('ShaderNodeBump')
    bump.inputs['Strength'].default_value = 0.65
    bump.inputs['Distance'].default_value = 0.08

    links.new(tex_coord.outputs['Object'], mapping.inputs['Vector'])
    links.new(mapping.outputs['Vector'], noise_bark.inputs['Vector'])
    links.new(noise_bark.outputs['Fac'], ramp_bark.inputs['Fac'])

    links.new(geom.outputs['Normal'], sep_xyz.inputs['Vector'])
    links.new(tex_coord.outputs['Object'], noise_moss.inputs['Vector'])
    links.new(sep_xyz.outputs['Z'], math_add.inputs[0])
    links.new(noise_moss.outputs['Fac'], math_add.inputs[1])
    links.new(math_add.outputs['Value'], ramp_mask.inputs['Fac'])
    links.new(noise_moss.outputs['Fac'], ramp_moss.inputs['Fac'])

    links.new(ramp_mask.outputs['Color'], mix_color.inputs['Factor'])
    links.new(ramp_bark.outputs['Color'], mix_color.inputs[6])
    links.new(ramp_moss.outputs['Color'], mix_color.inputs[7])
    links.new(mix_color.outputs[2], bsdf.inputs['Base Color'])

    links.new(noise_bark.outputs['Fac'], bump.inputs['Height'])
    links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])
    links.new(bsdf.outputs['BSDF'], out.inputs['Surface'])
    return mat

def create_foliage_material(name, color_dark, color_bright, sss_weight=0.45):
    """Creates translucent sunlit leaves (lush green canopy or warm golden-amber leaves)."""
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    out = nodes.new('ShaderNodeOutputMaterial')
    bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    bsdf.inputs['Roughness'].default_value = 0.42
    
    if 'Subsurface Weight' in bsdf.inputs:
        bsdf.inputs['Subsurface Weight'].default_value = sss_weight
        bsdf.inputs['Subsurface Radius'].default_value = (0.4, 0.8, 0.1)

    tex_coord = nodes.new('ShaderNodeTexCoord')
    noise = nodes.new('ShaderNodeTexNoise')
    noise.inputs['Scale'].default_value = 3.5
    noise.inputs['Detail'].default_value = 5.0

    ramp = nodes.new('ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].position = 0.25
    ramp.color_ramp.elements[0].color = color_dark
    ramp.color_ramp.elements[1].position = 0.78
    ramp.color_ramp.elements[1].color = color_bright

    links.new(tex_coord.outputs['World'], noise.inputs['Vector'])
    links.new(noise.outputs['Fac'], ramp.inputs['Fac'])
    links.new(ramp.outputs['Color'], bsdf.inputs['Base Color'])
    links.new(bsdf.outputs['BSDF'], out.inputs['Surface'])
    return mat

# -------------------------------------------------------------------------
# Procedural Geometry Builders
# -------------------------------------------------------------------------
def create_organic_branch_mesh(name, points, radii, mat, segments=16, noise_amp=0.12):
    """Sweeps a gnarled, organic trunk or bough along a 3D spline path."""
    mesh = bpy.data.meshes.new(name + "_Mesh")
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)

    bm = bmesh.new()
    rings = []

    for i, (pt, rad) in enumerate(zip(points, radii)):
        if i == 0:
            tangent = (points[1] - points[0]).normalized()
        elif i == len(points) - 1:
            tangent = (points[-1] - points[-2]).normalized()
        else:
            tangent = (points[i + 1] - points[i - 1]).normalized()

        up = Vector((0, 0, 1)) if abs(tangent.z) < 0.95 else Vector((1, 0, 0))
        binormal = tangent.cross(up).normalized()
        normal = binormal.cross(tangent).normalized()

        ring = []
        for s in range(segments):
            angle = (2.0 * math.pi * s) / segments
            # Gnarled bark fluting and root-buttress distortion
            flute = 1.0 + noise_amp * math.sin(angle * 5.0 + i * 0.8) + (noise_amp * 0.5) * math.cos(angle * 3.0 - i)
            r_local = rad * flute
            offset = (binormal * math.cos(angle) + normal * math.sin(angle)) * r_local
            v = bm.verts.new(pt + offset)
            ring.append(v)
        rings.append(ring)

    for i in range(len(rings) - 1):
        r1, r2 = rings[i], rings[i + 1]
        for s in range(segments):
            ns = (s + 1) % segments
            bm.faces.new([r1[s], r1[ns], r2[ns], r2[s]])

    # Cap ends
    bm.faces.new(rings[0][::-1])
    bm.faces.new(rings[-1])

    bm.to_mesh(mesh)
    bm.free()

    sub = obj.modifiers.new(name="Subsurf", type='SUBSURF')
    sub.levels = 2
    sub.render_levels = 2
    for poly in mesh.polygons:
        poly.use_smooth = True

    return obj

def add_foliage_cluster(name, center, radius, count, mat, seed=42):
    """Generates an organic cluster of leaf fronds/icospheres for rich canopy volume."""
    rng = random.Random(seed)
    mesh = bpy.data.meshes.new(name + "_Mesh")
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)

    bm = bmesh.new()
    for _ in range(count):
        offset = Vector((
            rng.uniform(-radius, radius),
            rng.uniform(-radius, radius),
            rng.uniform(-radius * 0.65, radius * 0.65)
        ))
        if offset.length > radius * 1.15:
            offset = offset.normalized() * radius
        
        leaf_size = rng.uniform(0.28, 0.65)
        rot_mat = Euler((rng.uniform(0, 6.28), rng.uniform(0, 6.28), rng.uniform(0, 6.28))).to_matrix().to_4x4()
        trans_mat = Matrix.Translation(center + offset)
        scale_mat = Matrix.Diagonal((leaf_size * 1.4, leaf_size * 0.8, leaf_size * 0.35, 1.0))
        bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0, matrix=trans_mat @ rot_mat @ scale_mat)

    bm.to_mesh(mesh)
    bm.free()
    for poly in mesh.polygons:
        poly.use_smooth = True
    return obj

# -------------------------------------------------------------------------
# Build Reference Forest Composition (Excluding Character)
# -------------------------------------------------------------------------
def build_forest_scene():
    mat_bark = create_mossy_bark_material()
    mat_leaves_green = create_foliage_material(
        "M_CanopyGreen",
        (0.04, 0.18, 0.02, 1.0),
        (0.32, 0.58, 0.06, 1.0),
        sss_weight=0.55
    )
    mat_leaves_gold = create_foliage_material(
        "M_CanopyAmberGold",
        (0.35, 0.16, 0.01, 1.0),
        (0.88, 0.52, 0.04, 1.0),
        sss_weight=0.6
    )

    root = bpy.data.objects.new("Ancient_Forest_Root", None)
    bpy.context.collection.objects.link(root)

    # 1. Foreground Hero Diagonal Mossy Bough (Sweeping from bottom-left to mid-right)
    bough_pts = [
        Vector((-6.5, -5.5, -1.8)),
        Vector((-3.8, -2.5, -0.7)),
        Vector((-1.2, 0.2, 0.15)),
        Vector((1.6, 2.8, 0.95)),
        Vector((4.2, 5.2, 2.2)),
        Vector((7.5, 7.8, 4.5))
    ]
    bough_radii = [1.35, 1.12, 0.95, 0.82, 0.65, 0.35]
    hero_bough = create_organic_branch_mesh("Hero_Diagonal_Bough", bough_pts, bough_radii, mat_bark, segments=20, noise_amp=0.14)
    hero_bough.parent = root

    # Secondary sub-branches sprouting off the hero bough (Right foreground)
    sub_bough_pts = [
        Vector((1.5, 2.7, 0.9)),
        Vector((3.2, 2.2, 1.3)),
        Vector((5.4, 1.6, 1.9)),
        Vector((7.2, 1.2, 2.6))
    ]
    sub_bough = create_organic_branch_mesh("Hero_SubBough_Right", sub_bough_pts, [0.48, 0.36, 0.22, 0.08], mat_bark, segments=12)
    sub_bough.parent = root

    # Golden-green foliage clusters along the right foreground bough
    add_foliage_cluster("Foreground_GoldLeaves_1", Vector((3.8, 2.1, 1.6)), 1.6, 45, mat_leaves_gold, seed=10).parent = root
    add_foliage_cluster("Foreground_GoldLeaves_2", Vector((5.8, 1.5, 2.2)), 1.9, 55, mat_leaves_gold, seed=11).parent = root
    add_foliage_cluster("Foreground_GreenLeaves_3", Vector((2.6, 3.1, 1.9)), 1.5, 40, mat_leaves_green, seed=12).parent = root

    # 2. Colossal Central Ancient Trunk (Rising vertically in mid-ground)
    trunk_pts = [
        Vector((1.8, 6.5, -6.0)),
        Vector((1.6, 6.2, -1.5)),
        Vector((1.4, 5.8, 2.5)),
        Vector((1.9, 6.1, 6.5)),
        Vector((2.6, 6.6, 11.0)),
        Vector((3.2, 7.2, 16.0))
    ]
    trunk_radii = [2.1, 1.75, 1.45, 1.25, 0.95, 0.6]
    central_trunk = create_organic_branch_mesh("Colossal_Central_Trunk", trunk_pts, trunk_radii, mat_bark, segments=24, noise_amp=0.18)
    central_trunk.parent = root

    # Massive Upper Canopy Limbs diverging from Central Trunk
    limb_left_pts = [
        Vector((1.5, 5.9, 5.2)),
        Vector((-1.2, 5.2, 7.8)),
        Vector((-4.5, 4.4, 10.2)),
        Vector((-7.8, 3.8, 12.0))
    ]
    create_organic_branch_mesh("Upper_Limb_Left", limb_left_pts, [0.85, 0.62, 0.4, 0.15], mat_bark).parent = root

    limb_right_pts = [
        Vector((2.1, 6.2, 6.0)),
        Vector((4.8, 5.8, 8.6)),
        Vector((8.2, 5.2, 11.4))
    ]
    create_organic_branch_mesh("Upper_Limb_Right", limb_right_pts, [0.78, 0.52, 0.22], mat_bark).parent = root

    # Lush Upper Canopy Crown (Framing top of shot)
    canopy_positions = [
        (Vector((-3.5, 4.5, 9.5)), 3.2, mat_leaves_green, 20),
        (Vector((0.5, 5.5, 11.0)), 3.8, mat_leaves_green, 21),
        (Vector((4.5, 5.2, 10.2)), 3.4, mat_leaves_green, 22),
        (Vector((-6.8, 3.5, 8.2)), 2.8, mat_leaves_gold, 23),
        (Vector((7.5, 4.2, 7.5)), 2.9, mat_leaves_gold, 24),
    ]
    for idx, (pos, rad, mat, sd) in enumerate(canopy_positions):
        add_foliage_cluster(f"Upper_Canopy_{idx}", pos, rad, 75, mat, seed=sd).parent = root

    # 3. Left Foreground/Midground Amber-Foliage Tree (Framing left edge)
    left_tree_pts = [
        Vector((-6.8, 3.2, -5.0)),
        Vector((-6.5, 3.4, 1.0)),
        Vector((-6.2, 3.6, 6.5)),
        Vector((-5.9, 3.8, 12.0))
    ]
    create_organic_branch_mesh("Left_Framing_Tree", left_tree_pts, [0.85, 0.68, 0.52, 0.32], mat_bark).parent = root
    add_foliage_cluster("Left_Tree_AmberLeaves_1", Vector((-5.5, 2.8, 5.8)), 2.4, 65, mat_leaves_gold, seed=30).parent = root
    add_foliage_cluster("Left_Tree_AmberLeaves_2", Vector((-4.8, 2.2, 3.6)), 2.0, 50, mat_leaves_gold, seed=31).parent = root
    add_foliage_cluster("Left_Tree_GreenLeaves_Top", Vector((-5.8, 3.2, 8.5)), 2.6, 60, mat_leaves_green, seed=32).parent = root

    # 4. Deep Misty Background Forest Trunks & Floor
    bpy.ops.mesh.primitive_plane_add(size=120, location=(0, 25, -8.0))
    floor = bpy.context.active_object
    floor.name = "Forest_Floor"
    floor.data.materials.append(mat_bark)
    floor.parent = root

    rng = random.Random(99)
    for i in range(28):
        bx = rng.uniform(-22.0, 24.0)
        by = rng.uniform(12.0, 42.0)
        brad = rng.uniform(0.35, 0.95)
        b_pts = [
            Vector((bx, by, -8.0)),
            Vector((bx + rng.uniform(-0.4, 0.4), by + rng.uniform(-0.4, 0.4), 4.0)),
            Vector((bx + rng.uniform(-0.8, 0.8), by + rng.uniform(-0.8, 0.8), 18.0))
        ]
        bg_tree = create_organic_branch_mesh(f"BG_Trunk_{i}", b_pts, [brad * 1.2, brad, brad * 0.6], mat_bark, segments=10, noise_amp=0.08)
        bg_tree.parent = root

        if i % 2 == 0:
            add_foliage_cluster(f"BG_Canopy_{i}", Vector((bx, by, rng.uniform(8.0, 14.0))), 3.2, 35, mat_leaves_green, seed=100 + i).parent = root

    return root

# -------------------------------------------------------------------------
# Volumetric Sunbeams (God Rays) & Cinematic Camera Setup
# -------------------------------------------------------------------------
def setup_volumetric_atmosphere_and_camera():
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 64
    scene.cycles.volume_step_rate = 1.5
    scene.cycles.volume_max_steps = 64

    # World Environment with Deep Misty Forest Atmosphere
    world = bpy.data.worlds.new("Forest_World")
    scene.world = world
    world.use_nodes = True
    w_nodes = world.node_tree.nodes
    w_links = world.node_tree.links
    w_nodes.clear()

    w_out = w_nodes.new('ShaderNodeOutputWorld')
    bg = w_nodes.new('ShaderNodeBackground')
    bg.inputs['Color'].default_value = (0.12, 0.18, 0.16, 1.0)
    bg.inputs['Strength'].default_value = 0.85
    w_links.new(bg.outputs['Background'], w_out.inputs['Surface'])

    # Volumetric Scattering Cube for Sun Shafts / God Rays
    bpy.ops.mesh.primitive_cube_add(size=90.0, location=(0, 18.0, 5.0))
    vol_box = bpy.context.active_object
    vol_box.name = "Volumetric_Mist_Domain"
    vol_box.display_type = 'WIRE'

    mat_vol = bpy.data.materials.new("M_ForestVolumetricMist")
    mat_vol.use_nodes = True
    v_nodes = mat_vol.node_tree.nodes
    v_links = mat_vol.node_tree.links
    v_nodes.clear()

    v_out = v_nodes.new('ShaderNodeOutputMaterial')
    vol_scatter = v_nodes.new('ShaderNodeVolumeScatter')
    vol_scatter.inputs['Color'].default_value = (0.78, 0.88, 0.82, 1.0)
    vol_scatter.inputs['Density'].default_value = 0.028
    vol_scatter.inputs['Anisotropy'].default_value = 0.68  # Forward scattering for crisp sunbeams

    v_links.new(vol_scatter.outputs['Volume'], v_out.inputs['Volume'])
    vol_box.data.materials.append(mat_vol)

    # Primary Backlit Sunburst (Positioned upper-right behind canopy to match reference)
    sun_data = bpy.data.lights.new(name="Sun_GodRays", type='SUN')
    sun_data.energy = 8.5
    sun_data.angle = math.radians(1.8)  # Crisp volumetric rays
    sun_data.color = (1.0, 0.93, 0.78)
    sun_obj = bpy.data.objects.new("Sun_GodRays", sun_data)
    bpy.context.collection.objects.link(sun_obj)
    # Angled down-left from upper right background toward the camera
    sun_obj.rotation_euler = (math.radians(64), math.radians(-12), math.radians(142))

    # Dedicated Spot Light to accentuate diagonal god-ray shafts through the branches
    spot_data = bpy.data.lights.new(name="Spot_SunShafts", type='SPOT')
    spot_data.energy = 120000.0
    spot_data.spot_size = math.radians(48)
    spot_data.spot_blend = 0.45
    spot_data.shadow_soft_size = 0.35
    spot_data.color = (1.0, 0.95, 0.82)
    spot_obj = bpy.data.objects.new("Spot_SunShafts", spot_data)
    bpy.context.collection.objects.link(spot_obj)
    spot_obj.location = (11.5, 16.0, 10.5)
    spot_obj.rotation_euler = (math.radians(62), math.radians(0), math.radians(138))

    # Cool Forest Shadow Fill Light (Subtle emerald-teal ambient bounce)
    fill_data = bpy.data.lights.new(name="Area_ForestBounce", type='AREA')
    fill_data.energy = 350.0
    fill_data.size = 14.0
    fill_data.color = (0.35, 0.58, 0.48)
    fill_obj = bpy.data.objects.new("Area_ForestBounce", fill_data)
    bpy.context.collection.objects.link(fill_obj)
    fill_obj.location = (-6.0, -4.0, 4.0)
    fill_obj.rotation_euler = (math.radians(65), 0, math.radians(-45))

    # Wide-Angle Dynamic Camera (Dutch tilt & perspective matching reference)
    cam_data = bpy.data.cameras.new(name="Forest_Ref_Camera")
    cam_data.lens = 24.0
    cam_data.dof.use_dof = True
    cam_data.dof.focus_distance = 7.5
    cam_data.dof.aperture_fstop = 4.0

    cam_obj = bpy.data.objects.new("Camera", cam_data)
    bpy.context.collection.objects.link(cam_obj)
    cam_obj.location = (-3.6, -5.2, 0.45)
    # Tilted slightly upward and rolled to capture the sweeping diagonal bough and towering canopy
    cam_obj.rotation_euler = (math.radians(96), math.radians(-5.5), math.radians(-32))
    scene.camera = cam_obj

# -------------------------------------------------------------------------
# Execute Scene Generation
# -------------------------------------------------------------------------
clean_scene()
build_forest_scene()
setup_volumetric_atmosphere_and_camera()

# Switch Viewport to Rendered / Material Preview
for area in bpy.context.screen.areas:
    if area.type == 'VIEW_3D':
        for space in area.spaces:
            if space.type == 'VIEW_3D':
                space.shading.type = 'MATERIAL'
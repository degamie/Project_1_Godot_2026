import bpy
import math

def clean_scene():
    """Wipe default cube, lights, and cameras."""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

# -----------------------------------------------------------------------------
# 1. Procedural Deep-Water Dynamic Shader (Cycles / Eevee Next)
# -----------------------------------------------------------------------------
def create_deep_ocean_material():
    mat = bpy.data.materials.new(name="M_Mahavatar_DeepOcean")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    # Material Output
    out_node = nodes.new(type="ShaderNodeOutputMaterial")
    out_node.location = (800, 0)

    # Principled BSDF
    bsdf = nodes.new(type="ShaderNodeBsdfPrincipled")
    bsdf.location = (500, 0)
    # Deep Abyssal Azure Color Base
    bsdf.inputs['Base Color'].default_value = (0.015, 0.085, 0.16, 1.0)
    bsdf.inputs['Roughness'].default_value = 0.08
    bsdf.inputs['IOR'].default_value = 1.333
    
    # Transmission for realistic liquid depth & refraction
    if 'Transmission Weight' in bsdf.inputs:
        bsdf.inputs['Transmission Weight'].default_value = 0.94
    elif 'Transmission' in bsdf.inputs:
        bsdf.inputs['Transmission'].default_value = 0.94

    # Volumetric Absorption / Depth Scatter
    vol_absorb = nodes.new(type="ShaderNodeVolumeAbsorption")
    vol_absorb.location = (500, -220)
    vol_absorb.inputs['Color'].default_value = (0.008, 0.045, 0.09, 1.0)
    vol_absorb.inputs['Density'].default_value = 0.45

    # Texture Coordinate & Mapping
    tex_coord = nodes.new(type="ShaderNodeTexCoord")
    tex_coord.location = (-600, 0)

    # Animated Sea-foam & Caustics Noise
    noise_foam = nodes.new(type="ShaderNodeTexNoise")
    noise_foam.location = (-300, 100)
    noise_foam.inputs['Scale'].default_value = 18.0
    noise_foam.inputs['Detail'].default_value = 8.0
    noise_foam.inputs['Roughness'].default_value = 0.72

    # Color Ramp for foam peaks
    color_ramp = nodes.new(type="ShaderNodeValToRGB")
    color_ramp.location = (-50, 100)
    color_ramp.color_ramp.elements[0].position = 0.52
    color_ramp.color_ramp.elements[0].color = (0.015, 0.085, 0.16, 1.0)
    color_ramp.color_ramp.elements[1].position = 0.78
    color_ramp.color_ramp.elements[1].color = (0.65, 0.92, 1.0, 1.0)

    # Normal Bump Node for micro capillary waves
    bump = nodes.new(type="ShaderNodeBump")
    bump.location = (250, -100)
    bump.inputs['Strength'].default_value = 0.25
    bump.inputs['Distance'].default_value = 0.1

    links.new(tex_coord.outputs['Object'], noise_foam.inputs['Vector'])
    links.new(noise_foam.outputs['Fac'], color_ramp
import bpy
import bmesh
import math
from mathutils import Vector, Euler

def clean_scene():
    """Clear existing objects in the default scene."""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

# -------------------------------------------------------------------------
# Shader / Materials (Compatible with Blender 4.x & 5.x)
# -------------------------------------------------------------------------
def create_sacred_gold_material():
    """Creates an ornate ancient Vedic gold shader with micro-roughness & specular warmth."""
    mat = bpy.data.materials.new(name="M_Mukut_Gold")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    node_out = nodes.new(type='ShaderNodeOutputMaterial')
    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')

    # Rich radiant ancient gold base
    bsdf.inputs['Base Color'].default_value = (1.0, 0.76, 0.28, 1.0)
    bsdf.inputs['Metallic'].default_value = 1.0
    bsdf.inputs['Roughness'].default_value = 0.24

    # Micro-relief procedural bump for hand-beaten gold texture
    tex_noise = nodes.new(type='ShaderNodeTexNoise')
    tex_noise.inputs['Scale'].default_value = 45.0
    tex_noise.inputs['Detail'].default_value = 6.0

    bump = nodes.new
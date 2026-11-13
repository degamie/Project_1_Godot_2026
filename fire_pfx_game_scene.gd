#WID(13/11/2026)(Sarthak Mittal(DegamieSign)(fire#particle#sys)
extends Node3D

@export var flare_texture:Texture2D
@export var flame_intensity:float=1.9
var particles:GPUParticles3D

func display_particles(particles:GPUParticles3D)->GPUParticles3D:
	return particles

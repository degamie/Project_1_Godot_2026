#WID(14/11/2026)(Sarthak Mittal(DegamieSign)(fire#particle#sys)
extends Node3D

@export var flare_texture:Texture2D
@export var flame_intensity:float=1.9
func dynamic_flare_texture(flare_texture:Texture2D)->void:
	var flame_flare;
	flame_flare=flare_texture
	
var particles:GPUParticles3D

func display_particles(particles:GPUParticles3D)->GPUParticles3D:
	return particles

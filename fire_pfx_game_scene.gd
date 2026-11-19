#WID(19/11/2026)(Sarthak Mittal(DegamieSign)(fire#particle#sys)
extends Node3D

@export var flare_texture:Texture2D
@export var flame_intensity:float=1.9
@export var _flame_cache=0
@onready var intenisty_of_flame:float=1
func set_flame_intensity(flame_intensity:float)->void:
	flame_intensity=intenisty_of_flame
func flame_enhancement(flame_intensity:float=2.1)->float:
	if(flame_intensity>=0):
		_flame_cache+=flame_intensity
	else:_flame_cache=0
	return _flame_cache
	
func dynamic_flare_texture(flare_texture:Texture2D)->void:
	var flame_flare;
	flame_flare=flare_texture
	
var particles:GPUParticles3D

func display_particles(particles:GPUParticles3D)->GPUParticles3D:
	return particles

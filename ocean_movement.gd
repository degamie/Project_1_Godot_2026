#WID(10/11/2026)(Sarthak Mittal)(DegamieSign)(Ocean#water#script)
extends MeshInstance3D

@export var wave_cntrl:float=50.0
@export var is_wave_moving:bool=true

@export_group("Ocean Water Settings")
@export var ocean_width:float=35.0
@export var ocean_depth: float = 22.0
@export var fish_count: int = 12
@export var bubble_count: int = 45
@export var plankton_count: int = 100

func _ready()->void:
	create_ocean_environment()
func increase_wave_moving(is_wave_moving:bool)->bool:
	is_wave_moving=true;return is_wave_moving

func wave_increase_number(wave_cntrl:float,is_wave_moving:bool)->float:
	while(is_wave_moving!=false):
		if(is_wave_moving!=true):wave_cntrl=10
		else: wave_cntrl=0
	
	return wave_cntrl

func create_ocean_environment() -> void:
	var world_env := WorldEnvironment.new()
	var environment := Environment.new()

	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.002, 0.025, 0.07)

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.12, 0.32, 0.55)
	environment.ambient_light_energy = 0.55

	environment.fog_enabled = true
	environment.fog_light_color = Color(0.015, 0.12, 0.23)
	environment.fog_density = 0.025

	world_env.environment = environment
	add_child(world_env)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -25, 0)
	light.light_color = Color(0.35, 0.65, 1.0)
	light.light_energy = 0.8
	add_child(light)

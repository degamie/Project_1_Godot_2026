#WID(11/11/2026)(Sarthak Mittal)(DegamieSign)(Ocean#water#script)
extends MeshInstance3D

@export var wave_cntrl:float=50.0
@export var is_wave_moving:bool=true

@export_group("Ocean Water Settings")
@export var ocean_width:float=35.0
@export var ocean_depth: float = 22.0
@export var fish_count: int = 12
@export var bubble_count: int = 45
@export var plankton_count: int = 100

@export_group("Animation")
@export var swim_speed:float=5.0
@export  var sway_seed_speed:float=4.5
@export var bubble_speed:float=1.5

var fish_data: Array = []
var bubble_data: Array = []
var seaweed_data: Array = []
var plankton_data: Array = []

var elapsed_time:=0.0
func _process(delta:flaot)->void:
	elapsed_time+=delta
func animate_plankton()->void:
	particle.scale=Vector3.ONE(.7+glow*1.0)
func _ready()->void:
	create_ocean_environment()
	create_camera()
	create_ocean_flooar()
func increase_wave_moving(is_wave_moving:bool)->bool:
	is_wave_moving=true;return is_wave_moving

func wave_increase_number(wave_cntrl:float,is_wave_moving:bool)->float:
	while(is_wave_moving!=false):
		if(is_wave_moving!=true):wave_cntrl=10
		else: wave_cntrl=0
	
	return wave_cntrl
	
func create_ocean_flooar()->void:
		var floor := MeshInstance3D.new();var plane := PlaneMesh.new()
		
		plane.size = Vector2(ocean_width, ocean_width)
		floor.mesh = plane
		floor.position = Vector3(0, -5, 0)
		floor.material_override = create_material(
		Color(0.025, 0.065, 0.09)
	)
		add_child(floor)

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
	
	func create_camera() -> void:
	var camera := Camera3D.new()

	camera.position = Vector3(0, 3, 15)
	camera.fov = 70
	camera.current = true

	add_child(camera)
	camera.look_at(Vector3(0, 0, 0))
#func _ready() -> void:
	#amount = 800
	#lifetime = 8.0
	#preprocess = 4.0
	#visibility_aabb = AABB(Vector3(-20, -10, -20), Vector3(40, 20, 40))
	#
	#var mat := ParticleProcessMaterial.new()
	#mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	#mat.emission_box_extents = Vector3(15.0, 8.0, 15.0)
	#
	## Gentle slow upward and lateral drift
	#mat.direction = Vector3(0.1, 1.0, 0.05)
	#mat.spread = 35.0
	#mat.initial_velocity_min = 0.15
	#mat.initial_velocity_max = 0.45
	#mat.gravity = Vector3(0.0, 0.08, 0.0) # Floats gently upward
	#
	## Size variation
	#mat.scale_min = 0.02
	#mat.scale_max = 0.08
	#mat.color = Color(0.7, 0.9, 1.0, 0.35)
	#
	#process_material = mat
	#
	## Billboard Quad for particle drawing
	#var quad := QuadMesh.new()
	#quad.size = Vector2(0.08, 0.08)
	#var std_mat := StandardMaterial3D.new()
	#std_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	#std_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	#std_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	#quad.material = std_mat
	#draw_pass=1

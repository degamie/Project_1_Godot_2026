
# WID(13/11/2026)
# Sarthak Mittal (DegamieSign)
# Ocean Water / Deep Sea Animation

extends MeshInstance3D

@export_group("Wave Controller")
@export_range(0.0, 100.0, 1.0)
var wave_cntrl: float = 50.0

@export var is_wave_moving: bool = true

@export_group("Ocean Water Settings")
@export var ocean_width: float = 35.0
@export var ocean_depth: float = 22.0

@export var fish_count: int = 12
@export var bubble_count: int = 45
@export var plankton_count: int = 100

@export_group("Animation")
@export var swim_speed: float = 5.0
@export var sway_seed_speed: float = 4.5
@export var bubble_speed: float = 1.5
@export var ocean_level:float=10.0
var fish_data: Array = []
var bubble_data: Array = []
var seaweed_data: Array = []
var plankton_data: Array = []

var elapsed_time: float = 0.0

var water_material: ShaderMaterial

func update_water_material(water_material: ShaderMaterial)->ShaderMaterial:
	get_water_material(water_material)+set_water_material(water_material)+1
# ==========================================
# INITIALIZATION
# ==========================================

func _ready() -> void:
	randomize()

	create_water_mesh()
	create_ocean_environment()
	create_camera()
	create_ocean_floor()
	create_rocks()


func _process(delta: float) -> void:
	elapsed_time += delta

	update_wave_controller()


# ==========================================
# WATER MESH
# ==========================================

func create_water_mesh() -> void:

	var plane := PlaneMesh.new()

	plane.size = Vector2(ocean_width, ocean_depth)

	# More subdivisions = smoother vertex waves.
	plane.subdivide_width = 100
	plane.subdivide_depth = 100

	mesh = plane

	water_material = ShaderMaterial.new()

	var water_shader := Shader.new()

	water_shader.code = """
    shader_type spatial;
    render_mode blend_mix, depth_draw_opaque;

    uniform float wave_amplitude = 0.5;
    uniform float wave_frequency = 1.5;
    uniform float wave_speed = 1.0;

    uniform bool waves_enabled = true;

    void vertex() {

        if (waves_enabled) {

            float wave1 = sin(
                VERTEX.x * wave_frequency + TIME * wave_speed
            );

            float wave2 = cos(
                VERTEX.z * wave_frequency * 0.8
                + TIME * wave_speed * 0.7
            );

            VERTEX.y += (
                wave1 + wave2
            ) * wave_amplitude;

        }
    }

    void fragment() {

        vec3 deep_blue = vec3(0.005, 0.12, 0.28);
        vec3 ocean_blue = vec3(0.01, 0.35, 0.55);

        float depth_color = clamp(
            UV.y + 0.2,
            0.0,
            1.0
        );

        ALBEDO = mix(
            deep_blue,
            ocean_blue,
            depth_color
        );

        METALLIC = 0.15;
        ROUGHNESS = 0.18;

        ALPHA = 0.88;
    }
	"""

	water_material.shader = water_shader

	material_override = water_material

	update_wave_controller()


# ==========================================
# WAVE CONTROLLER
# ==========================================

func update_wave_controller() -> void:

	if water_material == null:
		return

	var amplitude: float = wave_cntrl * 0.01

	water_material.set_shader_parameter(
		"wave_amplitude",
		amplitude
	)

	water_material.set_shader_parameter(
		"waves_enabled",
		is_wave_moving
	)

	water_material.set_shader_parameter(
		"wave_speed",
		sway_seed_speed
	)


func increase_wave_moving(value: bool) -> bool:

	is_wave_moving = value

	update_wave_controller()

	return is_wave_moving


func wave_increase_number(
	amount: float,
	moving: bool
) -> float:

	wave_cntrl = clampf(amount, 0.0, 100.0)

	is_wave_moving = moving

	update_wave_controller()

	return wave_cntrl


# ==========================================
# MATERIAL CREATION
# ==========================================

func create_material(
	color: Color,
	glow: float = 0.0
) -> StandardMaterial3D:

	var mat := StandardMaterial3D.new()

	mat.albedo_color = color

	if glow > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = glow

	return mat


# ==========================================
# OCEAN FLOOR
# ==========================================

func create_ocean_floor() -> void:

	var ocean_floor := MeshInstance3D.new()

	var plane := PlaneMesh.new()

	plane.size = Vector2(
		ocean_width,
		ocean_width
	)

	ocean_floor.mesh = plane

	ocean_floor.position = Vector3(
		0,
		-5,
		0
	)

	ocean_floor.material_override = create_material(
		Color(0.025, 0.065, 0.09)
	)

	add_child(ocean_floor)


# ==========================================
# ROCK GENERATION
# ==========================================

func create_rocks() -> void:

	for i in range(35):

		var rock := create_sphere(
			randf_range(0.3, 0.9),
			Color(0.025, 0.07, 0.11),
			Vector3(
				randf_range(-17, 17),
				-4.7,
				randf_range(-10, 5)
			),
			Vector3(
				randf_range(1.0, 2.0),
				randf_range(0.5, 1.2),
				randf_range(1.0, 2.0)
			)
		)


func create_sphere(
	radius: float,
	color: Color,
	pos: Vector3,
	object_scale: Vector3 = Vector3.ONE
) -> MeshInstance3D:

	var sphere := MeshInstance3D.new()

	var sphere_mesh := SphereMesh.new()

	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0

	sphere.mesh = sphere_mesh

	sphere.material_override = create_material(color)

	sphere.position = pos
	sphere.scale = object_scale

	add_child(sphere)

	return sphere


# ==========================================
# UNDERWATER ENVIRONMENT
# ==========================================

func create_ocean_environment() -> void:

	var world_env := WorldEnvironment.new()

	var environment := Environment.new()

	environment.background_mode = Environment.BG_COLOR

	environment.background_color = Color(
		0.002,
		0.025,
		0.07
	)

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR

	environment.ambient_light_color = Color(
		0.12,
		0.32,
		0.55
	)

	environment.ambient_light_energy = 0.55

	environment.fog_enabled = true

	environment.fog_light_color = Color(
		0.015,
		0.12,
		0.23
	)

	environment.fog_density = 0.025

	world_env.environment = environment

	add_child(world_env)

	var light := DirectionalLight3D.new()

	light.rotation_degrees = Vector3(
		-35,
		-25,
		0
	)

	light.light_color = Color(
		0.35,
		0.65,
		1.0
	)

	light.light_energy = 0.8

	add_child(light)


# ==========================================
# CAMERA
# ==========================================

func create_camera() -> void:

	var camera := Camera3D.new()

	camera.position = Vector3(
		0,
		3,
		15
	)

	camera.fov = 70

	add_child(camera)

	camera.look_at(Vector3.ZERO)

	camera.current = true

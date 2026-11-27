#WID(27/11/2026)(Sarthak Mittal)(DegamieSign)(Universe Scene)(Star field Creation)
extends Node3D

@export_group("Universe Settings")
@export var universe_radius: float = 370.0
@export var stars_cnt: int = 2100
@export var universe_speed: float = 0.015

@export_group("Cosmic Energy")
@export var core_radius: float = 18.0
@export var core_glow_energy: float = 7.0

@export_group("Planet Settings")
@export var planet_count: int = 8

var star_instance := MultiMeshInstance3D.new()
var rng := RandomNumberGenerator.new()
var universe_root: Node3D
var planets: Array[Node3D] = []
var core: Node3D


func _ready() -> void:
	rng.randomize()
	universe_root = Node3D.new()
	universe_root.name = "UniverseRoot"
	add_child(universe_root)

	create_nebula()
	create_cosmic_lighting()
	create_camera()
	create_star_field()


func _process(delta: float) -> void:
	if universe_root:
		universe_root.rotate_y(universe_speed * delta)


# ---------------------------------------------------------
# SETTERS & MODIFIERS
# ---------------------------------------------------------

func set_universe_radius(new_radius: float) -> void:
	universe_radius = new_radius


func increase_universe_radius(amount: float = 1.0) -> void:
	universe_radius += amount


func set_stars_cnt(new_count: int) -> void:
	stars_cnt = new_count


func increase_stars_cnt(amount: int = 1) -> void:
	stars_cnt += amount


func set_universe_speed(new_speed: float) -> void:
	universe_speed = new_speed


# ---------------------------------------------------------
# STAR FIELD CREATION
# ---------------------------------------------------------

func create_star_field() -> void:
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.35
	star_mesh.height = 0.7

	var star_mat := StandardMaterial3D.new()
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_mat.emission_enabled = true
	star_mat.emission = Color(1.0, 0.98, 0.9)
	star_mat.emission_energy_multiplier = 2.5
	star_mat.vertex_color_use_as_albedo = true
	star_mesh.material = star_mat

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = star_mesh
	multimesh.instance_count = stars_cnt

	for i in range(stars_cnt):
		var pos := random_sphere_position(universe_radius)
		var star_scale := rng.randf_range(0.4, 1.6)
		var basis := Basis().scaled(Vector3.ONE * star_scale)
		multimesh.set_instance_transform(i, Transform3D(basis, pos))

		# Subtle star color tint (blue-white to warm yellow)
		var tint := Color.from_hsv(rng.randf_range(0.08, 0.65), rng.randf_range(0.0, 0.35), 1.0)
		multimesh.set_instance_color(i, tint)

	star_instance.name = "StarField"
	star_instance.multimesh = multimesh
	universe_root.add_child(star_instance)


# ---------------------------------------------------------
# NEBULA & LIGHTING
# ---------------------------------------------------------

func create_nebula() -> void:
	var nebula_colors: Array[Color] = [
		Color(0.35, 0.05, 0.8, 0.12),
		Color(0.08, 0.3, 0.9, 0.12),
		Color(0.85, 0.1, 0.25, 0.12),
		Color(0.95, 0.45, 0.08, 0.12),
		Color(0.2, 0.05, 0.5, 0.12)
	]

	for i in range(28):
		var nebula := MeshInstance3D.new()
		nebula.name = "NebulaCloud_%02d" % i

		var mesh := SphereMesh.new()
		mesh.radius = 1.0
		mesh.height = 2.7
		nebula.mesh = mesh

		var material := StandardMaterial3D.new()
		var chosen_color := nebula_colors[rng.randi_range(0, nebula_colors.size() - 1)]
		material.albedo_color = chosen_color
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.emission_enabled = true
		material.emission = Color(chosen_color.r, chosen_color.g, chosen_color.b)
		material.emission_energy_multiplier = 1.5

		nebula.material_override = material
		nebula.position = random_sphere_position(universe_radius * 0.5)
		nebula.scale = Vector3(
			rng.randf_range(20.0, 60.0),
			rng.randf_range(8.0, 30.0),
			rng.randf_range(20.0, 60.0)
		)
		universe_root.add_child(nebula)


func create_cosmic_lighting() -> void:
	var light := DirectionalLight3D.new()
	light.name = "CosmicLighting"
	light.rotation_degrees = Vector3(0.55, 0.1, 0.65)
	light.light_color = Color(0.45, 0.55, 1.0)
	light.energy = 0.45
	universe_root.add_child(light)


# ---------------------------------------------------------
# CAMERA & HELPERS
# ---------------------------------------------------------

func create_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "CosmicCamera"
	camera.position = Vector3(0.0, 12.0, 95.0)
	camera.fov = 70.0
	camera.near = 0.1
	camera.far = universe_radius * 3.0

	add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)


func random_sphere_position(max_radius: float) -> Vector3:
	var theta := rng.randf_range(0.0, TAU)
	var cos_phi := rng.randf_range(-1.0, 1.0)
	var sin_phi := sqrt(max(0.0, 1.0 - cos_phi * cos_phi))
	var r := max_radius * pow(rng.randf(), 1.0 / 3.0)

	return Vector3(
		r * sin_phi * cos(theta),
		r * cos_phi,
		r * sin_phi * sin(theta)
	)

extends Node3D
## Procedural universe / solar system scene.
## Controls: click = capture mouse, Esc = release, WASD = fly, Space/E = up, Q/Ctrl = down,
## Shift = boost, 0 = sun, 1-8 = jump to planet, +/- = time speed, P = pause, O = toggle orbit lines.

const PLANETS := [
	{"name": "Mercury", "radius": 0.8, "dist": 20.0, "period": 10.0, "color": Color(0.62, 0.58, 0.55), "spin": 1.0},
	{"name": "Venus", "radius": 1.5, "dist": 30.0, "period": 16.0, "color": Color(0.9, 0.7, 0.4), "spin": -0.5},
	{"name": "Earth", "radius": 1.6, "dist": 42.0, "period": 24.0, "color": Color(0.2, 0.45, 0.85), "spin": 3.0, "moon": true},
	{"name": "Mars", "radius": 1.1, "dist": 54.0, "period": 36.0, "color": Color(0.8, 0.35, 0.2), "spin": 2.8},
	{"name": "Jupiter", "radius": 5.0, "dist": 90.0, "period": 70.0, "color": Color(0.85, 0.65, 0.45), "spin": 5.0},
	{"name": "Saturn", "radius": 4.2, "dist": 120.0, "period": 100.0, "color": Color(0.9, 0.8, 0.55), "spin": 4.5, "ring": true},
	{"name": "Uranus", "radius": 2.8, "dist": 148.0, "period": 140.0, "color": Color(0.5, 0.82, 0.9), "spin": 3.5},
	{"name": "Neptune", "radius": 2.7, "dist": 172.0, "period": 180.0, "color": Color(0.25, 0.35, 0.9), "spin": 3.4},
]

var cam: Camera3D
var hud: Label
var orbit_lines: Node3D
var belt: Node3D
var sun: MeshInstance3D
var orbit_pivots: Array[Node3D] = []
var planet_nodes: Array[Node3D] = []
var spinners: Array[Node3D] = []
var moon_pivot: Node3D

var yaw := 0.0
var pitch := -0.25
var velocity := Vector3.ZERO
var time_scale := 1.0
var paused := false
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = 20261010
	_setup_environment()
	_make_starfield()
	_make_sun()
	_make_planets()
	_make_asteroid_belt()
	_make_camera()
	_make_hud()
	_jump_to(-1)


func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.12, 0.13, 0.2)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 1.0
	env.glow_bloom = 0.15
	env.glow_hdr_threshold = 0.9
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _make_starfield() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color.WHITE
	mesh.material = mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = 2500
	for i in mm.instance_count:
		var dir := Vector3(rng.randfn(), rng.randfn(), rng.randfn()).normalized()
		var s := rng.randf_range(0.8, 2.6)
		var xf := Transform3D(Basis().scaled(Vector3.ONE * s), dir * rng.randf_range(1400.0, 1800.0))
		mm.set_instance_transform(i, xf)
		var tint := rng.randf()
		var col := Color(1.0, 0.85 + tint * 0.15, 0.7 + tint * 0.3)
		if rng.randf() < 0.3:
			col = Color(0.7, 0.8, 1.0)
		mm.set_instance_color(i, col)
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mat.vertex_color_use_as_albedo = true
	add_child(inst)


func _surface_material(base: Color, noise_freq: float = 0.02) -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = noise_freq
	noise.seed = rng.randi()
	var grad := Gradient.new()
	grad.colors = PackedColorArray([base.darkened(0.4), base, base.lightened(0.3)])
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.color_ramp = grad
	tex.seamless = true
	tex.width = 512
	tex.height = 256
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = 0.9
	return mat


func _make_sun() -> void:
	sun = MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 10.0
	mesh.height = 20.0
	mesh.radial_segments = 64
	mesh.rings = 32
	sun.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.8, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.65, 0.15)
	mat.emission_energy_multiplier = 2.5
	sun.material_override = mat
	sun.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sun)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.92, 0.8)
	light.light_energy = 6.0
	light.omni_range = 600.0
	light.omni_attenuation = 0.6
	light.shadow_enabled = true
	add_child(light)


func _make_planets() -> void:
	orbit_lines = Node3D.new()
	add_child(orbit_lines)

	for p in PLANETS:
		var pivot := Node3D.new()
		pivot.rotation.y = rng.randf() * TAU
		add_child(pivot)
		orbit_pivots.append(pivot)

		var holder := Node3D.new()
		holder.position = Vector3(p["dist"], 0, 0)
		pivot.add_child(holder)
		planet_nodes.append(holder)

		var body := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = p["radius"]
		mesh.height = p["radius"] * 2.0
		mesh.radial_segments = 48
		mesh.rings = 24
		body.mesh = mesh
		body.material_override = _surface_material(p["color"], 0.015 if p["name"] in ["Jupiter", "Saturn"] else 0.03)
		body.rotation.z = deg_to_rad(rng.randf_range(0.0, 25.0))
		holder.add_child(body)
		spinners.append(body)

		# Atmosphere halo for Earth/Venus
		if p["name"] in ["Earth", "Venus"]:
			var atmo := MeshInstance3D.new()
			var am := SphereMesh.new()
			am.radius = p["radius"] * 1.06
			am.height = p["radius"] * 2.12
			atmo.mesh = am
			var amat := StandardMaterial3D.new()
			amat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			amat.albedo_color = Color(0.5, 0.7, 1.0, 0.18)
			amat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			amat.cull_mode = BaseMaterial3D.CULL_BACK
			atmo.material_override = amat
			atmo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			holder.add_child(atmo)

		if p.get("ring", false):
			var ring := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = p["radius"] * 1.7
			tm.outer_radius = p["radius"] * 2.5
			tm.rings = 96
			tm.ring_segments = 8
			ring.mesh = tm
			ring.scale = Vector3(1, 0.02, 1)
			ring.rotation.z = deg_to_rad(18.0)
			var rmat := StandardMaterial3D.new()
			rmat.albedo_color = Color(0.85, 0.75, 0.55, 0.85)
			rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			rmat.roughness = 1.0
			ring.material_override = rmat
			holder.add_child(ring)

		if p.get("moon", false):
			moon_pivot = Node3D.new()
			holder.add_child(moon_pivot)
			var moon := MeshInstance3D.new()
			var mm := SphereMesh.new()
			mm.radius = 0.45
			mm.height = 0.9
			moon.mesh = mm
			moon.material_override = _surface_material(Color(0.75, 0.75, 0.78), 0.06)
			moon.position = Vector3(4.0, 0, 0)
			moon_pivot.add_child(moon)

		_make_orbit_line(p["dist"])


func _make_orbit_line(radius: float) -> void:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var segs := 160
	for i in segs + 1:
		var a := float(i) / segs * TAU
		im.surface_add_vertex(Vector3(cos(a) * radius, 0, sin(a) * radius))
	im.surface_end()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.4, 0.6, 1.0, 0.25)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	orbit_lines.add_child(mi)


func _make_asteroid_belt() -> void:
	belt = Node3D.new()
	add_child(belt)
	var mesh := SphereMesh.new()
	mesh.radius = 0.35
	mesh.height = 0.7
	mesh.radial_segments = 6
	mesh.rings = 4
	mesh.material = _surface_material(Color(0.5, 0.45, 0.4), 0.2)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = 1800
	for i in mm.instance_count:
		var a := rng.randf() * TAU
		var r := rng.randf_range(65.0, 78.0)
		var pos := Vector3(cos(a) * r, rng.randfn(0.0, 1.2), sin(a) * r)
		var b := Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU))
		b = b.scaled(Vector3(rng.randf_range(0.4, 1.6), rng.randf_range(0.4, 1.2), rng.randf_range(0.4, 1.6)))
		mm.set_instance_transform(i, Transform3D(b, pos))
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	belt.add_child(inst)


func _make_camera() -> void:
	cam = Camera3D.new()
	cam.far = 4000.0
	cam.near = 0.1
	cam.fov = 70.0
	add_child(cam)


func _make_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(16, 12)
	hud.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	hud.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	hud.add_theme_constant_override("shadow_offset_x", 1)
	hud.add_theme_constant_override("shadow_offset_y", 1)
	layer.add_child(hud)


func _jump_to(index: int) -> void:
	# index -1 = overview of the whole system, otherwise planet index
	velocity = Vector3.ZERO
	if index < 0:
		cam.global_position = Vector3(0, 120, 260)
		yaw = 0.0
		pitch = -0.4
	else:
		var p: Dictionary = PLANETS[index]
		var target: Vector3 = planet_nodes[index].global_position
		var offset := Vector3(0, p["radius"] * 1.2, p["radius"] * 4.5 + 4.0)
		cam.global_position = target + offset
		yaw = 0.0
		pitch = -0.15
	cam.rotation = Vector3(pitch, yaw, 0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.0028
		pitch = clampf(pitch - event.relative.y * 0.0028, -1.55, 1.55)
		cam.rotation = Vector3(pitch, yaw, 0)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_P:
				paused = not paused
			KEY_O:
				orbit_lines.visible = not orbit_lines.visible
			KEY_EQUAL, KEY_KP_ADD:
				time_scale = minf(time_scale * 2.0, 64.0)
			KEY_MINUS, KEY_KP_SUBTRACT:
				time_scale = maxf(time_scale * 0.5, 0.125)
			KEY_0:
				_jump_to(-1)
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8:
				_jump_to(event.keycode - KEY_1)


func _process(delta: float) -> void:
	var dt := 0.0 if paused else delta * time_scale

	sun.rotate_y(dt * 0.05)
	for i in PLANETS.size():
		orbit_pivots[i].rotate_y(dt * TAU / PLANETS[i]["period"])
		spinners[i].rotate_y(dt * PLANETS[i]["spin"])
	if moon_pivot:
		moon_pivot.rotate_y(dt * 1.6)
	belt.rotate_y(dt * 0.04)

	_fly(delta)

	var nearest := ""
	var nearest_d := INF
	for i in PLANETS.size():
		var d := cam.global_position.distance_to(planet_nodes[i].global_position)
		if d < nearest_d:
			nearest_d = d
			nearest = PLANETS[i]["name"]
	hud.text = "UNIVERSE  |  Nearest: %s (%.0f u)  |  Time x%s%s\nWASD fly  Space/Q up/down  Shift boost  1-8 planets  0 overview  +/- time  P pause  O orbits  Click: capture mouse, Esc: release" % [
		nearest, nearest_d, str(time_scale), " (paused)" if paused else ""]


func _fly(delta: float) -> void:
	var dir := Vector3.ZERO
	var b := cam.global_transform.basis
	if Input.is_key_pressed(KEY_W): dir -= b.z
	if Input.is_key_pressed(KEY_S): dir += b.z
	if Input.is_key_pressed(KEY_A): dir -= b.x
	if Input.is_key_pressed(KEY_D): dir += b.x
	if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_E): dir += Vector3.UP
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_CTRL): dir -= Vector3.UP
	var speed := 30.0
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= 5.0
	velocity = velocity.lerp(dir.normalized() * speed, 1.0 - exp(-5.0 * delta))
	cam.global_position += velocity * delta

#WID(21/11/2026)(Sarthak Mittal(DegamieSign)
@tool
class_name ForestRenovator
extends Node3D
## Adds green grass, foliage, brown trunks with branches, logs and stumps
## on top of the imported forest FBX. Everything is generated (not saved into
## the .tscn), so the scene stays light. Change a value in the Inspector and
## tick "Rebuild" to regenerate inside the editor.

@export_group("Area")
@export var area_size := 40.0
@export var seed_value := 1234
## Keeps the middle of the scene (spawn / path) free of big objects.
@export var clearing_radius := 3.0

@export_group("Ground & Grass")
@export var add_ground := true
@export var ground_y := -0.02
@export_range(0, 80000) var grass_count := 25000
@export var grass_base_color := Color(0.10, 0.33, 0.07)
@export var grass_tip_color := Color(0.42, 0.78, 0.22)
@export var wind_strength := 0.18

@export_group("Trees, Logs & Foliage")
@export var x := 22.0
@export var bush_count := 35
@export var log_count := 10
@export var stump_count := 6
@export var add_collision := true

func increase_bush_count(bush_count := 35)->void:
	bush_count+=1
	

func create_fog_mist_volume(pos:Vector3,volume_size:Vector3)->void:
	#Code to be continued


@export var rebuild := false:
	set(v):
		rebuild = false
		if v and is_inside_tree():
			_build()

const GRASS_SHADER := """
shader_type spatial;
render_mode cull_disabled;

uniform vec4 base_color : source_color = vec4(0.10, 0.33, 0.07, 1.0);
uniform vec4 tip_color : source_color = vec4(0.42, 0.78, 0.22, 1.0);
uniform float wind_strength = 0.18;
uniform float wind_speed = 1.6;
varying float h;

void vertex() {
	h = UV.y;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float s = sin(TIME * wind_speed + wp.x * 0.7 + wp.z * 0.5);
	float s2 = cos(TIME * wind_speed * 0.7 + wp.z * 0.9);
	VERTEX.x += s * wind_strength * h * h;
	VERTEX.z += s2 * wind_strength * 0.5 * h * h;
}

void fragment() {
	vec3 patch_tint = vec3(1.0) + 0.10 * sin(vec3(INSTANCE_CUSTOM.x));
	ALBEDO = mix(base_color.rgb, tip_color.rgb, h) * patch_tint;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
}
"""

var _rng := RandomNumberGenerator.new()
var _bark: Array[StandardMaterial3D] = []
var _wood_end: StandardMaterial3D
var _leaves: Array[StandardMaterial3D] = []
var _half := 20.0


func _ready() -> void:
	_build()

func add_tree_count(tree_count:float=10)->void:
	tree_count+=1
func _build() -> void:
	var old := get_node_or_null("Generated")
	if old:
		remove_child(old)
		old.free()

	_rng.seed = seed_value
	_half = area_size * 0.5
	_make_materials()

	var root := Node3D.new()
	root.name = "Generated"
	add_child(root)

	if add_ground:
		root.add_child(_make_ground())
	if grass_count > 0:
		root.add_child(_make_grass())

	var trees := Node3D.new()
	trees.name = "Trees"
	root.add_child(trees)
	for i in tree_count:
		trees.add_child(_make_tree(_rand_pos()))

	var bushes := Node3D.new()
	bushes.name = "Bushes"
	root.add_child(bushes)
	for i in bush_count:
		bushes.add_child(_make_bush(_rand_pos()))

	var logs := Node3D.new()
	logs.name = "LogsAndStumps"
	root.add_child(logs)
	for i in log_count:
		logs.add_child(_make_log(_rand_pos()))
	for i in stump_count:
		logs.add_child(_make_stump(_rand_pos()))


# ---------------------------------------------------------------- materials

func _make_materials() -> void:
	_bark.clear()
	_leaves.clear()
	for c in [Color(0.33, 0.20, 0.10), Color(0.28, 0.17, 0.08), Color(0.40, 0.26, 0.13)]:
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.95
		_bark.append(m)

	_wood_end = StandardMaterial3D.new()
	_wood_end.albedo_color = Color(0.55, 0.38, 0.20)
	_wood_end.roughness = 0.9

	for c in [Color(0.13, 0.42, 0.12), Color(0.20, 0.52, 0.15), Color(0.28, 0.60, 0.18)]:
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.85
		_leaves.append(m)


func _pick(arr: Array) -> StandardMaterial3D:
	return arr[_rng.randi() % arr.size()]


# ------------------------------------------------------------------- helpers

func _rand_pos() -> Vector3:
	for i in 30:
		var p := Vector3(_rng.randf_range(-_half, _half), 0.0, _rng.randf_range(-_half, _half))
		if Vector2(p.x, p.z).length() >= clearing_radius:
			return p
	return Vector3(_half, 0.0, _half)


func _cyl(top_r: float, bottom_r: float, h: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = h
	mesh.radial_segments = 10
	mesh.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = null
	mi.set_surface_override_material(0, mat)
	mi.set_surface_override_material(1, _wood_end)
	mi.set_surface_override_material(2, _wood_end)
	return mi


func _blob(pos: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 1.7
	mesh.radial_segments = 14
	mesh.rings = 7
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation.y = _rng.randf() * TAU
	return mi


func _solid_cyl(radius: float, h: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = h
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	return body


# -------------------------------------------------------------------- ground

func _make_ground() -> MeshInstance3D:
	var plane := PlaneMesh.new()
	plane.size = Vector2(area_size * 1.2, area_size * 1.2)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.13, 0.30, 0.08)
	mat.roughness = 1.0
	var mi := MeshInstance3D.new()
	mi.name = "GrassGround"
	mi.mesh = plane
	mi.material_override = mat
	mi.position.y = ground_y
	return mi


# --------------------------------------------------------------------- grass

func _grass_blade_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := 0.05
	var h := 0.55
	for k in 3:
		var a := k * PI / 3.0
		var d := Vector3(cos(a), 0.0, sin(a))
		var bl := -d * w
		var br := d * w
		var ml := -d * w * 0.7 + Vector3(0, h * 0.5, 0)
		var mr := d * w * 0.7 + Vector3(0, h * 0.5, 0)
		var tip := d * 0.01 + Vector3(0, h, 0)
		var verts := [bl, br, mr, bl, mr, ml, ml, mr, tip]
		var uvs := [0.0, 0.0, 0.5, 0.0, 0.5, 0.5, 0.5, 0.5, 1.0]
		for i in 9:
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(0.5, uvs[i]))
			st.add_vertex(verts[i])
	return st.commit()


func _make_grass() -> MultiMeshInstance3D:
	var shader := Shader.new()
	shader.code = GRASS_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("base_color", grass_base_color)
	mat.set_shader_parameter("tip_color", grass_tip_color)
	mat.set_shader_parameter("wind_strength", wind_strength)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = _grass_blade_mesh()
	mm.instance_count = grass_count
	for i in grass_count:
		var pos := Vector3(_rng.randf_range(-_half, _half), ground_y, _rng.randf_range(-_half, _half))
		var s := _rng.randf_range(0.6, 1.5)
		var b := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s, s))
		mm.set_instance_transform(i, Transform3D(b, pos))
		mm.set_instance_custom_data(i, Color(_rng.randf() * 10.0, 0, 0, 0))

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Grass"
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mmi


# --------------------------------------------------------------------- trees

func _make_tree(pos: Vector3) -> Node3D:
	var tree := Node3D.new()
	tree.name = "Tree"
	tree.position = pos
	tree.rotation.y = _rng.randf() * TAU

	var h := _rng.randf_range(4.5, 8.0)
	var r := _rng.randf_range(0.25, 0.45)
	var bark := _pick(_bark)

	var trunk := _cyl(r * 0.6, r, h, bark)
	trunk.position.y = h * 0.5
	tree.add_child(trunk)

	if add_collision:
		var body := _solid_cyl(r, h)
		body.position.y = h * 0.5
		tree.add_child(body)

	# Branches with leaf clusters at their tips.
	var branches := _rng.randi_range(3, 6)
	for i in branches:
		var y := h * _rng.randf_range(0.45, 0.92)
		var angle := _rng.randf() * TAU
		var dir := Vector3(cos(angle), _rng.randf_range(0.5, 1.1), sin(angle)).normalized()
		var length := _rng.randf_range(1.4, 2.6)
		var br := r * 0.28
		var base := Vector3(0, y, 0)
		var branch := _cyl(br * 0.5, br, length, bark)
		branch.position = base + dir * length * 0.5
		branch.basis = Basis(Quaternion(Vector3.UP, dir))
		tree.add_child(branch)

		var tip := base + dir * length
		var leaf_mat := _pick(_leaves)
		tree.add_child(_blob(tip, _rng.randf_range(1.0, 1.6), leaf_mat))
		tree.add_child(_blob(tip + Vector3(_rng.randf_range(-0.5, 0.5), 0.5, _rng.randf_range(-0.5, 0.5)),
				_rng.randf_range(0.7, 1.1), _pick(_leaves)))

	# Crown on top.
	tree.add_child(_blob(Vector3(0, h + 0.6, 0), _rng.randf_range(1.6, 2.3), _pick(_leaves)))
	tree.add_child(_blob(Vector3(0.4, h - 0.3, -0.3), _rng.randf_range(1.2, 1.7), _pick(_leaves)))
	return tree


func _make_bush(pos: Vector3) -> Node3D:
	var bush := Node3D.new()
	bush.name = "Bush"
	bush.position = pos
	for i in _rng.randi_range(3, 5):
		var r := _rng.randf_range(0.4, 0.8)
		bush.add_child(_blob(Vector3(_rng.randf_range(-0.6, 0.6), r * 0.7, _rng.randf_range(-0.6, 0.6)),
				r, _pick(_leaves)))
	return bush


# ----------------------------------------------------------- logs and stumps

func _make_log(pos: Vector3) -> Node3D:
	var length := _rng.randf_range(2.5, 5.0)
	var r := _rng.randf_range(0.2, 0.4)
	var holder: Node3D = _solid_cyl(r, length) if add_collision else Node3D.new()
	holder.name = "Log"
	holder.position = Vector3(pos.x, r * 0.9, pos.z)
	holder.basis = Basis(Vector3.UP, _rng.randf() * TAU) * Basis(Vector3.BACK, PI * 0.5)
	holder.add_child(_cyl(r, r * 1.05, length, _pick(_bark)))

	# A couple of broken branch stubs sticking out of the log.
	for i in _rng.randi_range(1, 3):
		var stub_len := _rng.randf_range(0.5, 1.0)
		var stub := _cyl(r * 0.12, r * 0.22, stub_len, _pick(_bark))
		var sign_x := 1.0 if _rng.randf() < 0.5 else -1.0
		var dir := Vector3(sign_x, 0.8, _rng.randf_range(-0.6, 0.6)).normalized()
		stub.position = Vector3(0, _rng.randf_range(-length * 0.35, length * 0.35), 0) + dir * (r + stub_len * 0.3)
		stub.basis = Basis(Quaternion(Vector3.UP, dir))
		holder.add_child(stub)
	return holder


func _make_stump(pos: Vector3) -> Node3D:
	var h := _rng.randf_range(0.4, 0.9)
	var r := _rng.randf_range(0.3, 0.5)
	var holder: Node3D = _solid_cyl(r, h) if add_collision else Node3D.new()
	holder.name = "Stump"
	holder.position = Vector3(pos.x, h * 0.5, pos.z)
	var mesh := _cyl(r * 0.9, r * 1.15, h, _pick(_bark))
	holder.add_child(mesh)
	return holder

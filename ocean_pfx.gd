#WID(13/11/2026)(Sarthak Mittal)(Ocean#pfx#1)
extends GPUParticles3D

@export var amount:float:=100
func _ready() -> void:
	amount = 800
	lifetime = 8.0
	preprocess = 4.0
	visibility_aabb = AABB(Vector3(-20, -10, -20), Vector3(40, 20, 40))
	
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(15.0, 8.0, 15.0)
	
	# Gentle slow upward and lateral drift
	mat.direction = Vector3(0.1, 1.0, 0.05)
	mat.spread = 35.0
	mat.initial_velocity_min = 0.15
	mat.initial_velocity_max = 0.45
	mat.gravity = Vector3(0.0, 0.08, 0.0) # Floats gently upward
	
	# Size variation
	mat.scale_min = 0.02
	mat.scale_max = 0.08
	mat.color = Color(0.7, 0.9, 1.0, 0.35)
	
	process_material = mat
	
	# Billboard Quad for particle drawing
	var quad := QuadMesh.new()
	quad.size = Vector2(0.08, 0.08)
	var std_mat := StandardMaterial3D.new()
	std_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	std_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	std_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	quad.material = std_mat
	draw_pass=1

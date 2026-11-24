#WID(24/11/2026)(Sarthak Mittal(DegamieSign)(Universe Scene)(Nebula and Lighting)
extends Node3D

@export_group("Universe Settings")
@export var universe_radius:float=370.0
@export var stars_cnt:float=2100
@export var universe_speed:float=.015

var star_instance=MultiMeshInstance3D.new()

@export_group("Cosmic Energy")
@export var core_radius: float = 18.0
@export var core_glow_energy: float = 7.0

@export_group("Planet Settings")
@export var planet_count: int = 8

func set_stars_cnt(stars_cnt:float)->void:
	this.stars_cnt=stars_cnt
var rng:=RandomNumberGenerator.new()
var universe_root: Node3D
var planets: Array[Node3D] = []
var core: Node3D

func _ready()->void:
	rng.randomize()
	universe_root=Node3D.new()
	create_nebula()
	create_cosmic_lighting()
	#create_camera()

	#create_divine_energy()
	
	#create_starfield()
	#create_universe()
	
	add_child(universe_root)
	
#Methods to be imolemented
#func create_camera()->void:
	#
#func create_divine_energy()->void:
		#
func create_nebula()->void:
	var nebula_colors:Array[Color]=[
		Color(.35,.05,.8),
		Color(0.08, 0.3, 0.9),
		Color(0.85, 0.1, 0.25),
		Color(0.95, 0.45, 0.08),
		Color(0.2, 0.05, 0.5)
	]
	for i in range(28):
		var nebula := MeshInstance3D.new()
		nebula.name = "NebulaCloud_%02d" % i
		
		var mesh:=SphereMesh.new()
		mesh.radius=1.0 
		mesh.height=2.7 
		nebula.mesh=mesh
	var material := StandardMaterial3D.new()
	
	material.albedo_color = nebula_colors[
			rng.randi_range(0, nebula_colors.size() - 1)
		]
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy_multiplier = 1.5

	nebula.material_override = material
	nebula.position = random_sphere_position(universe_radius * 0.5)
	nebula.scale = Vector3(
			rng.randf_range(20.0, 60.0),
			rng.randf_range(8.0, 30.0),
			rng.randf_range(20.0, 60.0)
		 )
		universe_root.add_child(nebula)

	func create_cosmic_lighting()->void:
		var light=DirectionalLight3D.new()
#func create_starfield()->void:
	#
#func create_universe()->void:
	#

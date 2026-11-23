#WID(23/11/2026)(Sarthak Mittal(DegamieSign)(Universe Scene)
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

var rng:=RandomNumberGenerator.new()
var universe_root: Node3D
var planets: Array[Node3D] = []
var core: Node3D

func _ready()->void:
	rng.randomize()
	universe_root=Node3D.new()
	create_camera()
	create_cosmic_lighting()
	create_divine_energy()
	create_nebula()
	create_starfield()
	create_universe()
	
	add_child(universe_root)
	
#Methods to be imolemented
#func create_camera()->void:
	#
#func create_divine_energy()->void:
		#
#func create_nebula()->void:
	#
#func create_starfield()->void:
	#
#func create_universe()->void:
	#
#func create_cosmic_lighting()->void:


 

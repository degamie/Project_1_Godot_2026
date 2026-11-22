extends Node3D

@export_group("Universe Settings")
@export var universe_radius:float=370.0
@export var stars_cnt:float=2100
@export var universe_speed:float=.015


@export_group("Cosmic Energy")
@export var core_radius: float = 18.0
@export var core_glow_energy: float = 7.0

@export_group("Planet Settings")
@export var planet_count: int = 8

var rng:=RandomNumberGenerator.new()
var universe_root: Node3D
var planets: Array[Node3D] = []
var core: Node3D

 

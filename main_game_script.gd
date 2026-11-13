#WID(13/11/2026)(Sarthak Mittal)(DegamieSign)(Main Game Script)
extends Node3D

const narsimha_action_src=preload("res://game-scene/mdl/NarSimha_God_Model/nar_simha_action.gd")
const worldmapscript=preload("res://src/worlmapsrc.gd")
const thirdplayersrc=preload("res://src/third_person_controller.gd")

const MAP_SCENES:Dictionary={
	&"Palace_Scene":preload("res://game-scene/palace_game_scene.tscn"),
	&"ocean_water_Scene":preload("res://game-scene/ocean_water.tscn"),
	&"universe_Scene":preload("res://game-scene/universe_Scene.tscn"),
}
var current_map_scene:worldmapscript

#func set_current_map_scene(current_map_scene:worldmapscript)->worldmapscript:
	#this.current_map_scene=current_map_scene
#@export_category(map_control:String)
@onready var map_container:Node3D=$WorldRoot/MapContainer
@onready var map_view:Viewport=$WorldRoot/Viewport
@onready var location_label:Label=$UILayerHUD/Location

@export var map_grid:Array=map_container
func handle_location_label(location_label:Label)->void:
	location_label=map_grid

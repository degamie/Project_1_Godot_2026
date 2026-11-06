#WID(6/11/2026)(Sarthak Mittal)(DegamieSign)(Main Game Script)
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

@onready var map_container:Node3D="$WorldRoot/MapContainer"
@onready var map_view:Viewport="$WorldRoot/Viewport"

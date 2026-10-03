#WID(03/10/2026)(Sarthak Mittal)(DegamieSign)(NpCController(script)
class_name Dialogue_resource extends ResourcePreloader

@export_multiline  var dialogue_lines:Array[String]=[]
@export_multiline var speaker_name:String="NPC Controller";
@onready ui_node=get_tree().get_first_node_in_group("DialogureResourceUI");

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#WID(3/10/2026)(Sarthak Mittal)(DegamieSign)(NPCDialogueSystem)
class_name NPCDiaglogue extends CanvasLayer
signal dialogue_finished # Emitted when the chat ends
@onready var name_label:Label=$Panel/NameLabel

@onready var text_label: RichTextLabel = $Panel/RichTextLabel
var curr_lines:Array[String]=[]
var is_active:bool=false
var indx_lines:int=0
#@export_group("Dialogues",FileDialog)
var data:DialogueData=new(curr_lines);
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false # Hide dialogue box on startup

func start_dialogue(data: DialogueData) -> void:
	if is_active: return
	
	curr_lines = data.dialogue_lines
	name_label.text = data.speaker_name
	indx_lines = 0
	is_active = true
	visible = true
	
	show_line()

func show_line() -> void:
	text_label.text = curr_lines[indx_lines]
	# Optional Typewriter Effect:
	text_label.visible_ratio = 0.0
	var tween = create_tween()
	tween.tween_property(text_label, "visible_ratio", 1.0, 0.5)

func _unhandled_input(event: InputEvent) -> void:
	if not is_active: return
	
	# Advances dialogue using the default UI Accept action (Enter/Space)
	if event.is_action_pressed("ui_accept"):
		advance_dialogue()

func advance_dialogue() -> void:
	indx_lines += 1
	if indx_lines < curr_lines.size():
		show_line()
	else:
		end_dialogue()

func end_dialogue() -> void:
	is_active = false
	visible = false
	dialogue_finished.emit() # Notify the NPC that interaction is over

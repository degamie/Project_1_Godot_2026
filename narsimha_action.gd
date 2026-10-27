#WID(27/10/2026)(Sarthak Mittal(DegamieSign)(NarSimha(action))
extends CharacterBody3D
@onready var bitezone:Area3D=$MouthBiteZone
@export var hunger_restore:float=20.0
@export var bite_damage: float = 50.0
var current_hunger: float = 100.0
var is_eating: bool = false

var lion_roar_range:float=100
func set_lion_roar_range(lion_roar_range:float)->void:
	this.lion_roar_range=lion_roar_range;
func restoring_hunger(hunger_restore:float)->float:
	return hunger_restore
	
func can_eat(is_eating:bool)->bool:
	return is_eating
func _process(delta: float) -> void:
	# Keep track of the lion's hunger over time
	current_hunger = max(0.0, current_hunger - delta * 0.5)
	
	# Trigger the eating ability (e.g., pressing the 'E' key or gamepad button)
	if Input.is_action_just_pressed("eat") and not is_eating:
		attempt_to_eat()

func attempt_to_eat() -> void:
	# Look inside the bite zone for valid targets
	var targets = bite_zone.get_overlapping_bodies()
	
	for body in targets:
		if body.is_in_group("prey"):
			start_eating_sequence(body)
			return # Stop searching once food is found

func start_eating_sequence(target: Node) -> void:
	is_eating = true
	velocity = Vector3.ZERO # Freeze movement during the animation
	
	# Play the eating/biting animation
	if animation_player.has_animation("eat_bite"):
		animation_player.play("eat_bite")
	
	# If the prey has a health system or a take_damage function, call it
	if target.has_method("take_damage"):
		target.take_damage(bite_damage)
	
	# Restore hunger and cleanly remove the target object
	current_hunger = min(100.0, current_hunger + hunger_restoration)
	
	# Optional: Use a timer or animation callback to reset the eating flag
	await animation_player.animation_finished
	is_eating = false

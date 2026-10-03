#//WID(01/10/2026)(Sarthak Mittal(DegamieSign)(ThirdPersonController(jump(ability)#1.1.1
extends CharacterBody3D
## Third-person controller: WASD/arrow movement relative to the camera
## (so the player can walk toward any part of the room, in any direction
## the camera happens to be facing), mouse-look via an orbiting camera rig,
## and jumping.
#
# Expected scene layout:
# CharacterBody3D (this script)
# ├─ CollisionShape3D
# ├─ CharacterModel      (MeshInstance3D placeholder, or your imported model)
# └─ CameraPivot         (Node3D)
#    └─ SpringArm3D
#       └─ Camera3D

@export var can_move: bool = true
@export var has_gravity: bool = true
@export var can_jump: bool = true
@export var can_E: bool = true

@export_group("Speeds")
@export var look_speed: float = .0075
@export var base_speed: float =16.5
@export var E_speed: float =50
@export var jump_velocity: float =10
@export var turn_speed: float = 12.5 # how fast the model turns to face movement

@export_group("Camera")
@export var min_pitch_deg: float = -60.0
@export var max_pitch_deg: float = 28

@export_group("Input Actions")
@export var input_forward: String = "ui_up"
@export var input_left: String = "ui_left"
@export var input_right: String = "ui_right"
#@export var input_forward: String = "W"
@export var input_back: String = "ui_down"
@export var input_jump: String = "ui_accept"
@export var input_E: String = "E"  # optional; safely disabled if not mapped

var mouse_captured: bool = false
var move_speed: float = 1

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var model: Node3D = $CharacterModel

func _ready() -> void:
	if can_E and not InputMap.has_action(input_E):
		push_warning("Eing disabled. Add an InputAction named '" + input_E + "' in Project Settings to enable it.")
		can_E = false
	capture_mouse()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:

		capture_mouse()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		release_mouse()

	if mouse_captured and event is InputEventMouseMotion:
		# Yaw: orbit the whole camera rig around the player.
		camera_pivot.rotate_y(-event.relative.x * look_speed)
		# Pitch: tilt the spring arm up/down, clamped so it can't flip over.
		var pitch :float = spring_arm.rotation_degrees.x - event.relative.y * look_speed * 57.3
		pitch = clamp(pitch, min_pitch_deg, max_pitch_deg)
		spring_arm.rotation_degrees.x = pitch
		# If mouse-look feels inverted on either axis, flip the sign above.

func _physics_process(delta: float) -> void:
	if has_gravity and not is_on_floor():
		velocity += get_gravity() * delta  # Godot 4.3+; see note below for older versions

	if can_jump and Input.is_action_just_pressed(input_jump) and is_on_floor():
		velocity.y = jump_velocity

	move_speed = E_speed if (can_E and Input.is_action_pressed(input_E)) else base_speed

	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		# Movement is relative to the camera's current yaw, not the character's
		# own facing, so the player can walk in every direction in the room
		# simply by looking that way and pressing forward.
		var cam_basis := camera_pivot.global_transform.basis
		var flat_right := Vector3(cam_basis.x.x, 0, cam_basis.x.z).normalized()
		var flat_back := Vector3(cam_basis.z.x, 0, cam_basis.z.z).normalized()
		var move_dir := input_dir.x * flat_right + input_dir.y * flat_back
		if move_dir.length() > 0.01:
			move_dir = move_dir.normalized()
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
			# Smoothly turn the visible model to face where it's walking.
			# If your model faces backward, add PI to target_angle below.
			var target_angle := atan2(move_dir.x, move_dir.z)
			model.rotation.y = lerp_angle(model.rotation.y, target_angle, turn_speed * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0;velocity.z = 0

	move_and_slide()

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

# Note: get_gravity() requires Godot 4.3+. On older 4.x versions replace it with:
#   Vector3.DOWN * ProjectSettings.get_setting("physics/3d/default_gravity")

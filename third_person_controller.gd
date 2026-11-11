extends CharacterBody3D
## Third-person controller: WASD/arrow movement relative to the camera
## Mouse-look via an orbiting camera rig, and jumping.

@export var can_move: bool = true
@export var has_gravity: bool = true
@export var can_jump: bool = true
@export var can_sprint: bool = true

@export_group("Speeds")
@export var look_speed: float = 0.004
@export var base_speed: float = 6.0
@export var sprint_speed: float = 10.0
@export var jump_velocity: float = 4.8
@export var turn_speed: float = 10.0

@export_group("Camera")
@export var min_pitch_deg: float = -60.0
@export var max_pitch_deg: float = 20.0

@export_group("Input Actions")
@export var input_left: String = "ui_left"
@export var input_right: String = "ui_right"
@export var input_forward: String = "ui_up"
@export var input_back: String = "ui_down"
@export var input_jump: String = "ui_accept"
@export var input_sprint: String = "sprint"

var mouse_captured: bool = false
var move_speed: float = 0.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var model: Node3D = $CharacterModel

func _ready() -> void:
	if can_sprint and not InputMap.has_action(input_sprint):
		push_warning("Sprinting disabled. Add an InputAction named '" + input_sprint + "' in Project Settings.")
		can_sprint = false
	capture_mouse()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		capture_mouse()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		release_mouse()

	if mouse_captured and event is InputEventMouseMotion:
		camera_pivot.rotate_y(-event.relative.x * look_speed)
		var pitch: float = spring_arm.rotation_degrees.x - event.relative.y * look_speed * 57.3
		pitch = clamp(pitch, min_pitch_deg, max_pitch_deg)
		spring_arm.rotation_degrees.x = pitch

func _physics_process(delta: float) -> void:
	if has_gravity and not is_on_floor():
		velocity += get_gravity() * delta

	if can_jump and Input.is_action_just_pressed(input_jump) and is_on_floor():
		velocity.y = jump_velocity

	move_speed = sprint_speed if (can_sprint and Input.is_action_pressed(input_sprint)) else base_speed

	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var cam_basis := camera_pivot.global_transform.basis
		var flat_right := Vector3(cam_basis.x.x, 0, cam_basis.x.z).normalized()
		var flat_back := Vector3(cam_basis.z.x, 0, cam_basis.z.z).normalized()
		var move_dir := input_dir.x * flat_right + input_dir.y * flat_back
		if move_dir.length() > 0.01:
			move_dir = move_dir.normalized()
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
			var target_angle := atan2(move_dir.x, move_dir.z)
			model.rotation.y = lerp_angle(model.rotation.y, target_angle, turn_speed * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

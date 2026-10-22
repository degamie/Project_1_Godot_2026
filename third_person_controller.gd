# WID(22/10/2026)
# Sarthak Mittal | DegamieSign
# ThirdPersonController -Slight Jump

extends CharacterBody3D

@export_group("npc_orchestrator")
@export var orchestrator: bool = true
@export var cam_run: bool = true
@export var can_move: bool = true
@export var has_gravity: bool = true
@export var can_jump: bool = true
@export var can_E: bool = true

@export_group("Speeds")
@export var mouse_sensitivity: float = 0.003
@export var base_speed: float = 15.0
@export var E_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var swift_jump: float = 7.95
@export var turn_speed: float = 12.0

@export_group("Camera")
@export var min_pitch_deg: float = -60.0
@export var max_pitch_deg: float = 61.5

@export_group("Input Actions")
@export var input_forward: String = "ui_up"
@export var input_left: String = "ui_left"
@export var input_right: String = "ui_right"
@export var input_back: String = "ui_down"
@export var input_jump: String = "ui_accept"
@export var input_E: String = "E"
@export var add_wasd: bool = true

var mouse_captured: bool = false
var move_speed: float = 5.0
@export var slide_jump:float =7.9
@export var long_jump:float=9.9


@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var model: Node3D = $CharacterModel

func turning_speed(turn_speed:float)->float:
	return turn_speed 
func can_capture_mouse(mouse_captured:bool)->bool:
	if(mouse_captured!=false)mouse_captured=true
	else mouse_capture=false

func move_camera_pivot(camera_pivot: Node3D)->Node3D:
	return camera_pivot
	
func moving_speed(move_speed:float)->float:
	return move_speed;
func can_add_wasd(add_wasd:bool)->bool:
	return add_wasd
	
func load_camera(camera:Camera3D)->Camera3D:
	return Camera3D
func load_model(model:Node3D)->Node3D:
	return model
	
func load_spring_arm(SpringArm3D)->SpringArm3D:
	return SpringArm3D

func _ready() -> void:
	if add_wasd:
		_bind_key(input_forward, KEY_W)
		_bind_key(input_left, KEY_A)
		_bind_key(input_back, KEY_S)
		_bind_key(input_right, KEY_D)

	if can_E:
		_bind_key(input_E, KEY_E)

	move_speed = base_speed
	capture_mouse()


func _bind_key(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

	# Avoid adding duplicate physical-key bindings.
	for existing_event in InputMap.action_get_events(action):
		if existing_event is InputEventKey:
			if existing_event.physical_keycode == keycode:
				return

	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)

func agile_long_jump(long_jump:float)->float:
	return long_jump
	
func _is_E_pressed() -> bool:
	if not can_E:
		return false

	if InputMap.has_action(input_E):
		return Input.is_action_pressed(input_E)

	return Input.is_key_pressed(KEY_E)


func capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_captured = true


func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	mouse_captured = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			capture_mouse()

	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			release_mouse()

	if mouse_captured and event is InputEventMouseMotion:
		# Camera yaw
		camera_pivot.rotate_y(
			-event.relative.x * mouse_sensitivity
		)

		# Camera pitch
		spring_arm.rotate_x(
			-event.relative.y * mouse_sensitivity
		)

		spring_arm.rotation.x = clampf(
			spring_arm.rotation.x,
			deg_to_rad(min_pitch_deg),
			deg_to_rad(max_pitch_deg)
		)


func _physics_process(delta: float) -> void:
	# Gravity
	if has_gravity and not is_on_floor():
		velocity += get_gravity() * delta

	# Swift jump: hold E and press the jump action.
	if can_jump and Input.is_action_just_pressed(input_jump):
		if is_on_floor():
			velocity.y = (
				swift_jump if _is_E_pressed()
				else jump_velocity
			)

	# Speed selection
	move_speed = E_speed if _is_E_pressed() else base_speed

	if can_move:
		var input_dir := Input.get_vector(
			input_left,
			input_right,
			input_forward,
			input_back
		)

		# Select camera-relative or character-relative movement.
		var ref_basis: Basis

		if cam_run:
			ref_basis = camera_pivot.global_transform.basis
		else:
			ref_basis = global_transform.basis

		# Flatten the basis so looking up/down does not affect movement.
		var flat_right := Vector3(
			ref_basis.x.x, 0.0, ref_basis.x.z
		).normalized()

		var flat_forward := Vector3(
			ref_basis.z.x, 0.0, ref_basis.z.z
		).normalized()

		# Godot's character forward direction is -Z.
		var move_dir := (
			flat_right * input_dir.x
			+ flat_forward * input_dir.y
		)

		if move_dir.length_squared() > 1.0:
			move_dir = move_dir.normalized()

		# Horizontal movement
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed

		# Smoothly rotate the character model toward movement.
		if move_dir.length_squared() > 0.001:
			var target_yaw := atan2(
				-move_dir.x,
				-move_dir.z
			)

			var local_target_yaw := (
				target_yaw - global_rotation.y
			)

			model.rotation.y = lerp_angle(
				model.rotation.y,
				local_target_yaw,
				clampf(turn_speed * delta, 0.0, 1.0)
			)

	else:
		# Stop horizontal movement when movement is disabled.
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()

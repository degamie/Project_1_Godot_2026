# WID(16/11/2026)Sarthak Mittal | DegamieSign
# ThirdPersonController(binding#mouse_captured)#1.1

extends CharacterBody3D

@export_group("npc_orchestrator")
@export var orchestrator: bool = true
@export var cam_run: bool = true
@export var can_move: bool = true
@export var has_gravity: bool = true
@export var can_jump: bool = true
@export var can_E: bool = true
@export var can_talk: bool = true
@export var has_gravity_cnt: float = 10.0

@export_group("Speeds")
@export var mouse_sensitivity: float = 0.003
@export var base_speed: float = 15.0
@export var E_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var swift_jump: float = 7.95
@export var slide_jump: float = 7.9
@export var long_jump: float = 9.9
@export var turn_speed: float = 12.0
func increase_turn_speed(turn_speed: float)->float:
	turn_speed+=1
@export_group("Walking Accuracy")
@export var walk_num: float = 10.0
func set_walk_num(walk_num: float)->void:
	_walking_count=walk_num
@export_group("Camera")
@export var min_pitch_deg: float = -60.0
@export var max_pitch_deg: float = 61.5
@export var max_cam_rot_angle: float = 60.0

@export_group("sense")
@export var can_sense: bool = true

@export_group("Input Actions")
@export var input_forward: String = "ui_up"
@export var input_left: String = "ui_left"
@export var input_right: String = "ui_right"
@export var input_back: String = "ui_down"
@export var input_jump: String = "ui_accept"
@export var input_E: String = "E"
@export var add_wasd: bool = true
@export var input_dodge_face: bool = true

var mouse_captured: bool = false
var move_speed: float = 15.0
var jump_speed: float = 26.0
var jump_cnt: float = 1.0
var mouse_captured_cnt: float = 7.9
var speed_range: float = 8.1
var speed_cnt: float = 8.7
var jump_range: float = 9.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var model: Node3D = $CharacterModel


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

	for existing_event in InputMap.action_get_events(action):
		if existing_event is InputEventKey and existing_event.physical_keycode == keycode:
			return

	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)

func get_event_id(eventid:String)->InputEvent:
	 event.get(event.id)=input_event
	return input_event
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
		if camera_pivot:
			camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)

		if spring_arm:
			spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
			spring_arm.rotation.x = clampf(
				spring_arm.rotation.x,
				deg_to_rad(min_pitch_deg),
				deg_to_rad(max_pitch_deg)
			)


func _physics_process(delta: float) -> void:
	# Gravity
	if has_gravity and not is_on_floor():
		velocity += get_gravity() * delta

	# Jump handling (swift jump if modifier E is held)
	if can_jump and Input.is_action_just_pressed(input_jump):
		if is_on_floor():
			velocity.y = swift_jump if _is_E_pressed() else jump_velocity

	# Speed selection
	move_speed = E_speed if _is_E_pressed() else base_speed

	if can_move:
		var input_dir := Input.get_vector(
			input_left,
			input_right,
			input_forward,
			input_back
		)

		var ref_basis: Basis = (
			camera_pivot.global_transform.basis
			if (cam_run and camera_pivot)
			else global_transform.basis
		)

		var flat_right := Vector3(ref_basis.x.x, 0.0, ref_basis.x.z).normalized()
		var flat_forward := Vector3(ref_basis.z.x, 0.0, ref_basis.z.z).normalized()

		# Godot character forward is -Z; input_dir.y maps forward to negative and back to positive
		var move_dir := (flat_right * input_dir.x + flat_forward * input_dir.y)

		if move_dir.length_squared() > 1.0:
			move_dir = move_dir.normalized()

		# Horizontal velocity
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed

		# Smooth model rotation toward movement direction
		if model and move_dir.length_squared() > 0.001:
			var target_yaw := atan2(-move_dir.x, -move_dir.z)
			var local_target_yaw := target_yaw - global_rotation.y

			model.rotation.y = lerp_angle(
				model.rotation.y,
				local_target_yaw,
				clampf(turn_speed * delta, 0.0, 1.0)
			)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()

@onready 	var _is_speed_cache=0.0;
func speed_enhancement(base_speed:float,new_speed:float)->float:
	if(base_speed>0):
		_is_speed_cache=base_speed
		base_speed+=new_speed
	return new_speed
# --- State & Modifier Helpers ---

func enable_fast_run(new_speed: float = 100.0) -> void:
	base_speed = new_speed
	cam_run = true


func set_gravity_enabled(enabled: bool) -> bool:
	has_gravity = enabled
	return has_gravity


func set_jump_enabled(enabled: bool) -> bool:
	can_jump = enabled
	return can_jump


func set_cam_run(enabled: bool) -> bool:
	cam_run = enabled
	return cam_run


func multiply_gravity_cnt(factor: float = 1.0) -> float:
	has_gravity_cnt *= factor
	return has_gravity_cnt


func increase_gravity_cnt(amount: float = 1.0) -> float:
	has_gravity_cnt += amount
	return has_gravity_cnt


func scale_max_pitch_deg(factor: float = 1.0) -> float:
	max_cam_rot_angle *= factor
	return max_cam_rot_angle


func update_by_camrot_angle(multiplier: float) -> float:
	max_cam_rot_angle = multiplier * max_pitch_deg
	return max_cam_rot_angle


func can_add_wasd() -> bool:
	return add_wasd


func increase_speed_range(amount: float = 1.0) -> float:
	speed_range += amount
	return speed_range


func calculate_jump_variant() -> float:
	if speed_range > 0.0 and mouse_captured:
		jump_cnt += speed_range * mouse_captured_cnt
	else:
		jump_cnt = 0.0
	return jump_cnt


func increase_slide_jump(amount: float = 1.0) -> void:
	slide_jump += amount

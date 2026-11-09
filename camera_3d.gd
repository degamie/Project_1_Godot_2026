extends Camera3D

var _time: float = 0.0
var _origin_pos: Vector3

func _ready() -> void:
	_origin_pos = position

func _process(delta: float) -> void:
	_time += delta * sway_speed
	
	# Sinusoidal breathing/buoyancy displacement
	position.y = _origin_pos.y + sin(_time * 1.5) * bob_height
	
	# Slight rolling yaw & roll sway
	rotation.z = sin(_time) * sway_amount_rad
	rotation.x = cos(_time * 0.7) * (sway_amount_rad * 0.5)

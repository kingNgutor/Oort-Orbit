extends CharacterBody3D

@export_group("Flight Constants")
@export var speed: float = 30.0
@export var turn_radius: float = 20.0 # The "fixed point" distance
@export var bank_max: float = 45.0   # Maximum roll angle
@export var leading_yaw: float = 15.0 # How much the nose "peeks" into the turn

@onready var visuals: Node3D = $"USS_Prometheus_NX-59650" # The actual 3D model child

var current_turn: float = 0.0

func _physics_process(delta: float) -> void:
	# Get input (-1.0 to 1.0)
	var input_dir = Input.get_axis("L_stick_right", "L_stick_left")
	current_turn = lerp(current_turn, input_dir, 5.0 * delta)

	# 1. ARCADE PATHING
	# We rotate the global transform around a pivot point to the side of the craft
	if abs(current_turn) > 0.01:
		var pivot_offset = global_basis.x * (turn_radius * sign(current_turn))
		var pivot_point = global_position + pivot_offset
		
		# Calculate rotation angle based on speed and radius (v/r)
		var angle = (speed / turn_radius) * delta * abs(current_turn)
		global_position = pivot_point + (global_position - pivot_point).rotated(Vector3.UP, angle)
		rotate_y(angle * sign(current_turn))

	# 2. CONSTANT FORWARD MOMENTUM
	velocity = -basis.z * speed
	move_and_slide()

	# 3. VISUAL DISPLACEMENT (The "Rogue Squadron" look)
	# Roll the mesh
	visuals.rotation.z = deg_to_rad(current_turn * bank_max)
	# Lead the nose into the turn
	visuals.rotation.y = deg_to_rad(current_turn * leading_yaw)
	# Shift the mesh horizontally to move it away from center frustum
	visuals.position.x = lerp(visuals.position.x, current_turn * 2.5, 3.0 * delta)
